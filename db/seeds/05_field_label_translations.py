"""
Seed script: Add field label translations for de, fr, es, zh, ja.
Run with: docker compose exec app python -m db.seeds.05_field_label_translations
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

FIELD_LABELS = {
    "field_year": {"de": "Jahr", "fr": "Année", "es": "Año", "zh": "年份", "ja": "年"},
    "field_genre": {"de": "Genre", "fr": "Genre", "es": "Género", "zh": "类型", "ja": "ジャンル"},
    "field_title": {"de": "Titel", "fr": "Titre", "es": "Título", "zh": "标题", "ja": "タイトル"},
    "field_rating": {"de": "Bewertung", "fr": "Note", "es": "Calificación", "zh": "评分", "ja": "評価"},
    "field_country": {"de": "Land", "fr": "Pays", "es": "País", "zh": "国家", "ja": "国"},
    "field_language": {"de": "Sprache", "fr": "Langue", "es": "Idioma", "zh": "语言", "ja": "言語"},
    "field_budget_mln": {"de": "Budget (Mio.)", "fr": "Budget (Mio.)", "es": "Presupuesto (Mio.)", "zh": "预算 (百万)", "ja": "予算 (百万)"},
    "field_duration_min": {"de": "Dauer (Min)", "fr": "Durée (min)", "es": "Duración (min)", "zh": "时长 (分钟)", "ja": "上映時間 (分)"},
    "field_artist": {"de": "Künstler", "fr": "Artiste", "es": "Artista", "zh": "艺术家", "ja": "アーティスト"},
    "field_album": {"de": "Album", "fr": "Album", "es": "Álbum", "zh": "专辑", "ja": "アルバム"},
    "field_bpm": {"de": "BPM", "fr": "BPM", "es": "BPM", "zh": "BPM", "ja": "BPM"},
    "field_author": {"de": "Autor", "fr": "Auteur", "es": "Autor", "zh": "作者", "ja": "著者"},
    "field_pages": {"de": "Seiten", "fr": "Pages", "es": "Páginas", "zh": "页数", "ja": "ページ"},
    "field_isbn": {"de": "ISBN", "fr": "ISBN", "es": "ISBN", "zh": "ISBN", "ja": "ISBN"},
    "field_first_name": {"de": "Vorname", "fr": "Prénom", "es": "Nombre", "zh": "名字", "ja": "名"},
    "field_last_name": {"de": "Nachname", "fr": "Nom", "es": "Apellido", "zh": "姓氏", "ja": "姓"},
    "field_birth_date": {"de": "Geburtsdatum", "fr": "Date de naissance", "es": "Fecha de nacimiento", "zh": "出生日期", "ja": "生年月日"},
    "field_birth_place": {"de": "Geburtsort", "fr": "Lieu de naissance", "es": "Lugar de nacimiento", "zh": "出生地", "ja": "出生地"},
    "field_nationality": {"de": "Nationalität", "fr": "Nationalité", "es": "Nacionalidad", "zh": "国籍", "ja": "国籍"},
    "field_occupation": {"de": "Beruf", "fr": "Profession", "es": "Profesión", "zh": "职业", "ja": "職業"},
    "field_name": {"de": "Name", "fr": "Nom", "es": "Nombre", "zh": "名称", "ja": "名前"},
    "field_species": {"de": "Art", "fr": "Espèce", "es": "Especie", "zh": "物种", "ja": "種"},
    "field_habitat": {"de": "Lebensraum", "fr": "Habitat", "es": "Hábitat", "zh": "栖息地", "ja": "生息地"},
    "field_diet": {"de": "Ernährung", "fr": "Régime alimentaire", "es": "Dieta", "zh": "饮食", "ja": "食性"},
    "field_lifespan_years": {"de": "Lebensdauer", "fr": "Espérance de vie", "es": "Esperanza de vida", "zh": "寿命", "ja": "寿命"},
    "field_symbol": {"de": "Symbol", "fr": "Symbole", "es": "Símbolo", "zh": "符号", "ja": "記号"},
    "field_atomic_number": {"de": "Ordnungszahl", "fr": "Numéro atomique", "es": "Número atómico", "zh": "原子序数", "ja": "原子番号"},
    "field_atomic_mass": {"de": "Atommasse", "fr": "Masse atomique", "es": "Masa atómica", "zh": "原子质量", "ja": "原子量"},
    "field_group": {"de": "Gruppe", "fr": "Groupe", "es": "Grupo", "zh": "族", "ja": "族"},
    "field_period": {"de": "Periode", "fr": "Période", "es": "Período", "zh": "周期", "ja": "周期"},
    "field_category": {"de": "Kategorie", "fr": "Catégorie", "es": "Categoría", "zh": "类别", "ja": "カテゴリ"},
    "field_definition": {"de": "Definition", "fr": "Définition", "es": "Definición", "zh": "定义", "ja": "定義"},
    "field_domain": {"de": "Bereich", "fr": "Domaine", "es": "Dominio", "zh": "领域", "ja": "分野"},
    "field_start_year": {"de": "Startjahr", "fr": "Année de début", "es": "Año de inicio", "zh": "开始年份", "ja": "開始年"},
    "field_end_year": {"de": "Endjahr", "fr": "Année de fin", "es": "Año de fin", "zh": "结束年份", "ja": "終了年"},
    "field_region": {"de": "Region", "fr": "Région", "es": "Región", "zh": "地区", "ja": "地域"},
    "field_significance": {"de": "Bedeutung", "fr": "Signification", "es": "Importancia", "zh": "意义", "ja": "意義"},
    "field_format": {"de": "Format", "fr": "Format", "es": "Formato", "zh": "格式", "ja": "フォーマット"},
    "field_size_kb": {"de": "Größe (KB)", "fr": "Taille (Ko)", "es": "Tamaño (KB)", "zh": "大小 (KB)", "ja": "サイズ (KB)"},
    "field_photographer": {"de": "Fotograf", "fr": "Photographe", "es": "Fotógrafo", "zh": "摄影师", "ja": "写真家"},
    "field_subject": {"de": "Thema", "fr": "Sujet", "es": "Tema", "zh": "主题", "ja": "テーマ"},
    "field_published": {"de": "Veröffentlicht", "fr": "Publié", "es": "Publicado", "zh": "已发布", "ja": "公開済み"},
    "field_source": {"de": "Quelle", "fr": "Source", "es": "Fuente", "zh": "来源", "ja": "ソース"},
    "field_description": {"de": "Beschreibung", "fr": "Description", "es": "Descripción", "zh": "描述", "ja": "説明"},
    "field_content": {"de": "Inhalt", "fr": "Contenu", "es": "Contenido", "zh": "内容", "ja": "コンテンツ"},
    "field_poster_url": {"de": "Poster", "fr": "Affiche", "es": "Póster", "zh": "海报", "ja": "ポスター"},
    "field_file_url": {"de": "Datei", "fr": "Fichier", "es": "Archivo", "zh": "文件", "ja": "ファイル"},
    "field_file_title": {"de": "Dateiname", "fr": "Nom du fichier", "es": "Nombre del archivo", "zh": "文件名", "ja": "ファイル名"},
    "field_images": {"de": "Bilder", "fr": "Images", "es": "Imágenes", "zh": "图片", "ja": "画像"},
    "field_video_url": {"de": "Video", "fr": "Vidéo", "es": "Video", "zh": "视频", "ja": "ビデオ"},
    "field_audio_url": {"de": "Audio", "fr": "Audio", "es": "Audio", "zh": "音频", "ja": "オーディオ"},
    "field_audio_title": {"de": "Audiotitel", "fr": "Titre audio", "es": "Título del audio", "zh": "音频标题", "ja": "オーディオタイトル"},
    "field_release_date": {"de": "Erscheinungsdatum", "fr": "Date de sortie", "es": "Fecha de estreno", "zh": "发行日期", "ja": "公開日"},
    "field_start_date": {"de": "Startdatum", "fr": "Date de début", "es": "Fecha de inicio", "zh": "开始日期", "ja": "開始日"},
    "field_end_date": {"de": "Enddatum", "fr": "Date de fin", "es": "Fecha de fin", "zh": "结束日期", "ja": "終了日"},
    "field_price": {"de": "Preis", "fr": "Prix", "es": "Precio", "zh": "价格", "ja": "価格"},
    "field_website": {"de": "Webseite", "fr": "Site web", "es": "Sitio web", "zh": "网站", "ja": "ウェブサイト"},
    "field_email": {"de": "E-Mail", "fr": "E-mail", "es": "Correo", "zh": "电子邮件", "ja": "メール"},
    "field_score": {"de": "Bewertung", "fr": "Score", "es": "Puntuación", "zh": "分数", "ja": "スコア"},
    "field_director": {"de": "Regisseur", "fr": "Réalisateur", "es": "Director", "zh": "导演", "ja": "監督"},
    "field_duration": {"de": "Dauer", "fr": "Durée", "es": "Duración", "zh": "时长", "ja": "上映時間"},
    "field_starring": {"de": "Hauptdarsteller", "fr": "Avec", "es": "Reparto", "zh": "主演", "ja": "主演"},
    "field_screenwriter": {"de": "Drehbuchautor", "fr": "Scénariste", "es": "Guionista", "zh": "编剧", "ja": "脚本家"},
    "field_operator": {"de": "Kameramann", "fr": "Directeur de la photographie", "es": "Cinematógrafo", "zh": "摄影师", "ja": "撮影監督"},
    "field_composer": {"de": "Komponist", "fr": "Compositeur", "es": "Compositor", "zh": "作曲家", "ja": "作曲家"},
    "field_producer": {"de": "Produzent", "fr": "Producteur", "es": "Productor", "zh": "制片人", "ja": "プロデューサー"},
    "field_narrator": {"de": "Erzähler", "fr": "Narrateur", "es": "Narrador", "zh": "旁白", "ja": "ナレーター"},
    "field_studio": {"de": "Studio", "fr": "Studio", "es": "Estudio", "zh": "工作室", "ja": "スタジオ"},
    "field_country_origin": {"de": "Herkunftsland", "fr": "Pays d'origine", "es": "País de origen", "zh": "产地", "ja": "制作国"},
    "field_world_premiere": {"de": "Weltpremiere", "fr": "Première mondiale", "es": "Estreno mundial", "zh": "全球首映", "ja": "世界初上映"},
    "field_tagline": {"de": "Slogan", "fr": "Slogan", "es": "Lema", "zh": "宣传语", "ja": "タグライン"},
    "field_mpaa_rating": {"de": "FSK-Bewertung", "fr": "Classification MPAA", "es": "Clasificación MPAA", "zh": "MPAA评级", "ja": "MPAAレーティング"},
    "field_budget": {"de": "Budget", "fr": "Budget", "es": "Presupuesto", "zh": "预算", "ja": "予算"},
    "field_revenue": {"de": "Einnahmen", "fr": "Recettes", "es": "Ingresos", "zh": "票房", "ja": "興行収入"},
    "field_currency": {"de": "Währung", "fr": "Devise", "es": "Moneda", "zh": "货币", "ja": "通貨"},
}

async def seed():
    async with async_session() as db:
        kind = (await db.execute(select(EntityKind).where(EntityKind.kind_code == 'ui_string'))).scalar_one_or_none()
        model = (await db.execute(select(OntologyModel).where(OntologyModel.model_code == 'language'))).scalar_one_or_none()
        template = (await db.execute(select(OntologyTemplate).where(OntologyTemplate.template_code == 'ui_translation'))).scalar_one_or_none()
        ctx = (await db.execute(select(Context).where(Context.context_code == 'default'))).scalar_one_or_none()
        
        # Get language IDs for de, fr, es, zh, ja
        lang_ids = {}
        for code in ['de', 'fr', 'es', 'zh', 'ja']:
            lang = (await db.execute(select(Language).where(Language.code == code))).scalar_one_or_none()
            if lang:
                lang_ids[code] = lang.language_id
        
        if not lang_ids:
            print("No target languages found")
            return
        
        created = 0
        for key, values in FIELD_LABELS.items():
            # Find existing entity
            entity = (await db.execute(select(Entity).where(Entity.entity_code == key, Entity.kind_id == kind.kind_id))).scalar_one_or_none()
            if not entity:
                continue
            
            for lang_code, value in values.items():
                if lang_code not in lang_ids or not value:
                    continue
                
                lang_id = lang_ids[lang_code]
                
                # Check if projection already exists
                existing = await db.execute(
                    select(EntityProjection).where(
                        EntityProjection.entity_id == entity.entity_id,
                        EntityProjection.projection_code == f"{key}_{lang_code}"
                    )
                )
                if existing.scalar_one_or_none():
                    continue
                
                # Create projection
                proj_id = uuid.uuid4()
                db.add(EntityProjection(
                    projection_id=proj_id,
                    entity_id=entity.entity_id,
                    model_id=model.model_id,
                    template_id=template.template_id,
                    context_id=ctx.context_id,
                    projection_code=f"{key}_{lang_code}",
                    projection_name=f"{key} ({lang_code})",
                    confidence=1.0,
                    version_id=1
                ))
                await db.flush()
                
                state_data = {"key": key, "value": value}
                state_hash = hashlib.sha256(json.dumps(state_data, sort_keys=True).encode()).hexdigest()
                db.add(ProjectionState(
                    projection_id=proj_id,
                    state_data=state_data,
                    state_hash=state_hash,
                    is_current=True,
                    version_id=1
                ))
                created += 1
        
        await db.commit()
        print(f"Created {created} field label translations for de/fr/es/zh/ja")

asyncio.run(seed())
