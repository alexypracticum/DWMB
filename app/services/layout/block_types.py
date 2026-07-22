"""Block type definitions and labels."""
"""
Block-based layout rendering system for entity pages.

Layout definition format (JSON):
[
    {
        "id": "block_1",
        "type": "hero_image",
        "config": {"source": "state.poster_url", "alt_field": "title"},
        "width": "full"
    },
    {
        "id": "block_2",
        "type": "columns",
        "config": {"left_width": "40%", "right_width": "60%"},
        "children": [
            {"id": "block_2a", "type": "info_table", "config": {"fields": [...]}, "width": "left"},
            {"id": "block_2b", "type": "markdown", "config": {"source": "state.description"}, "width": "right"}
        ]
    }
]
"""

BLOCK_TYPES = {
    "hero_image": {
        "name": "block_hero_image",
        "icon": "image",
        "description": "Большое изображение сверху (постер, обложка)",
        "config_fields": [
            {"key": "source", "label": "Поле данных", "type": "state_field", "default": "poster_url"},
            {"key": "alt_field", "label": "Поле для alt-текста", "type": "state_field", "default": "title"},
        ],
    },
    "image": {
        "name": "block_image",
        "icon": "photo",
        "description": "Одно изображение",
        "config_fields": [
            {"key": "source", "label": "Поле данных", "type": "state_field", "default": "image_url"},
            {"key": "alt_field", "label": "Alt-текст", "type": "state_field", "default": "title"},
            {"key": "caption", "label": "Подпись", "type": "state_field", "default": "image_caption"},
            {"key": "height", "label": "Высота (px)", "type": "text", "default": ""},
        ],
    },
    "gallery": {
        "name": "block_gallery",
        "icon": "collection",
        "description": "Горизонтальная прокручиваемая галерея",
        "config_fields": [
            {"key": "source", "label": "Поле данных (массив URL)", "type": "state_field", "default": "images"},
            {"key": "title", "label": "Заголовок", "type": "text", "default": ""},
            {"key": "height", "label": "Высота (px)", "type": "text", "default": "300"},
        ],
    },
    "markdown": {
        "name": "block_markdown",
        "icon": "document-text",
        "description": "Форматированный текст с поддержкой Markdown, изображений, видео",
        "config_fields": [
            {"key": "source", "label": "Поле данных", "type": "state_field", "default": "content"},
            {"key": "max_height", "label": "Макс. высота (px, 0=без ограничения)", "type": "text", "default": "0"},
        ],
    },
    "video": {
        "name": "block_video",
        "icon": "play",
        "description": "Встроенное видео (YouTube, Vimeo, MP4)",
        "config_fields": [
            {"key": "source", "label": "Поле данных (URL)", "type": "state_field", "default": "video_url"},
            {"key": "aspect", "label": "Соотношение сторон", "type": "select", "options": ["16:9", "4:3", "1:1"], "default": "16:9"},
        ],
    },
    "audio": {
        "name": "block_audio",
        "icon": "musical-note",
        "description": "Аудиоплеер",
        "config_fields": [
            {"key": "source", "label": "Поле данных (URL)", "type": "state_field", "default": "audio_url"},
            {"key": "title", "label": "Название трека", "type": "state_field", "default": "title"},
        ],
    },
    "info_table": {
        "name": "block_info_table",
        "icon": "table",
        "description": "Ключ-значение: год, длительность, жанр и т.д.",
        "config_fields": [
            {"key": "fields", "label": "Поля (JSON массив)", "type": "json",
             "default": '[{"key": "year", "label": "Год"}, {"key": "genre", "label": "Жанр"}]'},
            {"key": "style", "label": "Стиль", "type": "select", "options": ["table", "cards", "inline"], "default": "table"},
        ],
    },
    "relation_list": {
        "name": "block_relation_list",
        "icon": "link",
        "description": "Список связанных сущностей (актёры, авторы и т.д.)",
        "config_fields": [
            {"key": "relation_type", "label": "Тип связи", "type": "text", "default": ""},
            {"key": "display", "label": "Отображение", "type": "select", "options": ["list", "cards", "avatars"], "default": "list"},
            {"key": "max_items", "label": "Макс. кол-во", "type": "text", "default": "20"},
        ],
    },
    "aggregated_relations": {
        "name": "block_aggregated_relations",
        "icon": "users",
        "description": "Компактный список связанных сущностей через запятую (Актёры, Режиссёры и т.д.)",
        "config_fields": [
            {"key": "relation_type", "label": "Тип связи", "type": "relation_type_select", "default": ""},
            {"key": "label", "label": "Заголовок (напр. Актёры)", "type": "text", "default": ""},
            {"key": "max_items", "label": "Макс. кол-во", "type": "text", "default": "10"},
        ],
    },
    "text_block": {
        "name": "block_text",
        "icon": "text",
        "description": "Блок описания сущности (автоматически из поля description)",
        "config_fields": [],
    },
    "richtext": {
        "name": "block_richtext",
        "icon": "text",
        "description": "Текстовый блок с заголовком и настраиваемым содержимым",
        "config_fields": [
            {"key": "title", "label": "Заголовок", "type": "text", "default": ""},
            {"key": "source", "label": "Поле данных", "type": "state_field", "default": ""},
            {"key": "content", "label": "Статический текст", "type": "textarea", "default": ""},
        ],
    },
    "divider": {
        "name": "block_divider",
        "icon": "minus",
        "description": "Горизонтальная линия",
        "config_fields": [],
    },
    "spacer": {
        "name": "block_spacer",
        "icon": "arrow-down",
        "description": "Вертикальный отступ",
        "config_fields": [
            {"key": "height", "label": "Высота (px)", "type": "text", "default": "40"},
        ],
    },
    "custom_html": {
        "name": "block_custom_html",
        "icon": "code",
        "description": "Свой HTML/CSS код",
        "config_fields": [
            {"key": "html", "label": "HTML", "type": "textarea", "default": ""},
        ],
    },
    "image_data_row": {
        "name": "block_image_data_row",
        "icon": "photograph",
        "description": "Изображение слева, информация справа",
        "config_fields": [
            {"key": "image_source", "label": "Поле изображения", "type": "state_field", "default": "poster_url"},
            {"key": "alt_field", "label": "Alt-текст", "type": "state_field", "default": "title"},
            {"key": "fields", "label": "Поля данных (JSON)", "type": "json",
             "default": '[{"key":"year","label":"Год"},{"key":"genre","label":"Жанр"}]'},
        ],
    },
    "horizontal_row": {
        "name": "block_horizontal_row",
        "icon": "view-columns",
        "description": "2-5 блоков в ряд (горизонтально)",
        "config_fields": [
            {"key": "columns", "label": "Кол-во колонок (2-5)", "type": "text", "default": "2"},
        ],
    },
    "file_link": {
        "name": "block_file_link",
        "icon": "document-arrow-down",
        "description": "Ссылка на файл (PDF, DOC и т.д.)",
        "config_fields": [
            {"key": "source", "label": "Поле данных (URL)", "type": "state_field", "default": "file_url"},
            {"key": "title", "label": "Название файла", "type": "state_field", "default": "file_title"},
        ],
    },
    "file_upload": {
        "name": "block_file_upload",
        "icon": "arrow-up-tray",
        "description": "Загрузка файла с сохранением в хранилище",
        "config_fields": [
            {"key": "source", "label": "Поле данных (URL)", "type": "state_field", "default": "uploaded_file_url"},
            {"key": "title", "label": "Название", "type": "state_field", "default": "uploaded_file_title"},
        ],
    },
    "actor_character_row": {
        "name": "block_actor_character_row",
        "icon": "user-group",
        "description": "Строка: слева актёр, справа персонаж",
        "config_fields": [
            {"key": "acted_in_type", "label": "Тип связи актёр→фильм", "type": "relation_type_select", "default": "acted_in"},
            {"key": "plays_type", "label": "Тип связи актёр→персонаж", "type": "relation_type_select", "default": "plays"},
            {"key": "appears_in_type", "label": "Тип связи персонаж→фильм", "type": "relation_type_select", "default": "appears_in"},
            {"key": "max_items", "label": "Макс. кол-во", "type": "text", "default": "20"},
        ],
    },
    "actor_character_gallery": {
        "name": "block_actor_character_gallery",
        "icon": "photo-group",
        "description": "Компактная галерея с изображениями актёров и персонажей, со спойлером",
        "config_fields": [
            {"key": "acted_in_type", "label": "Тип связи актёр→фильм", "type": "relation_type_select", "default": "acted_in"},
            {"key": "plays_type", "label": "Тип связи актёр→персонаж", "type": "relation_type_select", "default": "plays"},
            {"key": "appears_in_type", "label": "Тип связи персонаж→фильм", "type": "relation_type_select", "default": "appears_in"},
            {"key": "max_items", "label": "Макс. кол-во", "type": "text", "default": "20"},
            {"key": "spoiler_text", "label": "Текст спойлера", "type": "text", "default": "Показать актёрский состав"},
        ],
    },
}


