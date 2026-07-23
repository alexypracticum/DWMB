import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Text, ForeignKey, BigInteger, Numeric, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID, JSONB, ENUM as PG_ENUM
from sqlalchemy.orm import relationship
from app.database import Base


class RelationType(Base):
    __tablename__ = "relation_type"
    __table_args__ = {"schema": "meta"}

    relation_type_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    relation_code = Column(String, unique=True, nullable=False)
    relation_name = Column(String, nullable=False)
    description = Column(Text)
    from_kind_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity_kind.kind_id"))
    to_kind_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity_kind.kind_id"))
    directionality = Column(PG_ENUM("directed", "undirected", name="relation_direction", schema="meta", create_type=False), nullable=False)
    transitive_relation = Column(Boolean, default=False)
    symmetric_relation = Column(Boolean, default=False)
    inverse_type_id = Column(UUID(as_uuid=True), ForeignKey("meta.relation_type.relation_type_id"))
    version_id = Column(BigInteger, nullable=False)

    from_kind = relationship("EntityKind", foreign_keys=[from_kind_id])
    to_kind = relationship("EntityKind", foreign_keys=[to_kind_id])
    source_relations = relationship("SemanticRelation", foreign_keys="SemanticRelation.relation_type_id", back_populates="relation_type")


class SemanticRelation(Base):
    __tablename__ = "semantic_relation"
    __table_args__ = (
        CheckConstraint("source_projection_id <> target_projection_id", name="check_no_self_relation"),
        {"schema": "meta"},
    )

    relation_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    source_projection_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity_projection.projection_id", ondelete="CASCADE"), nullable=False)
    relation_type_id = Column(UUID(as_uuid=True), ForeignKey("meta.relation_type.relation_type_id"), nullable=False)
    target_projection_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity_projection.projection_id", ondelete="CASCADE"), nullable=False)
    context_id = Column(UUID(as_uuid=True), ForeignKey("meta.context.context_id"))
    weight = Column(Numeric(6, 5))
    confidence = Column(Numeric(6, 5))
    metadata_ = Column("metadata", JSONB, default={})
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    valid_from = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    valid_to = Column(DateTime(timezone=True))
    version_id = Column(BigInteger, nullable=False)

    source_projection = relationship("EntityProjection", foreign_keys=[source_projection_id], back_populates="source_relations")
    target_projection = relationship("EntityProjection", foreign_keys=[target_projection_id], back_populates="target_relations")
    relation_type = relationship("RelationType", back_populates="source_relations")
