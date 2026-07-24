"""Admin: Email Settings — SMTP configuration."""
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

EMAIL_KEYS = {
    "email_smtp_host": {"label": "SMTP Host", "default": ""},
    "email_smtp_port": {"label": "SMTP Port", "default": "587"},
    "email_smtp_user": {"label": "SMTP Username", "default": ""},
    "email_smtp_password": {"label": "SMTP Password", "default": "", "type": "password"},
    "email_smtp_from": {"label": "From Address", "default": "noreply@dwmb.local"},
    "email_smtp_tls": {"label": "Use TLS", "default": "true", "type": "checkbox"},
}


async def _get_email_settings(db: AsyncSession) -> dict:
    result = await db.execute(select(AppSetting).where(AppSetting.key.in_(EMAIL_KEYS.keys())))
    return {row.key: row.value for row in result.scalars().all()}


@router.get("/email-settings", response_class=HTMLResponse)
async def email_settings_page(request: Request, db: AsyncSession = Depends(get_db), user=Depends(require_permission("admin.access"))):
    from app.config import get_settings
    settings_obj = get_settings()
    db_settings = await _get_email_settings(db)

    items = []
    for key, meta in EMAIL_KEYS.items():
        db_val = db_settings.get(key, "")
        env_val = ""
        env_map = {"email_smtp_host": "SMTP_HOST", "email_smtp_port": "SMTP_PORT", "email_smtp_user": "SMTP_USER",
                    "email_smtp_password": "SMTP_PASSWORD", "email_smtp_from": "SMTP_FROM", "email_smtp_tls": "SMTP_TLS"}
        if key in env_map:
            env_val = str(getattr(settings_obj, env_map[key], ""))
        current = db_val if db_val else env_val
        items.append({
            "key": key, "label": meta["label"], "value": current,
            "type": meta.get("type", "text"), "default": meta["default"],
            "source": "database" if db_val else ("env" if env_val else "default"),
        })

    return templates.TemplateResponse("admin/email_settings.html", {
        "request": request, "user": user, "items": items,
    })


@router.post("/email-settings")
async def email_settings_save(request: Request, db: AsyncSession = Depends(get_db), user=Depends(require_permission("admin.access"))):
    form = await request.form()
    for key, meta in EMAIL_KEYS.items():
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
    return RedirectResponse("/admin/email-settings", status_code=303)
