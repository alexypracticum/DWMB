-- Migration 015: Add UI translations for new admin pages
-- Event Log, Roles, API Settings, Email Settings, Security, Backup

DO $$
DECLARE
    lang RECORD;
    ui_string_id UUID;
BEGIN
    -- Helper function to create UI string with translations
    -- We'll insert UI strings and their translations

    -- ============================================================
    -- EVENT LOG translations
    -- ============================================================

    INSERT INTO meta.ui_string (string_id, key, category) VALUES
        (gen_random_uuid(), 'admin_event_log', 'admin'),
        (gen_random_uuid(), 'admin_event_type', 'admin'),
        (gen_random_uuid(), 'admin_event_all', 'admin'),
        (gen_random_uuid(), 'admin_event_create', 'admin'),
        (gen_random_uuid(), 'admin_event_update', 'admin'),
        (gen_random_uuid(), 'admin_event_delete', 'admin'),
        (gen_random_uuid(), 'admin_event_state_transition', 'admin'),
        (gen_random_uuid(), 'admin_event_relation_change', 'admin'),
        (gen_random_uuid(), 'admin_entity_id', 'admin'),
        (gen_random_uuid(), 'admin_caused_by', 'admin'),
        (gen_random_uuid(), 'admin_filter', 'admin'),
        (gen_random_uuid(), 'admin_reset', 'admin'),
        (gen_random_uuid(), 'admin_date', 'admin'),
        (gen_random_uuid(), 'admin_version', 'admin'),
        (gen_random_uuid(), 'admin_no_events', 'admin'),
        (gen_random_uuid(), 'admin_prev', 'admin'),
        (gen_random_uuid(), 'admin_next', 'admin'),
        (gen_random_uuid(), 'admin_total_events', 'admin'),
        (gen_random_uuid(), 'admin_page_of', 'admin');

    -- ============================================================
    -- ROLES translations
    -- ============================================================

    INSERT INTO meta.ui_string (string_id, key, category) VALUES
        (gen_random_uuid(), 'admin_roles', 'admin'),
        (gen_random_uuid(), 'admin_role_code', 'admin'),
        (gen_random_uuid(), 'admin_role_name', 'admin'),
        (gen_random_uuid(), 'admin_role_description', 'admin'),
        (gen_random_uuid(), 'admin_role_users', 'admin'),
        (gen_random_uuid(), 'admin_role_permissions', 'admin'),
        (gen_random_uuid(), 'admin_create_role', 'admin'),
        (gen_random_uuid(), 'admin_edit_role', 'admin'),
        (gen_random_uuid(), 'admin_back_to_roles', 'admin'),
        (gen_random_uuid(), 'admin_role_settings', 'admin'),
        (gen_random_uuid(), 'admin_permissions', 'admin'),
        (gen_random_uuid(), 'admin_no_roles', 'admin'),
        (gen_random_uuid(), 'admin_confirm_delete_role', 'admin');

    -- ============================================================
    -- API SETTINGS translations
    -- ============================================================

    INSERT INTO meta.ui_string (string_id, key, category) VALUES
        (gen_random_uuid(), 'admin_api_settings', 'admin'),
        (gen_random_uuid(), 'admin_api_key_omdb', 'admin'),
        (gen_random_uuid(), 'admin_api_key_omdb_desc', 'admin'),
        (gen_random_uuid(), 'admin_api_key_lastfm', 'admin'),
        (gen_random_uuid(), 'admin_api_key_lastfm_desc', 'admin'),
        (gen_random_uuid(), 'admin_api_key_tmdb', 'admin'),
        (gen_random_uuid(), 'admin_api_key_tmdb_desc', 'admin'),
        (gen_random_uuid(), 'admin_api_key_ai', 'admin'),
        (gen_random_uuid(), 'admin_api_key_ai_desc', 'admin'),
        (gen_random_uuid(), 'admin_api_source', 'admin'),
        (gen_random_uuid(), 'admin_api_source_database', 'admin'),
        (gen_random_uuid(), 'admin_api_source_env', 'admin'),
        (gen_random_uuid(), 'admin_api_source_not_set', 'admin'),
        (gen_random_uuid(), 'admin_api_key_placeholder', 'admin'),
        (gen_random_uuid(), 'admin_api_settings_note', 'admin');

    -- ============================================================
    -- EMAIL SETTINGS translations
    -- ============================================================

    INSERT INTO meta.ui_string (string_id, key, category) VALUES
        (gen_random_uuid(), 'admin_email_settings', 'admin'),
        (gen_random_uuid(), 'admin_smtp_configuration', 'admin'),
        (gen_random_uuid(), 'admin_smtp_host', 'admin'),
        (gen_random_uuid(), 'admin_smtp_port', 'admin'),
        (gen_random_uuid(), 'admin_smtp_username', 'admin'),
        (gen_random_uuid(), 'admin_smtp_password', 'admin'),
        (gen_random_uuid(), 'admin_smtp_from', 'admin'),
        (gen_random_uuid(), 'admin_smtp_tls', 'admin'),
        (gen_random_uuid(), 'admin_enabled', 'admin');

    -- ============================================================
    -- SECURITY translations
    -- ============================================================

    INSERT INTO meta.ui_string (string_id, key, category) VALUES
        (gen_random_uuid(), 'admin_security_settings', 'admin'),
        (gen_random_uuid(), 'admin_secret_key_status', 'admin'),
        (gen_random_uuid(), 'admin_secret_key_strong', 'admin'),
        (gen_random_uuid(), 'admin_secret_key_short', 'admin'),
        (gen_random_uuid(), 'admin_secret_key_default', 'admin'),
        (gen_random_uuid(), 'admin_cors_origins', 'admin'),
        (gen_random_uuid(), 'admin_cors_origins_desc', 'admin'),
        (gen_random_uuid(), 'admin_rate_limit', 'admin'),
        (gen_random_uuid(), 'admin_rate_limit_desc', 'admin'),
        (gen_random_uuid(), 'admin_auth_rate_limit', 'admin'),
        (gen_random_uuid(), 'admin_auth_rate_limit_desc', 'admin'),
        (gen_random_uuid(), 'admin_csrf_protection', 'admin'),
        (gen_random_uuid(), 'admin_csrf_protection_desc', 'admin'),
        (gen_random_uuid(), 'admin_security_note', 'admin');

    -- ============================================================
    -- BACKUP translations
    -- ============================================================

    INSERT INTO meta.ui_string (string_id, key, category) VALUES
        (gen_random_uuid(), 'admin_backup_restore', 'admin'),
        (gen_random_uuid(), 'admin_create_backup', 'admin'),
        (gen_random_uuid(), 'admin_filename', 'admin'),
        (gen_random_uuid(), 'admin_size', 'admin'),
        (gen_random_uuid(), 'admin_created', 'admin'),
        (gen_random_uuid(), 'admin_download', 'admin'),
        (gen_random_uuid(), 'admin_restore', 'admin'),
        (gen_random_uuid(), 'admin_delete', 'admin'),
        (gen_random_uuid(), 'admin_no_backups', 'admin'),
        (gen_random_uuid(), 'admin_confirm_restore', 'admin'),
        (gen_random_uuid(), 'admin_confirm_delete_backup', 'admin'),
        (gen_random_uuid(), 'admin_backup_note', 'admin'),
        (gen_random_uuid(), 'admin_mb', 'admin');

END $$;
