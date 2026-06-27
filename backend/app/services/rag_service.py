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

RISK_LEVEL_LABELS = {
    "low": "BAJO",
    "medium": "MEDIO",
    "high": "ALTO",
    "critical": "CRITICO",
}

SUPPORTED_LANGUAGES = {"es", "ay", "es-ay"}

AYMARA_SECURITY_GLOSSARY = """
Glosario practico español-aymara para UbicaSafe:
- seguridad: jark'aqasiwi / suma jakasiwi
- peligro: jan walt'awi
- riesgo bajo: jisk'a jan walt'awi
- riesgo medio: taypi jan walt'awi
- riesgo alto: jach'a jan walt'awi
- robo: lunthatawi
- ladron: lunthata
- denuncia/reporte: yatiyawi
- ayuda: yanapt'awi
- ayuda urgente: jank'aki yanapt'awi
- zona segura: suma chiqa
- zona peligrosa: jan wali chiqa
- ubicacion: kawkhankta
- llama al 110: 110 ukar jawst'am
- busca un lugar seguro: suma chiqaw thaqam
- no enfrentes al agresor: jan nuwasimti
- comparte tu ubicacion: kawkhanktasa yatiyam
- armas: armampi / nuwasiñ yänaka
- lesiones/heridas: usuchjawi
- de noche: arumaxa
- transitar/caminar: sarnaqaña
"""

AYMARA_EMERGENCY_GUIDE = """
Frases criticas sugeridas:
Español: Si estás en peligro inmediato, llama al 110 y busca un lugar seguro.
Aymara: Jichhpach jan walt'awinksta ukhaxa, 110 ukar jawst'am ukat suma chiqaw thaqam.

Español: No enfrentes al agresor. Aléjate y comparte tu ubicación.
Aymara: Jan nuwasimti. Jayan saram ukat kawkhanktasa yatiyam.

Español: Si hubo heridas o armas, pide ayuda urgente.
Aymara: Usuchjawi jan ukax armampi utjchi ukhaxa, jank'aki yanapt'awi mayim.
"""


def risk_level_label(value: str | None) -> str:
    """Return a user-facing Spanish label for a stored risk level."""
    normalized = (value or "").strip().lower()
    return RISK_LEVEL_LABELS.get(normalized, normalized.upper() or "NO ESPECIFICADO")


def normalize_language(language: str | None) -> str:
    """Validate and normalize response language mode."""
    normalized = (language or "es").strip().lower()
    return normalized if normalized in SUPPORTED_LANGUAGES else "es"


def language_instruction(language: str) -> str:
    """Prompt block that controls Spanish/Aymara output."""
    if language == "ay":
        return (
            "Responde principalmente en aymara boliviano claro y practico. "
            "Usa frases cortas y naturales. Conserva nombres de zonas, calles, "
            "universidades y lugares exactamente como aparecen en CONTEXTO. "
            "Si una palabra tecnica de seguridad no tiene traduccion clara, "
            "escribe el termino en aymara y agrega el español entre parentesis. "
            "No traduzcas numeros de emergencia como 110."
        )
    if language == "es-ay":
        return (
            "Responde en formato bilingue. Primero una respuesta breve en español "
            "y luego una version corta en aymara bajo el texto 'Aymarata:'. "
            "La version en aymara debe ser clara, practica y no demasiado larga. "
            "Conserva nombres de zonas y datos numericos sin traducir."
        )
    return "Responde en español claro, breve y util."


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
    tokens = [
        token
        for token in re.findall(r"[a-záéíóúñ0-9]+", question.lower())
        if len(token) > 3 and token not in STOPWORDS
    ]
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
) -> str:
    """Format retrieved documents into context for the LLM prompt."""
    parts: list[str] = []

    if zones:
        parts.append("=== ZONAS DE RIESGO RELEVANTES ===")
        for i, z in enumerate(zones, 1):
            parts.append(
                f"{i}. {z['name']} — Nivel: {risk_level_label(z.get('risk_level'))} — "
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

    language = normalize_language(language)
    system_instruction = (
        "Eres IA+ de UbicaSafe, asistente de seguridad ciudadana para "
        "El Alto y La Paz, Bolivia. "
        f"{language_instruction(language)} "
        "IMPORTANTE: Basa tus respuestas en los datos reales proporcionados "
        "en la sección CONTEXTO. No inventes estadísticas ni reportes. "
        "Si hay peligro inmediato, recomienda llamar al 110 y buscar un "
        "lugar seguro. "
        "No uses Markdown: no escribas asteriscos, negritas, listas con *, "
        "tablas ni encabezados. "
        "Cuando menciones niveles de riesgo, usa solo estas etiquetas en "
        "español: BAJO, MEDIO, ALTO o CRITICO. Nunca respondas LOW, MEDIUM, "
        "HIGH ni CRITICAL. "
        "Cuando respondas en aymara, puedes conservar esas etiquetas de riesgo "
        "en español junto a una explicacion breve en aymara. "
        "Guía al usuario para reportar, consultar riesgo o recibir "
        "consejos preventivos."
    )

    history = ""
    if recent_messages:
        history = "Historial reciente:\n" + "\n".join(recent_messages[-4:]) + "\n\n"

    language_context = ""
    if language in {"ay", "es-ay"}:
        language_context = (
            f"\n\nAPOYO DE IDIOMA AYMARA:\n{AYMARA_SECURITY_GLOSSARY}\n"
            f"{AYMARA_EMERGENCY_GUIDE}\n"
            "Usa este glosario como guia, pero prioriza claridad y seguridad."
        )

    prompt = f"""{history}CONTEXTO (datos reales de la base de datos de UbicaSafe):
{context}
{language_context}

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

    if not zones:
        try:
            zones = await search_zones_by_text(session, question, limit=3)
        except Exception:
            await session.rollback()
            logger.exception("Text search for risk zones failed")
            warnings.append("zone_text_search_failed")

    # 3. Build RAG context from retrieved documents
    context = build_rag_context(reports, zones)

    # 4. Generate response with Gemini
    language = normalize_language(language)
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
