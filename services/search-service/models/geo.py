"""
Geospatial model for DWMB.
Stores latitude/longitude coordinates for entities.
"""
from sqlalchemy import Column, Float, String, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from app.models import Base


class EntityGeo(Base):
    """Geospatial data for entities."""
    __tablename__ = "entity_geo"
    __table_args__ = {"schema": "meta"}
    
    entity_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity.entity_id"), primary_key=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    altitude = Column(Float, nullable=True)
    accuracy = Column(Float, nullable=True)
    geo_type = Column(String(50), nullable=True)
    geo_data = Column(Text, nullable=True)
    description = Column(Text, nullable=True)
    
    def distance_to(self, lat: float, lng: float) -> float:
        """Calculate distance to another point using Haversine formula."""
        import math
        
        R = 6371000  # Earth's radius in meters
        
        lat1 = math.radians(self.latitude)
        lat2 = math.radians(lat)
        dlat = math.radians(lat - self.latitude)
        dlng = math.radians(lng - self.longitude)
        
        a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlng/2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
        
        return R * c
