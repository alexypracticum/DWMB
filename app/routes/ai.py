"""
AI-related routes for entity parsing, embedding updates, and suggestions.
"""
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.entities import Entity
from app.models.projections import ProjectionState
from app.services.auth import require_auth
from app.services.ai import ai_service

router = APIRouter(prefix="/api/ai", tags=["ai"])


@router.post("/parse-text")
async def parse_entity_text(
    text: str,
    entity_type: str = "movie",
    user=Depends(require_auth),
):
    """Parse free text into structured entity data using AI."""
    result = await ai_service.parse_entity_text(text, entity_type)
    if not result:
        raise HTTPException(status_code=400, detail="Failed to parse text")
    return {"data": result}


@router.post("/update-embeddings")
async def update_embeddings(
    entity_id: UUID | None = None,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    user=Depends(require_auth),
):
    """Update embeddings for projection states in batch."""
    if not ai_service.api_key:
        raise HTTPException(status_code=400, detail="AI API key not configured")

    updated = await ai_service.update_embeddings_batch(db, entity_id, limit)
    return {"updated": updated}


@router.post("/suggest-fields/{entity_id}")
async def suggest_entity_fields(
    entity_id: UUID,
    db: AsyncSession = Depends(get_db),
    user=Depends(require_auth),
):
    """Use AI to suggest additional fields for an entity."""
    # Get entity projection state
    query = select(ProjectionState).join(
        ProjectionState.entity
    ).where(
        Entity.entity_id == entity_id,
        ProjectionState.is_current == True
    )
    result = await db.execute(query)
    state = result.scalar_one_or_none()

    if not state:
        raise HTTPException(status_code=404, detail="Entity not found")

    suggestions = await ai_service.suggest_fields(db, entity_id, state.state_data)
    return {"suggestions": suggestions}


@router.get("/search")
async def ai_search(
    query: str,
    kind: str = None,
    year_min: int = None,
    year_max: int = None,
    limit: int = 10,
    db: AsyncSession = Depends(get_db),
):
    """AI-powered hybrid search."""
    if not ai_service.api_key:
        raise HTTPException(status_code=400, detail="AI API key not configured")

    kind_filter = [kind] if kind else None
    year_range = (year_min, year_max) if year_min and year_max else None

    matches = await ai_service.hybrid_search(
        db, query, kind_filter=kind_filter,
        year_range=year_range, limit=limit
    )
    return {"matches": matches, "total": len(matches)}


@router.get("/similar/{entity_id}")
async def similar_entities(
    entity_id: UUID,
    limit: int = 5,
    db: AsyncSession = Depends(get_db),
):
    """Find entities similar to the given entity."""
    similar = await ai_service.find_similar(db, entity_id, limit)
    return {"similar": similar}


@router.get("/config")
async def get_ai_config(
    db: AsyncSession = Depends(get_db),
    user=Depends(require_auth),
):
    """Get current AI configuration."""
    from app.models.ai import AiConfig as AiConfigModel
    result = await db.execute(
        select(AiConfigModel).where(AiConfigModel.is_active == True).limit(1)
    )
    config = result.scalar_one_or_none()
    if not config:
        return {"configured": False}

    return {
        "configured": True,
        "provider": config.provider,
        "model_embedding": config.model_embedding,
        "model_chat": config.model_chat,
        "api_base_url": config.api_base_url,
        "max_tokens": config.max_tokens,
        "has_api_key": bool(config.api_key_enc),
    }


@router.post("/config")
async def update_ai_config(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user=Depends(require_auth),
):
    """Update AI configuration."""
    from app.models.ai import AiConfig as AiConfigModel

    body = await request.json()

    result = await db.execute(
        select(AiConfigModel).where(AiConfigModel.is_active == True).limit(1)
    )
    config = result.scalar_one_or_none()

    if not config:
        config = AiConfigModel(is_active=True)
        db.add(config)

    if "api_key" in body and body["api_key"]:
        config.api_key_enc = ai_service.encrypt_api_key(body["api_key"])
    if "model_embedding" in body:
        config.model_embedding = body["model_embedding"]
    if "model_chat" in body:
        config.model_chat = body["model_chat"]
    if "api_base_url" in body:
        config.api_base_url = body["api_base_url"]
    if "max_tokens" in body:
        config.max_tokens = body["max_tokens"]

    await db.commit()
    return {"ok": True}


@router.get("/logs")
async def get_ai_logs(
    limit: int = 50,
    task_type: str = None,
    db: AsyncSession = Depends(get_db),
    user=Depends(require_auth),
):
    """Get AI task logs."""
    from app.models.ai import AiTaskLog as AiTaskLogModel

    query = select(AiTaskLogModel).order_by(AiTaskLogModel.created_at.desc())
    if task_type:
        query = query.where(AiTaskLogModel.task_type == task_type)
    query = query.limit(limit)

    result = await db.execute(query)
    logs = result.scalars().all()

    return {
        "logs": [
            {
                "task_id": str(log.task_id),
                "task_type": log.task_type,
                "model_used": log.model_used,
                "input_tokens": log.input_tokens,
                "output_tokens": log.output_tokens,
                "cost_usd": float(log.cost_usd) if log.cost_usd else 0,
                "duration_ms": log.duration_ms,
                "status": log.status,
                "error_message": log.error_message,
                "created_at": log.created_at.isoformat() if log.created_at else None,
            }
            for log in logs
        ]
    }
