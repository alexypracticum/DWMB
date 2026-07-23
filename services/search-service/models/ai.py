import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Text, ForeignKey, BigInteger, Numeric, Integer, LargeBinary
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from app.database import Base


class AiConfig(Base):
    __tablename__ = "ai_config"
    __table_args__ = {"schema": "meta"}

    config_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    provider = Column(String, nullable=False, default="openai")
    model_embedding = Column(String, nullable=False, default="text-embedding-3-small")
    model_chat = Column(String, nullable=False, default="gpt-4o-mini")
    api_key_enc = Column(LargeBinary)
    api_base_url = Column(String, default="https://api.openai.com/v1")
    max_tokens = Column(Integer, nullable=False, default=4096)
    is_active = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class AiTaskLog(Base):
    __tablename__ = "ai_task_log"
    __table_args__ = {"schema": "meta"}

    task_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    task_type = Column(String, nullable=False)
    model_used = Column(String)
    input_tokens = Column(Integer, default=0)
    output_tokens = Column(Integer, default=0)
    cost_usd = Column(Numeric(10, 6), default=0)
    duration_ms = Column(Integer)
    entity_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity.entity_id"))
    status = Column(String, nullable=False, default="pending")
    error_message = Column(Text)
    payload = Column(JSONB)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class AiSuggestion(Base):
    __tablename__ = "ai_suggestion"
    __table_args__ = {"schema": "meta"}

    suggestion_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    entity_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity.entity_id", ondelete="CASCADE"), nullable=False)
    suggestion_type = Column(String, nullable=False)
    field_key = Column(String)
    suggested_value = Column(JSONB, nullable=False)
    confidence = Column(Numeric(5, 4))
    is_accepted = Column(Boolean)
    reviewed_by = Column(UUID(as_uuid=True), ForeignKey("meta.user_account.user_id"))
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    entity = relationship("Entity", foreign_keys=[entity_id])


class AiConfigProfile(Base):
    __tablename__ = "ai_config_profile"
    __table_args__ = {"schema": "meta"}

    profile_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_name = Column(String, nullable=False)
    is_active = Column(Boolean, default=False)
    provider = Column(String, default="openai")
    model_embedding = Column(String, default="text-embedding-3-small")
    model_chat = Column(String, default="gpt-4o-mini")
    api_key_enc = Column(LargeBinary)
    api_base_url = Column(String, default="https://api.openai.com/v1")
    max_tokens = Column(Integer, default=4096)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
