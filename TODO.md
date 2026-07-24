# TODO

## Текущий статус: v0.18.0

### Выполнено (v0.18.0)

**Внешние API:**
- [x] Last.fm интеграция (12 API эндпоинтов, виджет "Часто слушаю")
- [x] Wikipedia API (поиск, импорт, кэш, rate limit)
- [x] MusicBrainz API (поиск, детали, импорт, кэш, rate limit)
- [x] OMDb кэширование + rate limiting

**Граф связей:**
- [x] Поиск по графу (расширенный поиск с учётом связей)
- [x] Экспорт графа: PNG/SVG/JSON
- [x] Тёмная тема для графа

**GraphQL:**
- [x] Subscriptions (entityChanged, commentChanged, relationChanged)
- [x] JS клиент с auto-reconnect

**Инфраструктура:**
- [x] CI/CD: GitHub Actions (test, deploy, docker-publish)
- [x] Toast-уведомления
- [x] Email подтверждение + CRUD пользователей

**Тесты:**
- [x] 207 тестовых функций (37 файлов)

---

### Выполнено (v0.17.0)

**Локализация:**
- [x] Версия в main.py: обновлена до "0.17.0"
- [x] RU_LABELS/EN_LABELS удалены из helpers.py
- [x] field_schema titles заменены на i18n keys
- [x] edit.html + layout_fields.html переведены
- [x] /map, редактор тем, темы пресетов переведены
- [x] Dark mode toggle для всех

**Граф связей:**
- [x] D3.js force-directed граф
- [x] API endpoint + AJAX загрузка
- [x] zoom/pan, drag, hover, клик
- [x] Фильтрация по типам связей

**OMDb / IMDB:**
- [x] search_imdb(), get_imdb_details(), import_imdb_movie()
- [x] REST эндпоинты + UI модалка
- [x] Кэширование: поиск 1ч, детали 24ч
- [x] Rate limiting: 500ms между запросами

**Инфраструктура:**
- [x] CI/CD: GitHub Actions (test, deploy, docker-publish)
- [x] GraphQL subscriptions (entityChanged, commentChanged, relationChanged)
- [x] WebSocket event bus + JS клиент

**Исправления:**
- [x] CSRF middleware: form body validation
- [x] manager import в crud.py
- [x] label priority в info_table

---

## Осталось — Функциональное

- [x] Wikipedia API: поиск и импорт описаний
- [x] MusicBrainz API: поиск музыкальных данных
- [x] Last.fm интеграция: импорт истории, виджет "Часто слушаю" + кросс-референс MusicBrainz
- [x] Поиск по графу: расширенный поиск с учётом связей (UI + API)
- [ ] Экспорт графа: PNG/SVG/JSON

## Осталось — Техническое

- [x] Тесты покрытие: граф (12 тестов), OMDb, Wikipedia, MusicBrainz
- [x] API документация: OpenAPI аннотации, теги, Swagger UI (/api/docs), ReDoc (/api/redoc)
- [ ] API документация: OpenAPI аннотации

## Осталось — UI/UX

- [x] Личный кабинет: профиль, история импортов, избранное (/dashboard/)
- [x] Уведомления в UI: toast через subscriptions
- [x] Тёмная тема для графа

## Осталось — Аутентификация

- [x] Email подтверждение: верификация при регистрации, повторная отправка, статус в профиле
- [x] CRUD пользователей: создание, редактирование, удаление, ролевая модель

## Осталось — Продакшен (отложить)

- [ ] Мониторинг (Prometheus/Grafana)

---

## Заметки

- Тесты: 169+ тестов (`docker exec dwmb_app python -m pytest tests/`)
- OMDb API ключ: бесплатный, https://www.omdbapi.com/apikey.aspx
- Redis кэш: автоматически fallback на in-memory если Redis недоступен
- CI/CD: тесты работают, деплой требует настройки секретов в GitHub
