"""
Abstract base class for DWMB plugins.

All plugins must subclass PluginBase and implement register().
"""
from abc import ABC, abstractmethod
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from fastapi import FastAPI


class PluginBase(ABC):
    """Base class for all DWMB plugins."""

    name: str = "unnamed"
    description: str = ""
    version: str = "0.1.0"

    @abstractmethod
    def register(self, app: "FastAPI") -> None:
        """
        Register the plugin with the FastAPI application.

        Override this method to:
        - Add routers via app.include_router()
        - Add middleware via app.add_middleware()
        - Register event handlers
        - Initialize services
        """
        ...

    def get_routers(self) -> list:
        """Return list of APIRouter instances to register. Override if needed."""
        return []

    def get_middleware(self) -> list:
        """Return list of middleware classes to add. Override if needed."""
        return []

    async def on_startup(self) -> None:
        """Called when the application starts. Override for initialization."""
        pass

    async def on_shutdown(self) -> None:
        """Called when the application shuts down. Override for cleanup."""
        pass

    def get_info(self) -> dict:
        """Return plugin metadata."""
        return {
            "name": self.name,
            "description": self.description,
            "version": self.version,
        }
