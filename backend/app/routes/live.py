"""Gemini Live API WebSocket bridge for real-time voice calls."""

from __future__ import annotations

import asyncio
import base64
import json
import logging
from contextlib import suppress

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from google import genai
from google.genai import types
from sqlalchemy import select

from app.config import get_settings
from app.database.connection import async_session_factory
from app.models.report import Report
from app.models.risk_zone import RiskZone

logger = logging.getLogger(__name__)
router = APIRouter(tags=["live"])
settings = get_settings()


_AYMARA_RISK_LEVELS = {
    "low": "jisk'a jan walt'awi",
    "medium": "taypi jan walt'awi",
    "high": "jach'a jan walt'awi",
    "critical": "sinti jach'a jan walt'awi",
}


async def _build_live_context() -> str:
    """Load a compact DB snapshot so Live has current UbicaSafe context."""
    async with async_session_factory() as session:
        zone_result = await session.execute(
            select(RiskZone)
            .order_by(RiskZone.report_count.desc(), RiskZone.risk_level.desc())
            .limit(30)
        )
        zones = list(zone_result.scalars().all())

        report_result = await session.execute(
            select(Report).order_by(Report.created_at.desc()).limit(12)
        )
        reports = list(report_result.scalars().all())

    parts = [
        "Te llamas Wara. Eres Wara, la asistente de seguridad ciudadana de UbicaSafe para El Alto, Bolivia.",
        "Si el usuario pregunta tu nombre o quién eres, responde: Soy Wara, tu asistente de seguridad de UbicaSafe.",
        "Responde siempre breve, natural y útil.",
        "Si el usuario habla en aymara, responde en aymara claro. No mezcles español para el nivel de riesgo.",
        "En aymara traduce niveles así: bajo = jisk'a jan walt'awi, medio = taypi jan walt'awi, alto = jach'a jan walt'awi, critico = sinti jach'a jan walt'awi.",
        "Si respondes en aymara, no digas BAJO, MEDIO, ALTO ni CRITICO.",
        "Si el usuario habla en español, responde en español claro.",
        "Si hay peligro inmediato, recomienda llamar al 110 y buscar un lugar seguro.",
        "No afirmes que contactaste autoridades. Orienta al usuario para reportar o prevenir.",
    ]

    if zones:
        parts.append("Zonas de riesgo actuales:")
        for zone in zones:
            aymara_level = _AYMARA_RISK_LEVELS.get(
                zone.risk_level,
                zone.risk_level,
            )
            parts.append(
                f"- {zone.name}: nivel {zone.risk_level}, "
                f"nivel en aymara {aymara_level}, "
                f"{zone.report_count} reportes, {zone.description}"
            )

    if reports:
        parts.append("Reportes recientes:")
        for report in reports:
            parts.append(
                f"- {report.incident_date:%d/%m/%Y %H:%M}: "
                f"{report.report_type} en {report.location_text}, "
                f"violencia {report.violence_level}, {report.description[:160]}"
            )

    return "\n".join(parts)


async def _send_json(websocket: WebSocket, payload: dict) -> None:
    await websocket.send_text(json.dumps(payload, ensure_ascii=False))


@router.websocket("/api/live")
async def live_voice(websocket: WebSocket) -> None:
    """Bridge Flutter PCM audio to Gemini Live and stream PCM audio back."""
    await websocket.accept()
    logger.info("Live voice websocket accepted client=%s", websocket.client)
    client = genai.Client(api_key=settings.gemini_api_key)
    live_context = await _build_live_context()
    config = {
        "response_modalities": ["AUDIO"],
        "input_audio_transcription": {},
        "output_audio_transcription": {},
        "system_instruction": live_context,
        "temperature": 0.55,
        "speech_config": {
            "voice_config": {
                "prebuilt_voice_config": {
                    "voice_name": settings.live_voice_name,
                }
            }
        },
    }

    try:
        async with client.aio.live.connect(
            model=settings.live_model,
            config=config,
        ) as session:
            logger.info(
                "Gemini Live session ready model=%s voice=%s",
                settings.live_model,
                settings.live_voice_name,
            )
            await _send_json(
                websocket,
                {
                    "type": "ready",
                    "model": settings.live_model,
                    "inputRate": 16000,
                    "outputRate": 24000,
                },
            )

            async def receive_from_client() -> None:
                while True:
                    raw_message = await websocket.receive_text()
                    message = json.loads(raw_message)
                    message_type = message.get("type")

                    if message_type == "audio":
                        data = base64.b64decode(message["data"])
                        await session.send_realtime_input(
                            audio=types.Blob(
                                data=data,
                                mime_type=message.get(
                                    "mimeType",
                                    "audio/pcm;rate=16000",
                                ),
                            )
                        )
                    elif message_type == "audio_stream_end":
                        logger.info("Live audio stream pause received")
                        with suppress(TypeError):
                            await session.send_realtime_input(
                                audio_stream_end=True
                            )
                    elif message_type == "text":
                        logger.info("Live text message received")
                        await session.send_realtime_input(text=message["text"])
                    elif message_type == "stop":
                        logger.info("Live voice stop received")
                        break

            async def send_to_client() -> None:
                while True:
                    received_any = False
                    async for response in session.receive():
                        received_any = True
                        server_content = response.server_content
                        if server_content is None:
                            continue

                        if getattr(server_content, "interrupted", False):
                            logger.info("Gemini Live interrupted current turn")
                            await _send_json(websocket, {"type": "interrupted"})

                        turn_complete = getattr(server_content, "turn_complete", None)
                        generation_complete = getattr(
                            server_content,
                            "generation_complete",
                            False,
                        )
                        if turn_complete is True or (
                            turn_complete is None and generation_complete
                        ):
                            logger.info(
                                "Gemini Live turn complete "
                                "turn_complete=%s generation_complete=%s",
                                turn_complete,
                                generation_complete,
                            )
                            await _send_json(websocket, {"type": "complete"})

                        input_transcription = getattr(
                            server_content,
                            "input_transcription",
                            None,
                        )
                        if input_transcription is not None:
                            text = getattr(input_transcription, "text", "")
                            if text:
                                await _send_json(
                                    websocket,
                                    {"type": "input_transcript", "text": text},
                                )

                        output_transcription = getattr(
                            server_content,
                            "output_transcription",
                            None,
                        )
                        if output_transcription is not None:
                            text = getattr(output_transcription, "text", "")
                            if text:
                                await _send_json(
                                    websocket,
                                    {"type": "output_transcript", "text": text},
                                )

                        model_turn = server_content.model_turn
                        if model_turn is None:
                            continue

                        for part in model_turn.parts:
                            inline_data = part.inline_data
                            if inline_data is None:
                                continue
                            await _send_json(
                                websocket,
                                {
                                    "type": "audio",
                                    "mimeType": inline_data.mime_type
                                    or "audio/pcm;rate=24000",
                                    "data": base64.b64encode(
                                        inline_data.data
                                    ).decode("ascii"),
                                },
                            )

                    # Some SDK versions end a receive iterator after a model turn.
                    # Keep the websocket/session open and wait for the next turn.
                    if not received_any:
                        await asyncio.sleep(0.05)

            tasks = [
                asyncio.create_task(receive_from_client()),
                asyncio.create_task(send_to_client()),
            ]
            done, pending = await asyncio.wait(
                tasks,
                return_when=asyncio.FIRST_COMPLETED,
            )
            for task in pending:
                task.cancel()
            for task in done:
                task.result()

    except WebSocketDisconnect:
        logger.info("Live voice websocket disconnected")
    except Exception:
        logger.exception("Live voice session failed")
        with suppress(Exception):
            await _send_json(
                websocket,
                {
                    "type": "error",
                    "message": "No se pudo iniciar la llamada con Gemini Live.",
                },
            )
    finally:
        with suppress(Exception):
            await websocket.close()
