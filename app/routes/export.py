"""
Export routes — export entities as Markdown or PDF.
"""
import logging
from fastapi import APIRouter, Depends, Request, HTTPException
from fastapi.responses import StreamingResponse, HTMLResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
import io

from app.database import get_db
from app.models.entities import Entity, EntityLabel, MediaAsset
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.projections import EntityProjection, ProjectionState, OntologyModel, OntologyTemplate
from app.models.relations import SemanticRelation, RelationType
from app.models.users import UserAccount
from app.services.auth import get_current_user
from app.services.layout import get_state_field

router = APIRouter(tags=["export"])


def _generate_markdown(entity, label, kind_label, state_data, outgoing, incoming, lang="ru") -> str:
    """Generate Markdown content for an entity."""
    lines = []

    # Title
    title = label.label if label else entity.entity_code
    lines.append(f"# {title}")
    lines.append("")

    # Kind badge
    if kind_label:
        lines.append(f"**Тип:** {kind_label}")
    lines.append("")

    # Description
    if label and label.description:
        lines.append("## Описание")
        lines.append("")
        lines.append(label.description)
        lines.append("")

    # Key fields from state_data
    _field_labels = {
        "year": "Год", "genre": "Жанр", "rating": "Рейтинг", "country": "Страна",
        "language": "Язык", "budget": "Бюджет", "revenue": "Сборы", "runtime": "Хронометраж",
        "director": "Режиссёр", "author": "Автор", "publisher": "Издатель",
        "birth_date": "Дата рождения", "birth_place": "Место рождения",
        "description": None, "poster": None, "tmdb_id": None, "imdb_id": None,
        "meta_title": None, "meta_description": None, "og_image": None,
    }

    has_fields = False
    for key, val in state_data.items():
        if key in _field_labels and _field_labels[key] and val:
            if not has_fields:
                lines.append("## Данные")
                lines.append("")
                has_fields = True
            lines.append(f"- **{_field_labels[key]}:** {val}")

    if has_fields:
        lines.append("")

    # Content (from richtext/markdown)
    content = state_data.get("content", "")
    if content:
        lines.append("## Контент")
        lines.append("")
        # Strip HTML tags for plain markdown
        import re
        content_plain = re.sub(r'<[^>]+>', '', str(content))
        lines.append(content_plain)
        lines.append("")

    # Relations
    if outgoing:
        lines.append("## Связи (исходящие)")
        lines.append("")
        for rel_data in outgoing:
            target_label = rel_data["label"].label if rel_data["label"] else "?"
            rel_type = rel_data["type"].relation_name if rel_data["type"] else "?"
            lines.append(f"- {rel_type} → {target_label}")
        lines.append("")

    if incoming:
        lines.append("## Связи (входящие)")
        lines.append("")
        for rel_data in incoming:
            source_label = rel_data["label"].label if rel_data["label"] else "?"
            rel_type = rel_data["type"].relation_name if rel_data["type"] else "?"
            lines.append(f"- {rel_type} ← {source_label}")
        lines.append("")

    # Meta
    lines.append("---")
    lines.append(f"*ID: {entity.entity_id}*")
    lines.append(f"*Создано: {entity.created_at.strftime('%d.%m.%Y %H:%M') if entity.created_at else '-'}*")
    lines.append(f"*Обновлено: {entity.updated_at.strftime('%d.%m.%Y %H:%M') if entity.updated_at else '-'}*")

    return "\n".join(lines)


@router.get("/entity/{entity_id}/export/markdown", summary="Экспорт в Markdown", description="Скачать сущность в формате Markdown (.md)")
async def export_markdown(
    entity_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Export entity as Markdown file."""
    eid = UUID(entity_id)

    entity_result = await db.execute(select(Entity).where(Entity.entity_id == eid))
    entity = entity_result.scalar_one_or_none()
    if not entity:
        raise HTTPException(404)

    # Get label
    label_result = await db.execute(
        select(EntityLabel).where(EntityLabel.entity_id == eid, EntityLabel.is_primary == True).limit(1)
    )
    label = label_result.scalars().first()

    # Get kind label
    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_id == entity.kind_id))
    kind = kind_result.scalars().first()
    lang = "ru"
    kind_label = None
    if kind:
        kl_result = await db.execute(
            select(EntityKindLabel.label).where(EntityKindLabel.kind_id == kind.kind_id).limit(1)
        )
        kind_label = kl_result.scalar_one_or_none()

    # Get state data
    state_data = {}
    proj_result = await db.execute(
        select(EntityProjection).where(EntityProjection.entity_id == eid).limit(1)
    )
    proj = proj_result.scalars().first()
    if proj:
        state_result = await db.execute(
            select(ProjectionState).where(
                ProjectionState.projection_id == proj.projection_id,
                ProjectionState.is_current == True
            ).limit(1)
        )
        state = state_result.scalars().first()
        if state:
            state_data = state.state_data or {}

    # Get relations
    from app.models.projections import EntityProjection as EP
    source_rels = await db.execute(
        select(SemanticRelation, RelationType, EP, Entity, EntityLabel)
        .join(RelationType, RelationType.relation_type_id == SemanticRelation.relation_type_id)
        .join(EP, EP.projection_id == SemanticRelation.target_projection_id)
        .join(Entity, Entity.entity_id == EP.entity_id)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .where(SemanticRelation.source_projection_id.in_(
            select(EP.projection_id).where(EP.entity_id == eid)
        ), EntityLabel.is_primary == True)
    )
    outgoing = [{"relation": r, "type": t, "label": l} for r, t, p, e, l in source_rels.unique()]

    target_rels = await db.execute(
        select(SemanticRelation, RelationType, EP, Entity, EntityLabel)
        .join(RelationType, RelationType.relation_type_id == SemanticRelation.relation_type_id)
        .join(EP, EP.projection_id == SemanticRelation.source_projection_id)
        .join(Entity, Entity.entity_id == EP.entity_id)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .where(SemanticRelation.target_projection_id.in_(
            select(EP.projection_id).where(EP.entity_id == eid)
        ), EntityLabel.is_primary == True)
    )
    incoming = [{"relation": r, "type": t, "label": l} for r, t, p, e, l in target_rels.unique()]

    # Generate markdown
    md_content = _generate_markdown(entity, label, kind_label, state_data, outgoing, incoming, lang)

    # Return as file download
    filename = f"{entity.entity_code}.md"
    return StreamingResponse(
        io.BytesIO(md_content.encode("utf-8")),
        media_type="text/markdown",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.get("/entity/{entity_id}/export/html", summary="Экспорт в HTML", description="Скачать сущность как standalone HTML страницу")
async def export_html(
    entity_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Export entity as standalone HTML page (printable)."""
    eid = UUID(entity_id)

    entity_result = await db.execute(select(Entity).where(Entity.entity_id == eid))
    entity = entity_result.scalar_one_or_none()
    if not entity:
        raise HTTPException(404)

    # Get label
    label_result = await db.execute(
        select(EntityLabel).where(EntityLabel.entity_id == eid, EntityLabel.is_primary == True).limit(1)
    )
    label = label_result.scalars().first()

    # Get kind label
    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_id == entity.kind_id))
    kind = kind_result.scalars().first()
    kind_label = None
    if kind:
        kl_result = await db.execute(
            select(EntityKindLabel.label).where(EntityKindLabel.kind_id == kind.kind_id).limit(1)
        )
        kind_label = kl_result.scalar_one_or_none()

    # Get state data
    state_data = {}
    proj_result = await db.execute(
        select(EntityProjection).where(EntityProjection.entity_id == eid).limit(1)
    )
    proj = proj_result.scalars().first()
    if proj:
        state_result = await db.execute(
            select(ProjectionState).where(
                ProjectionState.projection_id == proj.projection_id,
                ProjectionState.is_current == True
            ).limit(1)
        )
        state = state_result.scalars().first()
        if state:
            state_data = state.state_data or {}

    title = label.label if label else entity.entity_code
    description = label.description if label else ""

    html_content = f"""<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>{title} — DWMB</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 800px; margin: 0 auto; padding: 40px 20px; color: #1f2937; line-height: 1.6; }}
        h1 {{ color: #111827; border-bottom: 2px solid #e5e7eb; padding-bottom: 8px; }}
        h2 {{ color: #374151; margin-top: 24px; }}
        .badge {{ display: inline-block; padding: 2px 8px; background: #3b82f6; color: #fff; border-radius: 12px; font-size: 12px; }}
        .meta {{ color: #6b7280; font-size: 12px; margin-top: 24px; border-top: 1px solid #e5e7eb; padding-top: 12px; }}
        ul {{ padding-left: 20px; }}
        li {{ margin-bottom: 4px; }}
    </style>
</head>
<body>
    <h1>{title}</h1>
    <p><span class="badge">{kind_label or entity.entity_code}</span></p>
    {"<h2>Описание</h2><p>" + description + "</p>" if description else ""}
"""

    # Key fields
    _field_labels = {
        "year": "Год", "genre": "Жанр", "rating": "Рейтинг", "country": "Страна",
        "language": "Язык", "budget": "Бюджет", "revenue": "Сборы", "runtime": "Хронометраж",
        "director": "Режиссёр", "author": "Автор", "publisher": "Издатель",
    }

    fields_html = ""
    for key, val in state_data.items():
        if key in _field_labels and val:
            fields_html += f"<li><strong>{_field_labels[key]}:</strong> {val}</li>\n"

    if fields_html:
        html_content += f"<h2>Данные</h2>\n<ul>\n{fields_html}</ul>\n"

    # Content
    content = state_data.get("content", "")
    if content:
        html_content += f"<h2>Контент</h2>\n<div>{content}</div>\n"

    html_content += f"""
    <div class="meta">
        <p>ID: {entity.entity_id}</p>
        <p>Создано: {entity.created_at.strftime('%d.%m.%Y %H:%M') if entity.created_at else '-'}</p>
        <p>Обновлено: {entity.updated_at.strftime('%d.%m.%Y %H:%M') if entity.updated_at else '-'}</p>
    </div>
</body>
</html>"""

    filename = f"{entity.entity_code}.html"
    return StreamingResponse(
        io.BytesIO(html_content.encode("utf-8")),
        media_type="text/html",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
