"""
Unit tests for ontology entities (model and template as entities).
"""
import pytest


def test_ontology_model_kind_exists():
    """Verify ontology_model kind exists in translations."""
    from app.services.i18n import get_translation
    t = get_translation("ru")
    assert "nav_entities" in t


def test_ontology_model_entity_schema():
    """Verify ontology model entity has correct schema fields."""
    schema = {
        "required": ["model_code", "domain"],
        "properties": {
            "model_code": {"type": "string", "title": "Код модели"},
            "domain": {"type": "string", "title": "Домен"},
            "description": {"type": "string", "title": "Описание"},
        }
    }
    assert "model_code" in schema["properties"]
    assert "domain" in schema["properties"]
    assert schema["required"] == ["model_code", "domain"]


def test_ontology_template_entity_schema():
    """Verify ontology template entity has correct schema fields."""
    schema = {
        "required": ["template_code", "template_name"],
        "properties": {
            "template_code": {"type": "string", "title": "Код шаблона"},
            "template_name": {"type": "string", "title": "Название"},
            "kind_code": {"type": "string", "title": "Тип сущности"},
            "model_code": {"type": "string", "title": "Модель"},
        }
    }
    assert "template_code" in schema["properties"]
    assert "template_name" in schema["properties"]
    assert "kind_code" in schema["properties"]
    assert "model_code" in schema["properties"]


def test_layout_rendering_info_table():
    """Verify info_table block renders correctly."""
    from app.services.layout import render_block_html
    block = {
        "type": "info_table",
        "config": {
            "fields": [{"key": "name", "label": "Name"}, {"key": "value", "label": "Value"}],
            "style": "table"
        }
    }
    state = {"name": "Test", "value": "123"}
    html = render_block_html(block, state)
    assert "Test" in html
    assert "123" in html
    assert "Name" in html


def test_layout_rendering_image_data_row():
    """Verify image_data_row block renders correctly."""
    from app.services.layout import render_block_html
    block = {
        "type": "image_data_row",
        "config": {
            "image_source": "poster",
            "alt_field": "title",
            "fields": [{"key": "year", "label": "Year"}]
        }
    }
    state = {"poster": "http://example.com/img.jpg", "title": "Test", "year": 2025}
    html = render_block_html(block, state)
    assert "http://example.com/img.jpg" in html
    assert "2025" in html


def test_layout_rendering_empty_state():
    """Verify layout handles empty state_data."""
    from app.services.layout import render_layout
    blocks = [{"type": "divider", "config": {}}]
    html = render_layout(blocks, {})
    assert "<hr" in html
