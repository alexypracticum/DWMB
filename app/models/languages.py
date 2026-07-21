"""
Language model — справочник языков для мультиязычности.

Заменяет ENUM language_code на динамическую таблицу.
Позволяет добавлять новые языки без миграции БД.
"""

import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, Integer, DateTime
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class Language(Base):
    """Справочник языков."""
    
    __tablename__ = "language"
    __table_args__ = {"schema": "meta"}

    language_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    code = Column(String(10), unique=True, nullable=False, index=True)
    name = Column(String(100), nullable=False)
    native_name = Column(String(100))
    is_active = Column(Boolean, default=True)
    sort_order = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    def __str__(self) -> str:
        return f"{self.name} ({self.code})"
