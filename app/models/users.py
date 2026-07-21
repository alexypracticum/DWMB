import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base


class UserAccount(Base):
    __tablename__ = "user_account"
    __table_args__ = {"schema": "meta"}

    user_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String, unique=True, nullable=False)
    email = Column(String)
    display_name = Column(String)
    password_hash = Column(String)
    auth_provider = Column(String, default="local")
    external_id = Column(String)
    is_active = Column(Boolean, default=True)
    is_admin = Column(Boolean, default=False)
    phone = Column(String)
    bio = Column(Text)
    avatar_url = Column(String)
    language_id = Column(UUID(as_uuid=True), ForeignKey("meta.language.language_id"))
    theme_id = Column(UUID(as_uuid=True), ForeignKey("meta.user_theme.theme_id"))
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    entities = relationship("Entity", back_populates="owner")
    themes = relationship("UserTheme", back_populates="user", foreign_keys="UserTheme.user_id")
    roles = relationship("Role", secondary="meta.user_role", back_populates="users")
    language = relationship("Language", foreign_keys=[language_id])
