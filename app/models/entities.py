import uuid
import enum
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Text, ForeignKey, BigInteger, Numeric, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID, JSONB, ENUM as PG_ENUM
from sqlalchemy.orm import relationship
from app.database import Base


class EntityStatus(str, enum.Enum):
    active = "active"
    deprecated = "deprecated"
    deleted = "deleted"


class VersionRegistry(Base):
    __tablename__ = "version_registry"
    __table_args__ = {"schema": "meta"}

    version_id = Column(BigInteger, primary_key=True, autoincrement=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(String, default="system")
    description = Column(Text)


class SourceSystem(Base):
    __tablename__ = "source_system"
    __table_args__ = {"schema": "meta"}

    source_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    source_code = Column(String, unique=True, nullable=False)
    description = Column(Text)
    is_trusted = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class ImportBatch(Base):
    __tablename__ = "import_batch"
    __table_args__ = {"schema": "meta"}

    batch_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    source_id = Column(UUID(as_uuid=True), ForeignKey("meta.source_system.source_id"))
    batch_code = Column(String)
    started_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    finished_at = Column(DateTime(timezone=True))
    items_total = Column(BigInteger)
    items_success = Column(BigInteger)
    items_failed = Column(BigInteger)
    error_log = Column(JSONB, default=[])


class Context(Base):
    __tablename__ = "context"
    __table_args__ = {"schema": "meta"}

    context_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    parent_context_id = Column(UUID(as_uuid=True), ForeignKey("meta.context.context_id"))
    context_code = Column(String, unique=True, nullable=False)
    context_name = Column(String)
    description = Column(Text)
    rules = Column(JSONB, default={})
    valid_from = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    valid_to = Column(DateTime(timezone=True))
    version_id = Column(BigInteger, nullable=False)


class Entity(Base):
    __tablename__ = "entity"
    __table_args__ = {"schema": "meta"}

    entity_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    entity_code = Column(String, nullable=False, index=True)
    kind_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity_kind.kind_id"), nullable=False)
    status = Column(PG_ENUM("active", "deprecated", "deleted", name="entity_status", schema="meta", create_type=False), default="active")
    source_id = Column(UUID(as_uuid=True), ForeignKey("meta.source_system.source_id"))
    batch_id = Column(UUID(as_uuid=True), ForeignKey("meta.import_batch.batch_id"))
    owner_id = Column(UUID(as_uuid=True), ForeignKey("meta.user_account.user_id"))
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    valid_from = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    valid_to = Column(DateTime(timezone=True))
    version_id = Column(BigInteger, nullable=False)

    kind = relationship("EntityKind", back_populates="entities")
    labels = relationship("EntityLabel", back_populates="entity", cascade="all, delete-orphan")
    projections = relationship("EntityProjection", back_populates="entity", cascade="all, delete-orphan")
    owner = relationship("UserAccount", back_populates="entities")
    media = relationship("MediaAsset", back_populates="entity")


class EntityLabel(Base):
    __tablename__ = "entity_label"
    __table_args__ = (
        {"schema": "meta"},
    )

    entity_label_id = Column(BigInteger, primary_key=True, autoincrement=True)
    entity_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity.entity_id", ondelete="CASCADE"), nullable=False)
    language = Column(PG_ENUM("en", "ru", "de", "fr", "es", "zh", "ja", name="language_code", schema="meta", create_type=False), nullable=False)
    label = Column(String, nullable=False)
    description = Column(Text)
    content = Column(Text)
    is_primary = Column(Boolean, default=False)
    owner_id = Column(UUID(as_uuid=True), ForeignKey("meta.user_account.user_id"))
    version_id = Column(BigInteger, nullable=False)

    entity = relationship("Entity", back_populates="labels")


class MediaAsset(Base):
    __tablename__ = "media_asset"
    __table_args__ = {"schema": "meta"}

    asset_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    entity_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity.entity_id"))
    original_name = Column(String, nullable=False)
    mime_type = Column(String, nullable=False)
    size_bytes = Column(BigInteger)
    file_hash = Column(String, unique=True, nullable=False)
    storage_backend = Column(PG_ENUM("local", "nfs", "s3", name="storage_backend", schema="meta", create_type=False), default="local")
    storage_key = Column(String, nullable=False)
    width = Column(BigInteger)
    height = Column(BigInteger)
    duration_secs = Column(Numeric(10, 3))
    metadata_ = Column("metadata", JSONB, default={})
    is_processed = Column(Boolean, default=False)
    processing_log = Column(Text)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    version_id = Column(BigInteger, nullable=False)

    entity = relationship("Entity", back_populates="media")


class EventLog(Base):
    __tablename__ = "event_log"
    __table_args__ = {"schema": "meta"}

    event_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    entity_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity.entity_id"))
    projection_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity_projection.projection_id"))
    relation_id = Column(UUID(as_uuid=True), ForeignKey("meta.semantic_relation.relation_id"))
    asset_id = Column(UUID(as_uuid=True), ForeignKey("meta.media_asset.asset_id"))
    event_type = Column(PG_ENUM("create", "update", "delete", "merge", "split", "state_transition", "relation_change", name="event_kind", schema="meta", create_type=False), nullable=False)
    payload = Column(JSONB, default={})
    caused_by = Column(String)
    occurred_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    version_id = Column(BigInteger, nullable=False)
