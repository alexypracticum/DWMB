"""
CMS plugin — page registry, menus, and content management.

This plugin wraps the existing page management routes.
"""
from plugins.base import PluginBase


class CMSPlugin(PluginBase):
    name = "cms"
    description = "CMS: page registry, hierarchical menus, content management"
    version = "0.1.0"

    def register(self, app):
        from app.routes.page_management import router
        app.include_router(router)


plugin = CMSPlugin()
