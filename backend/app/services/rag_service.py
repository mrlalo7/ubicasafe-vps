"""RAG (Retrieval-Augmented Generation) service.

Orchestrates: query embedding → pgvector search → context building → Gemini generation.
"""

from __future__ import annotations

import asyncio
import logging
import re
from datetime import datetime

import google.generativeai as genai
from sqlalchemy import text as sql_text
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.services.embedding_service import generate_query_embedding

logger = logging.getLogger(__name__)
settings = get_settings()

STOPWORDS = {
    "alto",
    "buenas",
    "como",
    "cual",
    "cuales",
    "donde",
    "esta",
    "este",
    "hola",
    "para",
    "puedo",
    "puede",
    "segura",
    "seguro",
    "sobre",
    "zona",
}

REPORT_QUERY_WORDS = {
    "denuncia",
    "denuncias",
    "incidente",
    "incidentes",
    "reciente",
    "recientes",
    "reporte",
    "reportes",
    "robo",
    "robos",
    "ultimo",
    "ultimos",
    "último",
    "últimos",
}

RISK_LEVEL_LABELS = {
    "low": "BAJO",
    "medium": "MEDIO",
    "high": "ALTO",
    "critical": "CRITICO",
}

AYMARA_RISK_LEVEL_LABELS = {
    "low": "jisk'a jan walt'awi",
    "medium": "taypi jan walt'awi",
    "high": "jach'a jan walt'awi",
    "critical": "sinti jach'a jan walt'awi",
}


def _query_tokens(question: str) -> list[str]:
    """Return relevant lowercase tokens from a user question."""
    return [
        token
        for token in re.findall(r"[a-záéíóúñ0-9]+", question.lower())
        if len(token) > 3 and token not in STOPWORDS
    ]


def _looks_like_report_query(question: str) -> bool:
    tokens = set(_query_tokens(question))
    return bool(tokens & REPORT_QUERY_WORDS)


def _merge_documents(primary: list[dict], secondary: list[dict]) -> list[dict]:
    """Merge DB rows without duplicating ids, preserving order."""
    seen: set[str] = set()
    merged: list[dict] = []
    for item in [*primary, *secondary]:
        item_id = str(item.get("id", ""))
        if item_id and item_id in seen:
            continue
        if item_id:
            seen.add(item_id)
        merged.append(item)
    return merged


def risk_level_label(value: str | None, language: str = "es") -> str:
    """Return a user-facing risk label for a stored risk level."""
    normalized = (value or "").strip().lower()
    if language == "ay":
        return AYMARA_RISK_LEVEL_LABELS.get(
            normalized,
            normalized or "jan qhananchata",
        )
    return RISK_LEVEL_LABELS.get(normalized, normalized.upper() or "NO ESPECIFICADO")


async def search_similar_reports(
    session: AsyncSession,
    query_embedding: list[float],
    limit: int = 5,
) -> list[dict]:
    """Find the most semantically similar reports using pgvector cosine distance.

    Uses parameterized query — no string concatenation with user input.
    """
    embedding_str = "[" + ",".join(str(v) for v in query_embedding) + "]"

    result = await session.execute(
        sql_text(
            """
            SELECT
                id, report_type, location_text, description,
                violence_level, had_injuries, had_weapons, weapon_type,
                incident_date, latitude, longitude,
                1 - (embedding <=> CAST(:embedding AS vector)) AS similarity
            FROM reports
            WHERE embedding IS NOT NULL
            ORDER BY embedding <=> CAST(:embedding AS vector)
            LIMIT :limit
            """
        ),
        {"embedding": embedding_str, "limit": limit},
    )

    rows = result.mappings().all()
    return [dict(row) for row in rows]


async def search_reports_by_text(
    session: AsyncSession,
    question: str,
    limit: int = 5,
) -> list[dict]:
    """Find recent reports by text/location, including rows without embeddings."""
    tokens = [
        token for token in _query_tokens(question) if token not in REPORT_QUERY_WORDS
    ]

    params: dict[str, object] = {"limit": limit}
    where_clause = ""

    if tokens:
        conditions = []
        for index, token in enumerate(tokens[:6]):
            key = f"report_term_{index}"
            params[key] = f"%{token}%"
            conditions.append(
                f"""(
                    LOWER(location_text) LIKE :{key}
                    OR LOWER(description) LIKE :{key}
                    OR LOWER(report_type) LIKE :{key}
                    OR LOWER(violence_level) LIKE :{key}
                )"""
            )
        where_clause = f"WHERE {' OR '.join(conditions)}"
    elif not _looks_like_report_query(question):
        return []

    result = await session.execute(
        sql_text(
            f"""
            SELECT
                id, report_type, location_text, description,
                violence_level, had_injuries, had_weapons, weapon_type,
                incident_date, latitude, longitude,
                0 AS similarity
            FROM reports
            {where_clause}
            ORDER BY incident_date DESC, created_at DESC
            LIMIT :limit
            """
        ),
        params,
    )

    rows = result.mappings().all()
    return [dict(row) for row in rows]


async def search_similar_zones(
    session: AsyncSession,
    query_embedding: list[float],
    limit: int = 3,
) -> list[dict]:
    """Find the most relevant risk zones via vector similarity."""
    embedding_str = "[" + ",".join(str(v) for v in query_embedding) + "]"

    result = await session.execute(
        sql_text(
            """
            SELECT
                id, name, risk_level, description,
                radius_meters, report_count, latitude, longitude,
                1 - (embedding <=> CAST(:embedding AS vector)) AS similarity
            FROM risk_zones
            WHERE embedding IS NOT NULL
            ORDER BY embedding <=> CAST(:embedding AS vector)
            LIMIT :limit
            """
        ),
        {"embedding": embedding_str, "limit": limit},
    )

    rows = result.mappings().all()
    return [dict(row) for row in rows]


async def search_zones_by_text(
    session: AsyncSession,
    question: str,
    limit: int = 3,
) -> list[dict]:
    """Fallback zone search when embeddings are missing or unavailable."""
    tokens = _query_tokens(question)
    if not tokens:
        return []

    conditions = []
    params: dict[str, object] = {"limit": limit}
    for index, token in enumerate(tokens[:6]):
        key = f"term_{index}"
        params[key] = f"%{token}%"
        conditions.append(
            f"(LOWER(name) LIKE :{key} OR LOWER(description) LIKE :{key})"
        )

    result = await session.execute(
        sql_text(
            f"""
            SELECT
                id, name, risk_level, description,
                radius_meters, report_count, latitude, longitude,
                0 AS similarity
            FROM risk_zones
            WHERE {" OR ".join(conditions)}
            ORDER BY
                CASE risk_level
                    WHEN 'high' THEN 3
                    WHEN 'medium' THEN 2
                    ELSE 1
                END DESC,
                name ASC
            LIMIT :limit
            """
        ),
        params,
    )

    rows = result.mappings().all()
    return [dict(row) for row in rows]


def build_rag_context(
    reports: list[dict],
    zones: list[dict],
    language: str = "es",
) -> str:
    """Format retrieved documents into context for the LLM prompt."""
    parts: list[str] = []

    if zones:
        parts.append("=== ZONAS DE RIESGO RELEVANTES ===")
        for i, z in enumerate(zones, 1):
            parts.append(
                f"{i}. {z['name']} — Nivel: {risk_level_label(z.get('risk_level'), language)} — "
                f"Radio: {z['radius_meters']:.0f}m — "
                f"Reportes registrados: {z.get('report_count', 0)} — "
                f"{z['description']}"
            )

    if reports:
        parts.append("\n=== DENUNCIAS RECIENTES RELEVANTES ===")
        for i, r in enumerate(reports, 1):
            fecha = r.get("incident_date")
            if isinstance(fecha, datetime):
                fecha = fecha.strftime("%d/%m/%Y %H:%M")
            violence = r.get("violence_level", "No especificado")
            injuries = "Sí" if r.get("had_injuries") else "No"
            weapons = "Sí" if r.get("had_weapons") else "No"
            parts.append(
                f"{i}. [{fecha}] {r['report_type']} en {r['location_text']} — "
                f"Violencia: {violence} — Lesiones: {injuries} — "
                f"Armas: {weapons} — {r['description'][:200]}"
            )

    if not parts:
        return "No se encontraron datos relevantes en la base de datos."

    return "\n".join(parts)


async def generate_rag_response(
    question: str,
    context: str,
    recent_messages: list[str] | None = None,
    language: str = "es",
) -> str:
    """Call Gemini with the RAG-enriched prompt.

    The system instruction anchors the model's persona and the context
    section feeds it real data so it does not hallucinate statistics.
    """

    language_instruction = (
        "Responde en aymara claro. No mezcles español para el nivel de riesgo. "
        "Traduce los niveles así: low/jisk'a jan walt'awi, "
        "medium/taypi jan walt'awi, high/jach'a jan walt'awi, "
        "critical/sinti jach'a jan walt'awi. "
        "No escribas BAJO, MEDIO, ALTO ni CRITICO cuando respondas en aymara. "
        if language == "ay"
        else "Respondes en español claro, breve y útil. "
    )

    system_instruction = (
        "Te llamas Wara. Eres Wara, la asistente de seguridad ciudadana "
        "de UbicaSafe para El Alto y La Paz, Bolivia. "
        "Si el usuario pregunta tu nombre o quién eres, responde de forma "
        "directa: Soy Wara, tu asistente de seguridad de UbicaSafe. "
        f"{language_instruction}"
        "IMPORTANTE: Basa tus respuestas en los datos reales proporcionados "
        "en la sección CONTEXTO. No inventes estadísticas ni reportes. "
        "Si hay peligro inmediato, recomienda llamar al 110 y buscar un "
        "lugar seguro. "
        "No uses Markdown: no escribas asteriscos, negritas, listas con *, "
        "tablas ni encabezados. "
        "Nunca respondas LOW, MEDIUM, HIGH ni CRITICAL. "
        "En español usa BAJO, MEDIO, ALTO o CRITICO. "
        "En aymara usa jisk'a jan walt'awi, taypi jan walt'awi, "
        "jach'a jan walt'awi o sinti jach'a jan walt'awi. "
        "Guía al usuario para reportar, consultar riesgo o recibir "
        "consejos preventivos."
    )

    history = ""
    if recent_messages:
        history = "Historial reciente:\n" + "\n".join(recent_messages[-4:]) + "\n\n"

    prompt = f"""{history}CONTEXTO (datos reales de la base de datos de UbicaSafe):
{context}

Pregunta del usuario:
{question}"""

    def _generate() -> str:
        model = genai.GenerativeModel(
            model_name=settings.generation_model,
            system_instruction=system_instruction,
            generation_config={
                "temperature": 0.7,
                "max_output_tokens": 500,
            },
        )
        response = model.generate_content(prompt)
        return response.text or "No pude generar una respuesta. Intenta otra consulta."

    try:
        return await asyncio.to_thread(_generate)
    except Exception:
        logger.exception("Error generating RAG response")
        return (
            "Hubo un error al consultar la IA. "
            "Por favor intenta nuevamente en unos segundos."
        )


async def rag_pipeline(
    session: AsyncSession,
    question: str,
    recent_messages: list[str] | None = None,
    language: str = "es",
) -> dict:
    """Full RAG pipeline: embed → search → build context → generate.

    Returns a dict with the answer and the source documents used.
    """
    reports: list[dict] = []
    zones: list[dict] = []
    warnings: list[str] = []

    try:
        query_embedding = await generate_query_embedding(question)
    except Exception:
        logger.exception("Query embedding failed")
        query_embedding = None
        warnings.append("query_embedding_failed")

    if query_embedding is not None:
        try:
            reports = await search_similar_reports(session, query_embedding, limit=5)
        except Exception:
            await session.rollback()
            logger.exception("Vector search for reports failed")
            warnings.append("report_vector_search_failed")

        try:
            zones = await search_similar_zones(session, query_embedding, limit=3)
        except Exception:
            await session.rollback()
            logger.exception("Vector search for risk zones failed")
            warnings.append("zone_vector_search_failed")

    try:
        text_reports = await search_reports_by_text(session, question, limit=5)
        if text_reports:
            reports = _merge_documents(text_reports, reports)[:8]
    except Exception:
        await session.rollback()
        logger.exception("Text search for reports failed")
        warnings.append("report_text_search_failed")

    if not reports and _looks_like_report_query(question):
        warnings.append("no_matching_reports_found")

    if not zones:
        try:
            zones = await search_zones_by_text(session, question, limit=3)
        except Exception:
            await session.rollback()
            logger.exception("Text search for risk zones failed")
            warnings.append("zone_text_search_failed")

    # 3. Build RAG context from retrieved documents
    context = build_rag_context(reports, zones, language)

    # 4. Generate response with Gemini
    answer = await generate_rag_response(
        question,
        context,
        recent_messages,
        language,
    )

    return {
        "answer": answer,
        "sources": {
            "reports_used": len(reports),
            "zones_used": len(zones),
            "language": language,
            "warnings": warnings,
        },
    }
