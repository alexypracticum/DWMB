"""
Plugin system for DWMB.

Plugins are Python packages under the `plugins/` directory.
Each plugin must define a module-level `plugin` variable that is an instance
of a PluginBase subclass.

Usage in main.py:
    from plugins import load_plugins
    load_plugins(app)
"""
import importlib
import logging
import os
from pathlib import Path

logger = logging.getLogger(__name__)

_plugins: list = []


def get_plugins() -> list:
    """Return list of registered plugin instances."""
    return _plugins


def load_plugins(app) -> None:
    """
    Discover and register all plugins from the plugins/ directory.

    Each plugin package must have an __init__.py that exposes:
        plugin = SomePlugin()
    """
    plugins_dir = Path(__file__).parent
    for entry in sorted(plugins_dir.iterdir()):
        if not entry.is_dir():
            continue
        if entry.name.startswith("_") or entry.name in ("__pycache__",):
            continue
        init_file = entry / "__init__.py"
        if not init_file.exists():
            continue

        try:
            module = importlib.import_module(f"plugins.{entry.name}")
            plugin_instance = getattr(module, "plugin", None)
            if plugin_instance is None:
                logger.warning("Plugin '%s' has no 'plugin' variable, skipping", entry.name)
                continue

            plugin_instance.register(app)
            _plugins.append(plugin_instance)
            logger.info("Loaded plugin: %s", entry.name)
        except Exception as e:
            logger.error("Failed to load plugin '%s': %s", entry.name, e)
