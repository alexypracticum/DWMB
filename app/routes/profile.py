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

# Preset colors for system themes
_SYSTEM_LIGHT_COLORS = {
    "primary": "#3b82f6", "secondary": "#6366f1", "accent": "#f59e0b",
    "background": "#ffffff", "surface": "#f9fafb", "text": "#111827",
    "text_secondary": "#6b7280", "border": "#e5e7eb", "error": "#ef4444", "success": "#10b981",
}
_SYSTEM_DARK_COLORS = {
    "primary": "#818cf8", "secondary": "#a78bfa", "accent": "#fbbf24",
    "background": "#0f172a", "surface": "#1e293b", "text": "#f1f5f9",
    "text_secondary": "#94a3b8", "border": "#334155", "error": "#f87171", "success": "#34d399",
}
_DEFAULT_FONTS = {
    "heading": "Inter, sans-serif", "body": "Inter, sans-serif",
    "mono": "JetBrains Mono, monospace", "heading_size": "1.5rem", "body_size": "0.875rem",
}


async def _ensure_system_themes(db: AsyncSession, user: UserAccount):
    """Create system themes for a user if they don't exist yet."""
    result = await db.execute(
        select(UserTheme).where(UserTheme.user_id == user.user_id, UserTheme.is_system == True)
    )
    system_themes = result.scalars().all()
    if len(system_themes) >= 2:
        return

    existing_keys = {t.is_dark for t in system_themes}

    if False not in existing_keys:
        light = UserTheme(
            user_id=user.user_id, theme_name="Светлая",
            is_dark=False, is_system=True, is_active=False,
            colors=_SYSTEM_LIGHT_COLORS, fonts=_DEFAULT_FONTS,
        )
        db.add(light)

    if True not in existing_keys:
        dark = UserTheme(
            user_id=user.user_id, theme_name="Тёмная",
            is_dark=True, is_system=True, is_active=False,
            colors=_SYSTEM_DARK_COLORS, fonts=_DEFAULT_FONTS,
        )
        db.add(dark)

    await db.commit()

    # If user has no active theme, activate light
    if not user.theme_id:
        result = await db.execute(
            select(UserTheme).where(UserTheme.user_id == user.user_id, UserTheme.is_dark == False, UserTheme.is_system == True)
        )
        light = result.scalar_one_or_none()
        if light:
            light.is_active = True
            user.theme_id = light.theme_id
            await db.commit()


@router.get("/", response_class=HTMLResponse)
async def profile_page(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """User profile page."""
    await _ensure_system_themes(db, user)

    # Get user themes
    themes_result = await db.execute(
        select(UserTheme).where(UserTheme.user_id == user.user_id)
    )
    themes = themes_result.scalars().all()

    # Get active theme for toggle state
    active_theme = None
    if user.theme_id:
        active_result = await db.execute(
            select(UserTheme).where(UserTheme.theme_id == user.theme_id)
        )
        active_theme = active_result.scalar_one_or_none()

    # Get available languages
    from app.models.languages import Language
    lang_result = await db.execute(select(Language).where(Language.is_active == True).order_by(Language.sort_order))
    languages = lang_result.scalars().all()

    return templates.TemplateResponse("profile/index.html", {
        "request": request,
        "user": user,
        "themes": themes,
        "languages": languages,
        "active_theme": active_theme,
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
    from app.services.ui_strings import get_ui_string

    t = getattr(request.state, "t", {})
    lang = getattr(request.state, "lang", "ru")
    error_msg = t.get("label_wrong_password", "Неверный текущий пароль")

    if not verify_password(current_password, user.password_hash):
        themes_result = await db.execute(
            select(UserTheme).where(UserTheme.user_id == user.user_id)
        )
        themes = themes_result.scalars().all()
        from app.models.languages import Language
        lang_result = await db.execute(select(Language).where(Language.is_active == True).order_by(Language.sort_order))
        languages = lang_result.scalars().all()
        return templates.TemplateResponse("profile/index.html", {
            "request": request,
            "user": user,
            "themes": themes,
            "languages": languages,
            "active_theme": None,
            "error": error_msg,
        })

    user.password_hash = get_password_hash(new_password)
    await db.commit()
    return RedirectResponse(url="/profile/", status_code=303)


@router.post("/toggle-dark")
async def toggle_dark(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Toggle between system light/dark themes."""
    # Determine target is_dark by checking current active theme
    current_dark = False
    if user.theme_id:
        result = await db.execute(
            select(UserTheme).where(UserTheme.theme_id == user.theme_id)
        )
        current = result.scalar_one_or_none()
        if current:
            current_dark = current.is_dark

    target_dark = not current_dark

    # Find the system theme with the target is_dark value
    result = await db.execute(
        select(UserTheme).where(
            UserTheme.user_id == user.user_id,
            UserTheme.is_system == True,
            UserTheme.is_dark == target_dark,
        )
    )
    target_theme = result.scalar_one_or_none()

    if target_theme:
        # Deactivate all themes
        all_themes = await db.execute(
            select(UserTheme).where(UserTheme.user_id == user.user_id)
        )
        for t in all_themes.scalars().all():
            t.is_active = False

        target_theme.is_active = True
        user.theme_id = target_theme.theme_id
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
    """Delete a custom theme. System themes cannot be deleted."""
    result = await db.execute(
        select(UserTheme).where(UserTheme.theme_id == UUID(theme_id), UserTheme.user_id == user.user_id)
    )
    theme = result.scalar_one_or_none()
    if theme and not theme.is_system:
        if user.theme_id == theme.theme_id:
            user.theme_id = None
        await db.delete(theme)
        await db.commit()

    return RedirectResponse(url="/profile/", status_code=303)
