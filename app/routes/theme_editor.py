"""
Theme editor route — full visual theme customization with color pickers.
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
from app.services.auth import require_auth

router = APIRouter(prefix="/profile/theme-editor", tags=["theme-editor"])
templates = Jinja2Templates(directory="app/templates")


PRESETS = {
    "midnight": {
        "name_key": "preset_midnight",
        "is_dark": True,
        "colors": {
            "primary": "#818cf8", "secondary": "#a78bfa", "accent": "#fbbf24",
            "background": "#0f172a", "surface": "#1e293b", "text": "#f1f5f9",
            "text_secondary": "#94a3b8", "border": "#334155", "error": "#f87171", "success": "#34d399",
        },
    },
    "tokyo-night": {
        "name_key": "preset_tokyo_night",
        "is_dark": True,
        "colors": {
            "primary": "#7c3aed", "secondary": "#a78bfa", "accent": "#fbbf24",
            "background": "#1a1b26", "surface": "#24283b", "text": "#c0caf5",
            "text_secondary": "#737aa2", "border": "#3b4261", "error": "#f7768e", "success": "#9ece6a",
        },
    },
    "dracula": {
        "name_key": "preset_dracula",
        "is_dark": True,
        "colors": {
            "primary": "#bd93f9", "secondary": "#ff79c6", "accent": "#f1fa8c",
            "background": "#282a36", "surface": "#343746", "text": "#f8f8f2",
            "text_secondary": "#6272a4", "border": "#44475a", "error": "#ff5555", "success": "#50fa7b",
        },
    },
    "nord": {
        "name_key": "preset_nord",
        "is_dark": True,
        "colors": {
            "primary": "#88c0d0", "secondary": "#81a1c1", "accent": "#ebcb8b",
            "background": "#2e3440", "surface": "#3b4252", "text": "#eceff4",
            "text_secondary": "#7b88a1", "border": "#4c566a", "error": "#bf616a", "success": "#a3be8c",
        },
    },
    "light-clean": {
        "name_key": "preset_light",
        "is_dark": False,
        "colors": {
            "primary": "#3b82f6", "secondary": "#6366f1", "accent": "#f59e0b",
            "background": "#ffffff", "surface": "#f9fafb", "text": "#111827",
            "text_secondary": "#6b7280", "border": "#e5e7eb", "error": "#ef4444", "success": "#10b981",
        },
    },
    "cinema": {
        "name_key": "preset_cinema",
        "is_dark": True,
        "colors": {
            "primary": "#e50914", "secondary": "#b20710", "accent": "#f5c518",
            "background": "#0a0a0a", "surface": "#1a1a1a", "text": "#e5e5e5",
            "text_secondary": "#808080", "border": "#2a2a2a", "error": "#ff4444", "success": "#2ecc71",
        },
    },
    "literature": {
        "name_key": "preset_literature",
        "is_dark": True,
        "colors": {
            "primary": "#c9a96e", "secondary": "#8b6f47", "accent": "#d4a574",
            "background": "#1a1510", "surface": "#2a2318", "text": "#e8dcc8",
            "text_secondary": "#9a8b70", "border": "#3a3228", "error": "#c0392b", "success": "#27ae60",
        },
    },
    "music": {
        "name_key": "preset_music",
        "is_dark": True,
        "colors": {
            "primary": "#9b59b6", "secondary": "#8e44ad", "accent": "#e74c3c",
            "background": "#0d0221", "surface": "#1a0533", "text": "#e0d0ff",
            "text_secondary": "#7b5ea7", "border": "#2d1b4e", "error": "#ff6b6b", "success": "#51cf66",
        },
    },
    "people": {
        "name_key": "preset_people",
        "is_dark": True,
        "colors": {
            "primary": "#17a2b8", "secondary": "#138496", "accent": "#fd7e14",
            "background": "#0d1117", "surface": "#161b22", "text": "#c9d1d9",
            "text_secondary": "#8b949e", "border": "#30363d", "error": "#f85149", "success": "#3fb950",
        },
    },
}


@router.get("/{theme_id}", response_class=HTMLResponse)
async def theme_editor(
    theme_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Open theme editor for a specific theme."""
    result = await db.execute(
        select(UserTheme).where(UserTheme.theme_id == UUID(theme_id), UserTheme.user_id == user.user_id)
    )
    theme = result.scalar_one_or_none()
    if not theme:
        raise HTTPException(status_code=404)

    t = getattr(request.state, "t", {})
    localized_presets = {}
    for key, preset in PRESETS.items():
        name_key = preset.get("name_key", key)
        localized_presets[key] = {
            **preset,
            "name": t.get(name_key, key),
        }

    return templates.TemplateResponse("profile/theme_editor.html", {
        "request": request,
        "user": user,
        "theme": theme,
        "presets": localized_presets,
    })


@router.post("/{theme_id}/save")
async def save_theme(
    theme_id: str,
    request: Request,
    primary: str = Form(...),
    secondary: str = Form(...),
    accent: str = Form(...),
    background: str = Form(...),
    surface: str = Form(...),
    text: str = Form(...),
    text_secondary: str = Form(...),
    border: str = Form(...),
    error: str = Form(...),
    success: str = Form(...),
    font_heading: str = Form("Inter, sans-serif"),
    font_body: str = Form("Inter, sans-serif"),
    font_mono: str = Form("JetBrains Mono, monospace"),
    heading_size: str = Form("1.5rem"),
    body_size: str = Form("0.875rem"),
    is_dark: bool = Form(False),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Save theme colors and fonts."""
    result = await db.execute(
        select(UserTheme).where(UserTheme.theme_id == UUID(theme_id), UserTheme.user_id == user.user_id)
    )
    theme = result.scalar_one_or_none()
    if not theme:
        raise HTTPException(status_code=404)

    theme.is_dark = is_dark
    theme.colors = {
        "primary": primary, "secondary": secondary, "accent": accent,
        "background": background, "surface": surface, "text": text,
        "text_secondary": text_secondary, "border": border,
        "error": error, "success": success,
    }
    theme.fonts = {
        "heading": font_heading, "body": font_body, "mono": font_mono,
        "heading_size": heading_size, "body_size": body_size,
    }
    await db.commit()

    return RedirectResponse(url="/profile/", status_code=303)


@router.post("/{theme_id}/apply-preset")
async def apply_preset(
    theme_id: str,
    preset_key: str = Form(...),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Apply a preset color scheme."""
    if preset_key not in PRESETS:
        raise HTTPException(status_code=400)

    result = await db.execute(
        select(UserTheme).where(UserTheme.theme_id == UUID(theme_id), UserTheme.user_id == user.user_id)
    )
    theme = result.scalar_one_or_none()
    if not theme:
        raise HTTPException(status_code=404)

    preset = PRESETS[preset_key]
    theme.is_dark = preset["is_dark"]
    theme.colors = preset["colors"]

    await db.commit()
    return RedirectResponse(url=f"/profile/theme-editor/{theme_id}", status_code=303)
