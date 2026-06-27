"""UBICASAFE RAG Backend — FastAPI application."""

from __future__ import annotations

import logging

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.config import get_settings
from app.database.connection import engine
from app.models import Base
from app.routes import chat, live, reports, stats, zones

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)

settings = get_settings()

# ── Rate limiter ──────────────────────────────────────────────────────
limiter = Limiter(key_func=get_remote_address, default_limits=[settings.rate_limit])

# ── FastAPI App ───────────────────────────────────────────────────────
app = FastAPI(
    title="UbicaSafe RAG API",
    description="Backend RAG con pgvector + Gemini para consultas de seguridad ciudadana",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ── CORS ──────────────────────────────────────────────────────────────
# TODO(security): Restrict CORS to specific origins in production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
)


# ── Security Headers Middleware ───────────────────────────────────────
@app.middleware("http")
async def add_security_headers(request: Request, call_next) -> Response:  # type: ignore[type-arg]
    """Add security headers to every response."""
    response: Response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Cache-Control"] = "no-store"
    response.headers["Content-Security-Policy"] = (
        "default-src 'self'; frame-ancestors 'none'"
    )
    return response


# ── Startup / Shutdown ────────────────────────────────────────────────
@app.on_event("startup")
async def on_startup() -> None:
    """Create tables if they don't exist."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Database tables ensured — UbicaSafe RAG API ready")


@app.on_event("shutdown")
async def on_shutdown() -> None:
    await engine.dispose()
    logger.info("Database engine disposed")


# ── Routers ───────────────────────────────────────────────────────────
app.include_router(reports.router)
app.include_router(chat.router)
app.include_router(live.router)
app.include_router(stats.router)
app.include_router(zones.router)


# ── Health Check ──────────────────────────────────────────────────────
@app.get("/api/health", tags=["health"])
async def health() -> dict:
    """Simple health check endpoint."""
    return {"status": "ok", "service": "ubicasafe-rag"}
