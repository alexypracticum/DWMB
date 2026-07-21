"""
Middleware that loads the active theme for every request and makes it
available to templates via request.state.theme / request.state.theme_css.
Also provides i18n translations based on user's language preference.

v0.8.0: Translations loaded exclusively from DB (ui_string entities).
"""
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from jose import JWTError, jwt
from sqlalchemy import select

from app.database import async_session
from app.config import get_settings
from app.models.users import UserAccount
from app.models.themes import UserTheme
from app.models.languages import Language

settings = get_settings()


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
                    async with async_session() as session:
                        result = await session.execute(
                            select(UserAccount).where(UserAccount.username == username)
                        )
                        user = result.scalar_one_or_none()
                        if user:
                            # Get language code from language_id FK
                            lang = "ru"
                            if user.language_id:
                                lang_result = await session.execute(
                                    select(Language.code).where(Language.language_id == user.language_id)
                                )
                                lang = lang_result.scalar_one_or_none() or "ru"
                            request.state.lang = lang
                            
                            # Load translations from DB
                            try:
                                from app.services.ui_translations import get_translation_dict
                                request.state.t = await get_translation_dict(session, lang)
                            except Exception:
                                request.state.t = {}
                            
                            if user.theme_id:
                                theme_result = await session.execute(
                                    select(UserTheme).where(UserTheme.theme_id == user.theme_id)
                                )
                                theme = theme_result.scalar_one_or_none()
                                if theme:
                                    request.state.theme = theme
                                    from app.services.theme import theme_css_variables
                                    request.state.theme_css = theme_css_variables({
                                        "is_dark": theme.is_dark,
                                        "colors": theme.colors,
                                        "fonts": theme.fonts,
                                    })
            except JWTError:
                pass

        # Fallback to lang cookie if no user language set
        if request.state.lang == "ru" and not token:
            cookie_lang = request.cookies.get("lang")
            if cookie_lang and cookie_lang in ("ru", "en", "de", "fr", "es", "zh", "ja"):
                request.state.lang = cookie_lang
                try:
                    async with async_session() as session:
                        from app.services.ui_translations import get_translation_dict
                        request.state.t = await get_translation_dict(session, cookie_lang)
                except Exception:
                    request.state.t = {}

        response = await call_next(request)
        return response
