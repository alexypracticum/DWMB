"""
Search Microservice for DWMB.
Handles full-text and vector search operations.
"""
import os
import sys
import logging
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from sqlalchemy import create_engine, select, func, text
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from sqlalchemy import Column, String, UUID, Boolean, Text, Integer, DateTime
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="DWMB Search Service", version="1.0.0")

# Database connection
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://dwmb:dwmb_secret_2026@db:5432/dwmb")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)


# Minimal models for search
class Base(DeclarativeBase):
    pass


class Entity(Base):
    __tablename__ = "entity"
    __table_args__ = {"schema": "meta"}
    
    entity_id = Column(UUID(as_uuid=True), primary_key=True)
    entity_code = Column(String, nullable=False)
    kind_id = Column(UUID(as_uuid=True), nullable=False)
    status = Column(String, nullable=False)
    owner_id = Column(UUID(as_uuid=True))


class EntityLabel(Base):
    __tablename__ = "entity_label"
    __table_args__ = {"schema": "meta"}
    
    entity_label_id = Column(Integer, primary_key=True)
    entity_id = Column(UUID(as_uuid=True), nullable=False)
    language_id = Column(UUID(as_uuid=True), nullable=False)
    label = Column(String, nullable=False)
    is_primary = Column(Boolean, default=False)


class EntityKind(Base):
    __tablename__ = "entity_kind"
    __table_args__ = {"schema": "meta"}
    
    kind_id = Column(UUID(as_uuid=True), primary_key=True)
    kind_code = Column(String, nullable=False)
    description = Column(String)


class SearchRequest(BaseModel):
    query: str
    kind: Optional[str] = None
    limit: int = 20
    offset: int = 0


class SearchResult(BaseModel):
    entity_id: str
    entity_code: str
    label: str
    kind: Optional[str]
    score: Optional[float]


class SearchResponse(BaseModel):
    results: List[SearchResult]
    total: int
    query: str


@app.get("/health")
async def health():
    return {"status": "ok", "service": "search-service"}


@app.post("/search", response_model=SearchResponse)
async def search(request: SearchRequest):
    """Full-text search for entities."""
    session = SessionLocal()
    try:
        search_pattern = f"%{request.query}%"
        
        query = (
            select(Entity, EntityLabel, EntityKind)
            .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
            .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
            .where(
                Entity.status == "active",
                EntityLabel.is_primary == True,
                EntityLabel.label.ilike(search_pattern)
            )
        )
        
        if request.kind:
            query = query.where(EntityKind.kind_code == request.kind)
        
        count_query = select(func.count(Entity.entity_id)).select_from(query.subquery())
        total = session.scalar(count_query)
        
        query = query.limit(request.limit).offset(request.offset)
        result = session.execute(query)
        
        results = []
        for entity, label, kind in result.unique():
            results.append(SearchResult(
                entity_id=str(entity.entity_id),
                entity_code=entity.entity_code,
                label=label.label,
                kind=kind.kind_code if kind else None,
                score=None
            ))
        
        return SearchResponse(
            results=results,
            total=total,
            query=request.query
        )
    finally:
        session.close()


@app.get("/suggest")
async def suggest(q: str, limit: int = 10):
    """Get search suggestions."""
    session = SessionLocal()
    try:
        search_pattern = f"%{q}%"
        
        result = session.execute(
            select(Entity.entity_code, EntityLabel.label)
            .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
            .where(
                Entity.status == "active",
                EntityLabel.is_primary == True,
                EntityLabel.label.ilike(search_pattern)
            )
            .limit(limit)
        )
        
        suggestions = [{"code": code, "label": label} for code, label in result]
        
        return {"suggestions": suggestions}
    finally:
        session.close()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
