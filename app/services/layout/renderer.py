"""Main layout renderer."""
from .block_renderers import render_block_html
def render_layout(layout_blocks, state_data: dict, relations: dict = None, entity_id: str = None, lang: str = "ru", t: dict = None) -> str:
    """Render full layout from block definitions."""
    if isinstance(layout_blocks, str):
        try:
            import json
            layout_blocks = json.loads(layout_blocks)
        except Exception:
            return ""
    if not isinstance(layout_blocks, list) or not layout_blocks:
        return ""

    html_parts = []
    for block in layout_blocks:
        btype = block.get("type", "")
        width = block.get("width", "full")

        if btype == "columns" and "children" in block:
            left_blocks = [c for c in block["children"] if c.get("width") == "left"]
            right_blocks = [c for c in block["children"] if c.get("width") == "right"]
            left_html = "".join(render_block_html(b, state_data, relations, entity_id, lang, t) for b in left_blocks)
            right_html = "".join(render_block_html(b, state_data, relations, entity_id, lang, t) for b in right_blocks)
            left_w = block.get("config", {}).get("left_width", "40%")
            right_w = block.get("config", {}).get("right_width", "60%")
            html_parts.append(
                f'<div class="flex flex-col md:flex-row gap-6 my-4">'
                f'<div style="width:{left_w}; flex-shrink:0;">{left_html}</div>'
                f'<div style="width:{right_w};">{right_html}</div>'
                f'</div>'
            )
        elif btype == "horizontal_row" and "children" in block:
            cols = int(block.get("config", {}).get("columns", "2") or "2")
            cols = max(2, min(5, cols))
            children = block.get("children", [])
            col_width = f"{100 / cols}%"
            col_html = ""
            for child in children:
                col_html += f'<div style="width:{col_width}; flex-shrink:0;">{render_block_html(child, state_data, relations, entity_id, lang, t)}</div>'
            html_parts.append(f'<div class="flex flex-col md:flex-row gap-4 my-4">{col_html}</div>')
        else:
            html_parts.append(render_block_html(block, state_data, relations, entity_id, lang, t))

    return "\n".join(html_parts)
