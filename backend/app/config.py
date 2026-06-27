"""Centralized configuration loaded from environment variables.

Secrets are resolved from environment variables only. If a required secret
is missing the application refuses to start — this prevents accidental
deployment without proper configuration (fail-safe).
"""

from __future__ import annotations

import logging
import os

from pydantic_settings import BaseSettings

logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    """Application settings — loaded once at startup."""

    # ── Database ──────────────────────────────────────────────────────
    database_url: str

    # ── Gemini AI ─────────────────────────────────────────────────────
    gemini_api_key: str
    embedding_model: str = "gemini-embedding-001"
    embedding_dimensions: int = 768
    generation_model: str = "gemini-2.5-flash"
    live_model: str = "gemini-3.1-flash-live-preview"
    live_voice_name: str = "Aoede"

    # ── CORS ──────────────────────────────────────────────────────────
    # TODO(security): Restrict CORS_ORIGINS to specific trusted domains in production.
    # For the current MVP/test deployment, Flutter Web may be served from
    # localhost, 0.0.0.0, a LAN IP, or a temporary dev-server host.
    cors_origins: str = "*"
    cors_origin_regex: str = r"https?://.*"

    # ── Rate limiting ─────────────────────────────────────────────────
    rate_limit: str = "30/minute"

    # ── Server ────────────────────────────────────────────────────────
    host: str = "127.0.0.1"
    port: int = 8000

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


def get_settings() -> Settings:
    """Return a validated Settings instance, failing fast on missing secrets."""
    try:
        return Settings()  # type: ignore[call-arg]
    except Exception as exc:
        logger.critical(
            "Failed to load settings. Ensure all required environment "
            "variables are set (see .env.example): %s",
            exc,
        )
        raise
