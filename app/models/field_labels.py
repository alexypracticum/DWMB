import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base


class FieldRegistryLabel(Base):
    __tablename__ = "field_registry_label"
    __table_args__ = {"schema": "meta"}

    field_id = Column(UUID(as_uuid=True), ForeignKey("meta.field_registry.field_id", ondelete="CASCADE"), primary_key=True)
    language_id = Column(UUID(as_uuid=True), ForeignKey("meta.language.language_id"), primary_key=True)
    label = Column(String, nullable=False)
    description = Column(Text)

    field = relationship("FieldRegistry", foreign_keys=[field_id])
    language = relationship("Language", foreign_keys=[language_id])
