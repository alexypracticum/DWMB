import json
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, Request, Form, Query, HTTPException, UploadFile, File
from fastapi.responses import RedirectResponse, HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select, func, or_, text
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.entities import Entity, EntityLabel, Context
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.projections import EntityProjection, ProjectionState, OntologyModel, OntologyTemplate
from app.models.relations import SemanticRelation, RelationType
from app.models.users import UserAccount
from app.services.auth import get_current_user, require_auth
from app.services.layout import render_layout, get_state_field, get_localized_value
from app.services.language_service import get_language_id, get_kind_label, get_entity_label, entity_label_filter, lang_priority_case, get_lang_ids, get_lang

templates = Jinja2Templates(directory="app/templates")

router = APIRouter(tags=["entities"])
@router.post("/upload")
async def upload_file(
    request: Request,
    user: UserAccount = Depends(require_auth),
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
):
    import os, hashlib as _hl
    from uuid import uuid4
    from app.services.storage import storage_service
    from app.models.entities import MediaAsset

    filename = file.filename or "file"
    ext = os.path.splitext(filename)[1].lower()

    if ext in BLOCKED_EXTENSIONS:
        return JSONResponse(
            {"error": f"Загрузка файлов типа {ext} запрещена"},
            status_code=400,
        )

    # Read content and compute hash BEFORE upload (for dedup check)
    content = await file.read()
    file_hash = _hl.sha256(content).hexdigest()

    # Check for duplicate by hash
    existing = await db.execute(
        select(MediaAsset).where(MediaAsset.file_hash == file_hash)
    )
    existing_asset = existing.scalar_one_or_none()
    if existing_asset:
        # Duplicate found — return existing URL without re-uploading
        url = storage_service.get_presigned_url(existing_asset.storage_key)
        return JSONResponse({
            "url": url,
            "filename": existing_asset.original_name,
            "size": existing_asset.size_bytes,
            "storage_key": existing_asset.storage_key,
            "entity_id": str(existing_asset.entity_id),
            "duplicate": True,
        })

    # No duplicate — upload to MinIO (reset file position after hash read)
    entity_id = uuid4()
    await file.seek(0)
    result = await storage_service.upload_file(file, entity_id)

    url = storage_service.get_presigned_url(result["key"])
    is_image = ext in (".jpg", ".jpeg", ".png", ".webp", ".gif", ".svg")

    # Create Entity for ALL files (kind='digital_file')
    file_kind = await db.execute(
        select(EntityKind).where(EntityKind.kind_code == "digital_file")
    )
    file_kind_obj = file_kind.scalar_one_or_none()
    if file_kind_obj:
        entity = Entity(
            entity_id=entity_id,
            entity_code=f"file-{entity_id.hex[:12]}",
            kind_id=file_kind_obj.kind_id,
            status="active",
            owner_id=user.user_id,
            version_id=1,
        )
        db.add(entity)
        await db.flush()

        label = EntityLabel(
            entity_id=entity_id,
            language_id=await get_language_id(db, "ru"),
            label=os.path.splitext(filename)[0].replace("_", " ").replace("-", " "),
            is_primary=True,
            owner_id=user.user_id,
            version_id=1,
        )
        db.add(label)

        # Create projection with state containing file metadata
        from app.models.projections import EntityProjection, ProjectionState, OntologyTemplate
        import json as _json, hashlib

        tmpl_result = await db.execute(
            select(OntologyTemplate)
            .join(EntityKind, EntityKind.kind_id == OntologyTemplate.kind_id)
            .where(EntityKind.kind_code == "digital_file", OntologyTemplate.is_active == True)
            .limit(1)
        )
        tmpl = tmpl_result.scalar_one_or_none()
        if tmpl:
            proj_id = uuid4()
            proj = EntityProjection(
                projection_id=proj_id,
                entity_id=entity_id,
                model_id=tmpl.model_id,
                template_id=tmpl.template_id,
                projection_code=f"file_{entity_id.hex[:12]}",
                projection_name=os.path.splitext(filename)[0],
                confidence=1.0,
                version_id=1,
            )
            db.add(proj)
            await db.flush()

            state_data = {
                "original_name": filename,
                "mime_type": file.content_type or "application/octet-stream",
                "size_bytes": result["size"],
                "file_hash": result["hash"],
                "storage_key": result["key"],
                "storage_backend": "s3",
                "url": url,
                "is_image": is_image,
                "poster_url": url if is_image else None,
            }
            state_hash = hashlib.sha256(_json.dumps(state_data, sort_keys=True, default=str).encode()).hexdigest()
            ps = ProjectionState(
                projection_id=proj_id,
                state_data=state_data,
                state_hash=state_hash,
                is_current=True,
                version_id=1,
            )
            db.add(ps)

    # Create MediaAsset record (after Entity so FK is satisfied)
    from app.models.entities import MediaAsset
    media_asset = MediaAsset(
        entity_id=entity_id,
        original_name=filename,
        mime_type=file.content_type or "application/octet-stream",
        size_bytes=result["size"],
        file_hash=result["hash"],
        storage_key=result["key"],
        version_id=1,
    )
    db.add(media_asset)

    await db.commit()

    return JSONResponse({
        "url": url,
        "filename": filename,
        "size": result["size"],
        "storage_key": result["key"],
        "entity_id": str(entity_id),
    })


# =============================================================================
#  MEDIA MANAGEMENT (entity CRUD for media_asset)
# =============================================================================

@router.get("/media/{asset_id}")
async def get_media(
    asset_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    """Get media asset metadata by asset_id."""
    from uuid import UUID
    from app.models.entities import MediaAsset

    result = await db.execute(
        select(MediaAsset).where(MediaAsset.asset_id == UUID(asset_id))
    )
    asset = result.scalar_one_or_none()
    if not asset:
        raise HTTPException(status_code=404, detail="Media asset not found")

    from app.services.storage import storage_service
    url = storage_service.get_presigned_url(asset.storage_key)

    return JSONResponse({
        "asset_id": str(asset.asset_id),
        "entity_id": str(asset.entity_id) if asset.entity_id else None,
        "original_name": asset.original_name,
        "mime_type": asset.mime_type,
        "size_bytes": asset.size_bytes,
        "file_hash": asset.file_hash,
        "storage_key": asset.storage_key,
        "url": url,
        "is_processed": asset.is_processed,
        "created_at": asset.created_at.isoformat() if asset.created_at else None,
    })


@router.get("/media/{asset_id}/info")
async def get_media_info(
    asset_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    """Get detailed media info via entity projection."""
    from uuid import UUID
    from app.models.entities import MediaAsset

    result = await db.execute(
        select(MediaAsset).where(MediaAsset.asset_id == UUID(asset_id))
    )
    asset = result.scalar_one_or_none()
    if not asset:
        raise HTTPException(status_code=404, detail="Media asset not found")

    if not asset.entity_id:
        return JSONResponse({
            "asset_id": str(asset.asset_id),
            "original_name": asset.original_name,
            "mime_type": asset.mime_type,
            "size_bytes": asset.size_bytes,
            "entity": None,
        })

    # Get entity info
    entity_result = await db.execute(
        select(Entity).where(Entity.entity_id == asset.entity_id)
    )
    entity = entity_result.scalar_one_or_none()

    # Get projection state
    proj_result = await db.execute(
        select(EntityProjection)
        .where(EntityProjection.entity_id == asset.entity_id)
        .limit(1)
    )
    proj = proj_result.scalar_one_or_none()

    state_data = None
    if proj:
        state_result = await db.execute(
            select(ProjectionState)
            .where(ProjectionState.projection_id == proj.projection_id, ProjectionState.is_current == True)
            .limit(1)
        )
        state = state_result.scalar_one_or_none()
        if state:
            state_data = state.state_data

    # Get label
    label_result = await db.execute(
        select(EntityLabel)
        .where(EntityLabel.entity_id == asset.entity_id, EntityLabel.is_primary == True)
        .limit(1)
    )
    label = label_result.scalar_one_or_none()

    from app.services.storage import storage_service
    url = storage_service.get_presigned_url(asset.storage_key)

    return JSONResponse({
        "asset_id": str(asset.asset_id),
        "entity_id": str(asset.entity_id),
        "entity_code": entity.entity_code if entity else None,
        "label": label.label if label else None,
        "original_name": asset.original_name,
        "mime_type": asset.mime_type,
        "size_bytes": asset.size_bytes,
        "file_hash": asset.file_hash,
        "storage_key": asset.storage_key,
        "url": url,
        "state_data": state_data,
        "is_processed": asset.is_processed,
        "created_at": asset.created_at.isoformat() if asset.created_at else None,
    })


@router.delete("/media/{asset_id}")
async def delete_media(
    asset_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Delete media asset and its entity."""
    from uuid import UUID
    from app.models.entities import MediaAsset
    from app.services.storage import storage_service

    result = await db.execute(
        select(MediaAsset).where(MediaAsset.asset_id == UUID(asset_id))
    )
    asset = result.scalar_one_or_none()
    if not asset:
        raise HTTPException(status_code=404, detail="Media asset not found")

    # Delete from storage
    try:
        storage_service.delete_file(asset.storage_key)
    except Exception as e:
        # Log but don't fail — storage might be already deleted
        pass

    # Delete entity if exists
    if asset.entity_id:
        entity_result = await db.execute(
            select(Entity).where(Entity.entity_id == asset.entity_id)
        )
        entity = entity_result.scalar_one_or_none()
        if entity:
            # Soft delete entity
            entity.status = "deleted"
            entity.updated_at = datetime.now(timezone.utc)
            entity.version_id = (entity.version_id or 1) + 1

    # Delete media_asset record
    await db.delete(asset)
    await db.commit()

    return JSONResponse({"status": "deleted", "asset_id": str(asset_id)})
