import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Text, ForeignKey, Integer
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from app.database import Base


class PageRegistry(Base):
    __tablename__ = "page_registry"
    __table_args__ = {"schema": "meta"}

    page_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    page_code = Column(String, unique=True, nullable=False)
    title = Column(String, nullable=False)
    title_en = Column(String)
    template_name = Column(String, nullable=False, default="default")
    content = Column(JSONB, default={})
    meta_title = Column(String)
    meta_description = Column(String)
    is_published = Column(Boolean, default=False)
    sort_order = Column(Integer, default=0)
    created_by = Column(UUID(as_uuid=True), ForeignKey("meta.user_account.user_id"))
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class MenuItem(Base):
    __tablename__ = "menu_item"
    __table_args__ = {"schema": "meta"}

    menu_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    parent_id = Column(UUID(as_uuid=True), ForeignKey("meta.menu_item.menu_id", ondelete="CASCADE"))
    menu_code = Column(String, nullable=False, default="main")
    label = Column(String, nullable=False)
    label_en = Column(String)
    url = Column(String)
    icon = Column(String)
    sort_order = Column(Integer, default=0)
    is_visible = Column(Boolean, default=True)
    required_role = Column(String)
    css_class = Column(String)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    parent = relationship("MenuItem", remote_side=[menu_id], backref="children")
