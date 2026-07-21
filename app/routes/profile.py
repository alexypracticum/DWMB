"""
Profile and theme management routes.
"""
from uuid import UUID
from fastapi import APIRouter, Depends, Request, Form, HTTPException
from fastapi.responses import RedirectResponse, HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.users import UserAccount
from app.models.themes import UserTheme
from app.services.auth import get_current_user, require_auth, get_password_hash
from app.services.language import get_language_id

router = APIRouter(prefix="/profile", tags=["profile"])
templates = Jinja2Templates(directory="app/templates")


@router.get("/", response_class=HTMLResponse)
async def profile_page(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """User profile page."""
    # Get user themes
    themes_result = await db.execute(
        select(UserTheme).where(UserTheme.user_id == user.user_id)
    )
    themes = themes_result.scalars().all()

    # Get available languages
    from app.models.languages import Language
    lang_result = await db.execute(select(Language).where(Language.is_active == True).order_by(Language.sort_order))
    languages = lang_result.scalars().all()

    return templates.TemplateResponse("profile/index.html", {
        "request": request,
        "user": user,
        "themes": themes,
        "languages": languages,
    })


@router.post("/update")
async def update_profile(
    request: Request,
    display_name: str = Form(None),
    email: str = Form(None),
    phone: str = Form(None),
    bio: str = Form(None),
    language_id: str = Form(None),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Update user profile."""
    from app.services.language import clear_language_cache
    
    if display_name is not None:
        user.display_name = display_name
    if email is not None:
        user.email = email
    if phone is not None:
        user.phone = phone
    if bio is not None:
        user.bio = bio
    if language_id:
        try:
            user.language_id = UUID(language_id)
            clear_language_cache()
        except (ValueError, TypeError):
            pass

    await db.commit()
    return RedirectResponse(url="/profile/", status_code=303)


@router.post("/change-password")
async def change_password(
    request: Request,
    current_password: str = Form(...),
    new_password: str = Form(...),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Change user password."""
    from app.services.auth import verify_password

    if not verify_password(current_password, user.password_hash):
        return templates.TemplateResponse("profile/index.html", {
            "request": request,
            "user": user,
            "error": "Неверный текущий пароль",
        })

    user.password_hash = get_password_hash(new_password)
    await db.commit()
    return RedirectResponse(url="/profile/", status_code=303)


@router.post("/theme/create")
async def create_theme(
    request: Request,
    theme_name: str = Form(...),
    is_dark: bool = Form(False),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Create a new custom theme."""
    theme = UserTheme(
        user_id=user.user_id,
        theme_name=theme_name,
        is_dark=is_dark,
    )
    db.add(theme)
    await db.commit()
    return RedirectResponse(url="/profile/", status_code=303)


@router.post("/theme/{theme_id}/activate")
async def activate_theme(
    theme_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Activate a theme."""
    # Deactivate all user themes
    themes_result = await db.execute(
        select(UserTheme).where(UserTheme.user_id == user.user_id)
    )
    for theme in themes_result.scalars().all():
        theme.is_active = False

    # Activate selected theme
    selected = await db.execute(
        select(UserTheme).where(UserTheme.theme_id == UUID(theme_id), UserTheme.user_id == user.user_id)
    )
    theme = selected.scalar_one_or_none()
    if theme:
        theme.is_active = True
        user.theme_id = theme.theme_id
        await db.commit()

    return RedirectResponse(url="/profile/", status_code=303)


@router.post("/theme/{theme_id}/delete")
async def delete_theme(
    theme_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Delete a custom theme."""
    result = await db.execute(
        select(UserTheme).where(UserTheme.theme_id == UUID(theme_id), UserTheme.user_id == user.user_id)
    )
    theme = result.scalar_one_or_none()
    if theme:
        if user.theme_id == theme.theme_id:
            user.theme_id = None
        await db.delete(theme)
        await db.commit()

    return RedirectResponse(url="/profile/", status_code=303)
