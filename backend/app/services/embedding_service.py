"""Embedding generation via Gemini, normalized to the DB vector size."""

from __future__ import annotations

import logging

import google.generativeai as genai

from app.config import get_settings

logger = logging.getLogger(__name__)

settings = get_settings()
genai.configure(api_key=settings.gemini_api_key)


def _fit_embedding_dimensions(embedding: list[float]) -> list[float]:
    """Ensure Gemini embeddings match the pgvector column dimensions."""
    expected = settings.embedding_dimensions
    if len(embedding) == expected:
        return embedding
    if len(embedding) > expected:
        logger.warning(
            "Embedding returned %d dimensions; trimming to %d",
            len(embedding),
            expected,
        )
        return embedding[:expected]

    logger.warning(
        "Embedding returned %d dimensions; padding to %d",
        len(embedding),
        expected,
    )
    return embedding + [0.0] * (expected - len(embedding))


async def generate_embedding(text: str) -> list[float]:
    """Generate a 768-dim embedding for *text* using Gemini.

    The call is CPU-bound (network I/O managed by the SDK), so we use
    the synchronous SDK method — for a VPS with moderate load this is
    acceptable.  For high throughput, wrap in ``asyncio.to_thread``.
    """
    import asyncio

    def _embed() -> list[float]:
        result = genai.embed_content(
            model=f"models/{settings.embedding_model}",
            content=text,
            task_type="RETRIEVAL_DOCUMENT",
            output_dimensionality=settings.embedding_dimensions,
        )
        return _fit_embedding_dimensions(result["embedding"])

    return await asyncio.to_thread(_embed)


async def generate_query_embedding(text: str) -> list[float]:
    """Generate an embedding optimized for *query* retrieval."""
    import asyncio

    def _embed() -> list[float]:
        result = genai.embed_content(
            model=f"models/{settings.embedding_model}",
            content=text,
            task_type="RETRIEVAL_QUERY",
            output_dimensionality=settings.embedding_dimensions,
        )
        return _fit_embedding_dimensions(result["embedding"])

    return await asyncio.to_thread(_embed)


def build_report_text(
    report_type: str,
    location_text: str,
    description: str,
    violence_level: str,
    had_injuries: bool = False,
    had_weapons: bool = False,
    weapon_type: str | None = None,
    device_brand: str | None = None,
    **_extra: object,
) -> str:
    """Convert report fields into a single text for embedding.

    The text representation captures the semantic essence of the report
    so that vector similarity searches return meaningful results.
    """
    parts = [
        f"Tipo de incidente: {report_type}.",
        f"Ubicación: {location_text}.",
        f"Descripción: {description}.",
        f"Nivel de violencia: {violence_level}.",
    ]
    if had_injuries:
        parts.append("Hubo lesiones físicas.")
    if had_weapons:
        weapon_desc = weapon_type or "tipo no especificado"
        parts.append(f"Se usaron armas: {weapon_desc}.")
    if device_brand:
        parts.append(f"Dispositivo robado marca: {device_brand}.")
    return " ".join(parts)


def build_zone_text(
    name: str,
    risk_level: str,
    description: str,
    radius_meters: float,
    **_extra: object,
) -> str:
    """Convert zone data into text for embedding."""
    return (
        f"Zona de riesgo: {name}. "
        f"Nivel: {risk_level}. "
        f"Radio: {radius_meters:.0f} metros. "
        f"Descripción: {description}."
    )
