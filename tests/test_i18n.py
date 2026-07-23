"""Tests for i18n service."""
import pytest


def test_i18n_service_imports():
    """Test that i18n service imports work."""
    from app.services.ui_strings import get_all_ui_strings_dict
    assert callable(get_all_ui_strings_dict)
