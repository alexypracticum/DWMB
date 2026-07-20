"""
RSS/Atom feeds — latest entities and pages.
"""
import logging
from fastapi import APIRouter, Depends, Request, Query
from fastapi.responses import Response
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime

from app.database import get_db
from app.models.entities import Entity, EntityLabel
from app.models.kinds import EntityKind
from app.models.users import UserAccount
from app.services.auth import get_current_user

router = APIRouter(tags=["feeds"])


def _generate_rss(items: list, title: str, link: str, description: str) -> str:
    """Generate RSS 2.0 XML."""
    now = datetime.utcnow().strftime("%a, %d %b %Y %H:%M:%S +0000")

    items_xml = ""
    for item in items:
        pub_date = item["date"].strftime("%a, %d %b %Y %H:%M:%S +0000") if item["date"] else now
        items_xml += f"""
        <item>
            <title><![CDATA[{item['title']}]]></title>
            <link>{item['link']}</link>
            <description><![CDATA[{item.get('description', '')}]]></description>
            <pubDate>{pub_date}</pubDate>
            <guid isPermaLink="true">{item['link']}</guid>
        </item>"""

    return f"""<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
    <channel>
        <title><![CDATA[{title}]]></title>
        <link>{link}</link>
        <description><![CDATA[{description}]]></description>
        <language>ru</language>
        <lastBuildDate>{now}</lastBuildDate>
        <atom:link href="{link}/feed/entities" rel="self" type="application/rss+xml"/>
        {items_xml}
    </channel>
</rss>"""


@router.get("/feed/entities", response_class=Response)
async def feed_entities(
    request: Request,
    db: AsyncSession = Depends(get_db),
    kind: str = Query(None),
    limit: int = Query(20, ge=1, le=100),
):
    """RSS feed of latest entities."""
    base_url = str(request.base_url).rstrip("/")

    query = (
        select(Entity, EntityLabel, EntityKind)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
        .where(Entity.status == "active", EntityLabel.is_primary == True)
        .order_by(Entity.updated_at.desc())
        .limit(limit)
    )

    if kind:
        query = query.join(EntityKind, EntityKind.kind_id == Entity.kind_id).where(EntityKind.kind_code == kind)

    result = await db.execute(query)

    items = []
    for entity, label, kind_obj in result.unique():
        items.append({
            "title": label.label or entity.entity_code,
            "link": f"{base_url}/entity/{entity.entity_id}",
            "description": label.description or "",
            "date": entity.updated_at or entity.created_at,
        })

    title = f"DWMB — Последние сущности"
    if kind:
        title += f" ({kind})"

    rss_xml = _generate_rss(items, title, base_url, "Последние сущности из DWMB метасистемы")

    return Response(content=rss_xml, media_type="application/rss+xml; charset=utf-8")


@router.get("/feed/pages", response_class=Response)
async def feed_pages(
    request: Request,
    db: AsyncSession = Depends(get_db),
    limit: int = Query(20, ge=1, le=100),
):
    """RSS feed of published pages."""
    from app.models.pages import PageRegistry

    base_url = str(request.base_url).rstrip("/")

    result = await db.execute(
        select(PageRegistry)
        .where(PageRegistry.is_published == True)
        .order_by(PageRegistry.updated_at.desc())
        .limit(limit)
    )
    pages = result.scalars().all()

    items = []
    for page in pages:
        items.append({
            "title": page.title,
            "link": f"{base_url}/page/{page.page_code}",
            "description": page.meta_description or "",
            "date": page.updated_at or page.created_at,
        })

    rss_xml = _generate_rss(items, "DWMB — Страницы", base_url, "Опубликованные страницы DWMB")

    return Response(content=rss_xml, media_type="application/rss+xml; charset=utf-8")
