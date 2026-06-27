"""RAG chat endpoint — the core of the intelligent assistant."""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.connection import get_session
from app.services.rag_service import rag_pipeline

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/chat", tags=["chat"])


class ChatRequest(BaseModel):
    """Input: user message + optional conversation history."""

    message: str = Field(..., min_length=1, max_length=2000)
    recent_messages: list[str] = Field(default_factory=list, max_length=10)
    language: str = Field(default="es", pattern="^(es|ay|es-ay)$")


class ChatResponse(BaseModel):
    """Output: AI answer + metadata about sources used."""

    answer: str
    sources: dict


@router.post("/", response_model=ChatResponse)
async def chat(
    data: ChatRequest,
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Process a user question through the full RAG pipeline.

    1. Embeds the question with Gemini text-embedding-004
    2. Searches pgvector for relevant reports & risk zones
    3. Builds context from real data
    4. Generates response with Gemini, grounded in actual data
    """
    # Truncate recent_messages to last 4 for context window efficiency
    recent = data.recent_messages[-4:] if data.recent_messages else None

    result = await rag_pipeline(
        session=session,
        question=data.message,
        recent_messages=recent,
        language=data.language,
    )

    logger.info(
        "RAG query processed — reports_used=%d zones_used=%d",
        result["sources"]["reports_used"],
        result["sources"]["zones_used"],
    )

    return result
