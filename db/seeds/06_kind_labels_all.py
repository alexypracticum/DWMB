"""
Seed script: Add kind labels for all 46 kinds in 7 languages.
Run with: docker compose exec app python -m db.seeds.06_kind_labels_all
"""
import asyncio
from sqlalchemy import select
from app.database import async_session
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.languages import Language

# Kind labels: kind_code -> {lang_code: label}
KIND_LABELS = {
    "actor": {"de": "Schauspieler", "fr": "Acteur", "es": "Actor", "zh": "演员", "ja": "俳優"},
    "album": {"de": "Album", "fr": "Album", "es": "Álbum", "zh": "专辑", "ja": "アルバム"},
    "animal": {"de": "Tier", "fr": "Animal", "es": "Animal", "zh": "动物", "ja": "動物"},
    "article": {"de": "Artikel", "fr": "Article", "es": "Artículo", "zh": "文章", "ja": "記事"},
    "artist": {"de": "Künstler", "fr": "Artiste", "es": "Artista", "zh": "艺术家", "ja": "アーティスト"},
    "award": {"de": "Auszeichnung", "fr": "Prix", "es": "Premio", "zh": "奖项", "ja": "賞"},
    "book": {"de": "Buch", "fr": "Livre", "es": "Libro", "zh": "书籍", "ja": "本"},
    "channel": {"de": "Kanal", "fr": "Chaîne", "es": "Canal", "zh": "频道", "ja": "チャンネル"},
    "character": {"de": "Figur", "fr": "Personnage", "es": "Personaje", "zh": "角色", "ja": "キャラクター"},
    "chemical_element": {"de": "Chemisches Element", "fr": "Élément chimique", "es": "Elemento químico", "zh": "化学元素", "ja": "化学元素"},
    "classifier": {"de": "Klassifikator", "fr": "Classificateur", "es": "Clasificador", "zh": "分类器", "ja": "分類器"},
    "collection": {"de": "Sammlung", "fr": "Collection", "es": "Colección", "zh": "收藏", "ja": "コレクション"},
    "concept": {"de": "Konzept", "fr": "Concept", "es": "Concepto", "zh": "概念", "ja": "概念"},
    "currency": {"de": "Währung", "fr": "Devise", "es": "Moneda", "zh": "货币", "ja": "通貨"},
    "digital_file": {"de": "Digitale Datei", "fr": "Fichier numérique", "es": "Archivo digital", "zh": "数字文件", "ja": "デジタルファイル"},
    "director": {"de": "Regisseur", "fr": "Réalisateur", "es": "Director", "zh": "导演", "ja": "監督"},
    "event": {"de": "Ereignis", "fr": "Événement", "es": "Evento", "zh": "事件", "ja": "イベント"},
    "field": {"de": "Feld", "fr": "Champ", "es": "Campo", "zh": "字段", "ja": "フィールド"},
    "formula": {"de": "Formel", "fr": "Formule", "es": "Fórmula", "zh": "公式", "ja": "公式"},
    "game": {"de": "Spiel", "fr": "Jeu", "es": "Juego", "zh": "游戏", "ja": "ゲーム"},
    "genre": {"de": "Genre", "fr": "Genre", "es": "Género", "zh": "类型", "ja": "ジャンル"},
    "human": {"de": "Mensch", "fr": "Humain", "es": "Humano", "zh": "人类", "ja": "人間"},
    "label_entity": {"de": "Label-Entität", "fr": "Entité étiquette", "es": "Entidad de etiqueta", "zh": "标签实体", "ja": "ラベルエンティティ"},
    "language": {"de": "Sprache", "fr": "Langue", "es": "Idioma", "zh": "语言", "ja": "言語"},
    "language_entity": {"de": "Sprach-Entität", "fr": "Entité linguistique", "es": "Entidad lingüística", "zh": "语言实体", "ja": "言語エンティティ"},
    "movement": {"de": "Bewegung", "fr": "Mouvement", "es": "Movimiento", "zh": "运动", "ja": "運動"},
    "movie": {"de": "Film", "fr": "Film", "es": "Película", "zh": "电影", "ja": "映画"},
    "musician": {"de": "Musiker", "fr": "Musicien", "es": "Músico", "zh": "音乐家", "ja": "音楽家"},
    "ontology_model": {"de": "Ontologie-Modell", "fr": "Modèle ontologique", "es": "Modelo ontológico", "zh": "本体模型", "ja": "オントロジーモデル"},
    "ontology_template": {"de": "Ontologie-Vorlage", "fr": "Modèle ontologique", "es": "Plantilla ontológica", "zh": "本体模板", "ja": "オントロジーテンプレート"},
    "organization": {"de": "Organisation", "fr": "Organisation", "es": "Organización", "zh": "组织", "ja": "組織"},
    "period": {"de": "Zeitraum", "fr": "Période", "es": "Período", "zh": "时期", "ja": "時代"},
    "phenomenon": {"de": "Phänomen", "fr": "Phénomène", "es": "Fenómeno", "zh": "现象", "ja": "現象"},
    "photo": {"de": "Foto", "fr": "Photo", "es": "Foto", "zh": "照片", "ja": "写真"},
    "physical_item": {"de": "Physischer Gegenstand", "fr": "Objet physique", "es": "Objeto físico", "zh": "实物", "ja": "物理的アイテム"},
    "place": {"de": "Ort", "fr": "Lieu", "es": "Lugar", "zh": "地点", "ja": "場所"},
    "plant": {"de": "Pflanze", "fr": "Plante", "es": "Planta", "zh": "植物", "ja": "植物"},
    "podcast": {"de": "Podcast", "fr": "Podcast", "es": "Podcast", "zh": "播客", "ja": "ポッドキャスト"},
    "scientist": {"de": "Wissenschaftler", "fr": "Scientifique", "es": "Científico", "zh": "科学家", "ja": "科学者"},
    "software": {"de": "Software", "fr": "Logiciel", "es": "Software", "zh": "软件", "ja": "ソフトウェア"},
    "song": {"de": "Lied", "fr": "Chanson", "es": "Canción", "zh": "歌曲", "ja": "曲"},
    "tag": {"de": "Tag", "fr": "Étiquette", "es": "Etiqueta", "zh": "标签", "ja": "タグ"},
    "theorem": {"de": "Theorem", "fr": "Théorème", "es": "Teorema", "zh": "定理", "ja": "定理"},
    "ui_string": {"de": "UI-Zeichenkette", "fr": "Chaîne UI", "es": "Cadena UI", "zh": "UI字符串", "ja": "UI文字列"},
    "unit": {"de": "Einheit", "fr": "Unité", "es": "Unidad", "zh": "单位", "ja": "単位"},
    "writer": {"de": "Schriftsteller", "fr": "Écrivain", "es": "Escritor", "zh": "作家", "ja": "作家"},
}

async def seed():
    async with async_session() as db:
        lang_ids = {}
        for code in ['de', 'fr', 'es', 'zh', 'ja']:
            lang = (await db.execute(select(Language).where(Language.code == code))).scalar_one_or_none()
            if lang:
                lang_ids[code] = lang.language_id
        
        if not lang_ids:
            print("No target languages found")
            return
        
        created = 0
        for kind_code, labels in KIND_LABELS.items():
            kind = (await db.execute(select(EntityKind).where(EntityKind.kind_code == kind_code))).scalar_one_or_none()
            if not kind:
                continue
            
            for lang_code, label in labels.items():
                if lang_code not in lang_ids:
                    continue
                
                lang_id = lang_ids[lang_code]
                
                # Check if label already exists
                existing = await db.execute(
                    select(EntityKindLabel).where(
                        EntityKindLabel.kind_id == kind.kind_id,
                        EntityKindLabel.language_id == lang_id
                    )
                )
                if existing.scalar_one_or_none():
                    continue
                
                db.add(EntityKindLabel(
                    kind_id=kind.kind_id,
                    language_id=lang_id,
                    label=label
                ))
                created += 1
        
        await db.commit()
        print(f"Created {created} kind labels for de/fr/es/zh/ja")

asyncio.run(seed())
