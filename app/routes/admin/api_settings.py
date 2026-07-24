"""Admin: API Settings — manage API keys (OMDB, Last.fm, TMDB, AI)."""
from fastapi import APIRouter, Depends, Request, Form
from fastapi.responses import RedirectResponse, HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.app_settings import AppSetting
from app.services.rbac import require_permission

templates = Jinja2Templates(directory="app/templates")
router = APIRouter(tags=["admin"])

API_KEYS = {
    "api_omdb_key": {"label": "OMDb API Key", "description": "Open Movie Database — https://www.omdbapi.com/apikey.aspx", "env_key": "OMDB_API_KEY"},
    "api_lastfm_key": {"label": "Last.fm API Key", "description": "Last.fm — https://www.last.fm/api/account/create", "env_key": "LASTFM_API_KEY"},
    "api_tmdb_key": {"label": "TMDB API Key", "description": "The Movie Database — https://www.themoviedb.org/settings/api", "env_key": "TMDB_API_KEY"},
    "api_ai_key": {"label": "AI API Key", "description": "OpenAI API key for embeddings and chat", "env_key": "AI_API_KEY"},
}


async def _get_settings(db: AsyncSession) -> dict:
    result = await db.execute(select(AppSetting).where(AppSetting.key.in_(API_KEYS.keys())))
    return {row.key: row.value for row in result.scalars().all()}


@router.get("/api-settings", response_class=HTMLResponse)
async def api_settings_page(request: Request, db: AsyncSession = Depends(get_db), user=Depends(require_permission("admin.access"))):
    from app.config import get_settings
    settings_obj = get_settings()
    db_settings = await _get_settings(db)

    items = []
    for key, meta in API_KEYS.items():
        db_val = db_settings.get(key, "")
        env_val = getattr(settings_obj, meta["env_key"], "")
        current = db_val or env_val
        items.append({
            "key": key, "label": meta["label"], "description": meta["description"],
            "value": current, "source": "database" if db_val else ("env" if env_val else "not set"),
        })

    return templates.TemplateResponse("admin/api_settings.html", {
        "request": request, "user": user, "items": items,
    })


@router.post("/api-settings")
async def api_settings_save(request: Request, db: AsyncSession = Depends(get_db), user=Depends(require_permission("admin.access"))):
    form = await request.form()
    for key in API_KEYS:
        val = form.get(key, "").strip()
        result = await db.execute(select(AppSetting).where(AppSetting.key == key))
        setting = result.scalar_one_or_none()
        if setting:
            setting.value = val
            setting.updated_by = user.username if hasattr(user, 'username') else "admin"
        else:
            db.add(AppSetting(key=key, value=val, updated_by=user.username if hasattr(user, 'username') else "admin"))
    await db.commit()
    return RedirectResponse("/admin/api-settings", status_code=303)
