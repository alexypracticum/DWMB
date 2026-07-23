"""Tests for multilingual functionality."""
import pytest


def test_ui_strings_service():
    """Test UI strings service."""
    from app.services.ui_strings import get_all_ui_strings_dict, get_ui_strings_dict
    assert callable(get_all_ui_strings_dict)
    assert callable(get_ui_strings_dict)
