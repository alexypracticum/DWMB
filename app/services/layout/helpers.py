"""Helper functions for layout rendering."""
import re
import json

def get_label(key, lang="ru", t: dict = None):
    """Get label for a field based on language.
    Uses translation dict (t) first, then query DB, then fallback to key.
    """
    trans_key = f"field_{key}"
    if t and trans_key in t:
        return t[trans_key]
    # Fallback: try to load from DB cache
    try:
        from app.middleware.theme import _translations_cache
        cache_key = f"trans:{lang}"
        if cache_key in _translations_cache:
            cached = _translations_cache[cache_key].get("data", {})
            if trans_key in cached:
                return cached[trans_key]
    except Exception:
        pass
    return key.replace("_", " ").title()


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


