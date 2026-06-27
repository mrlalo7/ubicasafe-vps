"""Seed initial risk zones from the original Dart data.

Usage:
    cd backend
    python -m app.seed
"""

from __future__ import annotations

import asyncio
import logging

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.connection import async_session_factory, engine
from app.models import Base, RiskZone
from app.services.embedding_service import build_zone_text, generate_embedding

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ── 24 risk zones from risk_zones.dart ────────────────────────────────
INITIAL_ZONES = [
    # High risk
    {"name": "UPEA - Universidad Pública de El Alto", "latitude": -16.491033, "longitude": -68.193479, "radius_meters": 400, "risk_level": "high", "description": "Sede principal de la UPEA. Múltiples reportes de robos en los alrededores."},
    {"name": "Puente Vela", "latitude": -16.5975, "longitude": -68.1842, "radius_meters": 250, "risk_level": "high", "description": "Peligroso a partir de las 8:00 pm en adelante."},
    {"name": "Zona 12 de Octubre", "latitude": -16.5118, "longitude": -68.1632, "radius_meters": 149, "risk_level": "high", "description": "Zona peligrosa por múltiples reportes a partir de las 8:00 pm."},
    {"name": "La Ceja de El Alto", "latitude": -16.5034, "longitude": -68.1625, "radius_meters": 180, "risk_level": "high", "description": "Zona comercial principal. ALTO RIESGO en el Pasaje Artesanal y áreas aledañas."},
    {"name": "Feria 16 de Julio", "latitude": -16.4942, "longitude": -68.1736, "radius_meters": 450, "risk_level": "high", "description": "Alta incidencia de robos por distracción en aglomeraciones."},
    {"name": "Terminal Metropolitana", "latitude": -16.52073, "longitude": -68.17723, "radius_meters": 380, "risk_level": "high", "description": "Terminal con alta afluencia. Reportes frecuentes de asaltos."},
    {"name": "Senkata", "latitude": -16.5702, "longitude": -68.1862, "radius_meters": 380, "risk_level": "high", "description": "Lugar alejado. Reportes frecuentes de robos."},
    {"name": "Terminal de Buses Río Seco", "latitude": -16.4878, "longitude": -68.2002, "radius_meters": 350, "risk_level": "high", "description": "Zona de terminal con alta incidencia delictiva."},
    {"name": "Avenida 6 de Marzo", "latitude": -16.5059, "longitude": -68.1631, "radius_meters": 100, "risk_level": "high", "description": "Múltiples reportes de robos al paso."},
    # Medium risk
    {"name": "Mercado Satélite", "latitude": -16.5247, "longitude": -68.1506, "radius_meters": 280, "risk_level": "medium", "description": "Robos ocasionales por distracción."},
    {"name": "Plaza La Paz", "latitude": -16.4919, "longitude": -68.1832, "radius_meters": 250, "risk_level": "medium", "description": "Incidentes esporádicos en horarios de menor tránsito."},
    {"name": "Estacion Teleferico Azul", "latitude": -16.4893, "longitude": -68.1931, "radius_meters": 250, "risk_level": "medium", "description": "Zona transitada, precauciones en la noche."},
    {"name": "Universidad Franz Tamayo (UNIFRANZ)", "latitude": -16.5085, "longitude": -68.1663, "radius_meters": 200, "risk_level": "medium", "description": "Concurrencia universitaria."},
    {"name": "Universidad Técnica Privada Cosmos", "latitude": -16.5245, "longitude": -68.2131, "radius_meters": 200, "risk_level": "medium", "description": "Concurrencia universitaria."},
    {"name": "Universidad Salesiana de Bolivia (USB)", "latitude": -16.4770, "longitude": -68.1487, "radius_meters": 200, "risk_level": "medium", "description": "Concurrencia universitaria."},
    {"name": "Villa Dolores", "latitude": -16.5072, "longitude": -68.1608, "radius_meters": 260, "risk_level": "medium", "description": "Zona comercial y de alto tránsito. Riesgo moderado por robos al paso y aglomeraciones."},
    {"name": "Ballivian", "latitude": -16.4893, "longitude": -68.1805, "radius_meters": 250, "risk_level": "medium", "description": "Zona transitada."},
    {"name": "Estadio Municipal de El Alto", "latitude": -16.4713, "longitude": -68.2018, "radius_meters": 250, "risk_level": "medium", "description": "Zona transitada, precauciones los días de partido."},
    {"name": "Cementerio General Mercedario", "latitude": -16.5292, "longitude": -68.2481, "radius_meters": 250, "risk_level": "medium", "description": "Zona transitada, evitar la noche."},
    {"name": "Achocalla", "latitude": -16.4500, "longitude": -68.1200, "radius_meters": 300, "risk_level": "medium", "description": "Área periurbana con riesgo medio."},
    # Low risk
    {"name": "Alto Lima", "latitude": -16.4765, "longitude": -68.1751, "radius_meters": 350, "risk_level": "low", "description": "Urbanización. Seguridad y baja incidencia."},
    {"name": "Villa Ingenio", "latitude": -16.4750, "longitude": -68.2000, "radius_meters": 400, "risk_level": "low", "description": "Zona residencial tranquila."},
    {"name": "Rio seco", "latitude": -16.4868, "longitude": -68.2086, "radius_meters": 380, "risk_level": "low", "description": "Zona residencial organizada. Vigilancia vecinal."},
    {"name": "Ciudad Satélite", "latitude": -16.5282, "longitude": -68.1542, "radius_meters": 380, "risk_level": "low", "description": "Zona residencial organizada. Vigilancia vecinal."},
    {"name": "Estacion Linea Morada", "latitude": -16.5221, "longitude": -68.1694, "radius_meters": 380, "risk_level": "low", "description": "Zona transitada pero con vigilancia."},
]


async def seed_zones() -> None:
    """Insert all zones and generate their embeddings."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_session_factory() as session:
        result = await session.execute(select(RiskZone))
        existing_by_name = {zone.name: zone for zone in result.scalars().all()}
        inserted = 0
        updated = 0

        for zone_data in INITIAL_ZONES:
            existing_zone = existing_by_name.get(zone_data["name"])
            if existing_zone is not None and existing_zone.embedding is not None:
                continue

            text = build_zone_text(**zone_data)
            try:
                embedding = await generate_embedding(text)
            except Exception:
                logger.warning("Failed to embed zone %s", zone_data["name"])
                embedding = None

            if existing_zone is not None:
                existing_zone.embedding = embedding
                existing_zone.latitude = zone_data["latitude"]
                existing_zone.longitude = zone_data["longitude"]
                existing_zone.radius_meters = zone_data["radius_meters"]
                existing_zone.risk_level = zone_data["risk_level"]
                existing_zone.description = zone_data["description"]
                updated += 1
                logger.info(
                    "Updated zone: %s (%s)",
                    zone_data["name"],
                    zone_data["risk_level"],
                )
                continue

            zone = RiskZone(
                name=zone_data["name"],
                latitude=zone_data["latitude"],
                longitude=zone_data["longitude"],
                radius_meters=zone_data["radius_meters"],
                risk_level=zone_data["risk_level"],
                description=zone_data["description"],
                embedding=embedding,
            )
            session.add(zone)
            inserted += 1
            logger.info("Seeded zone: %s (%s)", zone_data["name"], zone_data["risk_level"])

        await session.commit()
        logger.info(
            "✅ Successfully seeded %d new risk zones and updated %d zones",
            inserted,
            updated,
        )


if __name__ == "__main__":
    asyncio.run(seed_zones())
