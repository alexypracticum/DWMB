-- Migration 013: Add i18n keys for new templates (lastfm, dashboard, admin, search, auth)

-- Helper function to add key + translations
CREATE OR REPLACE FUNCTION add_i18n_key(p_key TEXT, p_ru TEXT, p_en TEXT, p_de TEXT, p_fr TEXT, p_es TEXT, p_zh TEXT, p_ja TEXT)
RETURNS VOID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO meta.ui_string (key, category) VALUES (p_key, 'new_templates')
    ON CONFLICT (key) DO NOTHING
    RETURNING string_id INTO v_id;

    IF v_id IS NULL THEN
        SELECT string_id INTO v_id FROM meta.ui_string WHERE key = p_key;
    END IF;

    INSERT INTO meta.ui_string_translation (string_id, language_id, value)
    SELECT v_id, l.language_id, translation
    FROM (VALUES
        ('ru', p_ru), ('en', p_en), ('de', p_de), ('fr', p_fr),
        ('es', p_es), ('zh', p_zh), ('ja', p_ja)
    ) AS t(lang, translation)
    JOIN meta.language l ON l.code = t.lang
    ON CONFLICT (string_id, language_id) DO UPDATE SET value = EXCLUDED.value;
END;
$$ LANGUAGE plpgsql;

-- Last.fm Widget
SELECT add_i18n_key('label_frequently_played', 'Часто слушаю', 'Frequently Played', 'Häufig gehört', 'Fréquemment joué', 'Reproducido frecuentemente', '常听', 'よく聴く');
SELECT add_i18n_key('label_import_from_lastfm', 'Импортировать из Last.fm', 'Import from Last.fm', 'Aus Last.fm importieren', 'Importer depuis Last.fm', 'Importar desde Last.fm', '从Last.fm导入', 'Last.fmからインポート');
SELECT add_i18n_key('btn_update', 'Обновить', 'Update', 'Aktualisieren', 'Mettre à jour', 'Actualizar', '更新', '更新');
SELECT add_i18n_key('label_tracks_count', 'треков', 'tracks', 'Tracks', 'titres', 'pistas', '首', '曲');
SELECT add_i18n_key('placeholder_username', 'Введите имя пользователя', 'Enter username', 'Benutzernamen eingeben', "Entrez le nom d'utilisateur", 'Ingrese el nombre de usuario', '请输入用户名', 'ユーザー名を入力');
SELECT add_i18n_key('label_all_time', 'За всё время', 'All time', 'Gesamte Zeit', 'Tout le temps', 'Todo el tiempo', '全部时间', '全期間');
SELECT add_i18n_key('label_last_12_months', 'За 12 месяцев', 'Last 12 months', 'Letzte 12 Monate', '12 derniers mois', 'Últimos 12 meses', '过去12个月', '過去12ヶ月');
SELECT add_i18n_key('label_last_6_months', 'За 6 месяцев', 'Last 6 months', 'Letzte 6 Monate', '6 derniers mois', 'Últimos 6 meses', '过去6个月', '過去6ヶ月');
SELECT add_i18n_key('label_last_3_months', 'За 3 месяца', 'Last 3 months', 'Letzte 3 Monate', '3 derniers mois', 'Últimos 3 meses', '过去3个月', '過去3ヶ月');
SELECT add_i18n_key('label_last_month', 'За месяц', 'Last month', 'Letzter Monat', 'Dernier mois', 'Último mes', '上个月', '先月');
SELECT add_i18n_key('label_last_week', 'За неделю', 'Last week', 'Letzte Woche', 'Dernière semaine', 'Última semana', '上周', '先週');
SELECT add_i18n_key('label_tracks_count_short', 'шт.', 'pcs.', 'Stk.', 'pzs.', 'uds.', '件', '件');
SELECT add_i18n_key('no_data_played', 'Нет данных о прослушиваниях', 'No listening data available', 'Keine Höhdaten verfügbar', 'Aucune donnée d écoute', 'No hay datos de escucha', '没有收听数据', '聴取データなし');
SELECT add_i18n_key('label_musicbrainz_crossref', 'Кросс-референс с MusicBrainz', 'Cross-reference with MusicBrainz', 'Querverweis mit MusicBrainz', 'Référence croisée avec MusicBrainz', 'Referencia cruzada con MusicBrainz', '与MusicBrainz交叉引用', 'MusicBrainzとのクロスリファレンス');
SELECT add_i18n_key('label_importing', 'Импорт...', 'Importing...', 'Importieren...', 'Importation...', 'Importando...', '导入中...', 'インポート中...');
SELECT add_i18n_key('label_cancel', 'Отмена', 'Cancel', 'Abbrechen', 'Annuler', 'Cancelar', '取消', 'キャンセル');
SELECT add_i18n_key('btn_import', 'Импортировать', 'Import', 'Importieren', 'Importer', 'Importar', '导入', 'インポート');
SELECT add_i18n_key('label_period', 'Период', 'Period', 'Zeitraum', 'Période', 'Período', '期间', '期間');
SELECT add_i18n_key('label_tracks_count_field', 'Количество треков', 'Number of tracks', 'Anzahl der Tracks', 'Nombre de titres', 'Número de pistas', '曲数', '曲数');

-- Dashboard
SELECT add_i18n_key('label_dashboard', 'Личный кабинет', 'Personal Dashboard', 'Persönliches Dashboard', 'Tableau de bord personnel', 'Panel personal', '个人中心', 'パーソナルダッシュボード');
SELECT add_i18n_key('label_import_history', 'История импортов', 'Import History', 'Importverlauf', "Historique d'importation", 'Historial de importaciones', '导入历史', 'インポート履歴');
SELECT add_i18n_key('label_no_imports', 'Пока нет импортов', 'No imports yet', 'Noch keine Imports', "Aucune importation pour l'instant", 'Sin importaciones todavía', '暂无导入', 'インポートなし');
SELECT add_i18n_key('label_start_import', 'Начать импорт', 'Start import', 'Import starten', "Commencer l'importation", 'Iniciar importación', '开始导入', 'インポート開始');
SELECT add_i18n_key('label_favorites', 'Избранное', 'Favorites', 'Favoriten', 'Favoris', 'Favoritos', '收藏夹', 'お気に入り');
SELECT add_i18n_key('label_no_favorites', 'Избранное пусто', 'Favorites is empty', 'Favoriten sind leer', 'Les favoris sont vides', 'Favoritos vacíos', '收藏夹为空', 'お気に入りは空です');
SELECT add_i18n_key('label_add_favorites_hint', 'Нажмите ⭐ на странице сущности', 'Click ⭐ on entity page', 'Klicken Sie ⭐ auf der Entitätsseite', 'Cliquez ⭐ sur la page entité', 'Haga clic ⭐ en la página de entidad', '在实体页面点击⭐', 'エンティティページで⭐をクリック');
SELECT add_i18n_key('label_entities_created', 'Создано сущностей', 'Entities Created', 'Erstellte Entitäten', 'Entités créées', 'Entidades creadas', '已创建实体', '作成されたエンティティ');
SELECT add_i18n_key('label_imports_done', 'Импортов выполнено', 'Imports Done', 'Imports abgeschlossen', 'Importations effectuées', 'Importaciones realizadas', '完成导入', '完了したインポート');
SELECT add_i18n_key('label_quick_links', 'Быстрые ссылки', 'Quick Links', 'Schnelllinks', 'Liens rapides', 'Enlaces rápidos', '快捷链接', 'クイックリンク');
SELECT add_i18n_key('label_profile', 'Профиль', 'Profile', 'Profil', 'Profil', 'Perfil', '个人资料', 'プロフィール');
SELECT add_i18n_key('label_create_entity', 'Создать сущность', 'Create Entity', 'Entität erstellen', 'Créer une entité', 'Crear entidad', '创建实体', 'エンティティ作成');

-- Admin Users
SELECT add_i18n_key('btn_create_user', 'Создать пользователя', 'Create User', 'Benutzer erstellen', "Créer un utilisateur", 'Crear usuario', '创建用户', 'ユーザー作成');
SELECT add_i18n_key('btn_edit_short', 'Ред.', 'Edit', 'Bearb.', 'Modif.', 'Edit.', '编辑', '編集');
SELECT add_i18n_key('btn_verify_short', 'Подтв.', 'Verify', 'Best.', 'Vérif.', 'Verif.', '验证', '確認');
SELECT add_i18n_key('btn_block_short', 'Блок.', 'Block', 'Block.', 'Bloq.', 'Bloq.', '封禁', 'ブロック');
SELECT add_i18n_key('btn_unblock_short', 'Разбл.', 'Unblock', 'Aufh.', 'Débloq.', 'Desbloq.', '解封', 'ブロック解除');
SELECT add_i18n_key('btn_delete_short', 'Удал.', 'Del', 'Lösch.', 'Suppr.', 'Elim.', '删除', '削除');
SELECT add_i18n_key('confirm_delete_user', 'Удалить пользователя', 'Delete user', 'Benutzer löschen', "Supprimer l'utilisateur", 'Eliminar usuario', '删除用户', 'ユーザーを削除');
SELECT add_i18n_key('label_user_edit', 'Редактирование пользователя', 'Edit User', 'Benutzer bearbeiten', "Modifier l'utilisateur", 'Editar usuario', '编辑用户', 'ユーザー編集');
SELECT add_i18n_key('label_new_user', 'Новый', 'New', 'Neu', 'Nouveau', 'Nuevo', '新建', '新規');
SELECT add_i18n_key('label_display_name', 'Отображаемое имя', 'Display Name', 'Anzeigename', "Nom d'affichage", 'Nombre para mostrar', '显示名称', '表示名');
SELECT add_i18n_key('label_password', 'Пароль', 'Password', 'Passwort', 'Mot de passe', 'Contraseña', '密码', 'パスワード');
SELECT add_i18n_key('label_new_password', 'Новый пароль', 'New Password', 'Neues Passwort', 'Nouveau mot de passe', 'Nueva contraseña', '新密码', '新しいパスワード');
SELECT add_i18n_key('label_leave_empty_to_keep', 'Оставьте пустым для сохранения', 'Leave empty to keep current', 'Leer lassen um beizubehalten', 'Laisser vide pour conserver', 'Dejar vacío para mantener', '留空保持当前', '空欄で現在を維持');
SELECT add_i18n_key('label_role', 'Роль', 'Role', 'Rolle', 'Rôle', 'Rol', '角色', '役割');
SELECT add_i18n_key('label_no_role', 'Без роли', 'No role', 'Keine Rolle', 'Sans rôle', 'Sin rol', '无角色', '役割なし');
SELECT add_i18n_key('label_admin_flag', 'Администратор', 'Administrator', 'Administrator', 'Administrador', 'Administrador', '管理员', '管理者');
SELECT add_i18n_key('label_active_flag', 'Активен', 'Active', 'Aktiv', 'Actif', 'Activo', '活跃', 'アクティブ');
SELECT add_i18n_key('btn_save', 'Сохранить', 'Save', 'Speichern', 'Enregistrer', 'Guardar', '保存', '保存');
SELECT add_i18n_key('btn_cancel', 'Отмена', 'Cancel', 'Abbrechen', 'Annuler', 'Cancelar', '取消', 'キャンセル');

-- Auth / Email Verification
SELECT add_i18n_key('label_email_verified', 'Email подтверждён', 'Email verified', 'E-Mail bestätigt', 'Email vérifié', 'Email verificado', '邮箱已验证', 'メール確認済み');
SELECT add_i18n_key('label_email_not_verified', 'Email не подтверждён', 'Email not verified', 'E-Mail nicht bestätigt', 'Email non vérifié', 'Email no verificado', '邮箱未验证', 'メール未確認');
SELECT add_i18n_key('btn_resend', 'Отправить повторно', 'Resend', 'Erneut senden', 'Renvoyer', 'Reenviar', '重新发送', '再送信');
SELECT add_i18n_key('verify_sent', 'Письмо с подтверждением отправлено', 'Verification email sent', 'Bestätigungs-E-Mail gesendet', 'Email de vérification envoyé', 'Email de verificación enviado', '确认邮件已发送', '確認メール送信済み');
SELECT add_i18n_key('verify_title', 'Подтверждение email', 'Email Verification', 'E-Mail-Bestätigung', 'Vérification email', 'Verificación de email', '邮箱验证', 'メール確認');
SELECT add_i18n_key('verify_success', 'Email успешно подтверждён!', 'Email verified successfully!', 'E-Mail erfolgreich bestätigt!', 'Email vérifié avec succès !', '¡Email verificado con éxito!', '邮箱验证成功！', 'メール確認成功！');
SELECT add_i18n_key('verify_error', 'Неверный или устаревший токен', 'Invalid or expired token', 'Ungültiges oder abgelaufens Token', 'Jeton invalide ou expiré', 'Token inválido o expirado', '无效或过期的令牌', '無効または期限切れのトークン');
SELECT add_i18n_key('btn_login', 'Войти', 'Login', 'Anmelden', 'Se connecter', 'Iniciar sesión', '登录', 'ログイン');
SELECT add_i18n_key('verify_check_email', 'Проверьте вашу почту', 'Check your email', 'Überprüfen Sie Ihre E-Mail', 'Vérifiez votre email', 'Revise su correo electrónico', '请检查您的邮箱', 'メールを確認してください');

-- Search
SELECT add_i18n_key('search_found', 'Найдено', 'Found', 'Gefunden', 'Trouvé', 'Encontrado', '找到', '見つかりました');
SELECT add_i18n_key('search_related_results', 'связанных результат(ов)', 'related results', 'verwandte Ergebnisse', 'résultats liés', 'resultados relacionados', '个相关结果', '件の関連結果');
SELECT add_i18n_key('search_by_query', 'по запросу', 'for query', 'für Abfrage', 'pour la requête', 'para la consulta', '查询', 'クエリ');
SELECT add_i18n_key('search_no_graph_results', 'Не найдено связанных сущностей', 'No related entities found', 'Keine verwandten Entitäten gefunden', 'Aucune entité liée trouvée', 'No se encontraron entidades relacionadas', '未找到相关实体', '関連エンティティが見つかりません');
SELECT add_i18n_key('search_text_mode', 'Текстовый поиск', 'Text Search', 'Textsuche', 'Recherche texte', 'Búsqueda de texto', '文本搜索', 'テキスト検索');
SELECT add_i18n_key('search_graph_mode', 'Поиск по графу', 'Graph Search', 'Graphsuche', 'Recherche graphe', 'Búsqueda en grafo', '图搜索', 'グラフ検索');
SELECT add_i18n_key('search_relation', 'Связь', 'Relation', 'Beziehung', 'Relation', 'Relación', '关系', '関係');
SELECT add_i18n_key('search_all_relations', 'Все связи', 'All relations', 'Alle Beziehungen', 'Toutes les relations', 'Todas las relaciones', '所有关系', 'すべての関係');
SELECT add_i18n_key('ai_recognized', 'AI распознал', 'AI recognized', 'KI erkannt', 'IA reconnue', 'IA reconoció', 'AI识别', 'AI認識');

-- Cleanup
DROP FUNCTION IF EXISTS add_i18n_key(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);
