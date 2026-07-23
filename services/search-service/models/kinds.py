import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Text, ForeignKey, BigInteger, Integer
from sqlalchemy.dialects.postgresql import UUID, ENUM as PG_ENUM, JSONB
from sqlalchemy.orm import relationship
from app.database import Base


class EntityKind(Base):
    __tablename__ = "entity_kind"
    __table_args__ = {"schema": "meta"}

    kind_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    kind_code = Column(String, unique=True, nullable=False)
    parent_kind_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity_kind.kind_id"))
    description = Column(Text)
    is_abstract = Column(Boolean, default=False)
    sort_order = Column(Integer, default=0)
    field_schema = Column(JSONB, default=list)
    version_id = Column(BigInteger, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    parent = relationship("EntityKind", remote_side=[kind_id], backref="children")
    entities = relationship("Entity", back_populates="kind")
    labels = relationship("EntityKindLabel", back_populates="kind", cascade="all, delete-orphan")

    def __str__(self):
        return self.kind_code or str(self.kind_id)


class EntityKindLabel(Base):
    __tablename__ = "entity_kind_label"
    __table_args__ = {"schema": "meta"}

    kind_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity_kind.kind_id", ondelete="CASCADE"), primary_key=True)
    language_id = Column(UUID(as_uuid=True), ForeignKey("meta.language.language_id"), primary_key=True)
    label = Column(String, nullable=False)
    description = Column(Text)

    kind = relationship("EntityKind", back_populates="labels")
    language = relationship("Language", foreign_keys=[language_id])


class EntityKindRelationConstraint(Base):
    __tablename__ = "entity_kind_relation_constraint"
    __table_args__ = {"schema": "meta"}

    constraint_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    from_kind_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity_kind.kind_id"), nullable=False)
    relation_code = Column(String, nullable=False)
    to_kind_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity_kind.kind_id"), nullable=False)
    is_allowed = Column(Boolean, default=True)
    description = Column(Text)


class EntityKindOntology(Base):
    __tablename__ = "entity_kind_ontology"
    __table_args__ = {"schema": "meta"}

    kind_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity_kind.kind_id", ondelete="CASCADE"), primary_key=True)
    model_id = Column(UUID(as_uuid=True), ForeignKey("meta.ontology_model.model_id", ondelete="CASCADE"), primary_key=True)
    is_primary = Column(Boolean, default=False)

    kind = relationship("EntityKind", foreign_keys=[kind_id])
    model = relationship("OntologyModel", foreign_keys=[model_id])
