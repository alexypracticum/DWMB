"""Tests for plugin system."""
import pytest
from plugins import get_plugins, get_plugins_info
from plugins.base import PluginBase


def test_plugin_base_class():
    """Test PluginBase abstract class."""
    assert hasattr(PluginBase, 'name')
    assert hasattr(PluginBase, 'description')
    assert hasattr(PluginBase, 'version')
    assert hasattr(PluginBase, 'register')
    assert hasattr(PluginBase, 'on_startup')
    assert hasattr(PluginBase, 'on_shutdown')
    assert hasattr(PluginBase, 'get_info')


def test_plugins_loaded():
    """Test that plugins are loaded."""
    plugins = get_plugins()
    assert len(plugins) > 0


def test_plugins_info():
    """Test that plugin info is available."""
    info = get_plugins_info()
    assert len(info) > 0
    for plugin_info in info:
        assert 'name' in plugin_info
        assert 'description' in plugin_info
        assert 'version' in plugin_info


def test_plugin_names():
    """Test that expected plugins are loaded."""
    info = get_plugins_info()
    names = [p['name'] for p in info]
    assert 'ai' in names
    assert 'cms' in names
    assert 'stats' in names
    assert 'themes' in names
    assert 'tmdb' in names
