"""
Seed script: Create admin UI string entities for multilingual interface.
Run with: docker compose exec app python -m db.seeds.04_admin_ui_strings
"""
import asyncio
import uuid
import hashlib
import json
from sqlalchemy import select
from app.database import async_session
from app.models.entities import Entity, EntityLabel, Context
from app.models.kinds import EntityKind
from app.models.projections import EntityProjection, ProjectionState, OntologyModel, OntologyTemplate
from app.models.languages import Language

# All new translation keys with values for ru/en
TRANSLATIONS = {
    # Entity list page
    "search_btn": {"ru": "Найти", "en": "Find"},
    "search_reset": {"ru": "Сбросить", "en": "Reset"},
    "search_sort_name": {"ru": "По имени", "en": "By name"},
    "search_sort_newest": {"ru": "Сначала новые", "en": "Newest first"},
    "search_sort_oldest": {"ru": "Сначала старые", "en": "Oldest first"},
    "view_preview": {"ru": "Превью", "en": "Preview"},
    "view_grid": {"ru": "Плитки", "en": "Grid"},
    "view_list": {"ru": "Список", "en": "List"},
    "view_table": {"ru": "Таблица", "en": "Table"},
    "table_name": {"ru": "Название", "en": "Name"},
    "table_type": {"ru": "Тип", "en": "Type"},
    "table_updated": {"ru": "Обновлено", "en": "Updated"},
    
    # Entity detail page
    "breadcrumb_home": {"ru": "Главная", "en": "Home"},
    "breadcrumb_entities": {"ru": "Сущности", "en": "Entities"},
    "workflow_draft": {"ru": "Черновик", "en": "Draft"},
    "workflow_archived": {"ru": "Архив", "en": "Archived"},
    "workflow_published": {"ru": "Опубликовано", "en": "Published"},
    "btn_publish": {"ru": "Опубликовать", "en": "Publish"},
    "btn_to_archive": {"ru": "В архив", "en": "Archive"},
    "btn_unarchive": {"ru": "Разархивировать", "en": "Unarchive"},
    "btn_history": {"ru": "История", "en": "History"},
    "btn_edit": {"ru": "Редактировать", "en": "Edit"},
    "btn_export": {"ru": "Экспорт", "en": "Export"},
    "btn_confirm_delete_entity": {"ru": "Удалить сущность?", "en": "Delete entity?"},
    "section_data": {"ru": "Данные", "en": "Data"},
    "section_labels": {"ru": "Метки", "en": "Labels"},
    "label_primary_badge": {"ru": "основной", "en": "primary"},
    "section_relations": {"ru": "Связи", "en": "Relations"},
    "section_graph": {"ru": "Граф связей", "en": "Relation Graph"},
    "section_outgoing": {"ru": "Исходящие связи", "en": "Outgoing Relations"},
    "section_incoming": {"ru": "Входящие связи", "en": "Incoming Relations"},
    "section_meta": {"ru": "Мета-информация", "en": "Meta Information"},
    "meta_status": {"ru": "Статус", "en": "Status"},
    "meta_created": {"ru": "Создано", "en": "Created"},
    "meta_updated": {"ru": "Обновлено", "en": "Updated"},
    "section_comments": {"ru": "Комментарии", "en": "Comments"},
    "comment_placeholder": {"ru": "Написать комментарий...", "en": "Write a comment..."},
    "btn_send": {"ru": "Отправить", "en": "Send"},
    "comment_login_required": {"ru": "Войдите, чтобы оставить комментарий", "en": "Login to leave a comment"},
    "comment_anonymous": {"ru": "Аноним", "en": "Anonymous"},
    "btn_confirm_delete_comment": {"ru": "Удалить комментарий?", "en": "Delete comment?"},
    "comment_reply": {"ru": "Ответить", "en": "Reply"},
    "comment_reply_placeholder": {"ru": "Ответ...", "en": "Reply..."},
    "comment_no_comments": {"ru": "Пока нет комментариев", "en": "No comments yet"},
    
    # Admin fields page
    "admin_fields_registry": {"ru": "Реестр полей данных", "en": "Field Registry"},
    "admin_categories": {"ru": "Категории", "en": "Categories"},
    "admin_add_category": {"ru": "+ Добавить", "en": "+ Add"},
    "admin_key_latin": {"ru": "Ключ (лат.)", "en": "Key (latin)"},
    "admin_category_name": {"ru": "Название", "en": "Name"},
    "admin_category_placeholder": {"ru": "Моя категория", "en": "My category"},
    "admin_all": {"ru": "Все", "en": "All"},
    "admin_confirm_delete_category": {"ru": "Удалить категорию?", "en": "Delete category?"},
    "admin_new_field": {"ru": "Новое поле", "en": "New Field"},
    "admin_field_key": {"ru": "Ключ", "en": "Key"},
    "admin_field_name": {"ru": "Название", "en": "Name"},
    "admin_field_name_placeholder": {"ru": "Мое поле", "en": "My field"},
    "admin_field_type": {"ru": "Тип", "en": "Type"},
    "admin_field_category": {"ru": "Категория", "en": "Category"},
    "admin_field_default": {"ru": "По умолчанию", "en": "Default"},
    "admin_add_field": {"ru": "Добавить", "en": "Add"},
    "admin_all_fields": {"ru": "Все поля", "en": "All Fields"},
    "admin_actions": {"ru": "Действия", "en": "Actions"},
    "btn_short_edit": {"ru": "Ред.", "en": "Edit"},
    "btn_confirm_delete_field": {"ru": "Удалить поле?", "en": "Delete field?"},
    "btn_short_delete": {"ru": "Удал.", "en": "Del"},
    
    # Admin models page
    "admin_ontology_models": {"ru": "Онтологические модели", "en": "Ontology Models"},
    "admin_create_model": {"ru": "+ Создать модель", "en": "+ Create Model"},
    "admin_models_description": {"ru": "Онтологические модели определяют структуру данных для групп связанных сущностей.", "en": "Ontology models define data structure for groups of related entities."},
    "table_code": {"ru": "Код", "en": "Code"},
    "table_domain": {"ru": "Домен", "en": "Domain"},
    "table_description": {"ru": "Описание", "en": "Description"},
    "table_templates_count": {"ru": "Шаблонов", "en": "Templates"},
    "admin_confirm_delete_model": {"ru": "Удалить модель?", "en": "Delete model?"},
    "admin_no_models": {"ru": "Нет моделей.", "en": "No models."},
    "admin_create_first": {"ru": "Создать первую", "en": "Create first"},
    
    # Admin templates page
    "admin_ontology_templates": {"ru": "Шаблоны онтологии", "en": "Ontology Templates"},
    "admin_new_template": {"ru": "Новый шаблон", "en": "New Template"},
    "admin_template_kind": {"ru": "Тип сущности", "en": "Entity Type"},
    "admin_select_kind": {"ru": "— выбрать тип —", "en": "— select type —"},
    "admin_template_model": {"ru": "Модель", "en": "Model"},
    "admin_template_code": {"ru": "Код шаблона", "en": "Template Code"},
    "admin_template_name": {"ru": "Название", "en": "Name"},
    "admin_template_name_placeholder": {"ru": "Шаблон: Мой шаблон", "en": "Template: My template"},
    "admin_template_desc": {"ru": "Описание", "en": "Description"},
    "admin_template_desc_placeholder": {"ru": "Описание шаблона", "en": "Template description"},
    "admin_template_schema": {"ru": "Схема (JSON)", "en": "Schema (JSON)"},
    "btn_create_template": {"ru": "Создать шаблон", "en": "Create Template"},
    "admin_existing_templates": {"ru": "Существующие шаблоны", "en": "Existing Templates"},
    "table_status": {"ru": "Статус", "en": "Status"},
    "table_model": {"ru": "Модель", "en": "Model"},
    "table_layout": {"ru": "Макет", "en": "Layout"},
    "status_on": {"ru": "вкл", "en": "on"},
    "status_off": {"ru": "выкл", "en": "off"},
    "admin_blocks_count": {"ru": "блоков", "en": "blocks"},
    "admin_none": {"ru": "нет", "en": "none"},
    "btn_disable": {"ru": "Выкл.", "en": "Disable"},
    "btn_enable": {"ru": "Включить", "en": "Enable"},
    "btn_confirm_delete_template": {"ru": "Удалить шаблон?", "en": "Delete template?"},
    
    # Admin kinds page
    "admin_entity_types": {"ru": "Типы сущностей", "en": "Entity Types"},
    "admin_kinds_description": {"ru": "Управление схемами полей для каждого типа сущностей.", "en": "Manage field schemas for each entity type."},
    "table_fields_count": {"ru": "Полей", "en": "Fields"},
    
    # Admin relation types page
    "admin_relation_types": {"ru": "Типы связей", "en": "Relation Types"},
    "admin_relation_types_desc": {"ru": "Типы связей определяют, как сущности связаны друг с другом.", "en": "Relation types define how entities are connected."},
    "table_inverse_type": {"ru": "Обратный тип", "en": "Inverse Type"},
    "table_relations_count": {"ru": "Связей", "en": "Relations"},
    "relation_undirected": {"ru": "ненаправленная", "en": "undirected"},
    "relation_no_pair": {"ru": "нет пары", "en": "no pair"},
    "relation_transitive": {"ru": "транзитивная", "en": "transitive"},
    "admin_confirm_delete_relation_type": {"ru": "Удалить тип связи?", "en": "Delete relation type?"},
    
    # Admin users page
    "table_created": {"ru": "Создан", "en": "Created"},
    "status_blocked": {"ru": "заблокирован", "en": "blocked"},
    
    # Admin plugins page
    "admin_installed_plugins": {"ru": "Установленные плагины", "en": "Installed Plugins"},
    "admin_available_plugins": {"ru": "Доступные плагины", "en": "Available Plugins"},
    "admin_no_installed": {"ru": "Нет установленных плагинов", "en": "No installed plugins"},
    "admin_plugins_description": {"ru": "Плагины устанавливаются путём добавления директории в plugins/", "en": "Plugins are installed by adding a directory in plugins/"},
    
    # Admin languages page
    "admin_languages": {"ru": "Языки", "en": "Languages"},
    "table_native_name": {"ru": "Название (родной)", "en": "Native Name"},
    "table_sort_order": {"ru": "Порядок", "en": "Sort Order"},
    "status_active": {"ru": "Активен", "en": "Active"},
    "status_inactive": {"ru": "Неактивен", "en": "Inactive"},
    "btn_confirm_delete_language": {"ru": "Удалить язык?", "en": "Delete language?"},
    
    # Admin UI translations page
    "admin_ui_translations": {"ru": "UI Переводы", "en": "UI Translations"},
    "btn_export_json": {"ru": "Экспорт JSON", "en": "Export JSON"},
    "btn_import_json": {"ru": "Импорт JSON", "en": "Import JSON"},
    "admin_new_string": {"ru": "Новая строка", "en": "New String"},
    "admin_value": {"ru": "Значение", "en": "Value"},
    "table_key": {"ru": "Ключ", "en": "Key"},
    "btn_confirm_delete_string": {"ru": "Удалить строку?", "en": "Delete string?"},
    "admin_total": {"ru": "Всего", "en": "Total"},
    "admin_rows": {"ru": "строк", "en": "rows"},
    "admin_language": {"ru": "Язык", "en": "Language"},
    "admin_import_error": {"ru": "Ошибка импорта", "en": "Import error"},
}


async def seed_admin_ui_strings():
    """Create admin UI string entities with multilingual projections."""
    async with async_session() as db:
        kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_code == "ui_string"))
        kind = kind_result.scalar_one_or_none()
        if not kind:
            print("ERROR: EntityKind 'ui_string' not found.")
            return

        model_result = await db.execute(select(OntologyModel).where(OntologyModel.model_code == "language"))
        model = model_result.scalar_one_or_none()

        template_result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.template_code == "ui_translation"))
        template = template_result.scalar_one_or_none()

        ctx_result = await db.execute(select(Context).where(Context.context_code == "default"))
        ctx = ctx_result.scalar_one_or_none()

        lang_ids = {}
        for code in ["ru", "en"]:
            lang_result = await db.execute(select(Language).where(Language.code == code))
            lang = lang_result.scalar_one_or_none()
            if lang:
                lang_ids[code] = lang.language_id

        existing_result = await db.execute(
            select(Entity.entity_code).where(Entity.kind_id == kind.kind_id)
        )
        existing_codes = set(existing_result.scalars().all())

        created = 0
        skipped = 0
        for key, values in TRANSLATIONS.items():
            if key in existing_codes:
                skipped += 1
                continue

            entity_id = uuid.uuid4()
            entity = Entity(entity_id=entity_id, entity_code=key, kind_id=kind.kind_id, status="active", version_id=1)
            db.add(entity)
            await db.flush()

            ru_lang_id = lang_ids.get("ru")
            if ru_lang_id:
                db.add(EntityLabel(entity_id=entity_id, language_id=ru_lang_id, label=values.get("ru", key), is_primary=True, version_id=1))

            for lang_code, lang_id in lang_ids.items():
                value = values.get(lang_code, "")
                if not value:
                    continue
                proj_id = uuid.uuid4()
                db.add(EntityProjection(projection_id=proj_id, entity_id=entity_id, model_id=model.model_id, template_id=template.template_id, context_id=ctx.context_id, projection_code=f"{key}_{lang_code}", projection_name=f"{key} ({lang_code})", confidence=1.0, version_id=1))
                await db.flush()
                state_data = {"key": key, "value": value}
                state_hash = hashlib.sha256(json.dumps(state_data, sort_keys=True).encode()).hexdigest()
                db.add(ProjectionState(projection_id=proj_id, state_data=state_data, state_hash=state_hash, is_current=True, version_id=1))

            created += 1
            if created % 20 == 0:
                print(f"  Created {created} entities...")
                await db.flush()

        await db.commit()
        print(f"Done: {created} entities created, {skipped} skipped")


if __name__ == "__main__":
    asyncio.run(seed_admin_ui_strings())
