import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Text, Integer
from sqlalchemy.dialects.postgresql import UUID, JSONB
from app.database import Base


class FieldRegistry(Base):
    __tablename__ = "field_registry"
    __table_args__ = {"schema": "meta"}

    field_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    field_key = Column(String, unique=True, nullable=False)
    field_label = Column(String, nullable=False)
    field_type = Column(String, nullable=False, default="string")
    category = Column(String, nullable=False, default="common")
    default_value = Column(Text)
    options = Column(JSONB, default=[])
    sort_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
