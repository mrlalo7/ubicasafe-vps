"""Text-to-speech endpoint backed by Gemini TTS."""

from __future__ import annotations

import asyncio
import json
import logging
import urllib.error
import urllib.request

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.config import get_settings

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/tts", tags=["tts"])
settings = get_settings()


class TtsRequest(BaseModel):
    """Input text to synthesize."""

    text: str = Field(..., min_length=1, max_length=1400)


class TtsResponse(BaseModel):
    """Base64 PCM audio response."""

    mime_type: str
    sample_rate: int
    channels: int
    audio_base64: str


def _extract_audio_base64(payload: dict) -> str | None:
    """Support likely response shapes from the Interactions API."""
    output_audio = payload.get("output_audio") or payload.get("outputAudio")
    if isinstance(output_audio, dict):
        data = output_audio.get("data")
        if isinstance(data, str) and data:
            return data

    outputs = payload.get("outputs")
    if isinstance(outputs, list):
        for output in outputs:
            if not isinstance(output, dict):
                continue
            audio = output.get("audio") or output.get("output_audio")
            if isinstance(audio, dict):
                data = audio.get("data")
                if isinstance(data, str) and data:
                    return data

    return None


def _generate_tts_audio(text: str) -> str:
    """Generate base64 PCM audio through Gemini Interactions TTS."""
    prompt = (
        "Read this in Spanish with a natural, warm, calm female assistant voice. "
        "Use a Bolivian or neutral Latin American accent, friendly but serious, "
        "with clear pronunciation and a moderate pace. Do not add words.\n\n"
        f"{text}"
    )
    body = {
        "model": settings.tts_model,
        "input": prompt,
        "response_format": {"type": "audio"},
        "generation_config": {
            "speech_config": [
                {
                    "voice": settings.live_voice_name,
                }
            ]
        },
    }

    request = urllib.request.Request(
        "https://generativelanguage.googleapis.com/v1beta/interactions",
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "x-goog-api-key": settings.gemini_api_key,
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        logger.warning("Gemini TTS HTTP error %s: %s", exc.code, detail)
        raise HTTPException(
            status_code=502,
            detail=f"Gemini TTS no pudo generar audio ({exc.code}).",
        ) from exc
    except Exception as exc:
        logger.exception("Gemini TTS request failed")
        raise HTTPException(
            status_code=502,
            detail="No se pudo conectar con Gemini TTS.",
        ) from exc

    audio_base64 = _extract_audio_base64(payload)
    if not audio_base64:
        logger.warning("Gemini TTS response did not include audio: %s", payload)
        raise HTTPException(
            status_code=502,
            detail="Gemini TTS no devolvió audio.",
        )

    return audio_base64


@router.post("/", response_model=TtsResponse)
async def synthesize_speech(request: TtsRequest) -> TtsResponse:
    """Synthesize assistant speech as 24kHz mono PCM16 audio."""
    audio_base64 = await asyncio.to_thread(_generate_tts_audio, request.text)
    return TtsResponse(
        mime_type="audio/pcm;rate=24000",
        sample_rate=24000,
        channels=1,
        audio_base64=audio_base64,
    )
