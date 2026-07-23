"""GraphQL geospatial queries."""
import strawberry
from typing import List, Optional
from sqlalchemy import select, create_engine

from app.database import engine
from sqlalchemy.orm import sessionmaker
from app.config import get_settings
from app.models.entities import Entity, EntityLabel
from app.models.kinds import EntityKind
from app.models.geo import EntityGeo
# Note: EntityGeo is in meta schema

from .types import EntityKind as EntityKindType, GeoLocation

# Create sync engine
settings = get_settings()
sync_url = settings.DATABASE_URL.replace("+asyncpg", "")
_sync_engine = create_engine(sync_url, echo=False)
_sync_session_maker = sessionmaker(bind=_sync_engine)


def get_sync_session():
    return _sync_session_maker()


@strawberry.type
class GeoQuery:
    @strawberry.field
    async def entities_near(
        self,
        latitude: float,
        longitude: float,
        radius_km: float = 10.0,
        limit: int = 50,
    ) -> List[GeoLocation]:
        """Find entities near a location."""
        session = get_sync_session()
        try:
            result = session.execute(select(EntityGeo))
            geo_locations = result.scalars().all()
            
            nearby = []
            for geo in geo_locations:
                distance = geo.distance_to(latitude, longitude)
                if distance <= radius_km * 1000:
                    entity_result = session.execute(
                        select(Entity, EntityKind).join(
                            EntityKind, EntityKind.kind_id == Entity.kind_id
                        ).where(Entity.entity_id == geo.entity_id)
                    )
                    row = entity_result.first()
                    if row:
                        entity, kind = row
                        label_result = session.execute(
                            select(EntityLabel.label).where(
                                EntityLabel.entity_id == entity.entity_id,
                                EntityLabel.is_primary == True
                            ).limit(1)
                        )
                        label = label_result.scalar_one_or_none()
                        
                        nearby.append(GeoLocation(
                            entity_id=str(entity.entity_id),
                            entity_code=entity.entity_code,
                            latitude=geo.latitude,
                            longitude=geo.longitude,
                            altitude=geo.altitude,
                            accuracy=geo.accuracy,
                            geo_type=geo.geo_type,
                            description=geo.description,
                            kind=EntityKindType(
                                kind_id=str(kind.kind_id),
                                kind_code=kind.kind_code,
                                description=kind.description,
                                is_abstract=kind.is_abstract,
                                sort_order=kind.sort_order,
                            ) if kind else None,
                            label=label or entity.entity_code,
                        ))
            
            return nearby[:limit]
        finally:
            session.close()
    
    @strawberry.field
    async def entities_in_bounds(
        self,
        north: float,
        south: float,
        east: float,
        west: float,
        limit: int = 100,
    ) -> List[GeoLocation]:
        """Find entities within geographic bounds."""
        session = get_sync_session()
        try:
            result = session.execute(
                select(EntityGeo).where(
                    EntityGeo.latitude >= south,
                    EntityGeo.latitude <= north,
                    EntityGeo.longitude >= west,
                    EntityGeo.longitude <= east,
                ).limit(limit)
            )
            geo_locations = result.scalars().all()
            
            entities = []
            for geo in geo_locations:
                entity_result = session.execute(
                    select(Entity, EntityKind).join(
                        EntityKind, EntityKind.kind_id == Entity.kind_id
                    ).where(Entity.entity_id == geo.entity_id)
                )
                row = entity_result.first()
                if row:
                    entity, kind = row
                    label_result = session.execute(
                        select(EntityLabel.label).where(
                            EntityLabel.entity_id == entity.entity_id,
                            EntityLabel.is_primary == True
                        ).limit(1)
                    )
                    label = label_result.scalar_one_or_none()
                    
                    entities.append(GeoLocation(
                        entity_id=str(entity.entity_id),
                        entity_code=entity.entity_code,
                        latitude=geo.latitude,
                        longitude=geo.longitude,
                        altitude=geo.altitude,
                        accuracy=geo.accuracy,
                        geo_type=geo.geo_type,
                        description=geo.description,
                        kind=EntityKindType(
                            kind_id=str(kind.kind_id),
                            kind_code=kind.kind_code,
                            description=kind.description,
                            is_abstract=kind.is_abstract,
                            sort_order=kind.sort_order,
                        ) if kind else None,
                        label=label or entity.entity_code,
                    ))
            
            return entities
        finally:
            session.close()
    
    @strawberry.field
    async def all_geo_locations(self) -> List[GeoLocation]:
        """Get all entities with geospatial data."""
        session = get_sync_session()
        try:
            result = session.execute(select(EntityGeo))
            geo_locations = result.scalars().all()
            
            entities = []
            for geo in geo_locations:
                entity_result = session.execute(
                    select(Entity, EntityKind).join(
                        EntityKind, EntityKind.kind_id == Entity.kind_id
                    ).where(Entity.entity_id == geo.entity_id)
                )
                row = entity_result.first()
                if row:
                    entity, kind = row
                    label_result = session.execute(
                        select(EntityLabel.label).where(
                            EntityLabel.entity_id == entity.entity_id,
                            EntityLabel.is_primary == True
                        ).limit(1)
                    )
                    label = label_result.scalar_one_or_none()
                    
                    entities.append(GeoLocation(
                        entity_id=str(entity.entity_id),
                        entity_code=entity.entity_code,
                        latitude=geo.latitude,
                        longitude=geo.longitude,
                        altitude=geo.altitude,
                        accuracy=geo.accuracy,
                        geo_type=geo.geo_type,
                        description=geo.description,
                        kind=EntityKindType(
                            kind_id=str(kind.kind_id),
                            kind_code=kind.kind_code,
                            description=kind.description,
                            is_abstract=kind.is_abstract,
                            sort_order=kind.sort_order,
                        ) if kind else None,
                        label=label or entity.entity_code,
                    ))
            
            return entities
        finally:
            session.close()
