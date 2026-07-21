"""
Seed script: Migrate UI translations from i18n.py to entities.
Run with: docker compose exec app python db/seeds/03_ui_translations.py
"""

import asyncio
import hashlib
import json
import uuid
from sqlalchemy import select, func
from app.database import async_session
from app.models.entities import Entity, EntityLabel, Context
from app.models.kinds import EntityKind
from app.models.projections import EntityProjection, ProjectionState, OntologyModel, OntologyTemplate
from app.models.languages import Language
from app.services.i18n import TRANSLATIONS


async def seed_ui_translations():
    """Create UI string entities with multilingual projections."""
    async with async_session() as db:
        # Get required IDs
        kind_result = await db.execute(
            select(EntityKind).where(EntityKind.kind_code == "ui_string")
        )
        kind = kind_result.scalar_one_or_none()
        if not kind:
            print("ERROR: EntityKind 'ui_string' not found. Run migration 008 first.")
            return

        model_result = await db.execute(
            select(OntologyModel).where(OntologyModel.model_code == "language")
        )
        model = model_result.scalar_one_or_none()
        if not model:
            print("ERROR: OntologyModel 'language' not found. Run migration 008 first.")
            return

        template_result = await db.execute(
            select(OntologyTemplate).where(OntologyTemplate.template_code == "ui_translation")
        )
        template = template_result.scalar_one_or_none()
        if not template:
            print("ERROR: OntologyTemplate 'ui_translation' not found. Run migration 008 first.")
            return

        ctx_result = await db.execute(
            select(Context).where(Context.context_code == "default")
        )
        ctx = ctx_result.scalar_one_or_none()
        if not ctx:
            print("ERROR: Context 'default' not found.")
            return

        # Get language IDs
        lang_ids = {}
        for code in TRANSLATIONS.keys():
            lang_result = await db.execute(
                select(Language).where(Language.code == code)
            )
            lang = lang_result.scalar_one_or_none()
            if lang:
                lang_ids[code] = lang.language_id

        if not lang_ids:
            print("ERROR: No languages found in language table.")
            return

        # Get all translation keys from Russian (base language)
        ru_keys = list(TRANSLATIONS["ru"].keys())
        print(f"Found {len(ru_keys)} translation keys")

        # Check existing entities
        existing_result = await db.execute(
            select(Entity.entity_code).where(Entity.kind_id == kind.kind_id)
        )
        existing_codes = set(existing_result.scalars().all())
        print(f"Found {len(existing_codes)} existing ui_string entities")

        # Create entities for each translation key
        created = 0
        skipped = 0
        for key in ru_keys:
            if key in existing_codes:
                skipped += 1
                continue

            # Create entity
            entity_id = uuid.uuid4()
            entity = Entity(
                entity_id=entity_id,
                entity_code=key,
                kind_id=kind.kind_id,
                status="active",
                version_id=1,
            )
            db.add(entity)
            await db.flush()

            # Create Russian label (primary)
            ru_label = EntityLabel(
                entity_id=entity_id,
                language_id=lang_ids.get("ru"),
                label=TRANSLATIONS["ru"].get(key, key),
                is_primary=True,
                version_id=1,
            )
            db.add(ru_label)

            # Create projection for each language
            for lang_code, lang_id in lang_ids.items():
                value = TRANSLATIONS.get(lang_code, {}).get(key, "")
                if not value:
                    continue

                proj_id = uuid.uuid4()
                proj = EntityProjection(
                    projection_id=proj_id,
                    entity_id=entity_id,
                    model_id=model.model_id,
                    template_id=template.template_id,
                    context_id=ctx.context_id,
                    projection_code=f"{key}_{lang_code}",
                    projection_name=f"{key} ({lang_code})",
                    confidence=1.0,
                    version_id=1,
                )
                db.add(proj)
                await db.flush()

                state_data = {"key": key, "value": value}
                state_hash = hashlib.sha256(
                    json.dumps(state_data, sort_keys=True).encode()
                ).hexdigest()
                ps = ProjectionState(
                    projection_id=proj_id,
                    state_data=state_data,
                    state_hash=state_hash,
                    is_current=True,
                    version_id=1,
                )
                db.add(ps)

            created += 1
            if created % 50 == 0:
                print(f"  Created {created} entities...")
                await db.flush()

        await db.commit()
        print(f"Done: {created} entities created, {skipped} skipped (already exist)")


if __name__ == "__main__":
    asyncio.run(seed_ui_translations())
