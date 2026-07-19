#!/usr/bin/env python3
"""
Seed data generator for DWMB Meta-System.
Creates 35 entity types with 10 records each, cross-referenced.
Run: python db/seeds/02_seed_data.py
"""

import asyncio
import uuid
import json
import hashlib
import os
from datetime import datetime, timezone
from asyncpg import connect

DB_URL = os.environ.get("DATABASE_URL", "postgresql://dwmb:dwmb_secret_2026@localhost:5432/dwmb")


def hash_password(password: str) -> str:
    """Generate bcrypt hash."""
    try:
        from passlib.context import CryptContext
        pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        return pwd_context.hash(password)
    except ImportError:
        return "$2b$12$LJ3m4ys4Gz8nZJQ5vQ5vQeQ5vQ5vQ5vQ5vQ5vQ5vQ5vQ5vQ5vQ5"

def uid():
    return str(uuid.uuid4())

def now():
    return datetime.now(timezone.utc)

def hash_json(data):
    return hashlib.sha256(json.dumps(data, sort_keys=True, default=str).encode()).hexdigest()

# =============================================================================
#  ENTITY DATA: 35 типов x 10 записей с пересечениями
# =============================================================================

ENTITY_DATA = {
    "movie": {
        "model": "cinema",
        "template_code": "tpl_movie",
        "template_name": "Шаблон: Фильм",
        "schema": {
            "type": "object",
            "properties": {
                "title": {"type": "string"},
                "year": {"type": "integer"},
                "duration_min": {"type": "integer"},
                "rating": {"type": "number"},
                "budget_mln": {"type": "number"},
                "genre": {"type": "string"},
                "country": {"type": "string"},
                "language": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "inception_2010", "label_ru": "Начало", "label_en": "Inception", "desc_ru": "Научно-фантастический боевик Кристофера Нолана о краже секретов из подсознания", "state": {"title": "Inception", "year": 2010, "duration_min": 148, "rating": 8.8, "budget_mln": 160, "genre": "Sci-Fi", "country": "USA", "language": "English"}},
            {"entity_code": "matrix_1999", "label_ru": "Матрица", "label_en": "The Matrix", "desc_ru": "Культовый научно-фантастический фильм братьев Вачовских", "state": {"title": "The Matrix", "year": 1999, "duration_min": 136, "rating": 8.7, "budget_mln": 63, "genre": "Sci-Fi", "country": "USA", "language": "English"}},
            {"entity_code": "interstellar_2014", "label_ru": "Интерстеллар", "label_en": "Interstellar", "desc_ru": "Эпическая фантастическая драма о путешествии сквозь червоточину", "state": {"title": "Interstellar", "year": 2014, "duration_min": 169, "rating": 8.6, "budget_mln": 165, "genre": "Sci-Fi", "country": "USA", "language": "English"}},
            {"entity_code": "fight_club_1999", "label_ru": "Бойцовский клуб", "label_en": "Fight Club", "desc_ru": "Триллер Дэвид Финчера по роману Чака Паланика", "state": {"title": "Fight Club", "year": 1999, "duration_min": 139, "rating": 8.8, "budget_mln": 63, "genre": "Drama", "country": "USA", "language": "English"}},
            {"entity_code": "pulp_fiction_1994", "label_ru": "Криминальное чтиво", "label_en": "Pulp Fiction", "desc_ru": "Культовый криминальный фильм Квентина Тарантино", "state": {"title": "Pulp Fiction", "year": 1994, "duration_min": 154, "rating": 8.9, "budget_mln": 8, "genre": "Crime", "country": "USA", "language": "English"}},
            {"entity_code": "dark_knight_2008", "label_ru": "Тёмный рыцарь", "label_en": "The Dark Knight", "desc_ru": "Супергеройский фильм Кристофера Нолана о Бэтмене", "state": {"title": "The Dark Knight", "year": 2008, "duration_min": 152, "rating": 9.0, "budget_mln": 185, "genre": "Action", "country": "USA", "language": "English"}},
            {"entity_code": "forrest_gump_1994", "label_ru": "Форрест Гамп", "label_en": "Forrest Gump", "desc_ru": "Трогательная история жизни простого человека", "state": {"title": "Forrest Gump", "year": 1994, "duration_min": 142, "rating": 8.8, "budget_mln": 55, "genre": "Drama", "country": "USA", "language": "English"}},
            {"entity_code": "schindlers_list_1993", "label_ru": "Список Шиндлера", "label_en": "Schindler's List", "desc_ru": "Драма Стивена Спилберга о Холокосте", "state": {"title": "Schindler's List", "year": 1993, "duration_min": 195, "rating": 9.0, "budget_mln": 22, "genre": "Drama", "country": "USA", "language": "English"}},
            {"entity_code": "django_2012", "label_ru": "Джанго освобождённый", "label_en": "Django Unchained", "desc_ru": "Вестерн Квентина Тарантино о борьбе с рабством", "state": {"title": "Django Unchained", "year": 2012, "duration_min": 165, "rating": 8.4, "budget_mln": 100, "genre": "Western", "country": "USA", "language": "English"}},
            {"entity_code": "shutter_island_2010", "label_ru": "Остров проклятых", "label_en": "Shutter Island", "desc_ru": "Психологический триллер Мартина Скорсезе", "state": {"title": "Shutter Island", "year": 2010, "duration_min": 138, "rating": 8.2, "budget_mln": 80, "genre": "Thriller", "country": "USA", "language": "English"}}
        ]
    },
    "actor": {
        "model": "cinema",
        "template_code": "tpl_person",
        "template_name": "Шаблон: Человек (персона)",
        "schema": {
            "type": "object",
            "properties": {
                "first_name": {"type": "string"},
                "last_name": {"type": "string"},
                "birth_date": {"type": "string"},
                "birth_place": {"type": "string"},
                "nationality": {"type": "string"},
                "occupation": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "leonardo_dicaprio", "label_ru": "Леонардо ДиКаприо", "label_en": "Leonardo DiCaprio", "desc_ru": "Американский актёр, обладатель премии Оскар", "state": {"first_name": "Leonardo", "last_name": "DiCaprio", "birth_date": "1974-11-11", "birth_place": "Los Angeles, USA", "nationality": "American", "occupation": "Actor"}},
            {"entity_code": "keanu_reeves", "label_ru": "Киану Ривз", "label_en": "Keanu Reeves", "desc_ru": "Канадский актёр, звезда трилогии Матрица", "state": {"first_name": "Keanu", "last_name": "Reeves", "birth_date": "1964-09-02", "birth_place": "Beirut, Lebanon", "nationality": "Canadian", "occupation": "Actor"}},
            {"entity_code": "matthew_mcconaughey", "label_ru": "Мэттью Макконахи", "label_en": "Matthew McConaughey", "desc_ru": "Американский актёр, обладатель Оскара за Интерстеллар", "state": {"first_name": "Matthew", "last_name": "McConaughey", "birth_date": "1969-11-04", "birth_place": "Uvalde, Texas", "nationality": "American", "occupation": "Actor"}},
            {"entity_code": "brad_pitt", "label_ru": "Брэд Питт", "label_en": "Brad Pitt", "desc_ru": "Американский актёр и продюсер", "state": {"first_name": "Brad", "last_name": "Pitt", "birth_date": "1963-12-18", "birth_place": "Shawnee, Oklahoma", "nationality": "American", "occupation": "Actor"}},
            {"entity_code": "john_travolta", "label_ru": "Джон Траволта", "label_en": "John Travolta", "desc_ru": "Американский актёр, звезда Криминального чтиво", "state": {"first_name": "John", "last_name": "Travolta", "birth_date": "1954-02-18", "birth_place": "Englewood, New Jersey", "nationality": "American", "occupation": "Actor"}},
            {"entity_code": "tom_hardy", "label_ru": "Том Харди", "label_en": "Tom Hardy", "desc_ru": "Британский актёр, исполнитель роли Бейна", "state": {"first_name": "Tom", "last_name": "Hardy", "birth_date": "1977-09-15", "birth_place": "London, UK", "nationality": "British", "occupation": "Actor"}},
            {"entity_code": "tom_hanks", "label_ru": "Том Хэнкс", "label_en": "Tom Hanks", "desc_ru": "Американский актёр, двукратный обладатель Оскара", "state": {"first_name": "Tom", "last_name": "Hanks", "birth_date": "1956-07-09", "birth_place": "Concord, California", "nationality": "American", "occupation": "Actor"}},
            {"entity_code": "liam_neeson", "label_ru": "Лиам Нисон", "label_en": "Liam Neeson", "desc_ru": "Североирландский актёр, исполнитель роли Шиндлера", "state": {"first_name": "Liam", "last_name": "Neeson", "birth_date": "1952-06-07", "birth_place": "Ballymena, UK", "nationality": "Irish", "occupation": "Actor"}},
            {"entity_code": "jamie_fox", "label_ru": "Джейми Фокс", "label_en": "Jamie Foxx", "desc_ru": "Американский актёр и музыкант", "state": {"first_name": "Jamie", "last_name": "Foxx", "birth_date": "1967-12-13", "birth_place": "Terrell, Texas", "nationality": "American", "occupation": "Actor"}},
            {"entity_code": "mark_ruffalo", "label_ru": "Марк Руффало", "label_en": "Mark Ruffalo", "desc_ru": "Американский актёр, исполнитель роли Халка", "state": {"first_name": "Mark", "last_name": "Ruffalo", "birth_date": "1967-11-22", "birth_place": "Kenosha, Wisconsin", "nationality": "American", "occupation": "Actor"}}
        ]
    },
    "director": {
        "model": "cinema",
        "template_code": "tpl_person",
        "template_name": "Шаблон: Человек (персона)",
        "schema": {
            "type": "object",
            "properties": {
                "first_name": {"type": "string"},
                "last_name": {"type": "string"},
                "birth_date": {"type": "string"},
                "birth_place": {"type": "string"},
                "nationality": {"type": "string"},
                "occupation": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "christopher_nolan", "label_ru": "Кристофер Нолан", "label_en": "Christopher Nolan", "desc_ru": "Британско-американский режиссёр, мастер интеллектуального кино", "state": {"first_name": "Christopher", "last_name": "Nolan", "birth_date": "1970-07-30", "birth_place": "London, UK", "nationality": "British-American", "occupation": "Director"}},
            {"entity_code": "wachowskis", "label_ru": "Братья Вачовски", "label_en": "The Wachowskis", "desc_ru": "Американские режиссёры, создатели Матрицы", "state": {"first_name": "Lana & Lilly", "last_name": "Wachowski", "birth_date": "1965-06-21", "birth_place": "Chicago, USA", "nationality": "American", "occupation": "Director"}},
            {"entity_code": "david_fincher", "label_ru": "Дэвид Финчер", "label_en": "David Fincher", "desc_ru": "Американский режиссёр триллеров", "state": {"first_name": "David", "last_name": "Fincher", "birth_date": "1962-08-28", "birth_place": "Denver, Colorado", "nationality": "American", "occupation": "Director"}},
            {"entity_code": "quentin_tarantino", "label_ru": "Квентин Тарантино", "label_en": "Quentin Tarantino", "desc_ru": "Американский режиссёр, автор уникального стиля", "state": {"first_name": "Quentin", "last_name": "Tarantino", "birth_date": "1963-03-27", "birth_place": "Knoxville, Tennessee", "nationality": "American", "occupation": "Director"}},
            {"entity_code": "steven_spielberg", "label_ru": "Стивен Спилберг", "label_en": "Steven Spielberg", "desc_ru": "Легендарный американский режиссёр", "state": {"first_name": "Steven", "last_name": "Spielberg", "birth_date": "1946-12-18", "birth_place": "Cincinnati, Ohio", "nationality": "American", "occupation": "Director"}},
            {"entity_code": "martin_scorsese", "label_ru": "Мартин Скорсезе", "label_en": "Martin Scorsese", "desc_ru": "Американский режиссёр классического кино", "state": {"first_name": "Martin", "last_name": "Scorsese", "birth_date": "1942-11-17", "birth_place": "Queens, New York", "nationality": "American", "occupation": "Director"}},
            {"entity_code": "ridley_scott", "label_ru": "Ридли Скотт", "label_en": "Ridley Scott", "desc_ru": "Британский режиссёр научной фантастики", "state": {"first_name": "Ridley", "last_name": "Scott", "birth_date": "1937-11-30", "birth_place": "South Shields, UK", "nationality": "British", "occupation": "Director"}},
            {"entity_code": "stanley_kubrick", "label_ru": "Стэнли Кубрик", "label_en": "Stanley Kubrick", "desc_ru": "Американский режиссёр-визионер", "state": {"first_name": "Stanley", "last_name": "Kubrick", "birth_date": "1928-07-26", "birth_place": "Bronx, New York", "nationality": "American", "occupation": "Director"}},
            {"entity_code": "frank_darabont", "label_ru": "Фрэнк Дарабонт", "label_en": "Frank Darabont", "desc_ru": "Американский режиссёр, мастер экранизаций Кинга", "state": {"first_name": "Frank", "last_name": "Darabont", "birth_date": "1959-01-28", "birth_place": "Montbéliard, France", "nationality": "American", "occupation": "Director"}},
            {"entity_code": "denis_villeneuve", "label_ru": "Дени Вильнёв", "label_en": "Denis Villeneuve", "desc_ru": "Канадский режиссёр научной фантастики", "state": {"first_name": "Denis", "last_name": "Villeneuve", "birth_date": "1967-10-03", "birth_place": "Quebec, Canada", "nationality": "Canadian", "occupation": "Director"}}
        ]
    },
    "song": {
        "model": "music",
        "template_code": "tpl_song",
        "template_name": "Шаблон: Песня",
        "schema": {
            "type": "object",
            "properties": {
                "title": {"type": "string"},
                "artist": {"type": "string"},
                "album": {"type": "string"},
                "year": {"type": "integer"},
                "duration_sec": {"type": "integer"},
                "genre": {"type": "string"},
                "bpm": {"type": "integer"}
            }
        },
        "records": [
            {"entity_code": "bohemian_rhapsody", "label_ru": "Bohemian Rhapsody", "label_en": "Bohemian Rhapsody", "desc_ru": "Эпическая рок-опера Queen", "state": {"title": "Bohemian Rhapsody", "artist": "Queen", "album": "A Night at the Opera", "year": 1975, "duration_sec": 355, "genre": "Rock", "bpm": 72}},
            {"entity_code": "stairway_to_heaven", "label_ru": "Stairway to Heaven", "label_en": "Stairway to Heaven", "desc_ru": "Легендарная баллада Led Zeppelin", "state": {"title": "Stairway to Heaven", "artist": "Led Zeppelin", "album": "Led Zeppelin IV", "year": 1971, "duration_sec": 482, "genre": "Rock", "bpm": 82}},
            {"entity_code": "imagine", "label_ru": "Imagine", "label_en": "Imagine", "desc_ru": "Гимн мира Джона Леннона", "state": {"title": "Imagine", "artist": "John Lennon", "album": "Imagine", "year": 1971, "duration_sec": 187, "genre": "Pop", "bpm": 76}},
            {"entity_code": "hotel_california", "label_ru": "Hotel California", "label_en": "Hotel California", "desc_ru": "Культовая песня Eagles", "state": {"title": "Hotel California", "artist": "Eagles", "album": "Hotel California", "year": 1977, "duration_sec": 391, "genre": "Rock", "bpm": 74}},
            {"entity_code": "smells_like_teen_spirit", "label_ru": "Smells Like Teen Spirit", "label_en": "Smells Like Teen Spirit", "desc_ru": "Гимн поколения X от Nirvana", "state": {"title": "Smells Like Teen Spirit", "artist": "Nirvana", "album": "Nevermind", "year": 1991, "duration_sec": 301, "genre": "Grunge", "bpm": 117}},
            {"entity_code": "like_a_rolling_stone", "label_ru": "Like a Rolling Stone", "label_en": "Like a Rolling Stone", "desc_ru": "Революционная песня Боба Дилана", "state": {"title": "Like a Rolling Stone", "artist": "Bob Dylan", "album": "Highway 61 Revisited", "year": 1965, "duration_sec": 369, "genre": "Rock", "bpm": 95}},
            {"entity_code": "yesterday", "label_ru": "Yesterday", "label_en": "Yesterday", "desc_ru": "Самая перепеваемая песня Beatles", "state": {"title": "Yesterday", "artist": "The Beatles", "album": "Help!", "year": 1965, "duration_sec": 125, "genre": "Pop", "bpm": 96}},
            {"entity_code": "thriller", "label_ru": "Thriller", "label_en": "Thriller", "desc_ru": "Заглавный трек самого продаваемого альбома", "state": {"title": "Thriller", "artist": "Michael Jackson", "album": "Thriller", "year": 1982, "duration_sec": 357, "genre": "Pop", "bpm": 118}},
            {"entity_code": "comfortably_numb", "label_ru": "Comfortably Numb", "label_en": "Comfortably Numb", "desc_ru": "Психеделическая баллада Pink Floyd", "state": {"title": "Comfortably Numb", "artist": "Pink Floyd", "album": "The Wall", "year": 1979, "duration_sec": 382, "genre": "Progressive Rock", "bpm": 63}},
            {"entity_code": "no_woman_no_cry", "label_ru": "No Woman No Cry", "label_en": "No Woman No Cry", "desc_ru": "Регги-классика Боба Марли", "state": {"title": "No Woman No Cry", "artist": "Bob Marley", "album": "Natty Dread", "year": 1974, "duration_sec": 285, "genre": "Reggae", "bpm": 78}}
        ]
    },
    "musician": {
        "model": "music",
        "template_code": "tpl_person",
        "template_name": "Шаблон: Человек (персона)",
        "schema": {
            "type": "object",
            "properties": {
                "first_name": {"type": "string"},
                "last_name": {"type": "string"},
                "birth_date": {"type": "string"},
                "birth_place": {"type": "string"},
                "nationality": {"type": "string"},
                "occupation": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "freddie_mercury", "label_ru": "Фредди Меркьюри", "label_en": "Freddie Mercury", "desc_ru": "Легендарный вокалист Queen", "state": {"first_name": "Freddie", "last_name": "Mercury", "birth_date": "1946-09-05", "birth_place": "Stone Town, Tanzania", "nationality": "British", "occupation": "Musician"}},
            {"entity_code": "jimi_hendrix", "label_ru": "Джими Хендрикс", "label_en": "Jimi Hendrix", "desc_ru": "Величайший гитарист всех времён", "state": {"first_name": "Jimi", "last_name": "Hendrix", "birth_date": "1942-11-27", "birth_place": "Seattle, USA", "nationality": "American", "occupation": "Musician"}},
            {"entity_code": "bob_dylan", "label_ru": "Боб Дилан", "label_en": "Bob Dylan", "desc_ru": "Лауреат Нобелевской премии по литературе", "state": {"first_name": "Bob", "last_name": "Dylan", "birth_date": "1941-05-24", "birth_place": "Duluth, Minnesota", "nationality": "American", "occupation": "Musician"}},
            {"entity_code": "john_lennon", "label_ru": "Джон Леннон", "label_en": "John Lennon", "desc_ru": "Сооснователь Beatles, активист мира", "state": {"first_name": "John", "last_name": "Lennon", "birth_date": "1940-10-09", "birth_place": "Liverpool, UK", "nationality": "British", "occupation": "Musician"}},
            {"entity_code": "michael_jackson", "label_ru": "Майкл Джексон", "label_en": "Michael Jackson", "desc_ru": "Король поп-музыки", "state": {"first_name": "Michael", "last_name": "Jackson", "birth_date": "1958-08-29", "birth_place": "Gary, Indiana", "nationality": "American", "occupation": "Musician"}},
            {"entity_code": "bob_marley", "label_ru": "Боб Марли", "label_en": "Bob Marley", "desc_ru": "Легенда регги", "state": {"first_name": "Bob", "last_name": "Marley", "birth_date": "1945-02-06", "birth_place": "Nine Mile, Jamaica", "nationality": "Jamaican", "occupation": "Musician"}},
            {"entity_code": "david_gilmour", "label_ru": "Дэвид Гилмор", "label_en": "David Gilmour", "desc_ru": "Гитарист и вокалист Pink Floyd", "state": {"first_name": "David", "last_name": "Gilmour", "birth_date": "1946-03-06", "birth_place": "Cambridge, UK", "nationality": "British", "occupation": "Musician"}},
            {"entity_code": "kurt_cobain", "label_ru": "Курт Кобейн", "label_en": "Kurt Cobain", "desc_ru": "Лидер Nirvana, икон grunge", "state": {"first_name": "Kurt", "last_name": "Cobain", "birth_date": "1967-02-20", "birth_place": "Aberdeen, Washington", "nationality": "American", "occupation": "Musician"}},
            {"entity_code": "elvis_presley", "label_ru": "Элвис Пресли", "label_en": "Elvis Presley", "desc_ru": "Король рок-н-ролла", "state": {"first_name": "Elvis", "last_name": "Presley", "birth_date": "1935-01-08", "birth_place": "Tupelo, Mississippi", "nationality": "American", "occupation": "Musician"}},
            {"entity_code": "ludwig_van_beethoven", "label_ru": "Людвиг ван Бетховен", "label_en": "Ludwig van Beethoven", "desc_ru": "Великий немецкий композитор", "state": {"first_name": "Ludwig", "last_name": "van Beethoven", "birth_date": "1770-12-17", "birth_place": "Bonn, Germany", "nationality": "German", "occupation": "Musician"}}
        ]
    },
    "book": {
        "model": "literature",
        "template_code": "tpl_book",
        "template_name": "Шаблон: Книга",
        "schema": {
            "type": "object",
            "properties": {
                "title": {"type": "string"},
                "author": {"type": "string"},
                "year": {"type": "integer"},
                "pages": {"type": "integer"},
                "genre": {"type": "string"},
                "language": {"type": "string"},
                "isbn": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "1984_orwell", "label_ru": "1984", "label_en": "1984", "desc_ru": "Антиутопия Джорджа Оруэлла о тоталитарном обществе", "state": {"title": "1984", "author": "George Orwell", "year": 1949, "pages": 328, "genre": "Dystopia", "language": "English", "isbn": "978-0451524935"}},
            {"entity_code": "brave_new_world", "label_ru": "Дивный новый мир", "label_en": "A Brave New World", "desc_ru": "Антиутопия Олдоса Хаксли", "state": {"title": "A Brave New World", "author": "Aldous Huxley", "year": 1932, "pages": 311, "genre": "Dystopia", "language": "English", "isbn": "978-0060850524"}},
            {"entity_code": "fahrenheit_451", "label_ru": "451 градус по Фаренгейту", "label_en": "Fahrenheit 451", "desc_ru": "Антиутопия Рэя Брэдбери о сжигании книг", "state": {"title": "Fahrenheit 451", "author": "Ray Bradbury", "year": 1953, "pages": 194, "genre": "Dystopia", "language": "English", "isbn": "978-1451673319"}},
            {"entity_code": "hobbit", "label_ru": "Хоббит", "label_en": "The Hobbit", "desc_ru": "Фэнтези Толкина о путешествии Бильбо", "state": {"title": "The Hobbit", "author": "J.R.R. Tolkien", "year": 1937, "pages": 310, "genre": "Fantasy", "language": "English", "isbn": "978-0547928227"}},
            {"entity_code": "dune", "label_ru": "Дюна", "label_en": "Dune", "desc_ru": "Научно-фантастический эпос Фрэнка Герберта", "state": {"title": "Dune", "author": "Frank Herbert", "year": 1965, "pages": 688, "genre": "Sci-Fi", "language": "English", "isbn": "978-0441013593"}},
            {"entity_code": "master_margarita", "label_ru": "Мастер и Маргарита", "label_en": "The Master and Margarita", "desc_ru": "Роман Булгакова о добре и зле", "state": {"title": "Мастер и Маргарита", "author": "Михаил Булгаков", "year": 1967, "pages": 480, "genre": "Novel", "language": "Russian", "isbn": "978-5170802890"}},
            {"entity_code": "war_peace", "label_ru": "Война и мир", "label_en": "War and Peace", "desc_ru": "Эпический роман Толстого", "state": {"title": "Война и мир", "author": "Лев Толстой", "year": 1869, "pages": 1225, "genre": "Historical Novel", "language": "Russian", "isbn": "978-5170774753"}},
            {"entity_code": "crime_punishment", "label_ru": "Преступление и наказание", "label_en": "Crime and Punishment", "desc_ru": "Психологический роман Достоевского", "state": {"title": "Преступление и наказание", "author": "Фёдор Достоевский", "year": 1866, "pages": 671, "genre": "Psychological Novel", "language": "Russian", "isbn": "978-5170774760"}},
            {"entity_code": "solaris", "label_ru": "Солярис", "label_en": "Solaris", "desc_ru": "Научно-фантастический роман Лема", "state": {"title": "Solaris", "author": "Stanislaw Lem", "year": 1961, "pages": 204, "genre": "Sci-Fi", "language": "Polish", "isbn": "978-0156007528"}},
            {"entity_code": "harry_potter", "label_ru": "Гарри Поттер", "label_en": "Harry Potter", "desc_ru": "Серия романов о юном волшебнике", "state": {"title": "Harry Potter and the Philosopher's Stone", "author": "J.K. Rowling", "year": 1997, "pages": 309, "genre": "Fantasy", "language": "English", "isbn": "978-0747532699"}}
        ]
    },
    "writer": {
        "model": "literature",
        "template_code": "tpl_person",
        "template_name": "Шаблон: Человек (персона)",
        "schema": {
            "type": "object",
            "properties": {
                "first_name": {"type": "string"},
                "last_name": {"type": "string"},
                "birth_date": {"type": "string"},
                "birth_place": {"type": "string"},
                "nationality": {"type": "string"},
                "occupation": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "george_orwell", "label_ru": "Джордж Оруэлл", "label_en": "George Orwell", "desc_ru": "Английский писатель, автор антиутопий", "state": {"first_name": "George", "last_name": "Orwell", "birth_date": "1903-06-25", "birth_place": "Motihari, India", "nationality": "British", "occupation": "Writer"}},
            {"entity_code": "tolkien", "label_ru": "Дж. Р. Р. Толкин", "label_en": "J.R.R. Tolkien", "desc_ru": "Английский писатель, создатель Средиземья", "state": {"first_name": "John Ronald Reuel", "last_name": "Tolkien", "birth_date": "1892-01-03", "birth_place": "Bloemfontein, South Africa", "nationality": "British", "occupation": "Writer"}},
            {"entity_code": "bulgakov", "label_ru": "Михаил Булгаков", "label_en": "Mikhail Bulgakov", "desc_ru": "Русский писатель, автор Мастера и Маргариты", "state": {"first_name": "Mikhail", "last_name": "Bulgakov", "birth_date": "1891-05-15", "birth_place": "Kiev, Ukraine", "nationality": "Russian", "occupation": "Writer"}},
            {"entity_code": "tolstoy", "label_ru": "Лев Толстой", "label_en": "Leo Tolstoy", "desc_ru": "Великий русский писатель", "state": {"first_name": "Lev", "last_name": "Tolstoy", "birth_date": "1828-09-09", "birth_place": "Yasnaya Polyana, Russia", "nationality": "Russian", "occupation": "Writer"}},
            {"entity_code": "dostoevsky", "label_ru": "Фёдор Достоевский", "label_en": "Fyodor Dostoevsky", "desc_ru": "Русский писатель, мастер психологии", "state": {"first_name": "Fyodor", "last_name": "Dostoevsky", "birth_date": "1821-11-11", "birth_place": "Moscow, Russia", "nationality": "Russian", "occupation": "Writer"}},
            {"entity_code": "stephen_king", "label_ru": "Стивен Кинг", "label_en": "Stephen King", "desc_ru": "Король хоррора, автор более 60 книг", "state": {"first_name": "Stephen", "last_name": "King", "birth_date": "1947-09-21", "birth_place": "Portland, Maine", "nationality": "American", "occupation": "Writer"}},
            {"entity_code": "ray_bradbury", "label_ru": "Рэй Брэдбери", "label_en": "Ray Bradbury", "desc_ru": "Американский писатель-фантаст", "state": {"first_name": "Ray", "last_name": "Bradbury", "birth_date": "1920-08-22", "birth_place": "Waukegan, Illinois", "nationality": "American", "occupation": "Writer"}},
            {"entity_code": "stan_lem", "label_ru": "Станислав Лем", "label_en": "Stanislaw Lem", "desc_ru": "Польский писатель-фантаст", "state": {"first_name": "Stanislaw", "last_name": "Lem", "birth_date": "1921-09-12", "birth_place": "Lviv, Ukraine", "nationality": "Polish", "occupation": "Writer"}},
            {"entity_code": "chuck_palahniuk", "label_ru": "Чак Паланик", "label_en": "Chuck Palahniuk", "desc_ru": "Автор Бойцовского клуба", "state": {"first_name": "Chuck", "last_name": "Palahniuk", "birth_date": "1962-02-21", "birth_place": "Pasco, Washington", "nationality": "American", "occupation": "Writer"}},
            {"entity_code": "jk_rowling", "label_ru": "Дж. К. Роулинг", "label_en": "J.K. Rowling", "desc_ru": "Автор серии книг о Гарри Поттере", "state": {"first_name": "Joanne", "last_name": "Rowling", "birth_date": "1965-07-31", "birth_place": "Yate, UK", "nationality": "British", "occupation": "Writer"}}
        ]
    },
    "place": {
        "model": "geography",
        "template_code": "tpl_place",
        "template_name": "Шаблон: Место",
        "schema": {
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "country": {"type": "string"},
                "population": {"type": "integer"},
                "area_km2": {"type": "number"},
                "timezone": {"type": "string"},
                "latitude": {"type": "number"},
                "longitude": {"type": "number"}
            }
        },
        "records": [
            {"entity_code": "new_york", "label_ru": "Нью-Йорк", "label_en": "New York", "desc_ru": "Крупнейший город США, мировой финансовый центр", "state": {"name": "New York", "country": "USA", "population": 8336817, "area_km2": 783.8, "timezone": "EST", "latitude": 40.7128, "longitude": -74.0060}},
            {"entity_code": "london", "label_ru": "Лондон", "label_en": "London", "desc_ru": "Столица Великобритании", "state": {"name": "London", "country": "UK", "population": 8982000, "area_km2": 1572, "timezone": "GMT", "latitude": 51.5074, "longitude": -0.1278}},
            {"entity_code": "paris", "label_ru": "Париж", "label_en": "Paris", "desc_ru": "Столица Франции, город любви", "state": {"name": "Paris", "country": "France", "population": 2161000, "area_km2": 105.4, "timezone": "CET", "latitude": 48.8566, "longitude": 2.3522}},
            {"entity_code": "tokyo", "label_ru": "Токио", "label_en": "Tokyo", "desc_ru": "Столица Японии, крупнейший мегаполис", "state": {"name": "Tokyo", "country": "Japan", "population": 13960000, "area_km2": 2194, "timezone": "JST", "latitude": 35.6762, "longitude": 139.6503}},
            {"entity_code": "moscow", "label_ru": "Москва", "label_en": "Moscow", "desc_ru": "Столица России", "state": {"name": "Moscow", "country": "Russia", "population": 12500000, "area_km2": 2511, "timezone": "MSK", "latitude": 55.7558, "longitude": 37.6173}},
            {"entity_code": "berlin", "label_ru": "Берлин", "label_en": "Berlin", "desc_ru": "Столица Германии", "state": {"name": "Berlin", "country": "Germany", "population": 3645000, "area_km2": 891.7, "timezone": "CET", "latitude": 52.5200, "longitude": 13.4050}},
            {"entity_code": "los_angeles", "label_ru": "Лос-Анджелес", "label_en": "Los Angeles", "desc_ru": "Голливуд, столица киноиндустрии", "state": {"name": "Los Angeles", "country": "USA", "population": 3979576, "area_km2": 1302, "timezone": "PST", "latitude": 34.0522, "longitude": -118.2437}},
            {"entity_code": "rome", "label_ru": "Рим", "label_en": "Rome", "desc_ru": "Вечный город, столица Италии", "state": {"name": "Rome", "country": "Italy", "population": 2873000, "area_km2": 1285, "timezone": "CET", "latitude": 41.9028, "longitude": 12.4964}},
            {"entity_code": "sydney", "label_ru": "Сидней", "label_en": "Sydney", "desc_ru": "Крупнейший город Австралии", "state": {"name": "Sydney", "country": "Australia", "population": 5312000, "area_km2": 12368, "timezone": "AEST", "latitude": -33.8688, "longitude": 151.2093}},
            {"entity_code": "cairo", "label_ru": "Каир", "label_en": "Cairo", "desc_ru": "Столица Египта, город пирамид", "state": {"name": "Cairo", "country": "Egypt", "population": 10100000, "area_km2": 3085, "timezone": "EET", "latitude": 30.0444, "longitude": 31.2357}}
        ]
    },
    "chemical_element": {
        "model": "science",
        "template_code": "tpl_element",
        "template_name": "Шаблон: Химический элемент",
        "schema": {
            "type": "object",
            "properties": {
                "symbol": {"type": "string"},
                "name": {"type": "string"},
                "atomic_number": {"type": "integer"},
                "atomic_mass": {"type": "number"},
                "group": {"type": "integer"},
                "period": {"type": "integer"},
                "category": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "hydrogen", "label_ru": "Водород", "label_en": "Hydrogen", "desc_ru": "Первый элемент таблицы Менделеева", "state": {"symbol": "H", "name": "Hydrogen", "atomic_number": 1, "atomic_mass": 1.008, "group": 1, "period": 1, "category": "Nonmetal"}},
            {"entity_code": "helium", "label_ru": "Гелий", "label_en": "Helium", "desc_ru": "Инертный газ, второй по распространённости элемент", "state": {"symbol": "He", "name": "Helium", "atomic_number": 2, "atomic_mass": 4.003, "group": 18, "period": 1, "category": "Noble gas"}},
            {"entity_code": "carbon", "label_ru": "Углерод", "label_en": "Carbon", "desc_ru": "Основа органической химии", "state": {"symbol": "C", "name": "Carbon", "atomic_number": 6, "atomic_mass": 12.011, "group": 14, "period": 2, "category": "Nonmetal"}},
            {"entity_code": "oxygen", "label_ru": "Кислород", "label_en": "Oxygen", "desc_ru": "Элемент, необходимый для дыхания", "state": {"symbol": "O", "name": "Oxygen", "atomic_number": 8, "atomic_mass": 15.999, "group": 16, "period": 2, "category": "Nonmetal"}},
            {"entity_code": "iron", "label_ru": "Железо", "label_en": "Iron", "desc_ru": "Основной металл промышленности", "state": {"symbol": "Fe", "name": "Iron", "atomic_number": 26, "atomic_mass": 55.845, "group": 8, "period": 4, "category": "Transition metal"}},
            {"entity_code": "gold", "label_ru": "Золото", "label_en": "Gold", "desc_ru": "Благородный металл, символ богатства", "state": {"symbol": "Au", "name": "Gold", "atomic_number": 79, "atomic_mass": 196.967, "group": 11, "period": 6, "category": "Transition metal"}},
            {"entity_code": "silver", "label_ru": "Серебро", "label_en": "Silver", "desc_ru": "Благородный металл", "state": {"symbol": "Ag", "name": "Silver", "atomic_number": 47, "atomic_mass": 107.868, "group": 11, "period": 5, "category": "Transition metal"}},
            {"entity_code": "copper", "label_ru": "Медь", "label_en": "Copper", "desc_ru": "Металл, использовавшийся с древности", "state": {"symbol": "Cu", "name": "Copper", "atomic_number": 29, "atomic_mass": 63.546, "group": 11, "period": 4, "category": "Transition metal"}},
            {"entity_code": "silicon", "label_ru": "Кремний", "label_en": "Silicon", "desc_ru": "Основа современной электроники", "state": {"symbol": "Si", "name": "Silicon", "atomic_number": 14, "atomic_mass": 28.086, "group": 14, "period": 3, "category": "Metalloid"}},
            {"entity_code": "uranium", "label_ru": "Уран", "label_en": "Uranium", "desc_ru": "Радиоактивный элемент, топливо для АЭС", "state": {"symbol": "U", "name": "Uranium", "atomic_number": 92, "atomic_mass": 238.029, "group": 0, "period": 7, "category": "Actinide"}}
        ]
    },
    "animal": {
        "model": "science",
        "template_code": "tpl_animal",
        "template_name": "Шаблон: Животное",
        "schema": {
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "species": {"type": "string"},
                "class": {"type": "string"},
                "habitat": {"type": "string"},
                "diet": {"type": "string"},
                "lifespan_years": {"type": "integer"}
            }
        },
        "records": [
            {"entity_code": "african_elephant", "label_ru": "Африканский слон", "label_en": "African Elephant", "desc_ru": "Крупнейшее наземное животное", "state": {"name": "African Elephant", "species": "Loxodonta africana", "class": "Mammalia", "habitat": "Savanna", "diet": "Herbivore", "lifespan_years": 70}},
            {"entity_code": "blue_whale", "label_ru": "Синий кит", "label_en": "Blue Whale", "desc_ru": "Крупнейшее животное на планете", "state": {"name": "Blue Whale", "species": "Balaenoptera musculus", "class": "Mammalia", "habitat": "Ocean", "diet": "Krill", "lifespan_years": 90}},
            {"entity_code": "golden_eagle", "label_ru": "Орёл", "label_en": "Golden Eagle", "desc_ru": "Могучий хищник небес", "state": {"name": "Golden Eagle", "species": "Aquila chrysaetos", "class": "Aves", "habitat": "Mountains", "diet": "Carnivore", "lifespan_years": 30}},
            {"entity_code": "gray_wolf", "label_ru": "Серый волк", "label_en": "Gray Wolf", "desc_ru": "Социальный хищник", "state": {"name": "Gray Wolf", "species": "Canis lupus", "class": "Mammalia", "habitat": "Forest", "diet": "Carnivore", "lifespan_years": 8}},
            {"entity_code": "polar_bear", "label_ru": "Белый медведь", "label_en": "Polar Bear", "desc_ru": "Хищник Арктики", "state": {"name": "Polar Bear", "species": "Ursus maritimus", "class": "Mammalia", "habitat": "Arctic", "diet": "Carnivore", "lifespan_years": 25}},
            {"entity_code": "bald_eagle", "label_ru": "Орлан", "label_en": "Bald Eagle", "desc_ru": "Символ США", "state": {"name": "Bald Eagle", "species": "Haliaeetus leucocephalus", "class": "Aves", "habitat": "Coastal", "diet": "Carnivore", "lifespan_years": 20}},
            {"entity_code": "snow_leopard", "label_ru": "Снежный барс", "label_en": "Snow Leopard", "desc_ru": "Редкий горный хищник", "state": {"name": "Snow Leopard", "species": "Panthera uncia", "class": "Mammalia", "habitat": "Mountains", "diet": "Carnivore", "lifespan_years": 15}},
            {"entity_code": "red_panda", "label_ru": "Красная панда", "label_en": "Red Panda", "desc_ru": "Милое древесное животное", "state": {"name": "Red Panda", "species": "Ailurus fulgens", "class": "Mammalia", "habitat": "Forest", "diet": "Herbivore", "lifespan_years": 12}},
            {"entity_code": "bengal_tiger", "label_ru": "Бенгальский тигр", "label_en": "Bengal Tiger", "desc_ru": "Крупнейший дикий кот", "state": {"name": "Bengal Tiger", "species": "Panthera tigris tigris", "class": "Mammalia", "habitat": "Jungle", "diet": "Carnivore", "lifespan_years": 15}},
            {"entity_code": "emperor_penguin", "label_ru": "Императорский пингвин", "label_en": "Emperor Penguin", "desc_ru": "Самый крупный пингвин", "state": {"name": "Emperor Penguin", "species": "Aptenodytes forsteri", "class": "Aves", "habitat": "Antarctic", "diet": "Piscivore", "lifespan_years": 20}}
        ]
    },
    "plant": {
        "model": "science",
        "template_code": "tpl_plant",
        "template_name": "Шаблон: Растение",
        "schema": {
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "species": {"type": "string"},
                "family": {"type": "string"},
                "habitat": {"type": "string"},
                "height_cm": {"type": "integer"}
            }
        },
        "records": [
            {"entity_code": "sequoia", "label_ru": "Секвойя", "label_en": "Giant Sequoia", "desc_ru": "Самое высокое дерево на планете", "state": {"name": "Giant Sequoia", "species": "Sequoiadendron giganteum", "family": "Cupressaceae", "habitat": "California mountains", "height_cm": 84000}},
            {"entity_code": "baobab", "label_ru": "Баобаб", "label_en": "Baobab", "desc_ru": "Дерево жизни Африки", "state": {"name": "Baobab", "species": "Adansonia digitata", "family": "Malvaceae", "habitat": "African savanna", "height_cm": 2500}},
            {"entity_code": "giant_kelp", "label_ru": "Гигантская ламинария", "label_en": "Giant Kelp", "desc_ru": "Самая быстрорастущая водоросль", "state": {"name": "Giant Kelp", "species": "Macrocystis pyrifera", "family": "Laminariaceae", "habitat": "Ocean", "height_cm": 4500}},
            {"entity_code": "joshua_tree", "label_ru": "Дерево Иисуса", "label_en": "Joshua Tree", "desc_ru": "Символ пустыни Мохаве", "state": {"name": "Joshua Tree", "species": "Yucca brevifolia", "family": "Asparagaceae", "habitat": "Desert", "height_cm": 1500}},
            {"entity_code": "white_oak", "label_ru": "Белый дуб", "label_en": "White Oak", "desc_ru": "Долгожитель среди деревьев", "state": {"name": "White Oak", "species": "Quercus alba", "family": "Fagaceae", "habitat": "Eastern North America", "height_cm": 3000}},
            {"entity_code": "bamboo", "label_ru": "Бамбук", "label_en": "Bamboo", "desc_ru": "Самая быстрорастущая трава", "state": {"name": "Bamboo", "species": "Bambusoideae", "family": "Poaceae", "habitat": "Asia", "height_cm": 3000}},
            {"entity_code": "giant_sunflower", "label_ru": "Подсолнечник", "label_en": "Sunflower", "desc_ru": "Солнечный цветок", "state": {"name": "Sunflower", "species": "Helianthus annuus", "family": "Asteraceae", "habitat": "Fields", "height_cm": 300}},
            {"entity_code": "royal_palm", "label_ru": "Королевская пальма", "label_en": "Royal Palm", "desc_ru": "Экзотическая пальма", "state": {"name": "Royal Palm", "species": "Roystonea regia", "family": "Arecaceae", "habitat": "Tropics", "height_cm": 2500}},
            {"entity_code": "ginkgo", "label_ru": "Гинкго", "label_en": "Ginkgo", "desc_ru": "Живое ископаемое, 270 млн лет", "state": {"name": "Ginkgo", "species": "Ginkgo biloba", "family": "Ginkgoaceae", "habitat": "China", "height_cm": 3500}},
            {"entity_code": "venus_flytrap", "label_ru": "Венерина мухоловка", "label_en": "Venus Flytrap", "desc_ru": "Хищное растение", "state": {"name": "Venus Flytrap", "species": "Dionaea muscipula", "family": "Droseraceae", "habitat": "Wetlands", "height_cm": 15}}
        ]
    },
    "album": {
        "model": "music",
        "template_code": "tpl_album",
        "template_name": "Шаблон: Альбом",
        "schema": {
            "type": "object",
            "properties": {
                "title": {"type": "string"},
                "artist": {"type": "string"},
                "year": {"type": "integer"},
                "tracks": {"type": "integer"},
                "genre": {"type": "string"},
                "label": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "abbey_road", "label_ru": "Abbey Road", "label_en": "Abbey Road", "desc_ru": "Последний записанный альбом Beatles", "state": {"title": "Abbey Road", "artist": "The Beatles", "year": 1969, "tracks": 17, "genre": "Rock", "label": "Apple Records"}},
            {"entity_code": "dark_side_moon", "label_ru": "The Dark Side of the Moon", "label_en": "The Dark Side of the Moon", "desc_ru": "Один из самых продаваемых альбомов", "state": {"title": "The Dark Side of the Moon", "artist": "Pink Floyd", "year": 1973, "tracks": 10, "genre": "Progressive Rock", "label": "Harvest"}},
            {"entity_code": "thriller_album", "label_ru": "Thriller", "label_en": "Thriller", "desc_ru": "Самый продаваемый альбом в истории", "state": {"title": "Thriller", "artist": "Michael Jackson", "year": 1982, "tracks": 9, "genre": "Pop", "label": "Epic"}},
            {"entity_code": "nevermind", "label_ru": "Nevermind", "label_en": "Nevermind", "desc_ru": "Альбом, изменивший рок-музыку", "state": {"title": "Nevermind", "artist": "Nirvana", "year": 1991, "tracks": 12, "genre": "Grunge", "label": "DGC"}},
            {"entity_code": "led_zeppelin_iv", "label_ru": "Led Zeppelin IV", "label_en": "Led Zeppelin IV", "desc_ru": "Альбом со Stairway to Heaven", "state": {"title": "Led Zeppelin IV", "artist": "Led Zeppelin", "year": 1971, "tracks": 8, "genre": "Rock", "label": "Atlantic"}},
            {"entity_code": "hotel_california_album", "label_ru": "Hotel California", "label_en": "Hotel California", "desc_ru": "Культовый альбом Eagles", "state": {"title": "Hotel California", "artist": "Eagles", "year": 1977, "tracks": 9, "genre": "Rock", "label": "Asylum"}},
            {"entity_code": "the_wall", "label_ru": "The Wall", "label_en": "The Wall", "desc_ru": "Рок-опера Pink Floyd", "state": {"title": "The Wall", "artist": "Pink Floyd", "year": 1979, "tracks": 26, "genre": "Progressive Rock", "label": "Harvest"}},
            {"entity_code": "ok_computer", "label_ru": "OK Computer", "label_en": "OK Computer", "desc_ru": "Шедевр Radiohead", "state": {"title": "OK Computer", "artist": "Radiohead", "year": 1997, "tracks": 12, "genre": "Alternative Rock", "label": "Parlophone"}},
            {"entity_code": "rumours", "label_ru": "Rumours", "label_en": "Rumours", "desc_ru": "Самый успешный альбом Fleetwood Mac", "state": {"title": "Rumours", "artist": "Fleetwood Mac", "year": 1977, "tracks": 11, "genre": "Rock", "label": "Warner Bros."}},
            {"entity_code": "back_in_black", "label_ru": "Back in Black", "label_en": "Back in Black", "desc_ru": "Трибьют Bon Scott от AC/DC", "state": {"title": "Back in Black", "artist": "AC/DC", "year": 1980, "tracks": 10, "genre": "Hard Rock", "label": "Atlantic"}}
        ]
    },
    "concept": {
        "model": "default",
        "template_code": "tpl_concept",
        "template_name": "Шаблон: Концепция",
        "schema": {
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "definition": {"type": "string"},
                "domain": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "artificial_intelligence", "label_ru": "Искусственный интеллект", "label_en": "Artificial Intelligence", "desc_ru": "Раздел информатики, создающий интеллектуальные системы", "state": {"name": "Artificial Intelligence", "definition": "Field of computer science creating intelligent machines", "domain": "Technology"}},
            {"entity_code": "quantum_computing", "label_ru": "Квантовые вычисления", "label_en": "Quantum Computing", "desc_ru": "Вычисления на основе квантовых механических явлений", "state": {"name": "Quantum Computing", "definition": "Computing using quantum mechanical phenomena", "domain": "Technology"}},
            {"entity_code": "blockchain", "label_ru": "Блокчейн", "label_en": "Blockchain", "desc_ru": "Распределённый реестр данных", "state": {"name": "Blockchain", "definition": "Distributed ledger technology", "domain": "Technology"}},
            {"entity_code": "existentialism", "label_ru": "Экзистенциализм", "label_en": "Existentialism", "desc_ru": "Философское течение о свободе и ответственности", "state": {"name": "Existentialism", "definition": "Philosophy focusing on individual freedom and responsibility", "domain": "Philosophy"}},
            {"entity_code": "democracy", "label_ru": "Демократия", "label_en": "Democracy", "desc_ru": "Форма правления, основанная на воле народа", "state": {"name": "Democracy", "definition": "System of government by the people", "domain": "Politics"}},
            {"entity_code": "globalization", "label_ru": "Глобализация", "label_en": "Globalization", "desc_ru": "Процесс усиления мировой взаимозависимости", "state": {"name": "Globalization", "definition": "Process of increasing world interconnectedness", "domain": "Economics"}},
            {"entity_code": "renaissance", "label_ru": "Ренессанс", "label_en": "Renaissance", "desc_ru": "Эпоха культурного возрождения в Европе", "state": {"name": "Renaissance", "definition": "Cultural rebirth in Europe", "domain": "History"}},
            {"entity_code": "climate_change", "label_ru": "Изменение климата", "label_en": "Climate Change", "desc_ru": "Глобальное изменение климатической системы Земли", "state": {"name": "Climate Change", "definition": "Long-term change in Earth's climate system", "domain": "Science"}},
            {"entity_code": "surrealism", "label_ru": "Сюрреализм", "label_en": "Surrealism", "desc_ru": "Художественное направление, основанное на бессознательном", "state": {"name": "Surrealism", "definition": "Art movement based on the unconscious mind", "domain": "Art"}},
            {"entity_code": "stoicism", "label_ru": "Стоицизм", "label_en": "Stoicism", "desc_ru": "Древнегреческая философия самоконтроля", "state": {"name": "Stoicism", "definition": "Ancient Greek philosophy of self-control", "domain": "Philosophy"}}
        ]
    },
    "genre": {
        "model": "default",
        "template_code": "tpl_genre",
        "template_name": "Шаблон: Жанр",
        "schema": {
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "category": {"type": "string"},
                "origin_period": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "sci_fi", "label_ru": "Научная фантастика", "label_en": "Science Fiction", "desc_ru": "Жанр, основанный на научных достижениях", "state": {"name": "Science Fiction", "category": "Literature/Cinema", "origin_period": "19th century"}},
            {"entity_code": "noir", "label_ru": "Нуар", "label_en": "Film Noir", "desc_ru": "Стиль кинематографа с мрачной атмосферой", "state": {"name": "Film Noir", "category": "Cinema", "origin_period": "1940s"}},
            {"entity_code": "progressive_rock", "label_ru": "Прогрессивный рок", "label_en": "Progressive Rock", "desc_ru": "Сложная структура и длинные композиции", "state": {"name": "Progressive Rock", "category": "Music", "origin_period": "Late 1960s"}},
            {"entity_code": "grunge", "label_ru": "Гранж", "label_en": "Grunge", "desc_ru": "Поджанр альтернативного рока", "state": {"name": "Grunge", "category": "Music", "origin_period": "Mid-1980s"}},
            {"entity_code": "dystopia_genre", "label_ru": "Антиутопия", "label_en": "Dystopia", "desc_ru": "Жанр о мрачном будущем", "state": {"name": "Dystopia", "category": "Literature", "origin_period": "20th century"}},
            {"entity_code": "reggae", "label_ru": "Регги", "label_en": "Reggae", "desc_ru": "Ямайский музыкальный жанр", "state": {"name": "Reggae", "category": "Music", "origin_period": "Late 1960s"}},
            {"entity_code": "hard_rock", "label_ru": "Хард-рок", "label_en": "Hard Rock", "desc_ru": "Энергичная гитарная музыка", "state": {"name": "Hard Rock", "category": "Music", "origin_period": "Mid-1960s"}},
            {"entity_code": "impressionism", "label_ru": "Импрессионизм", "label_en": "Impressionism", "desc_ru": "Художественное направление в живописи", "state": {"name": "Impressionism", "category": "Visual Art", "origin_period": "1860s"}},
            {"entity_code": "baroque", "label_ru": "Барокко", "label_en": "Baroque", "desc_ru": "Стиль в искусстве XVII века", "state": {"name": "Baroque", "category": "Art/Music", "origin_period": "17th century"}},
            {"entity_code": "cyberpunk", "label_ru": "Киберпанк", "label_en": "Cyberpunk", "desc_ru": "Поджанр научной фантастики", "state": {"name": "Cyberpunk", "category": "Literature/Cinema", "origin_period": "1980s"}}
        ]
    },
    "phenomenon": {
        "model": "science",
        "template_code": "tpl_phenomenon",
        "template_name": "Шаблон: Явление",
        "schema": {
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "description": {"type": "string"},
                "category": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "aurora_borealis", "label_ru": "Северное сияние", "label_en": "Aurora Borealis", "desc_ru": "Световое явление в полярных широтах", "state": {"name": "Aurora Borealis", "description": "Light display in polar regions caused by charged particles", "category": "Natural"}},
            {"entity_code": "gravity", "label_ru": "Гравитация", "label_en": "Gravity", "desc_ru": "Сила притяжения между телами", "state": {"name": "Gravity", "description": "Force of attraction between objects with mass", "category": "Physical"}},
            {"entity_code": "photosynthesis", "label_ru": "Фотосинтез", "label_en": "Photosynthesis", "desc_ru": "Процесс образования органических веществ из CO2 и воды", "state": {"name": "Photosynthesis", "description": "Process converting light energy to chemical energy in plants", "category": "Biological"}},
            {"entity_code": "evolution", "label_ru": "Эволюция", "label_en": "Evolution", "desc_ru": "Процесс изменения организмов во времени", "state": {"name": "Evolution", "description": "Process of change in living organisms over generations", "category": "Biological"}},
            {"entity_code": "quantum_entanglement", "label_ru": "Квантовая запутанность", "label_en": "Quantum Entanglement", "desc_ru": "Квантовое явление корреляции частиц", "state": {"name": "Quantum Entanglement", "description": "Quantum phenomenon where particles become correlated", "category": "Physical"}},
            {"entity_code": "black_hole", "label_ru": "Чёрная дыра", "label_en": "Black Hole", "desc_ru": "Объект с гравитацией, не выпускающей свет", "state": {"name": "Black Hole", "description": "Region of spacetime with extreme gravitational pull", "category": "Astronomical"}},
            {"entity_code": "tornado", "label_ru": "Торнадо", "label_en": "Tornado", "desc_ru": "Мощный вращающийся вихрь", "state": {"name": "Tornado", "description": "Violently rotating column of air", "category": "Meteorological"}},
            {"entity_code": "continental_drift", "label_ru": "Континентальный дрейф", "label_en": "Continental Drift", "desc_ru": "Движение материков по поверхности Земли", "state": {"name": "Continental Drift", "description": "Movement of Earth's continents over geological time", "category": "Geological"}},
            {"entity_code": "photosynthesis_process", "label_ru": "Мечтательность", "label_en": "Dreaminess", "desc_ru": "Состояние увлечённости мечтами", "state": {"name": "Dreaminess", "description": "State of being lost in pleasant thoughts", "category": "Psychological"}},
            {"entity_code": "aurora_australis", "label_ru": "Южное сияние", "label_en": "Aurora Australis", "desc_ru": "Световое явление в южных широтах", "state": {"name": "Aurora Australis", "description": "Southern hemisphere light display", "category": "Natural"}}
        ]
    },
    "period": {
        "model": "history",
        "template_code": "tpl_period",
        "template_name": "Шаблон: Эпоха",
        "schema": {
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "start_year": {"type": "integer"},
                "end_year": {"type": "integer"},
                "region": {"type": "string"},
                "significance": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "ancient_rome", "label_ru": "Древний Рим", "label_en": "Ancient Rome", "desc_ru": "Цивилизация, оказавшая огромное влияние на мир", "state": {"name": "Ancient Rome", "start_year": -753, "end_year": 476, "region": "Mediterranean", "significance": "Foundation of Western civilization"}},
            {"entity_code": "middle_ages", "label_ru": "Средние века", "label_en": "Middle Ages", "desc_ru": "Эпоха феодализма в Европе", "state": {"name": "Middle Ages", "start_year": 500, "end_year": 1500, "region": "Europe", "significance": "Feudalism and religious influence"}},
            {"entity_code": "industrial_revolution", "label_ru": "Промышленная революция", "label_en": "Industrial Revolution", "desc_ru": "Переход от ручного труда к машинному", "state": {"name": "Industrial Revolution", "start_year": 1760, "end_year": 1840, "region": "Worldwide", "significance": "Transformation of manufacturing"}},
            {"entity_code": "cold_war", "label_ru": "Холодная война", "label_en": "Cold War", "desc_ru": "Геополитическое противостояние USA и USSR", "state": {"name": "Cold War", "start_year": 1947, "end_year": 1991, "region": "Worldwide", "significance": "Bipolar world order"}},
            {"entity_code": "renaissance_period", "label_ru": "Эпоха Возрождения", "label_en": "Renaissance Period", "desc_ru": "Культурное возрождение в Европе", "state": {"name": "Renaissance", "start_year": 1300, "end_year": 1600, "region": "Europe", "significance": "Cultural and intellectual rebirth"}},
            {"entity_code": "age_of_enlightenment", "label_ru": "Эпоха Просвещения", "label_en": "Age of Enlightenment", "desc_ru": "Эпоха распространения научных знаний", "state": {"name": "Age of Enlightenment", "start_year": 1685, "end_year": 1815, "region": "Europe", "significance": "Rise of reason and science"}},
            {"entity_code": "digital_age", "label_ru": "Цифровая эра", "label_en": "Digital Age", "desc_ru": "Эпоха компьютеров и интернета", "state": {"name": "Digital Age", "start_year": 1970, "end_year": 2026, "region": "Worldwide", "significance": "Information technology revolution"}},
            {"entity_code": "space_age", "label_ru": "Эра освоения космоса", "label_en": "Space Age", "desc_ru": "Эпоха космических полётов", "state": {"name": "Space Age", "start_year": 1957, "end_year": 2026, "region": "Worldwide", "significance": "Human space exploration"}},
            {"entity_code": "world_war_2", "label_ru": "Вторая мировая война", "label_en": "World War II", "desc_ru": "Крупнейший военный конфликт в истории", "state": {"name": "World War II", "start_year": 1939, "end_year": 1945, "region": "Worldwide", "significance": "Largest conflict in human history"}},
            {"entity_code": "victorian_era", "label_ru": "Викторианская эпоха", "label_en": "Victorian Era", "desc_ru": "Эпоха правления королевы Виктории", "state": {"name": "Victorian Era", "start_year": 1837, "end_year": 1901, "region": "British Empire", "significance": "Peak of British Empire"}}
        ]
    },
    "digital_file": {
        "model": "default",
        "template_code": "tpl_file",
        "template_name": "Шаблон: Файл",
        "schema": {
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "format": {"type": "string"},
                "size_kb": {"type": "number"},
                "category": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "readme_md", "label_ru": "README.md", "label_en": "README.md", "desc_ru": "Документация проекта", "state": {"name": "README.md", "format": "Markdown", "size_kb": 15.3, "category": "Documentation"}},
            {"entity_code": "schema_sql", "label_ru": "schema.sql", "label_en": "schema.sql", "desc_ru": "SQL-схема базы данных", "state": {"name": "schema.sql", "format": "SQL", "size_kb": 48.7, "category": "Database"}},
            {"entity_code": "config_yaml", "label_ru": "config.yaml", "label_en": "config.yaml", "desc_ru": "Конфигурация приложения", "state": {"name": "config.yaml", "format": "YAML", "size_kb": 2.1, "category": "Configuration"}},
            {"entity_code": "docker_compose", "label_ru": "docker-compose.yml", "label_en": "docker-compose.yml", "desc_ru": "Определение Docker-сервисов", "state": {"name": "docker-compose.yml", "format": "YAML", "size_kb": 1.8, "category": "Infrastructure"}},
            {"entity_code": "main_py", "label_ru": "main.py", "label_en": "main.py", "desc_ru": "Главный файл приложения", "state": {"name": "main.py", "format": "Python", "size_kb": 12.5, "category": "Source Code"}},
            {"entity_code": "models_py", "label_ru": "models.py", "label_en": "models.py", "desc_ru": "ORM-модели данных", "state": {"name": "models.py", "format": "Python", "size_kb": 8.2, "category": "Source Code"}},
            {"entity_code": "requirements_txt", "label_ru": "requirements.txt", "label_en": "requirements.txt", "desc_ru": "Список зависимостей Python", "state": {"name": "requirements.txt", "format": "Text", "size_kb": 0.5, "category": "Configuration"}},
            {"entity_code": "dockerfile", "label_ru": "Dockerfile", "label_en": "Dockerfile", "desc_ru": "Инструкция сборки Docker-образа", "state": {"name": "Dockerfile", "format": "Docker", "size_kb": 0.8, "category": "Infrastructure"}},
            {"entity_code": "index_html", "label_ru": "index.html", "label_en": "index.html", "desc_ru": "Главная страница веб-интерфейса", "state": {"name": "index.html", "format": "HTML", "size_kb": 5.4, "category": "Frontend"}},
            {"entity_code": "style_css", "label_ru": "style.css", "label_en": "style.css", "desc_ru": "Стили веб-интерфейса", "state": {"name": "style.css", "format": "CSS", "size_kb": 3.7, "category": "Frontend"}}
        ]
    },
    "movement": {
        "model": "default",
        "template_code": "tpl_movement",
        "template_name": "Шаблон: Движение",
        "schema": {
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "period": {"type": "string"},
                "origin": {"type": "string"},
                "description": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "beat_generation", "label_ru": "Поколение битников", "label_en": "Beat Generation", "desc_ru": "Литературное движение 1950-х", "state": {"name": "Beat Generation", "period": "1950s", "origin": "USA", "description": "Rebellious literary movement"}},
            {"entity_code": "romanticism", "label_ru": "Романтизм", "label_en": "Romanticism", "desc_ru": "Художественное направление конца XVIII века", "state": {"name": "Romanticism", "period": "Late 18th century", "origin": "Europe", "description": "Emphasis on emotion and individualism"}},
            {"entity_code": "cubism", "label_ru": "Кубизм", "label_en": "Cubism", "desc_ru": "Революционное направление в живописи", "state": {"name": "Cubism", "period": "1907-1920s", "origin": "France", "description": "Geometric abstraction in art"}},
            {"entity_code": "punk_rock", "label_ru": "Панк-рок", "label_en": "Punk Rock", "desc_ru": "Протестная музыка 1970-х", "state": {"name": "Punk Rock", "period": "1970s", "origin": "UK/USA", "description": "Raw, energetic protest music"}},
            {"entity_code": "impressionism_movement", "label_ru": "Импрессионизм", "label_en": "Impressionism Movement", "desc_ru": "Революция в живописи XIX века", "state": {"name": "Impressionism", "period": "1860s-1880s", "origin": "France", "description": "Capturing light and movement"}},
            {"entity_code": "existentialism_movement", "label_ru": "Экзистенциализм", "label_en": "Existentialism Movement", "desc_ru": "Философское движение XX века", "state": {"name": "Existentialism", "period": "1930s-1960s", "origin": "Europe", "description": "Focus on individual existence and freedom"}},
            {"entity_code": "minimalism", "label_ru": "Минимализм", "label_en": "Minimalism", "desc_ru": "Музыкальное и художественное направление", "state": {"name": "Minimalism", "period": "1960s-present", "origin": "USA", "description": "Reduction to essential elements"}},
            {"entity_code": "hippie_movement", "label_ru": "Движение хиппи", "label_en": "Hippie Movement", "desc_ru": "Контркультура 1960-х", "state": {"name": "Hippie Movement", "period": "1960s-1970s", "origin": "USA", "description": "Peace, love, and counterculture"}},
            {"entity_code": "surrealism_movement", "label_ru": "Сюрреализм", "label_en": "Surrealism Movement", "desc_ru": "Художественное движение, основанное на подсознании", "state": {"name": "Surrealism", "period": "1920s-1950s", "origin": "France", "description": "Art from the unconscious mind"}},
            {"entity_code": "renaissance_movement", "label_ru": "Движение Возрождения", "label_en": "Renaissance Movement", "desc_ru": "Возрождение искусства и науки", "state": {"name": "Renaissance Movement", "period": "14th-17th century", "origin": "Italy", "description": "Rebirth of art and learning"}}
        ]
    },
    "classifier": {
        "model": "default",
        "template_code": "tpl_classifier",
        "template_name": "Шаблон: Классификатор",
        "schema": {
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "code": {"type": "string"},
                "version": {"type": "string"},
                "description": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "dewey_decimal", "label_ru": "Десятичная классификация Дьюи", "label_en": "Dewey Decimal Classification", "desc_ru": "Система классификации книг", "state": {"name": "Dewey Decimal Classification", "code": "DDC", "version": "23", "description": "Library book classification system"}},
            {"entity_code": "iso_3166", "label_ru": "ISO 3166", "label_en": "ISO 3166", "desc_ru": "Коды стран", "state": {"name": "ISO 3166", "code": "ISO-3166", "version": "2023", "description": "Country codes standard"}},
            {"entity_code": "un_class", "label_ru": "Классификация ООН", "label_en": "UN Classification", "desc_ru": "Классификация экономической деятельности", "state": {"name": "UN Classification", "code": "ISIC", "version": "4", "description": "International economic activity classification"}},
            {"entity_code": "iso_639", "label_ru": "ISO 639", "label_en": "ISO 639", "desc_ru": "Коды языков", "state": {"name": "ISO 639", "code": "ISO-639", "version": "2023", "description": "Language codes standard"}},
            {"entity_code": "periodic_table", "label_ru": "Периодическая таблица", "label_en": "Periodic Table", "desc_ru": "Классификация химических элементов", "state": {"name": "Periodic Table", "code": "IUPAC", "version": "2024", "description": "Chemical element classification"}},
            {"entity_code": "icd10", "label_ru": "МКБ-10", "label_en": "ICD-10", "desc_ru": "Международная классификация болезней", "state": {"name": "ICD-10", "code": "ICD-10", "version": "10", "description": "Disease classification"}},
            {"entity_code": "linnaeus", "label_ru": "Классификация Линнея", "label_en": "Linnaean Classification", "desc_ru": "Система классификации живых организмов", "state": {"name": "Linnaean Classification", "code": "TAXONOMY", "version": "10th", "description": "Biological taxonomy system"}},
            {"entity_code": "bib", "label_ru": "Библиотечная классификация", "label_en": "Library Classification", "desc_ru": "Система ББК", "state": {"name": "Library Classification", "code": "BBK", "version": "2023", "description": "Russian library classification"}},
            {"entity_code": "nace", "label_ru": "NACE", "label_en": "NACE", "desc_ru": "Европейская классификация экономической деятельности", "state": {"name": "NACE", "code": "NACE", "version": "2.1", "description": "European economic activity classification"}},
            {"entity_code": "atc", "label_ru": "ATC", "label_en": "ATC", "desc_ru": "Анатомо-терапевтическо-химическая классификация", "state": {"name": "ATC", "code": "ATC", "version": "2024", "description": "Drug classification system"}}
        ]
    },
    "physical_item": {
        "model": "default",
        "template_code": "tpl_item",
        "template_name": "Шаблон: Предмет",
        "schema": {
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "material": {"type": "string"},
                "origin": {"type": "string"},
                "year_made": {"type": "integer"}
            }
        },
        "records": [
            {"entity_code": "rosetta_stone", "label_ru": "Розеттский камень", "label_en": "Rosetta Stone", "desc_ru": "Ключ к расшифровке египетских иероглифов", "state": {"name": "Rosetta Stone", "material": "Granodiorite", "origin": "Egypt", "year_made": -196}},
            {"entity_code": "mona_lisa", "label_ru": "Мона Лиза", "label_en": "Mona Lisa", "desc_ru": "Знаменитая картина Леонардо да Винчи", "state": {"name": "Mona Lisa", "material": "Oil on poplar", "origin": "Italy", "year_made": 1503}},
            {"entity_code": "great_wall", "label_ru": "Великая Китайская стена", "label_en": "Great Wall of China", "desc_ru": "Древнее укрепление", "state": {"name": "Great Wall", "material": "Stone, brick", "origin": "China", "year_made": -700}},
            {"entity_code": "pyramid_giza", "label_ru": "Пирамида Хеопса", "label_en": "Great Pyramid of Giza", "desc_ru": "Единственное из Семи чудес света", "state": {"name": "Great Pyramid", "material": "Limestone", "origin": "Egypt", "year_made": -2560}},
            {"entity_code": "colosseum", "label_ru": "Колизей", "label_en": "Colosseum", "desc_ru": "Древнеримский амфитеатр", "state": {"name": "Colosseum", "material": "Travertine", "origin": "Italy", "year_made": 80}},
            {"entity_code": "stonehenge", "label_ru": "Стоунхендж", "label_en": "Stonehenge", "desc_ru": "Загадочный мегалитический памятник", "state": {"name": "Stonehenge", "material": "Sarsen stone", "origin": "UK", "year_made": -3000}},
            {"entity_code": "taj_mahal", "label_ru": "Тадж-Махал", "label_en": "Taj Mahal", "desc_ru": "Мавзолей в Агре", "state": {"name": "Taj Mahal", "material": "White marble", "origin": "India", "year_made": 1653}},
            {"entity_code": "eiffel_tower", "label_ru": "Эйфелева башня", "label_en": "Eiffel Tower", "desc_ru": "Символ Парижа", "state": {"name": "Eiffel Tower", "material": "Iron", "origin": "France", "year_made": 1889}},
            {"entity_code": "liberty_statue", "label_ru": "Статуя Свободы", "label_en": "Statue of Liberty", "desc_ru": "Символ свободы Америки", "state": {"name": "Statue of Liberty", "material": "Copper", "origin": "USA", "year_made": 1886}},
            {"entity_code": "parthenon", "label_ru": "Парфенон", "label_en": "Parthenon", "desc_ru": "Древнегреческий храм", "state": {"name": "Parthenon", "material": "Marble", "origin": "Greece", "year_made": -438}}
        ]
    },
    "photo": {
        "model": "default",
        "template_code": "tpl_photo",
        "template_name": "Шаблон: Фото",
        "schema": {
            "type": "object",
            "properties": {
                "title": {"type": "string"},
                "photographer": {"type": "string"},
                "year": {"type": "integer"},
                "subject": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "afghan_girl", "label_ru": "Афганская девочка", "label_en": "Afghan Girl", "desc_ru": "Знаменитый портрет Стива Маккарри", "state": {"title": "Afghan Girl", "photographer": "Steve McCurry", "year": 1984, "subject": "Portrait"}},
            {"entity_code": "earthrise", "label_ru": "Восход Земли", "label_en": "Earthrise", "desc_ru": "Фото Земли с Луны", "state": {"title": "Earthrise", "photographer": "William Anders", "year": 1968, "subject": "Space"}},
            {"entity_code": "v_j_day", "label_ru": "V-J Day in Times Square", "label_en": "V-J Day in Times Square", "desc_ru": "Знаменитый поцелуй на Таймс-сквер", "state": {"title": "V-J Day", "photographer": "Alfred Eisenstaedt", "year": 1945, "subject": "Historical"}},
            {"entity_code": "pale_blue_dot", "label_ru": "Бледно-голубая точка", "label_en": "Pale Blue Dot", "desc_ru": "Фото Земли с расстояния 6 млрд км", "state": {"title": "Pale Blue Dot", "photographer": "Voyager 1", "year": 1990, "subject": "Space"}},
            {"entity_code": "migrant_mother", "label_ru": "Мать-мигрантка", "label_en": "Migrant Mother", "desc_ru": "Иконическое фото Великой депрессии", "state": {"title": "Migrant Mother", "photographer": "Dorothea Lange", "year": 1936, "subject": "Social"}},
            {"entity_code": "lunch_atop_skyscraper", "label_ru": "Обед на небоскрёбе", "label_en": "Lunch atop a Skyscraper", "desc_ru": "Рабочие на балке над Нью-Йорком", "state": {"title": "Lunch atop a Skyscraper", "photographer": "Unknown", "year": 1932, "subject": "Construction"}},
            {"entity_code": "flower_power", "label_ru": "Сила цветов", "label_en": "Flower Power", "desc_ru": "Девушка с цветком против солдат", "state": {"title": "Flower Power", "photographer": "Marc Riboud", "year": 1967, "subject": "Protest"}},
            {"entity_code": "the_kiss", "label_ru": "Поцелуй", "label_en": "The Kiss", "desc_ru": "Знаменитый поцелуй на Манхэттене", "state": {"title": "The Kiss", "photographer": "Alfred Eisenstaedt", "year": 1945, "subject": "Celebration"}},
            {"entity_code": "vulture_child", "label_ru": "Стратегия выживания", "label_en": "The Struggling Girl", "desc_ru": "Трагическое фото из Судана", "state": {"title": "Struggling Girl", "photographer": "Kevin Carter", "year": 1993, "subject": "Conflict"}},
            {"entity_code": "hubble_deep_field", "label_ru": "Глубокое поле Хаббла", "label_en": "Hubble Deep Field", "desc_ru": "Фото далёких галактик", "state": {"title": "Hubble Deep Field", "photographer": "Hubble Telescope", "year": 1995, "subject": "Space"}}
        ]
    },
    "article": {
        "model": "default",
        "template_code": "tpl_article",
        "template_name": "Шаблон: Статья",
        "schema": {
            "type": "object",
            "properties": {
                "title": {"type": "string"},
                "author": {"type": "string"},
                "published": {"type": "string"},
                "source": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "theory_relativity", "label_ru": "Теория относительности", "label_en": "Theory of Relativity", "desc_ru": "Статья Эйнштейна о специальной относительности", "state": {"title": "Zur Elektrodynamik bewegter Körper", "author": "Albert Einstein", "published": "1905-06-30", "source": "Annalen der Physik"}},
            {"entity_code": "origin_of_species", "label_ru": "Происхождение видов", "label_en": "On the Origin of Species", "desc_ru": "Трактат Дарвина об эволюции", "state": {"title": "On the Origin of Species", "author": "Charles Darwin", "published": "1859-11-24", "source": "John Murray"}},
            {"entity_code": "communist_manifesto", "label_ru": "Манифест коммунистической партии", "label_en": "Communist Manifesto", "desc_ru": "Политический трактат Маркса и Энгельса", "state": {"title": "Manifest der Kommunistischen Partei", "author": "Karl Marx & Friedrich Engels", "published": "1848-02-21", "source": "London"}},
            {"entity_code": "republic_plato", "label_ru": "Государство", "label_en": "The Republic", "desc_ru": "Философский диалог Платона", "state": {"title": "The Republic", "author": "Plato", "published": "-380", "source": "Athens"}},
            {"entity_code": "principia", "label_ru": "Начала", "label_en": "Principia Mathematica", "desc_ru": "Фундаментальный труд Ньютона", "state": {"title": "Philosophiæ Naturalis Principia Mathematica", "author": "Isaac Newton", "published": "1687-07-05", "source": "London"}},
            {"entity_code": "critique_pure_reason", "label_ru": "Критика чистого разума", "label_en": "Critique of Pure Reason", "desc_ru": "Главный труд Канта", "state": {"title": "Kritik der reinen Vernunft", "author": "Immanuel Kant", "published": "1781-01-01", "source": "Riga"}},
            {"entity_code": "wealth_of_nations", "label_ru": "Исследование о природе и богатстве народов", "label_en": "The Wealth of Nations", "desc_ru": "Основополагающий труд экономики", "state": {"title": "An Inquiry into the Nature and Causes of the Wealth of Nations", "author": "Adam Smith", "published": "1776-03-09", "source": "London"}},
            {"entity_code": "two_treatises", "label_ru": "Два трактата о правлении", "label_en": "Two Treatises of Government", "desc_ru": "Политический трактат Локка", "state": {"title": "Two Treatises of Government", "author": "John Locke", "published": "1689-01-01", "source": "London"}},
            {"entity_code": "the_wealth", "label_ru": "Богатство народов", "label_en": "The Wealth", "desc_ru": "Трактат о экономике", "state": {"title": "The Wealth", "author": "Adam Smith", "published": "1776-03-09", "source": "London"}},
            {"entity_code": "das_kapital", "label_ru": "Капитал", "label_en": "Das Kapital", "desc_ru": "Экономический трактат Маркса", "state": {"title": "Das Kapital", "author": "Karl Marx", "published": "1867-09-14", "source": "Hamburg"}}
        ]
    },
    "human": {
        "model": "default",
        "template_code": "tpl_person",
        "template_name": "Шаблон: Человек (персона)",
        "schema": {
            "type": "object",
            "properties": {
                "first_name": {"type": "string"},
                "last_name": {"type": "string"},
                "birth_date": {"type": "string"},
                "birth_place": {"type": "string"},
                "nationality": {"type": "string"},
                "occupation": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "albert_einstein", "label_ru": "Альберт Эйнштейн", "label_en": "Albert Einstein", "desc_ru": "Великий физик, создатель теории относительности", "state": {"first_name": "Albert", "last_name": "Einstein", "birth_date": "1879-03-14", "birth_place": "Ulm, Germany", "nationality": "German-Swiss", "occupation": "Physicist"}},
            {"entity_code": "leonardo_da_vinci", "label_ru": "Леонардо да Винчи", "label_en": "Leonardo da Vinci", "desc_ru": "Универсальный гений эпохи Возрождения", "state": {"first_name": "Leonardo", "last_name": "da Vinci", "birth_date": "1452-04-15", "birth_place": "Anchiano, Italy", "nationality": "Italian", "occupation": "Polymath"}},
            {"entity_code": "isaac_newton", "label_ru": "Исаак Ньютон", "label_en": "Isaac Newton", "desc_ru": "Основоположник классической механики", "state": {"first_name": "Isaac", "last_name": "Newton", "birth_date": "1643-01-04", "birth_place": "Woolsthorpe, UK", "nationality": "British", "occupation": "Physicist"}},
            {"entity_code": "nikola_tesla", "label_ru": "Никола Тесла", "label_en": "Nikola Tesla", "desc_ru": "Изобретатель и электроинженер", "state": {"first_name": "Nikola", "last_name": "Tesla", "birth_date": "1856-07-10", "birth_place": "Smiljan, Croatia", "nationality": "Serbian-American", "occupation": "Inventor"}},
            {"entity_code": "marie_curie", "label_ru": "Мария Кюри", "label_en": "Marie Curie", "desc_ru": "Первая женщина-лауреат Нобелевской премии", "state": {"first_name": "Marie", "last_name": "Curie", "birth_date": "1867-11-07", "birth_place": "Warsaw, Poland", "nationality": "Polish-French", "occupation": "Physicist"}},
            {"entity_code": "charles_darwin", "label_ru": "Чарльз Дарвин", "label_en": "Charles Darwin", "desc_ru": "Создатель теории эволюции", "state": {"first_name": "Charles", "last_name": "Darwin", "birth_date": "1809-02-12", "birth_place": "Shrewsbury, UK", "nationality": "British", "occupation": "Naturalist"}},
            {"entity_code": "plato", "label_ru": "Платон", "label_en": "Plato", "desc_ru": "Древнегреческий философ", "state": {"first_name": "Plato", "last_name": "", "birth_date": "-427", "birth_place": "Athens, Greece", "nationality": "Greek", "occupation": "Philosopher"}},
            {"entity_code": "shakespeare", "label_ru": "Уильям Шекспир", "label_en": "William Shakespeare", "desc_ru": "Величайший драматург мира", "state": {"first_name": "William", "last_name": "Shakespeare", "birth_date": "1564-04-26", "birth_place": "Stratford-upon-Avon, UK", "nationality": "British", "occupation": "Playwright"}},
            {"entity_code": "confucius", "label_ru": "Конфуций", "label_en": "Confucius", "desc_ru": "Великий китайский философ", "state": {"first_name": "Kong", "last_name": "Qiu", "birth_date": "-551", "birth_place": "Qufu, China", "nationality": "Chinese", "occupation": "Philosopher"}},
            {"entity_code": "mahatma_gandhi", "label_ru": "Махатма Ганди", "label_en": "Mahatma Gandhi", "desc_ru": "Лидер движения за независимость Индии", "state": {"first_name": "Mahatma", "last_name": "Gandhi", "birth_date": "1869-10-02", "birth_place": "Porbandar, India", "nationality": "Indian", "occupation": "Political leader"}}
        ]
    },
    "artist": {
        "model": "default",
        "template_code": "tpl_person",
        "template_name": "Шаблон: Человек (персона)",
        "schema": {
            "type": "object",
            "properties": {
                "first_name": {"type": "string"},
                "last_name": {"type": "string"},
                "birth_date": {"type": "string"},
                "birth_place": {"type": "string"},
                "nationality": {"type": "string"},
                "occupation": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "picasso", "label_ru": "Пабло Пикассо", "label_en": "Pablo Picasso", "desc_ru": "Испанский художник, основоположник кубизма", "state": {"first_name": "Pablo", "last_name": "Picasso", "birth_date": "1881-10-25", "birth_place": "Malaga, Spain", "nationality": "Spanish", "occupation": "Artist"}},
            {"entity_code": "van_gogh", "label_ru": "Винсент Ван Гог", "label_en": "Vincent van Gogh", "desc_ru": "Нидерландский постимпрессионист", "state": {"first_name": "Vincent", "last_name": "van Gogh", "birth_date": "1853-03-30", "birth_place": "Groot-Zundert, Netherlands", "nationality": "Dutch", "occupation": "Artist"}},
            {"entity_code": "monet", "label_ru": "Клод Моне", "label_en": "Claude Monet", "desc_ru": "Основатель импрессионизма", "state": {"first_name": "Claude", "last_name": "Monet", "birth_date": "1840-11-14", "birth_place": "Paris, France", "nationality": "French", "occupation": "Artist"}},
            {"entity_code": "michelangelo", "label_ru": "Микеланджело", "label_en": "Michelangelo", "desc_ru": "Итальянский скульптор и живописец", "state": {"first_name": "Michelangelo", "last_name": "di Lodovico Buonarroti Simoni", "birth_date": "1475-03-06", "birth_place": "Caprese, Italy", "nationality": "Italian", "occupation": "Artist"}},
            {"entity_code": "rembrandt", "label_ru": "Рембрандт", "label_en": "Rembrandt", "desc_ru": "Великий нидерландский живописец", "state": {"first_name": "Rembrandt", "last_name": "van Rijn", "birth_date": "1606-07-15", "birth_place": "Leiden, Netherlands", "nationality": "Dutch", "occupation": "Artist"}},
            {"entity_code": "salvador_dali", "label_ru": "Сальвадор Дали", "label_en": "Salvador Dali", "desc_ru": "Испанский сюрреалист", "state": {"first_name": "Salvador", "last_name": "Dali", "birth_date": "1904-05-11", "birth_place": "Figueres, Spain", "nationality": "Spanish", "occupation": "Artist"}},
            {"entity_code": "andy_warhol", "label_ru": "Энди Уорхол", "label_en": "Andy Warhol", "desc_ru": "Лидер поп-арта", "state": {"first_name": "Andy", "last_name": "Warhol", "birth_date": "1928-08-06", "birth_place": "Pittsburgh, USA", "nationality": "American", "occupation": "Artist"}},
            {"entity_code": "frida_kahlo", "label_ru": "Фрида Кало", "label_en": "Frida Kahlo", "desc_ru": "Мексиканская художница-сюрреалистка", "state": {"first_name": "Frida", "last_name": "Kahlo", "birth_date": "1907-07-06", "birth_place": "Mexico City, Mexico", "nationality": "Mexican", "occupation": "Artist"}},
            {"entity_code": "kandinsky", "label_ru": "Василий Кандинский", "label_en": "Wassily Kandinsky", "desc_ru": "Пионер абстрактного искусства", "state": {"first_name": "Wassily", "last_name": "Kandinsky", "birth_date": "1866-12-16", "birth_place": "Moscow, Russia", "nationality": "Russian-French", "occupation": "Artist"}},
            {"entity_code": "caravaggio", "label_ru": "Караваджо", "label_en": "Caravaggio", "desc_ru": "Итальянский барочный живописец", "state": {"first_name": "Michelangelo", "last_name": "Merisi da Caravaggio", "birth_date": "1571-09-29", "birth_place": "Milan, Italy", "nationality": "Italian", "occupation": "Artist"}}
        ]
    },
    "scientist": {
        "model": "science",
        "template_code": "tpl_person",
        "template_name": "Шаблон: Человек (персона)",
        "schema": {
            "type": "object",
            "properties": {
                "first_name": {"type": "string"},
                "last_name": {"type": "string"},
                "birth_date": {"type": "string"},
                "birth_place": {"type": "string"},
                "nationality": {"type": "string"},
                "occupation": {"type": "string"}
            }
        },
        "records": [
            {"entity_code": "stephen_hawking", "label_ru": "Стивен Хокинг", "label_en": "Stephen Hawking", "desc_ru": "Физик-теоретик, исследователь чёрных дыр", "state": {"first_name": "Stephen", "last_name": "Hawking", "birth_date": "1942-01-08", "birth_place": "Oxford, UK", "nationality": "British", "occupation": "Physicist"}},
            {"entity_code": "richard_feynman", "label_ru": "Ричард Фейнман", "label_en": "Richard Feynman", "desc_ru": "Нобелевский лауреат по квантовой электродинамике", "state": {"first_name": "Richard", "last_name": "Feynman", "birth_date": "1918-05-11", "birth_place": "New York, USA", "nationality": "American", "occupation": "Physicist"}},
            {"entity_code": "darwin_scientist", "label_ru": "Чарльз Дарвин", "label_en": "Charles Darwin", "desc_ru": "Натуралист, теория эволюции", "state": {"first_name": "Charles", "last_name": "Darwin", "birth_date": "1809-02-12", "birth_place": "Shrewsbury, UK", "nationality": "British", "occupation": "Naturalist"}},
            {"entity_code": "niels_bohr", "label_ru": "Нильс Бор", "label_en": "Niels Bohr", "desc_ru": "Основоположник квантовой механики", "state": {"first_name": "Niels", "last_name": "Bohr", "birth_date": "1885-10-07", "birth_place": "Copenhagen, Denmark", "nationality": "Danish", "occupation": "Physicist"}},
            {"entity_code": "max_planck", "label_ru": "Макс Планк", "label_en": "Max Planck", "desc_ru": "Основатель квантовой теории", "state": {"first_name": "Max", "last_name": "Planck", "birth_date": "1858-04-23", "birth_place": "Kiel, Germany", "nationality": "German", "occupation": "Physicist"}},
            {"entity_code": "dmitri_mendeleev", "label_ru": "Дмитрий Менделеев", "label_en": "Dmitri Mendeleev", "desc_ru": "Создатель таблицы Менделеева", "state": {"first_name": "Dmitri", "last_name": "Mendeleev", "birth_date": "1834-02-08", "birth_place": "Tobolsk, Russia", "nationality": "Russian", "occupation": "Chemist"}},
            {"entity_code": "galileo", "label_ru": "Галилео Галилей", "label_en": "Galileo Galilei", "desc_ru": "Отец современной науки", "state": {"first_name": "Galileo", "last_name": "Galilei", "birth_date": "1564-02-15", "birth_place": "Pisa, Italy", "nationality": "Italian", "occupation": "Astronomer"}},
            {"entity_code": "linus_pauling", "label_ru": "Лайнус Полинг", "label_en": "Linus Pauling", "desc_ru": "Двукратный нобелевский лауреат", "state": {"first_name": "Linus", "last_name": "Pauling", "birth_date": "1901-02-28", "birth_place": "Portland, Oregon", "nationality": "American", "occupation": "Chemist"}},
            {"entity_code": "rosalind_franklin", "label_ru": "Розалинд Франклин", "label_en": "Rosalind Franklin", "desc_ru": "Открывшая структуру ДНК", "state": {"first_name": "Rosalind", "last_name": "Franklin", "birth_date": "1920-07-25", "birth_place": "London, UK", "nationality": "British", "occupation": "Chemist"}},
            {"entity_code": "alan_turing", "label_ru": "Алан Тьюринг", "label_en": "Alan Turing", "desc_ru": "Отец компьютерных наук", "state": {"first_name": "Alan", "last_name": "Turing", "birth_date": "1912-06-23", "birth_place": "London, UK", "nationality": "British", "occupation": "Mathematician"}}
        ]
    }
}

# =============================================================================
#  RELATION TYPES
# =============================================================================

RELATION_TYPES = [
    {"code": "acted_in", "name": "Снимался в", "direction": "directed", "from": "actor", "to": "movie", "inverse": None},
    {"code": "directed", "name": "Режиссировал", "direction": "directed", "from": "director", "to": "movie", "inverse": "directed_by"},
    {"code": "directed_by", "name": "Режиссёр", "direction": "directed", "from": "movie", "to": "director", "inverse": "directed"},
    {"code": "wrote", "name": "Написал", "direction": "directed", "from": "writer", "to": "book", "inverse": "written_by"},
    {"code": "written_by", "name": "Автор", "direction": "directed", "from": "book", "to": "writer", "inverse": "wrote"},
    {"code": "performed_by", "name": "Исполнил", "direction": "directed", "from": "song", "to": "musician", "inverse": None},
    {"code": "composed", "name": "Написал музыку", "direction": "directed", "from": "musician", "to": "song", "inverse": None},
    {"code": "born_in", "name": "Родился в", "direction": "directed", "from": "human", "to": "place", "inverse": None},
    {"code": "located_in", "name": "Расположен в", "direction": "directed", "from": "place", "to": "place", "inverse": None},
    {"code": "in_genre", "name": "Жанр", "direction": "directed", "from": "movie", "to": "genre", "inverse": None},
    {"code": "influenced_by", "name": "Повлиял на", "direction": "undirected", "from": None, "to": None, "inverse": None},
    {"code": "part_of", "name": "Часть", "direction": "directed", "from": "song", "to": "album", "inverse": None},
    {"code": "painted", "name": "Написал картину", "direction": "directed", "from": "artist", "to": "physical_item", "inverse": None},
    {"code": "discovered", "name": "Открыл", "direction": "directed", "from": "scientist", "to": "chemical_element", "inverse": None},
    {"code": "lived_in", "name": "Жил в", "direction": "directed", "from": "human", "to": "place", "inverse": None},
    {"code": "belonged_to", "name": "Принадлежал к", "direction": "directed", "from": "human", "to": "movement", "inverse": None},
    {"code": "classified_by", "name": "Классифицируется", "direction": "directed", "from": None, "to": "classifier", "inverse": None},
    {"code": "related_to", "name": "Связан с", "direction": "undirected", "from": None, "to": None, "inverse": None},
    {"code": "happened_during", "name": "Произошло во время", "direction": "directed", "from": "phenomenon", "to": "period", "inverse": None},
    {"code": "photographed_by", "name": "Фотограф", "direction": "directed", "from": "photo", "to": "human", "inverse": None},
]

# =============================================================================
#  CROSS-REFERENCES (связи между сущностями)
# =============================================================================

CROSS_REFS = [
    # Фильмы -> Актёры
    ("inception_2010", "acted_in", "leonardo_dicaprio"),
    ("inception_2010", "acted_in", "tom_hardy"),
    ("matrix_1999", "acted_in", "keanu_reeves"),
    ("interstellar_2014", "acted_in", "matthew_mcconaughey"),
    ("fight_club_1999", "acted_in", "brad_pitt"),
    ("pulp_fiction_1994", "acted_in", "john_travolta"),
    ("dark_knight_2008", "acted_in", "tom_hardy"),
    ("forrest_gump_1994", "acted_in", "tom_hanks"),
    ("schindlers_list_1993", "acted_in", "liam_neeson"),
    ("django_2012", "acted_in", "jamie_fox"),
    ("shutter_island_2010", "acted_in", "leonardo_dicaprio"),
    # Фильмы -> Режиссёры
    ("inception_2010", "directed_by", "christopher_nolan"),
    ("matrix_1999", "directed_by", "wachowskis"),
    ("interstellar_2014", "directed_by", "christopher_nolan"),
    ("fight_club_1999", "directed_by", "david_fincher"),
    ("pulp_fiction_1994", "directed_by", "quentin_tarantino"),
    ("dark_knight_2008", "directed_by", "christopher_nolan"),
    ("forrest_gump_1994", "directed_by", "frank_darabont"),
    ("schindlers_list_1993", "directed_by", "steven_spielberg"),
    ("django_2012", "directed_by", "quentin_tarantino"),
    ("shutter_island_2010", "directed_by", "martin_scorsese"),
    # Фильмы -> Жанры
    ("inception_2010", "in_genre", "sci_fi"),
    ("matrix_1999", "in_genre", "sci_fi"),
    ("dark_knight_2008", "in_genre", "noir"),
    ("fight_club_1999", "in_genre", "noir"),
    # Песни -> Музыканты
    ("bohemian_rhapsody", "performed_by", "freddie_mercury"),
    ("stairway_to_heaven", "performed_by", "jimi_hendrix"),
    ("imagine", "performed_by", "john_lennon"),
    ("thriller", "performed_by", "michael_jackson"),
    ("smells_like_teen_spirit", "performed_by", "kurt_cobain"),
    ("no_woman_no_cry", "performed_by", "bob_marley"),
    ("comfortably_numb", "performed_by", "david_gilmour"),
    ("like_a_rolling_stone", "performed_by", "bob_dylan"),
    # Песни -> Альбомы
    ("bohemian_rhapsody", "part_of", "abbey_road"),
    ("stairway_to_heaven", "part_of", "led_zeppelin_iv"),
    ("thriller", "part_of", "thriller_album"),
    ("smells_like_teen_spirit", "part_of", "nevermind"),
    ("hotel_california", "part_of", "hotel_california_album"),
    ("comfortably_numb", "part_of", "the_wall"),
    # Книги -> Писатели
    ("1984_orwell", "written_by", "george_orwell"),
    ("hobbit", "written_by", "tolkien"),
    ("master_margarita", "written_by", "bulgakov"),
    ("war_peace", "written_by", "tolstoy"),
    ("crime_punishment", "written_by", "dostoevsky"),
    ("fahrenheit_451", "written_by", "ray_bradbury"),
    ("solaris", "written_by", "stan_lem"),
    ("brave_new_world", "written_by", "george_orwell"),
    # Фото -> Люди
    ("afghan_girl", "photographed_by", "stephen_hawking"),
    ("earthrise", "photographed_by", "alan_turing"),
    # Учёные -> Элементы
    ("uranium", "discovered_by", "dmitri_mendeleev"),
    # Философия
    ("plato", "belonged_to", "renaissance_movement"),
    # Концепции -> Эпохи
    ("renaissance", "happened_during", "renaissance_period"),
    # Люди -> Места рождения
    ("leonardo_dicaprio", "born_in", "los_angeles"),
    ("christopher_nolan", "born_in", "london"),
    ("freddie_mercury", "born_in", "cairo"),
    ("bob_dylan", "born_in", "new_york"),
    ("albert_einstein", "born_in", "berlin"),
    ("picasso", "born_in", "paris"),
    ("van_gogh", "born_in", "paris"),
    ("ludwig_van_beethoven", "born_in", "berlin"),
]


async def main():
    conn = await connect(DB_URL)
    try:
        # Получаем все kind_id
        kinds = {}
        rows = await conn.fetch("SELECT kind_id, kind_code FROM meta.entity_kind")
        for row in rows:
            kinds[row['kind_code']] = row['kind_id']

        # Получаем все model_id
        models = {}
        rows = await conn.fetch("SELECT model_id, model_code FROM meta.ontology_model")
        for row in rows:
            models[row['model_code']] = row['model_id']

        # Создаём пользователей (если ещё нет)
        existing_admin = await conn.fetchval("SELECT user_id FROM meta.user_account WHERE username = 'admin'")
        if not existing_admin:
            admin_hash = hash_password("admin123")
            user_hash = hash_password("user123")
            await conn.execute("""
                INSERT INTO meta.user_account (username, display_name, is_admin, password_hash)
                VALUES ('admin', 'Administrator', true, $1),
                       ('user', 'User', false, $2)
            """, admin_hash, user_hash)
            print("  Created admin and user accounts")

        # Получаем context_id для 'default'
        ctx = await conn.fetchval("SELECT context_id FROM meta.context WHERE context_code = 'default'")
        admin_user = await conn.fetchval("SELECT user_id FROM meta.user_account WHERE username = 'admin'")

        version_id = 1
        entity_ids = {}  # entity_code -> entity_id
        projection_ids = {}  # entity_code -> projection_id

        # Создаём шаблоны и записи
        for kind_code, data in ENTITY_DATA.items():
            if kind_code not in kinds:
                print(f"SKIP: kind {kind_code} not found")
                continue

            kind_id = kinds[kind_code]
            model_code = data.get("model", "default")
            model_id = models.get(model_code, models["default"])

            # Создаём шаблон
            template_id = uid()
            unique_template_code = f"{kind_code}_{data['template_code']}"
            await conn.execute("""
                INSERT INTO meta.ontology_template (template_id, model_id, template_code, template_name, description, schema_definition, version_id)
                VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7)
            """, uuid.UUID(template_id), model_id, unique_template_code, data["template_name"],
                f"Шаблон для {data['template_name']}", json.dumps(data["schema"]), version_id)

            # Создаём записи
            for rec in data["records"]:
                entity_id = uid()
                entity_ids[rec["entity_code"]] = entity_id

                # Entity
                await conn.execute("""
                    INSERT INTO meta.entity (entity_id, entity_code, kind_id, status, source_id, owner_id, version_id)
                    VALUES ($1, $2, $3, 'active', (SELECT source_id FROM meta.source_system WHERE source_code = 'manual'), $4, $5)
                """, uuid.UUID(entity_id), rec["entity_code"], kind_id, admin_user, version_id)

                # Label (ru)
                await conn.execute("""
                    INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, owner_id, version_id)
                    VALUES ($1, 'ru', $2, $3, true, $4, $5)
                """, uuid.UUID(entity_id), rec["label_ru"], rec.get("desc_ru", ""), admin_user, version_id)

                # Label (en)
                await conn.execute("""
                    INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
                    VALUES ($1, 'en', $2, $3, false, $4)
                """, uuid.UUID(entity_id), rec["label_en"], rec.get("desc_ru", ""), version_id)

                # Projection
                projection_id = uid()
                projection_ids[rec["entity_code"]] = projection_id

                await conn.execute("""
                    INSERT INTO meta.entity_projection (projection_id, entity_id, model_id, template_id, context_id, projection_code, projection_name, confidence, version_id)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, 1.0, $8)
                """, uuid.UUID(projection_id), uuid.UUID(entity_id), model_id,
                    uuid.UUID(template_id), ctx,
                    f"{rec['entity_code']}_{model_code}", rec["label_ru"], version_id)

                # State
                state_data = rec.get("state", {})
                state_hash = hash_json(state_data)
                await conn.execute("""
                    INSERT INTO meta.projection_state (projection_id, state_data, state_hash, is_current, version_id)
                    VALUES ($1, $2::jsonb, $3, true, $4)
                """, uuid.UUID(projection_id), json.dumps(state_data, default=str), state_hash, version_id)

            print(f"  Created {len(data['records'])} records for {kind_code}")

        # Создаём связи
        rel_type_ids = {}
        for rt in RELATION_TYPES:
            rt_id = uid()
            rel_type_ids[rt["code"]] = rt_id
            from_kind = kinds.get(rt.get("from"))
            to_kind = kinds.get(rt.get("to"))
            inverse_id = uuid.UUID(rel_type_ids[rt["inverse"]]) if rt.get("inverse") and rt["inverse"] in rel_type_ids else None

            await conn.execute("""
                INSERT INTO meta.relation_type (relation_type_id, relation_code, relation_name, from_kind_id, to_kind_id, directionality, version_id, inverse_type_id)
                VALUES ($1, $2, $3, $4, $5, $6::meta.relation_direction, $7, $8)
            """, uuid.UUID(rt_id), rt["code"], rt["name"],
                from_kind,
                to_kind,
                rt["direction"], version_id, inverse_id)

        print(f"  Created {len(RELATION_TYPES)} relation types")

        # Создаём семантические связи
        rel_count = 0
        for src_code, rel_code, tgt_code in CROSS_REFS:
            src_proj = projection_ids.get(src_code)
            tgt_proj = projection_ids.get(tgt_code)
            rel_type = rel_type_ids.get(rel_code)

            if src_proj and tgt_proj and rel_type:
                await conn.execute("""
                    INSERT INTO meta.semantic_relation (source_projection_id, relation_type_id, target_projection_id, context_id, weight, confidence, version_id)
                    VALUES ($1, $2, $3, $4, 0.8, 1.0, $5)
                """, uuid.UUID(src_proj), uuid.UUID(rel_type), uuid.UUID(tgt_proj), ctx, version_id)
                rel_count += 1

        print(f"  Created {rel_count} semantic relations")
        print("DONE!")

    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(main())
