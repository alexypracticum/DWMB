"""
User favorites model.
"""
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class UserFavorite(Base):
    __tablename__ = "user_favorite"
    __table_args__ = (
        UniqueConstraint("user_id", "entity_id", name="uq_user_favorite"),
        {"schema": "meta"},
    )

    favorite_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("meta.user_account.user_id"), nullable=False)
    entity_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity.entity_id"), nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
