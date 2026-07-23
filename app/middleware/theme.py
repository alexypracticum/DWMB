"""
Middleware that loads the active theme for every request and makes it
available to templates via request.state.theme / request.state.theme_css.
Also provides i18n translations based on user's language preference.

v0.8.0: Translations loaded exclusively from DB (ui_string entities).
v0.9.0: Added caching to reduce DB queries per request.
"""
import time
import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from jose import JWTError, jwt
from sqlalchemy import select

from app.database import async_session
from app.config import get_settings
from app.models.users import UserAccount
from app.models.themes import UserTheme
from app.models.languages import Language

logger = logging.getLogger(__name__)
settings = get_settings()

# In-memory cache for user data ( TTL 5 minutes )
_user_cache: dict[str, dict] = {}
_user_cache_ttl = 300  # 5 minutes

# Cache for language codes (language_id -> code)
_lang_cache: dict[str, str] = {}

# Cache for translations (lang -> dict)
_translations_cache: dict[str, dict] = {}
_translations_cache_ttl = 300  # 5 minutes


def invalidate_translations_cache(lang: str = None):
    """Invalidate translations cache for a specific language or all languages."""
    global _translations_cache
    if lang:
        # Remove specific language from cache
        keys_to_remove = [k for k in _translations_cache.keys() if k.endswith(f":{lang}")]
        for key in keys_to_remove:
            del _translations_cache[key]
    else:
        # Clear all translations cache
        _translations_cache.clear()

# Cache for themes (theme_id -> theme_data)
_theme_cache: dict[str, dict] = {}
_theme_cache_ttl = 300


def _get_cached_user(username: str) -> dict | None:
    """Get user from cache if valid."""
    entry = _user_cache.get(username)
    if entry and entry["expires"] > time.time():
        return entry["data"]
    return None


def _set_cached_user(username: str, data: dict) -> None:
    """Set user in cache."""
    _user_cache[username] = {
        "data": data,
        "expires": time.time() + _user_cache_ttl
    }


class ThemeMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request.state.theme = None
        request.state.theme_css = ""
        request.state.lang = "ru"
        request.state.t = {}

        token = request.cookies.get("access_token")
        if token:
            try:
                payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
                username = payload.get("sub")
                if username:
                    # Try cache first
                    cached = _get_cached_user(username)
                    if cached:
                        request.state.lang = cached.get("lang", "ru")
                        request.state.t = cached.get("translations", {})
                        if cached.get("theme"):
                            request.state.theme = cached["theme"]
                            request.state.theme_css = cached.get("theme_css", "")
                    else:
                        # Cache miss - query DB
                        async with async_session() as session:
                            result = await session.execute(
                                select(UserAccount).where(UserAccount.username == username)
                            )
                            user = result.scalar_one_or_none()
                            if user:
                                lang = "ru"
                                if user.language_id:
                                    lang_id_str = str(user.language_id)
                                    if lang_id_str in _lang_cache:
                                        lang = _lang_cache[lang_id_str]
                                    else:
                                        lang_result = await session.execute(
                                            select(Language.code).where(Language.language_id == user.language_id)
                                        )
                                        lang = lang_result.scalar_one_or_none() or "ru"
                                        _lang_cache[lang_id_str] = lang
                                request.state.lang = lang
                                
                                # Load translations (with cache)
                                translations = {}
                                trans_cache_key = f"trans:{lang}"
                                if trans_cache_key in _translations_cache and _translations_cache[trans_cache_key].get("expires", 0) > time.time():
                                    translations = _translations_cache[trans_cache_key]["data"]
                                else:
                                    try:
                                        from app.services.ui_strings import get_all_ui_strings_dict
                                        translations = await get_all_ui_strings_dict(session, lang)
                                        _translations_cache[trans_cache_key] = {
                                            "data": translations,
                                            "expires": time.time() + _translations_cache_ttl
                                        }
                                    except Exception:
                                        translations = {}
                                request.state.t = translations
                                
                                # Load theme (with cache)
                                theme_data = None
                                theme_css = ""
                                if user.theme_id:
                                    theme_id_str = str(user.theme_id)
                                    if theme_id_str in _theme_cache and _theme_cache[theme_id_str].get("expires", 0) > time.time():
                                        cached_theme = _theme_cache[theme_id_str]["data"]
                                        request.state.theme = cached_theme
                                        request.state.theme_css = cached_theme.get("css", "")
                                    else:
                                        theme_result = await session.execute(
                                            select(UserTheme).where(UserTheme.theme_id == user.theme_id)
                                        )
                                        theme = theme_result.scalar_one_or_none()
                                        if theme:
                                            from app.services.theme import theme_css_variables
                                            theme_css = theme_css_variables({
                                                "is_dark": theme.is_dark,
                                                "colors": theme.colors,
                                                "fonts": theme.fonts,
                                            })
                                            request.state.theme = theme
                                            request.state.theme_css = theme_css
                                            _theme_cache[theme_id_str] = {
                                                "data": theme,
                                                "css": theme_css,
                                                "expires": time.time() + _theme_cache_ttl
                                            }
                                
                                # Cache user data
                                _set_cached_user(username, {
                                    "lang": lang,
                                    "translations": translations,
                                    "theme": request.state.theme,
                                    "theme_css": theme_css,
                                })
            except JWTError:
                pass

        # Always check cookie for language preference
        cookie_lang = request.cookies.get("lang")
        if cookie_lang and cookie_lang in ("ru", "en", "de", "fr", "es", "zh", "ja"):
            request.state.lang = cookie_lang
            # Load translations for cookie language (with cache)
            trans_cache_key = f"trans:{cookie_lang}"
            if trans_cache_key in _translations_cache and _translations_cache[trans_cache_key].get("expires", 0) > time.time():
                request.state.t = _translations_cache[trans_cache_key]["data"]
            else:
                try:
                    async with async_session() as session:
                        from app.services.ui_strings import get_all_ui_strings_dict
                        translations = await get_all_ui_strings_dict(session, cookie_lang)
                        request.state.t = translations
                        logger.info(f"Loaded {len(translations)} translations for {cookie_lang}")
                        logger.info(f"nav_map in translations: {'nav_map' in translations}")
                        logger.info(f"nav_map value: {translations.get('nav_map')}")
                        _translations_cache[trans_cache_key] = {
                            "data": translations,
                            "expires": time.time() + _translations_cache_ttl
                        }
                except Exception:
                    request.state.t = {}

        # Load translations for unauthenticated users without lang cookie
        if not request.state.t:
            try:
                async with async_session() as session:
                    from app.services.ui_strings import get_all_ui_strings_dict
                    request.state.t = await get_all_ui_strings_dict(session, "ru")
            except Exception:
                request.state.t = {}

        # Dark mode cookie for unauthenticated users (no theme set)
        if not request.state.theme and request.cookies.get("dark_mode") == "1":
            request.state.theme_css = (
                "--color-primary: #818cf8; --color-secondary: #a78bfa; --color-accent: #fbbf24; "
                "--color-bg: #0f172a; --color-surface: #1e293b; --color-text: #f1f5f9; "
                "--color-text-secondary: #94a3b8; --color-border: #334155; --color-error: #f87171; --color-success: #34d399;"
            )

        response = await call_next(request)
        return response
