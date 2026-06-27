"""Statistics endpoints — real-time aggregations from the database."""

from __future__ import annotations

from datetime import datetime, timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.connection import get_session
from app.models.report import Report
from app.models.risk_zone import RiskZone

router = APIRouter(prefix="/api/stats", tags=["stats"])


@router.get("/summary")
async def summary(
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Dashboard summary: counts, most dangerous zone, trends."""
    now = datetime.utcnow()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_ago = now - timedelta(days=7)

    # Total reports today
    result = await session.execute(
        select(func.count(Report.id)).where(
            Report.created_at >= today_start
        )
    )
    reports_today = result.scalar() or 0

    # Total reports this week
    result = await session.execute(
        select(func.count(Report.id)).where(
            Report.created_at >= week_ago
        )
    )
    reports_week = result.scalar() or 0

    # Total reports all time
    result = await session.execute(select(func.count(Report.id)))
    reports_total = result.scalar() or 0

    # Breakdown by type
    result = await session.execute(
        select(Report.report_type, func.count(Report.id))
        .group_by(Report.report_type)
    )
    by_type = {row[0]: row[1] for row in result.all()}

    # Most dangerous zone (by report_count)
    result = await session.execute(
        select(RiskZone.name, RiskZone.risk_level, RiskZone.report_count)
        .order_by(RiskZone.report_count.desc())
        .limit(1)
    )
    top_zone = result.first()
    most_dangerous = {
        "name": top_zone[0] if top_zone else "Sin datos",
        "risk_level": top_zone[1] if top_zone else "unknown",
        "report_count": top_zone[2] if top_zone else 0,
    }

    # Violence level breakdown
    result = await session.execute(
        select(Report.violence_level, func.count(Report.id))
        .group_by(Report.violence_level)
    )
    by_violence = {row[0]: row[1] for row in result.all()}

    return {
        "reports_today": reports_today,
        "reports_week": reports_week,
        "reports_total": reports_total,
        "by_type": by_type,
        "by_violence": by_violence,
        "most_dangerous_zone": most_dangerous,
    }


@router.get("/by-zone")
async def stats_by_zone(
    session: AsyncSession = Depends(get_session),
) -> list[dict]:
    """Report counts grouped by risk zone."""
    result = await session.execute(
        select(
            RiskZone.name,
            RiskZone.risk_level,
            RiskZone.report_count,
            RiskZone.latitude,
            RiskZone.longitude,
        ).order_by(RiskZone.report_count.desc())
    )
    return [
        {
            "name": row[0],
            "risk_level": row[1],
            "report_count": row[2],
            "latitude": row[3],
            "longitude": row[4],
        }
        for row in result.all()
    ]
