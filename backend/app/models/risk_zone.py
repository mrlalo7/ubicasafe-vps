"""SQLAlchemy model for risk zones."""

from __future__ import annotations

import uuid
from datetime import datetime

from pgvector.sqlalchemy import Vector
from sqlalchemy import DateTime, Double, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.report import Base


class RiskZone(Base):
    """A geographic risk zone with associated danger metadata."""

    __tablename__ = "risk_zones"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    latitude: Mapped[float] = mapped_column(Double, nullable=False)
    longitude: Mapped[float] = mapped_column(Double, nullable=False)
    radius_meters: Mapped[float] = mapped_column(Double, nullable=False)
    risk_level: Mapped[str] = mapped_column(String(20), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    report_count: Mapped[int] = mapped_column(Integer, default=0)
    last_incident_at: Mapped[datetime | None] = mapped_column(
        DateTime, nullable=True
    )

    # pgvector embedding (768-dim for text-embedding-004)
    embedding = mapped_column(Vector(768), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow
    )

    def __repr__(self) -> str:
        return f"<RiskZone {self.name!r} level={self.risk_level!r}>"
