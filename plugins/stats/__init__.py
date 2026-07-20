"""
Stats plugin — dashboard with entity/kind/relation statistics.

This plugin wraps the existing statistics route.
"""
from plugins.base import PluginBase


class StatsPlugin(PluginBase):
    name = "stats"
    description = "Statistics dashboard with charts and aggregates"
    version = "0.1.0"

    def register(self, app):
        from app.routes.stats import router
        app.include_router(router)


plugin = StatsPlugin()
