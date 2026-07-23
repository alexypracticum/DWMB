"""API endpoint for language switching with autosave."""
from fastapi import APIRouter, Request, Depends
from fastapi.responses import JSONResponse
from sqlalchemy import select
from jose import JWTError, jwt

from app.config import get_settings
from app.database import async_session
from app.models.languages import Language
from app.models.users import UserAccount
from app.services.language import clear_language_cache

router = APIRouter(prefix="/api", tags=["api"])
settings = get_settings()


@router.post("/set-language")
async def set_language_api(request: Request):
    """Set language preference via AJAX (no page reload)."""
    try:
        body = await request.json()
        lang = body.get("lang", "ru")
    except Exception:
        return JSONResponse({"error": "Invalid request"}, status_code=400)
    
    valid_langs = ("ru", "en", "de", "fr", "es", "zh", "ja")
    if lang not in valid_langs:
        lang = "ru"
    
    # Save to user profile if logged in
    token = request.cookies.get("access_token")
    if token:
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
            username = payload.get("sub")
            if username:
                async with async_session() as session:
                    result = await session.execute(
                        select(UserAccount).where(UserAccount.username == username)
                    )
                    user = result.scalar_one_or_none()
                    if user:
                        lang_result = await session.execute(
                            select(Language.language_id).where(Language.code == lang)
                        )
                        lang_id = lang_result.scalar_one_or_none()
                        if lang_id:
                            user.language_id = lang_id
                            await session.commit()
                            clear_language_cache()
        except JWTError:
            pass
    
    # Invalidate translations cache for this language
    from app.middleware.theme import invalidate_translations_cache
    invalidate_translations_cache(lang)
    
    response = JSONResponse({"success": True, "lang": lang})
    response.set_cookie("lang", lang, max_age=365 * 24 * 3600, httponly=False)
    
    return response
