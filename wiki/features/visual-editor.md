---
type: feature
title: "Визуальный редактор"
description: "Модульный редактор макетов с 21+ типами блоков, drag-and-drop, живым превью и рендерингом страниц"
tags: [features, visual-editor, layout, blocks, wsiwyg]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - app/services/layout.py
  - app/templates/admin/template_edit.html
  - raw/22.07.2026.MIMO.md
resource: "file://raw/22.07.2026.MIMO.md"
status: AI-Generated
---

# Визуальный редактор

Модульный визуальный редактор макетов страниц сущностей — **ключевая фича** DWMB.

## Типы блоков (21+)

| Блок | Описание |
|------|----------|
| `hero_image` | Главное изображение (постер) |
| `image` | Изображение |
| `gallery` | Галерея изображений |
| `markdown` | Текст в формате Markdown |
| `video` | Видео |
| `audio` | Аудио |
| `info_table` | Таблица информации (ключ-значение) |
| `relation_list` | Список связанных сущностей |
| `text_block` | Текстовый блок |
| `divider` | Разделитель |
| `spacer` | Отступ |
| `custom_html` | Произвольный HTML |
| `image_data_row` | Изображение слева + таблица данных справа |
| `horizontal_row` | 2-5 блоков в ряд (горизонтально) |
| `file_link` | Ссылка на файл с иконкой |
| `file_upload` | Загрузка файла |

## Как работает

### 1. Редактирование макета

В админ-панели (`/admin/templates/{template_id}/edit`) открывается визуальный редактор:

- **Drag-and-drop** reorder блоков
- **Конфигурация** каждого блока (поля данных, стили, параметры)
- **Живой превью** макета

### 2. Генерация формы

Блоки `hero_image`, `image`, `file_link`, `file_upload` генерируют **текстовые поля** в форме создания/редактирования сущности. Значения сохраняются в `state_data`.

### 3. Рендеринг страницы

При отображении сущности (`/entity/{id}`) движок `layout.py` читает `layout_blocks` из шаблона и рендерит данные из `projection_state.state_data`.

## Движок рендеринга (layout.py)

```python
class LayoutRenderer:
    """Рендерит макет сущности по блокам шаблона"""

    def render(self, template: OntologyTemplate, data: dict) -> str:
        html = ""
        for block in template.layout_blocks:
            block_type = block["type"]
            block_data = {k: data.get(k) for k in block.get("fields", [])}
            html += self.render_block(block_type, block_data)
        return html
```

## Fallback

Если у шаблона **нет макета** — страница отображает **сырые данные** из `state_data` в виде таблицы.

## Связанные страницы

- [[database/ontology]] — layout_blocks в шаблонах
- [[features/entity-crud]] — как данные попадают в блоки
- [[features/admin-panel]] — редактирование шаблонов

## Источники

- `app/services/layout.py` — движок рендеринга
- `app/templates/admin/template_edit.html` — визуальный редактор
- `raw/22.07.2026.MIMO.md` — история создания
