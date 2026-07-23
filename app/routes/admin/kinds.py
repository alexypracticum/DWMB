import json
from fastapi import APIRouter, Depends, Request, Form, Query, HTTPException
from fastapi.responses import RedirectResponse, HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from app.database import get_db
from app.models.entities import Entity, EntityLabel
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.users import UserAccount
from app.models.projections import OntologyModel, OntologyTemplate, EntityProjection, ProjectionState
from app.models.fields import FieldRegistry
from app.models.relations import RelationType
from app.services.auth import require_admin
from app.services.auth import get_password_hash
from app.services.rbac import require_permission
from app.services.language_service import get_language_id, get_kind_label, get_lang

templates = Jinja2Templates(directory="app/templates")

router = APIRouter(tags=["admin"])

def _ensure_json_schema(fs):
    """Convert old array-format field_schema to JSON Schema format if needed."""
    if not fs:
        return {"properties": {}, "required": []}
    if isinstance(fs, dict) and "properties" in fs:
        return fs
    if isinstance(fs, list):
        props = {}
        required = []
        for f in fs:
            if isinstance(f, dict) and "key" in f:
                key = f["key"]
                prop = {"type": f.get("type", "string"), "title": f.get("label", key)}
                if f.get("required"):
                    required.append(key)
                props[key] = prop
        return {"properties": props, "required": []}
    return {"properties": {}, "required": []}


def _sync_layout_fields_from_schema(layout_blocks, schema_json):
    """Update image_data_row block config.fields from schema properties."""
    SKIP_KEYS = {"poster", "poster_url", "description", "content"}
    if not isinstance(layout_blocks, list) or not isinstance(schema_json, dict):
        return layout_blocks
    props = schema_json.get("properties", {})
    field_order = schema_json.get("field_order", [])
    ordered_keys = field_order if field_order else list(props.keys())
    for block in layout_blocks:
        if block.get("type") == "image_data_row" and "config" in block:
            new_fields = []
            for key in ordered_keys:
                if key in props and key not in SKIP_KEYS:
                    prop = props[key]
                    if isinstance(prop, dict):
                        new_fields.append({"key": key, "label": prop.get("title", key), "type": prop.get("type", "string")})
                    elif isinstance(prop, str):
                        new_fields.append({"key": key, "label": key.replace("_", " ").title(), "type": prop})
            block["config"]["fields"] = new_fields
    return layout_blocks
@router.get("/kinds", response_class=HTMLResponse)
async def admin_kinds(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    result = await db.execute(
        select(EntityKind).order_by(EntityKind.sort_order)
    )
    kinds = result.scalars().all()

    kind_data = []
    lang = getattr(request.state, "lang", "ru")
    for kind in kinds:
        label = await get_kind_label(db, kind.kind_id, lang) or kind.kind_code
        fs = kind.field_schema if kind.field_schema else []
        kind_data.append({"kind": kind, "label": label, "field_count": len(fs)})

    return templates.TemplateResponse("admin/kinds.html", {
        "request": request,
        "user": user,
        "kinds": kind_data,
    })


@router.get("/kinds/{kind_id}/edit", response_class=HTMLResponse)
async def admin_kind_edit_page(request: Request, kind_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    from uuid import UUID
    from app.models.kinds import EntityKind, EntityKindLabel
    result = await db.execute(select(EntityKind).where(EntityKind.kind_id == UUID(kind_id)))
    kind = result.scalar_one_or_none()
    if not kind:
        return RedirectResponse(url="/admin/kinds", status_code=303)
    lbl_result = await db.execute(
        select(EntityKindLabel).where(EntityKindLabel.kind_id == kind.kind_id)
    )
    from app.services.language import get_language_code
    labels = {}
    for l in lbl_result.scalars().all():
        code = await get_language_code(db, l.language_id)
        if code:
            labels[code] = l
    import json
    fs = kind.field_schema if kind.field_schema else []
    field_schema_json = json.dumps(_ensure_json_schema(fs), ensure_ascii=False, indent=2)
    t = getattr(request.state, "t", {})
    import json as _json
    ui_translations_json = _json.dumps(t, ensure_ascii=False)
    return templates.TemplateResponse("admin/kind_edit.html", {
        "request": request, "user": user, "kind": kind, "labels": labels,
        "field_schema_json": field_schema_json,
        "ui_translations": ui_translations_json,
    })


@router.post("/kinds/{kind_id}/edit")
async def admin_kind_edit_save(
    kind_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
    kind_code: str = Form(""),
    label_ru: str = Form(""),
    label_en: str = Form(""),
    description: str = Form(""),
    is_abstract: bool = Form(False),
    sort_order: int = Form(0),
    field_schema: str = Form("[]"),
):
    from uuid import UUID
    from app.models.kinds import EntityKind, EntityKindLabel
    import json

    result = await db.execute(select(EntityKind).where(EntityKind.kind_id == UUID(kind_id)))
    kind = result.scalar_one_or_none()
    if not kind:
        return RedirectResponse(url="/admin/kinds", status_code=303)

    try:
        fs = json.loads(field_schema) if field_schema.strip() else {}
    except json.JSONDecodeError:
        fs = {}
    # Ensure JSON Schema format
    fs = _ensure_json_schema(fs)

    kind.kind_code = kind_code
    kind.description = description
    kind.is_abstract = is_abstract
    kind.sort_order = sort_order
    kind.field_schema = fs

    # Sync schema to all linked templates
    tmpl_result = await db.execute(
        select(OntologyTemplate).where(OntologyTemplate.kind_id == kind.kind_id)
    )
    for tmpl in tmpl_result.scalars().all():
        tmpl.schema_definition = fs
        _ld = tmpl.layout_definition
        if isinstance(_ld, str):
            try: _ld = json.loads(_ld)
            except (json.JSONDecodeError, ValueError, TypeError): _ld = []
        _ld = _sync_layout_fields_from_schema(_ld, fs)
        tmpl.layout_definition = _ld

    # Update labels
    ru_lang_id = await get_language_id(db, "ru")
    en_lang_id = await get_language_id(db, "en")
    if label_ru:
        if ru_lang_id:
            lbl = (await db.execute(select(EntityKindLabel).where(
                EntityKindLabel.kind_id == kind.kind_id, EntityKindLabel.language_id == ru_lang_id
            ))).scalar_one_or_none()
        else:
            lbl = None
        if lbl:
            lbl.label = label_ru
        else:
            db.add(EntityKindLabel(kind_id=kind.kind_id, language_id=ru_lang_id, label=label_ru))
    if label_en:
        if en_lang_id:
            lbl = (await db.execute(select(EntityKindLabel).where(
                EntityKindLabel.kind_id == kind.kind_id, EntityKindLabel.language_id == en_lang_id
            ))).scalar_one_or_none()
        else:
            lbl = None
        if lbl:
            lbl.label = label_en
        else:
            db.add(EntityKindLabel(kind_id=kind.kind_id, language_id=en_lang_id, label=label_en))

    await db.commit()
    return RedirectResponse(url="/admin/kinds", status_code=303)


@router.get("/kinds/create", response_class=HTMLResponse)
async def admin_kind_create_page(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    t = getattr(request.state, "t", {})
    import json as _json
    ui_translations_json = _json.dumps(t, ensure_ascii=False)
    return templates.TemplateResponse("admin/kind_create.html", {
        "request": request, "user": user,
        "ui_translations": ui_translations_json,
    })


@router.post("/kinds/create")
async def admin_kind_create(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
    kind_code: str = Form(""),
    label_ru: str = Form(""),
    label_en: str = Form(""),
    description: str = Form(""),
    is_abstract: bool = Form(False),
    sort_order: int = Form(0),
    field_schema: str = Form("{}"),
):
    from app.models.kinds import EntityKind, EntityKindLabel
    import json

    # Validate kind_code
    kind_code = kind_code.strip().lower().replace(" ", "_")
    if not kind_code:
        return RedirectResponse(url="/admin/kinds/create?error=empty_code", status_code=303)

    # Check unique
    existing = await db.execute(select(EntityKind).where(EntityKind.kind_code == kind_code))
    if existing.scalar_one_or_none():
        return RedirectResponse(url="/admin/kinds/create?error=exists", status_code=303)

    # Parse schema
    try:
        fs = json.loads(field_schema) if field_schema.strip() else {}
    except json.JSONDecodeError:
        fs = {}
    fs = _ensure_json_schema(fs)

    # Get version
    version_result = await db.execute(select(func.max(EntityKind.version_id)))
    version_id = (version_result.scalar() or 0) + 1

    kind = EntityKind(
        kind_code=kind_code,
        description=description,
        is_abstract=is_abstract,
        sort_order=sort_order,
        field_schema=fs,
        version_id=version_id,
    )
    db.add(kind)
    await db.flush()

    # Add labels
    if label_ru:
        ru_lang_id = await get_language_id(db, "ru")
        db.add(EntityKindLabel(kind_id=kind.kind_id, language_id=ru_lang_id, label=label_ru))
    if label_en:
        en_lang_id = await get_language_id(db, "en")
        db.add(EntityKindLabel(kind_id=kind.kind_id, language_id=en_lang_id, label=label_en))

    await db.commit()
    return RedirectResponse(url=f"/admin/kinds/{kind.kind_id}/edit", status_code=303)


@router.post("/kinds/{kind_id}/delete")
async def admin_kind_delete(
    kind_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
):
    from app.models.kinds import EntityKind, EntityKindLabel
    from app.models.projections import OntologyTemplate

    result = await db.execute(select(EntityKind).where(EntityKind.kind_id == UUID(kind_id)))
    kind = result.scalar_one_or_none()
    if not kind:
        return RedirectResponse(url="/admin/kinds", status_code=303)

    # Unlink templates from this kind
    tmpl_result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.kind_id == kind.kind_id))
    for tmpl in tmpl_result.scalars().all():
        tmpl.kind_id = None

    # Delete labels
    lbl_result = await db.execute(select(EntityKindLabel).where(EntityKindLabel.kind_id == kind.kind_id))
    for lbl in lbl_result.scalars().all():
        await db.delete(lbl)

    # Delete kind
    await db.delete(kind)
    await db.commit()
    return RedirectResponse(url="/admin/kinds", status_code=303)


# =============================================================================
#  ONTOLOGY MODEL CRUD
# =============================================================================

