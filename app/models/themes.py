import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from app.database import Base


class UserTheme(Base):
    __tablename__ = "user_theme"
    __table_args__ = {"schema": "meta"}

    theme_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("meta.user_account.user_id", ondelete="CASCADE"), nullable=False)
    theme_name = Column(String, nullable=False)
    is_dark = Column(Boolean, default=False)
    is_active = Column(Boolean, default=False)
    is_system = Column(Boolean, default=False)
    colors = Column(JSONB, nullable=False, default={
        "primary": "#3b82f6",
        "secondary": "#6366f1",
        "accent": "#f59e0b",
        "background": "#ffffff",
        "surface": "#f9fafb",
        "text": "#111827",
        "text_secondary": "#6b7280",
        "border": "#e5e7eb",
        "error": "#ef4444",
        "success": "#10b981",
    })
    fonts = Column(JSONB, nullable=False, default={
        "heading": "Inter, sans-serif",
        "body": "Inter, sans-serif",
        "mono": "JetBrains Mono, monospace",
        "heading_size": "1.5rem",
        "body_size": "0.875rem",
    })
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    user = relationship("UserAccount", back_populates="themes", foreign_keys=[user_id])
