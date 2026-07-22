"""Helper functions for layout rendering."""
import re
import json
RU_LABELS = {
    "year": "Год", "genre": "Жанр", "title": "Название", "rating": "Рейтинг",
    "country": "Страна", "language": "Язык", "budget_mln": "Бюджет (млн)",
    "duration_min": "Длительность (мин)", "artist": "Исполнитель", "album": "Альбом",
    "bpm": "BPM", "author": "Автор", "pages": "Страниц", "isbn": "ISBN",
    "first_name": "Имя", "last_name": "Фамилия", "birth_date": "Дата рождения",
    "birth_place": "Место рождения", "nationality": "Национальность",
    "occupation": "Профессия", "name": "Название", "species": "Вид",
    "habitat": "Среда обитания", "diet": "Питание", "lifespan_years": "Продолжительность жизни",
    "symbol": "Символ", "atomic_number": "Атомный номер", "atomic_mass": "Атомная масса",
    "group": "Группа", "period": "Период", "category": "Категория",
    "definition": "Определение", "domain": "Домен", "start_year": "Начало",
    "end_year": "Конец", "region": "Регион", "significance": "Значение",
    "format": "Формат", "size_kb": "Размер (КБ)", "photographer": "Фотограф",
    "subject": "Тема", "published": "Опубликовано", "source": "Источник",
    "description": "Описание", "content": "Контент",     "poster_url": "Постер",
    "file_url": "Файл", "file_title": "Название файла", "images": "Изображения",
    "video_url": "Видео", "audio_url": "Аудио", "audio_title": "Название аудио",
    "release_date": "Дата выхода", "start_date": "Дата начала", "end_date": "Дата окончания",
    "price": "Цена", "website": "Сайт", "email": "Email", "score": "Рейтинг",
    "director": "Режиссёр", "duration": "Длительность", "starring": "В главных ролях",
    "screenwriter": "Сценарист", "operator": "Оператор", "composer": "Композитор",
    "producer": "Продюсер", "narrator": "Рассказчик", "studio": "Студия",
    "country_origin": "Страна производства", "world_premiere": "Мировая премьера",
    "tagline": "Слоган", "mpaa_rating": "Рейтинг MPAA", "budget": "Бюджет",
    "revenue": "Сборы", "currency": "Валюта",
}

EN_LABELS = {
    "year": "Year", "genre": "Genre", "title": "Title", "rating": "Rating",
    "country": "Country", "language": "Language", "budget_mln": "Budget (mln)",
    "duration_min": "Duration (min)", "artist": "Artist", "album": "Album",
    "bpm": "BPM", "author": "Author", "pages": "Pages", "isbn": "ISBN",
    "first_name": "First Name", "last_name": "Last Name", "birth_date": "Birth Date",
    "birth_place": "Birth Place", "nationality": "Nationality",
    "occupation": "Occupation", "name": "Name", "species": "Species",
    "habitat": "Habitat", "diet": "Diet", "lifespan_years": "Lifespan",
    "symbol": "Symbol", "atomic_number": "Atomic Number", "atomic_mass": "Atomic Mass",
    "group": "Group", "period": "Period", "category": "Category",
    "definition": "Definition", "domain": "Domain", "start_year": "Start Year",
    "end_year": "End Year", "region": "Region", "significance": "Significance",
    "format": "Format", "size_kb": "Size (KB)", "photographer": "Photographer",
    "subject": "Subject", "published": "Published", "source": "Source",
    "description": "Description", "content": "Content", "poster_url": "Poster",
    "file_url": "File", "file_title": "File Title", "images": "Images",
    "video_url": "Video", "audio_url": "Audio", "audio_title": "Audio Title",
    "release_date": "Release Date", "start_date": "Start Date", "end_date": "End Date",
    "price": "Price", "website": "Website", "email": "Email", "score": "Score",
    "director": "Director", "duration": "Duration", "starring": "Starring",
    "screenwriter": "Screenwriter", "operator": "Cinematographer", "composer": "Composer",
    "producer": "Producer", "narrator": "Narrator", "studio": "Studio",
    "country_origin": "Country of Origin", "world_premiere": "World Premiere",
    "tagline": "Tagline", "mpaa_rating": "MPAA Rating", "budget": "Budget",
    "revenue": "Revenue", "currency": "Currency",
}

def get_label(key, lang="ru", t: dict = None):
    """Get label for a field based on language.
    Uses translation dict (t) if provided, falls back to hardcoded dicts.
    Field labels are stored as field_key in translation system.
    """
    if t:
        trans_key = f"field_{key}"
        if trans_key in t:
            return t[trans_key]
    if not t or len(t) < 10:
        try:
            from app.services.ui_translations import _translations_cache
            cached = _translations_cache.get(lang, {})
            trans_key = f"field_{key}"
            if trans_key in cached:
                return cached[trans_key]
        except Exception:
            pass
    labels = EN_LABELS if lang == "en" else RU_LABELS
    return labels.get(key, key.replace("_", " ").title())


def get_state_field(state_data: dict, field_path: str):
    """Get value from state_data by dot-notation path (e.g. 'meta.title')."""
    if not field_path or not state_data:
        return None
    parts = field_path.split(".")
    val = state_data
    for part in parts:
        if isinstance(val, dict):
            val = val.get(part)
        else:
            return None
    return val


def get_localized_value(state_data: dict, field_path: str, lang: str = "ru", fallback_lang: str = "ru"):
    """Get localized value from state_data.
    
    Supports both formats:
    - Simple: {"title": "Inception"} → returns "Inception"
    - Multilingual: {"title": {"ru": "Начало", "en": "Inception"}} → returns localized value
    
    Fallback chain: lang → fallback_lang → first available value
    """
    value = get_state_field(state_data, field_path)
    if value is None:
        return None
    
    # If value is a dict with language keys, it's multilingual
    if isinstance(value, dict):
        # Try requested language first
        if lang in value:
            return value[lang]
        # Try fallback language
        if fallback_lang in value:
            return value[fallback_lang]
        # Return first available value
        for v in value.values():
            if v:
                return v
        return None
    
    # Simple value (not multilingual)
    return value


def set_localized_value(state_data: dict, field_path: str, lang: str, value: str) -> dict:
    """Set a localized value in state_data.
    
    Creates multilingual structure if needed:
    - If field doesn't exist: creates {lang: value}
    - If field is simple string: converts to {lang: value}
    - If field is already multilingual dict: updates the language
    """
    if not field_path:
        return state_data
    
    parts = field_path.split(".")
    current = state_data
    
    # Navigate to the parent
    for part in parts[:-1]:
        if part not in current:
            current[part] = {}
        current = current[part]
    
    final_key = parts[-1]
    old_value = current.get(final_key)
    
    if old_value is None:
        # New field - create multilingual dict
        current[final_key] = {lang: value}
    elif isinstance(old_value, dict):
        # Already multilingual - update
        old_value[lang] = value
    else:
        # Was a simple string - convert to multilingual
        current[final_key] = {lang: value}
    
    return state_data


def _replace_variables(text: str, state_data: dict) -> str:
    """Replace [field_name] patterns with values from state_data.

    Supports:
      - [field_name] → state_data[field_name]
      - [field.subfield] → state_data[field][subfield]
      - Default values: [field_name:default text] → value or "default text"
    """
    if not text:
        return text

    import re

    def _replace_match(m):
        path = m.group(1).strip()
        default = m.group(2).strip() if m.group(2) else ""

        val = get_state_field(state_data, path)
        if val is None or val == "":
            return default if default else m.group(0)
        if isinstance(val, (dict, list)):
            import json as _json
            return _json.dumps(val, ensure_ascii=False, default=str)
        return str(val)

    return re.sub(r'\[([^\]:]+)(?::([^\]]*))?\]', _replace_match, text)


