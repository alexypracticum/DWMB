# TODO

## Текущий статус: v0.17.0

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

- [ ] Wikipedia API: поиск и импорт описаний
- [ ] MusicBrainz API: поиск музыкальных данных
- [ ] Поиск по графу: расширенный поиск с учётом связей
- [ ] Экспорт графа: PNG/SVG/JSON

## Осталось — Техническое

- [ ] Тесты покрытие: граф, OMDb, subscriptions
- [ ] API документация: OpenAPI аннотации

## Осталось — UI/UX

- [ ] Личный кабинет: профиль, история импортов, избранное
- [ ] Уведомления в UI: toast через subscriptions
- [ ] Тёмная тема для графа

## Осталось — Продакшен (отложить)

- [ ] Мониторинг (Prometheus/Grafana)

---

## Заметки

- Тесты: 169+ тестов (`docker exec dwmb_app python -m pytest tests/`)
- OMDb API ключ: бесплатный, https://www.omdbapi.com/apikey.aspx
- Redis кэш: автоматически fallback на in-memory если Redis недоступен
- CI/CD: тесты работают, деплой требует настройки секретов в GitHub
