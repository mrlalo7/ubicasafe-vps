"""CRUD endpoints for incident reports."""

from __future__ import annotations

import logging
import math
from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field, field_validator
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.connection import get_session
from app.models.report import Report
from app.models.risk_zone import RiskZone
from app.services.embedding_service import build_report_text, generate_embedding

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/reports", tags=["reports"])

# ── Allowed values (allow-list validation) ────────────────────────────
_VALID_REPORT_TYPES = {"Robo a Persona", "Robo de celular", "Otro"}
_VALID_VIOLENCE_LEVELS = {"Bajo", "Moderado", "Alto", "Extremo"}


def _to_naive_utc(value: datetime | None) -> datetime:
    """Convert incoming datetimes to UTC without tzinfo for PostgreSQL TIMESTAMP."""
    if value is None:
        return datetime.utcnow()
    if value.tzinfo is None:
        return value
    return value.astimezone(timezone.utc).replace(tzinfo=None)


def _distance_meters(
    lat1: float,
    lon1: float,
    lat2: float,
    lon2: float,
) -> float:
    """Approximate distance between two coordinates using haversine."""
    radius = 6371000
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    a = (
        math.sin(delta_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2
    )
    return radius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


async def _find_related_zone(
    session: AsyncSession,
    location_text: str,
    latitude: float | None,
    longitude: float | None,
) -> RiskZone | None:
    """Match a report to a known risk zone by text first, then coordinates."""
    result = await session.execute(select(RiskZone))
    zones = list(result.scalars().all())
    if not zones:
        return None

    normalized_location = location_text.lower()
    for zone in zones:
        if zone.name.lower() in normalized_location:
            return zone

    if latitude is None or longitude is None:
        return None

    nearest: tuple[RiskZone, float] | None = None
    for zone in zones:
        distance = _distance_meters(latitude, longitude, zone.latitude, zone.longitude)
        if distance <= zone.radius_meters and (
            nearest is None or distance < nearest[1]
        ):
            nearest = (zone, distance)

    return nearest[0] if nearest else None


# ── Pydantic schemas ─────────────────────────────────────────────────
class ReportCreate(BaseModel):
    """Input schema for creating a report. All fields validated."""

    report_type: str = Field(..., max_length=50)
    location_text: str = Field(..., min_length=3, max_length=500)
    latitude: float | None = Field(None, ge=-90, le=90)
    longitude: float | None = Field(None, ge=-180, le=180)
    incident_date: datetime | None = None
    violence_level: str = Field(..., max_length=20)
    had_injuries: bool = False
    had_weapons: bool = False
    weapon_type: str | None = Field(None, max_length=50)
    description: str = Field(..., min_length=5, max_length=5000)
    device_brand: str | None = Field(None, max_length=100)
    device_model: str | None = Field(None, max_length=200)
    device_condition: str | None = Field(None, max_length=100)
    device_color: str | None = Field(None, max_length=50)

    @field_validator("report_type")
    @classmethod
    def validate_report_type(cls, v: str) -> str:
        if v not in _VALID_REPORT_TYPES:
            raise ValueError(
                f"report_type must be one of {_VALID_REPORT_TYPES}"
            )
        return v

    @field_validator("violence_level")
    @classmethod
    def validate_violence_level(cls, v: str) -> str:
        if v not in _VALID_VIOLENCE_LEVELS:
            raise ValueError(
                f"violence_level must be one of {_VALID_VIOLENCE_LEVELS}"
            )
        return v


class ReportResponse(BaseModel):
    """Output schema — never exposes internal embedding vector."""

    id: UUID
    report_type: str
    location_text: str
    latitude: float | None
    longitude: float | None
    incident_date: datetime
    violence_level: str
    had_injuries: bool
    had_weapons: bool
    weapon_type: str | None
    description: str
    device_brand: str | None
    device_model: str | None
    device_condition: str | None
    device_color: str | None
    created_at: datetime

    class Config:
        from_attributes = True


# ── Endpoints ─────────────────────────────────────────────────────────


@router.post("/", response_model=ReportResponse, status_code=201)
async def create_report(
    data: ReportCreate,
    session: AsyncSession = Depends(get_session),
) -> Report:
    """Create a new incident report and generate its embedding."""
    incident_date = _to_naive_utc(data.incident_date)
    report = Report(
        report_type=data.report_type,
        location_text=data.location_text,
        latitude=data.latitude,
        longitude=data.longitude,
        incident_date=incident_date,
        violence_level=data.violence_level,
        had_injuries=data.had_injuries,
        had_weapons=data.had_weapons,
        weapon_type=data.weapon_type,
        description=data.description,
        device_brand=data.device_brand,
        device_model=data.device_model,
        device_condition=data.device_condition,
        device_color=data.device_color,
    )

    # Generate embedding asynchronously
    try:
        text = build_report_text(
            report_type=data.report_type,
            location_text=data.location_text,
            description=data.description,
            violence_level=data.violence_level,
            had_injuries=data.had_injuries,
            had_weapons=data.had_weapons,
            weapon_type=data.weapon_type,
            device_brand=data.device_brand,
        )
        report.embedding = await generate_embedding(text)
    except Exception:
        logger.warning("Failed to generate embedding, saving report without it")

    related_zone = await _find_related_zone(
        session=session,
        location_text=data.location_text,
        latitude=data.latitude,
        longitude=data.longitude,
    )
    if related_zone is not None:
        related_zone.report_count = (related_zone.report_count or 0) + 1
        related_zone.last_incident_at = report.incident_date

    session.add(report)
    try:
        await session.commit()
        await session.refresh(report)
    except Exception:
        await session.rollback()
        logger.exception("Failed to persist report")
        raise
    logger.info("Created report id=%s", report.id)
    return report


@router.get("/", response_model=list[ReportResponse])
async def list_reports(
    report_type: str | None = Query(None, max_length=50),
    violence_level: str | None = Query(None, max_length=20),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    session: AsyncSession = Depends(get_session),
) -> list[Report]:
    """List reports with optional filters. Parameterized — no SQL injection."""
    stmt = select(Report).order_by(Report.incident_date.desc())

    if report_type:
        if report_type not in _VALID_REPORT_TYPES:
            raise HTTPException(400, "Invalid report_type filter")
        stmt = stmt.where(Report.report_type == report_type)

    if violence_level:
        if violence_level not in _VALID_VIOLENCE_LEVELS:
            raise HTTPException(400, "Invalid violence_level filter")
        stmt = stmt.where(Report.violence_level == violence_level)

    stmt = stmt.limit(limit).offset(offset)
    result = await session.execute(stmt)
    return list(result.scalars().all())


@router.get("/{report_id}", response_model=ReportResponse)
async def get_report(
    report_id: UUID,
    session: AsyncSession = Depends(get_session),
) -> Report:
    """Get a single report by ID."""
    result = await session.execute(
        select(Report).where(Report.id == report_id)
    )
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(404, "Report not found")
    return report
