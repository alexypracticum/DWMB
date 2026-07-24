"""Admin: Security Settings — CORS, rate limiting, CSRF, SECRET_KEY."""
import json
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

SECURITY_KEYS = {
    "security_cors_origins": {"label": "CORS Origins", "description": "Comma-separated list of allowed origins", "default": "http://localhost:8000,http://127.0.0.1:8000"},
    "security_rate_limit": {"label": "Rate Limit (requests/min)", "description": "Max requests per minute per IP", "default": "200"},
    "security_auth_rate_limit": {"label": "Auth Rate Limit (requests/min)", "description": "Max auth requests per minute per IP", "default": "10"},
    "security_csrf_enabled": {"label": "CSRF Protection", "description": "Enable/disable CSRF token validation", "default": "true", "type": "checkbox"},
}


async def _get_security_settings(db: AsyncSession) -> dict:
    result = await db.execute(select(AppSetting).where(AppSetting.key.in_(SECURITY_KEYS.keys())))
    return {row.key: row.value for row in result.scalars().all()}


@router.get("/security", response_class=HTMLResponse)
async def security_page(request: Request, db: AsyncSession = Depends(get_db), user=Depends(require_permission("admin.access"))):
    from app.config import get_settings
    settings_obj = get_settings()
    db_settings = await _get_security_settings(db)

    items = []
    for key, meta in SECURITY_KEYS.items():
        db_val = db_settings.get(key, "")
        if key == "security_cors_origins":
            env_val = ",".join(settings_obj.CORS_ORIGINS)
        elif key == "security_rate_limit":
            env_val = "200"
        elif key == "security_auth_rate_limit":
            env_val = "10"
        elif key == "security_csrf_enabled":
            env_val = "true"
        else:
            env_val = ""
        current = db_val if db_val else env_val
        items.append({
            "key": key, "label": meta["label"], "description": meta["description"],
            "value": current, "type": meta.get("type", "text"),
            "source": "database" if db_val else "default",
        })

    secret_key = settings_obj.SECRET_KEY
    is_default = secret_key == "dwmb-super-secret-key-change-in-production"
    is_short = len(secret_key) < 32

    return templates.TemplateResponse("admin/security.html", {
        "request": request, "user": user, "items": items,
        "secret_key_status": "default" if is_default else ("short" if is_short else "ok"),
        "secret_key_length": len(secret_key),
    })


@router.post("/security")
async def security_save(request: Request, db: AsyncSession = Depends(get_db), user=Depends(require_permission("admin.access"))):
    form = await request.form()
    for key, meta in SECURITY_KEYS.items():
        if meta.get("type") == "checkbox":
            val = "true" if form.get(key) else "false"
        else:
            val = form.get(key, "").strip()
        result = await db.execute(select(AppSetting).where(AppSetting.key == key))
        setting = result.scalar_one_or_none()
        if setting:
            setting.value = val
            setting.updated_by = user.username if hasattr(user, 'username') else "admin"
        else:
            db.add(AppSetting(key=key, value=val, updated_by=user.username if hasattr(user, 'username') else "admin"))
    await db.commit()
    return RedirectResponse("/admin/security", status_code=303)
