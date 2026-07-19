"""
Page management routes.
"""
from uuid import UUID
from fastapi import APIRouter, Depends, Request, Form, HTTPException
from fastapi.responses import RedirectResponse, HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.users import UserAccount
from app.models.pages import PageRegistry, MenuItem
from app.services.auth import require_admin, require_auth

router = APIRouter(prefix="/admin/pages", tags=["admin-pages"])
templates = Jinja2Templates(directory="app/templates")


@router.get("/", response_class=HTMLResponse)
async def list_pages(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    """List all pages."""
    result = await db.execute(select(PageRegistry).order_by(PageRegistry.page_code))
    pages = result.scalars().all()

    return templates.TemplateResponse("admin/pages.html", {
        "request": request,
        "user": user,
        "pages": pages,
    })


@router.get("/new", response_class=HTMLResponse)
async def new_page(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    """New page form."""
    return templates.TemplateResponse("admin/page_edit.html", {
        "request": request,
        "user": user,
        "page": None,
    })


@router.post("/create")
async def create_page(
    request: Request,
    page_code: str = Form(...),
    title: str = Form(...),
    is_published: bool = Form(False),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    """Create a new page."""
    page = PageRegistry(
        page_code=page_code,
        title=title,
        content={},
        is_published=is_published,
        created_by=user.user_id,
    )
    db.add(page)
    await db.commit()
    return RedirectResponse(url=f"/admin/pages/{page.page_id}/edit", status_code=303)


@router.get("/{page_id}/edit", response_class=HTMLResponse)
async def edit_page(
    page_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    """Edit page form."""
    result = await db.execute(
        select(PageRegistry).where(PageRegistry.page_id == UUID(page_id))
    )
    page = result.scalar_one_or_none()
    if not page:
        raise HTTPException(status_code=404)

    return templates.TemplateResponse("admin/page_edit.html", {
        "request": request,
        "user": user,
        "page": page,
    })


@router.post("/{page_id}/update")
async def update_page(
    page_id: str,
    request: Request,
    page_code: str = Form(...),
    title: str = Form(...),
    content: str = Form("{}"),
    is_published: bool = Form(False),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    """Update page."""
    result = await db.execute(
        select(PageRegistry).where(PageRegistry.page_id == UUID(page_id))
    )
    page = result.scalar_one_or_none()
    if not page:
        raise HTTPException(status_code=404)

    page.page_code = page_code
    page.title = title
    page.content = content
    page.is_published = is_published
    await db.commit()

    return RedirectResponse(url="/admin/pages/", status_code=303)


@router.post("/{page_id}/delete")
async def delete_page(
    page_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    """Delete page."""
    result = await db.execute(
        select(PageRegistry).where(PageRegistry.page_id == UUID(page_id))
    )
    page = result.scalar_one_or_none()
    if page:
        await db.delete(page)
        await db.commit()

    return RedirectResponse(url="/admin/pages/", status_code=303)
