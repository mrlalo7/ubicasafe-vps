"""Text-to-speech endpoint backed by Gemini TTS."""

from __future__ import annotations

import asyncio
import hashlib
import json
import logging
import socket
import time
import urllib.error
import urllib.parse
import urllib.request

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.config import get_settings

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/tts", tags=["tts"])
settings = get_settings()
_AUDIO_CACHE: dict[str, str] = {}
_MAX_TTS_CHARS = 420


class TtsRequest(BaseModel):
    """Input text to synthesize."""

    text: str = Field(..., min_length=1, max_length=1400)


class TtsResponse(BaseModel):
    """Base64 PCM audio response."""

    mime_type: str
    sample_rate: int
    channels: int
    audio_base64: str


def _audio_data_from_content(content: object) -> str | None:
    """Return base64 data from any nested Gemini audio content."""
    if isinstance(content, dict):
        data = content.get("data")
        content_type = content.get("type")
        mime_type = content.get("mime_type") or content.get("mimeType")
        if (
            isinstance(data, str)
            and data
            and (
                content_type == "audio"
                or (isinstance(mime_type, str) and mime_type.startswith("audio/"))
                or "sample_rate" in content
            )
        ):
            return data

        for value in content.values():
            audio_data = _audio_data_from_content(value)
            if audio_data:
                return audio_data

    if isinstance(content, list):
        for item in content:
            audio_data = _audio_data_from_content(item)
            if audio_data:
                return audio_data

    return None


def _extract_audio_base64(payload: dict) -> str | None:
    """Support response shapes returned by Gemini TTS APIs."""
    audio_data = _audio_data_from_content(payload)
    if audio_data:
        return audio_data

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


def _prepare_tts_text(text: str) -> str:
    """Keep spoken replies short enough for predictable Gemini TTS latency."""
    normalized = " ".join(text.split())
    if len(normalized) <= _MAX_TTS_CHARS:
        return normalized

    cutoff = _MAX_TTS_CHARS
    for separator in (". ", "? ", "! ", "; "):
        candidate = normalized.rfind(separator, 0, _MAX_TTS_CHARS)
        if candidate >= 180:
            cutoff = candidate + 1
            break

    shortened = normalized[:cutoff].strip(" ,;:-")
    if shortened and shortened[-1] not in ".?!":
        shortened += "."
    return shortened


def _generate_tts_audio(text: str) -> str:
    """Generate base64 PCM audio through Gemini generateContent TTS."""
    prepared_text = _prepare_tts_text(text)
    cache_key = hashlib.sha256(
        f"{settings.tts_model}|{settings.live_voice_name}|{prepared_text}".encode(
            "utf-8"
        )
    ).hexdigest()
    cached_audio = _AUDIO_CACHE.get(cache_key)
    if cached_audio:
        logger.info(
            "Gemini TTS cache hit model=%s voice=%s text_length=%d",
            settings.tts_model,
            settings.live_voice_name,
            len(prepared_text),
        )
        return cached_audio

    prompt = (
        "Say the provided text exactly, in the same language it is written, "
        "with a natural, warm, calm female assistant voice. "
        "Use a Bolivian or neutral Latin American accent, friendly but serious, "
        "with clear pronunciation and a moderate pace. Do not add words.\n\n"
        f"{prepared_text}"
    )
    body = {
        "contents": [
            {
                "parts": [
                    {
                        "text": prompt,
                    }
                ]
            }
        ],
        "generationConfig": {
            "responseModalities": ["AUDIO"],
            "speechConfig": {
                "voiceConfig": {
                    "prebuiltVoiceConfig": {
                        "voiceName": settings.live_voice_name,
                    }
                }
            },
        },
        "model": settings.tts_model,
    }

    encoded_model = urllib.parse.quote(settings.tts_model, safe="")
    request = urllib.request.Request(
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{encoded_model}:generateContent",
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "x-goog-api-key": settings.gemini_api_key,
        },
        method="POST",
    )

    started_at = time.monotonic()
    try:
        with urllib.request.urlopen(
            request,
            timeout=settings.tts_timeout_seconds,
        ) as response:
            raw_body = response.read().decode("utf-8")
            elapsed_ms = int((time.monotonic() - started_at) * 1000)
            logger.info(
                "Gemini TTS success model=%s voice=%s status=%s elapsed_ms=%d "
                "text_length=%d original_length=%d",
                settings.tts_model,
                settings.live_voice_name,
                response.status,
                elapsed_ms,
                len(prepared_text),
                len(text),
            )
            payload = json.loads(raw_body)
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        elapsed_ms = int((time.monotonic() - started_at) * 1000)
        logger.warning(
            "Gemini TTS HTTP error model=%s voice=%s status=%s elapsed_ms=%d body=%s",
            settings.tts_model,
            settings.live_voice_name,
            exc.code,
            elapsed_ms,
            detail,
        )
        raise HTTPException(
            status_code=502,
            detail=f"Gemini TTS no pudo generar audio ({exc.code}).",
        ) from exc
    except (TimeoutError, socket.timeout, urllib.error.URLError) as exc:
        elapsed_ms = int((time.monotonic() - started_at) * 1000)
        logger.warning(
            "Gemini TTS timeout/network error model=%s voice=%s elapsed_ms=%d "
            "timeout_seconds=%d text_length=%d original_length=%d error=%r",
            settings.tts_model,
            settings.live_voice_name,
            elapsed_ms,
            settings.tts_timeout_seconds,
            len(prepared_text),
            len(text),
            exc,
        )
        raise HTTPException(
            status_code=504,
            detail="Gemini TTS tardó demasiado o no respondió.",
        ) from exc
    except Exception as exc:
        elapsed_ms = int((time.monotonic() - started_at) * 1000)
        logger.exception(
            "Gemini TTS request failed model=%s voice=%s elapsed_ms=%d",
            settings.tts_model,
            settings.live_voice_name,
            elapsed_ms,
        )
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

    if len(_AUDIO_CACHE) >= 64:
        _AUDIO_CACHE.clear()
    _AUDIO_CACHE[cache_key] = audio_base64
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
