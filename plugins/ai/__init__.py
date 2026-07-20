"""
AI plugin — integrates OpenAI embeddings, chat, and entity parsing.

This plugin wraps the existing AI service and routes.
"""
from plugins.base import PluginBase


class AIPlugin(PluginBase):
    name = "ai"
    description = "AI integration: embeddings, chat, entity parsing, hybrid search"
    version = "0.1.0"

    def register(self, app):
        from app.routes.ai import router
        app.include_router(router)


plugin = AIPlugin()
