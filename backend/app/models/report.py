"""SQLAlchemy model for incident reports."""

from __future__ import annotations

import uuid
from datetime import datetime

from pgvector.sqlalchemy import Vector
from sqlalchemy import Boolean, DateTime, Double, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    """Shared declarative base for all models."""

    pass


class Report(Base):
    """An incident report submitted from the mobile app."""

    __tablename__ = "reports"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    report_type: Mapped[str] = mapped_column(String(50), nullable=False)
    location_text: Mapped[str] = mapped_column(String(500), nullable=False)
    latitude: Mapped[float | None] = mapped_column(Double, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Double, nullable=True)
    incident_date: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    violence_level: Mapped[str] = mapped_column(String(20), nullable=False)
    had_injuries: Mapped[bool] = mapped_column(Boolean, default=False)
    had_weapons: Mapped[bool] = mapped_column(Boolean, default=False)
    weapon_type: Mapped[str | None] = mapped_column(String(50), nullable=True)
    description: Mapped[str] = mapped_column(Text, nullable=False)

    # Device info (only for phone theft)
    device_brand: Mapped[str | None] = mapped_column(String(100), nullable=True)
    device_model: Mapped[str | None] = mapped_column(String(200), nullable=True)
    device_condition: Mapped[str | None] = mapped_column(
        String(100), nullable=True
    )
    device_color: Mapped[str | None] = mapped_column(String(50), nullable=True)

    # pgvector embedding (768-dim for text-embedding-004)
    embedding = mapped_column(Vector(768), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    def __repr__(self) -> str:
        return f"<Report {self.id!s:.8} type={self.report_type!r}>"
