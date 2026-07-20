"""
Themes plugin — user-customizable visual themes with CSS variables.

This plugin wraps the existing theme system: models, service, middleware, and editor.
"""
from plugins.base import PluginBase


class ThemesPlugin(PluginBase):
    name = "themes"
    description = "Visual themes: CSS variables, presets, theme editor"
    version = "0.1.0"

    def register(self, app):
        from app.routes.theme_editor import router
        app.include_router(router)


plugin = ThemesPlugin()
