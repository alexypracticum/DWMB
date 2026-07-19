"""
Unit tests for i18n translation service.
"""
from app.services.i18n import get_translation, TRANSLATIONS


def test_get_translation_ru():
    t = get_translation("ru")
    assert t["nav_entities"] == "Сущности"
    assert t["nav_search"] == "Поиск"
    assert t["btn_save"] == "Сохранить"
    assert t["label_profile"] == "Профиль пользователя"


def test_get_translation_en():
    t = get_translation("en")
    assert t["nav_entities"] == "Entities"
    assert t["nav_search"] == "Search"
    assert t["btn_save"] == "Save"
    assert t["label_profile"] == "User Profile"


def test_unknown_language_falls_back_to_ru():
    t = get_translation("de")  # German not implemented
    assert t["nav_entities"] == "Сущности"  # Falls back to Russian


def test_all_languages_have_same_keys():
    ru_keys = set(TRANSLATIONS["ru"].keys())
    for lang, strings in TRANSLATIONS.items():
        missing = ru_keys - set(strings.keys())
        extra = set(strings.keys()) - ru_keys
        assert not missing, f"Language '{lang}' missing keys: {missing}"
        assert not extra, f"Language '{lang}' has extra keys: {extra}"


def test_translation_values_are_strings():
    for lang, strings in TRANSLATIONS.items():
        for key, val in strings.items():
            assert isinstance(val, str), f"Language '{lang}', key '{key}' is not a string"
