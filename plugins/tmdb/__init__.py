"""
TMDB plugin — movie and person import from The Movie Database.

This plugin wraps the existing TMDB service and routes.
"""
from plugins.base import PluginBase


class TMDBPlugin(PluginBase):
    name = "tmdb"
    description = "TMDB import: movies, people, credits, genres"
    version = "0.1.0"

    def register(self, app):
        from app.routes.import_api import router
        app.include_router(router)


plugin = TMDBPlugin()
