"""
Theme service — loads active theme for the current user.
"""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.users import UserAccount
from app.models.themes import UserTheme


async def get_active_theme(user: UserAccount | None, db: AsyncSession) -> dict:
    """Return the active theme colors/fonts for a user, or defaults."""
    if user and user.theme_id:
        result = await db.execute(
            select(UserTheme).where(UserTheme.theme_id == user.theme_id)
        )
        theme = result.scalar_one_or_none()
        if theme:
            return {
                "is_dark": theme.is_dark,
                "colors": theme.colors,
                "fonts": theme.fonts,
            }

    # Default: light theme
    return {
        "is_dark": False,
        "colors": {
            "primary": "#3b82f6",
            "secondary": "#6366f1",
            "accent": "#f59e0b",
            "background": "#ffffff",
            "surface": "#f9fafb",
            "text": "#111827",
            "text_secondary": "#6b7280",
            "border": "#e5e7eb",
            "error": "#ef4444",
            "success": "#10b981",
        },
        "fonts": {
            "heading": "Inter, sans-serif",
            "body": "Inter, sans-serif",
            "mono": "JetBrains Mono, monospace",
            "heading_size": "1.5rem",
            "body_size": "0.875rem",
        },
    }


def theme_css_variables(theme: dict) -> str:
    """Generate CSS custom properties string from theme dict."""
    c = theme["colors"]
    f = theme["fonts"]
    return f"""
        --color-primary: {c['primary']};
        --color-secondary: {c['secondary']};
        --color-accent: {c['accent']};
        --color-bg: {c['background']};
        --color-surface: {c['surface']};
        --color-text: {c['text']};
        --color-text-secondary: {c['text_secondary']};
        --color-border: {c['border']};
        --color-error: {c['error']};
        --color-success: {c['success']};
        --font-heading: {f['heading']};
        --font-body: {f['body']};
        --font-mono: {f['mono']};
        --font-heading-size: {f['heading_size']};
        --font-body-size: {f['body_size']};
    """
