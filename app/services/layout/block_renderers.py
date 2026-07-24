"""Block rendering functions."""
from .helpers import get_label, get_state_field, get_localized_value, _replace_variables
def render_block_html(block: dict, state_data: dict, relations: dict = None, entity_id: str = None, lang: str = "ru", t: dict = None) -> str:
    """Render a single block to HTML."""
    btype = block.get("type", "text_block")
    config = block.get("config", {})
    bid = block.get("id", "")

    if btype == "hero_image":
        src = get_state_field(state_data, config.get("source", "")) or ""
        alt = get_state_field(state_data, config.get("alt_field", "")) or ""
        if not src:
            return ""
        return f'<div class="w-full rounded-xl overflow-hidden mb-6 bg-gray-200"><img src="{src}" alt="{alt}" class="w-full object-cover" style="max-height:500px;"></div>'

    elif btype == "image":
        src = get_state_field(state_data, config.get("source", "")) or ""
        alt = get_state_field(state_data, config.get("alt_field", "")) or ""
        caption = get_state_field(state_data, config.get("caption", "")) or config.get("caption", "")
        height = config.get("height", "")
        if not src:
            return ""
        style = f' style="max-height:{height}px; object-fit:cover;"' if height else ""
        html = f'<div class="my-4"><img src="{src}" alt="{alt}" class="rounded-lg w-full"{style}></div>'
        if caption:
            html = f'<figure class="my-4"><img src="{src}" alt="{alt}" class="rounded-lg w-full"{style}><figcaption class="text-sm text-gray-500 mt-2 text-center">{caption}</figcaption></figure>'
        return html

    elif btype == "gallery":
        images_raw = get_state_field(state_data, config.get("source", "")) or []
        height = config.get("height", "300")
        title_raw = config.get("title", "")
        # Map Russian titles to translation keys
        TITLE_MAP = {
            "Галерея изображений": "block_gallery",
            "Актёры и персонажи": "layout_actors_characters",
        }
        if t and title_raw in TITLE_MAP:
            title = t.get(TITLE_MAP[title_raw], title_raw)
        elif t:
            title = t.get("block_gallery", title_raw)
        else:
            title = title_raw
        if isinstance(images_raw, str):
            images = [u.strip() for u in images_raw.replace("\r\n", "\n").replace("\r", "\n").split("\n") if u.strip()]
        elif isinstance(images_raw, list):
            images = images_raw
        else:
            images = []
        if not images:
            return ""
        from app.config import get_settings as _gs
        _minio_ep = _gs().MINIO_ENDPOINT
        items = ""
        for idx, img_url in enumerate(images):
            if img_url.strip():
                src = img_url.strip()
                if _minio_ep in src:
                    import urllib.parse
                    src = f"/media/proxy?url={urllib.parse.quote(src, safe='')}"
                items += f'<div class="flex-shrink-0 relative group/item"><img src="{src}" class="h-[{height}px] rounded-lg object-cover cursor-pointer hover:opacity-90 transition" alt="" loading="lazy" onclick="openGalleryFullscreen(this.src)" data-fullsrc="{src}"><button onclick="event.stopPropagation();openGalleryFullscreen(\'{src}\')" class="absolute inset-0 flex items-center justify-center opacity-0 group-hover/item:opacity-100 transition pointer-events-none"><svg class="w-10 h-10 text-white drop-shadow-lg" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7"/></svg></button></div>'
        title_html = f'<h3 class="text-xl font-bold text-gray-800 mb-3">{title}</h3>' if title else ''
        return f'''{title_html}<div class="relative group my-4"><button onclick="scrollGallery(this,-1)" class="absolute left-2 top-1/2 -translate-y-1/2 z-10 bg-black/50 hover:bg-black/70 text-white rounded-full w-9 h-9 flex items-center justify-center opacity-0 group-hover:opacity-100 transition shadow-lg backdrop-blur-sm" aria-label="prev"><svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg></button><button onclick="scrollGallery(this,1)" class="absolute right-2 top-1/2 -translate-y-1/2 z-10 bg-black/50 hover:bg-black/70 text-white rounded-full w-9 h-9 flex items-center justify-center opacity-0 group-hover:opacity-100 transition shadow-lg backdrop-blur-sm" aria-label="next"><svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg></button><div class="flex gap-3 overflow-x-auto pb-2 scroll-smooth gallery-scroll" style="scrollbar-width:none;-ms-overflow-style:none;">{items}</div></div>'''

    elif btype == "markdown":
        source = config.get("source", "")
        content = get_state_field(state_data, source) or "" if source else ""
        if not content:
            content = config.get("content", "")
        if not content:
            return ""
        content = _replace_variables(str(content), state_data)
        title = config.get("title", "")
        if title:
            title = _replace_variables(str(title), state_data)
        import markdown as md
        rendered = md.markdown(str(content), extensions=["tables", "fenced_code", "nl2br"])
        max_h = config.get("max_height", "0")
        style = f' style="max-height:{max_h}px; overflow-y:auto;"' if max_h and max_h != "0" else ""
        html = ""
        if title:
            html += f'<h3 class="text-lg font-semibold text-gray-800 mb-2">{title}</h3>'
        html += f'<div class="prose prose-sm max-w-none my-4"{style}>{rendered}</div>'
        return html

    elif btype == "video":
        url = get_state_field(state_data, config.get("source", "")) or ""
        if not url:
            return ""
        aspect = config.get("aspect", "16:9")
        if "youtube.com" in url or "youtu.be" in url:
            video_id = url.split("v=")[-1].split("&")[0] if "v=" in url else url.split("/")[-1]
            return f'<div class="my-4"><div style="padding-bottom:56.25%; position:relative;"><iframe src="https://www.youtube.com/embed/{video_id}" style="position:absolute;inset:0;width:100%;height:100%;" frameborder="0" allowfullscreen></iframe></div></div>'
        return f'<div class="my-4"><video controls class="w-full rounded-lg"><source src="{url}"></video></div>'

    elif btype == "audio":
        url = get_state_field(state_data, config.get("source", "")) or ""
        title = get_state_field(state_data, config.get("title", "")) or ""
        if not url:
            return ""
        return f'<div class="my-4 bg-gray-50 rounded-lg p-4"><p class="text-sm text-gray-600 mb-2">{title}</p><audio controls class="w-full"><source src="{url}"></audio></div>'

    elif btype == "info_table":
        import json as _json
        fields_raw = config.get("fields", "[]")
        if isinstance(fields_raw, str):
            fields = _json.loads(fields_raw) if fields_raw.strip() else []
        else:
            fields = fields_raw or []
        # Auto-generate fields from state_data if config is empty
        if not fields:
            for k, v in state_data.items():
                if v and str(v).strip():
                    fields.append({"key": k, "label": get_label(k, lang, t)})
        style = config.get("style", "table")
        if style == "table":
            rows = ""
            for f in fields:
                fkey = f.get("field_key") or f.get("key", "")
                val = get_localized_value(state_data, fkey, lang) or ""
                if not val and val != 0:
                    continue
                label = f.get("label") or get_label(fkey, lang, t)
                ftype = f.get("type", "string")
                val_str = str(val)
                if ftype == "currency":
                    try: val_html = f'{float(val):,.2f} ₽'
                    except (ValueError, TypeError): val_html = val_str
                elif ftype == "boolean":
                    val_html = '✓ Да' if val_str.lower() in ('true', '1', 'yes') else '✗ Нет'
                elif ftype == "date":
                    val_html = val_str[:10] if len(val_str) >= 10 else val_str
                elif ftype == "url" or val_str.startswith("http"):
                    val_html = f'<a href="{val_str}" target="_blank" class="text-blue-600 hover:underline text-sm">{val_str}</a>'
                elif ftype == "email":
                    val_html = f'<a href="mailto:{val_str}" class="text-blue-600 hover:underline text-sm">{val_str}</a>'
                elif ftype == "image" and val_str.startswith("http"):
                    val_html = f'<img src="{val_str}" class="rounded max-h-24 object-contain">'
                else:
                    val_html = val_str
                rows += f'<tr class="border-b border-gray-100"><td class="py-2 text-sm text-gray-500 font-medium text-right pr-3 whitespace-nowrap">{label}</td><td class="text-gray-400 pr-3">:</td><td class="py-2 text-sm">{val_html}</td></tr>'
            return f'<table class="w-full text-sm my-4">{rows}</table>'
        elif style == "cards":
            cards = ""
            for f in fields:
                fkey2 = f.get("field_key") or f.get("key", "")
                val = get_localized_value(state_data, fkey2, lang) or "-"
                cards += f'<div class="bg-gray-50 rounded-lg p-3 text-center"><div class="text-lg font-bold">{val}</div><div class="text-xs text-gray-500">{f.get("label", fkey2)}</div></div>'
            return f'<div class="grid grid-cols-2 md:grid-cols-4 gap-3 my-4">{cards}</div>'
        else:
            parts = []
            for f in fields:
                val = get_localized_value(state_data, f.get("key", ""), lang) or "-"
                parts.append(f'<span class="text-sm"><span class="text-gray-500">{f.get("label", f["key"])}:</span> <strong>{val}</strong></span>')
            return f'<div class="flex flex-wrap gap-4 my-4">{" ".join(parts)}</div>'

    elif btype == "relation_list":
        rel_type = config.get("relation_type", "")
        display = config.get("display", "list")
        max_items = int(config.get("max_items", "20") or "20")
        rels = (relations or {}).get(rel_type, [])[:max_items]
        if not rels:
            return ""
        items = ""
        for r in rels:
            label = r.get("label", "?")
            eid = r.get("entity_id", "")
            items += f'<a href="/entity/{eid}" class="block px-3 py-2 bg-gray-50 rounded-lg hover:bg-blue-50 transition text-sm">{label}</a>'
        return f'<div class="space-y-2 my-4">{items}</div>'

    elif btype == "aggregated_relations":
        rel_type = config.get("relation_type", "")
        label_raw = config.get("label", "")
        # Map Russian labels to translation keys
        LABEL_MAP = {
            "Актёры": "layout_acted_in",
            "Актеры": "layout_acted_in",
            "Режиссёр": "layout_directed_by",
            "Режисеры": "layout_directed_by",
            "Режисёры": "layout_directed_by",
            "Актёры и персонажи": "layout_actors_characters",
            "Актеры и персонажи": "layout_actors_characters",
        }
        if t and label_raw in LABEL_MAP:
            label = t.get(LABEL_MAP[label_raw], label_raw)
        elif t and label_raw:
            label = label_raw
        elif t:
            label = t.get(f"layout_{rel_type}", rel_type)
        else:
            label = label_raw or rel_type
        max_items = int(config.get("max_items", "10") or "10")
        rels = (relations or {}).get(rel_type, [])[:max_items]
        if not rels:
            return ""
        links = []
        for r in rels:
            rlabel = r.get("label", "?")
            eid = r.get("entity_id", "")
            role = r.get("role", "")
            display = f"{rlabel} ({role})" if role else rlabel
            links.append(f'<a href="/entity/{eid}" class="text-blue-600 hover:underline text-sm">{display}</a>')
        names = ", ".join(links)
        return f'<div class="my-2 text-sm"><span class="font-medium text-gray-700">{label}:</span> {names}</div>'

    elif btype == "text_block":
        content = get_localized_value(state_data, "description", lang) or ""
        if content:
            content = _replace_variables(str(content), state_data)
        if not content:
            return ""
        import markdown as md
        rendered = md.markdown(str(content), extensions=["tables", "fenced_code", "nl2br"])
        return f'<div class="my-4"><h3 class="text-lg font-semibold text-gray-800 mb-2">{t.get("layout_description", "Описание") if t else "Описание"}</h3><div class="prose prose-sm max-w-none text-gray-700">{rendered}</div></div>'

    elif btype == "richtext":
        title = config.get("title", "")
        source = config.get("source", "")
        static_content = config.get("content", "")
        content = get_localized_value(state_data, source, lang) or "" if source else static_content
        if not content:
            content = static_content
        if content:
            content = _replace_variables(str(content), state_data)
        if title:
            title = _replace_variables(str(title), state_data)
        if not content and not title:
            return ""
        html = ""
        if title:
            html += f'<h3 class="text-lg font-semibold text-gray-800 mb-2">{title}</h3>'
        if content:
            html += f'<p class="text-gray-700">{content}</p>'
        return f'<div class="my-4">{html}</div>'

    elif btype == "divider":
        return '<hr class="my-6 border-gray-200">'

    elif btype == "spacer":
        h = config.get("height", "40")
        return f'<div style="height:{h}px;"></div>'

    elif btype == "custom_html":
        html = config.get("html", "")
        if html:
            html = _replace_variables(str(html), state_data)
        return f'<div class="my-4">{html}</div>'

    elif btype == "image_data_row":
        img_src = get_state_field(state_data, config.get("image_source", "")) or ""
        alt = get_state_field(state_data, config.get("alt_field", "")) or ""
        import json as _json
        fields_raw = config.get("fields", "[]")
        if isinstance(fields_raw, str):
            fields = _json.loads(fields_raw) if fields_raw.strip() else []
        else:
            fields = fields_raw or []
        # Auto-generate fields from state_data if config is empty
        skip_keys = {config.get("image_source", ""), config.get("alt_field", ""), "description", "content"}
        if not fields:
            for k, v in state_data.items():
                if k not in skip_keys and v and str(v).strip():
                    fields.append({"key": k, "label": get_label(k, lang, t)})

        # Interactive field types that link to entity search
        _PERSON_KEYS = {"director", "author", "artist", "composer", "narrator", "producer", "screenwriter", "operator", "actor", "starring"}
        _GENRE_KEYS = {"genre", "genres", "subgenres"}
        _DATE_KEYS = {"year", "release_date", "birth_date", "death_date", "birth_year", "death_year", "founded", "start_year", "end_year"}
        _PLACE_KEYS = {"country", "country_origin", "birthplace", "birth_place", "location", "filming_locations"}
        _LANGUAGE_KEYS = {"language"}
        _COMPANY_KEYS = {"production_company", "production_companies", "studio", "publisher"}
        _TYPE_MAP = {
            "director": "director", "author": "writer", "artist": "musician",
            "composer": "musician", "actor": "actor", "starring": "actor",
            "screenwriter": "writer", "narrator": "actor", "producer": "director",
            "operator": "director",
        }

        rows = ""
        for f in fields:
            key = f.get("field_key") or f.get("key", "")
            val = get_localized_value(state_data, key, lang) or ""
            label = get_label(key, lang, t) or f.get("label")
            ftype = f.get("type", "string")
            val_str = str(val) if val is not None else ""

            if not val_str and val != 0:
                # Show stub for missing data with inline add popup
                _eid = entity_id or ""
                _add_id = f"add_{_eid}_{key}"
                if key in _PERSON_KEYS:
                    _kind_filter = _TYPE_MAP.get(key, "actor")
                    _popup_html = (
                        f'<div id="{_add_id}" class="hidden fixed inset-0 z-[9998] bg-black/40 flex items-center justify-center">'
                        f'<div class="bg-white rounded-xl shadow-2xl p-5 w-96 space-y-3" onclick="event.stopPropagation()">'
                        f'<h4 class="font-semibold text-gray-800 text-sm">{t.get("btn_add", "Добавить") if t else "Добавить"}: {label}</h4>'
                        f'<input id="{_add_id}_input" type="text" placeholder="{t.get("placeholder_enter_name", "Введите название...") if t else "Введите название..."}" class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 outline-none">'
                        f'<div id="{_add_id}_results" class="text-xs text-gray-500 max-h-40 overflow-y-auto"></div>'
                        f'<div class="flex gap-2">'
                        f'<button onclick="saveEntityField(\'{_eid}\',\'{key}\',document.getElementById(\'{_add_id}_input\').value)" class="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700">{t.get("btn_save", "Сохранить") if t else "Сохранить"}</button>'
                        f'<button onclick="document.getElementById(\'{_add_id}\').classList.add(\'hidden\')" class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg text-sm hover:bg-gray-300">{t.get("btn_cancel", "Отмена") if t else "Отмена"}</button>'
                        f'</div></div></div>'
                        f'<script>document.getElementById("{_add_id}_input").addEventListener("input",function(){{'
                        f'const q=this.value;const r=document.getElementById("{_add_id}_results");'
                        f'if(q.length<2){{r.innerHTML="";return;}}'
                        f'fetch("/api/editor/search?q="+encodeURIComponent(q)+"&kind={_kind_filter}&limit=5").then(r=>r.json()).then(d=>{{'
                        f'r.innerHTML=d.items?d.items.map(i=>`<div class="p-1 hover:bg-blue-50 cursor-pointer rounded" onclick="document.getElementById(\'{_add_id}_input\').value=\'${{i.label}}\'">${{i.label}}</div>`).join(""):"Ничего не найдено"}})}})</script>'
                    )
                    rows += (
                        f'<tr class="border-b border-gray-100">'
                        f'<td class="py-2 text-sm text-gray-500 font-medium text-right pr-3 whitespace-nowrap">{label}</td>'
                        f'<td class="text-gray-400 pr-3">:</td>'
                        f'<td class="py-2 text-sm italic text-gray-400">'
                        f'{t.get("layout_information_missing", "Информация отсутствует") if t else "Информация отсутствует"} '
                        f'<button onclick="event.preventDefault();document.getElementById(\'{_add_id}\').classList.remove(\'hidden\')" class="text-blue-500 hover:underline text-xs">+ {t.get("layout_add", "+ добавить") if t else "+ добавить"}</button>'
                        f'</td></tr>'
                    )
                    rows += _popup_html
                else:
                    rows += (
                        f'<tr class="border-b border-gray-100">'
                        f'<td class="py-2 text-sm text-gray-500 font-medium text-right pr-3 whitespace-nowrap">{label}</td>'
                        f'<td class="text-gray-400 pr-3">:</td>'
                        f'<td class="py-2 text-sm italic text-gray-400">'
                        f'{t.get("layout_information_missing", "Информация отсутствует") if t else "Информация отсутствует"} '
                        f'<button onclick="event.preventDefault();saveEntityField(\'{_eid}\',\'{key}\',prompt(\'{label}:\'))" class="text-blue-500 hover:underline text-xs">+ {t.get("layout_add", "+ добавить") if t else "+ добавить"}</button>'
                        f'</td></tr>'
                    )
                continue

            if ftype == "currency":
                try: val_html = f'{float(val):,.2f} ₽'
                except (ValueError, TypeError): val_html = val_str
            elif ftype == "boolean":
                val_html = '✓ Да' if val_str.lower() in ('true', '1', 'yes') else '✗ Нет'
            elif ftype == "date" or key in _DATE_KEYS:
                date_display = val_str[:10] if len(val_str) >= 10 else val_str
                # Link to search by year if it's a year field
                if key in ("year", "birth_year", "death_year", "founded", "start_year", "end_year"):
                    val_html = f'<a href="/search?q=&year_from={val_str}&year_to={val_str}" class="text-blue-600 hover:underline text-sm">{date_display}</a>'
                else:
                    val_html = f'<span class="text-sm">{date_display}</span>'
            elif ftype == "url" or (isinstance(val_str, str) and val_str.startswith("http")):
                val_html = f'<a href="{val_str}" target="_blank" class="text-blue-600 hover:underline text-sm">{val_str}</a>'
            elif ftype == "email":
                val_html = f'<a href="mailto:{val_str}" class="text-blue-600 hover:underline text-sm">{val_str}</a>'
            elif ftype in ("image",) and val_str.startswith("http"):
                val_html = f'<img src="{val_str}" class="rounded max-h-24 object-contain">'
            elif key in _PERSON_KEYS:
                # Link to entity search by name
                search_kind = _TYPE_MAP.get(key, "")
                val_html = (
                    f'<a href="/search?q={val_str}" class="text-blue-600 hover:underline text-sm font-medium">{val_str}</a>'
                )
            elif key in _GENRE_KEYS:
                genres = [g.strip() for g in val_str.split(",") if g.strip()]
                if len(genres) > 1:
                    tags = []
                    for g in genres:
                        tags.append(f'<a href="/search?q=&genre={g}" class="text-blue-600 hover:underline text-sm">{g}</a>')
                    val_html = f'<div class="flex flex-wrap gap-1">{"".join(tags)}</div>'
                else:
                    val_html = f'<a href="/search?q=&genre={val_str}" class="text-blue-600 hover:underline text-sm">{val_str}</a>'
            elif isinstance(val, list):
                tags = []
                for item in val:
                    item_str = str(item)
                    if key in _GENRE_KEYS:
                        tags.append(f'<a href="/search?q=&genre={item_str}" class="text-blue-600 hover:underline text-sm">{item_str}</a>')
                    else:
                        tags.append(f'<span class="text-sm text-gray-600">{item_str}</span>')
                val_html = f'<div class="flex flex-wrap gap-1">{"".join(tags)}</div>'
            elif key in _PLACE_KEYS:
                # Link to search by place
                val_html = f'<a href="/search?q={val_str}" class="text-blue-600 hover:underline text-sm">{val_str}</a>'
            elif key in _LANGUAGE_KEYS:
                # Link to search by language
                val_html = f'<a href="/search?q=&language={val_str}" class="text-blue-600 hover:underline text-sm">{val_str}</a>'
            elif key in _COMPANY_KEYS:
                companies = [c.strip() for c in val_str.split(",") if c.strip()]
                if len(companies) > 1:
                    tags = []
                    for c in companies:
                        tags.append(f'<a href="/search?q={c}" class="text-blue-600 hover:underline text-sm">{c}</a>')
                    val_html = f'<div class="flex flex-wrap gap-1">{"".join(tags)}</div>'
                else:
                    val_html = f'<a href="/search?q={val_str}" class="text-blue-600 hover:underline text-sm">{val_str}</a>'
            else:
                val_html = f'<span class="text-sm">{val}</span>'

            rows += (
                f'<tr class="border-b border-gray-100 hover:bg-gray-50 transition">'
                f'<td class="py-2.5 text-sm text-gray-500 font-medium text-right pr-3 whitespace-nowrap">{label}</td>'
                f'<td class="text-gray-300 pr-3">:</td>'
                f'<td class="py-2.5">{val_html}</td></tr>'
            )

        # Poster with standard 2:3 aspect ratio
        if img_src:
            img_html = (
                f'<div style="aspect-ratio: 2/3; overflow:hidden; border-radius: 0.75rem;">'
                f'<img src="{img_src}" alt="{alt}" class="w-full h-full object-cover">'
                f'</div>'
            )
        else:
            img_html = (
                f'<div style="aspect-ratio: 2/3;" class="bg-gray-200 rounded-xl flex items-center justify-center text-gray-400">'
                f'<svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">'
                f'<path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>'
                f'</svg>'
                f'</div>'
            )

        return (
            f'<div class="flex flex-col md:flex-row gap-6 my-4">'
            f'<div class="md:w-2/5 flex-shrink-0">{img_html}</div>'
            f'<div class="md:w-3/5"><table class="w-full">{rows}</table></div>'
            f'</div>'
        )

    elif btype == "actor_character_row":
        acted_in_type = config.get("acted_in_type", "acted_in")
        max_items = int(config.get("max_items", "20") or "20")
        acted_rels = (relations or {}).get(acted_in_type, [])
        if not acted_rels:
            return ""
        rows = ""
        for ar in acted_rels[:max_items]:
            actor_label = ar.get("label", "?")
            actor_id = ar.get("entity_id", "")
            role = ar.get("role", "")
            if not role:
                rows += (
                    f'<div class="flex items-center gap-3 py-2 border-b border-gray-100 last:border-0">'
                    f'<div class="flex-1"><a href="/entity/{actor_id}" class="text-blue-600 hover:underline text-sm font-medium">{actor_label}</a></div>'
                    f'<div class="text-sm text-gray-400">—</div>'
                    f'</div>'
                )
                continue
            rows += (
                f'<div class="flex items-center gap-3 py-2 border-b border-gray-100 last:border-0">'
                f'<div class="flex-1"><a href="/entity/{actor_id}" class="text-blue-600 hover:underline text-sm font-medium">{actor_label}</a></div>'
                f'<div class="text-sm text-gray-400">→</div>'
                f'<div class="flex-1"><span class="text-gray-700 text-sm">{role}</span></div>'
                f'</div>'
            )
        if not rows:
            return ""
        label_raw = config.get("label", "")
        LABEL_MAP = {
            "Актёры и персонажи": "layout_actors_characters",
            "Актеры и персонажи": "layout_actors_characters",
            "Актёры": "layout_acted_in",
            "Актеры": "layout_acted_in",
            "Режиссёр": "layout_directed_by",
            "Режисеры": "layout_directed_by",
            "Режисёры": "layout_directed_by",
        }
        if t and label_raw in LABEL_MAP:
            label = t.get(LABEL_MAP[label_raw], label_raw)
        elif t and label_raw:
            label = label_raw
        elif t:
            label = t.get("layout_actors_characters", "Актёры и персонажи")
        else:
            label = label_raw or "Актёры и персонажи"
        return f'<div class="my-4"><h3 class="text-sm font-semibold text-gray-700 mb-2">{label}</h3>{rows}</div>'

    elif btype == "actor_character_gallery":
        acted_in_type = config.get("acted_in_type", "acted_in")
        max_items = int(config.get("max_items", "20") or "20")
        spoiler_text = t.get("layout_show_cast", "") if t else ""
        if not spoiler_text:
            spoiler_text = config.get("spoiler_text", "")
        if not spoiler_text:
            spoiler_text = "Показать актёрский состав"
        acted_rels = (relations or {}).get(acted_in_type, [])
        if not acted_rels:
            return ""
        
        cards = ""
        for ar in acted_rels[:max_items]:
            actor_label = ar.get("label", "?")
            actor_id = ar.get("entity_id", "")
            role = ar.get("role", "")
            img_url = ar.get("image_url", "")
            
            actor_img_html = f'<img src="/media/proxy?url={img_url}" alt="{actor_label}" class="w-16 h-16 rounded-lg object-cover" loading="lazy">' if img_url else f'<div class="w-16 h-16 rounded-lg flex items-center justify-center text-lg font-bold" style="background:var(--color-primary);color:#fff;">{actor_label[:1]}</div>'
            char_img_html = f'<div class="w-12 h-12 rounded-lg flex items-center justify-center text-sm font-bold" style="background:var(--color-accent);color:#fff;">{role[:1] if role else "?"}</div>'
            
            cards += (
                f'<div class="flex items-center gap-3 p-3 rounded-lg border" style="border-color:var(--color-border);">'
                f'<a href="/entity/{actor_id}">{actor_img_html}</a>'
                f'<div class="flex-1 min-w-0">'
                f'<a href="/entity/{actor_id}" class="font-medium text-sm truncate block" style="color:var(--color-text);">{actor_label}</a>'
                f'<div class="text-xs truncate" style="color:var(--color-text-secondary);">{role}</div>'
                f'</div>'
                f'{char_img_html}'
                f'</div>'
            )
        
        if not cards:
            return ""
        
        return (
            f'<details class="my-4 rounded-xl border" style="border-color:var(--color-border);">'
            f'<summary class="p-4 cursor-pointer hover:bg-gray-50 transition text-sm font-semibold" style="color:var(--color-text);">'
            f'{spoiler_text} ({len(acted_rels[:max_items])})'
            f'</summary>'
            f'<div class="px-4 pb-4 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">'
            f'{cards}'
            f'</div>'
            f'</details>'
        )

    elif btype == "file_link":
        url = get_state_field(state_data, config.get("source", "")) or ""
        title = get_state_field(state_data, config.get("title", "")) or "Файл"
        if not url:
            return ""
        ext = url.rsplit(".", 1)[-1].upper() if "." in url else ""
        ext_badge = f'<span class="text-xs text-gray-400">{ext}</span>' if ext else ""
        return f'<div class="my-3"><a href="{url}" target="_blank" class="inline-flex items-center gap-2 px-4 py-3 bg-gray-50 rounded-lg border border-gray-200 hover:bg-blue-50 hover:border-blue-300 transition"><svg class="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg><span class="text-sm font-medium text-gray-700">{title}</span>{ext_badge}</a></div>'

    elif btype == "file_upload":
        url = get_state_field(state_data, config.get("source", "")) or ""
        title = get_state_field(state_data, config.get("title", "")) or "Файл"
        if not url:
            return ""
        return f'<div class="my-3 p-4 bg-blue-50 rounded-lg border border-blue-200"><a href="{url}" target="_blank" class="text-blue-700 hover:underline font-medium">{title}</a></div>'

    return ""
