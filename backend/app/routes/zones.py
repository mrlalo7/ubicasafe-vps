"""Risk zones endpoints — list and seed from the original Dart data."""

from __future__ import annotations

import logging
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.connection import get_session
from app.models.risk_zone import RiskZone

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/zones", tags=["zones"])


class ZoneResponse(BaseModel):
    """Output schema for a risk zone."""

    id: UUID
    name: str
    latitude: float
    longitude: float
    radius_meters: float
    risk_level: str
    description: str
    report_count: int

    class Config:
        from_attributes = True


@router.get("/", response_model=list[ZoneResponse])
async def list_zones(
    risk_level: str | None = None,
    session: AsyncSession = Depends(get_session),
) -> list[RiskZone]:
    """List all risk zones, optionally filtered by risk level."""
    _VALID_LEVELS = {"low", "medium", "high"}

    stmt = select(RiskZone).order_by(RiskZone.risk_level.desc())

    if risk_level:
        if risk_level.lower() not in _VALID_LEVELS:
            raise HTTPException(400, f"risk_level must be one of {_VALID_LEVELS}")
        stmt = stmt.where(RiskZone.risk_level == risk_level.lower())

    result = await session.execute(stmt)
    return list(result.scalars().all())


@router.get("/{zone_id}", response_model=ZoneResponse)
async def get_zone(
    zone_id: UUID,
    session: AsyncSession = Depends(get_session),
) -> RiskZone:
    """Get a single risk zone by ID."""
    result = await session.execute(
        select(RiskZone).where(RiskZone.id == zone_id)
    )
    zone = result.scalar_one_or_none()
    if not zone:
        raise HTTPException(404, "Zone not found")
    return zone
