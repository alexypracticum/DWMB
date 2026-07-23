"""GraphQL type definitions for DWMB entities."""
import strawberry
from typing import Optional, List
from datetime import datetime
from uuid import UUID


@strawberry.type
class EntityKind:
    kind_id: str
    kind_code: str
    description: Optional[str]
    is_abstract: bool
    sort_order: int
    label: Optional[str] = None


@strawberry.type
class EntityLabel:
    entity_label_id: int
    language: str
    label: str
    description: Optional[str]
    is_primary: bool


@strawberry.type
class Entity:
    entity_id: str
    entity_code: str
    status: str
    kind: Optional[EntityKind]
    labels: List[EntityLabel]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]


@strawberry.type
class OntologyModel:
    model_id: str
    model_code: str
    domain: str
    description: Optional[str]


@strawberry.type
class OntologyTemplate:
    template_id: str
    template_code: str
    template_name: str
    description: Optional[str]
    model: Optional[OntologyModel]


@strawberry.type
class ProjectionState:
    state_id: str
    state_data: str  # JSON string
    is_current: bool
    created_at: Optional[datetime]


@strawberry.type
class EntityProjection:
    projection_id: str
    entity: Optional[Entity]
    model: Optional[OntologyModel]
    template: Optional[OntologyTemplate]
    confidence: Optional[float]
    states: List[ProjectionState]


@strawberry.type
class RelationType:
    relation_type_id: str
    relation_code: str
    relation_name: str
    directionality: str


@strawberry.type
class SemanticRelation:
    relation_id: str
    relation_type: Optional[RelationType]
    source_projection: Optional[EntityProjection]
    target_projection: Optional[EntityProjection]


@strawberry.type
class UserAccount:
    user_id: str
    username: str
    email: Optional[str]
    display_name: Optional[str]
    is_active: bool
    is_admin: bool
    created_at: Optional[datetime]


@strawberry.type
class Language:
    language_id: str
    code: str
    name: Optional[str]


@strawberry.type
class PageInfo:
    total: int
    page: int
    per_page: int
    total_pages: int


@strawberry.type
class EntityConnection:
    items: List[Entity]
    page_info: PageInfo


@strawberry.type
class Stats:
    entity_count: int
    kind_count: int
    relation_count: int
    model_count: int


@strawberry.type
class GeoLocation:
    entity_id: str
    entity_code: str
    latitude: float
    longitude: float
    altitude: Optional[float]
    accuracy: Optional[float]
    geo_type: Optional[str]
    description: Optional[str]
    kind: Optional[EntityKind]
    label: Optional[str]


@strawberry.type
class GeoBounds:
    north: float
    south: float
    east: float
    west: float
