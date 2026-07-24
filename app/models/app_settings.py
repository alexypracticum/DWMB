"""AppSetting model — runtime configuration stored in database."""
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, DateTime
from sqlalchemy.dialects.postgresql import UUID, JSONB
from app.database import Base


class AppSetting(Base):
    __tablename__ = "app_setting"
    __table_args__ = {"schema": "meta"}

    setting_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    key = Column(String, unique=True, nullable=False)
    value = Column(JSONB, nullable=False)
    description = Column(Text)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    updated_by = Column(String)
