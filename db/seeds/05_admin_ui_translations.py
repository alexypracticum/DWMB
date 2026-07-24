#!/usr/bin/env python3
"""
Seed script: Add UI translations for new admin pages.
Run: docker exec dwmb_app python db/seeds/05_admin_ui_translations.py
"""
import asyncio
from sqlalchemy import text
from app.database import async_session


TRANSLATIONS = {
    # Event Log
    "admin_event_log": {"ru": "Журнал событий", "en": "Event Log", "de": "Ereignisprotokoll", "fr": "Journal des événements", "es": "Registro de eventos", "zh": "事件日志", "ja": "イベントログ"},
    "admin_event_type": {"ru": "Тип события", "en": "Event Type", "de": "Ereignistyp", "fr": "Type d'événement", "es": "Tipo de evento", "zh": "事件类型", "ja": "イベントタイプ"},
    "admin_event_all": {"ru": "Все", "en": "All", "de": "Alle", "fr": "Tous", "es": "Todos", "zh": "全部", "ja": "すべて"},
    "admin_event_create": {"ru": "Создание", "en": "Create", "de": "Erstellen", "fr": "Créer", "es": "Crear", "zh": "创建", "ja": "作成"},
    "admin_event_update": {"ru": "Обновление", "en": "Update", "de": "Aktualisieren", "fr": "Mettre à jour", "es": "Actualizar", "zh": "更新", "ja": "更新"},
    "admin_event_delete": {"ru": "Удаление", "en": "Delete", "de": "Löschen", "fr": "Supprimer", "es": "Eliminar", "zh": "删除", "ja": "削除"},
    "admin_event_state_transition": {"ru": "Смена состояния", "en": "State Transition", "de": "Zustandsübergang", "fr": "Transition d'état", "es": "Transición de estado", "zh": "状态转换", "ja": "状態遷移"},
    "admin_event_relation_change": {"ru": "Изменение связи", "en": "Relation Change", "de": "Beziehungsänderung", "fr": "Changement de relation", "es": "Cambio de relación", "zh": "关系变更", "ja": "リレーション変更"},
    "admin_entity_id": {"ru": "Сущность", "en": "Entity", "de": "Entität", "fr": "Entité", "es": "Entidad", "zh": "实体", "ja": "エンティティ"},
    "admin_caused_by": {"ru": "Вызвано", "en": "Caused By", "de": "Verursacht von", "fr": "Causé par", "es": "Causado por", "zh": "触发者", "ja": "実行者"},
    "admin_filter": {"ru": "Фильтр", "en": "Filter", "de": "Filter", "fr": "Filtrer", "es": "Filtrar", "zh": "筛选", "ja": "フィルター"},
    "admin_reset": {"ru": "Сбросить", "en": "Reset", "de": "Zurücksetzen", "fr": "Réinitialiser", "es": "Restablecer", "zh": "重置", "ja": "リセット"},
    "admin_date": {"ru": "Дата", "en": "Date", "de": "Datum", "fr": "Date", "es": "Fecha", "zh": "日期", "ja": "日付"},
    "admin_version": {"ru": "Версия", "en": "Version", "de": "Version", "fr": "Version", "es": "Versión", "zh": "版本", "ja": "バージョン"},
    "admin_no_events": {"ru": "Событий не найдено", "en": "No events found", "de": "Keine Ereignisse gefunden", "fr": "Aucun événement trouvé", "es": "No se encontraron eventos", "zh": "未找到事件", "ja": "イベントが見つかりません"},
    "admin_prev": {"ru": "Назад", "en": "Prev", "de": "Zurück", "fr": "Précédent", "es": "Anterior", "zh": "上一页", "ja": "前へ"},
    "admin_next": {"ru": "Далее", "en": "Next", "de": "Weiter", "fr": "Suivant", "es": "Siguiente", "zh": "下一页", "ja": "次へ"},
    "admin_total_events": {"ru": "Всего событий", "en": "Total events", "de": "Gesamtereignisse", "fr": "Total des événements", "es": "Total de eventos", "zh": "事件总数", "ja": "イベント合計"},
    "admin_page_of": {"ru": "Стр.", "en": "Page", "de": "Seite", "fr": "Page", "es": "Página", "zh": "页", "ja": "ページ"},

    # Roles
    "admin_roles": {"ru": "Роли и разрешения", "en": "Roles & Permissions", "de": "Rollen & Berechtigungen", "fr": "Rôles & Permissions", "es": "Roles y permisos", "zh": "角色与权限", "ja": "ロールと権限"},
    "admin_role_code": {"ru": "Код роли", "en": "Role Code", "de": "Rollencode", "fr": "Code de rôle", "es": "Código de rol", "zh": "角色代码", "ja": "ロールコード"},
    "admin_role_name": {"ru": "Название роли", "en": "Role Name", "de": "Rollenname", "fr": "Nom du rôle", "es": "Nombre del rol", "zh": "角色名称", "ja": "ロール名"},
    "admin_role_description": {"ru": "Описание", "en": "Description", "de": "Beschreibung", "fr": "Description", "es": "Descripción", "zh": "描述", "ja": "説明"},
    "admin_role_users": {"ru": "Пользователи", "en": "Users", "de": "Benutzer", "fr": "Utilisateurs", "es": "Usuarios", "zh": "用户", "ja": "ユーザー"},
    "admin_role_permissions": {"ru": "Разрешения", "en": "Permissions", "de": "Berechtigungen", "fr": "Permissions", "es": "Permisos", "zh": "权限", "ja": "権限"},
    "admin_create_role": {"ru": "Создать роль", "en": "Create Role", "de": "Rolle erstellen", "fr": "Créer un rôle", "es": "Crear rol", "zh": "创建角色", "ja": "ロール作成"},
    "admin_edit_role": {"ru": "Редактировать", "en": "Edit", "de": "Bearbeiten", "fr": "Modifier", "es": "Editar", "zh": "编辑", "ja": "編集"},
    "admin_back_to_roles": {"ru": "Назад к ролям", "en": "Back to Roles", "de": "Zurück zu Rollen", "fr": "Retour aux rôles", "es": "Volver a roles", "zh": "返回角色", "ja": "ロールに戻る"},
    "admin_role_settings": {"ru": "Настройки роли", "en": "Role Settings", "de": "Rolleneinstellungen", "fr": "Paramètres du rôle", "es": "Configuración del rol", "zh": "角色设置", "ja": "ロール設定"},
    "admin_permissions": {"ru": "Разрешения", "en": "Permissions", "de": "Berechtigungen", "fr": "Permissions", "es": "Permisos", "zh": "权限", "ja": "権限"},
    "admin_no_roles": {"ru": "Роли не найдены", "en": "No roles found", "de": "Keine Rollen gefunden", "fr": "Aucun rôle trouvé", "es": "No se encontraron roles", "zh": "未找到角色", "ja": "ロールが見つかりません"},
    "admin_confirm_delete_role": {"ru": "Удалить эту роль?", "en": "Delete this role?", "de": "Diese Rolle löschen?", "fr": "Supprimer ce rôle ?", "es": "¿Eliminar este rol?", "zh": "删除此角色？", "ja": "このロールを削除しますか？"},

    # API Settings
    "admin_api_settings": {"ru": "Настройки API", "en": "API Settings", "de": "API-Einstellungen", "fr": "Paramètres API", "es": "Configuración de API", "zh": "API 设置", "ja": "API 設定"},
    "admin_api_key_omdb": {"ru": "OMDb API ключ", "en": "OMDb API Key", "de": "OMDb API-Schlüssel", "fr": "Clé API OMDb", "es": "Clave API OMDb", "zh": "OMDb API 密钥", "ja": "OMDb API キー"},
    "admin_api_key_omdb_desc": {"ru": "Open Movie Database — https://www.omdbapi.com/apikey.aspx", "en": "Open Movie Database — https://www.omdbapi.com/apikey.aspx", "de": "Open Movie Database — https://www.omdbapi.com/apikey.aspx", "fr": "Open Movie Database — https://www.omdbapi.com/apikey.aspx", "es": "Open Movie Database — https://www.omdbapi.com/apikey.aspx", "zh": "Open Movie Database — https://www.omdbapi.com/apikey.aspx", "ja": "Open Movie Database — https://www.omdbapi.com/apikey.aspx"},
    "admin_api_key_lastfm": {"ru": "Last.fm API ключ", "en": "Last.fm API Key", "de": "Last.fm API-Schlüssel", "fr": "Clé API Last.fm", "es": "Clave API Last.fm", "zh": "Last.fm API 密钥", "ja": "Last.fm API キー"},
    "admin_api_key_lastfm_desc": {"ru": "Last.fm — https://www.last.fm/api/account/create", "en": "Last.fm — https://www.last.fm/api/account/create", "de": "Last.fm — https://www.last.fm/api/account/create", "fr": "Last.fm — https://www.last.fm/api/account/create", "es": "Last.fm — https://www.last.fm/api/account/create", "zh": "Last.fm — https://www.last.fm/api/account/create", "ja": "Last.fm — https://www.last.fm/api/account/create"},
    "admin_api_key_tmdb": {"ru": "TMDB API ключ", "en": "TMDB API Key", "de": "TMDB API-Schlüssel", "fr": "Clé API TMDB", "es": "Clave API TMDB", "zh": "TMDB API 密钥", "ja": "TMDB API キー"},
    "admin_api_key_tmdb_desc": {"ru": "The Movie Database — https://www.themoviedb.org/settings/api", "en": "The Movie Database — https://www.themoviedb.org/settings/api", "de": "The Movie Database — https://www.themoviedb.org/settings/api", "fr": "The Movie Database — https://www.themoviedb.org/settings/api", "es": "The Movie Database — https://www.themoviedb.org/settings/api", "zh": "The Movie Database — https://www.themoviedb.org/settings/api", "ja": "The Movie Database — https://www.themoviedb.org/settings/api"},
    "admin_api_key_ai": {"ru": "AI API ключ", "en": "AI API Key", "de": "AI API-Schlüssel", "fr": "Clé API IA", "es": "Clave API IA", "zh": "AI API 密钥", "ja": "AI API キー"},
    "admin_api_key_ai_desc": {"ru": "OpenAI API ключ для эмбеддингов и чата", "en": "OpenAI API key for embeddings and chat", "de": "OpenAI API-Schlüssel für Embeddings und Chat", "fr": "Clé API OpenAI pour embeddings et chat", "es": "Clave API OpenAI para embeddings y chat", "zh": "OpenAI API 密钥，用于嵌入和聊天", "ja": "OpenAI API キー（埋め込みとチャット用）"},
    "admin_api_source": {"ru": "Источник", "en": "Source", "de": "Quelle", "fr": "Source", "es": "Fuente", "zh": "来源", "ja": "ソース"},
    "admin_api_source_database": {"ru": "база данных", "en": "database", "de": "Datenbank", "fr": "base de données", "es": "base de datos", "zh": "数据库", "ja": "データベース"},
    "admin_api_source_env": {"ru": "переменная окружения", "en": "env variable", "de": "Umgebungsvariable", "fr": "variable d'environnement", "es": "variable de entorno", "zh": "环境变量", "ja": "環境変数"},
    "admin_api_source_not_set": {"ru": "не задан", "en": "not set", "de": "nicht gesetzt", "fr": "non défini", "es": "no configurado", "zh": "未设置", "ja": "未設定"},
    "admin_api_key_placeholder": {"ru": "Введите API ключ...", "en": "Enter API key...", "de": "API-Schlüssel eingeben...", "fr": "Entrer la clé API...", "es": "Ingresar clave API...", "zh": "输入 API 密钥...", "ja": "APIキーを入力..."},
    "admin_api_settings_note": {"ru": "Ключи сохраняются в базе данных и переопределяют значения из .env. Перезапуск не требуется.", "en": "Keys are saved in the database and override .env values. Restart is not required.", "de": "Schlüssel werden in der Datenbank gespeichert und überschreiben .env-Werte. Kein Neustart erforderlich.", "fr": "Les clés sont enregistrées en base de données et remplacent les valeurs .env. Redémarrage non requis.", "es": "Las claves se guardan en la base de datos y sobreescriben los valores de .env. No se requiere reinicio.", "zh": "密钥保存在数据库中，会覆盖 .env 值。无需重启。", "ja": "キーはデータベースに保存され、.env の値を上書きします。再起動は不要です。"},

    # Email Settings
    "admin_email_settings": {"ru": "Настройки email", "en": "Email Settings", "de": "E-Mail-Einstellungen", "fr": "Paramètres email", "es": "Configuración de email", "zh": "邮件设置", "ja": "メール設定"},
    "admin_smtp_configuration": {"ru": "Конфигурация SMTP", "en": "SMTP Configuration", "de": "SMTP-Konfiguration", "fr": "Configuration SMTP", "es": "Configuración SMTP", "zh": "SMTP 配置", "ja": "SMTP 設定"},
    "admin_smtp_host": {"ru": "SMTP хост", "en": "SMTP Host", "de": "SMTP-Host", "fr": "Hôte SMTP", "es": "Host SMTP", "zh": "SMTP 主机", "ja": "SMTP ホスト"},
    "admin_smtp_port": {"ru": "SMTP порт", "en": "SMTP Port", "de": "SMTP-Port", "fr": "Port SMTP", "es": "Puerto SMTP", "zh": "SMTP 端口", "ja": "SMTP ポート"},
    "admin_smtp_username": {"ru": "SMTP имя пользователя", "en": "SMTP Username", "de": "SMTP-Benutzername", "fr": "Nom d'utilisateur SMTP", "es": "Usuario SMTP", "zh": "SMTP 用户名", "ja": "SMTP ユーザー名"},
    "admin_smtp_password": {"ru": "SMTP пароль", "en": "SMTP Password", "de": "SMTP-Passwort", "fr": "Mot de passe SMTP", "es": "Contraseña SMTP", "zh": "SMTP 密码", "ja": "SMTP パスワード"},
    "admin_smtp_from": {"ru": "Адрес отправителя", "en": "From Address", "de": "Absenderadresse", "fr": "Adresse d'expéditeur", "es": "Dirección del remitente", "zh": "发件人地址", "ja": "送信元アドレス"},
    "admin_smtp_tls": {"ru": "Использовать TLS", "en": "Use TLS", "de": "TLS verwenden", "fr": "Utiliser TLS", "es": "Usar TLS", "zh": "使用 TLS", "ja": "TLS を使用"},
    "admin_enabled": {"ru": "Включено", "en": "Enabled", "de": "Aktiviert", "fr": "Activé", "es": "Habilitado", "zh": "已启用", "ja": "有効"},

    # Security
    "admin_security_settings": {"ru": "Настройки безопасности", "en": "Security Settings", "de": "Sicherheitseinstellungen", "fr": "Paramètres de sécurité", "es": "Configuración de seguridad", "zh": "安全设置", "ja": "セキュリティ設定"},
    "admin_secret_key_status": {"ru": "Статус SECRET_KEY", "en": "SECRET_KEY Status", "de": "SECRET_KEY-Status", "fr": "Statut SECRET_KEY", "es": "Estado SECRET_KEY", "zh": "SECRET_KEY 状态", "ja": "SECRET_KEY ステータス"},
    "admin_secret_key_strong": {"ru": "Надёжный ключ", "en": "Strong key", "de": "Starker Schlüssel", "fr": "Clé robuste", "es": "Clave fuerte", "zh": "强密钥", "ja": "強力なキー"},
    "admin_secret_key_short": {"ru": "Слишком короткий", "en": "Too short", "de": "Zu kurz", "fr": "Trop court", "es": "Demasiado corto", "zh": "太短", "ja": "短すぎます"},
    "admin_secret_key_default": {"ru": "Используется ключ по умолчанию", "en": "Using default key", "de": "Standard-Schlüssel wird verwendet", "fr": "Clé par défaut utilisée", "es": "Usando clave predeterminada", "zh": "使用默认密钥", "ja": "デフォルトキーを使用中"},
    "admin_cors_origins": {"ru": "CORS Origins", "en": "CORS Origins", "de": "CORS Origins", "fr": "Origines CORS", "es": "Orígenes CORS", "zh": "CORS 来源", "ja": "CORS オリジン"},
    "admin_cors_origins_desc": {"ru": "Список разрешённых доменов через запятую", "en": "Comma-separated list of allowed origins", "de": "Kommagetrennte Liste erlaubter Origins", "fr": "Liste séparée par des virgules des origines autorisées", "es": "Lista separada por comas de orígenes permitidos", "zh": "逗号分隔的允许来源列表", "ja": "許可オリジンのカンマ区切りリスト"},
    "admin_rate_limit": {"ru": "Лимит запросов (в мин)", "en": "Rate Limit (req/min)", "de": "Rate-Limit (Anf./Min)", "fr": "Limite de débit (req/min)", "es": "Límite de velocidad (req/min)", "zh": "速率限制（请求/分钟）", "ja": "レート制限（リクエスト/分）"},
    "admin_rate_limit_desc": {"ru": "Макс. запросов в минуту на IP", "en": "Max requests per minute per IP", "de": "Max. Anfragen pro Minute pro IP", "fr": "Requêtes max par minute par IP", "es": "Máx. solicitudes por minuto por IP", "zh": "每个 IP 每分钟最大请求数", "ja": "IPごとの1分あたり最大リクエスト数"},
    "admin_auth_rate_limit": {"ru": "Лимит авторизации (в мин)", "en": "Auth Rate Limit (req/min)", "de": "Auth-Rate-Limit (Anf./Min)", "fr": "Limite d'auth (req/min)", "es": "Límite de auth (req/min)", "zh": "认证速率限制（请求/分钟）", "ja": "認証レート制限（リクエスト/分）"},
    "admin_auth_rate_limit_desc": {"ru": "Макс. запросов авторизации в минуту", "en": "Max auth requests per minute per IP", "de": "Max. Auth-Anfragen pro Minute pro IP", "fr": "Requêtes d'auth max par minute par IP", "es": "Máx. solicitudes de auth por minuto por IP", "zh": "每个 IP 每分钟最大认证请求数", "ja": "IPごとの1分あたり最大認証リクエスト数"},
    "admin_csrf_protection": {"ru": "CSRF защита", "en": "CSRF Protection", "de": "CSRF-Schutz", "fr": "Protection CSRF", "es": "Protección CSRF", "zh": "CSRF 保护", "ja": "CSRF 保護"},
    "admin_csrf_protection_desc": {"ru": "Включить/выключить валидацию CSRF токенов", "en": "Enable/disable CSRF token validation", "de": "CSRF-Token-Validierung aktivieren/deaktivieren", "fr": "Activer/désactiver la validation du token CSRF", "es": "Habilitar/deshabilitar validación de token CSRF", "zh": "启用/禁用 CSRF 令牌验证", "ja": "CSRF トークン検証の有効/無効"},
    "admin_security_note": {"ru": "CORS и лимиты сохраняются в БД. Некоторые настройки (SECRET_KEY) требуют изменения в .env и перезапуска.", "en": "CORS and rate limits are saved in the database. Some settings (SECRET_KEY) must be changed in .env and require a restart.", "de": "CORS und Rate-Limits werden in der Datenbank gespeichert. Einige Einstellungen (SECRET_KEY) müssen in .env geändert werden und erfordern einen Neustart.", "fr": "Les CORS et les limites de débit sont enregistrés en base de données. Certains paramètres (SECRET_KEY) doivent être modifiés dans .env et nécessitent un redémarrage.", "es": "CORS y límites de velocidad se guardan en la base de datos. Algunas configuraciones (SECRET_KEY) deben cambiarse en .env y requieren reinicio.", "zh": "CORS 和速率限制保存在数据库中。某些设置（SECRET_KEY）必须在 .env 中更改并需要重启。", "ja": "CORS とレート制限はデータベースに保存されます。一部の設定（SECRET_KEY）は .env で変更し、再起動が必要です。"},

    # Backup
    "admin_backup_restore": {"ru": "Бэкап и восстановление", "en": "Backup & Restore", "de": "Backup & Wiederherstellung", "fr": "Sauvegarde & Restauration", "es": "Copia de seguridad y restauración", "zh": "备份与恢复", "ja": "バックアップと復元"},
    "admin_create_backup": {"ru": "Создать бэкап", "en": "Create Backup", "de": "Backup erstellen", "fr": "Créer une sauvegarde", "es": "Crear copia de seguridad", "zh": "创建备份", "ja": "バックアップ作成"},
    "admin_filename": {"ru": "Имя файла", "en": "Filename", "de": "Dateiname", "fr": "Nom du fichier", "es": "Nombre de archivo", "zh": "文件名", "ja": "ファイル名"},
    "admin_size": {"ru": "Размер", "en": "Size", "de": "Größe", "fr": "Taille", "es": "Tamaño", "zh": "大小", "ja": "サイズ"},
    "admin_created": {"ru": "Создан", "en": "Created", "de": "Erstellt", "fr": "Créé", "es": "Creado", "zh": "创建时间", "ja": "作成日時"},
    "admin_download": {"ru": "Скачать", "en": "Download", "de": "Herunterladen", "fr": "Télécharger", "es": "Descargar", "zh": "下载", "ja": "ダウンロード"},
    "admin_restore": {"ru": "Восстановить", "en": "Restore", "de": "Wiederherstellen", "fr": "Restaurer", "es": "Restaurar", "zh": "恢复", "ja": "復元"},
    "admin_delete": {"ru": "Удалить", "en": "Delete", "de": "Löschen", "fr": "Supprimer", "es": "Eliminar", "zh": "删除", "ja": "削除"},
    "admin_no_backups": {"ru": "Бэкапы не найдены. Создайте первый бэкап.", "en": "No backups found. Create one to get started.", "de": "Keine Backups gefunden. Erstellen Sie eines, um zu beginnen.", "fr": "Aucune sauvegarde trouvée. Créez-en une pour commencer.", "es": "No se encontraron copias de seguridad. Cree una para comenzar.", "zh": "未找到备份。创建一个以开始使用。", "ja": "バックアップが見つかりません。作成して開始してください。"},
    "admin_confirm_restore": {"ru": "Восстановить этот бэкап? Это перезапишет текущую базу данных!", "en": "Restore this backup? This will overwrite the current database!", "de": "Dieses Backup wiederherstellen? Dies überschreibt die aktuelle Datenbank!", "fr": "Restaurer cette sauvegarde ? Cela écrasera la base de données actuelle !", "es": "¿Restaurar esta copia de seguridad? ¡Esto sobrescribirá la base de datos actual!", "zh": "恢复此备份？这将覆盖当前数据库！", "ja": "このバックアップを復元しますか？現在のデータベースが上書きされます！"},
    "admin_confirm_delete_backup": {"ru": "Удалить этот бэкап?", "en": "Delete this backup?", "de": "Dieses Backup löschen?", "fr": "Supprimer cette sauvegarde ?", "es": "¿Eliminar esta copia de seguridad?", "zh": "删除此备份？", "ja": "このバックアップを削除しますか？"},
    "admin_backup_note": {"ru": "Бэкапы хранятся в папке backups/. Восстановление перезапишет текущую базу данных. Всегда создавайте бэкап перед восстановлением.", "en": "Backups are stored in the backups/ directory. Restore will overwrite the current database. Always create a backup before restoring.", "de": "Backups werden im backups/-Verzeichnis gespeichert. Die Wiederherstellung überschreibt die aktuelle Datenbank. Erstellen Sie vor der Wiederherstellung immer ein Backup.", "fr": "Les sauvegardes sont stockées dans le répertoire backups/. La restauration écrasera la base de données actuelle. Créez toujours une sauvegarde avant de restaurer.", "es": "Las copias de seguridad se almacenan en el directorio backups/. La restauración sobrescribirá la base de datos actual. Siempre cree una copia antes de restaurar.", "zh": "备份存储在 backups/ 目录中。恢复将覆盖当前数据库。恢复前请始终创建备份。", "ja": "バックアップは backups/ ディレクトリに保存されます。復元すると現在のデータベースが上書きされます。復元前に必ずバックアップを作成してください。"},
    "admin_mb": {"ru": "МБ", "en": "MB", "de": "MB", "fr": "Mo", "es": "MB", "zh": "MB", "ja": "MB"},
}


async def seed_translations():
    """Add translation keys and values to the database."""
    async with async_session() as db:
        # Get language IDs
        lang_result = await db.execute(text("SELECT language_id, code FROM meta.language"))
        lang_map = {row[1]: row[0] for row in lang_result}

        # Get existing keys
        existing_result = await db.execute(text("SELECT key FROM meta.ui_string"))
        existing_keys = {row[0] for row in existing_result}

        added = 0
        for key, translations in TRANSLATIONS.items():
            if key not in existing_keys:
                # Create UI string
                await db.execute(
                    text("INSERT INTO meta.ui_string (string_id, key, category) VALUES (gen_random_uuid(), :key, 'admin')"),
                    {"key": key}
                )
                added += 1

            # Create translations for each language
            for lang_code, value in translations.items():
                if lang_code in lang_map:
                    lang_id = lang_map[lang_code]
                    # Check if translation exists
                    check = await db.execute(
                        text("SELECT 1 FROM meta.ui_string_translation ust JOIN meta.ui_string us ON ust.string_id = us.string_id WHERE us.key = :key AND ust.language_id = :lang_id"),
                        {"key": key, "lang_id": lang_id}
                    )
                    if not check.fetchone():
                        await db.execute(
                            text("""
                                INSERT INTO meta.ui_string_translation (translation_id, string_id, language_id, value)
                                SELECT gen_random_uuid(), us.string_id, :lang_id, :value
                                FROM meta.ui_string us WHERE us.key = :key
                            """),
                            {"key": key, "lang_id": lang_id, "value": value}
                        )

        await db.commit()
        print(f"Added {added} new UI string keys")
        print(f"Total translations: {len(TRANSLATIONS) * 7}")


if __name__ == "__main__":
    asyncio.run(seed_translations())
