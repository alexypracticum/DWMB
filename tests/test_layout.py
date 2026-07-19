"""
Unit tests for layout rendering service.
"""
from app.services.layout import (
    render_layout, render_block_html, get_state_field,
    BLOCK_TYPES, RU_LABELS,
)


def test_get_state_field_simple():
    data = {"title": "Matrix", "year": 1999}
    assert get_state_field(data, "title") == "Matrix"
    assert get_state_field(data, "year") == 1999


def test_get_state_field_nested():
    data = {"meta": {"name": "test"}}
    assert get_state_field(data, "meta.name") == "test"


def test_get_state_field_missing():
    data = {"title": "Matrix"}
    assert get_state_field(data, "missing") is None
    assert get_state_field(data, "") is None
    assert get_state_field(None, "title") is None


def test_render_block_hero_image():
    block = {"type": "hero_image", "config": {"source": "poster_url", "alt_field": "title"}}
    state = {"poster_url": "http://example.com/poster.jpg", "title": "Matrix"}
    html = render_block_html(block, state)
    assert "http://example.com/poster.jpg" in html
    assert "Matrix" in html


def test_render_block_hero_image_empty():
    block = {"type": "hero_image", "config": {"source": "poster_url"}}
    html = render_block_html(block, {})
    assert html == ""


def test_render_block_text_block():
    block = {"type": "text_block", "config": {}}
    state = {"description": "A great movie"}
    html = render_block_html(block, state)
    assert "great movie" in html


def test_render_block_divider():
    block = {"type": "divider", "config": {}}
    html = render_block_html(block, {})
    assert "<hr" in html


def test_render_block_spacer():
    block = {"type": "spacer", "config": {"height": "40"}}
    html = render_block_html(block, {})
    assert "40px" in html


def test_render_block_info_table():
    block = {"type": "info_table", "config": {"fields": '[{"key":"year","label":"Год"}]'}}
    state = {"year": 1999}
    html = render_block_html(block, state)
    assert "1999" in html
    assert "Год" in html


def test_render_block_image_data_row():
    block = {"type": "image_data_row", "config": {
        "image_source": "poster",
        "alt_field": "title",
        "fields": '[{"key":"year","label":"Год","type":"integer"},{"key":"genre","label":"Жанр"}]'
    }}
    state = {"poster": "http://img.jpg", "title": "Matrix", "year": 1999, "genre": "Sci-Fi"}
    html = render_block_html(block, state)
    assert "http://img.jpg" in html
    assert "1999" in html
    assert "Sci-Fi" in html


def test_render_block_video():
    block = {"type": "video", "config": {"source": "video_url"}}
    state = {"video_url": "https://youtube.com/watch?v=abc123"}
    html = render_block_html(block, state)
    assert "youtube.com/embed/abc123" in html


def test_render_layout_empty():
    assert render_layout([], {}) == ""
    assert render_layout(None, {}) == ""
    assert render_layout("invalid json", {}) == ""


def test_render_layout_multiple_blocks():
    blocks = [
        {"type": "divider", "config": {}},
        {"type": "spacer", "config": {"height": "20"}},
    ]
    html = render_layout(blocks, {})
    assert "<hr" in html
    assert "20px" in html


def test_block_types_complete():
    """All defined block types should have required keys."""
    required_keys = {"name", "icon", "description", "config_fields"}
    for btype, meta in BLOCK_TYPES.items():
        for key in required_keys:
            assert key in meta, f"Block type '{btype}' missing '{key}'"


def test_ru_labels_cover_common_keys():
    """RU_LABELS should cover common field keys."""
    common_keys = ["year", "genre", "title", "director", "rating", "description"]
    for key in common_keys:
        assert key in RU_LABELS, f"RU_LABELS missing key '{key}'"
