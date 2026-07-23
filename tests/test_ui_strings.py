"""Tests for UI Strings service."""
import pytest
from app.services.ui_strings import get_ui_string, get_ui_strings_dict, get_all_ui_strings_dict


def test_ui_strings_service_exists():
    """Test that UI strings service functions exist."""
    assert callable(get_ui_string)
    assert callable(get_ui_strings_dict)
    assert callable(get_all_ui_strings_dict)
