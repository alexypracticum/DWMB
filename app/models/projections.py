import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Text, ForeignKey, BigInteger, Numeric
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector
from app.database import Base


class OntologyModel(Base):
    __tablename__ = "ontology_model"
    __table_args__ = {"schema": "meta"}

    model_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    model_code = Column(String, unique=True, nullable=False)
    domain = Column(String, nullable=False)
    description = Column(Text)
    version_id = Column(BigInteger, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    templates = relationship("OntologyTemplate", back_populates="model")
    projections = relationship("EntityProjection", back_populates="model")


class OntologyTemplate(Base):
    __tablename__ = "ontology_template"
    __table_args__ = {"schema": "meta"}

    template_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    model_id = Column(UUID(as_uuid=True), ForeignKey("meta.ontology_model.model_id"), nullable=False)
    kind_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity_kind.kind_id"), nullable=True)
    template_code = Column(String, unique=True, nullable=False)
    template_name = Column(String, nullable=False)
    description = Column(Text)
    schema_definition = Column(JSONB, nullable=False)
    layout_definition = Column(JSONB, default=[])
    is_active = Column(Boolean, default=True)
    constraints_definition = Column(JSONB, default={})
    version_id = Column(BigInteger, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    model = relationship("OntologyModel", back_populates="templates")
    projections = relationship("EntityProjection", back_populates="template")


class EntityProjection(Base):
    __tablename__ = "entity_projection"
    __table_args__ = {"schema": "meta"}

    projection_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    entity_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity.entity_id", ondelete="CASCADE"), nullable=False)
    model_id = Column(UUID(as_uuid=True), ForeignKey("meta.ontology_model.model_id"), nullable=False)
    template_id = Column(UUID(as_uuid=True), ForeignKey("meta.ontology_template.template_id"))
    context_id = Column(UUID(as_uuid=True), ForeignKey("meta.context.context_id"))
    projection_code = Column(String, unique=True, nullable=False)
    projection_name = Column(String)
    confidence = Column(Numeric(5, 4))
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    valid_from = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    valid_to = Column(DateTime(timezone=True))
    version_id = Column(BigInteger, nullable=False)

    entity = relationship("Entity", back_populates="projections")
    model = relationship("OntologyModel", back_populates="projections")
    template = relationship("OntologyTemplate", back_populates="projections")
    states = relationship("ProjectionState", back_populates="projection", cascade="all, delete-orphan")
    source_relations = relationship("SemanticRelation", foreign_keys="SemanticRelation.source_projection_id", back_populates="source_projection")
    target_relations = relationship("SemanticRelation", foreign_keys="SemanticRelation.target_projection_id", back_populates="target_projection")


class ProjectionState(Base):
    __tablename__ = "projection_state"
    __table_args__ = {"schema": "meta"}

    state_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    projection_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity_projection.projection_id", ondelete="CASCADE"), nullable=False)
    state_data = Column(JSONB, nullable=False)
    state_hash = Column(String)
    embedding = Column(Vector(1536))
    is_current = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    valid_from = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    valid_to = Column(DateTime(timezone=True))
    version_id = Column(BigInteger, nullable=False)

    projection = relationship("EntityProjection", back_populates="states")
