--
-- PostgreSQL database dump
--

\restrict bBKrEejqTvzRkpaJsbPmAa5U69uNHrshic3MAxjf0df6OOHb1ZNbXiW7S1pjrUW

-- Dumped from database version 16.14 (Debian 16.14-1.pgdg12+1)
-- Dumped by pg_dump version 16.14 (Debian 16.14-1.pgdg12+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: meta; Type: SCHEMA; Schema: -; Owner: dwmb
--

CREATE SCHEMA meta;


ALTER SCHEMA meta OWNER TO dwmb;

--
-- Name: entity_status; Type: TYPE; Schema: meta; Owner: dwmb
--

CREATE TYPE meta.entity_status AS ENUM (
    'active',
    'deprecated',
    'deleted'
);


ALTER TYPE meta.entity_status OWNER TO dwmb;

--
-- Name: event_kind; Type: TYPE; Schema: meta; Owner: dwmb
--

CREATE TYPE meta.event_kind AS ENUM (
    'create',
    'update',
    'delete',
    'merge',
    'split',
    'state_transition',
    'relation_change'
);


ALTER TYPE meta.event_kind OWNER TO dwmb;

--
-- Name: language_code; Type: TYPE; Schema: meta; Owner: dwmb
--

CREATE TYPE meta.language_code AS ENUM (
    'en',
    'ru',
    'de',
    'fr',
    'es',
    'zh',
    'ja'
);


ALTER TYPE meta.language_code OWNER TO dwmb;

--
-- Name: relation_direction; Type: TYPE; Schema: meta; Owner: dwmb
--

CREATE TYPE meta.relation_direction AS ENUM (
    'directed',
    'undirected'
);


ALTER TYPE meta.relation_direction OWNER TO dwmb;

--
-- Name: storage_backend; Type: TYPE; Schema: meta; Owner: dwmb
--

CREATE TYPE meta.storage_backend AS ENUM (
    'local',
    'nfs',
    's3'
);


ALTER TYPE meta.storage_backend OWNER TO dwmb;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ai_config; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.ai_config (
    config_id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider text DEFAULT 'openai'::text NOT NULL,
    model_embedding text DEFAULT 'text-embedding-3-small'::text NOT NULL,
    model_chat text DEFAULT 'gpt-4o-mini'::text NOT NULL,
    api_key_enc bytea,
    api_base_url text DEFAULT 'https://api.openai.com/v1'::text,
    max_tokens integer DEFAULT 4096 NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE meta.ai_config OWNER TO dwmb;

--
-- Name: ai_suggestion; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.ai_suggestion (
    suggestion_id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    suggestion_type text NOT NULL,
    field_key text,
    suggested_value jsonb NOT NULL,
    confidence numeric(5,4),
    is_accepted boolean,
    reviewed_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ai_suggestion_confidence_check CHECK (((confidence >= (0)::numeric) AND (confidence <= (1)::numeric)))
);


ALTER TABLE meta.ai_suggestion OWNER TO dwmb;

--
-- Name: ai_task_log; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.ai_task_log (
    task_id uuid DEFAULT gen_random_uuid() NOT NULL,
    task_type text NOT NULL,
    model_used text,
    input_tokens integer DEFAULT 0,
    output_tokens integer DEFAULT 0,
    cost_usd numeric(10,6) DEFAULT 0,
    duration_ms integer,
    entity_id uuid,
    status text DEFAULT 'pending'::text NOT NULL,
    error_message text,
    payload jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE meta.ai_task_log OWNER TO dwmb;

--
-- Name: comment; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.comment (
    comment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    user_id uuid,
    parent_id uuid,
    content text NOT NULL,
    is_approved boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE meta.comment OWNER TO dwmb;

--
-- Name: context; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.context (
    context_id uuid DEFAULT gen_random_uuid() NOT NULL,
    parent_context_id uuid,
    context_code text NOT NULL,
    context_name text,
    description text,
    rules jsonb DEFAULT '{}'::jsonb NOT NULL,
    valid_from timestamp with time zone DEFAULT now() NOT NULL,
    valid_to timestamp with time zone,
    version_id bigint NOT NULL
);


ALTER TABLE meta.context OWNER TO dwmb;

--
-- Name: entity; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.entity (
    entity_id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_code text NOT NULL,
    kind_id uuid NOT NULL,
    status meta.entity_status DEFAULT 'active'::meta.entity_status NOT NULL,
    source_id uuid,
    batch_id uuid,
    owner_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    valid_from timestamp with time zone DEFAULT now() NOT NULL,
    valid_to timestamp with time zone,
    version_id bigint NOT NULL,
    workflow_state text DEFAULT 'published'::text
);


ALTER TABLE meta.entity OWNER TO dwmb;

--
-- Name: entity_kind; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.entity_kind (
    kind_id uuid DEFAULT gen_random_uuid() NOT NULL,
    kind_code text NOT NULL,
    parent_kind_id uuid,
    description text,
    is_abstract boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    version_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    field_schema jsonb DEFAULT '[]'::jsonb
);


ALTER TABLE meta.entity_kind OWNER TO dwmb;

--
-- Name: entity_kind_label; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.entity_kind_label (
    kind_id uuid NOT NULL,
    language meta.language_code NOT NULL,
    label text NOT NULL,
    description text
);


ALTER TABLE meta.entity_kind_label OWNER TO dwmb;

--
-- Name: entity_kind_relation_constraint; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.entity_kind_relation_constraint (
    constraint_id uuid DEFAULT gen_random_uuid() NOT NULL,
    from_kind_id uuid NOT NULL,
    relation_code text NOT NULL,
    to_kind_id uuid NOT NULL,
    is_allowed boolean DEFAULT true NOT NULL,
    description text,
    CONSTRAINT entity_kind_relation_constraint_check CHECK ((from_kind_id <> to_kind_id))
);


ALTER TABLE meta.entity_kind_relation_constraint OWNER TO dwmb;

--
-- Name: entity_label; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.entity_label (
    entity_label_id bigint NOT NULL,
    entity_id uuid NOT NULL,
    language meta.language_code NOT NULL,
    label text NOT NULL,
    description text,
    content text,
    is_primary boolean DEFAULT false NOT NULL,
    owner_id uuid,
    version_id bigint NOT NULL
);


ALTER TABLE meta.entity_label OWNER TO dwmb;

--
-- Name: entity_label_entity_label_id_seq; Type: SEQUENCE; Schema: meta; Owner: dwmb
--

CREATE SEQUENCE meta.entity_label_entity_label_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE meta.entity_label_entity_label_id_seq OWNER TO dwmb;

--
-- Name: entity_label_entity_label_id_seq; Type: SEQUENCE OWNED BY; Schema: meta; Owner: dwmb
--

ALTER SEQUENCE meta.entity_label_entity_label_id_seq OWNED BY meta.entity_label.entity_label_id;


--
-- Name: entity_projection; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.entity_projection (
    projection_id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    model_id uuid NOT NULL,
    template_id uuid,
    context_id uuid,
    projection_code text NOT NULL,
    projection_name text,
    confidence numeric(5,4),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    valid_from timestamp with time zone DEFAULT now() NOT NULL,
    valid_to timestamp with time zone,
    version_id bigint NOT NULL,
    CONSTRAINT entity_projection_confidence_check CHECK (((confidence >= (0)::numeric) AND (confidence <= (1)::numeric)))
);


ALTER TABLE meta.entity_projection OWNER TO dwmb;

--
-- Name: entity_template_assignment; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.entity_template_assignment (
    assignment_id bigint NOT NULL,
    entity_id uuid NOT NULL,
    template_id uuid NOT NULL,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL,
    valid_from timestamp with time zone DEFAULT now() NOT NULL,
    valid_to timestamp with time zone,
    version_id bigint NOT NULL
);


ALTER TABLE meta.entity_template_assignment OWNER TO dwmb;

--
-- Name: entity_template_assignment_assignment_id_seq; Type: SEQUENCE; Schema: meta; Owner: dwmb
--

CREATE SEQUENCE meta.entity_template_assignment_assignment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE meta.entity_template_assignment_assignment_id_seq OWNER TO dwmb;

--
-- Name: entity_template_assignment_assignment_id_seq; Type: SEQUENCE OWNED BY; Schema: meta; Owner: dwmb
--

ALTER SEQUENCE meta.entity_template_assignment_assignment_id_seq OWNED BY meta.entity_template_assignment.assignment_id;


--
-- Name: event_log; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.event_log (
    event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid,
    projection_id uuid,
    relation_id uuid,
    asset_id uuid,
    event_type meta.event_kind NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    caused_by text,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    version_id bigint NOT NULL
);


ALTER TABLE meta.event_log OWNER TO dwmb;

--
-- Name: field_registry; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.field_registry (
    field_id uuid DEFAULT gen_random_uuid() NOT NULL,
    field_key text NOT NULL,
    field_label text NOT NULL,
    field_type text DEFAULT 'string'::text NOT NULL,
    category text DEFAULT 'common'::text NOT NULL,
    default_value text,
    options jsonb DEFAULT '[]'::jsonb,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE meta.field_registry OWNER TO dwmb;

--
-- Name: field_registry_label; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.field_registry_label (
    field_id uuid NOT NULL,
    language meta.language_code NOT NULL,
    label text NOT NULL,
    description text
);


ALTER TABLE meta.field_registry_label OWNER TO dwmb;

--
-- Name: import_batch; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.import_batch (
    batch_id uuid DEFAULT gen_random_uuid() NOT NULL,
    source_id uuid NOT NULL,
    batch_code text,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    finished_at timestamp with time zone,
    items_total integer,
    items_success integer,
    items_failed integer,
    error_log jsonb DEFAULT '[]'::jsonb
);


ALTER TABLE meta.import_batch OWNER TO dwmb;

--
-- Name: media_asset; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.media_asset (
    asset_id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid,
    original_name text NOT NULL,
    mime_type text NOT NULL,
    size_bytes bigint,
    file_hash text NOT NULL,
    storage_backend meta.storage_backend DEFAULT 'local'::meta.storage_backend NOT NULL,
    storage_key text NOT NULL,
    width integer,
    height integer,
    duration_secs numeric(10,3),
    metadata jsonb DEFAULT '{}'::jsonb,
    is_processed boolean DEFAULT false NOT NULL,
    processing_log text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    version_id bigint NOT NULL
);


ALTER TABLE meta.media_asset OWNER TO dwmb;

--
-- Name: menu_item; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.menu_item (
    menu_id uuid DEFAULT gen_random_uuid() NOT NULL,
    parent_id uuid,
    menu_code text DEFAULT 'main'::text NOT NULL,
    label text NOT NULL,
    label_en text,
    url text,
    icon text,
    sort_order integer DEFAULT 0 NOT NULL,
    is_visible boolean DEFAULT true NOT NULL,
    required_role text,
    css_class text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE meta.menu_item OWNER TO dwmb;

--
-- Name: ontology_model; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.ontology_model (
    model_id uuid DEFAULT gen_random_uuid() NOT NULL,
    model_code text NOT NULL,
    domain text NOT NULL,
    description text,
    version_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE meta.ontology_model OWNER TO dwmb;

--
-- Name: ontology_template; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.ontology_template (
    template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    model_id uuid NOT NULL,
    kind_id uuid,
    template_code text NOT NULL,
    template_name text NOT NULL,
    description text,
    schema_definition jsonb NOT NULL,
    layout_definition jsonb DEFAULT '[]'::jsonb NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    constraints_definition jsonb DEFAULT '{}'::jsonb NOT NULL,
    version_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE meta.ontology_template OWNER TO dwmb;

--
-- Name: page_registry; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.page_registry (
    page_id uuid DEFAULT gen_random_uuid() NOT NULL,
    page_code text NOT NULL,
    title text NOT NULL,
    title_en text,
    template_name text DEFAULT 'default'::text NOT NULL,
    content jsonb DEFAULT '{}'::jsonb NOT NULL,
    meta_title text,
    meta_description text,
    is_published boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE meta.page_registry OWNER TO dwmb;

--
-- Name: permission; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.permission (
    permission_id uuid DEFAULT gen_random_uuid() NOT NULL,
    permission_code text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE meta.permission OWNER TO dwmb;

--
-- Name: projection_state; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.projection_state (
    state_id uuid DEFAULT gen_random_uuid() NOT NULL,
    projection_id uuid NOT NULL,
    state_data jsonb NOT NULL,
    state_hash text,
    embedding public.vector(384),
    is_current boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    valid_from timestamp with time zone DEFAULT now() NOT NULL,
    valid_to timestamp with time zone,
    version_id bigint NOT NULL
);


ALTER TABLE meta.projection_state OWNER TO dwmb;

--
-- Name: relation_type; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.relation_type (
    relation_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    relation_code text NOT NULL,
    relation_name text NOT NULL,
    description text,
    from_kind_id uuid,
    to_kind_id uuid,
    directionality meta.relation_direction NOT NULL,
    transitive_relation boolean DEFAULT false NOT NULL,
    symmetric_relation boolean DEFAULT false NOT NULL,
    inverse_type_id uuid,
    version_id bigint NOT NULL
);


ALTER TABLE meta.relation_type OWNER TO dwmb;

--
-- Name: role; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.role (
    role_id uuid DEFAULT gen_random_uuid() NOT NULL,
    role_code text NOT NULL,
    role_name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE meta.role OWNER TO dwmb;

--
-- Name: role_permission; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.role_permission (
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL
);


ALTER TABLE meta.role_permission OWNER TO dwmb;

--
-- Name: semantic_relation; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.semantic_relation (
    relation_id uuid DEFAULT gen_random_uuid() NOT NULL,
    source_projection_id uuid NOT NULL,
    relation_type_id uuid NOT NULL,
    target_projection_id uuid NOT NULL,
    context_id uuid,
    weight numeric(6,5),
    confidence numeric(6,5),
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    valid_from timestamp with time zone DEFAULT now() NOT NULL,
    valid_to timestamp with time zone,
    version_id bigint NOT NULL,
    CONSTRAINT semantic_relation_check CHECK ((source_projection_id <> target_projection_id)),
    CONSTRAINT semantic_relation_confidence_check CHECK (((confidence >= (0)::numeric) AND (confidence <= (1)::numeric))),
    CONSTRAINT semantic_relation_weight_check CHECK (((weight >= (0)::numeric) AND (weight <= (1)::numeric)))
);


ALTER TABLE meta.semantic_relation OWNER TO dwmb;

--
-- Name: source_system; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.source_system (
    source_id uuid DEFAULT gen_random_uuid() NOT NULL,
    source_code text NOT NULL,
    description text,
    is_trusted boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE meta.source_system OWNER TO dwmb;

--
-- Name: user_account; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.user_account (
    user_id uuid DEFAULT gen_random_uuid() NOT NULL,
    username text NOT NULL,
    email text,
    display_name text,
    password_hash text,
    auth_provider text DEFAULT 'local'::text NOT NULL,
    external_id text,
    is_active boolean DEFAULT true NOT NULL,
    is_admin boolean DEFAULT false NOT NULL,
    phone text,
    bio text,
    avatar_url text,
    language_preference meta.language_code DEFAULT 'ru'::meta.language_code,
    theme_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE meta.user_account OWNER TO dwmb;

--
-- Name: user_role; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.user_role (
    user_id uuid NOT NULL,
    role_id uuid NOT NULL
);


ALTER TABLE meta.user_role OWNER TO dwmb;

--
-- Name: user_theme; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.user_theme (
    theme_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    theme_name text NOT NULL,
    is_dark boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    colors jsonb DEFAULT '{"text": "#111827", "error": "#ef4444", "accent": "#f59e0b", "border": "#e5e7eb", "primary": "#3b82f6", "success": "#10b981", "surface": "#f9fafb", "secondary": "#6366f1", "background": "#ffffff", "text_secondary": "#6b7280"}'::jsonb NOT NULL,
    fonts jsonb DEFAULT '{"body": "Inter, sans-serif", "mono": "JetBrains Mono, monospace", "heading": "Inter, sans-serif", "body_size": "0.875rem", "heading_size": "1.5rem"}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE meta.user_theme OWNER TO dwmb;

--
-- Name: version_registry; Type: TABLE; Schema: meta; Owner: dwmb
--

CREATE TABLE meta.version_registry (
    version_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text DEFAULT 'system'::text NOT NULL,
    description text
);


ALTER TABLE meta.version_registry OWNER TO dwmb;

--
-- Name: version_registry_version_id_seq; Type: SEQUENCE; Schema: meta; Owner: dwmb
--

CREATE SEQUENCE meta.version_registry_version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE meta.version_registry_version_id_seq OWNER TO dwmb;

--
-- Name: version_registry_version_id_seq; Type: SEQUENCE OWNED BY; Schema: meta; Owner: dwmb
--

ALTER SEQUENCE meta.version_registry_version_id_seq OWNED BY meta.version_registry.version_id;


--
-- Name: entity_label entity_label_id; Type: DEFAULT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_label ALTER COLUMN entity_label_id SET DEFAULT nextval('meta.entity_label_entity_label_id_seq'::regclass);


--
-- Name: entity_template_assignment assignment_id; Type: DEFAULT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_template_assignment ALTER COLUMN assignment_id SET DEFAULT nextval('meta.entity_template_assignment_assignment_id_seq'::regclass);


--
-- Name: version_registry version_id; Type: DEFAULT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.version_registry ALTER COLUMN version_id SET DEFAULT nextval('meta.version_registry_version_id_seq'::regclass);


--
-- Data for Name: ai_config; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.ai_config (config_id, provider, model_embedding, model_chat, api_key_enc, api_base_url, max_tokens, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: ai_suggestion; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.ai_suggestion (suggestion_id, entity_id, suggestion_type, field_key, suggested_value, confidence, is_accepted, reviewed_by, created_at) FROM stdin;
\.


--
-- Data for Name: ai_task_log; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.ai_task_log (task_id, task_type, model_used, input_tokens, output_tokens, cost_usd, duration_ms, entity_id, status, error_message, payload, created_at) FROM stdin;
\.


--
-- Data for Name: comment; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.comment (comment_id, entity_id, user_id, parent_id, content, is_approved, created_at, updated_at) FROM stdin;
88ae6a4b-703d-4f70-aa6a-2dab0fe31b4f	d0000001-0000-0000-0000-000000000005	a1000000-0000-0000-0000-000000000001	\N	Это первый комментарий	t	2026-07-20 09:38:50.765971+00	2026-07-20 09:38:50.765978+00
b608c53c-c006-4f62-9059-7e05769e501a	d0000001-0000-0000-0000-000000000005	a1000000-0000-0000-0000-000000000001	88ae6a4b-703d-4f70-aa6a-2dab0fe31b4f	а это ответ на первый комментарий	t	2026-07-20 09:39:10.79271+00	2026-07-20 09:39:10.792714+00
443689e6-db1f-42f4-bad5-c5754b1746b7	d0000001-0000-0000-0000-000000000005	a1000000-0000-0000-0000-000000000001	88ae6a4b-703d-4f70-aa6a-2dab0fe31b4f	ответ на ответ на комментарий предполагаю не предусмотрен	t	2026-07-20 09:39:40.037699+00	2026-07-20 09:39:40.037703+00
\.


--
-- Data for Name: context; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.context (context_id, parent_context_id, context_code, context_name, description, rules, valid_from, valid_to, version_id) FROM stdin;
8c3f9ad2-241e-4d66-9a50-2618621356b3	\N	default	Общий контекст	Контекст по умолчанию для всех данных	{}	2026-07-18 09:56:49.88812+00	\N	1
32597b9a-c8e6-4bfa-98df-796a589ea8ad	\N	physics	Физика	Физические процессы и явления	{}	2026-07-18 09:56:49.88812+00	\N	1
e682020c-6114-4456-8d5d-1f5807bd0b2a	\N	biology	Биология	Живые организмы и процессы	{}	2026-07-18 09:56:49.88812+00	\N	1
86cb4a45-28e6-4839-8bea-2ec7b4672e25	\N	chemistry	Химия	Химические элементы и соединения	{}	2026-07-18 09:56:49.88812+00	\N	1
a8b6a9be-e4c2-4f4d-b6db-300c82df54ee	\N	cinema	Кинематограф	Фильмы, актёры, режиссёры	{}	2026-07-18 09:56:49.88812+00	\N	1
3981dfdb-e046-4888-a475-2dbbb0a24532	\N	music	Музыка	Песни, альбомы, исполнители	{}	2026-07-18 09:56:49.88812+00	\N	1
7f02d35e-e021-4bb7-b3a5-569e8419421f	\N	literature	Литература	Книги, статьи, авторы	{}	2026-07-18 09:56:49.88812+00	\N	1
1f21f37a-c707-40e6-b59f-664f33537a4f	\N	geography	География	Города, страны, места	{}	2026-07-18 09:56:49.88812+00	\N	1
108ea37a-2afe-41e9-85f4-def16871fcec	\N	economy	Экономика	Экономические процессы	{}	2026-07-18 09:56:49.88812+00	\N	1
4ee6848d-5e17-480e-a8fa-450c245220e3	\N	history	История	Исторические события и периоды	{}	2026-07-18 09:56:49.88812+00	\N	1
\.


--
-- Data for Name: entity; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.entity (entity_id, entity_code, kind_id, status, source_id, batch_id, owner_id, created_at, updated_at, valid_from, valid_to, version_id, workflow_state) FROM stdin;
d0000001-0000-0000-0000-000000000002	inception	a0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000002-0000-0000-0000-000000000002	leonardo-dicaprio	a0000000-0000-0000-0000-000000000002	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000003-0000-0000-0000-000000000001	wachowskis	a0000000-0000-0000-0000-000000000003	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000003-0000-0000-0000-000000000002	christopher-nolan	a0000000-0000-0000-0000-000000000003	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000004-0000-0000-0000-000000000001	blue-danube	a0000000-0000-0000-0000-000000000004	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000004-0000-0000-0000-000000000002	bohemian-rhapsody	a0000000-0000-0000-0000-000000000004	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000005-0000-0000-0000-000000000001	johann-strauss	a0000000-0000-0000-0000-000000000005	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000005-0000-0000-0000-000000000002	freddie-mercury	a0000000-0000-0000-0000-000000000005	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000006-0000-0000-0000-000000000001	a-night-at-opera	a0000000-0000-0000-0000-000000000006	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000006-0000-0000-0000-000000000002	greatest-hits	a0000000-0000-0000-0000-000000000006	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000007-0000-0000-0000-000000000002	dune	a0000000-0000-0000-0000-000000000007	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000008-0000-0000-0000-000000000001	william-gibson	a0000000-0000-0000-0000-000000000008	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000008-0000-0000-0000-000000000002	frank-herbert	a0000000-0000-0000-0000-000000000008	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000009-0000-0000-0000-000000000001	moscow	a0000000-0000-0000-0000-000000000009	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000009-0000-0000-0000-000000000002	paris	a0000000-0000-0000-0000-000000000009	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000009-0000-0000-0000-000000000003	tokyo	a0000000-0000-0000-0000-000000000009	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000010-0000-0000-0000-000000000001	hydrogen	a0000000-0000-0000-0000-000000000010	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000010-0000-0000-0000-000000000002	oxygen	a0000000-0000-0000-0000-000000000010	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000010-0000-0000-0000-000000000003	carbon	a0000000-0000-0000-0000-000000000010	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000011-0000-0000-0000-000000000001	wolf	a0000000-0000-0000-0000-000000000011	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000011-0000-0000-0000-000000000002	eagle	a0000000-0000-0000-0000-000000000011	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000011-0000-0000-0000-000000000003	dolphin	a0000000-0000-0000-0000-000000000011	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000013-0000-0000-0000-000000000001	cyberpunk	a0000000-0000-0000-0000-000000000013	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000013-0000-0000-0000-000000000002	democracy	a0000000-0000-0000-0000-000000000013	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000013-0000-0000-0000-000000000003	artificial-intelligence	a0000000-0000-0000-0000-000000000013	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000014-0000-0000-0000-000000000001	sci-fi	a0000000-0000-0000-0000-000000000014	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000014-0000-0000-0000-000000000002	classical	a0000000-0000-0000-0000-000000000014	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000026-0000-0000-0000-000000000001	warner-bros	b0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000026-0000-0000-0000-000000000002	paris-opera	b0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000002-0000-0000-0000-000000000003	matt-damon	a0000000-0000-0000-0000-000000000002	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.86655+00	2026-07-18 09:57:12.86655+00	2026-07-18 09:57:12.86655+00	\N	1	published
d0000002-0000-0000-0000-000000000004	scarlett-johansson	a0000000-0000-0000-0000-000000000002	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.86655+00	2026-07-18 09:57:12.86655+00	2026-07-18 09:57:12.86655+00	\N	1	published
d0000002-0000-0000-0000-000000000005	ryan-gosling	a0000000-0000-0000-0000-000000000002	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.86655+00	2026-07-18 09:57:12.86655+00	2026-07-18 09:57:12.86655+00	\N	1	published
d0000003-0000-0000-0000-000000000003	david-fincher	a0000000-0000-0000-0000-000000000003	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.874564+00	2026-07-18 09:57:12.874564+00	2026-07-18 09:57:12.874564+00	\N	1	published
d0000003-0000-0000-0000-000000000004	denis-villeneuve	a0000000-0000-0000-0000-000000000003	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.874564+00	2026-07-18 09:57:12.874564+00	2026-07-18 09:57:12.874564+00	\N	1	published
d0000003-0000-0000-0000-000000000005	ridley-scott	a0000000-0000-0000-0000-000000000003	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.874564+00	2026-07-18 09:57:12.874564+00	2026-07-18 09:57:12.874564+00	\N	1	published
d0000004-0000-0000-0000-000000000003	stairway-to-heaven	a0000000-0000-0000-0000-000000000004	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.882419+00	2026-07-18 09:57:12.882419+00	2026-07-18 09:57:12.882419+00	\N	1	published
d0000004-0000-0000-0000-000000000004	hotel-california	a0000000-0000-0000-0000-000000000004	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.882419+00	2026-07-18 09:57:12.882419+00	2026-07-18 09:57:12.882419+00	\N	1	published
d0000004-0000-0000-0000-000000000005	imagine	a0000000-0000-0000-0000-000000000004	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.882419+00	2026-07-18 09:57:12.882419+00	2026-07-18 09:57:12.882419+00	\N	1	published
d0000005-0000-0000-0000-000000000003	john-lennon	a0000000-0000-0000-0000-000000000005	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.890444+00	2026-07-18 09:57:12.890444+00	2026-07-18 09:57:12.890444+00	\N	1	published
d0000005-0000-0000-0000-000000000004	jimi-hendrix	a0000000-0000-0000-0000-000000000005	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.890444+00	2026-07-18 09:57:12.890444+00	2026-07-18 09:57:12.890444+00	\N	1	published
d0000005-0000-0000-0000-000000000005	elvis-presley	a0000000-0000-0000-0000-000000000005	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.890444+00	2026-07-18 09:57:12.890444+00	2026-07-18 09:57:12.890444+00	\N	1	published
d0000007-0000-0000-0000-000000000004	fahrenheit-451	a0000000-0000-0000-0000-000000000007	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.89906+00	2026-07-18 09:57:12.89906+00	2026-07-18 09:57:12.89906+00	\N	1	published
d0000007-0000-0000-0000-000000000005	brave-new-world	a0000000-0000-0000-0000-000000000007	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.89906+00	2026-07-18 09:57:12.89906+00	2026-07-18 09:57:12.89906+00	\N	1	published
d0000008-0000-0000-0000-000000000003	george-orwell	a0000000-0000-0000-0000-000000000008	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.906897+00	2026-07-18 09:57:12.906897+00	2026-07-18 09:57:12.906897+00	\N	1	published
d0000008-0000-0000-0000-000000000004	ray-bradbury	a0000000-0000-0000-0000-000000000008	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.906897+00	2026-07-18 09:57:12.906897+00	2026-07-18 09:57:12.906897+00	\N	1	published
d0000008-0000-0000-0000-000000000005	aldous-huxley	a0000000-0000-0000-0000-000000000008	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.906897+00	2026-07-18 09:57:12.906897+00	2026-07-18 09:57:12.906897+00	\N	1	published
d0000009-0000-0000-0000-000000000004	london	a0000000-0000-0000-0000-000000000009	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.914506+00	2026-07-18 09:57:12.914506+00	2026-07-18 09:57:12.914506+00	\N	1	published
d0000009-0000-0000-0000-000000000005	new-york	a0000000-0000-0000-0000-000000000009	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.914506+00	2026-07-18 09:57:12.914506+00	2026-07-18 09:57:12.914506+00	\N	1	published
d0000009-0000-0000-0000-000000000006	rome	a0000000-0000-0000-0000-000000000009	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.914506+00	2026-07-18 09:57:12.914506+00	2026-07-18 09:57:12.914506+00	\N	1	published
d0000010-0000-0000-0000-000000000004	iron	a0000000-0000-0000-0000-000000000010	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.922435+00	2026-07-18 09:57:12.922435+00	2026-07-18 09:57:12.922435+00	\N	1	published
d0000010-0000-0000-0000-000000000005	gold	a0000000-0000-0000-0000-000000000010	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.922435+00	2026-07-18 09:57:12.922435+00	2026-07-18 09:57:12.922435+00	\N	1	published
d0000010-0000-0000-0000-000000000006	silver	a0000000-0000-0000-0000-000000000010	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.922435+00	2026-07-18 09:57:12.922435+00	2026-07-18 09:57:12.922435+00	\N	1	published
d0000011-0000-0000-0000-000000000004	tiger	a0000000-0000-0000-0000-000000000011	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.930289+00	2026-07-18 09:57:12.930289+00	2026-07-18 09:57:12.930289+00	\N	1	published
d0000007-0000-0000-0000-000000000003	1984	a0000000-0000-0000-0000-000000000007	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.89906+00	2026-07-18 20:40:08.204722+00	2026-07-18 09:57:12.89906+00	\N	1	published
d0000007-0000-0000-0000-000000000001	neuromancer	a0000000-0000-0000-0000-000000000007	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-18 20:58:43.840752+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000002-0000-0000-0000-000000000001	keanu-reeves	a0000000-0000-0000-0000-000000000002	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-19 10:18:15.923705+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000001-0000-0000-0000-000000000004	fight-club	a0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.852689+00	2026-07-19 12:20:53.434645+00	2026-07-18 09:57:12.852689+00	\N	1	published
d0000001-0000-0000-0000-000000000001	matrix	a0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.383285+00	2026-07-19 13:58:01.971423+00	2026-07-18 09:57:12.383285+00	\N	1	published
d0000011-0000-0000-0000-000000000005	elephant	a0000000-0000-0000-0000-000000000011	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.930289+00	2026-07-18 09:57:12.930289+00	2026-07-18 09:57:12.930289+00	\N	1	published
d0000011-0000-0000-0000-000000000006	penguin	a0000000-0000-0000-0000-000000000011	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.930289+00	2026-07-18 09:57:12.930289+00	2026-07-18 09:57:12.930289+00	\N	1	published
d0000026-0000-0000-0000-000000000003	disney	b0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.941563+00	2026-07-18 09:57:12.941563+00	2026-07-18 09:57:12.941563+00	\N	1	published
d0000026-0000-0000-0000-000000000004	apple-inc	b0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.941563+00	2026-07-18 09:57:12.941563+00	2026-07-18 09:57:12.941563+00	\N	1	published
cee359fa-0d72-4624-9686-33da0e0a42f1	inception_2010	a0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.631692+00	2026-07-18 09:57:20.631692+00	2026-07-18 09:57:20.631692+00	\N	1	published
9526ade9-abd0-4076-be6f-6fd821f33aac	dark_knight_2008	a0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.68556+00	2026-07-18 09:57:20.68556+00	2026-07-18 09:57:20.68556+00	\N	1	published
eb63ed0d-6b3d-495d-97cf-055bdc585459	forrest_gump_1994	a0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.694485+00	2026-07-18 09:57:20.694485+00	2026-07-18 09:57:20.694485+00	\N	1	published
b6bec71b-c05d-48df-8cde-7660d1a41d52	schindlers_list_1993	a0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.703262+00	2026-07-18 09:57:20.703262+00	2026-07-18 09:57:20.703262+00	\N	1	published
fdfdc747-8641-4c4c-84ea-5f31960a9efe	shutter_island_2010	a0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.721361+00	2026-07-18 09:57:20.721361+00	2026-07-18 09:57:20.721361+00	\N	1	published
f542950b-2fee-47b1-94bb-73c83609167f	leonardo_dicaprio	a0000000-0000-0000-0000-000000000002	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.73291+00	2026-07-18 09:57:20.73291+00	2026-07-18 09:57:20.73291+00	\N	1	published
848123f3-d2f3-4a5e-a992-add89081815f	keanu_reeves	a0000000-0000-0000-0000-000000000002	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.74334+00	2026-07-18 09:57:20.74334+00	2026-07-18 09:57:20.74334+00	\N	1	published
dccfaaf8-42b5-46c7-a915-f6b7d5b05fa2	matthew_mcconaughey	a0000000-0000-0000-0000-000000000002	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.754189+00	2026-07-18 09:57:20.754189+00	2026-07-18 09:57:20.754189+00	\N	1	published
ff224547-159e-403e-bd43-359c53d15ba5	brad_pitt	a0000000-0000-0000-0000-000000000002	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.764419+00	2026-07-18 09:57:20.764419+00	2026-07-18 09:57:20.764419+00	\N	1	published
66e7dda6-fc8a-4bae-b864-c54ae4962919	john_travolta	a0000000-0000-0000-0000-000000000002	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.775162+00	2026-07-18 09:57:20.775162+00	2026-07-18 09:57:20.775162+00	\N	1	published
f16dc2ac-4b8a-42f9-a44a-12411e90008d	tom_hardy	a0000000-0000-0000-0000-000000000002	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.787063+00	2026-07-18 09:57:20.787063+00	2026-07-18 09:57:20.787063+00	\N	1	published
73e99bfb-2168-4669-8831-071c97c4e7e4	tom_hanks	a0000000-0000-0000-0000-000000000002	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.796561+00	2026-07-18 09:57:20.796561+00	2026-07-18 09:57:20.796561+00	\N	1	published
96a28808-f001-49fd-8562-834a7f77db83	liam_neeson	a0000000-0000-0000-0000-000000000002	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.805362+00	2026-07-18 09:57:20.805362+00	2026-07-18 09:57:20.805362+00	\N	1	published
8c5def46-791c-4c04-b39f-21a975b5d3da	jamie_fox	a0000000-0000-0000-0000-000000000002	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.815406+00	2026-07-18 09:57:20.815406+00	2026-07-18 09:57:20.815406+00	\N	1	published
d3dbd8f2-19e2-4329-a383-d06fc61e04cc	mark_ruffalo	a0000000-0000-0000-0000-000000000002	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.828292+00	2026-07-18 09:57:20.828292+00	2026-07-18 09:57:20.828292+00	\N	1	published
60d6257f-5730-4868-8733-b3d6a310f8a2	christopher_nolan	a0000000-0000-0000-0000-000000000003	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.842944+00	2026-07-18 09:57:20.842944+00	2026-07-18 09:57:20.842944+00	\N	1	published
23180d0b-81b1-4384-9ba7-e27206bdff02	wachowskis	a0000000-0000-0000-0000-000000000003	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.854624+00	2026-07-18 09:57:20.854624+00	2026-07-18 09:57:20.854624+00	\N	1	published
c7d1a5fe-d2f5-4327-8a0e-01c571310078	david_fincher	a0000000-0000-0000-0000-000000000003	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.865783+00	2026-07-18 09:57:20.865783+00	2026-07-18 09:57:20.865783+00	\N	1	published
449fbd14-7ed0-4aaa-bacf-7811bd48dc5c	quentin_tarantino	a0000000-0000-0000-0000-000000000003	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.876481+00	2026-07-18 09:57:20.876481+00	2026-07-18 09:57:20.876481+00	\N	1	published
4d7f0c0c-de03-499b-a268-695d49237a92	steven_spielberg	a0000000-0000-0000-0000-000000000003	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.889667+00	2026-07-18 09:57:20.889667+00	2026-07-18 09:57:20.889667+00	\N	1	published
1703d7f9-ceb7-4f11-bcd3-d85e1b86b55e	martin_scorsese	a0000000-0000-0000-0000-000000000003	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.901297+00	2026-07-18 09:57:20.901297+00	2026-07-18 09:57:20.901297+00	\N	1	published
f4ee8f84-d477-465b-ab1d-d2cc5335c3ba	ridley_scott	a0000000-0000-0000-0000-000000000003	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.90989+00	2026-07-18 09:57:20.90989+00	2026-07-18 09:57:20.90989+00	\N	1	published
769f85f2-f19e-41c6-b099-078dd11dee55	stanley_kubrick	a0000000-0000-0000-0000-000000000003	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.918435+00	2026-07-18 09:57:20.918435+00	2026-07-18 09:57:20.918435+00	\N	1	published
4a672d0d-29bb-45f3-9ff9-90fd57017633	frank_darabont	a0000000-0000-0000-0000-000000000003	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.928414+00	2026-07-18 09:57:20.928414+00	2026-07-18 09:57:20.928414+00	\N	1	published
dc070982-5f72-4bec-9bc1-aa6eff656900	denis_villeneuve	a0000000-0000-0000-0000-000000000003	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.939339+00	2026-07-18 09:57:20.939339+00	2026-07-18 09:57:20.939339+00	\N	1	published
1496117c-f07f-4c35-8fd2-5b44db1604fe	bohemian_rhapsody	a0000000-0000-0000-0000-000000000004	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.952659+00	2026-07-18 09:57:20.952659+00	2026-07-18 09:57:20.952659+00	\N	1	published
0cf39fee-0df1-44c5-96a6-81b246c1b5d4	stairway_to_heaven	a0000000-0000-0000-0000-000000000004	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.96592+00	2026-07-18 09:57:20.96592+00	2026-07-18 09:57:20.96592+00	\N	1	published
49dd0902-ded3-452e-9cd7-3627778d8391	imagine	a0000000-0000-0000-0000-000000000004	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.978243+00	2026-07-18 09:57:20.978243+00	2026-07-18 09:57:20.978243+00	\N	1	published
a64cda25-19b1-42a6-8eed-55e0be2a9181	hotel_california	a0000000-0000-0000-0000-000000000004	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.989953+00	2026-07-18 09:57:20.989953+00	2026-07-18 09:57:20.989953+00	\N	1	published
80db5106-3ea1-4ef8-b8bd-a4b59250404b	smells_like_teen_spirit	a0000000-0000-0000-0000-000000000004	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.001365+00	2026-07-18 09:57:21.001365+00	2026-07-18 09:57:21.001365+00	\N	1	published
ce8dca5d-1f89-4443-b15a-84c40a01ff40	like_a_rolling_stone	a0000000-0000-0000-0000-000000000004	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.01359+00	2026-07-18 09:57:21.01359+00	2026-07-18 09:57:21.01359+00	\N	1	published
d27be8c9-b14a-42f4-8392-ea44372e5ed6	yesterday	a0000000-0000-0000-0000-000000000004	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.026391+00	2026-07-18 09:57:21.026391+00	2026-07-18 09:57:21.026391+00	\N	1	published
2e74dc73-3343-4cad-9310-e1ee2303cb04	thriller	a0000000-0000-0000-0000-000000000004	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.038482+00	2026-07-18 09:57:21.038482+00	2026-07-18 09:57:21.038482+00	\N	1	published
997258fe-8a0a-4273-bfb2-879a1057dcf9	comfortably_numb	a0000000-0000-0000-0000-000000000004	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.051773+00	2026-07-18 09:57:21.051773+00	2026-07-18 09:57:21.051773+00	\N	1	published
7f559dfa-39be-4d64-ab04-b654c4611bbe	no_woman_no_cry	a0000000-0000-0000-0000-000000000004	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.065838+00	2026-07-18 09:57:21.065838+00	2026-07-18 09:57:21.065838+00	\N	1	published
69edc036-d376-4fab-8bee-67ed2eef51c3	freddie_mercury	a0000000-0000-0000-0000-000000000005	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.081708+00	2026-07-18 09:57:21.081708+00	2026-07-18 09:57:21.081708+00	\N	1	published
c03b986b-dda2-4c30-9cb0-54b61e67438e	jimi_hendrix	a0000000-0000-0000-0000-000000000005	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.094075+00	2026-07-18 09:57:21.094075+00	2026-07-18 09:57:21.094075+00	\N	1	published
3ea280fa-29c3-4c89-9577-6398cf756257	bob_dylan	a0000000-0000-0000-0000-000000000005	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.107457+00	2026-07-18 09:57:21.107457+00	2026-07-18 09:57:21.107457+00	\N	1	published
21a43fa4-af0e-4c7c-b56e-7285a1240cc6	john_lennon	a0000000-0000-0000-0000-000000000005	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.119023+00	2026-07-18 09:57:21.119023+00	2026-07-18 09:57:21.119023+00	\N	1	published
d9184903-40b8-49ba-908e-161fe2174b6c	michael_jackson	a0000000-0000-0000-0000-000000000005	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.130266+00	2026-07-18 09:57:21.130266+00	2026-07-18 09:57:21.130266+00	\N	1	published
fe6098a4-85c4-4762-914b-d07f94736f11	bob_marley	a0000000-0000-0000-0000-000000000005	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.142025+00	2026-07-18 09:57:21.142025+00	2026-07-18 09:57:21.142025+00	\N	1	published
cbfaf521-05ba-4bb1-b10e-7c7cf885adbf	david_gilmour	a0000000-0000-0000-0000-000000000005	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.153415+00	2026-07-18 09:57:21.153415+00	2026-07-18 09:57:21.153415+00	\N	1	published
c45a8ad7-a307-4cd5-8a68-ad311fda0824	kurt_cobain	a0000000-0000-0000-0000-000000000005	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.164233+00	2026-07-18 09:57:21.164233+00	2026-07-18 09:57:21.164233+00	\N	1	published
ed04e968-a812-4eb5-8b0d-eceeb66160fe	elvis_presley	a0000000-0000-0000-0000-000000000005	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.175015+00	2026-07-18 09:57:21.175015+00	2026-07-18 09:57:21.175015+00	\N	1	published
85161a9a-6064-4b4b-baaf-1cf838c0b50e	django_2012	a0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.712221+00	2026-07-18 20:19:08.791276+00	2026-07-18 09:57:20.712221+00	\N	1	published
6df04304-28f0-4f16-a958-056f3b5230bb	fight_club_1999	a0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.667596+00	2026-07-18 20:23:03.165993+00	2026-07-18 09:57:20.667596+00	\N	1	published
eaff2e3b-3670-497e-b6d7-ca54caa660ab	matrix_1999	a0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.644145+00	2026-07-19 10:16:08.796266+00	2026-07-18 09:57:20.644145+00	\N	1	published
a24f87f7-fdf0-4258-862c-c17b89acd938	pulp_fiction_1994	a0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.676629+00	2026-07-19 19:59:45.833802+00	2026-07-18 09:57:20.676629+00	\N	1	published
b2122f3b-815c-471a-9e76-29e35fecee01	ludwig_van_beethoven	a0000000-0000-0000-0000-000000000005	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.189302+00	2026-07-18 09:57:21.189302+00	2026-07-18 09:57:21.189302+00	\N	1	published
01648745-0c99-4cfe-bb8d-acbdeea2e6c4	brave_new_world	a0000000-0000-0000-0000-000000000007	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.218908+00	2026-07-18 09:57:21.218908+00	2026-07-18 09:57:21.218908+00	\N	1	published
bbe028e9-d2b9-41bf-aefb-5f5373b616ba	fahrenheit_451	a0000000-0000-0000-0000-000000000007	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.229+00	2026-07-18 09:57:21.229+00	2026-07-18 09:57:21.229+00	\N	1	published
c42fd1c7-57e3-48f2-a429-94fe8e908f1f	hobbit	a0000000-0000-0000-0000-000000000007	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.240699+00	2026-07-18 09:57:21.240699+00	2026-07-18 09:57:21.240699+00	\N	1	published
c5803f80-ec8f-498e-a0dc-027184d0fc3d	dune	a0000000-0000-0000-0000-000000000007	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.252982+00	2026-07-18 09:57:21.252982+00	2026-07-18 09:57:21.252982+00	\N	1	published
f05470cf-ce25-4bf3-8acf-ac54bb3d2426	master_margarita	a0000000-0000-0000-0000-000000000007	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.26387+00	2026-07-18 09:57:21.26387+00	2026-07-18 09:57:21.26387+00	\N	1	published
c1605c47-91cb-4d46-8a6c-82643625caa8	war_peace	a0000000-0000-0000-0000-000000000007	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.275052+00	2026-07-18 09:57:21.275052+00	2026-07-18 09:57:21.275052+00	\N	1	published
3ad1b264-4c1a-4bab-a47c-7c464bd9fb75	crime_punishment	a0000000-0000-0000-0000-000000000007	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.286459+00	2026-07-18 09:57:21.286459+00	2026-07-18 09:57:21.286459+00	\N	1	published
5ed7d3d6-3486-43c2-bc33-13de728cc779	solaris	a0000000-0000-0000-0000-000000000007	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.298475+00	2026-07-18 09:57:21.298475+00	2026-07-18 09:57:21.298475+00	\N	1	published
472449a5-e0c8-45a2-ba13-8e85fd837166	harry_potter	a0000000-0000-0000-0000-000000000007	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.312583+00	2026-07-18 09:57:21.312583+00	2026-07-18 09:57:21.312583+00	\N	1	published
8803fa13-24d5-4d44-902d-a7a07b54db96	george_orwell	a0000000-0000-0000-0000-000000000008	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.329474+00	2026-07-18 09:57:21.329474+00	2026-07-18 09:57:21.329474+00	\N	1	published
7e50d09d-7cc0-45d7-a458-841fbc4bb306	tolkien	a0000000-0000-0000-0000-000000000008	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.344128+00	2026-07-18 09:57:21.344128+00	2026-07-18 09:57:21.344128+00	\N	1	published
8fbc5a21-3f98-40c0-a787-c43b2aa052ad	bulgakov	a0000000-0000-0000-0000-000000000008	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.35477+00	2026-07-18 09:57:21.35477+00	2026-07-18 09:57:21.35477+00	\N	1	published
78fb1db1-d560-4ade-a8a8-46d51af4c17d	tolstoy	a0000000-0000-0000-0000-000000000008	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.364346+00	2026-07-18 09:57:21.364346+00	2026-07-18 09:57:21.364346+00	\N	1	published
eccd785d-f09d-4eb8-88d7-61477586c60d	dostoevsky	a0000000-0000-0000-0000-000000000008	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.373734+00	2026-07-18 09:57:21.373734+00	2026-07-18 09:57:21.373734+00	\N	1	published
5f4b69e6-1dcc-45eb-a6c3-190613400bc9	stephen_king	a0000000-0000-0000-0000-000000000008	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.38263+00	2026-07-18 09:57:21.38263+00	2026-07-18 09:57:21.38263+00	\N	1	published
e03d486b-140a-4554-bbe8-73a526b9f722	ray_bradbury	a0000000-0000-0000-0000-000000000008	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.391442+00	2026-07-18 09:57:21.391442+00	2026-07-18 09:57:21.391442+00	\N	1	published
f95cb9e8-173b-48df-9514-5952b0a7ecd9	stan_lem	a0000000-0000-0000-0000-000000000008	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.400268+00	2026-07-18 09:57:21.400268+00	2026-07-18 09:57:21.400268+00	\N	1	published
01688b9c-cff6-4480-8e6f-fd665ebed28f	chuck_palahniuk	a0000000-0000-0000-0000-000000000008	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.409328+00	2026-07-18 09:57:21.409328+00	2026-07-18 09:57:21.409328+00	\N	1	published
8d533df6-9672-4f7c-b1be-a853b0381959	new_york	a0000000-0000-0000-0000-000000000009	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.432013+00	2026-07-18 09:57:21.432013+00	2026-07-18 09:57:21.432013+00	\N	1	published
19787a08-7bc6-46b1-9c07-9dc45148704c	london	a0000000-0000-0000-0000-000000000009	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.441437+00	2026-07-18 09:57:21.441437+00	2026-07-18 09:57:21.441437+00	\N	1	published
34245b99-bf0b-4aad-8c0f-a1c26faf531b	paris	a0000000-0000-0000-0000-000000000009	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.452264+00	2026-07-18 09:57:21.452264+00	2026-07-18 09:57:21.452264+00	\N	1	published
1b94695f-bb7e-4fd7-8c29-53c5a161812d	tokyo	a0000000-0000-0000-0000-000000000009	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.46131+00	2026-07-18 09:57:21.46131+00	2026-07-18 09:57:21.46131+00	\N	1	published
8e506f85-3b7d-4f71-93b0-bb6053188fcd	moscow	a0000000-0000-0000-0000-000000000009	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.469976+00	2026-07-18 09:57:21.469976+00	2026-07-18 09:57:21.469976+00	\N	1	published
926600a2-baeb-40e0-a9b3-45f1981cddbc	berlin	a0000000-0000-0000-0000-000000000009	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.478612+00	2026-07-18 09:57:21.478612+00	2026-07-18 09:57:21.478612+00	\N	1	published
15621346-ee2c-4cd0-9ed5-43532377a1cf	los_angeles	a0000000-0000-0000-0000-000000000009	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.48709+00	2026-07-18 09:57:21.48709+00	2026-07-18 09:57:21.48709+00	\N	1	published
cddfd7b4-aec3-4010-8869-5d88317bd6fd	rome	a0000000-0000-0000-0000-000000000009	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.495779+00	2026-07-18 09:57:21.495779+00	2026-07-18 09:57:21.495779+00	\N	1	published
df2cc641-dbb0-41d5-95f1-c2615f69a134	sydney	a0000000-0000-0000-0000-000000000009	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.5043+00	2026-07-18 09:57:21.5043+00	2026-07-18 09:57:21.5043+00	\N	1	published
5c8d82b2-23a8-49c8-abea-9e8b7a351bac	cairo	a0000000-0000-0000-0000-000000000009	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.5133+00	2026-07-18 09:57:21.5133+00	2026-07-18 09:57:21.5133+00	\N	1	published
e9b3e55b-2949-4199-a62f-561d4fcff81a	hydrogen	a0000000-0000-0000-0000-000000000010	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.524839+00	2026-07-18 09:57:21.524839+00	2026-07-18 09:57:21.524839+00	\N	1	published
e77046fa-3c1f-4f25-98c5-71fd3cc5eeb1	helium	a0000000-0000-0000-0000-000000000010	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.53459+00	2026-07-18 09:57:21.53459+00	2026-07-18 09:57:21.53459+00	\N	1	published
a8f5981e-e074-4f55-be73-7cd95387e91c	carbon	a0000000-0000-0000-0000-000000000010	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.543371+00	2026-07-18 09:57:21.543371+00	2026-07-18 09:57:21.543371+00	\N	1	published
eeccd18c-b028-4642-b73f-6027cf48de6a	oxygen	a0000000-0000-0000-0000-000000000010	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.553542+00	2026-07-18 09:57:21.553542+00	2026-07-18 09:57:21.553542+00	\N	1	published
4660dd15-b070-4ce6-b08d-dd04077e1dd6	iron	a0000000-0000-0000-0000-000000000010	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.562272+00	2026-07-18 09:57:21.562272+00	2026-07-18 09:57:21.562272+00	\N	1	published
6f3e4fd5-05e9-4885-8ac5-9adf9930a842	gold	a0000000-0000-0000-0000-000000000010	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.571547+00	2026-07-18 09:57:21.571547+00	2026-07-18 09:57:21.571547+00	\N	1	published
b7615e44-a938-4c65-9626-747afd9f874f	silver	a0000000-0000-0000-0000-000000000010	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.5818+00	2026-07-18 09:57:21.5818+00	2026-07-18 09:57:21.5818+00	\N	1	published
7a168f08-f4ae-4d92-8366-a259e41030ad	copper	a0000000-0000-0000-0000-000000000010	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.595578+00	2026-07-18 09:57:21.595578+00	2026-07-18 09:57:21.595578+00	\N	1	published
fbdeb7a4-0913-4939-ba6c-39de2943925a	silicon	a0000000-0000-0000-0000-000000000010	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.609935+00	2026-07-18 09:57:21.609935+00	2026-07-18 09:57:21.609935+00	\N	1	published
1521e795-f0bf-40a4-8522-9e334399a2a1	uranium	a0000000-0000-0000-0000-000000000010	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.622384+00	2026-07-18 09:57:21.622384+00	2026-07-18 09:57:21.622384+00	\N	1	published
4260b491-39b2-4d11-98e0-c66f9b024e29	african_elephant	a0000000-0000-0000-0000-000000000011	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.637163+00	2026-07-18 09:57:21.637163+00	2026-07-18 09:57:21.637163+00	\N	1	published
9fdd08c5-8ed1-41b6-a801-b05ada603e40	blue_whale	a0000000-0000-0000-0000-000000000011	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.650907+00	2026-07-18 09:57:21.650907+00	2026-07-18 09:57:21.650907+00	\N	1	published
6e00c01b-e63b-4d78-9601-565fc290e271	golden_eagle	a0000000-0000-0000-0000-000000000011	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.664545+00	2026-07-18 09:57:21.664545+00	2026-07-18 09:57:21.664545+00	\N	1	published
178e0a06-8854-4baf-ad7f-8328c8f3da06	gray_wolf	a0000000-0000-0000-0000-000000000011	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.678266+00	2026-07-18 09:57:21.678266+00	2026-07-18 09:57:21.678266+00	\N	1	published
93537e7f-6e85-407b-8f42-8791b6871e31	polar_bear	a0000000-0000-0000-0000-000000000011	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.69098+00	2026-07-18 09:57:21.69098+00	2026-07-18 09:57:21.69098+00	\N	1	published
ff6c4273-2f89-447b-af80-e2a858719f5b	bald_eagle	a0000000-0000-0000-0000-000000000011	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.702378+00	2026-07-18 09:57:21.702378+00	2026-07-18 09:57:21.702378+00	\N	1	published
ce493d5d-b11e-49b8-bfea-054988f6d50d	snow_leopard	a0000000-0000-0000-0000-000000000011	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.713031+00	2026-07-18 09:57:21.713031+00	2026-07-18 09:57:21.713031+00	\N	1	published
3afd0978-487a-4e25-9445-c5baedb40e00	red_panda	a0000000-0000-0000-0000-000000000011	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.723101+00	2026-07-18 09:57:21.723101+00	2026-07-18 09:57:21.723101+00	\N	1	published
70cf6c05-21e8-4a02-8977-87d94734a231	bengal_tiger	a0000000-0000-0000-0000-000000000011	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.734066+00	2026-07-18 09:57:21.734066+00	2026-07-18 09:57:21.734066+00	\N	1	published
7624f2b4-066f-4cac-ab86-766b04debc1f	emperor_penguin	a0000000-0000-0000-0000-000000000011	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.745152+00	2026-07-18 09:57:21.745152+00	2026-07-18 09:57:21.745152+00	\N	1	published
2dcca74c-ae06-4a67-8189-54116ff080b1	sequoia	a0000000-0000-0000-0000-000000000012	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.758143+00	2026-07-18 09:57:21.758143+00	2026-07-18 09:57:21.758143+00	\N	1	published
32e39547-50f5-4435-a0c6-f1f04876848b	baobab	a0000000-0000-0000-0000-000000000012	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.769579+00	2026-07-18 09:57:21.769579+00	2026-07-18 09:57:21.769579+00	\N	1	published
494f1216-d71a-4ab7-be3e-9291040bf88e	giant_kelp	a0000000-0000-0000-0000-000000000012	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.780822+00	2026-07-18 09:57:21.780822+00	2026-07-18 09:57:21.780822+00	\N	1	published
8dbaceed-a2a7-4c9c-b4cd-92202e7ec671	jk_rowling	a0000000-0000-0000-0000-000000000008	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.420299+00	2026-07-18 20:40:34.882924+00	2026-07-18 09:57:21.420299+00	\N	1	published
467ffb2a-3a24-4602-88bc-6e7ab40e2f4a	joshua_tree	a0000000-0000-0000-0000-000000000012	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.791166+00	2026-07-18 09:57:21.791166+00	2026-07-18 09:57:21.791166+00	\N	1	published
595bc463-ce69-4266-b984-623cb3fa1edd	white_oak	a0000000-0000-0000-0000-000000000012	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.802796+00	2026-07-18 09:57:21.802796+00	2026-07-18 09:57:21.802796+00	\N	1	published
e8886070-f942-48a8-a0ae-eb7e02cb6f02	bamboo	a0000000-0000-0000-0000-000000000012	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.813948+00	2026-07-18 09:57:21.813948+00	2026-07-18 09:57:21.813948+00	\N	1	published
aff17dd6-73f1-4cd7-a942-ff407d1defac	giant_sunflower	a0000000-0000-0000-0000-000000000012	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.825306+00	2026-07-18 09:57:21.825306+00	2026-07-18 09:57:21.825306+00	\N	1	published
39f54e29-3882-4ecd-be12-57db727bbf86	royal_palm	a0000000-0000-0000-0000-000000000012	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.837586+00	2026-07-18 09:57:21.837586+00	2026-07-18 09:57:21.837586+00	\N	1	published
f244fdb2-7356-4cb6-ab43-6185c9d9dabd	ginkgo	a0000000-0000-0000-0000-000000000012	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.849908+00	2026-07-18 09:57:21.849908+00	2026-07-18 09:57:21.849908+00	\N	1	published
1eb8cafd-7157-438a-83c2-8b72e51fd32b	venus_flytrap	a0000000-0000-0000-0000-000000000012	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.861746+00	2026-07-18 09:57:21.861746+00	2026-07-18 09:57:21.861746+00	\N	1	published
0c8db544-0346-4678-b1ca-1fc1a135b3d8	abbey_road	a0000000-0000-0000-0000-000000000006	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.874317+00	2026-07-18 09:57:21.874317+00	2026-07-18 09:57:21.874317+00	\N	1	published
54b581ae-2b9b-4108-85c6-553d06429fb6	dark_side_moon	a0000000-0000-0000-0000-000000000006	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.884727+00	2026-07-18 09:57:21.884727+00	2026-07-18 09:57:21.884727+00	\N	1	published
3b6a0e16-9e3e-4677-96b0-3805906570bb	thriller_album	a0000000-0000-0000-0000-000000000006	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.895854+00	2026-07-18 09:57:21.895854+00	2026-07-18 09:57:21.895854+00	\N	1	published
5469017a-120f-4283-9d3a-d825191eaafd	nevermind	a0000000-0000-0000-0000-000000000006	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.906412+00	2026-07-18 09:57:21.906412+00	2026-07-18 09:57:21.906412+00	\N	1	published
bdc5f754-0549-4710-a51e-c93b6f21b168	led_zeppelin_iv	a0000000-0000-0000-0000-000000000006	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.917025+00	2026-07-18 09:57:21.917025+00	2026-07-18 09:57:21.917025+00	\N	1	published
7e42c151-9cdf-4472-b69a-377fc72ff6b4	hotel_california_album	a0000000-0000-0000-0000-000000000006	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.928705+00	2026-07-18 09:57:21.928705+00	2026-07-18 09:57:21.928705+00	\N	1	published
8db8ca3d-43d7-4dad-99b0-55c5da133298	the_wall	a0000000-0000-0000-0000-000000000006	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.940201+00	2026-07-18 09:57:21.940201+00	2026-07-18 09:57:21.940201+00	\N	1	published
31932ca6-473d-4016-a865-cf8f44705dc7	ok_computer	a0000000-0000-0000-0000-000000000006	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.950992+00	2026-07-18 09:57:21.950992+00	2026-07-18 09:57:21.950992+00	\N	1	published
c9d9e0f0-5257-4fba-8587-303ad6fbbd27	rumours	a0000000-0000-0000-0000-000000000006	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.959772+00	2026-07-18 09:57:21.959772+00	2026-07-18 09:57:21.959772+00	\N	1	published
49718987-d935-42db-b3e6-3ef15651e7f1	back_in_black	a0000000-0000-0000-0000-000000000006	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.968185+00	2026-07-18 09:57:21.968185+00	2026-07-18 09:57:21.968185+00	\N	1	published
f70632ea-3cc3-41c8-b0d6-c1c81b8e733c	artificial_intelligence	a0000000-0000-0000-0000-000000000013	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.978694+00	2026-07-18 09:57:21.978694+00	2026-07-18 09:57:21.978694+00	\N	1	published
9693f320-3852-49e3-89dc-0dc685b3cb12	quantum_computing	a0000000-0000-0000-0000-000000000013	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.990229+00	2026-07-18 09:57:21.990229+00	2026-07-18 09:57:21.990229+00	\N	1	published
207dbab2-2833-4b41-82b3-029b50de9c3c	blockchain	a0000000-0000-0000-0000-000000000013	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.002515+00	2026-07-18 09:57:22.002515+00	2026-07-18 09:57:22.002515+00	\N	1	published
3512cdda-6ede-466b-97fe-6d6e38fcd2ac	existentialism	a0000000-0000-0000-0000-000000000013	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.012948+00	2026-07-18 09:57:22.012948+00	2026-07-18 09:57:22.012948+00	\N	1	published
64f99728-90df-40a1-ae15-c07e185c2eba	democracy	a0000000-0000-0000-0000-000000000013	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.024665+00	2026-07-18 09:57:22.024665+00	2026-07-18 09:57:22.024665+00	\N	1	published
6400258b-0021-4456-bea5-ad4ab07f4aed	globalization	a0000000-0000-0000-0000-000000000013	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.036802+00	2026-07-18 09:57:22.036802+00	2026-07-18 09:57:22.036802+00	\N	1	published
5ea88755-26e9-4ddb-a1a8-7fb956a9ae8a	renaissance	a0000000-0000-0000-0000-000000000013	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.049466+00	2026-07-18 09:57:22.049466+00	2026-07-18 09:57:22.049466+00	\N	1	published
fb23ce73-4dbe-4dc3-bea8-35438f725765	climate_change	a0000000-0000-0000-0000-000000000013	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.063298+00	2026-07-18 09:57:22.063298+00	2026-07-18 09:57:22.063298+00	\N	1	published
7c7f0ff5-5849-47ad-bd2d-91f9fbea99a1	surrealism	a0000000-0000-0000-0000-000000000013	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.075492+00	2026-07-18 09:57:22.075492+00	2026-07-18 09:57:22.075492+00	\N	1	published
cdc02526-45c8-40c0-9648-e1301798825a	stoicism	a0000000-0000-0000-0000-000000000013	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.086917+00	2026-07-18 09:57:22.086917+00	2026-07-18 09:57:22.086917+00	\N	1	published
929628d4-a955-4645-9a0b-bc4a861ba8bd	sci_fi	a0000000-0000-0000-0000-000000000014	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.099804+00	2026-07-18 09:57:22.099804+00	2026-07-18 09:57:22.099804+00	\N	1	published
9730c0fa-e351-4c1f-9b78-c7edd1e1337a	noir	a0000000-0000-0000-0000-000000000014	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.110298+00	2026-07-18 09:57:22.110298+00	2026-07-18 09:57:22.110298+00	\N	1	published
2800ae7e-b7f9-4475-9684-bbfba0dc2906	progressive_rock	a0000000-0000-0000-0000-000000000014	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.121384+00	2026-07-18 09:57:22.121384+00	2026-07-18 09:57:22.121384+00	\N	1	published
21439c77-30ed-4b20-a353-f6bf66826412	grunge	a0000000-0000-0000-0000-000000000014	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.132482+00	2026-07-18 09:57:22.132482+00	2026-07-18 09:57:22.132482+00	\N	1	published
f09dba17-9dad-4a4b-bb7c-0850f412740d	dystopia_genre	a0000000-0000-0000-0000-000000000014	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.143515+00	2026-07-18 09:57:22.143515+00	2026-07-18 09:57:22.143515+00	\N	1	published
7ec1f5cb-47dc-47cb-a2dd-a2c4a8c361b9	reggae	a0000000-0000-0000-0000-000000000014	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.15683+00	2026-07-18 09:57:22.15683+00	2026-07-18 09:57:22.15683+00	\N	1	published
8c23ab7d-4927-4cd8-baa4-c349ac078fa2	hard_rock	a0000000-0000-0000-0000-000000000014	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.169669+00	2026-07-18 09:57:22.169669+00	2026-07-18 09:57:22.169669+00	\N	1	published
b78f5b78-fc9f-4bba-9d2f-be0c98a53c9b	impressionism	a0000000-0000-0000-0000-000000000014	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.181056+00	2026-07-18 09:57:22.181056+00	2026-07-18 09:57:22.181056+00	\N	1	published
2ec9a308-af86-4a01-a3ed-1710a5ac21dd	baroque	a0000000-0000-0000-0000-000000000014	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.19205+00	2026-07-18 09:57:22.19205+00	2026-07-18 09:57:22.19205+00	\N	1	published
94651f3c-c40a-4f85-a4e4-f21ba3737283	cyberpunk	a0000000-0000-0000-0000-000000000014	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.204179+00	2026-07-18 09:57:22.204179+00	2026-07-18 09:57:22.204179+00	\N	1	published
e123000b-8bdb-49dc-a694-14330b7878c9	aurora_borealis	a0000000-0000-0000-0000-000000000015	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.218872+00	2026-07-18 09:57:22.218872+00	2026-07-18 09:57:22.218872+00	\N	1	published
e7fdeb64-4db0-48fc-b2cb-bebd928dbd27	gravity	a0000000-0000-0000-0000-000000000015	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.232297+00	2026-07-18 09:57:22.232297+00	2026-07-18 09:57:22.232297+00	\N	1	published
8f6afea3-9bb8-4d9e-9265-31cf569b1c39	photosynthesis	a0000000-0000-0000-0000-000000000015	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.245165+00	2026-07-18 09:57:22.245165+00	2026-07-18 09:57:22.245165+00	\N	1	published
afeb44a8-f93d-441b-b89f-fb51d1c9302f	evolution	a0000000-0000-0000-0000-000000000015	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.256471+00	2026-07-18 09:57:22.256471+00	2026-07-18 09:57:22.256471+00	\N	1	published
32b62974-af60-4ad1-853f-4b1e232d24a6	quantum_entanglement	a0000000-0000-0000-0000-000000000015	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.267368+00	2026-07-18 09:57:22.267368+00	2026-07-18 09:57:22.267368+00	\N	1	published
f895fc34-79da-4fe2-81d9-5fc885a8096b	black_hole	a0000000-0000-0000-0000-000000000015	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.280666+00	2026-07-18 09:57:22.280666+00	2026-07-18 09:57:22.280666+00	\N	1	published
23509af3-2a16-464d-ae37-17d962c7301d	tornado	a0000000-0000-0000-0000-000000000015	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.293932+00	2026-07-18 09:57:22.293932+00	2026-07-18 09:57:22.293932+00	\N	1	published
c4278647-d60c-4e2d-af89-6aae8bf5c233	continental_drift	a0000000-0000-0000-0000-000000000015	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.306213+00	2026-07-18 09:57:22.306213+00	2026-07-18 09:57:22.306213+00	\N	1	published
21f5acd5-5d9a-414f-8692-14b59869f7f2	photosynthesis_process	a0000000-0000-0000-0000-000000000015	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.31844+00	2026-07-18 09:57:22.31844+00	2026-07-18 09:57:22.31844+00	\N	1	published
7dbf9236-1dd5-4785-abbd-92d3f0808d65	aurora_australis	a0000000-0000-0000-0000-000000000015	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.329905+00	2026-07-18 09:57:22.329905+00	2026-07-18 09:57:22.329905+00	\N	1	published
2bd7a0b0-1e4b-4182-ab53-8f4a20e41f64	ancient_rome	a0000000-0000-0000-0000-000000000016	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.343614+00	2026-07-18 09:57:22.343614+00	2026-07-18 09:57:22.343614+00	\N	1	published
b170a449-4c28-467a-b410-611bb5c9b460	middle_ages	a0000000-0000-0000-0000-000000000016	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.353928+00	2026-07-18 09:57:22.353928+00	2026-07-18 09:57:22.353928+00	\N	1	published
bf444bcd-f2c5-4bd0-8d3f-503214fb8171	industrial_revolution	a0000000-0000-0000-0000-000000000016	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.36256+00	2026-07-18 09:57:22.36256+00	2026-07-18 09:57:22.36256+00	\N	1	published
45457d27-05b9-4509-b7cb-445e0dd5e29a	cold_war	a0000000-0000-0000-0000-000000000016	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.371458+00	2026-07-18 09:57:22.371458+00	2026-07-18 09:57:22.371458+00	\N	1	published
6db2b35a-441a-4701-aef5-4a7d5a4d1887	renaissance_period	a0000000-0000-0000-0000-000000000016	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.379836+00	2026-07-18 09:57:22.379836+00	2026-07-18 09:57:22.379836+00	\N	1	published
8a72467e-4dfd-4696-890b-e82afd0d15ad	age_of_enlightenment	a0000000-0000-0000-0000-000000000016	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.388251+00	2026-07-18 09:57:22.388251+00	2026-07-18 09:57:22.388251+00	\N	1	published
cf3be10d-89e3-4104-b444-6f3161c09f6c	digital_age	a0000000-0000-0000-0000-000000000016	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.396698+00	2026-07-18 09:57:22.396698+00	2026-07-18 09:57:22.396698+00	\N	1	published
b7f70d7a-6a4c-44df-ae95-b6b71cfd39b9	space_age	a0000000-0000-0000-0000-000000000016	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.408681+00	2026-07-18 09:57:22.408681+00	2026-07-18 09:57:22.408681+00	\N	1	published
c18b2fcf-017d-464b-b29a-3c2fd2dfd156	world_war_2	a0000000-0000-0000-0000-000000000016	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.419341+00	2026-07-18 09:57:22.419341+00	2026-07-18 09:57:22.419341+00	\N	1	published
8564232e-640e-42c5-a1df-0a339d9a409d	victorian_era	a0000000-0000-0000-0000-000000000016	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.428461+00	2026-07-18 09:57:22.428461+00	2026-07-18 09:57:22.428461+00	\N	1	published
9787517a-941a-4525-af34-d54132e601d9	readme_md	a0000000-0000-0000-0000-000000000017	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.439277+00	2026-07-18 09:57:22.439277+00	2026-07-18 09:57:22.439277+00	\N	1	published
ba56c9e9-ebf9-4d8c-8a23-ccfcc0951afc	schema_sql	a0000000-0000-0000-0000-000000000017	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.448344+00	2026-07-18 09:57:22.448344+00	2026-07-18 09:57:22.448344+00	\N	1	published
5a5da171-ced3-445b-882a-d2ec2c0873b8	config_yaml	a0000000-0000-0000-0000-000000000017	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.457481+00	2026-07-18 09:57:22.457481+00	2026-07-18 09:57:22.457481+00	\N	1	published
0664ab1a-77dd-46a7-a6e4-a80a7ea542d1	docker_compose	a0000000-0000-0000-0000-000000000017	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.466807+00	2026-07-18 09:57:22.466807+00	2026-07-18 09:57:22.466807+00	\N	1	published
3a4baf0a-e14c-4c20-a5d2-12c50e76cf57	main_py	a0000000-0000-0000-0000-000000000017	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.475986+00	2026-07-18 09:57:22.475986+00	2026-07-18 09:57:22.475986+00	\N	1	published
ba858154-8c3f-4f37-8bff-35c076aa8ada	models_py	a0000000-0000-0000-0000-000000000017	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.485416+00	2026-07-18 09:57:22.485416+00	2026-07-18 09:57:22.485416+00	\N	1	published
b17d8c52-7170-4605-85a4-72531eff1b3f	requirements_txt	a0000000-0000-0000-0000-000000000017	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.494398+00	2026-07-18 09:57:22.494398+00	2026-07-18 09:57:22.494398+00	\N	1	published
c85aa10c-655f-44f9-ae8a-1e430522ab2d	dockerfile	a0000000-0000-0000-0000-000000000017	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.503541+00	2026-07-18 09:57:22.503541+00	2026-07-18 09:57:22.503541+00	\N	1	published
1253e359-3cf0-49d2-a279-d3153b4f00fe	index_html	a0000000-0000-0000-0000-000000000017	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.512186+00	2026-07-18 09:57:22.512186+00	2026-07-18 09:57:22.512186+00	\N	1	published
2b10e601-f4ac-4ae8-8ded-acb1d1571151	style_css	a0000000-0000-0000-0000-000000000017	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.52063+00	2026-07-18 09:57:22.52063+00	2026-07-18 09:57:22.52063+00	\N	1	published
e14ae6a8-376a-4339-973c-fa37cfbb1543	beat_generation	a0000000-0000-0000-0000-000000000018	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.5322+00	2026-07-18 09:57:22.5322+00	2026-07-18 09:57:22.5322+00	\N	1	published
f6ccda96-7cd1-4d68-b756-9db1d84a6f0c	romanticism	a0000000-0000-0000-0000-000000000018	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.542432+00	2026-07-18 09:57:22.542432+00	2026-07-18 09:57:22.542432+00	\N	1	published
9a36665c-a89a-4829-b6a7-102628d64b9a	cubism	a0000000-0000-0000-0000-000000000018	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.552344+00	2026-07-18 09:57:22.552344+00	2026-07-18 09:57:22.552344+00	\N	1	published
3ddb497c-72f1-4046-9264-d29911798e31	punk_rock	a0000000-0000-0000-0000-000000000018	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.561056+00	2026-07-18 09:57:22.561056+00	2026-07-18 09:57:22.561056+00	\N	1	published
99738373-5e27-466b-9e8c-d18b1d91e6e1	impressionism_movement	a0000000-0000-0000-0000-000000000018	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.569333+00	2026-07-18 09:57:22.569333+00	2026-07-18 09:57:22.569333+00	\N	1	published
dd3c64a4-6feb-4c74-ae8a-29764dab4e11	existentialism_movement	a0000000-0000-0000-0000-000000000018	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.580556+00	2026-07-18 09:57:22.580556+00	2026-07-18 09:57:22.580556+00	\N	1	published
8483b889-21b6-4839-9b51-4845ae59e581	minimalism	a0000000-0000-0000-0000-000000000018	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.588557+00	2026-07-18 09:57:22.588557+00	2026-07-18 09:57:22.588557+00	\N	1	published
fc17dbbf-4e4a-48f4-aa77-28fabb1f19de	hippie_movement	a0000000-0000-0000-0000-000000000018	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.596851+00	2026-07-18 09:57:22.596851+00	2026-07-18 09:57:22.596851+00	\N	1	published
387a24fa-f1d9-4737-8e54-f4a69578669b	surrealism_movement	a0000000-0000-0000-0000-000000000018	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.605426+00	2026-07-18 09:57:22.605426+00	2026-07-18 09:57:22.605426+00	\N	1	published
b1f651d7-dbcd-48d2-8cbb-f29891f34d65	renaissance_movement	a0000000-0000-0000-0000-000000000018	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.616059+00	2026-07-18 09:57:22.616059+00	2026-07-18 09:57:22.616059+00	\N	1	published
3b0eda53-895f-4ea5-9204-406250784d76	dewey_decimal	a0000000-0000-0000-0000-000000000019	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.625992+00	2026-07-18 09:57:22.625992+00	2026-07-18 09:57:22.625992+00	\N	1	published
1c9d6f07-3e36-4463-97c5-b5e92f6543a6	iso_3166	a0000000-0000-0000-0000-000000000019	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.63426+00	2026-07-18 09:57:22.63426+00	2026-07-18 09:57:22.63426+00	\N	1	published
a853de21-1a72-4c42-9a67-e2881ca2045d	un_class	a0000000-0000-0000-0000-000000000019	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.645068+00	2026-07-18 09:57:22.645068+00	2026-07-18 09:57:22.645068+00	\N	1	published
6d983558-d3db-4047-8e24-6eed32da6c34	iso_639	a0000000-0000-0000-0000-000000000019	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.656641+00	2026-07-18 09:57:22.656641+00	2026-07-18 09:57:22.656641+00	\N	1	published
1429e676-43c3-4639-a5ed-b5aa42a0fc9f	periodic_table	a0000000-0000-0000-0000-000000000019	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.667813+00	2026-07-18 09:57:22.667813+00	2026-07-18 09:57:22.667813+00	\N	1	published
2b840df2-219a-4b5c-8b08-5dddf8b262e1	icd10	a0000000-0000-0000-0000-000000000019	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.676922+00	2026-07-18 09:57:22.676922+00	2026-07-18 09:57:22.676922+00	\N	1	published
995359be-1c66-40e0-8485-4ae46a31833d	linnaeus	a0000000-0000-0000-0000-000000000019	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.686823+00	2026-07-18 09:57:22.686823+00	2026-07-18 09:57:22.686823+00	\N	1	published
75d72ab4-af98-4bfb-895a-d9506b772556	bib	a0000000-0000-0000-0000-000000000019	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.696862+00	2026-07-18 09:57:22.696862+00	2026-07-18 09:57:22.696862+00	\N	1	published
87e67f23-ea6c-4386-8b25-d05592d13f07	nace	a0000000-0000-0000-0000-000000000019	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.70546+00	2026-07-18 09:57:22.70546+00	2026-07-18 09:57:22.70546+00	\N	1	published
9cff73c5-192f-4c24-ae22-55410dfb84ee	atc	a0000000-0000-0000-0000-000000000019	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.713823+00	2026-07-18 09:57:22.713823+00	2026-07-18 09:57:22.713823+00	\N	1	published
32463c6e-d667-4a73-947d-f17b775cba40	rosetta_stone	a0000000-0000-0000-0000-000000000020	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.723554+00	2026-07-18 09:57:22.723554+00	2026-07-18 09:57:22.723554+00	\N	1	published
53129942-9866-4b71-a11f-3fb0b46bcb90	mona_lisa	a0000000-0000-0000-0000-000000000020	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.731849+00	2026-07-18 09:57:22.731849+00	2026-07-18 09:57:22.731849+00	\N	1	published
26cfcd3a-4a6e-4060-b5b2-869059eee7e9	great_wall	a0000000-0000-0000-0000-000000000020	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.73998+00	2026-07-18 09:57:22.73998+00	2026-07-18 09:57:22.73998+00	\N	1	published
8a45830b-ad78-4487-89b0-ee7a962015a2	pyramid_giza	a0000000-0000-0000-0000-000000000020	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.751192+00	2026-07-18 09:57:22.751192+00	2026-07-18 09:57:22.751192+00	\N	1	published
f50a0a19-4fb6-4125-b054-34a59fdde08e	colosseum	a0000000-0000-0000-0000-000000000020	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.759866+00	2026-07-18 09:57:22.759866+00	2026-07-18 09:57:22.759866+00	\N	1	published
16180497-666f-434d-bc7a-37bef39d6225	stonehenge	a0000000-0000-0000-0000-000000000020	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.768242+00	2026-07-18 09:57:22.768242+00	2026-07-18 09:57:22.768242+00	\N	1	published
e6f19811-6f9f-4482-a529-2f3f8fb9e149	taj_mahal	a0000000-0000-0000-0000-000000000020	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.776337+00	2026-07-18 09:57:22.776337+00	2026-07-18 09:57:22.776337+00	\N	1	published
1d2041fd-963a-4a0e-852a-b76f18b9d263	eiffel_tower	a0000000-0000-0000-0000-000000000020	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.78678+00	2026-07-18 09:57:22.78678+00	2026-07-18 09:57:22.78678+00	\N	1	published
17eb8177-4cb8-44cc-844e-280e2b6e34c6	liberty_statue	a0000000-0000-0000-0000-000000000020	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.795735+00	2026-07-18 09:57:22.795735+00	2026-07-18 09:57:22.795735+00	\N	1	published
ff76ceeb-039c-4ad8-999d-7df99e8e7a47	parthenon	a0000000-0000-0000-0000-000000000020	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.803906+00	2026-07-18 09:57:22.803906+00	2026-07-18 09:57:22.803906+00	\N	1	published
192fa802-8d30-4838-a13a-e76acd3d5da4	afghan_girl	a0000000-0000-0000-0000-000000000021	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.81363+00	2026-07-18 09:57:22.81363+00	2026-07-18 09:57:22.81363+00	\N	1	published
c563b603-4af0-4b7c-9f7c-3fd70402e0d4	earthrise	a0000000-0000-0000-0000-000000000021	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.821867+00	2026-07-18 09:57:22.821867+00	2026-07-18 09:57:22.821867+00	\N	1	published
7900ac07-0528-470c-aded-4760fb15d894	v_j_day	a0000000-0000-0000-0000-000000000021	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.832122+00	2026-07-18 09:57:22.832122+00	2026-07-18 09:57:22.832122+00	\N	1	published
2c9edd9d-77c3-4839-9f12-46c2e252a5aa	pale_blue_dot	a0000000-0000-0000-0000-000000000021	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.840546+00	2026-07-18 09:57:22.840546+00	2026-07-18 09:57:22.840546+00	\N	1	published
18b40d02-87ec-4497-8b58-19e8f574d6cf	migrant_mother	a0000000-0000-0000-0000-000000000021	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.849284+00	2026-07-18 09:57:22.849284+00	2026-07-18 09:57:22.849284+00	\N	1	published
8d600c86-9e46-487c-91fa-e688407d990c	lunch_atop_skyscraper	a0000000-0000-0000-0000-000000000021	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.85855+00	2026-07-18 09:57:22.85855+00	2026-07-18 09:57:22.85855+00	\N	1	published
40a23b6d-f3b6-465f-ae9c-4b0ce56dfad2	flower_power	a0000000-0000-0000-0000-000000000021	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.868501+00	2026-07-18 09:57:22.868501+00	2026-07-18 09:57:22.868501+00	\N	1	published
cfd62e03-5400-47f5-95b2-8f53c1f33075	the_kiss	a0000000-0000-0000-0000-000000000021	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.880706+00	2026-07-18 09:57:22.880706+00	2026-07-18 09:57:22.880706+00	\N	1	published
6b9add19-73e1-4cf3-bb86-efbc215af007	vulture_child	a0000000-0000-0000-0000-000000000021	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.894633+00	2026-07-18 09:57:22.894633+00	2026-07-18 09:57:22.894633+00	\N	1	published
b837ade1-ac04-4ed3-a631-8a6b9c2e5291	field_translator	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	60	published
36ea6a1f-dd51-4f8a-94c7-8d1ce60f9ce1	hubble_deep_field	a0000000-0000-0000-0000-000000000021	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.907368+00	2026-07-18 09:57:22.907368+00	2026-07-18 09:57:22.907368+00	\N	1	published
30ead965-9b99-451f-b4db-2e192fb7aded	theory_relativity	a0000000-0000-0000-0000-000000000022	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.923399+00	2026-07-18 09:57:22.923399+00	2026-07-18 09:57:22.923399+00	\N	1	published
b1cef78e-be21-441b-9add-4af5569ac6b0	origin_of_species	a0000000-0000-0000-0000-000000000022	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.93695+00	2026-07-18 09:57:22.93695+00	2026-07-18 09:57:22.93695+00	\N	1	published
7d3c1b4d-0714-450f-a06b-9648b9cf2d90	communist_manifesto	a0000000-0000-0000-0000-000000000022	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.948463+00	2026-07-18 09:57:22.948463+00	2026-07-18 09:57:22.948463+00	\N	1	published
c2b27452-d479-4382-a750-93977d2b0e4a	republic_plato	a0000000-0000-0000-0000-000000000022	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.957885+00	2026-07-18 09:57:22.957885+00	2026-07-18 09:57:22.957885+00	\N	1	published
4c122d28-61f6-4d69-b58f-d1d1dec02d02	principia	a0000000-0000-0000-0000-000000000022	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.967453+00	2026-07-18 09:57:22.967453+00	2026-07-18 09:57:22.967453+00	\N	1	published
55d799fd-74d0-4545-93a0-539d3d44b700	critique_pure_reason	a0000000-0000-0000-0000-000000000022	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.976563+00	2026-07-18 09:57:22.976563+00	2026-07-18 09:57:22.976563+00	\N	1	published
b75c64b8-a707-41be-afc0-a585bde7e9b2	wealth_of_nations	a0000000-0000-0000-0000-000000000022	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.985731+00	2026-07-18 09:57:22.985731+00	2026-07-18 09:57:22.985731+00	\N	1	published
8b15e1c0-3472-420b-9b1a-8c1d5944e62c	two_treatises	a0000000-0000-0000-0000-000000000022	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:22.994816+00	2026-07-18 09:57:22.994816+00	2026-07-18 09:57:22.994816+00	\N	1	published
0825a264-83a9-4413-bf50-a77c31ee2580	the_wealth	a0000000-0000-0000-0000-000000000022	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.003278+00	2026-07-18 09:57:23.003278+00	2026-07-18 09:57:23.003278+00	\N	1	published
c770f360-33dc-45c2-b811-ab856cc0fc30	das_kapital	a0000000-0000-0000-0000-000000000022	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.011428+00	2026-07-18 09:57:23.011428+00	2026-07-18 09:57:23.011428+00	\N	1	published
42cac073-bfd6-420e-89a2-5eab703042b6	albert_einstein	a0000000-0000-0000-0000-000000000023	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.021543+00	2026-07-18 09:57:23.021543+00	2026-07-18 09:57:23.021543+00	\N	1	published
739f01e6-af8e-49b4-9834-b2d981eda3c3	leonardo_da_vinci	a0000000-0000-0000-0000-000000000023	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.031714+00	2026-07-18 09:57:23.031714+00	2026-07-18 09:57:23.031714+00	\N	1	published
4c2a367e-3250-4e23-92a7-d25231d5baef	isaac_newton	a0000000-0000-0000-0000-000000000023	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.042109+00	2026-07-18 09:57:23.042109+00	2026-07-18 09:57:23.042109+00	\N	1	published
d0f8a70b-b1f7-48f4-95e6-3c58e4a86b2b	nikola_tesla	a0000000-0000-0000-0000-000000000023	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.052624+00	2026-07-18 09:57:23.052624+00	2026-07-18 09:57:23.052624+00	\N	1	published
7f3107e7-796b-490f-869a-5d71521bc46e	marie_curie	a0000000-0000-0000-0000-000000000023	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.062273+00	2026-07-18 09:57:23.062273+00	2026-07-18 09:57:23.062273+00	\N	1	published
c744a36a-9aa5-4d60-8896-242132e90ac5	charles_darwin	a0000000-0000-0000-0000-000000000023	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.071586+00	2026-07-18 09:57:23.071586+00	2026-07-18 09:57:23.071586+00	\N	1	published
602e8d7d-ec89-4c85-80cf-7ae822b18f58	plato	a0000000-0000-0000-0000-000000000023	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.082225+00	2026-07-18 09:57:23.082225+00	2026-07-18 09:57:23.082225+00	\N	1	published
92039fd9-1eaa-4d7e-ac10-268281afd9ac	shakespeare	a0000000-0000-0000-0000-000000000023	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.093148+00	2026-07-18 09:57:23.093148+00	2026-07-18 09:57:23.093148+00	\N	1	published
4ad80497-ccd6-4371-ab57-96d8b91e9a09	confucius	a0000000-0000-0000-0000-000000000023	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.104886+00	2026-07-18 09:57:23.104886+00	2026-07-18 09:57:23.104886+00	\N	1	published
04ca95fc-d46c-41a1-bb8a-a9932fdc0fbb	mahatma_gandhi	a0000000-0000-0000-0000-000000000023	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.116728+00	2026-07-18 09:57:23.116728+00	2026-07-18 09:57:23.116728+00	\N	1	published
8a532ed1-c830-427c-a8ad-2e73a4f3a0b2	picasso	a0000000-0000-0000-0000-000000000024	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.129824+00	2026-07-18 09:57:23.129824+00	2026-07-18 09:57:23.129824+00	\N	1	published
f9650917-3e26-4be7-a635-ef4886cbc18f	van_gogh	a0000000-0000-0000-0000-000000000024	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.141111+00	2026-07-18 09:57:23.141111+00	2026-07-18 09:57:23.141111+00	\N	1	published
1de91eb3-e5ed-439f-9630-b14cb1abf490	monet	a0000000-0000-0000-0000-000000000024	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.153759+00	2026-07-18 09:57:23.153759+00	2026-07-18 09:57:23.153759+00	\N	1	published
bab8e621-eb12-4d5c-9f1d-6bcdefb375a0	michelangelo	a0000000-0000-0000-0000-000000000024	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.165458+00	2026-07-18 09:57:23.165458+00	2026-07-18 09:57:23.165458+00	\N	1	published
6d43a160-64d9-431f-ad10-8b012f01f15b	rembrandt	a0000000-0000-0000-0000-000000000024	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.176668+00	2026-07-18 09:57:23.176668+00	2026-07-18 09:57:23.176668+00	\N	1	published
bea2edde-5ade-474a-b441-ff5ef24a6627	salvador_dali	a0000000-0000-0000-0000-000000000024	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.188036+00	2026-07-18 09:57:23.188036+00	2026-07-18 09:57:23.188036+00	\N	1	published
ce480988-cdc7-4ce0-9e70-9d0422f85c3a	andy_warhol	a0000000-0000-0000-0000-000000000024	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.199588+00	2026-07-18 09:57:23.199588+00	2026-07-18 09:57:23.199588+00	\N	1	published
5901e379-0867-4b89-aa06-5741498f67e7	frida_kahlo	a0000000-0000-0000-0000-000000000024	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.209631+00	2026-07-18 09:57:23.209631+00	2026-07-18 09:57:23.209631+00	\N	1	published
29d6595c-a8df-49df-912b-555eb61dc11c	kandinsky	a0000000-0000-0000-0000-000000000024	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.220549+00	2026-07-18 09:57:23.220549+00	2026-07-18 09:57:23.220549+00	\N	1	published
bf8fa84f-ed54-41e4-9a47-bd082fd9c6df	caravaggio	a0000000-0000-0000-0000-000000000024	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.230322+00	2026-07-18 09:57:23.230322+00	2026-07-18 09:57:23.230322+00	\N	1	published
51db8499-cdd6-48b8-ae65-e05a29e3a2e8	stephen_hawking	a0000000-0000-0000-0000-000000000025	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.241165+00	2026-07-18 09:57:23.241165+00	2026-07-18 09:57:23.241165+00	\N	1	published
b5cddb03-0bb2-43d3-ac04-c7b2c70c53df	richard_feynman	a0000000-0000-0000-0000-000000000025	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.251858+00	2026-07-18 09:57:23.251858+00	2026-07-18 09:57:23.251858+00	\N	1	published
1af61118-34a1-4bf9-8988-26f85ba06f48	darwin_scientist	a0000000-0000-0000-0000-000000000025	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.262889+00	2026-07-18 09:57:23.262889+00	2026-07-18 09:57:23.262889+00	\N	1	published
7cc15fa4-879b-456b-8481-63cd73605e34	niels_bohr	a0000000-0000-0000-0000-000000000025	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.272038+00	2026-07-18 09:57:23.272038+00	2026-07-18 09:57:23.272038+00	\N	1	published
4e603c34-e64c-4cb9-bf8a-f73a36ca1b39	max_planck	a0000000-0000-0000-0000-000000000025	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.280868+00	2026-07-18 09:57:23.280868+00	2026-07-18 09:57:23.280868+00	\N	1	published
d8e2ddde-de40-40bc-a501-f9818e0b7cf6	dmitri_mendeleev	a0000000-0000-0000-0000-000000000025	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.290171+00	2026-07-18 09:57:23.290171+00	2026-07-18 09:57:23.290171+00	\N	1	published
31dfc80c-4ec5-43c1-ae1e-4b634c8209bd	galileo	a0000000-0000-0000-0000-000000000025	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.299755+00	2026-07-18 09:57:23.299755+00	2026-07-18 09:57:23.299755+00	\N	1	published
badce0e7-49fd-4253-8069-82e9509d4ad6	linus_pauling	a0000000-0000-0000-0000-000000000025	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.309615+00	2026-07-18 09:57:23.309615+00	2026-07-18 09:57:23.309615+00	\N	1	published
6c1b7a1d-a4c5-453e-afd7-3ff02e6b1eda	rosalind_franklin	a0000000-0000-0000-0000-000000000025	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.31961+00	2026-07-18 09:57:23.31961+00	2026-07-18 09:57:23.31961+00	\N	1	published
1458508b-bd19-4996-be27-1a87860aec35	alan_turing	a0000000-0000-0000-0000-000000000025	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:23.332008+00	2026-07-18 09:57:23.332008+00	2026-07-18 09:57:23.332008+00	\N	1	published
3a4da93c-0741-4717-a423-2e47c5ba8eab	kartinko	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 14:55:53.669226+00	2026-07-18 18:56:54.007333+00	2026-07-18 14:55:53.66923+00	\N	2	published
ccfb8bb4-73cc-4269-86aa-88371c4485b6	upload-ccfb8bb473cc	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 19:58:38.232151+00	2026-07-18 19:58:38.232154+00	2026-07-18 19:58:38.232155+00	\N	1	published
1ea63bec-f46d-43d4-bfce-ec55c7e3b96c	upload-1ea63becf46d	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 19:58:38.267657+00	2026-07-18 19:58:38.267661+00	2026-07-18 19:58:38.267661+00	\N	1	published
8877988a-cc00-4360-902c-b9236ef36f1c	upload-8877988acc00	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 19:58:38.296067+00	2026-07-18 19:58:38.296072+00	2026-07-18 19:58:38.296073+00	\N	1	published
058e03ee-0404-4bc5-b449-260f1f29e6a1	upload-058e03ee0404	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 19:58:38.327766+00	2026-07-18 19:58:38.32777+00	2026-07-18 19:58:38.327771+00	\N	1	published
5ceefbba-b512-467e-9bbb-2f8a537bd2b9	upload-5ceefbbab512	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 19:58:38.355002+00	2026-07-18 19:58:38.355007+00	2026-07-18 19:58:38.355008+00	\N	1	published
387fb842-3e32-462c-a70a-714bab27a2eb	upload-387fb8423e32	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 20:05:45.196376+00	2026-07-18 20:05:45.196379+00	2026-07-18 20:05:45.19638+00	\N	1	published
8f5afa8d-d5cf-41b8-9330-7794bdfa761e	upload-8f5afa8dd5cf	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 20:05:45.232081+00	2026-07-18 20:05:45.232085+00	2026-07-18 20:05:45.232087+00	\N	1	published
64a2dfe2-ea09-492c-8302-3e0c92e24c8d	upload-64a2dfe2ea09	a0000000-0000-0000-0000-000000000021	deleted	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 20:05:45.274538+00	2026-07-18 20:17:30.376646+00	2026-07-18 20:05:45.274543+00	\N	1	published
24a3b922-3ba0-4077-b0db-6eea4d22beca	upload-24a3b9223ba0	a0000000-0000-0000-0000-000000000021	deleted	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 19:56:54.486709+00	2026-07-18 20:18:10.401102+00	2026-07-18 19:56:54.486716+00	\N	1	published
e2c3c575-32e2-4e12-83da-f0bfb086ef24	upload-e2c3c57532e2	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 20:19:04.990975+00	2026-07-18 20:19:04.990979+00	2026-07-18 20:19:04.99098+00	\N	1	published
687e7c72-2f0a-46c2-8dec-9762d182a87f	interstellar_2014	a0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:20.655538+00	2026-07-19 12:08:05.301426+00	2026-07-18 09:57:20.655538+00	\N	1	published
4cb4bd5c-599a-4a8f-bfa0-44f2b5ff4ac8	upload-4cb4bd5c599a	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 20:22:59.451412+00	2026-07-18 20:22:59.451415+00	2026-07-18 20:22:59.451416+00	\N	1	published
c7940df6-46a1-483b-a8b0-0fb0d60019f2	upload-c7940df646a1	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 20:26:38.013344+00	2026-07-18 20:26:38.013355+00	2026-07-18 20:26:38.013358+00	\N	1	published
eb2cb77f-513e-450a-a911-aa2fd912f5c3	upload-eb2cb77f513e	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 20:26:50.662611+00	2026-07-18 20:26:50.662614+00	2026-07-18 20:26:50.662614+00	\N	1	published
7fe3dd00-a021-49d1-899a-93e6818a30a9	1984_orwell	a0000000-0000-0000-0000-000000000007	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 09:57:21.206373+00	2026-07-18 20:27:10.608784+00	2026-07-18 09:57:21.206373+00	\N	1	published
8bf8898d-097d-414e-beab-2c84e8fdd08b	upload-8bf8898d097d	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 20:38:28.47036+00	2026-07-18 20:38:28.470364+00	2026-07-18 20:38:28.470365+00	\N	1	published
163f66ff-44d7-4580-85ab-39c5bfbe1e9d	upload-163f66ff44d7	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 20:40:32.700413+00	2026-07-18 20:40:32.700418+00	2026-07-18 20:40:32.700419+00	\N	1	published
e66174d9-06a6-4caa-b896-e954d5087cbb	field_imdb_id	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	2	published
a906d913-ac95-45b0-adc2-e4b08fcec21a	field_tmdb_id	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	3	published
6af186bf-565b-4ca4-8799-5c309a61ea53	field_runtime	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	4	published
69776eb8-9425-46fa-b3ad-f1b535135200	field_mpaa_rating	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	5	published
fca7cd62-58d0-4103-9ac9-916b13fa9d23	field_budget	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	6	published
306287a6-1851-4701-841c-43b37eba32c2	field_revenue	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	7	published
0c26ec5b-2ee8-4642-bf05-b508dbb3ddac	field_filming_locations	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	8	published
859820dc-0724-47ce-8ede-8c7d12746963	field_production_companies	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	9	published
7668d04a-c745-4083-8b6a-9d96cdb7a697	field_tagline	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	10	published
0fdf2cca-af55-44bf-a5c6-4668d35356a0	field_vote_count	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	11	published
fc44eac6-8287-4f98-8ec1-ab2ba860b44f	field_production_company	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	12	published
29028900-dfc9-4cd7-9281-cd5a37f88d9f	field_title	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	13	published
4557e26d-735b-4518-9ea4-8fce83d419ec	field_description	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	14	published
51395a55-5bcd-4ae0-b2ca-275dcbaf03fa	field_year	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	15	published
87d78c11-7ba0-415c-9e72-b1863da3ca41	field_genre	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	16	published
52d3d0e2-7233-4312-904c-158bc3408aa1	field_rating	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	17	published
a566d1b6-4b21-4ee3-a03b-fbf9d4b3c18d	field_country	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	18	published
cdd8873d-72d0-44e8-b12b-dda57fefae95	field_language	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	19	published
fa0c8e75-4b32-4932-a25d-a41594e6284b	field_budget_mln	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	20	published
0b81ab90-ce6e-4e5e-8372-7cedf8f1f0b0	field_duration_min	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	21	published
e7f67fa4-8b5e-4a21-9ee7-1dfd016e0e79	field_author	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	22	published
2db68426-d7fb-4558-85d6-2200c4be7483	field_pages	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	23	published
e87f137c-0dd4-4ef1-bcab-90947f245310	field_isbn	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	24	published
7c268ffe-390a-42f6-a295-3cbaf14bd4ed	field_release_date	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	25	published
8083d83c-1095-4467-892b-73ab6f7b38a3	field_start_date	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	26	published
2740d254-056a-4355-8bf6-e3f511053c7e	field_end_date	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	27	published
f0a5ae18-416c-4cd0-8ce8-5eae3b62a46b	field_price	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	28	published
7a445a3b-a359-4090-b87d-56a72d2561e9	field_website	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	29	published
16e0ab11-a890-4a0c-9ae5-e9760dc6caba	field_email	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	30	published
50560847-3cfc-414b-8659-222fe703e181	field_content	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	31	published
f8dec4ff-ef2d-4c25-9985-ce576f01fce6	field_age_rating	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	32	published
5b3db321-e48a-4fd2-8bbf-73edb79e93c9	field_version	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	33	published
3695518e-aa08-4f99-8421-62fb84454a6c	field_license	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	34	published
c897e8e5-2f44-47e7-b93e-c3240967f793	field_repository_url	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	35	published
7e1abafa-5000-47eb-96ed-f65f268d2c3f	field_programming_language	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	36	published
e45d48bc-398f-4c4f-aa41-259ddf8fd143	field_platform	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	37	published
6cd97c90-dd19-4c1c-848d-2dfa70eeb9c0	field_developer	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	38	published
621a6f31-c9b5-4a63-805e-eca92ce9814e	field_event_date	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	39	published
a2b6152e-388d-496c-9972-a3c3a7d6e6e7	field_event_end_date	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	40	published
834fa7cd-5b92-4849-9522-7d5e9d9df64b	field_venue	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	41	published
5db2a94e-43a7-49c7-96fa-8c60cb1152ed	field_organizer	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	42	published
efbc604f-c1e3-425d-b0d6-f3c7281c2d95	field_attendee_count	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	43	published
10d0b551-2b83-42d6-a983-c3465cb16f94	field_ticket_price	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	44	published
8c450ef6-a30b-4fc4-a0e9-397908ac32fb	field_game_engine	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	45	published
51611186-f6ba-473f-b5bd-92b8ac47271e	field_platform_list	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	46	published
7a44f578-6a88-4b63-b0df-a69b1a0820de	field_player_count	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	47	published
cfb13f53-8d02-4bb1-a857-ae5f32400de1	field_esrb_rating	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	48	published
c21b5e7b-9139-4449-9779-7e1faa9909a9	field_latitude	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	49	published
dd58db39-620a-4dcc-b6db-53b0d6fc6d32	field_longitude	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	50	published
672956aa-18e5-4de8-b812-0f025a815a62	field_elevation_m	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	51	published
5c7b2aab-226c-40ec-9d67-aefa5cbc5cfb	field_timezone	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	52	published
83393a4c-4dac-4e25-9c5d-0992ff381746	field_area_km2	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	53	published
d2356d9e-df72-4cb5-bf34-f895df20056e	field_population	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	54	published
d3313362-0c00-49e9-92e7-7bd6d47cddc1	field_postal_code	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	55	published
2d134f2b-010a-4fe2-bf12-ee93dc343850	field_iso_code	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	56	published
64a70b92-8c8e-4763-9542-7f520cabc9da	field_publisher	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	57	published
41858589-b5ed-41bd-946d-e75f457e62d3	field_publication_city	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	58	published
9141ee3c-c83d-4730-8828-416d8385a973	field_edition	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	59	published
05bac44f-54b7-42b9-8e4e-e30d0b103efb	field_original_language	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	61	published
6a28f029-ddc2-4120-8fe7-28a1b361cb4d	field_dewey_decimal	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	62	published
1c9f03b8-2309-4b59-ac26-ea5ba2b1024e	field_poster_url	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	63	published
369fe9c8-7839-432d-b1e0-b23c34ba53b3	field_images	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	64	published
e965c7bd-f8f4-4bbf-b4a5-1b51abf8c1fc	field_video_url	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	65	published
708d1c90-2f73-4757-9a0f-3319350d3d74	field_audio_url	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	66	published
8762c43d-8e8e-4977-9e69-f1c77e3baa41	field_file_url	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	67	published
e2a1125f-8457-4fcc-8b2d-be5fe38d6810	field_file_title	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	68	published
9cdf7eb1-420b-4c77-9af3-8ca575b58ad8	field_episode_number	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	69	published
eec27388-96e1-4d80-8356-0ce7fea2bf22	field_season_number	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	70	published
0b25635d-07c0-424c-84c4-88c06b6231e7	field_podcast_url	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	71	published
3674cffb-1308-4671-a49d-9de30d991615	field_channel_url	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	72	published
5f2fad97-43d9-463d-a326-9578ff29b8ee	field_artist	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	73	published
279b4865-bd06-4be5-ab2e-03284416eb70	field_album	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	74	published
54db1b64-d1f1-4c4b-a51f-ff17989d10fa	field_bpm	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	75	published
e4fa9e7b-84e8-4284-b09f-5ae2fc98d1d4	field_isrc	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	76	published
ed532ab3-134a-4e40-8a83-82b057a0b5f5	field_iswc	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	77	published
91b6d7e4-b4b5-4604-b8d2-b0e548370229	field_track_number	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	78	published
0c731b79-48f7-4cd5-9ee6-7cddcbc4059e	field_disc_number	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	79	published
f122a48c-6683-4cde-944e-200fadccafac	field_explicit	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	80	published
fde1ecd4-ccb9-48f8-bcf0-2c7b788dd6ab	field_key_signature	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	81	published
65e96845-dad5-4e31-ad2e-fd8eaf9594ca	field_time_signature	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	82	published
e2ba9020-2019-4ca9-a1c3-bfe04b285b0a	field_label_name	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	83	published
e82819ac-b840-4323-8573-7e08c9d24f18	field_founding_date	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	84	published
aa8a9231-caf4-4c65-8d6b-a2cc5fd47a31	field_dissolution_date	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	85	published
84d76e43-7d13-41f1-9e85-b8e4b65e0d1c	field_founder	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	86	published
ce740df6-b817-457a-8dc8-f47a174a45cb	field_industry	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	87	published
1b99e712-73f8-4f74-8ac2-2f734c21dc61	field_employee_count	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	88	published
aca43b1c-341f-4b10-af2a-6801719bd242	field_headquarters	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	89	published
501d186a-f239-454c-ab02-dad26ab85263	field_first_name	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	90	published
9be46b9f-0097-46ce-bb31-9b92339e3bd0	field_last_name	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	91	published
c7eb9698-deeb-4f2a-8d40-4190006c55c8	field_patronymic	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	92	published
cc56d0bf-a031-4ba6-8904-c14f6344d234	field_birth_date	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	93	published
10ffb420-a434-447b-b207-6b2f3c9b107f	field_birth_place	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	94	published
15352e27-8d98-42ca-adcb-78d1f7bc83df	field_death_date	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	95	published
7d6a7080-967b-48cc-8034-53b1662f4681	field_death_place	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	96	published
b23c6d35-ec9a-429d-891d-aabdb23f1082	field_height_cm	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	97	published
defed9c0-35a9-420f-afcb-a6b0180584fb	field_nationality	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	98	published
84da9ec5-cec4-4e37-acef-1c9572014138	field_occupation	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	99	published
1f5c413e-1aed-4c2e-96c7-39d8dc30d2d0	field_electron_configuration	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	100	published
783ef653-d827-4583-b9cb-6d3d6470ee5d	field_oxidation_states	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	101	published
f763b263-01bf-4721-bbc0-8529a716c627	field_electronegativity	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	102	published
e802227c-4f05-446e-ac3b-b99421b1401c	field_density	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	103	published
14753e08-083b-4068-8e9e-ffe785b64468	field_melting_point	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	104	published
1aa33c64-8a8b-4ef8-9f1f-99a187b1e1e3	field_boiling_point	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	105	published
257bfc6b-5728-4955-8710-c4cc18041adc	field_discovery_year	06125618-0d99-40fc-ac91-44cc8207a434	active	\N	\N	\N	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	106	published
4cacf75e-5bde-4587-8552-102584be4e14	 -2	a0000000-0000-0000-0000-000000000001	deleted	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 07:04:44.874635+00	2026-07-19 07:04:44.874643+00	2026-07-19 07:04:44.874645+00	\N	108	published
a5cf7ea3-4ce6-43fa-a34d-66173cf61b71	 -3	a0000000-0000-0000-0000-000000000001	deleted	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 07:43:09.829556+00	2026-07-19 07:44:50.64218+00	2026-07-19 07:43:09.829561+00	\N	109	published
87135199-274e-4cc5-9027-dc0ca71c7206	 -4	a0000000-0000-0000-0000-000000000001	deleted	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 07:51:47.835479+00	2026-07-19 07:52:39.436801+00	2026-07-19 07:51:47.835482+00	\N	110	published
afed8c62-00d3-476b-a20c-2b8173d303a6	upload-afed8c6200d3	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 08:07:20.044237+00	2026-07-19 08:07:20.04424+00	2026-07-19 08:07:20.04424+00	\N	1	published
28bd6d73-486b-411d-a0a4-be628e8bc486	 	a0000000-0000-0000-0000-000000000001	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 07:04:20.734166+00	2026-07-19 08:07:42.606725+00	2026-07-19 07:04:20.734168+00	\N	107	published
bc2e4b44-1cc5-49bd-9150-344db72a1ada	ontology_cinema	92f3be1c-718d-4059-9485-80c75fa959e5	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	101	published
bb0c3817-0c84-4636-bbe4-a2e526e2ed4a	ontology_literature	92f3be1c-718d-4059-9485-80c75fa959e5	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	102	published
5f187205-5b33-4ef3-b22d-548919737ae2	ontology_music	92f3be1c-718d-4059-9485-80c75fa959e5	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	103	published
eb270429-1d7a-40ef-99ff-febd7e3c9cfd	ontology_technology	92f3be1c-718d-4059-9485-80c75fa959e5	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	104	published
0c0ab9ea-fabc-4497-9b2a-551bce2633aa	ontology_default	92f3be1c-718d-4059-9485-80c75fa959e5	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	105	published
c204aa0c-04c6-44ef-8e86-e53ff4a4eb81	ontology_field_model	92f3be1c-718d-4059-9485-80c75fa959e5	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	106	published
af903b79-d26c-48b1-973b-a1bfaa229723	ontology_ontology_entity_model	92f3be1c-718d-4059-9485-80c75fa959e5	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	107	published
29f93b7a-c8a0-46bb-a5b9-8c7e4bbec851	ontology_science	92f3be1c-718d-4059-9485-80c75fa959e5	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	108	published
736f1f2b-b9a0-4199-b026-410ae5d32fd0	ontology_geography	92f3be1c-718d-4059-9485-80c75fa959e5	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	109	published
1b53bbd4-9c24-407b-8af3-ed833c9f11c1	ontology_history	92f3be1c-718d-4059-9485-80c75fa959e5	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	110	published
1ecd1e93-4eef-4ecb-9ff5-b77c1c4211c3	upload-1ecd1e934eef	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-18 20:58:32.197385+00	2026-07-19 17:02:57.663717+00	2026-07-18 20:58:32.197397+00	\N	1	published
d0000001-0000-0000-0000-000000000005	blade-runner-2049	a0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.852689+00	2026-07-20 10:08:33.53835+00	2026-07-18 09:57:12.852689+00	\N	1	published
a0c57af5-a57c-4a21-825f-5f64d0f104e8	onttemplate_actor_tpl_person	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	112	published
cf7ee646-99ca-4d12-9b58-8859b9771de6	onttemplate_album_tpl_album	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	113	published
e09b6c18-7e5b-4a6b-8653-584f86c318d6	onttemplate_book_tpl_book	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	114	published
09c95573-23ed-43ae-9b4c-a39d10c30e7c	onttemplate_digital_file_Clip	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	115	published
138b1eb4-bcb4-46c8-a608-80ae65c59654	onttemplate_director_tpl_person	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	116	published
cddfb16e-fd93-45b8-93de-afcb0a09bc02	onttemplate_movie_tpl_movie	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	117	published
9ce79308-04cf-4d9b-849c-5abadca3a604	onttemplate_musician_tpl_person	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	118	published
85a3fcf9-5269-45db-9635-6e28e3ebf5be	onttemplate_song_tpl_song	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	119	published
152a73bb-f373-465c-80d5-399208c86fc5	onttemplate_writer_tpl_person	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	120	published
14c04917-f468-4f95-a512-a8645ac910bb	onttemplate_article_tpl_article	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	121	published
4b061c8b-e244-41ce-9d09-e2f2da50521c	onttemplate_artist_tpl_person	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	122	published
5f4607e5-7201-4db5-9815-0097a92c5960	onttemplate_classifier_tpl_classifier	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	123	published
2f6881f2-7199-4f36-8df7-e72442e331a7	onttemplate_concept_tpl_concept	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	124	published
ff738162-46d2-4729-b625-13fb9e4a74b9	onttemplate_digital_file_tpl_file	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	125	published
8be3db4d-998a-407e-abbf-80c80d4bfb34	onttemplate_genre_tpl_genre	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	126	published
8dbad62b-b97d-4b4d-9daa-2035ad88e8af	onttemplate_human_tpl_person	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	127	published
38b8568b-f382-4b4d-b3bf-67285bd3f8df	onttemplate_movement_tpl_movement	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	128	published
29a3fbd3-ef9c-4005-92a3-ffcd69b8750a	onttemplate_photo_tpl_photo	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	129	published
2f24423f-b243-4349-b141-d742e7760df9	onttemplate_physical_item_tpl_item	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	130	published
a5c1e6af-ddbf-4f1c-814a-af4d72355b98	onttemplate_tpl_my_image	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	131	published
e3a539f8-2616-48ef-9b6c-91d4e7d7fd98	onttemplate_field_template	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	132	published
e9f2746c-654d-40c6-8889-d2644b716ed2	onttemplate_ontology_model_tpl	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	133	published
661a1a34-cabe-4d19-a233-1d615919a52d	onttemplate_ontology_template_tpl	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	134	published
7a309616-4834-46b7-bcdc-ba5b4bc518aa	onttemplate_animal_tpl_animal	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	135	published
bae1f4a5-c622-4136-8f95-8e25917db03e	onttemplate_chemical_element_tpl_element	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	136	published
00acc2db-82e9-4955-8c81-cfd4afeff149	onttemplate_phenomenon_tpl_phenomenon	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	137	published
54ee9c51-8f8c-4811-a102-4ae1c591acfe	onttemplate_plant_tpl_plant	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	138	published
26e0e57e-5d11-4a9d-80d5-f098bc5c3032	onttemplate_scientist_tpl_person	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	139	published
0c3967e8-9189-40c0-bfc0-68682ddb648b	onttemplate_period_tpl_period	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	140	published
68384b8c-39fa-4923-8c43-c2922b468d31	onttemplate_place_tpl_place	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	\N	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	141	published
675126c2-ba40-42d8-a669-087c992e5066	interstellar tmdb test	a0000000-0000-0000-0000-000000000001	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 12:07:04.294005+00	2026-07-19 12:07:04.29401+00	2026-07-19 12:07:04.294011+00	\N	142	published
d0000001-0000-0000-0000-000000000003	interstellar	a0000000-0000-0000-0000-000000000001	active	07cf887d-2773-4450-8605-9ec40d159d95	\N	\N	2026-07-18 09:57:12.852689+00	2026-07-19 12:16:43.473926+00	2026-07-18 09:57:12.852689+00	\N	1	published
316f401b-37b5-4928-bc24-4d8298e6eb73	test	a0000000-0000-0000-0000-000000000001	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 12:27:44.257061+00	2026-07-19 12:27:44.257064+00	2026-07-19 12:27:44.257065+00	\N	143	published
88d8fb43-a635-4880-ae5a-a2f966d35191	boytsovskiy klub	a0000000-0000-0000-0000-000000000001	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 12:27:44.282348+00	2026-07-19 12:27:44.28235+00	2026-07-19 12:27:44.282351+00	\N	144	published
3c62b9a7-7089-4dac-93ec-4a2ddecb2e96	actor_6384	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:57.971919+00	2026-07-19 13:48:57.971924+00	2026-07-19 13:48:57.971925+00	\N	146	published
4a97d9d9-9fe6-4acf-96ad-2eb1eb2fc8ec	actor_2975	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:58.050007+00	2026-07-19 13:48:58.050014+00	2026-07-19 13:48:58.050015+00	\N	146	published
eba3b8f1-7030-4030-b081-7cbc1188f5c0	actor_530	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:58.059346+00	2026-07-19 13:48:58.059349+00	2026-07-19 13:48:58.059349+00	\N	146	published
40c5f5cc-2e35-4dfb-a752-594660f1b481	actor_1331	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:58.064467+00	2026-07-19 13:48:58.064468+00	2026-07-19 13:48:58.064469+00	\N	146	published
ff901aa3-31ac-4e8d-ba94-3765066ffb64	actor_9364	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:58.06851+00	2026-07-19 13:48:58.068511+00	2026-07-19 13:48:58.068512+00	\N	146	published
c1f10e6f-a57f-41b2-98b4-2cb40142f4fa	actor_532	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:58.073356+00	2026-07-19 13:48:58.073359+00	2026-07-19 13:48:58.07336+00	\N	146	published
57bce17e-0ba5-455d-bc66-9351a10d7094	actor_9372	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:58.079897+00	2026-07-19 13:48:58.079899+00	2026-07-19 13:48:58.0799+00	\N	146	published
c3f22c49-3287-429b-bf3e-8e17987bc06c	actor_7244	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:58.084614+00	2026-07-19 13:48:58.084616+00	2026-07-19 13:48:58.084617+00	\N	146	published
42a03e22-8ac3-4dbc-a084-9dd54dbd8dea	actor_9374	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:58.089936+00	2026-07-19 13:48:58.089938+00	2026-07-19 13:48:58.089939+00	\N	146	published
12d77665-1267-491a-a8ee-2d3fe2910980	actor_9376	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:58.09401+00	2026-07-19 13:48:58.094011+00	2026-07-19 13:48:58.094012+00	\N	146	published
02c2a15e-b864-4c1c-bfb5-e315b4ef5582	actor_9378	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:58.097821+00	2026-07-19 13:48:58.097822+00	2026-07-19 13:48:58.097823+00	\N	146	published
8040279c-cfa4-46ba-84e7-ccbe4508468c	actor_9380	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:58.101493+00	2026-07-19 13:48:58.101495+00	2026-07-19 13:48:58.101495+00	\N	146	published
859bbc34-a13f-44e0-9b68-98b77af590e4	actor_39545	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:58.105332+00	2026-07-19 13:48:58.105335+00	2026-07-19 13:48:58.105336+00	\N	146	published
a419fe53-6f2e-4b32-b8dc-3aef96e52b47	actor_9383	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:58.109232+00	2026-07-19 13:48:58.109233+00	2026-07-19 13:48:58.109234+00	\N	146	published
07d68dbe-bec6-4dc0-af9d-430408143885	actor_9384	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:58.11283+00	2026-07-19 13:48:58.112832+00	2026-07-19 13:48:58.112832+00	\N	146	published
9a49ab7f-8491-4f7b-b502-870b5e770c59	director_9340	a0000000-0000-0000-0000-000000000003	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:58.116434+00	2026-07-19 13:48:58.116435+00	2026-07-19 13:48:58.116436+00	\N	146	published
d5837aa3-c87e-4b54-be6b-8fd1a85cd5f2	director_9339	a0000000-0000-0000-0000-000000000003	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 13:48:58.120122+00	2026-07-19 13:48:58.120124+00	2026-07-19 13:48:58.120124+00	\N	146	published
14299d64-b42e-4da1-a332-17044d038483	moana	a0000000-0000-0000-0000-000000000001	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 14:10:57.957976+00	2026-07-19 14:58:35.066116+00	2026-07-19 14:10:57.957981+00	\N	147	published
485dee97-cde2-4603-8aa3-1b9364a5cbb1	upload-485dee97cde2	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 15:13:23.03071+00	2026-07-19 15:13:23.030714+00	2026-07-19 15:13:23.030715+00	\N	1	published
ce6d5b1a-8536-4823-88c3-6d077da6c23c	upload-ce6d5b1a8536	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 15:13:23.108273+00	2026-07-19 15:13:23.108276+00	2026-07-19 15:13:23.108276+00	\N	1	published
c42af2c3-8bff-431d-84aa-31fee4e37dba	upload-c42af2c38bff	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 15:13:23.143877+00	2026-07-19 15:13:23.14388+00	2026-07-19 15:13:23.14388+00	\N	1	published
9559dcd0-3ee8-4941-ac8e-65bde4b2e705	upload-9559dcd03ee8	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 15:13:23.166257+00	2026-07-19 15:13:23.166259+00	2026-07-19 15:13:23.16626+00	\N	1	published
b56aeff9-0ebd-4687-b5f3-c7bdd8efa1a6	upload-b56aeff90ebd	a0000000-0000-0000-0000-000000000021	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 15:13:23.421818+00	2026-07-19 15:13:23.421821+00	2026-07-19 15:13:23.421822+00	\N	1	published
2dc022f2-ce9a-4460-961f-b0eb14940557	spaun	a0000000-0000-0000-0000-000000000001	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 16:57:18.127236+00	2026-07-19 16:57:18.127239+00	2026-07-19 16:57:18.12724+00	\N	148	published
81fc4a44-8440-495a-ab10-9071e01b03f2	actor_3	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:35:23.965843+00	2026-07-19 17:35:23.965846+00	2026-07-19 17:35:23.965847+00	\N	149	published
539e17de-4a18-4fb7-9f60-1a67eb6d7342	actor_585	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:35:23.975914+00	2026-07-19 17:35:23.975915+00	2026-07-19 17:35:23.975916+00	\N	149	published
379e665e-a13a-4f99-b4ae-ba6d68694f79	actor_586	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:35:23.979948+00	2026-07-19 17:35:23.97995+00	2026-07-19 17:35:23.97995+00	\N	149	published
3723a9d9-c419-4d93-8601-213fab20f209	actor_587	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:35:23.98383+00	2026-07-19 17:35:23.983831+00	2026-07-19 17:35:23.983832+00	\N	149	published
dd82c80c-57d6-47df-96b9-68725482a8f9	actor_588	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:35:23.987722+00	2026-07-19 17:35:23.987723+00	2026-07-19 17:35:23.987724+00	\N	149	published
84a7abd7-aeaf-44d7-accb-ab32916c05ef	actor_589	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:35:23.991908+00	2026-07-19 17:35:23.99191+00	2026-07-19 17:35:23.991911+00	\N	149	published
678fb7a5-59ea-4f96-8e18-50a3512531f3	actor_590	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:35:23.996342+00	2026-07-19 17:35:23.996344+00	2026-07-19 17:35:23.996344+00	\N	149	published
0aacbfa3-02c8-47ef-b65b-b31831c5e810	actor_591	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:35:24.000163+00	2026-07-19 17:35:24.000165+00	2026-07-19 17:35:24.000165+00	\N	149	published
da777e99-1053-4964-91ed-dd50b1ec472b	actor_592	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:35:24.00444+00	2026-07-19 17:35:24.004442+00	2026-07-19 17:35:24.004442+00	\N	149	published
2519866a-6643-448a-b7d3-b715460f00b2	actor_593	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:35:24.008774+00	2026-07-19 17:35:24.008776+00	2026-07-19 17:35:24.008777+00	\N	149	published
272384e9-863b-4c5c-9173-5a33e916b463	actor_20904	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:35:24.012862+00	2026-07-19 17:35:24.012863+00	2026-07-19 17:35:24.012864+00	\N	149	published
83465a83-d6cc-490d-8eb7-2ff76c09db26	actor_58495	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:35:24.01692+00	2026-07-19 17:35:24.016922+00	2026-07-19 17:35:24.016922+00	\N	149	published
3c9f167e-c3e6-4c90-b685-0c5c4140ef4a	actor_53760	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:35:24.020903+00	2026-07-19 17:35:24.020904+00	2026-07-19 17:35:24.020905+00	\N	149	published
563aa5cc-fdff-4ce9-9286-51ccac80df1c	actor_943481	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:35:24.024824+00	2026-07-19 17:35:24.024825+00	2026-07-19 17:35:24.024826+00	\N	149	published
e73db3a3-7d24-448a-8dc3-a0372ee8d227	actor_107074	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:35:24.028733+00	2026-07-19 17:35:24.028734+00	2026-07-19 17:35:24.028735+00	\N	149	published
98c7bf0d-8906-4a15-8dc5-d93344cf713a	director_578	a0000000-0000-0000-0000-000000000003	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:35:24.032834+00	2026-07-19 17:35:24.032836+00	2026-07-19 17:35:24.032837+00	\N	149	published
2f182f95-9d5f-49a8-bf3c-7e859d73dcde	actor_12073	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.111827+00	2026-07-19 17:54:23.111832+00	2026-07-19 17:54:23.111833+00	\N	151	published
06b10f9f-ebff-49ea-a556-a2add917fd87	actor_776	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.125343+00	2026-07-19 17:54:23.125345+00	2026-07-19 17:54:23.125345+00	\N	151	published
aead556f-5a34-467c-b9f2-0ad48b737a18	actor_6941	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.129493+00	2026-07-19 17:54:23.129494+00	2026-07-19 17:54:23.129495+00	\N	151	published
9a98109b-27bc-480f-a64a-54b4447e7c9b	actor_12074	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.133693+00	2026-07-19 17:54:23.133694+00	2026-07-19 17:54:23.133695+00	\N	151	published
689de5a6-5552-4753-8ee3-cf2e07504d06	actor_1925	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.137524+00	2026-07-19 17:54:23.137525+00	2026-07-19 17:54:23.137526+00	\N	151	published
ad7566fb-15e1-42b2-a666-336325036d7b	actor_12075	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.14145+00	2026-07-19 17:54:23.141451+00	2026-07-19 17:54:23.141452+00	\N	151	published
0855aa2a-2de9-4164-8461-60001c848184	actor_12076	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.145352+00	2026-07-19 17:54:23.145353+00	2026-07-19 17:54:23.145353+00	\N	151	published
1a134efa-d413-46ea-8447-b49b1a68a2da	actor_12077	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.148935+00	2026-07-19 17:54:23.148936+00	2026-07-19 17:54:23.148937+00	\N	151	published
f73c9001-eb85-437b-83e1-0f6d280db498	actor_12078	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.152567+00	2026-07-19 17:54:23.152568+00	2026-07-19 17:54:23.152569+00	\N	151	published
b545556c-bea5-42c9-bc07-5dee10fe9904	actor_12098	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.156381+00	2026-07-19 17:54:23.156382+00	2026-07-19 17:54:23.156383+00	\N	151	published
8270ba47-9b11-42e4-8ffe-30f51e9f8626	actor_12095	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.159968+00	2026-07-19 17:54:23.159969+00	2026-07-19 17:54:23.15997+00	\N	151	published
fb527f7d-f74a-467c-9593-af47f5e12749	actor_7210	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.163292+00	2026-07-19 17:54:23.163294+00	2026-07-19 17:54:23.163294+00	\N	151	published
160fb1d4-716b-4ef7-9c90-10333879d806	actor_4865931	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.166564+00	2026-07-19 17:54:23.166565+00	2026-07-19 17:54:23.166565+00	\N	151	published
e033a044-0907-445a-bf36-862bfb0f6322	actor_12097	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.169867+00	2026-07-19 17:54:23.169868+00	2026-07-19 17:54:23.169868+00	\N	151	published
6ec4fd76-0b26-4a32-9774-ac313ab191a7	actor_44114	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.173118+00	2026-07-19 17:54:23.17312+00	2026-07-19 17:54:23.17312+00	\N	151	published
c83c06f0-a896-431a-b643-f0e67b0b4d11	director_5524	a0000000-0000-0000-0000-000000000003	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.176319+00	2026-07-19 17:54:23.17632+00	2026-07-19 17:54:23.176321+00	\N	151	published
b386e593-80d7-4129-b214-994ff319c9aa	director_12058	a0000000-0000-0000-0000-000000000003	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:54:23.179647+00	2026-07-19 17:54:23.179648+00	2026-07-19 17:54:23.179649+00	\N	151	published
5ac853dd-6a1a-4d71-8774-578661c88632	actor_5823	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:00:17.262437+00	2026-07-19 18:00:17.262439+00	2026-07-19 18:00:17.26244+00	\N	153	published
66c1fc69-fac3-4800-a8e4-b439a25ce422	actor_3131	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:00:17.267742+00	2026-07-19 18:00:17.267744+00	2026-07-19 18:00:17.267744+00	\N	153	published
f49ff441-4222-4550-ac33-a270547cfd4d	actor_8930	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:00:17.271701+00	2026-07-19 18:00:17.271703+00	2026-07-19 18:00:17.271703+00	\N	153	published
11a99954-254a-4e7e-bd58-3608ad9d192b	actor_4757	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:00:17.275796+00	2026-07-19 18:00:17.275797+00	2026-07-19 18:00:17.275798+00	\N	153	published
5424ac10-6763-4503-bfd1-e0823933fee9	actor_12094	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:00:17.280723+00	2026-07-19 18:00:17.280725+00	2026-07-19 18:00:17.280726+00	\N	153	published
57b3dd72-a998-4438-a845-5ed8b837191e	actor_12106	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:00:17.284789+00	2026-07-19 18:00:17.284791+00	2026-07-19 18:00:17.284791+00	\N	153	published
ec021e80-77ec-41fd-9871-de19afde613f	actor_12079	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:00:17.288463+00	2026-07-19 18:00:17.288465+00	2026-07-19 18:00:17.288465+00	\N	153	published
c7c27520-d78f-4443-8801-c723b1e9c02a	actor_12080	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:00:17.293784+00	2026-07-19 18:00:17.293785+00	2026-07-19 18:00:17.293786+00	\N	153	published
259683c9-ad8e-410a-af06-331da98bf1e5	actor_1077844	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:00:17.299083+00	2026-07-19 18:00:17.299084+00	2026-07-19 18:00:17.299085+00	\N	153	published
40483f49-65b4-4a7b-bce7-555cd7474b4c	actor_71857	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:00:17.302343+00	2026-07-19 18:00:17.302345+00	2026-07-19 18:00:17.302345+00	\N	153	published
d9330950-bc06-49bc-aabc-2543652c0fa8	director_12080	a0000000-0000-0000-0000-000000000003	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:00:17.305604+00	2026-07-19 18:00:17.305605+00	2026-07-19 18:00:17.305606+00	\N	153	published
56aa342d-fa35-4b84-96a4-75c8a4ec999e	director_12079	a0000000-0000-0000-0000-000000000003	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:00:17.309122+00	2026-07-19 18:00:17.309123+00	2026-07-19 18:00:17.309123+00	\N	153	published
705601a6-39ee-4e1f-b770-a13b33e90b7c	shrek	a0000000-0000-0000-0000-000000000001	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 17:51:27.91895+00	2026-07-19 19:00:19.915735+00	2026-07-19 17:51:27.918954+00	\N	150	published
229c3096-e041-4990-b9a8-7d8e3e644362	shrek 2	a0000000-0000-0000-0000-000000000001	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:00:09.242374+00	2026-07-19 19:44:38.829363+00	2026-07-19 18:00:09.242378+00	\N	152	published
ac29698a-8d3a-44d5-8720-40ce7c85787d	character_603_6384	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:56:27.726561+00	2026-07-19 18:56:27.726564+00	2026-07-19 18:56:27.726565+00	\N	154	published
523a5c7b-d459-4d32-a647-d888d5f6f738	character_603_2975	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:56:27.740457+00	2026-07-19 18:56:27.740459+00	2026-07-19 18:56:27.74046+00	\N	154	published
d830d8f3-593e-4195-9cbc-97c37653c14c	character_603_530	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:56:27.747353+00	2026-07-19 18:56:27.747355+00	2026-07-19 18:56:27.747356+00	\N	154	published
90464e8a-fc3a-4576-bbdf-94c81971c321	character_603_1331	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:56:27.753854+00	2026-07-19 18:56:27.753856+00	2026-07-19 18:56:27.753856+00	\N	154	published
66528ea1-0831-4868-adab-f3588e2b964c	character_603_9364	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:56:27.760141+00	2026-07-19 18:56:27.760142+00	2026-07-19 18:56:27.760143+00	\N	154	published
d5f7dd2e-f165-4b1e-977e-6ab1ac54f5e2	character_603_532	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:56:27.766189+00	2026-07-19 18:56:27.766191+00	2026-07-19 18:56:27.766191+00	\N	154	published
7becbb13-0dad-4669-8f9b-6b857799a05a	character_603_9372	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:56:27.772931+00	2026-07-19 18:56:27.772932+00	2026-07-19 18:56:27.772933+00	\N	154	published
02ba8507-0771-481d-9a92-bdbad5658629	character_603_7244	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:56:27.778731+00	2026-07-19 18:56:27.778733+00	2026-07-19 18:56:27.778733+00	\N	154	published
3a647e68-82c5-4c8b-83f9-20faf8d51ec8	character_603_9374	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:56:27.78476+00	2026-07-19 18:56:27.784761+00	2026-07-19 18:56:27.784762+00	\N	154	published
d0b81c6a-4ada-4567-9f87-6e697c0d0efb	character_603_9376	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:56:27.790712+00	2026-07-19 18:56:27.790713+00	2026-07-19 18:56:27.790713+00	\N	154	published
29c51f60-52c2-4e92-bf73-08c289059cf6	character_603_9378	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:56:27.796495+00	2026-07-19 18:56:27.796497+00	2026-07-19 18:56:27.796497+00	\N	154	published
6773e984-aa56-4c9c-99f1-deac1c967325	character_603_9383	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:56:27.814111+00	2026-07-19 18:56:27.814113+00	2026-07-19 18:56:27.814113+00	\N	154	published
a2b416c0-b4a3-4303-924a-87cbaeee7b38	character_603_9384	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:56:27.821541+00	2026-07-19 18:56:27.821543+00	2026-07-19 18:56:27.821544+00	\N	154	published
883166fd-b28b-4e97-902d-e080991ef752	character_809_12073	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:59:48.506447+00	2026-07-19 18:59:48.50645+00	2026-07-19 18:59:48.50645+00	\N	155	published
0983686f-848a-441c-8e62-1802e2522a20	character_809_776	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:59:48.51429+00	2026-07-19 18:59:48.514293+00	2026-07-19 18:59:48.514293+00	\N	155	published
7f82e79b-d981-497e-8b7a-3fa95630a433	character_809_6941	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:59:48.521199+00	2026-07-19 18:59:48.521201+00	2026-07-19 18:59:48.521202+00	\N	155	published
90fab262-c29e-4e2d-adea-5887ad1312f0	character_809_5823	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:59:48.531133+00	2026-07-19 18:59:48.531135+00	2026-07-19 18:59:48.531136+00	\N	155	published
470cd6bb-540a-4620-b8d0-45026599ce8c	character_809_3131	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:59:48.538271+00	2026-07-19 18:59:48.538273+00	2026-07-19 18:59:48.538273+00	\N	155	published
17b5a4fd-013e-4c64-a8e9-2e953f12efe1	character_809_8930	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:59:48.545104+00	2026-07-19 18:59:48.545106+00	2026-07-19 18:59:48.545106+00	\N	155	published
6816830a-a41a-4397-8f04-75370ddf85fa	character_809_4757	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:59:48.551861+00	2026-07-19 18:59:48.551863+00	2026-07-19 18:59:48.551864+00	\N	155	published
3f41d21f-8f62-4c5d-a8ff-823b0739f897	character_809_12094	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:59:48.558882+00	2026-07-19 18:59:48.558885+00	2026-07-19 18:59:48.558885+00	\N	155	published
9a1bb389-8a7f-45a1-90c3-e9a9d5a9484b	character_809_12106	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:59:48.565942+00	2026-07-19 18:59:48.565944+00	2026-07-19 18:59:48.565945+00	\N	155	published
e2cea8f1-7a08-4c03-b204-3ace121057cf	character_809_12079	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:59:48.573352+00	2026-07-19 18:59:48.573354+00	2026-07-19 18:59:48.573355+00	\N	155	published
5ed8f232-6eca-4033-bdee-725292684348	character_809_12095	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:59:48.579686+00	2026-07-19 18:59:48.579687+00	2026-07-19 18:59:48.579688+00	\N	155	published
6c187652-aa74-462a-8ce9-606af3e4ca49	character_809_12080	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:59:48.586465+00	2026-07-19 18:59:48.586467+00	2026-07-19 18:59:48.586467+00	\N	155	published
bc7e0f85-a611-46f3-851b-5970a3ae369b	character_809_12097	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:59:48.592698+00	2026-07-19 18:59:48.592699+00	2026-07-19 18:59:48.5927+00	\N	155	published
4e8f67e3-57c9-4acb-a3c8-35063990f7e8	character_809_1077844	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:59:48.599317+00	2026-07-19 18:59:48.599318+00	2026-07-19 18:59:48.599319+00	\N	155	published
dedb547a-ba06-4560-a1a1-44cd1eef2ac8	character_809_71857	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:59:48.606004+00	2026-07-19 18:59:48.606006+00	2026-07-19 18:59:48.606006+00	\N	155	published
243465dd-ea0f-47ba-a95b-8a82ea75df5e	character_808_12073	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:00:09.516461+00	2026-07-19 19:00:09.516464+00	2026-07-19 19:00:09.516465+00	\N	156	published
d0c4d4f7-e5a9-4136-a98d-ce2523c56f52	character_808_776	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:00:09.531168+00	2026-07-19 19:00:09.53117+00	2026-07-19 19:00:09.531171+00	\N	156	published
344bb824-8999-4300-908a-4fd54cbf0ea6	character_808_6941	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:00:09.537863+00	2026-07-19 19:00:09.537864+00	2026-07-19 19:00:09.537865+00	\N	156	published
933317ac-7ab5-4847-97b1-ab27f87c8175	character_808_12074	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:00:09.544213+00	2026-07-19 19:00:09.544214+00	2026-07-19 19:00:09.544215+00	\N	156	published
d5656cb6-1892-4b2f-ad26-9ab8d7b9b36f	character_808_1925	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:00:09.550506+00	2026-07-19 19:00:09.550508+00	2026-07-19 19:00:09.550508+00	\N	156	published
29891216-e6a1-49fb-89f7-1402edf76d15	character_808_12075	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:00:09.556803+00	2026-07-19 19:00:09.556805+00	2026-07-19 19:00:09.556805+00	\N	156	published
3240c58a-d7b5-469c-96a5-5238a42a0106	character_808_12076	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:00:09.567083+00	2026-07-19 19:00:09.567085+00	2026-07-19 19:00:09.567086+00	\N	156	published
adaedd26-2341-410c-9568-7420219b5c9b	character_808_12077	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:00:09.574482+00	2026-07-19 19:00:09.574484+00	2026-07-19 19:00:09.574484+00	\N	156	published
9ed7d6a4-9cfe-42de-8463-24af8f242f8a	character_808_12078	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:00:09.580504+00	2026-07-19 19:00:09.580505+00	2026-07-19 19:00:09.580506+00	\N	156	published
e1d73f3b-dc6b-4f88-b42c-3ca16ded87f1	character_808_12098	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:00:09.586465+00	2026-07-19 19:00:09.586466+00	2026-07-19 19:00:09.586467+00	\N	156	published
ba7d4a8b-36e3-470c-a2a4-9c01bda0ad73	character_808_12095	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:00:09.592362+00	2026-07-19 19:00:09.592364+00	2026-07-19 19:00:09.592364+00	\N	156	published
06b01798-92f4-4cbc-97cf-9b4206bb71a6	character_808_7210	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:00:09.598252+00	2026-07-19 19:00:09.598254+00	2026-07-19 19:00:09.598254+00	\N	156	published
83043a41-8c2a-49e9-ac00-bfa18d7496db	character_808_4865931	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:00:09.603749+00	2026-07-19 19:00:09.603751+00	2026-07-19 19:00:09.603751+00	\N	156	published
0ec21891-3421-4a67-b856-565fa413210f	character_808_12097	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:00:09.609551+00	2026-07-19 19:00:09.609552+00	2026-07-19 19:00:09.609553+00	\N	156	published
e2886d37-3d47-448d-a873-a88f9ee476a5	character_808_44114	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:00:09.615898+00	2026-07-19 19:00:09.6159+00	2026-07-19 19:00:09.6159+00	\N	156	published
b1bc0591-73b3-4ce3-b2a6-46167d7c781b	onttemplate_charaster_cinema	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:05:43.796121+00	2026-07-19 19:05:43.796123+00	2026-07-19 19:05:43.796124+00	\N	4	published
b5f0c24d-a156-478a-aecc-e36a066571e8	character_603_9380	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:56:27.802477+00	2026-07-19 19:41:24.146768+00	2026-07-19 18:56:27.802479+00	\N	154	published
9ecebfcf-5ac0-4bd9-87fb-4c94eee5a7e0	character_603_39545	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 18:56:27.80829+00	2026-07-19 19:44:04.10865+00	2026-07-19 18:56:27.808291+00	\N	154	published
4d51480b-62d4-4e80-9e0d-788e06b9de9e	actor_417	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.483426+00	2026-07-19 19:48:41.483435+00	2026-07-19 19:48:41.483438+00	\N	157	published
89253a08-ed05-452e-966f-d7b8115fbf03	character_269149_417	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.51114+00	2026-07-19 19:48:41.511142+00	2026-07-19 19:48:41.511143+00	\N	157	published
de7a2e08-de57-4c26-918b-0bc5c175760e	actor_23532	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.518428+00	2026-07-19 19:48:41.518429+00	2026-07-19 19:48:41.51843+00	\N	157	published
39134944-dfa8-4c1b-ba5a-887b0125c67c	character_269149_23532	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.521861+00	2026-07-19 19:48:41.521863+00	2026-07-19 19:48:41.521863+00	\N	157	published
e7c2c4d3-cc9c-4a7e-bda0-c5a7208c2d76	actor_17605	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.526346+00	2026-07-19 19:48:41.526347+00	2026-07-19 19:48:41.526348+00	\N	157	published
8c418373-1974-4784-8fa4-ddd8d6847cdb	character_269149_17605	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.53024+00	2026-07-19 19:48:41.530241+00	2026-07-19 19:48:41.530242+00	\N	157	published
4d282837-83a7-4203-88e6-4d4a7b00c624	actor_213001	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.535049+00	2026-07-19 19:48:41.53505+00	2026-07-19 19:48:41.535051+00	\N	157	published
758a85b5-ecd8-4c74-a4ec-571fe809c89d	character_269149_213001	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.53846+00	2026-07-19 19:48:41.538462+00	2026-07-19 19:48:41.538462+00	\N	157	published
4b0bed58-440b-420e-ac2c-fd232ae80222	actor_41565	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.543404+00	2026-07-19 19:48:41.543406+00	2026-07-19 19:48:41.543406+00	\N	157	published
6967b660-ee0c-4349-be84-c4a141974b91	character_269149_41565	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.547348+00	2026-07-19 19:48:41.547349+00	2026-07-19 19:48:41.54735+00	\N	157	published
3c62d619-d614-464c-9e6a-bf5af782d2e5	actor_5149	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.552123+00	2026-07-19 19:48:41.552124+00	2026-07-19 19:48:41.552125+00	\N	157	published
baee7a49-84af-4574-a6ed-519ef8ec16d0	character_269149_5149	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.555506+00	2026-07-19 19:48:41.555508+00	2026-07-19 19:48:41.555508+00	\N	157	published
768b0ca6-cd5e-421f-b1fc-37ebdf55525a	actor_27530	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.560256+00	2026-07-19 19:48:41.560257+00	2026-07-19 19:48:41.560258+00	\N	157	published
336c833e-2a5d-4d89-84a5-bd439126cc41	character_269149_27530	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.563616+00	2026-07-19 19:48:41.563617+00	2026-07-19 19:48:41.563618+00	\N	157	published
1ebc284d-9509-449e-82a9-11fbafa60126	actor_63208	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.568195+00	2026-07-19 19:48:41.568197+00	2026-07-19 19:48:41.568197+00	\N	157	published
d25ceccc-8274-4b2f-a178-f3b87acbaa28	character_269149_63208	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.57172+00	2026-07-19 19:48:41.571722+00	2026-07-19 19:48:41.571722+00	\N	157	published
28a1a6b1-1903-44a2-9e92-bb6c30ce17ad	actor_18999	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.576231+00	2026-07-19 19:48:41.576232+00	2026-07-19 19:48:41.576233+00	\N	157	published
c5b29f37-2299-49b4-b42b-1891b9650e4a	character_269149_18999	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.57959+00	2026-07-19 19:48:41.579592+00	2026-07-19 19:48:41.579592+00	\N	157	published
ec1e4fa0-b379-40d7-a304-53f121c7dcd1	actor_6944	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.584291+00	2026-07-19 19:48:41.584292+00	2026-07-19 19:48:41.584293+00	\N	157	published
4aa2b2e2-0ba4-4a21-a2c3-ea96cad84fee	character_269149_6944	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.587627+00	2026-07-19 19:48:41.587629+00	2026-07-19 19:48:41.587629+00	\N	157	published
2c7cae86-9da7-4161-a1dc-c61585ef73e9	actor_21088	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.592247+00	2026-07-19 19:48:41.592248+00	2026-07-19 19:48:41.592249+00	\N	157	published
3db35cb3-700b-47e7-b923-e1e32b83bb2f	character_269149_21088	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.595332+00	2026-07-19 19:48:41.595333+00	2026-07-19 19:48:41.595333+00	\N	157	published
37beaa06-448e-41c1-a19b-9b90bbc5a8e2	actor_446511	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.599955+00	2026-07-19 19:48:41.599956+00	2026-07-19 19:48:41.599956+00	\N	157	published
bd7dfea1-7379-4774-9654-46ea90f5ed81	character_269149_446511	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.603192+00	2026-07-19 19:48:41.603194+00	2026-07-19 19:48:41.603194+00	\N	157	published
b6e7c077-56e0-4156-88e6-05a2a6ddd2d8	actor_1223658	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.607311+00	2026-07-19 19:48:41.607313+00	2026-07-19 19:48:41.607313+00	\N	157	published
b56cffab-b7e8-4f68-9a91-db0e683e1232	character_269149_1223658	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.610516+00	2026-07-19 19:48:41.610518+00	2026-07-19 19:48:41.610518+00	\N	157	published
aa1a3294-70ac-4c96-99fc-160aae00c0d1	actor_1610446	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.614716+00	2026-07-19 19:48:41.614718+00	2026-07-19 19:48:41.614718+00	\N	157	published
765237cf-fbcd-4b5b-9a34-4ea0f51ea5ce	character_269149_1610446	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.617764+00	2026-07-19 19:48:41.617765+00	2026-07-19 19:48:41.617766+00	\N	157	published
7d6ecb14-1cd7-41e1-8594-60efb56b832d	actor_34521	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.621912+00	2026-07-19 19:48:41.621914+00	2026-07-19 19:48:41.621914+00	\N	157	published
35b08f2f-cf9f-4af4-ba8d-6c7ee122b062	character_269149_34521	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.624946+00	2026-07-19 19:48:41.624947+00	2026-07-19 19:48:41.624948+00	\N	157	published
2c52c7a0-b375-40a7-89fb-7aa37e426655	director_76595	a0000000-0000-0000-0000-000000000003	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.629045+00	2026-07-19 19:48:41.629047+00	2026-07-19 19:48:41.629047+00	\N	157	published
98f27997-e5e8-47b6-93de-a2da4cda2af3	director_165787	a0000000-0000-0000-0000-000000000003	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:48:41.632366+00	2026-07-19 19:48:41.632367+00	2026-07-19 19:48:41.632367+00	\N	157	published
ae4f652d-0f13-4bf5-9e56-91e094533563	zveropolis	a0000000-0000-0000-0000-000000000001	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 12:53:24.170995+00	2026-07-19 19:49:08.049081+00	2026-07-19 12:53:24.170999+00	\N	145	published
87814d62-16a3-4e34-8dc0-03ec5a78f28d	actor_8891	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.900119+00	2026-07-19 19:59:31.900125+00	2026-07-19 19:59:31.900126+00	\N	158	published
7c69de82-5026-43f1-a6c2-b43523920b15	character_680_8891	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.909602+00	2026-07-19 19:59:31.909604+00	2026-07-19 19:59:31.909605+00	\N	158	published
220e556b-14bd-48d3-9360-96018d7ac784	actor_2231	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.914836+00	2026-07-19 19:59:31.914837+00	2026-07-19 19:59:31.914837+00	\N	158	published
d1a6f8bc-0d39-4a37-8a58-d9f44bb87212	character_680_2231	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.918008+00	2026-07-19 19:59:31.91801+00	2026-07-19 19:59:31.91801+00	\N	158	published
59fd53ef-6ef3-4881-9773-9a6db97ae7d8	actor_139	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.922147+00	2026-07-19 19:59:31.922148+00	2026-07-19 19:59:31.922149+00	\N	158	published
be680376-546c-4896-aee1-b567e094396f	character_680_139	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.925135+00	2026-07-19 19:59:31.925136+00	2026-07-19 19:59:31.925137+00	\N	158	published
a77e6546-5b15-4eb5-a847-7a3db999431b	actor_62	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.929235+00	2026-07-19 19:59:31.929236+00	2026-07-19 19:59:31.929236+00	\N	158	published
f8082a95-3a70-4103-a9ca-615731d702fe	character_680_62	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.932225+00	2026-07-19 19:59:31.932227+00	2026-07-19 19:59:31.932227+00	\N	158	published
54c31fa7-0f61-4967-8057-1acde78186c7	actor_10182	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.936198+00	2026-07-19 19:59:31.936199+00	2026-07-19 19:59:31.936199+00	\N	158	published
c8d15721-a419-4cab-9bfc-b6e7249c77bb	character_680_10182	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.939686+00	2026-07-19 19:59:31.939688+00	2026-07-19 19:59:31.939689+00	\N	158	published
e09eeed4-6e9e-4ce5-a66b-3b62e9884d23	actor_1037	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.943808+00	2026-07-19 19:59:31.943809+00	2026-07-19 19:59:31.94381+00	\N	158	published
e12285f3-076b-473e-82ff-e7a8517d49ac	character_680_1037	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.946783+00	2026-07-19 19:59:31.946784+00	2026-07-19 19:59:31.946784+00	\N	158	published
fd2725fe-9094-4e29-91a4-afdfe3877e4c	actor_7036	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.950843+00	2026-07-19 19:59:31.950844+00	2026-07-19 19:59:31.950844+00	\N	158	published
ce98a882-8980-43eb-9995-019b022df28a	character_680_7036	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.954017+00	2026-07-19 19:59:31.954018+00	2026-07-19 19:59:31.954018+00	\N	158	published
d631016e-2a42-42af-95a8-a225eb96a473	actor_3129	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.958163+00	2026-07-19 19:59:31.958164+00	2026-07-19 19:59:31.958164+00	\N	158	published
60a01a47-e33f-48ec-929b-dbe3da458d08	character_680_3129	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.961195+00	2026-07-19 19:59:31.961197+00	2026-07-19 19:59:31.961197+00	\N	158	published
86e86f24-6bda-490f-88e6-ba92c365dbd0	actor_99	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.965202+00	2026-07-19 19:59:31.965203+00	2026-07-19 19:59:31.965204+00	\N	158	published
b97431db-599d-4e5f-be33-19c579f1b942	character_680_99	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.968203+00	2026-07-19 19:59:31.968204+00	2026-07-19 19:59:31.968205+00	\N	158	published
ad618e1d-d36b-4937-8037-515d6fad866c	actor_2319	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.975764+00	2026-07-19 19:59:31.975767+00	2026-07-19 19:59:31.975768+00	\N	158	published
35476ee0-ad26-4c7d-9d7d-e82f46d5b1cb	character_680_2319	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.981843+00	2026-07-19 19:59:31.981845+00	2026-07-19 19:59:31.981846+00	\N	158	published
d99db646-f219-44f4-8ff2-387ba5ceddb6	actor_138	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.988929+00	2026-07-19 19:59:31.988932+00	2026-07-19 19:59:31.988934+00	\N	158	published
7df1ed35-88e8-490e-a5dc-7791684c1cde	character_680_138	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:31.995809+00	2026-07-19 19:59:31.995812+00	2026-07-19 19:59:31.995813+00	\N	158	published
da298a62-6ff0-43b8-b9ad-008800d934b4	actor_4690	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:32.003008+00	2026-07-19 19:59:32.00301+00	2026-07-19 19:59:32.003011+00	\N	158	published
0d569910-8953-486f-85c4-3540d8efc979	character_680_4690	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:32.006641+00	2026-07-19 19:59:32.006642+00	2026-07-19 19:59:32.006643+00	\N	158	published
adb70f3f-257f-4b66-beea-2d0ff3142eea	actor_2165	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:32.012349+00	2026-07-19 19:59:32.012352+00	2026-07-19 19:59:32.012352+00	\N	158	published
d870f544-ea59-412e-868d-8f1281cbad95	character_680_2165	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:32.018121+00	2026-07-19 19:59:32.018122+00	2026-07-19 19:59:32.018123+00	\N	158	published
d295ce90-1f32-463b-9a7d-cb77d4ba8fe9	actor_11803	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:32.022953+00	2026-07-19 19:59:32.022955+00	2026-07-19 19:59:32.022955+00	\N	158	published
42fb105e-da54-46c4-9612-325bb33f4512	character_680_11803	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:32.026035+00	2026-07-19 19:59:32.026037+00	2026-07-19 19:59:32.026037+00	\N	158	published
e248cb29-34df-4aa2-bc9a-7ad069d9b043	actor_11804	a0000000-0000-0000-0000-000000000002	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:32.031539+00	2026-07-19 19:59:32.031541+00	2026-07-19 19:59:32.031542+00	\N	158	published
fd29096b-43b9-4e34-9f08-caeabc31b545	character_680_11804	e0480aef-9629-440d-b15f-15f8f20f20b0	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:32.035015+00	2026-07-19 19:59:32.035017+00	2026-07-19 19:59:32.035017+00	\N	158	published
2fe65b14-7a7f-4c13-868c-115bf8430f0a	director_138	a0000000-0000-0000-0000-000000000003	active	\N	\N	a1000000-0000-0000-0000-000000000001	2026-07-19 19:59:32.039054+00	2026-07-19 19:59:32.039056+00	2026-07-19 19:59:32.039056+00	\N	158	published
\.


--
-- Data for Name: entity_kind; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.entity_kind (kind_id, kind_code, parent_kind_id, description, is_abstract, sort_order, version_id, created_at, field_schema) FROM stdin;
a0000000-0000-0000-0000-000000000012	plant	\N	Растение	f	12	1	2026-07-18 09:56:49.89334+00	[]
a0000000-0000-0000-0000-000000000015	phenomenon	\N	Явление	f	15	1	2026-07-18 09:56:49.89334+00	[]
a0000000-0000-0000-0000-000000000016	period	\N	Эпоха	f	16	1	2026-07-18 09:56:49.89334+00	[]
a0000000-0000-0000-0000-000000000017	digital_file	\N	Файл	f	17	1	2026-07-18 09:56:49.89334+00	[]
a0000000-0000-0000-0000-000000000018	movement	\N	Движение	f	18	1	2026-07-18 09:56:49.89334+00	[]
a0000000-0000-0000-0000-000000000019	classifier	\N	Классификатор	f	19	1	2026-07-18 09:56:49.89334+00	[]
a0000000-0000-0000-0000-000000000020	physical_item	\N	Предмет	f	20	1	2026-07-18 09:56:49.89334+00	[]
a0000000-0000-0000-0000-000000000021	photo	\N	Фото	f	21	1	2026-07-18 09:56:49.89334+00	[]
a0000000-0000-0000-0000-000000000022	article	\N	Статья	f	22	1	2026-07-18 09:56:49.89334+00	[]
b0000000-0000-0000-0000-000000000001	organization	\N	Организация	f	26	1	2026-07-18 09:56:49.89334+00	[]
b0000000-0000-0000-0000-000000000002	event	\N	Событие	f	27	1	2026-07-18 09:56:49.89334+00	[]
b0000000-0000-0000-0000-000000000003	award	\N	Награда	f	28	1	2026-07-18 09:56:49.89334+00	[]
b0000000-0000-0000-0000-000000000004	collection	\N	Коллекция	f	29	1	2026-07-18 09:56:49.89334+00	[]
b0000000-0000-0000-0000-000000000005	tag	\N	Тег	f	30	1	2026-07-18 09:56:49.89334+00	[]
b0000000-0000-0000-0000-000000000006	language_entity	\N	Язык	f	31	1	2026-07-18 09:56:49.89334+00	[]
b0000000-0000-0000-0000-000000000007	currency	\N	Валюта	f	32	1	2026-07-18 09:56:49.89334+00	[]
b0000000-0000-0000-0000-000000000008	unit	\N	Единица измерения	f	33	1	2026-07-18 09:56:49.89334+00	[]
b0000000-0000-0000-0000-000000000009	formula	\N	Формула	f	34	1	2026-07-18 09:56:49.89334+00	[]
b0000000-0000-0000-0000-000000000010	theorem	\N	Теорема	f	35	1	2026-07-18 09:56:49.89334+00	[]
b0000000-0000-0000-0000-000000000011	software	\N	Программа	f	36	1	2026-07-18 09:56:49.89334+00	[]
b0000000-0000-0000-0000-000000000012	game	\N	Игра	f	37	1	2026-07-18 09:56:49.89334+00	[]
b0000000-0000-0000-0000-000000000013	podcast	\N	Подкаст	f	38	1	2026-07-18 09:56:49.89334+00	[]
b0000000-0000-0000-0000-000000000014	channel	\N	Канал	f	39	1	2026-07-18 09:56:49.89334+00	[]
b0000000-0000-0000-0000-000000000015	label_entity	\N	Лейбл	f	40	1	2026-07-18 09:56:49.89334+00	[]
a0000000-0000-0000-0000-000000000002	actor	\N	Актёр	f	2	1	2026-07-18 09:56:49.89334+00	[{"key": "first_name", "type": "string", "label": "Имя", "required": true}, {"key": "last_name", "type": "string", "label": "Фамилия", "required": true}, {"key": "birth_date", "type": "date", "label": "Дата рождения"}, {"key": "birth_place", "type": "string", "label": "Место рождения"}, {"key": "nationality", "type": "string", "label": "Национальность"}, {"key": "height_cm", "type": "integer", "label": "Рост (см)"}]
a0000000-0000-0000-0000-000000000008	writer	\N	Писатель	f	8	1	2026-07-18 09:56:49.89334+00	[{"key": "first_name", "type": "string", "label": "Имя", "required": true}, {"key": "last_name", "type": "string", "label": "Фамилия", "required": true}, {"key": "birth_date", "type": "date", "label": "Дата рождения"}, {"key": "birth_place", "type": "string", "label": "Место рождения"}, {"key": "nationality", "type": "string", "label": "Национальность"}, {"key": "occupation", "type": "string", "label": "Профессия"}, {"key": "photo", "type": "url", "label": "Фото (URL)"}, {"key": "biography", "type": "text", "label": "Биография"}]
a0000000-0000-0000-0000-000000000013	concept	\N	Концепция	f	13	1	2026-07-18 09:56:49.89334+00	[{"key": "name", "type": "string", "label": "Название", "required": true}, {"key": "definition", "type": "text", "label": "Определение"}, {"key": "domain", "type": "string", "label": "Домен"}, {"key": "description", "type": "text", "label": "Описание"}]
a0000000-0000-0000-0000-000000000003	director	\N	Режиссёр	f	3	1	2026-07-18 09:56:49.89334+00	[{"key": "first_name", "type": "string", "label": "Имя", "required": true}, {"key": "last_name", "type": "string", "label": "Фамилия", "required": true}, {"key": "birth_date", "type": "date", "label": "Дата рождения"}, {"key": "birth_place", "type": "string", "label": "Место рождения"}, {"key": "nationality", "type": "string", "label": "Национальность"}]
a0000000-0000-0000-0000-000000000023	human	\N	Человек	f	23	1	2026-07-18 09:56:49.89334+00	[{"key": "first_name", "type": "string", "label": "Имя", "required": true}, {"key": "last_name", "type": "string", "label": "Фамилия", "required": true}, {"key": "birth_date", "type": "date", "label": "Дата рождения"}, {"key": "birth_place", "type": "string", "label": "Место рождения"}, {"key": "nationality", "type": "string", "label": "Национальность"}, {"key": "occupation", "type": "string", "label": "Профессия"}, {"key": "photo", "type": "url", "label": "Фото (URL)"}, {"key": "biography", "type": "text", "label": "Биография"}]
a0000000-0000-0000-0000-000000000024	artist	\N	Художник	f	24	1	2026-07-18 09:56:49.89334+00	[{"key": "first_name", "type": "string", "label": "Имя", "required": true}, {"key": "last_name", "type": "string", "label": "Фамилия", "required": true}, {"key": "birth_date", "type": "date", "label": "Дата рождения"}, {"key": "birth_place", "type": "string", "label": "Место рождения"}, {"key": "nationality", "type": "string", "label": "Национальность"}, {"key": "occupation", "type": "string", "label": "Профессия"}, {"key": "photo", "type": "url", "label": "Фото (URL)"}, {"key": "biography", "type": "text", "label": "Биография"}]
a0000000-0000-0000-0000-000000000025	scientist	\N	Учёный	f	25	1	2026-07-18 09:56:49.89334+00	[{"key": "first_name", "type": "string", "label": "Имя", "required": true}, {"key": "last_name", "type": "string", "label": "Фамилия", "required": true}, {"key": "birth_date", "type": "date", "label": "Дата рождения"}, {"key": "birth_place", "type": "string", "label": "Место рождения"}, {"key": "nationality", "type": "string", "label": "Национальность"}, {"key": "occupation", "type": "string", "label": "Профессия"}, {"key": "photo", "type": "url", "label": "Фото (URL)"}, {"key": "biography", "type": "text", "label": "Биография"}]
a0000000-0000-0000-0000-000000000006	album	\N	Альбом	f	6	1	2026-07-18 09:56:49.89334+00	[{"key": "title", "type": "string", "label": "Название", "required": true}, {"key": "artist", "type": "string", "label": "Исполнитель"}, {"key": "year", "type": "integer", "label": "Год"}, {"key": "tracks", "type": "integer", "label": "Треков"}, {"key": "genre", "type": "string", "label": "Жанр"}, {"key": "label_name", "type": "string", "label": "Лейбл"}, {"key": "cover", "type": "url", "label": "Обложка (URL)"}, {"key": "description", "type": "text", "label": "Описание"}]
a0000000-0000-0000-0000-000000000010	chemical_element	\N	Химический элемент	f	10	1	2026-07-18 09:56:49.89334+00	[{"key": "symbol", "type": "string", "label": "Символ", "required": true}, {"key": "name", "type": "string", "label": "Название", "required": true}, {"key": "atomic_number", "type": "integer", "label": "Атомный номер"}, {"key": "atomic_mass", "type": "number", "label": "Атомная масса"}, {"key": "group", "type": "integer", "label": "Группа"}, {"key": "period", "type": "integer", "label": "Период"}, {"key": "category", "type": "string", "label": "Категория"}, {"key": "description", "type": "text", "label": "Описание"}]
a0000000-0000-0000-0000-000000000011	animal	\N	Животное	f	11	1	2026-07-18 09:56:49.89334+00	[{"key": "name", "type": "string", "label": "Название", "required": true}, {"key": "species", "type": "string", "label": "Вид"}, {"key": "class", "type": "string", "label": "Класс"}, {"key": "habitat", "type": "string", "label": "Среда обитания"}, {"key": "diet", "type": "string", "label": "Питание"}, {"key": "lifespan_years", "type": "integer", "label": "Продолжительность жизни"}, {"key": "description", "type": "text", "label": "Описание"}]
a0000000-0000-0000-0000-000000000014	genre	\N	Жанр	f	14	1	2026-07-18 09:56:49.89334+00	[{"key": "name", "type": "string", "label": "Название", "required": true}, {"key": "description", "type": "text", "label": "Описание"}]
a0000000-0000-0000-0000-000000000005	musician	\N	Музыкант	f	5	1	2026-07-18 09:56:49.89334+00	[{"key": "first_name", "type": "string", "label": "Имя", "required": true}, {"key": "last_name", "type": "string", "label": "Фамилия", "required": true}, {"key": "birth_date", "type": "date", "label": "Дата рождения"}, {"key": "death_date", "type": "date", "label": "Дата смерти"}, {"key": "birth_place", "type": "string", "label": "Место рождения"}, {"key": "occupation", "type": "string", "label": "Профессия"}]
a0000000-0000-0000-0000-000000000007	book	\N	Книга	f	7	1	2026-07-18 09:56:49.89334+00	[{"key": "title", "type": "string", "label": "Название", "required": true}, {"key": "author", "type": "string", "label": "Автор", "required": true}, {"key": "year", "type": "integer", "label": "Год"}, {"key": "genre", "type": "string", "label": "Жанр"}, {"key": "pages", "type": "integer", "label": "Страниц"}, {"key": "publisher", "type": "string", "label": "Издательство"}, {"key": "isbn", "type": "string", "label": "ISBN"}, {"key": "language", "type": "string", "label": "Язык"}]
a0000000-0000-0000-0000-000000000004	song	\N	Песня	f	4	1	2026-07-18 09:56:49.89334+00	[{"key": "title", "type": "string", "label": "Название", "required": true}, {"key": "artist", "type": "string", "label": "Исполнитель", "required": true}, {"key": "album", "type": "string", "label": "Альбом"}, {"key": "year", "type": "integer", "label": "Год"}, {"key": "duration", "type": "integer", "label": "Длительность (сек)"}, {"key": "key", "type": "string", "label": "Тональность"}]
a0000000-0000-0000-0000-000000000009	place	\N	Место	f	9	1	2026-07-18 09:56:49.89334+00	[{"key": "name", "type": "string", "label": "Название", "required": true}, {"key": "country", "type": "string", "label": "Страна"}, {"key": "latitude", "type": "number", "label": "Широта"}, {"key": "longitude", "type": "number", "label": "Долгота"}, {"key": "population", "type": "integer", "label": "Население"}, {"key": "timezone", "type": "string", "label": "Часовой пояс"}, {"key": "area_km2", "type": "number", "label": "Площадь (км²)"}]
06125618-0d99-40fc-ac91-44cc8207a434	field	\N	Поле реестра	f	999	1	2026-07-18 20:49:36.139473+00	{"required": [], "properties": {"category": {"type": "string", "title": "Категория"}, "field_key": {"type": "string", "title": "Ключ"}, "field_type": {"type": "string", "title": "Тип"}, "default_value": {"type": "string", "title": "Значение по умолчанию"}}}
92f3be1c-718d-4059-9485-80c75fa959e5	ontology_model	\N	Онтологическая модель — определяет домен и структуру данных	f	998	1	2026-07-19 08:16:25.856956+00	{"required": ["model_code", "domain"], "properties": {"domain": {"type": "string", "title": "Домен"}, "model_code": {"type": "string", "title": "Код модели"}, "description": {"type": "string", "title": "Описание"}}}
1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	ontology_template	\N	Шаблон онтологии — определяет схему полей и макет для типа сущности	f	997	1	2026-07-19 08:16:25.856956+00	{"required": ["template_code", "template_name"], "properties": {"kind_code": {"type": "string", "title": "Тип сущности"}, "model_code": {"type": "string", "title": "Модель"}, "description": {"type": "string", "title": "Описание"}, "template_code": {"type": "string", "title": "Код шаблона"}, "template_name": {"type": "string", "title": "Название шаблона"}}}
a0000000-0000-0000-0000-000000000001	movie	\N		f	0	1	2026-07-18 09:56:49.89334+00	{"required": [], "properties": {"year": {"type": "integer", "title": "Год"}, "genre": {"type": "string", "title": "Жанр"}, "budget": {"type": "string", "title": "Бюджет"}, "rating": {"type": "number", "title": "Рейтинг"}, "country": {"type": "string", "title": "Страна"}, "imdb_id": {"type": "string", "title": "IMDb ID"}, "tagline": {"type": "string", "title": "Слоган"}, "tmdb_id": {"type": "string", "title": "TMDb ID"}, "director": {"type": "string", "title": "Режиссёр"}, "duration": {"type": "string", "title": "Длительность"}, "language": {"type": "string", "title": "Язык"}, "age_rating": {"type": "string", "title": "Возрастной рейтинг"}, "description": {"type": "string", "title": "Описание"}, "production_company": {"type": "string", "title": "Кинокомпания"}}, "field_order": ["year", "genre", "budget", "rating", "country", "tagline", "director", "duration", "language", "production_company", "age_rating", "imdb_id", "tmdb_id", "description"]}
e0480aef-9629-440d-b15f-15f8f20f20b0	character	\N	Auto-created kind	f	999	1	2026-07-19 18:54:13.832284+00	{"required": [], "properties": {"name": "Имя", "tmdb_id": "TMDB_ID", "character_of": "Актёр"}}
\.


--
-- Data for Name: entity_kind_label; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.entity_kind_label (kind_id, language, label, description) FROM stdin;
a0000000-0000-0000-0000-000000000001	en	Movie	Film
a0000000-0000-0000-0000-000000000002	ru	Актёр	Актёр кино и театра
a0000000-0000-0000-0000-000000000002	en	Actor	Film and stage actor
a0000000-0000-0000-0000-000000000003	ru	Режиссёр	Режиссёр кино
a0000000-0000-0000-0000-000000000003	en	Director	Film director
a0000000-0000-0000-0000-000000000004	ru	Песня	Музыкальное произведение
a0000000-0000-0000-0000-000000000004	en	Song	Musical composition
a0000000-0000-0000-0000-000000000005	ru	Музыкант	Исполнитель музыки
a0000000-0000-0000-0000-000000000005	en	Musician	Music performer
a0000000-0000-0000-0000-000000000006	ru	Альбом	Музыкальный альбом
a0000000-0000-0000-0000-000000000006	en	Album	Music album
a0000000-0000-0000-0000-000000000007	ru	Книга	Книжное издание
a0000000-0000-0000-0000-000000000007	en	Book	Book publication
a0000000-0000-0000-0000-000000000008	ru	Писатель	Автор книг
a0000000-0000-0000-0000-000000000008	en	Writer	Book author
a0000000-0000-0000-0000-000000000009	ru	Место	Географическое место
a0000000-0000-0000-0000-000000000009	en	Place	Geographic place
a0000000-0000-0000-0000-000000000010	ru	Химический элемент	Элемент периодической таблицы
a0000000-0000-0000-0000-000000000010	en	Chemical Element	Periodic table element
a0000000-0000-0000-0000-000000000011	ru	Животное	Живое существо
a0000000-0000-0000-0000-000000000011	en	Animal	Living creature
a0000000-0000-0000-0000-000000000012	ru	Растение	Растительный организм
a0000000-0000-0000-0000-000000000012	en	Plant	Plant organism
a0000000-0000-0000-0000-000000000013	ru	Концепция	Абстрактная идея
a0000000-0000-0000-0000-000000000013	en	Concept	Abstract idea
a0000000-0000-0000-0000-000000000014	ru	Жанр	Творческое направление
a0000000-0000-0000-0000-000000000014	en	Genre	Creative direction
a0000000-0000-0000-0000-000000000015	ru	Явление	Наблюдаемый процесс
a0000000-0000-0000-0000-000000000015	en	Phenomenon	Observable process
a0000000-0000-0000-0000-000000000016	ru	Эпоха	Исторический период
a0000000-0000-0000-0000-000000000016	en	Period	Historical era
a0000000-0000-0000-0000-000000000017	ru	Файл	Цифровой файл
a0000000-0000-0000-0000-000000000017	en	Digital File	Digital file
a0000000-0000-0000-0000-000000000018	ru	Движение	Социальное или культурное движение
a0000000-0000-0000-0000-000000000018	en	Movement	Social or cultural movement
a0000000-0000-0000-0000-000000000019	ru	Классификатор	Система классификации
a0000000-0000-0000-0000-000000000019	en	Classifier	Classification system
a0000000-0000-0000-0000-000000000020	ru	Предмет	Физический объект
a0000000-0000-0000-0000-000000000020	en	Physical Item	Physical object
a0000000-0000-0000-0000-000000000021	ru	Фото	Фотография
a0000000-0000-0000-0000-000000000021	en	Photo	Photograph
a0000000-0000-0000-0000-000000000022	ru	Статья	Опубликованная статья
a0000000-0000-0000-0000-000000000022	en	Article	Published article
a0000000-0000-0000-0000-000000000023	ru	Человек	Персона
a0000000-0000-0000-0000-000000000023	en	Human	Person
a0000000-0000-0000-0000-000000000024	ru	Художник	Творец изобразительного искусства
a0000000-0000-0000-0000-000000000024	en	Artist	Visual art creator
a0000000-0000-0000-0000-000000000025	ru	Учёный	Исследователь
a0000000-0000-0000-0000-000000000025	en	Scientist	Researcher
b0000000-0000-0000-0000-000000000001	ru	Организация	Организация или компания
b0000000-0000-0000-0000-000000000001	en	Organization	Organization or company
b0000000-0000-0000-0000-000000000002	ru	Событие	Событие или мероприятие
b0000000-0000-0000-0000-000000000002	en	Event	Event or occurrence
b0000000-0000-0000-0000-000000000003	ru	Награда	Награда или премия
b0000000-0000-0000-0000-000000000003	en	Award	Award or prize
b0000000-0000-0000-0000-000000000004	ru	Коллекция	Коллекция или подборка
b0000000-0000-0000-0000-000000000004	en	Collection	Collection or compilation
b0000000-0000-0000-0000-000000000005	ru	Тег	Тег или метка
b0000000-0000-0000-0000-000000000005	en	Tag	Tag or label
b0000000-0000-0000-0000-000000000006	ru	Язык	Язык программирования или общения
b0000000-0000-0000-0000-000000000006	en	Language	Programming or natural language
b0000000-0000-0000-0000-000000000007	ru	Валюта	Денежная единица
b0000000-0000-0000-0000-000000000007	en	Currency	Monetary unit
b0000000-0000-0000-0000-000000000008	ru	Единица измерения	Единица измерения
b0000000-0000-0000-0000-000000000008	en	Unit of Measurement	Unit of measurement
b0000000-0000-0000-0000-000000000009	ru	Формула	Научная формула
b0000000-0000-0000-0000-000000000009	en	Formula	Scientific formula
b0000000-0000-0000-0000-000000000010	ru	Теорема	Математическая или научная теорема
b0000000-0000-0000-0000-000000000010	en	Theorem	Mathematical or scientific theorem
b0000000-0000-0000-0000-000000000011	ru	Программа	Программное обеспечение
b0000000-0000-0000-0000-000000000011	en	Software	Software application
b0000000-0000-0000-0000-000000000012	ru	Игра	Видеоигра или настольная игра
b0000000-0000-0000-0000-000000000012	en	Game	Video or board game
b0000000-0000-0000-0000-000000000013	ru	Подкаст	Аудиоподкаст
b0000000-0000-0000-0000-000000000013	en	Podcast	Audio podcast
b0000000-0000-0000-0000-000000000014	ru	Канал	Видео- или аудиоканал
b0000000-0000-0000-0000-000000000014	en	Channel	Video or audio channel
b0000000-0000-0000-0000-000000000015	ru	Лейбл	Музыкальный или издательский лейбл
b0000000-0000-0000-0000-000000000015	en	Label	Music or publishing label
06125618-0d99-40fc-ac91-44cc8207a434	ru	Поле	Элемент реестра полей
06125618-0d99-40fc-ac91-44cc8207a434	en	Field	Field registry element
92f3be1c-718d-4059-9485-80c75fa959e5	ru	Онтологическая модель	Модель онтологии
a0000000-0000-0000-0000-000000000001	ru	Фильмы	Кинофильм
92f3be1c-718d-4059-9485-80c75fa959e5	en	Ontology Model	Ontology model definition
1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	ru	Шаблон онтологии	Шаблон для типа сущности
1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	en	Ontology Template	Template for entity kind
e0480aef-9629-440d-b15f-15f8f20f20b0	ru	Персонаж	Auto-created
e0480aef-9629-440d-b15f-15f8f20f20b0	en	Character	\N
\.


--
-- Data for Name: entity_kind_relation_constraint; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.entity_kind_relation_constraint (constraint_id, from_kind_id, relation_code, to_kind_id, is_allowed, description) FROM stdin;
\.


--
-- Data for Name: entity_label; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.entity_label (entity_label_id, entity_id, language, label, description, content, is_primary, owner_id, version_id) FROM stdin;
2	d0000001-0000-0000-0000-000000000001	en	The Matrix	1999 science fiction film	\N	t	\N	1
3	d0000001-0000-0000-0000-000000000002	ru	Начало	Фильм Кристофера Нолана 2010 года	\N	t	\N	1
4	d0000001-0000-0000-0000-000000000002	en	Inception	2010 film by Christopher Nolan	\N	t	\N	1
5	d0000002-0000-0000-0000-000000000001	ru	Киану Ривз	Канадский актёр	\N	t	\N	1
6	d0000002-0000-0000-0000-000000000001	en	Keanu Reeves	Canadian actor	\N	t	\N	1
7	d0000002-0000-0000-0000-000000000002	ru	Леонардо ДиКаприо	Американский актёр	\N	t	\N	1
8	d0000002-0000-0000-0000-000000000002	en	Leonardo DiCaprio	American actor	\N	t	\N	1
9	d0000003-0000-0000-0000-000000000001	ru	Братья Вачовски	Американские режиссёры	\N	t	\N	1
10	d0000003-0000-0000-0000-000000000001	en	The Wachowskis	American directors	\N	t	\N	1
11	d0000003-0000-0000-0000-000000000002	ru	Кристофер Нолан	Британско-американский режиссёр	\N	t	\N	1
12	d0000003-0000-0000-0000-000000000002	en	Christopher Nolan	British-American director	\N	t	\N	1
13	d0000004-0000-0000-0000-000000000001	ru	Голубой Дунай	Вальс Иоганна Штрауса	\N	t	\N	1
14	d0000004-0000-0000-0000-000000000001	en	The Blue Danube	Waltz by Johann Strauss II	\N	t	\N	1
15	d0000004-0000-0000-0000-000000000002	ru	Богемская рапсодия	Песня группы Queen	\N	t	\N	1
16	d0000004-0000-0000-0000-000000000002	en	Bohemian Rhapsody	Song by Queen	\N	t	\N	1
17	d0000005-0000-0000-0000-000000000001	ru	Иоганн Штраус	Австрийский композитор	\N	t	\N	1
18	d0000005-0000-0000-0000-000000000001	en	Johann Strauss II	Austrian composer	\N	t	\N	1
19	d0000005-0000-0000-0000-000000000002	ru	Фредди Меркьюри	Британский певец	\N	t	\N	1
20	d0000005-0000-0000-0000-000000000002	en	Freddie Mercury	British singer	\N	t	\N	1
21	d0000006-0000-0000-0000-000000000001	ru	Ночь в опере	Альбом группы Queen	\N	t	\N	1
22	d0000006-0000-0000-0000-000000000001	en	A Night at the Opera	Album by Queen	\N	t	\N	1
23	d0000006-0000-0000-0000-000000000002	ru	Лучшие хиты	Сборник хитов Queen	\N	t	\N	1
24	d0000006-0000-0000-0000-000000000002	en	Greatest Hits	Queen compilation album	\N	t	\N	1
26	d0000007-0000-0000-0000-000000000001	en	Neuromancer	Novel by William Gibson	\N	t	\N	1
27	d0000007-0000-0000-0000-000000000002	ru	Дюна	Роман Фрэнка Герберта	\N	t	\N	1
28	d0000007-0000-0000-0000-000000000002	en	Dune	Novel by Frank Herbert	\N	t	\N	1
29	d0000008-0000-0000-0000-000000000001	ru	Уильям Гибсон	Американский писатель	\N	t	\N	1
30	d0000008-0000-0000-0000-000000000001	en	William Gibson	American writer	\N	t	\N	1
31	d0000008-0000-0000-0000-000000000002	ru	Фрэнк Герберт	Американский писатель	\N	t	\N	1
32	d0000008-0000-0000-0000-000000000002	en	Frank Herbert	American writer	\N	t	\N	1
33	d0000009-0000-0000-0000-000000000001	ru	Москва	Столица России	\N	t	\N	1
34	d0000009-0000-0000-0000-000000000001	en	Moscow	Capital of Russia	\N	t	\N	1
35	d0000009-0000-0000-0000-000000000002	ru	Париж	Столица Франции	\N	t	\N	1
36	d0000009-0000-0000-0000-000000000002	en	Paris	Capital of France	\N	t	\N	1
37	d0000009-0000-0000-0000-000000000003	ru	Токио	Столица Японии	\N	t	\N	1
38	d0000009-0000-0000-0000-000000000003	en	Tokyo	Capital of Japan	\N	t	\N	1
39	d0000010-0000-0000-0000-000000000001	ru	Водород	Химический элемент 1	\N	t	\N	1
40	d0000010-0000-0000-0000-000000000001	en	Hydrogen	Chemical element 1	\N	t	\N	1
41	d0000010-0000-0000-0000-000000000002	ru	Кислород	Химический элемент 8	\N	t	\N	1
42	d0000010-0000-0000-0000-000000000002	en	Oxygen	Chemical element 8	\N	t	\N	1
43	d0000010-0000-0000-0000-000000000003	ru	Углерод	Химический элемент 6	\N	t	\N	1
44	d0000010-0000-0000-0000-000000000003	en	Carbon	Chemical element 6	\N	t	\N	1
45	d0000011-0000-0000-0000-000000000001	ru	Волк	Хищное млекопитающее	\N	t	\N	1
46	d0000011-0000-0000-0000-000000000001	en	Wolf	Predatory mammal	\N	t	\N	1
47	d0000011-0000-0000-0000-000000000002	ru	Орёл	Хищная птица	\N	t	\N	1
48	d0000011-0000-0000-0000-000000000002	en	Eagle	Bird of prey	\N	t	\N	1
49	d0000011-0000-0000-0000-000000000003	ru	Дельфин	Морское млекопитающее	\N	t	\N	1
50	d0000011-0000-0000-0000-000000000003	en	Dolphin	Marine mammal	\N	t	\N	1
51	d0000013-0000-0000-0000-000000000001	ru	Киберпанк	Научно-фантастический жанр	\N	t	\N	1
52	d0000013-0000-0000-0000-000000000001	en	Cyberpunk	Science fiction genre	\N	t	\N	1
53	d0000013-0000-0000-0000-000000000002	ru	Демократия	Форма правления	\N	t	\N	1
54	d0000013-0000-0000-0000-000000000002	en	Democracy	Form of government	\N	t	\N	1
55	d0000013-0000-0000-0000-000000000003	ru	Искусственный интеллект	Технология ИИ	\N	t	\N	1
56	d0000013-0000-0000-0000-000000000003	en	Artificial Intelligence	AI technology	\N	t	\N	1
57	d0000014-0000-0000-0000-000000000001	ru	Научная фантастика	Жанр	\N	t	\N	1
58	d0000014-0000-0000-0000-000000000001	en	Science Fiction	Genre	\N	t	\N	1
59	d0000014-0000-0000-0000-000000000002	ru	Классическая музыка	Музыкальный жанр	\N	t	\N	1
60	d0000014-0000-0000-0000-000000000002	en	Classical Music	Music genre	\N	t	\N	1
61	d0000026-0000-0000-0000-000000000001	ru	Уорнер Бразерс	Киностудия	\N	t	\N	1
62	d0000026-0000-0000-0000-000000000001	en	Warner Bros.	Film studio	\N	t	\N	1
63	d0000026-0000-0000-0000-000000000002	ru	Парижская опера	Оперный театр	\N	t	\N	1
64	d0000026-0000-0000-0000-000000000002	en	Paris Opera	Opera house	\N	t	\N	1
66	d0000001-0000-0000-0000-000000000003	en	Interstellar	2014 sci-fi film by Christopher Nolan about space travel	\N	t	\N	1
68	d0000001-0000-0000-0000-000000000004	en	Fight Club	1999 film by David Fincher	\N	t	\N	1
71	d0000002-0000-0000-0000-000000000003	ru	Мэтт Деймон	Американский актёр, сценарист и продюсер	\N	t	\N	1
72	d0000002-0000-0000-0000-000000000003	en	Matt Damon	American actor, screenwriter and producer	\N	t	\N	1
73	d0000002-0000-0000-0000-000000000004	ru	Скарлетт Йоханссон	Американская актриса и певица	\N	t	\N	1
74	d0000002-0000-0000-0000-000000000004	en	Scarlett Johansson	American actress and singer	\N	t	\N	1
75	d0000002-0000-0000-0000-000000000005	ru	Райан Гослинг	Канадский актёр и музыкант	\N	t	\N	1
76	d0000002-0000-0000-0000-000000000005	en	Ryan Gosling	Canadian actor and musician	\N	t	\N	1
77	d0000003-0000-0000-0000-000000000003	ru	Дэвид Финчер	Американский режиссёр и продюсер	\N	t	\N	1
78	d0000003-0000-0000-0000-000000000003	en	David Fincher	American film director and producer	\N	t	\N	1
79	d0000003-0000-0000-0000-000000000004	ru	Дени Вильнёв	Канадский режиссёр	\N	t	\N	1
80	d0000003-0000-0000-0000-000000000004	en	Denis Villeneuve	Canadian film director	\N	t	\N	1
81	d0000003-0000-0000-0000-000000000005	ru	Ридли Скотт	Британский режиссёр и продюсер	\N	t	\N	1
82	d0000003-0000-0000-0000-000000000005	en	Ridley Scott	British film director and producer	\N	t	\N	1
83	d0000004-0000-0000-0000-000000000003	ru	Лестница в небо	Композиция Led Zeppelin	\N	t	\N	1
84	d0000004-0000-0000-0000-000000000003	en	Stairway to Heaven	Song by Led Zeppelin	\N	t	\N	1
85	d0000004-0000-0000-0000-000000000004	ru	Отель «Калифорния»	Композиция Eagles	\N	t	\N	1
86	d0000004-0000-0000-0000-000000000004	en	Hotel California	Song by Eagles	\N	t	\N	1
87	d0000004-0000-0000-0000-000000000005	ru	Представь	Композиция Джона Леннона	\N	t	\N	1
88	d0000004-0000-0000-0000-000000000005	en	Imagine	Song by John Lennon	\N	t	\N	1
89	d0000005-0000-0000-0000-000000000003	ru	Джон Леннон	Британский музыкант, участник The Beatles	\N	t	\N	1
90	d0000005-0000-0000-0000-000000000003	en	John Lennon	British musician, member of The Beatles	\N	t	\N	1
91	d0000005-0000-0000-0000-000000000004	ru	Джими Хендрикс	Американский гитарист и певец	\N	t	\N	1
92	d0000005-0000-0000-0000-000000000004	en	Jimi Hendrix	American guitarist and singer	\N	t	\N	1
93	d0000005-0000-0000-0000-000000000005	ru	Элвис Пресли	Американский певец, «Король рок-н-ролла»	\N	t	\N	1
94	d0000005-0000-0000-0000-000000000005	en	Elvis Presley	American singer, King of Rock and Roll	\N	t	\N	1
95	d0000007-0000-0000-0000-000000000003	ru	1984	Антиутопический роман Джорджа Оруэлла	\N	t	\N	1
96	d0000007-0000-0000-0000-000000000003	en	Nineteen Eighty-Four	Dystopian novel by George Orwell	\N	t	\N	1
97	d0000007-0000-0000-0000-000000000004	ru	451 градус по Фаренгейту	Антиутопический роман Рея Брэдбери	\N	t	\N	1
98	d0000007-0000-0000-0000-000000000004	en	Fahrenheit 451	Dystopian novel by Ray Bradbury	\N	t	\N	1
99	d0000007-0000-0000-0000-000000000005	ru	Дивный новый мир	Антиутопический роман Олдоса Хаксли	\N	t	\N	1
100	d0000007-0000-0000-0000-000000000005	en	Brave New World	Dystopian novel by Aldous Huxley	\N	t	\N	1
101	d0000008-0000-0000-0000-000000000003	ru	Джордж Оруэлл	Английский писатель и публицист	\N	t	\N	1
102	d0000008-0000-0000-0000-000000000003	en	George Orwell	English novelist and essayist	\N	t	\N	1
103	d0000008-0000-0000-0000-000000000004	ru	Рэй Брэдбери	Американский писатель-фантаст	\N	t	\N	1
104	d0000008-0000-0000-0000-000000000004	en	Ray Bradbury	American science fiction author	\N	t	\N	1
105	d0000008-0000-0000-0000-000000000005	ru	Олдос Хаксли	Английский писатель и философ	\N	t	\N	1
106	d0000008-0000-0000-0000-000000000005	en	Aldous Huxley	English writer and philosopher	\N	t	\N	1
107	d0000009-0000-0000-0000-000000000004	ru	Лондон	Столица Великобритании	\N	t	\N	1
108	d0000009-0000-0000-0000-000000000004	en	London	Capital of the United Kingdom	\N	t	\N	1
109	d0000009-0000-0000-0000-000000000005	ru	Нью-Йорк	Крупнейший город США	\N	t	\N	1
110	d0000009-0000-0000-0000-000000000005	en	New York	Largest city in the United States	\N	t	\N	1
111	d0000009-0000-0000-0000-000000000006	ru	Рим	Столица Италии	\N	t	\N	1
112	d0000009-0000-0000-0000-000000000006	en	Rome	Capital of Italy	\N	t	\N	1
113	d0000010-0000-0000-0000-000000000004	ru	Железо	Химический элемент группы железа	\N	t	\N	1
114	d0000010-0000-0000-0000-000000000004	en	Iron	Chemical element of the iron group	\N	t	\N	1
115	d0000010-0000-0000-0000-000000000005	ru	Золото	Химический элемент золотой группы	\N	t	\N	1
116	d0000010-0000-0000-0000-000000000005	en	Gold	Chemical element of the gold group	\N	t	\N	1
117	d0000010-0000-0000-0000-000000000006	ru	Серебро	Химический элемент серебряной группы	\N	t	\N	1
118	d0000010-0000-0000-0000-000000000006	en	Silver	Chemical element of the silver group	\N	t	\N	1
119	d0000011-0000-0000-0000-000000000004	ru	Тигр	Крупнейший дикий кот	\N	t	\N	1
120	d0000011-0000-0000-0000-000000000004	en	Tiger	Largest wild cat	\N	t	\N	1
121	d0000011-0000-0000-0000-000000000005	ru	Слон	Крупнейшее наземное животное	\N	t	\N	1
122	d0000011-0000-0000-0000-000000000005	en	Elephant	Largest land animal	\N	t	\N	1
123	d0000011-0000-0000-0000-000000000006	ru	Пингвин	Нелетающая морская птица	\N	t	\N	1
124	d0000011-0000-0000-0000-000000000006	en	Penguin	Flightless sea bird	\N	t	\N	1
125	d0000026-0000-0000-0000-000000000003	ru	Уолт Дисней	Американская медиакорпорация	\N	t	\N	1
126	d0000026-0000-0000-0000-000000000003	en	The Walt Disney Company	American mass media corporation	\N	t	\N	1
70	d0000001-0000-0000-0000-000000000005	en	Blade Runner	2017 film by Denis Villeneuve	\N	t	\N	1
127	d0000026-0000-0000-0000-000000000004	ru	Эппл	Американская технологическая компания	\N	t	\N	1
128	d0000026-0000-0000-0000-000000000004	en	Apple Inc.	American technology company	\N	t	\N	1
129	cee359fa-0d72-4624-9686-33da0e0a42f1	ru	Начало	Научно-фантастический боевик Кристофера Нолана о краже секретов из подсознания	\N	t	a1000000-0000-0000-0000-000000000001	1
130	cee359fa-0d72-4624-9686-33da0e0a42f1	en	Inception	Научно-фантастический боевик Кристофера Нолана о краже секретов из подсознания	\N	f	\N	1
131	eaff2e3b-3670-497e-b6d7-ca54caa660ab	ru	Матрица	Культовый научно-фантастический фильм братьев Вачовских	\N	t	a1000000-0000-0000-0000-000000000001	1
132	eaff2e3b-3670-497e-b6d7-ca54caa660ab	en	The Matrix	Культовый научно-фантастический фильм братьев Вачовских	\N	f	\N	1
134	687e7c72-2f0a-46c2-8dec-9762d182a87f	en	Interstellar	Эпическая фантастическая драма о путешествии сквозь червоточину	\N	f	\N	1
135	6df04304-28f0-4f16-a958-056f3b5230bb	ru	Бойцовский клуб	Триллер Дэвид Финчера по роману Чака Паланика	\N	t	a1000000-0000-0000-0000-000000000001	1
136	6df04304-28f0-4f16-a958-056f3b5230bb	en	Fight Club	Триллер Дэвид Финчера по роману Чака Паланика	\N	f	\N	1
138	a24f87f7-fdf0-4258-862c-c17b89acd938	en	Pulp Fiction	Культовый криминальный фильм Квентина Тарантино	\N	f	\N	1
139	9526ade9-abd0-4076-be6f-6fd821f33aac	ru	Тёмный рыцарь	Супергеройский фильм Кристофера Нолана о Бэтмене	\N	t	a1000000-0000-0000-0000-000000000001	1
140	9526ade9-abd0-4076-be6f-6fd821f33aac	en	The Dark Knight	Супергеройский фильм Кристофера Нолана о Бэтмене	\N	f	\N	1
141	eb63ed0d-6b3d-495d-97cf-055bdc585459	ru	Форрест Гамп	Трогательная история жизни простого человека	\N	t	a1000000-0000-0000-0000-000000000001	1
142	eb63ed0d-6b3d-495d-97cf-055bdc585459	en	Forrest Gump	Трогательная история жизни простого человека	\N	f	\N	1
143	b6bec71b-c05d-48df-8cde-7660d1a41d52	ru	Список Шиндлера	Драма Стивена Спилберга о Холокосте	\N	t	a1000000-0000-0000-0000-000000000001	1
144	b6bec71b-c05d-48df-8cde-7660d1a41d52	en	Schindler's List	Драма Стивена Спилберга о Холокосте	\N	f	\N	1
145	85161a9a-6064-4b4b-baaf-1cf838c0b50e	ru	Джанго освобождённый	Вестерн Квентина Тарантино о борьбе с рабством	\N	t	a1000000-0000-0000-0000-000000000001	1
146	85161a9a-6064-4b4b-baaf-1cf838c0b50e	en	Django Unchained	Вестерн Квентина Тарантино о борьбе с рабством	\N	f	\N	1
147	fdfdc747-8641-4c4c-84ea-5f31960a9efe	ru	Остров проклятых	Психологический триллер Мартина Скорсезе	\N	t	a1000000-0000-0000-0000-000000000001	1
148	fdfdc747-8641-4c4c-84ea-5f31960a9efe	en	Shutter Island	Психологический триллер Мартина Скорсезе	\N	f	\N	1
149	f542950b-2fee-47b1-94bb-73c83609167f	ru	Леонардо ДиКаприо	Американский актёр, обладатель премии Оскар	\N	t	a1000000-0000-0000-0000-000000000001	1
150	f542950b-2fee-47b1-94bb-73c83609167f	en	Leonardo DiCaprio	Американский актёр, обладатель премии Оскар	\N	f	\N	1
151	848123f3-d2f3-4a5e-a992-add89081815f	ru	Киану Ривз	Канадский актёр, звезда трилогии Матрица	\N	t	a1000000-0000-0000-0000-000000000001	1
152	848123f3-d2f3-4a5e-a992-add89081815f	en	Keanu Reeves	Канадский актёр, звезда трилогии Матрица	\N	f	\N	1
153	dccfaaf8-42b5-46c7-a915-f6b7d5b05fa2	ru	Мэттью Макконахи	Американский актёр, обладатель Оскара за Интерстеллар	\N	t	a1000000-0000-0000-0000-000000000001	1
154	dccfaaf8-42b5-46c7-a915-f6b7d5b05fa2	en	Matthew McConaughey	Американский актёр, обладатель Оскара за Интерстеллар	\N	f	\N	1
155	ff224547-159e-403e-bd43-359c53d15ba5	ru	Брэд Питт	Американский актёр и продюсер	\N	t	a1000000-0000-0000-0000-000000000001	1
156	ff224547-159e-403e-bd43-359c53d15ba5	en	Brad Pitt	Американский актёр и продюсер	\N	f	\N	1
157	66e7dda6-fc8a-4bae-b864-c54ae4962919	ru	Джон Траволта	Американский актёр, звезда Криминального чтиво	\N	t	a1000000-0000-0000-0000-000000000001	1
158	66e7dda6-fc8a-4bae-b864-c54ae4962919	en	John Travolta	Американский актёр, звезда Криминального чтиво	\N	f	\N	1
159	f16dc2ac-4b8a-42f9-a44a-12411e90008d	ru	Том Харди	Британский актёр, исполнитель роли Бейна	\N	t	a1000000-0000-0000-0000-000000000001	1
160	f16dc2ac-4b8a-42f9-a44a-12411e90008d	en	Tom Hardy	Британский актёр, исполнитель роли Бейна	\N	f	\N	1
161	73e99bfb-2168-4669-8831-071c97c4e7e4	ru	Том Хэнкс	Американский актёр, двукратный обладатель Оскара	\N	t	a1000000-0000-0000-0000-000000000001	1
162	73e99bfb-2168-4669-8831-071c97c4e7e4	en	Tom Hanks	Американский актёр, двукратный обладатель Оскара	\N	f	\N	1
163	96a28808-f001-49fd-8562-834a7f77db83	ru	Лиам Нисон	Североирландский актёр, исполнитель роли Шиндлера	\N	t	a1000000-0000-0000-0000-000000000001	1
164	96a28808-f001-49fd-8562-834a7f77db83	en	Liam Neeson	Североирландский актёр, исполнитель роли Шиндлера	\N	f	\N	1
165	8c5def46-791c-4c04-b39f-21a975b5d3da	ru	Джейми Фокс	Американский актёр и музыкант	\N	t	a1000000-0000-0000-0000-000000000001	1
166	8c5def46-791c-4c04-b39f-21a975b5d3da	en	Jamie Foxx	Американский актёр и музыкант	\N	f	\N	1
167	d3dbd8f2-19e2-4329-a383-d06fc61e04cc	ru	Марк Руффало	Американский актёр, исполнитель роли Халка	\N	t	a1000000-0000-0000-0000-000000000001	1
168	d3dbd8f2-19e2-4329-a383-d06fc61e04cc	en	Mark Ruffalo	Американский актёр, исполнитель роли Халка	\N	f	\N	1
217	d9184903-40b8-49ba-908e-161fe2174b6c	ru	Майкл Джексон	Король поп-музыки	\N	t	a1000000-0000-0000-0000-000000000001	1
169	60d6257f-5730-4868-8733-b3d6a310f8a2	ru	Кристофер Нолан	Британско-американский режиссёр, мастер интеллектуального кино	\N	t	a1000000-0000-0000-0000-000000000001	1
170	60d6257f-5730-4868-8733-b3d6a310f8a2	en	Christopher Nolan	Британско-американский режиссёр, мастер интеллектуального кино	\N	f	\N	1
171	23180d0b-81b1-4384-9ba7-e27206bdff02	ru	Братья Вачовски	Американские режиссёры, создатели Матрицы	\N	t	a1000000-0000-0000-0000-000000000001	1
172	23180d0b-81b1-4384-9ba7-e27206bdff02	en	The Wachowskis	Американские режиссёры, создатели Матрицы	\N	f	\N	1
173	c7d1a5fe-d2f5-4327-8a0e-01c571310078	ru	Дэвид Финчер	Американский режиссёр триллеров	\N	t	a1000000-0000-0000-0000-000000000001	1
174	c7d1a5fe-d2f5-4327-8a0e-01c571310078	en	David Fincher	Американский режиссёр триллеров	\N	f	\N	1
175	449fbd14-7ed0-4aaa-bacf-7811bd48dc5c	ru	Квентин Тарантино	Американский режиссёр, автор уникального стиля	\N	t	a1000000-0000-0000-0000-000000000001	1
176	449fbd14-7ed0-4aaa-bacf-7811bd48dc5c	en	Quentin Tarantino	Американский режиссёр, автор уникального стиля	\N	f	\N	1
177	4d7f0c0c-de03-499b-a268-695d49237a92	ru	Стивен Спилберг	Легендарный американский режиссёр	\N	t	a1000000-0000-0000-0000-000000000001	1
178	4d7f0c0c-de03-499b-a268-695d49237a92	en	Steven Spielberg	Легендарный американский режиссёр	\N	f	\N	1
179	1703d7f9-ceb7-4f11-bcd3-d85e1b86b55e	ru	Мартин Скорсезе	Американский режиссёр классического кино	\N	t	a1000000-0000-0000-0000-000000000001	1
180	1703d7f9-ceb7-4f11-bcd3-d85e1b86b55e	en	Martin Scorsese	Американский режиссёр классического кино	\N	f	\N	1
181	f4ee8f84-d477-465b-ab1d-d2cc5335c3ba	ru	Ридли Скотт	Британский режиссёр научной фантастики	\N	t	a1000000-0000-0000-0000-000000000001	1
182	f4ee8f84-d477-465b-ab1d-d2cc5335c3ba	en	Ridley Scott	Британский режиссёр научной фантастики	\N	f	\N	1
183	769f85f2-f19e-41c6-b099-078dd11dee55	ru	Стэнли Кубрик	Американский режиссёр-визионер	\N	t	a1000000-0000-0000-0000-000000000001	1
184	769f85f2-f19e-41c6-b099-078dd11dee55	en	Stanley Kubrick	Американский режиссёр-визионер	\N	f	\N	1
185	4a672d0d-29bb-45f3-9ff9-90fd57017633	ru	Фрэнк Дарабонт	Американский режиссёр, мастер экранизаций Кинга	\N	t	a1000000-0000-0000-0000-000000000001	1
186	4a672d0d-29bb-45f3-9ff9-90fd57017633	en	Frank Darabont	Американский режиссёр, мастер экранизаций Кинга	\N	f	\N	1
187	dc070982-5f72-4bec-9bc1-aa6eff656900	ru	Дени Вильнёв	Канадский режиссёр научной фантастики	\N	t	a1000000-0000-0000-0000-000000000001	1
188	dc070982-5f72-4bec-9bc1-aa6eff656900	en	Denis Villeneuve	Канадский режиссёр научной фантастики	\N	f	\N	1
189	1496117c-f07f-4c35-8fd2-5b44db1604fe	ru	Bohemian Rhapsody	Эпическая рок-опера Queen	\N	t	a1000000-0000-0000-0000-000000000001	1
190	1496117c-f07f-4c35-8fd2-5b44db1604fe	en	Bohemian Rhapsody	Эпическая рок-опера Queen	\N	f	\N	1
191	0cf39fee-0df1-44c5-96a6-81b246c1b5d4	ru	Stairway to Heaven	Легендарная баллада Led Zeppelin	\N	t	a1000000-0000-0000-0000-000000000001	1
192	0cf39fee-0df1-44c5-96a6-81b246c1b5d4	en	Stairway to Heaven	Легендарная баллада Led Zeppelin	\N	f	\N	1
193	49dd0902-ded3-452e-9cd7-3627778d8391	ru	Imagine	Гимн мира Джона Леннона	\N	t	a1000000-0000-0000-0000-000000000001	1
194	49dd0902-ded3-452e-9cd7-3627778d8391	en	Imagine	Гимн мира Джона Леннона	\N	f	\N	1
195	a64cda25-19b1-42a6-8eed-55e0be2a9181	ru	Hotel California	Культовая песня Eagles	\N	t	a1000000-0000-0000-0000-000000000001	1
196	a64cda25-19b1-42a6-8eed-55e0be2a9181	en	Hotel California	Культовая песня Eagles	\N	f	\N	1
197	80db5106-3ea1-4ef8-b8bd-a4b59250404b	ru	Smells Like Teen Spirit	Гимн поколения X от Nirvana	\N	t	a1000000-0000-0000-0000-000000000001	1
198	80db5106-3ea1-4ef8-b8bd-a4b59250404b	en	Smells Like Teen Spirit	Гимн поколения X от Nirvana	\N	f	\N	1
199	ce8dca5d-1f89-4443-b15a-84c40a01ff40	ru	Like a Rolling Stone	Революционная песня Боба Дилана	\N	t	a1000000-0000-0000-0000-000000000001	1
200	ce8dca5d-1f89-4443-b15a-84c40a01ff40	en	Like a Rolling Stone	Революционная песня Боба Дилана	\N	f	\N	1
201	d27be8c9-b14a-42f4-8392-ea44372e5ed6	ru	Yesterday	Самая перепеваемая песня Beatles	\N	t	a1000000-0000-0000-0000-000000000001	1
202	d27be8c9-b14a-42f4-8392-ea44372e5ed6	en	Yesterday	Самая перепеваемая песня Beatles	\N	f	\N	1
203	2e74dc73-3343-4cad-9310-e1ee2303cb04	ru	Thriller	Заглавный трек самого продаваемого альбома	\N	t	a1000000-0000-0000-0000-000000000001	1
204	2e74dc73-3343-4cad-9310-e1ee2303cb04	en	Thriller	Заглавный трек самого продаваемого альбома	\N	f	\N	1
205	997258fe-8a0a-4273-bfb2-879a1057dcf9	ru	Comfortably Numb	Психеделическая баллада Pink Floyd	\N	t	a1000000-0000-0000-0000-000000000001	1
206	997258fe-8a0a-4273-bfb2-879a1057dcf9	en	Comfortably Numb	Психеделическая баллада Pink Floyd	\N	f	\N	1
207	7f559dfa-39be-4d64-ab04-b654c4611bbe	ru	No Woman No Cry	Регги-классика Боба Марли	\N	t	a1000000-0000-0000-0000-000000000001	1
208	7f559dfa-39be-4d64-ab04-b654c4611bbe	en	No Woman No Cry	Регги-классика Боба Марли	\N	f	\N	1
209	69edc036-d376-4fab-8bee-67ed2eef51c3	ru	Фредди Меркьюри	Легендарный вокалист Queen	\N	t	a1000000-0000-0000-0000-000000000001	1
210	69edc036-d376-4fab-8bee-67ed2eef51c3	en	Freddie Mercury	Легендарный вокалист Queen	\N	f	\N	1
211	c03b986b-dda2-4c30-9cb0-54b61e67438e	ru	Джими Хендрикс	Величайший гитарист всех времён	\N	t	a1000000-0000-0000-0000-000000000001	1
212	c03b986b-dda2-4c30-9cb0-54b61e67438e	en	Jimi Hendrix	Величайший гитарист всех времён	\N	f	\N	1
213	3ea280fa-29c3-4c89-9577-6398cf756257	ru	Боб Дилан	Лауреат Нобелевской премии по литературе	\N	t	a1000000-0000-0000-0000-000000000001	1
214	3ea280fa-29c3-4c89-9577-6398cf756257	en	Bob Dylan	Лауреат Нобелевской премии по литературе	\N	f	\N	1
215	21a43fa4-af0e-4c7c-b56e-7285a1240cc6	ru	Джон Леннон	Сооснователь Beatles, активист мира	\N	t	a1000000-0000-0000-0000-000000000001	1
216	21a43fa4-af0e-4c7c-b56e-7285a1240cc6	en	John Lennon	Сооснователь Beatles, активист мира	\N	f	\N	1
768	1b53bbd4-9c24-407b-8af3-ed833c9f11c1	ru	history	История	\N	t	\N	110
218	d9184903-40b8-49ba-908e-161fe2174b6c	en	Michael Jackson	Король поп-музыки	\N	f	\N	1
219	fe6098a4-85c4-4762-914b-d07f94736f11	ru	Боб Марли	Легенда регги	\N	t	a1000000-0000-0000-0000-000000000001	1
220	fe6098a4-85c4-4762-914b-d07f94736f11	en	Bob Marley	Легенда регги	\N	f	\N	1
221	cbfaf521-05ba-4bb1-b10e-7c7cf885adbf	ru	Дэвид Гилмор	Гитарист и вокалист Pink Floyd	\N	t	a1000000-0000-0000-0000-000000000001	1
222	cbfaf521-05ba-4bb1-b10e-7c7cf885adbf	en	David Gilmour	Гитарист и вокалист Pink Floyd	\N	f	\N	1
223	c45a8ad7-a307-4cd5-8a68-ad311fda0824	ru	Курт Кобейн	Лидер Nirvana, икон grunge	\N	t	a1000000-0000-0000-0000-000000000001	1
224	c45a8ad7-a307-4cd5-8a68-ad311fda0824	en	Kurt Cobain	Лидер Nirvana, икон grunge	\N	f	\N	1
225	ed04e968-a812-4eb5-8b0d-eceeb66160fe	ru	Элвис Пресли	Король рок-н-ролла	\N	t	a1000000-0000-0000-0000-000000000001	1
226	ed04e968-a812-4eb5-8b0d-eceeb66160fe	en	Elvis Presley	Король рок-н-ролла	\N	f	\N	1
227	b2122f3b-815c-471a-9e76-29e35fecee01	ru	Людвиг ван Бетховен	Великий немецкий композитор	\N	t	a1000000-0000-0000-0000-000000000001	1
228	b2122f3b-815c-471a-9e76-29e35fecee01	en	Ludwig van Beethoven	Великий немецкий композитор	\N	f	\N	1
229	7fe3dd00-a021-49d1-899a-93e6818a30a9	ru	1984	Антиутопия Джорджа Оруэлла о тоталитарном обществе	\N	t	a1000000-0000-0000-0000-000000000001	1
230	7fe3dd00-a021-49d1-899a-93e6818a30a9	en	1984	Антиутопия Джорджа Оруэлла о тоталитарном обществе	\N	f	\N	1
231	01648745-0c99-4cfe-bb8d-acbdeea2e6c4	ru	Дивный новый мир	Антиутопия Олдоса Хаксли	\N	t	a1000000-0000-0000-0000-000000000001	1
232	01648745-0c99-4cfe-bb8d-acbdeea2e6c4	en	A Brave New World	Антиутопия Олдоса Хаксли	\N	f	\N	1
233	bbe028e9-d2b9-41bf-aefb-5f5373b616ba	ru	451 градус по Фаренгейту	Антиутопия Рэя Брэдбери о сжигании книг	\N	t	a1000000-0000-0000-0000-000000000001	1
234	bbe028e9-d2b9-41bf-aefb-5f5373b616ba	en	Fahrenheit 451	Антиутопия Рэя Брэдбери о сжигании книг	\N	f	\N	1
235	c42fd1c7-57e3-48f2-a429-94fe8e908f1f	ru	Хоббит	Фэнтези Толкина о путешествии Бильбо	\N	t	a1000000-0000-0000-0000-000000000001	1
236	c42fd1c7-57e3-48f2-a429-94fe8e908f1f	en	The Hobbit	Фэнтези Толкина о путешествии Бильбо	\N	f	\N	1
237	c5803f80-ec8f-498e-a0dc-027184d0fc3d	ru	Дюна	Научно-фантастический эпос Фрэнка Герберта	\N	t	a1000000-0000-0000-0000-000000000001	1
238	c5803f80-ec8f-498e-a0dc-027184d0fc3d	en	Dune	Научно-фантастический эпос Фрэнка Герберта	\N	f	\N	1
239	f05470cf-ce25-4bf3-8acf-ac54bb3d2426	ru	Мастер и Маргарита	Роман Булгакова о добре и зле	\N	t	a1000000-0000-0000-0000-000000000001	1
240	f05470cf-ce25-4bf3-8acf-ac54bb3d2426	en	The Master and Margarita	Роман Булгакова о добре и зле	\N	f	\N	1
241	c1605c47-91cb-4d46-8a6c-82643625caa8	ru	Война и мир	Эпический роман Толстого	\N	t	a1000000-0000-0000-0000-000000000001	1
242	c1605c47-91cb-4d46-8a6c-82643625caa8	en	War and Peace	Эпический роман Толстого	\N	f	\N	1
243	3ad1b264-4c1a-4bab-a47c-7c464bd9fb75	ru	Преступление и наказание	Психологический роман Достоевского	\N	t	a1000000-0000-0000-0000-000000000001	1
244	3ad1b264-4c1a-4bab-a47c-7c464bd9fb75	en	Crime and Punishment	Психологический роман Достоевского	\N	f	\N	1
245	5ed7d3d6-3486-43c2-bc33-13de728cc779	ru	Солярис	Научно-фантастический роман Лема	\N	t	a1000000-0000-0000-0000-000000000001	1
246	5ed7d3d6-3486-43c2-bc33-13de728cc779	en	Solaris	Научно-фантастический роман Лема	\N	f	\N	1
247	472449a5-e0c8-45a2-ba13-8e85fd837166	ru	Гарри Поттер	Серия романов о юном волшебнике	\N	t	a1000000-0000-0000-0000-000000000001	1
248	472449a5-e0c8-45a2-ba13-8e85fd837166	en	Harry Potter	Серия романов о юном волшебнике	\N	f	\N	1
249	8803fa13-24d5-4d44-902d-a7a07b54db96	ru	Джордж Оруэлл	Английский писатель, автор антиутопий	\N	t	a1000000-0000-0000-0000-000000000001	1
250	8803fa13-24d5-4d44-902d-a7a07b54db96	en	George Orwell	Английский писатель, автор антиутопий	\N	f	\N	1
251	7e50d09d-7cc0-45d7-a458-841fbc4bb306	ru	Дж. Р. Р. Толкин	Английский писатель, создатель Средиземья	\N	t	a1000000-0000-0000-0000-000000000001	1
252	7e50d09d-7cc0-45d7-a458-841fbc4bb306	en	J.R.R. Tolkien	Английский писатель, создатель Средиземья	\N	f	\N	1
253	8fbc5a21-3f98-40c0-a787-c43b2aa052ad	ru	Михаил Булгаков	Русский писатель, автор Мастера и Маргариты	\N	t	a1000000-0000-0000-0000-000000000001	1
254	8fbc5a21-3f98-40c0-a787-c43b2aa052ad	en	Mikhail Bulgakov	Русский писатель, автор Мастера и Маргариты	\N	f	\N	1
255	78fb1db1-d560-4ade-a8a8-46d51af4c17d	ru	Лев Толстой	Великий русский писатель	\N	t	a1000000-0000-0000-0000-000000000001	1
256	78fb1db1-d560-4ade-a8a8-46d51af4c17d	en	Leo Tolstoy	Великий русский писатель	\N	f	\N	1
257	eccd785d-f09d-4eb8-88d7-61477586c60d	ru	Фёдор Достоевский	Русский писатель, мастер психологии	\N	t	a1000000-0000-0000-0000-000000000001	1
258	eccd785d-f09d-4eb8-88d7-61477586c60d	en	Fyodor Dostoevsky	Русский писатель, мастер психологии	\N	f	\N	1
259	5f4b69e6-1dcc-45eb-a6c3-190613400bc9	ru	Стивен Кинг	Король хоррора, автор более 60 книг	\N	t	a1000000-0000-0000-0000-000000000001	1
260	5f4b69e6-1dcc-45eb-a6c3-190613400bc9	en	Stephen King	Король хоррора, автор более 60 книг	\N	f	\N	1
261	e03d486b-140a-4554-bbe8-73a526b9f722	ru	Рэй Брэдбери	Американский писатель-фантаст	\N	t	a1000000-0000-0000-0000-000000000001	1
262	e03d486b-140a-4554-bbe8-73a526b9f722	en	Ray Bradbury	Американский писатель-фантаст	\N	f	\N	1
263	f95cb9e8-173b-48df-9514-5952b0a7ecd9	ru	Станислав Лем	Польский писатель-фантаст	\N	t	a1000000-0000-0000-0000-000000000001	1
264	f95cb9e8-173b-48df-9514-5952b0a7ecd9	en	Stanislaw Lem	Польский писатель-фантаст	\N	f	\N	1
265	01688b9c-cff6-4480-8e6f-fd665ebed28f	ru	Чак Паланик	Автор Бойцовского клуба	\N	t	a1000000-0000-0000-0000-000000000001	1
266	01688b9c-cff6-4480-8e6f-fd665ebed28f	en	Chuck Palahniuk	Автор Бойцовского клуба	\N	f	\N	1
267	8dbaceed-a2a7-4c9c-b4cd-92202e7ec671	ru	Дж. К. Роулинг	Автор серии книг о Гарри Поттере	\N	t	a1000000-0000-0000-0000-000000000001	1
268	8dbaceed-a2a7-4c9c-b4cd-92202e7ec671	en	J.K. Rowling	Автор серии книг о Гарри Поттере	\N	f	\N	1
269	8d533df6-9672-4f7c-b1be-a853b0381959	ru	Нью-Йорк	Крупнейший город США, мировой финансовый центр	\N	t	a1000000-0000-0000-0000-000000000001	1
270	8d533df6-9672-4f7c-b1be-a853b0381959	en	New York	Крупнейший город США, мировой финансовый центр	\N	f	\N	1
271	19787a08-7bc6-46b1-9c07-9dc45148704c	ru	Лондон	Столица Великобритании	\N	t	a1000000-0000-0000-0000-000000000001	1
272	19787a08-7bc6-46b1-9c07-9dc45148704c	en	London	Столица Великобритании	\N	f	\N	1
273	34245b99-bf0b-4aad-8c0f-a1c26faf531b	ru	Париж	Столица Франции, город любви	\N	t	a1000000-0000-0000-0000-000000000001	1
274	34245b99-bf0b-4aad-8c0f-a1c26faf531b	en	Paris	Столица Франции, город любви	\N	f	\N	1
275	1b94695f-bb7e-4fd7-8c29-53c5a161812d	ru	Токио	Столица Японии, крупнейший мегаполис	\N	t	a1000000-0000-0000-0000-000000000001	1
276	1b94695f-bb7e-4fd7-8c29-53c5a161812d	en	Tokyo	Столица Японии, крупнейший мегаполис	\N	f	\N	1
277	8e506f85-3b7d-4f71-93b0-bb6053188fcd	ru	Москва	Столица России	\N	t	a1000000-0000-0000-0000-000000000001	1
278	8e506f85-3b7d-4f71-93b0-bb6053188fcd	en	Moscow	Столица России	\N	f	\N	1
279	926600a2-baeb-40e0-a9b3-45f1981cddbc	ru	Берлин	Столица Германии	\N	t	a1000000-0000-0000-0000-000000000001	1
280	926600a2-baeb-40e0-a9b3-45f1981cddbc	en	Berlin	Столица Германии	\N	f	\N	1
281	15621346-ee2c-4cd0-9ed5-43532377a1cf	ru	Лос-Анджелес	Голливуд, столица киноиндустрии	\N	t	a1000000-0000-0000-0000-000000000001	1
282	15621346-ee2c-4cd0-9ed5-43532377a1cf	en	Los Angeles	Голливуд, столица киноиндустрии	\N	f	\N	1
283	cddfd7b4-aec3-4010-8869-5d88317bd6fd	ru	Рим	Вечный город, столица Италии	\N	t	a1000000-0000-0000-0000-000000000001	1
284	cddfd7b4-aec3-4010-8869-5d88317bd6fd	en	Rome	Вечный город, столица Италии	\N	f	\N	1
285	df2cc641-dbb0-41d5-95f1-c2615f69a134	ru	Сидней	Крупнейший город Австралии	\N	t	a1000000-0000-0000-0000-000000000001	1
286	df2cc641-dbb0-41d5-95f1-c2615f69a134	en	Sydney	Крупнейший город Австралии	\N	f	\N	1
287	5c8d82b2-23a8-49c8-abea-9e8b7a351bac	ru	Каир	Столица Египта, город пирамид	\N	t	a1000000-0000-0000-0000-000000000001	1
288	5c8d82b2-23a8-49c8-abea-9e8b7a351bac	en	Cairo	Столица Египта, город пирамид	\N	f	\N	1
289	e9b3e55b-2949-4199-a62f-561d4fcff81a	ru	Водород	Первый элемент таблицы Менделеева	\N	t	a1000000-0000-0000-0000-000000000001	1
290	e9b3e55b-2949-4199-a62f-561d4fcff81a	en	Hydrogen	Первый элемент таблицы Менделеева	\N	f	\N	1
291	e77046fa-3c1f-4f25-98c5-71fd3cc5eeb1	ru	Гелий	Инертный газ, второй по распространённости элемент	\N	t	a1000000-0000-0000-0000-000000000001	1
292	e77046fa-3c1f-4f25-98c5-71fd3cc5eeb1	en	Helium	Инертный газ, второй по распространённости элемент	\N	f	\N	1
293	a8f5981e-e074-4f55-be73-7cd95387e91c	ru	Углерод	Основа органической химии	\N	t	a1000000-0000-0000-0000-000000000001	1
294	a8f5981e-e074-4f55-be73-7cd95387e91c	en	Carbon	Основа органической химии	\N	f	\N	1
295	eeccd18c-b028-4642-b73f-6027cf48de6a	ru	Кислород	Элемент, необходимый для дыхания	\N	t	a1000000-0000-0000-0000-000000000001	1
296	eeccd18c-b028-4642-b73f-6027cf48de6a	en	Oxygen	Элемент, необходимый для дыхания	\N	f	\N	1
297	4660dd15-b070-4ce6-b08d-dd04077e1dd6	ru	Железо	Основной металл промышленности	\N	t	a1000000-0000-0000-0000-000000000001	1
298	4660dd15-b070-4ce6-b08d-dd04077e1dd6	en	Iron	Основной металл промышленности	\N	f	\N	1
299	6f3e4fd5-05e9-4885-8ac5-9adf9930a842	ru	Золото	Благородный металл, символ богатства	\N	t	a1000000-0000-0000-0000-000000000001	1
300	6f3e4fd5-05e9-4885-8ac5-9adf9930a842	en	Gold	Благородный металл, символ богатства	\N	f	\N	1
301	b7615e44-a938-4c65-9626-747afd9f874f	ru	Серебро	Благородный металл	\N	t	a1000000-0000-0000-0000-000000000001	1
302	b7615e44-a938-4c65-9626-747afd9f874f	en	Silver	Благородный металл	\N	f	\N	1
303	7a168f08-f4ae-4d92-8366-a259e41030ad	ru	Медь	Металл, использовавшийся с древности	\N	t	a1000000-0000-0000-0000-000000000001	1
304	7a168f08-f4ae-4d92-8366-a259e41030ad	en	Copper	Металл, использовавшийся с древности	\N	f	\N	1
305	fbdeb7a4-0913-4939-ba6c-39de2943925a	ru	Кремний	Основа современной электроники	\N	t	a1000000-0000-0000-0000-000000000001	1
306	fbdeb7a4-0913-4939-ba6c-39de2943925a	en	Silicon	Основа современной электроники	\N	f	\N	1
307	1521e795-f0bf-40a4-8522-9e334399a2a1	ru	Уран	Радиоактивный элемент, топливо для АЭС	\N	t	a1000000-0000-0000-0000-000000000001	1
308	1521e795-f0bf-40a4-8522-9e334399a2a1	en	Uranium	Радиоактивный элемент, топливо для АЭС	\N	f	\N	1
309	4260b491-39b2-4d11-98e0-c66f9b024e29	ru	Африканский слон	Крупнейшее наземное животное	\N	t	a1000000-0000-0000-0000-000000000001	1
310	4260b491-39b2-4d11-98e0-c66f9b024e29	en	African Elephant	Крупнейшее наземное животное	\N	f	\N	1
311	9fdd08c5-8ed1-41b6-a801-b05ada603e40	ru	Синий кит	Крупнейшее животное на планете	\N	t	a1000000-0000-0000-0000-000000000001	1
312	9fdd08c5-8ed1-41b6-a801-b05ada603e40	en	Blue Whale	Крупнейшее животное на планете	\N	f	\N	1
313	6e00c01b-e63b-4d78-9601-565fc290e271	ru	Орёл	Могучий хищник небес	\N	t	a1000000-0000-0000-0000-000000000001	1
314	6e00c01b-e63b-4d78-9601-565fc290e271	en	Golden Eagle	Могучий хищник небес	\N	f	\N	1
315	178e0a06-8854-4baf-ad7f-8328c8f3da06	ru	Серый волк	Социальный хищник	\N	t	a1000000-0000-0000-0000-000000000001	1
316	178e0a06-8854-4baf-ad7f-8328c8f3da06	en	Gray Wolf	Социальный хищник	\N	f	\N	1
317	93537e7f-6e85-407b-8f42-8791b6871e31	ru	Белый медведь	Хищник Арктики	\N	t	a1000000-0000-0000-0000-000000000001	1
318	93537e7f-6e85-407b-8f42-8791b6871e31	en	Polar Bear	Хищник Арктики	\N	f	\N	1
319	ff6c4273-2f89-447b-af80-e2a858719f5b	ru	Орлан	Символ США	\N	t	a1000000-0000-0000-0000-000000000001	1
320	ff6c4273-2f89-447b-af80-e2a858719f5b	en	Bald Eagle	Символ США	\N	f	\N	1
321	ce493d5d-b11e-49b8-bfea-054988f6d50d	ru	Снежный барс	Редкий горный хищник	\N	t	a1000000-0000-0000-0000-000000000001	1
322	ce493d5d-b11e-49b8-bfea-054988f6d50d	en	Snow Leopard	Редкий горный хищник	\N	f	\N	1
323	3afd0978-487a-4e25-9445-c5baedb40e00	ru	Красная панда	Милое древесное животное	\N	t	a1000000-0000-0000-0000-000000000001	1
324	3afd0978-487a-4e25-9445-c5baedb40e00	en	Red Panda	Милое древесное животное	\N	f	\N	1
325	70cf6c05-21e8-4a02-8977-87d94734a231	ru	Бенгальский тигр	Крупнейший дикий кот	\N	t	a1000000-0000-0000-0000-000000000001	1
326	70cf6c05-21e8-4a02-8977-87d94734a231	en	Bengal Tiger	Крупнейший дикий кот	\N	f	\N	1
327	7624f2b4-066f-4cac-ab86-766b04debc1f	ru	Императорский пингвин	Самый крупный пингвин	\N	t	a1000000-0000-0000-0000-000000000001	1
328	7624f2b4-066f-4cac-ab86-766b04debc1f	en	Emperor Penguin	Самый крупный пингвин	\N	f	\N	1
329	2dcca74c-ae06-4a67-8189-54116ff080b1	ru	Секвойя	Самое высокое дерево на планете	\N	t	a1000000-0000-0000-0000-000000000001	1
330	2dcca74c-ae06-4a67-8189-54116ff080b1	en	Giant Sequoia	Самое высокое дерево на планете	\N	f	\N	1
331	32e39547-50f5-4435-a0c6-f1f04876848b	ru	Баобаб	Дерево жизни Африки	\N	t	a1000000-0000-0000-0000-000000000001	1
332	32e39547-50f5-4435-a0c6-f1f04876848b	en	Baobab	Дерево жизни Африки	\N	f	\N	1
333	494f1216-d71a-4ab7-be3e-9291040bf88e	ru	Гигантская ламинария	Самая быстрорастущая водоросль	\N	t	a1000000-0000-0000-0000-000000000001	1
334	494f1216-d71a-4ab7-be3e-9291040bf88e	en	Giant Kelp	Самая быстрорастущая водоросль	\N	f	\N	1
335	467ffb2a-3a24-4602-88bc-6e7ab40e2f4a	ru	Дерево Иисуса	Символ пустыни Мохаве	\N	t	a1000000-0000-0000-0000-000000000001	1
336	467ffb2a-3a24-4602-88bc-6e7ab40e2f4a	en	Joshua Tree	Символ пустыни Мохаве	\N	f	\N	1
337	595bc463-ce69-4266-b984-623cb3fa1edd	ru	Белый дуб	Долгожитель среди деревьев	\N	t	a1000000-0000-0000-0000-000000000001	1
338	595bc463-ce69-4266-b984-623cb3fa1edd	en	White Oak	Долгожитель среди деревьев	\N	f	\N	1
339	e8886070-f942-48a8-a0ae-eb7e02cb6f02	ru	Бамбук	Самая быстрорастущая трава	\N	t	a1000000-0000-0000-0000-000000000001	1
340	e8886070-f942-48a8-a0ae-eb7e02cb6f02	en	Bamboo	Самая быстрорастущая трава	\N	f	\N	1
341	aff17dd6-73f1-4cd7-a942-ff407d1defac	ru	Подсолнечник	Солнечный цветок	\N	t	a1000000-0000-0000-0000-000000000001	1
342	aff17dd6-73f1-4cd7-a942-ff407d1defac	en	Sunflower	Солнечный цветок	\N	f	\N	1
343	39f54e29-3882-4ecd-be12-57db727bbf86	ru	Королевская пальма	Экзотическая пальма	\N	t	a1000000-0000-0000-0000-000000000001	1
344	39f54e29-3882-4ecd-be12-57db727bbf86	en	Royal Palm	Экзотическая пальма	\N	f	\N	1
345	f244fdb2-7356-4cb6-ab43-6185c9d9dabd	ru	Гинкго	Живое ископаемое, 270 млн лет	\N	t	a1000000-0000-0000-0000-000000000001	1
346	f244fdb2-7356-4cb6-ab43-6185c9d9dabd	en	Ginkgo	Живое ископаемое, 270 млн лет	\N	f	\N	1
347	1eb8cafd-7157-438a-83c2-8b72e51fd32b	ru	Венерина мухоловка	Хищное растение	\N	t	a1000000-0000-0000-0000-000000000001	1
348	1eb8cafd-7157-438a-83c2-8b72e51fd32b	en	Venus Flytrap	Хищное растение	\N	f	\N	1
349	0c8db544-0346-4678-b1ca-1fc1a135b3d8	ru	Abbey Road	Последний записанный альбом Beatles	\N	t	a1000000-0000-0000-0000-000000000001	1
350	0c8db544-0346-4678-b1ca-1fc1a135b3d8	en	Abbey Road	Последний записанный альбом Beatles	\N	f	\N	1
351	54b581ae-2b9b-4108-85c6-553d06429fb6	ru	The Dark Side of the Moon	Один из самых продаваемых альбомов	\N	t	a1000000-0000-0000-0000-000000000001	1
352	54b581ae-2b9b-4108-85c6-553d06429fb6	en	The Dark Side of the Moon	Один из самых продаваемых альбомов	\N	f	\N	1
353	3b6a0e16-9e3e-4677-96b0-3805906570bb	ru	Thriller	Самый продаваемый альбом в истории	\N	t	a1000000-0000-0000-0000-000000000001	1
354	3b6a0e16-9e3e-4677-96b0-3805906570bb	en	Thriller	Самый продаваемый альбом в истории	\N	f	\N	1
355	5469017a-120f-4283-9d3a-d825191eaafd	ru	Nevermind	Альбом, изменивший рок-музыку	\N	t	a1000000-0000-0000-0000-000000000001	1
356	5469017a-120f-4283-9d3a-d825191eaafd	en	Nevermind	Альбом, изменивший рок-музыку	\N	f	\N	1
357	bdc5f754-0549-4710-a51e-c93b6f21b168	ru	Led Zeppelin IV	Альбом со Stairway to Heaven	\N	t	a1000000-0000-0000-0000-000000000001	1
358	bdc5f754-0549-4710-a51e-c93b6f21b168	en	Led Zeppelin IV	Альбом со Stairway to Heaven	\N	f	\N	1
359	7e42c151-9cdf-4472-b69a-377fc72ff6b4	ru	Hotel California	Культовый альбом Eagles	\N	t	a1000000-0000-0000-0000-000000000001	1
360	7e42c151-9cdf-4472-b69a-377fc72ff6b4	en	Hotel California	Культовый альбом Eagles	\N	f	\N	1
361	8db8ca3d-43d7-4dad-99b0-55c5da133298	ru	The Wall	Рок-опера Pink Floyd	\N	t	a1000000-0000-0000-0000-000000000001	1
362	8db8ca3d-43d7-4dad-99b0-55c5da133298	en	The Wall	Рок-опера Pink Floyd	\N	f	\N	1
363	31932ca6-473d-4016-a865-cf8f44705dc7	ru	OK Computer	Шедевр Radiohead	\N	t	a1000000-0000-0000-0000-000000000001	1
364	31932ca6-473d-4016-a865-cf8f44705dc7	en	OK Computer	Шедевр Radiohead	\N	f	\N	1
365	c9d9e0f0-5257-4fba-8587-303ad6fbbd27	ru	Rumours	Самый успешный альбом Fleetwood Mac	\N	t	a1000000-0000-0000-0000-000000000001	1
366	c9d9e0f0-5257-4fba-8587-303ad6fbbd27	en	Rumours	Самый успешный альбом Fleetwood Mac	\N	f	\N	1
367	49718987-d935-42db-b3e6-3ef15651e7f1	ru	Back in Black	Трибьют Bon Scott от AC/DC	\N	t	a1000000-0000-0000-0000-000000000001	1
368	49718987-d935-42db-b3e6-3ef15651e7f1	en	Back in Black	Трибьют Bon Scott от AC/DC	\N	f	\N	1
369	f70632ea-3cc3-41c8-b0d6-c1c81b8e733c	ru	Искусственный интеллект	Раздел информатики, создающий интеллектуальные системы	\N	t	a1000000-0000-0000-0000-000000000001	1
370	f70632ea-3cc3-41c8-b0d6-c1c81b8e733c	en	Artificial Intelligence	Раздел информатики, создающий интеллектуальные системы	\N	f	\N	1
371	9693f320-3852-49e3-89dc-0dc685b3cb12	ru	Квантовые вычисления	Вычисления на основе квантовых механических явлений	\N	t	a1000000-0000-0000-0000-000000000001	1
372	9693f320-3852-49e3-89dc-0dc685b3cb12	en	Quantum Computing	Вычисления на основе квантовых механических явлений	\N	f	\N	1
373	207dbab2-2833-4b41-82b3-029b50de9c3c	ru	Блокчейн	Распределённый реестр данных	\N	t	a1000000-0000-0000-0000-000000000001	1
374	207dbab2-2833-4b41-82b3-029b50de9c3c	en	Blockchain	Распределённый реестр данных	\N	f	\N	1
422	23509af3-2a16-464d-ae37-17d962c7301d	en	Tornado	Мощный вращающийся вихрь	\N	f	\N	1
375	3512cdda-6ede-466b-97fe-6d6e38fcd2ac	ru	Экзистенциализм	Философское течение о свободе и ответственности	\N	t	a1000000-0000-0000-0000-000000000001	1
376	3512cdda-6ede-466b-97fe-6d6e38fcd2ac	en	Existentialism	Философское течение о свободе и ответственности	\N	f	\N	1
377	64f99728-90df-40a1-ae15-c07e185c2eba	ru	Демократия	Форма правления, основанная на воле народа	\N	t	a1000000-0000-0000-0000-000000000001	1
378	64f99728-90df-40a1-ae15-c07e185c2eba	en	Democracy	Форма правления, основанная на воле народа	\N	f	\N	1
379	6400258b-0021-4456-bea5-ad4ab07f4aed	ru	Глобализация	Процесс усиления мировой взаимозависимости	\N	t	a1000000-0000-0000-0000-000000000001	1
380	6400258b-0021-4456-bea5-ad4ab07f4aed	en	Globalization	Процесс усиления мировой взаимозависимости	\N	f	\N	1
381	5ea88755-26e9-4ddb-a1a8-7fb956a9ae8a	ru	Ренессанс	Эпоха культурного возрождения в Европе	\N	t	a1000000-0000-0000-0000-000000000001	1
382	5ea88755-26e9-4ddb-a1a8-7fb956a9ae8a	en	Renaissance	Эпоха культурного возрождения в Европе	\N	f	\N	1
383	fb23ce73-4dbe-4dc3-bea8-35438f725765	ru	Изменение климата	Глобальное изменение климатической системы Земли	\N	t	a1000000-0000-0000-0000-000000000001	1
384	fb23ce73-4dbe-4dc3-bea8-35438f725765	en	Climate Change	Глобальное изменение климатической системы Земли	\N	f	\N	1
385	7c7f0ff5-5849-47ad-bd2d-91f9fbea99a1	ru	Сюрреализм	Художественное направление, основанное на бессознательном	\N	t	a1000000-0000-0000-0000-000000000001	1
386	7c7f0ff5-5849-47ad-bd2d-91f9fbea99a1	en	Surrealism	Художественное направление, основанное на бессознательном	\N	f	\N	1
387	cdc02526-45c8-40c0-9648-e1301798825a	ru	Стоицизм	Древнегреческая философия самоконтроля	\N	t	a1000000-0000-0000-0000-000000000001	1
388	cdc02526-45c8-40c0-9648-e1301798825a	en	Stoicism	Древнегреческая философия самоконтроля	\N	f	\N	1
389	929628d4-a955-4645-9a0b-bc4a861ba8bd	ru	Научная фантастика	Жанр, основанный на научных достижениях	\N	t	a1000000-0000-0000-0000-000000000001	1
390	929628d4-a955-4645-9a0b-bc4a861ba8bd	en	Science Fiction	Жанр, основанный на научных достижениях	\N	f	\N	1
391	9730c0fa-e351-4c1f-9b78-c7edd1e1337a	ru	Нуар	Стиль кинематографа с мрачной атмосферой	\N	t	a1000000-0000-0000-0000-000000000001	1
392	9730c0fa-e351-4c1f-9b78-c7edd1e1337a	en	Film Noir	Стиль кинематографа с мрачной атмосферой	\N	f	\N	1
393	2800ae7e-b7f9-4475-9684-bbfba0dc2906	ru	Прогрессивный рок	Сложная структура и длинные композиции	\N	t	a1000000-0000-0000-0000-000000000001	1
394	2800ae7e-b7f9-4475-9684-bbfba0dc2906	en	Progressive Rock	Сложная структура и длинные композиции	\N	f	\N	1
395	21439c77-30ed-4b20-a353-f6bf66826412	ru	Гранж	Поджанр альтернативного рока	\N	t	a1000000-0000-0000-0000-000000000001	1
396	21439c77-30ed-4b20-a353-f6bf66826412	en	Grunge	Поджанр альтернативного рока	\N	f	\N	1
397	f09dba17-9dad-4a4b-bb7c-0850f412740d	ru	Антиутопия	Жанр о мрачном будущем	\N	t	a1000000-0000-0000-0000-000000000001	1
398	f09dba17-9dad-4a4b-bb7c-0850f412740d	en	Dystopia	Жанр о мрачном будущем	\N	f	\N	1
399	7ec1f5cb-47dc-47cb-a2dd-a2c4a8c361b9	ru	Регги	Ямайский музыкальный жанр	\N	t	a1000000-0000-0000-0000-000000000001	1
400	7ec1f5cb-47dc-47cb-a2dd-a2c4a8c361b9	en	Reggae	Ямайский музыкальный жанр	\N	f	\N	1
401	8c23ab7d-4927-4cd8-baa4-c349ac078fa2	ru	Хард-рок	Энергичная гитарная музыка	\N	t	a1000000-0000-0000-0000-000000000001	1
402	8c23ab7d-4927-4cd8-baa4-c349ac078fa2	en	Hard Rock	Энергичная гитарная музыка	\N	f	\N	1
403	b78f5b78-fc9f-4bba-9d2f-be0c98a53c9b	ru	Импрессионизм	Художественное направление в живописи	\N	t	a1000000-0000-0000-0000-000000000001	1
404	b78f5b78-fc9f-4bba-9d2f-be0c98a53c9b	en	Impressionism	Художественное направление в живописи	\N	f	\N	1
405	2ec9a308-af86-4a01-a3ed-1710a5ac21dd	ru	Барокко	Стиль в искусстве XVII века	\N	t	a1000000-0000-0000-0000-000000000001	1
406	2ec9a308-af86-4a01-a3ed-1710a5ac21dd	en	Baroque	Стиль в искусстве XVII века	\N	f	\N	1
407	94651f3c-c40a-4f85-a4e4-f21ba3737283	ru	Киберпанк	Поджанр научной фантастики	\N	t	a1000000-0000-0000-0000-000000000001	1
408	94651f3c-c40a-4f85-a4e4-f21ba3737283	en	Cyberpunk	Поджанр научной фантастики	\N	f	\N	1
409	e123000b-8bdb-49dc-a694-14330b7878c9	ru	Северное сияние	Световое явление в полярных широтах	\N	t	a1000000-0000-0000-0000-000000000001	1
410	e123000b-8bdb-49dc-a694-14330b7878c9	en	Aurora Borealis	Световое явление в полярных широтах	\N	f	\N	1
411	e7fdeb64-4db0-48fc-b2cb-bebd928dbd27	ru	Гравитация	Сила притяжения между телами	\N	t	a1000000-0000-0000-0000-000000000001	1
412	e7fdeb64-4db0-48fc-b2cb-bebd928dbd27	en	Gravity	Сила притяжения между телами	\N	f	\N	1
413	8f6afea3-9bb8-4d9e-9265-31cf569b1c39	ru	Фотосинтез	Процесс образования органических веществ из CO2 и воды	\N	t	a1000000-0000-0000-0000-000000000001	1
414	8f6afea3-9bb8-4d9e-9265-31cf569b1c39	en	Photosynthesis	Процесс образования органических веществ из CO2 и воды	\N	f	\N	1
415	afeb44a8-f93d-441b-b89f-fb51d1c9302f	ru	Эволюция	Процесс изменения организмов во времени	\N	t	a1000000-0000-0000-0000-000000000001	1
416	afeb44a8-f93d-441b-b89f-fb51d1c9302f	en	Evolution	Процесс изменения организмов во времени	\N	f	\N	1
417	32b62974-af60-4ad1-853f-4b1e232d24a6	ru	Квантовая запутанность	Квантовое явление корреляции частиц	\N	t	a1000000-0000-0000-0000-000000000001	1
418	32b62974-af60-4ad1-853f-4b1e232d24a6	en	Quantum Entanglement	Квантовое явление корреляции частиц	\N	f	\N	1
419	f895fc34-79da-4fe2-81d9-5fc885a8096b	ru	Чёрная дыра	Объект с гравитацией, не выпускающей свет	\N	t	a1000000-0000-0000-0000-000000000001	1
420	f895fc34-79da-4fe2-81d9-5fc885a8096b	en	Black Hole	Объект с гравитацией, не выпускающей свет	\N	f	\N	1
421	23509af3-2a16-464d-ae37-17d962c7301d	ru	Торнадо	Мощный вращающийся вихрь	\N	t	a1000000-0000-0000-0000-000000000001	1
423	c4278647-d60c-4e2d-af89-6aae8bf5c233	ru	Континентальный дрейф	Движение материков по поверхности Земли	\N	t	a1000000-0000-0000-0000-000000000001	1
424	c4278647-d60c-4e2d-af89-6aae8bf5c233	en	Continental Drift	Движение материков по поверхности Земли	\N	f	\N	1
425	21f5acd5-5d9a-414f-8692-14b59869f7f2	ru	Мечтательность	Состояние увлечённости мечтами	\N	t	a1000000-0000-0000-0000-000000000001	1
426	21f5acd5-5d9a-414f-8692-14b59869f7f2	en	Dreaminess	Состояние увлечённости мечтами	\N	f	\N	1
427	7dbf9236-1dd5-4785-abbd-92d3f0808d65	ru	Южное сияние	Световое явление в южных широтах	\N	t	a1000000-0000-0000-0000-000000000001	1
428	7dbf9236-1dd5-4785-abbd-92d3f0808d65	en	Aurora Australis	Световое явление в южных широтах	\N	f	\N	1
429	2bd7a0b0-1e4b-4182-ab53-8f4a20e41f64	ru	Древний Рим	Цивилизация, оказавшая огромное влияние на мир	\N	t	a1000000-0000-0000-0000-000000000001	1
430	2bd7a0b0-1e4b-4182-ab53-8f4a20e41f64	en	Ancient Rome	Цивилизация, оказавшая огромное влияние на мир	\N	f	\N	1
431	b170a449-4c28-467a-b410-611bb5c9b460	ru	Средние века	Эпоха феодализма в Европе	\N	t	a1000000-0000-0000-0000-000000000001	1
432	b170a449-4c28-467a-b410-611bb5c9b460	en	Middle Ages	Эпоха феодализма в Европе	\N	f	\N	1
433	bf444bcd-f2c5-4bd0-8d3f-503214fb8171	ru	Промышленная революция	Переход от ручного труда к машинному	\N	t	a1000000-0000-0000-0000-000000000001	1
434	bf444bcd-f2c5-4bd0-8d3f-503214fb8171	en	Industrial Revolution	Переход от ручного труда к машинному	\N	f	\N	1
435	45457d27-05b9-4509-b7cb-445e0dd5e29a	ru	Холодная война	Геополитическое противостояние USA и USSR	\N	t	a1000000-0000-0000-0000-000000000001	1
436	45457d27-05b9-4509-b7cb-445e0dd5e29a	en	Cold War	Геополитическое противостояние USA и USSR	\N	f	\N	1
437	6db2b35a-441a-4701-aef5-4a7d5a4d1887	ru	Эпоха Возрождения	Культурное возрождение в Европе	\N	t	a1000000-0000-0000-0000-000000000001	1
438	6db2b35a-441a-4701-aef5-4a7d5a4d1887	en	Renaissance Period	Культурное возрождение в Европе	\N	f	\N	1
439	8a72467e-4dfd-4696-890b-e82afd0d15ad	ru	Эпоха Просвещения	Эпоха распространения научных знаний	\N	t	a1000000-0000-0000-0000-000000000001	1
440	8a72467e-4dfd-4696-890b-e82afd0d15ad	en	Age of Enlightenment	Эпоха распространения научных знаний	\N	f	\N	1
441	cf3be10d-89e3-4104-b444-6f3161c09f6c	ru	Цифровая эра	Эпоха компьютеров и интернета	\N	t	a1000000-0000-0000-0000-000000000001	1
442	cf3be10d-89e3-4104-b444-6f3161c09f6c	en	Digital Age	Эпоха компьютеров и интернета	\N	f	\N	1
443	b7f70d7a-6a4c-44df-ae95-b6b71cfd39b9	ru	Эра освоения космоса	Эпоха космических полётов	\N	t	a1000000-0000-0000-0000-000000000001	1
444	b7f70d7a-6a4c-44df-ae95-b6b71cfd39b9	en	Space Age	Эпоха космических полётов	\N	f	\N	1
445	c18b2fcf-017d-464b-b29a-3c2fd2dfd156	ru	Вторая мировая война	Крупнейший военный конфликт в истории	\N	t	a1000000-0000-0000-0000-000000000001	1
446	c18b2fcf-017d-464b-b29a-3c2fd2dfd156	en	World War II	Крупнейший военный конфликт в истории	\N	f	\N	1
447	8564232e-640e-42c5-a1df-0a339d9a409d	ru	Викторианская эпоха	Эпоха правления королевы Виктории	\N	t	a1000000-0000-0000-0000-000000000001	1
448	8564232e-640e-42c5-a1df-0a339d9a409d	en	Victorian Era	Эпоха правления королевы Виктории	\N	f	\N	1
449	9787517a-941a-4525-af34-d54132e601d9	ru	README.md	Документация проекта	\N	t	a1000000-0000-0000-0000-000000000001	1
450	9787517a-941a-4525-af34-d54132e601d9	en	README.md	Документация проекта	\N	f	\N	1
451	ba56c9e9-ebf9-4d8c-8a23-ccfcc0951afc	ru	schema.sql	SQL-схема базы данных	\N	t	a1000000-0000-0000-0000-000000000001	1
452	ba56c9e9-ebf9-4d8c-8a23-ccfcc0951afc	en	schema.sql	SQL-схема базы данных	\N	f	\N	1
453	5a5da171-ced3-445b-882a-d2ec2c0873b8	ru	config.yaml	Конфигурация приложения	\N	t	a1000000-0000-0000-0000-000000000001	1
454	5a5da171-ced3-445b-882a-d2ec2c0873b8	en	config.yaml	Конфигурация приложения	\N	f	\N	1
455	0664ab1a-77dd-46a7-a6e4-a80a7ea542d1	ru	docker-compose.yml	Определение Docker-сервисов	\N	t	a1000000-0000-0000-0000-000000000001	1
456	0664ab1a-77dd-46a7-a6e4-a80a7ea542d1	en	docker-compose.yml	Определение Docker-сервисов	\N	f	\N	1
457	3a4baf0a-e14c-4c20-a5d2-12c50e76cf57	ru	main.py	Главный файл приложения	\N	t	a1000000-0000-0000-0000-000000000001	1
458	3a4baf0a-e14c-4c20-a5d2-12c50e76cf57	en	main.py	Главный файл приложения	\N	f	\N	1
459	ba858154-8c3f-4f37-8bff-35c076aa8ada	ru	models.py	ORM-модели данных	\N	t	a1000000-0000-0000-0000-000000000001	1
460	ba858154-8c3f-4f37-8bff-35c076aa8ada	en	models.py	ORM-модели данных	\N	f	\N	1
461	b17d8c52-7170-4605-85a4-72531eff1b3f	ru	requirements.txt	Список зависимостей Python	\N	t	a1000000-0000-0000-0000-000000000001	1
462	b17d8c52-7170-4605-85a4-72531eff1b3f	en	requirements.txt	Список зависимостей Python	\N	f	\N	1
463	c85aa10c-655f-44f9-ae8a-1e430522ab2d	ru	Dockerfile	Инструкция сборки Docker-образа	\N	t	a1000000-0000-0000-0000-000000000001	1
464	c85aa10c-655f-44f9-ae8a-1e430522ab2d	en	Dockerfile	Инструкция сборки Docker-образа	\N	f	\N	1
465	1253e359-3cf0-49d2-a279-d3153b4f00fe	ru	index.html	Главная страница веб-интерфейса	\N	t	a1000000-0000-0000-0000-000000000001	1
466	1253e359-3cf0-49d2-a279-d3153b4f00fe	en	index.html	Главная страница веб-интерфейса	\N	f	\N	1
467	2b10e601-f4ac-4ae8-8ded-acb1d1571151	ru	style.css	Стили веб-интерфейса	\N	t	a1000000-0000-0000-0000-000000000001	1
468	2b10e601-f4ac-4ae8-8ded-acb1d1571151	en	style.css	Стили веб-интерфейса	\N	f	\N	1
469	e14ae6a8-376a-4339-973c-fa37cfbb1543	ru	Поколение битников	Литературное движение 1950-х	\N	t	a1000000-0000-0000-0000-000000000001	1
470	e14ae6a8-376a-4339-973c-fa37cfbb1543	en	Beat Generation	Литературное движение 1950-х	\N	f	\N	1
471	f6ccda96-7cd1-4d68-b756-9db1d84a6f0c	ru	Романтизм	Художественное направление конца XVIII века	\N	t	a1000000-0000-0000-0000-000000000001	1
472	f6ccda96-7cd1-4d68-b756-9db1d84a6f0c	en	Romanticism	Художественное направление конца XVIII века	\N	f	\N	1
473	9a36665c-a89a-4829-b6a7-102628d64b9a	ru	Кубизм	Революционное направление в живописи	\N	t	a1000000-0000-0000-0000-000000000001	1
474	9a36665c-a89a-4829-b6a7-102628d64b9a	en	Cubism	Революционное направление в живописи	\N	f	\N	1
475	3ddb497c-72f1-4046-9264-d29911798e31	ru	Панк-рок	Протестная музыка 1970-х	\N	t	a1000000-0000-0000-0000-000000000001	1
476	3ddb497c-72f1-4046-9264-d29911798e31	en	Punk Rock	Протестная музыка 1970-х	\N	f	\N	1
477	99738373-5e27-466b-9e8c-d18b1d91e6e1	ru	Импрессионизм	Революция в живописи XIX века	\N	t	a1000000-0000-0000-0000-000000000001	1
478	99738373-5e27-466b-9e8c-d18b1d91e6e1	en	Impressionism Movement	Революция в живописи XIX века	\N	f	\N	1
479	dd3c64a4-6feb-4c74-ae8a-29764dab4e11	ru	Экзистенциализм	Философское движение XX века	\N	t	a1000000-0000-0000-0000-000000000001	1
480	dd3c64a4-6feb-4c74-ae8a-29764dab4e11	en	Existentialism Movement	Философское движение XX века	\N	f	\N	1
481	8483b889-21b6-4839-9b51-4845ae59e581	ru	Минимализм	Музыкальное и художественное направление	\N	t	a1000000-0000-0000-0000-000000000001	1
482	8483b889-21b6-4839-9b51-4845ae59e581	en	Minimalism	Музыкальное и художественное направление	\N	f	\N	1
483	fc17dbbf-4e4a-48f4-aa77-28fabb1f19de	ru	Движение хиппи	Контркультура 1960-х	\N	t	a1000000-0000-0000-0000-000000000001	1
484	fc17dbbf-4e4a-48f4-aa77-28fabb1f19de	en	Hippie Movement	Контркультура 1960-х	\N	f	\N	1
485	387a24fa-f1d9-4737-8e54-f4a69578669b	ru	Сюрреализм	Художественное движение, основанное на подсознании	\N	t	a1000000-0000-0000-0000-000000000001	1
486	387a24fa-f1d9-4737-8e54-f4a69578669b	en	Surrealism Movement	Художественное движение, основанное на подсознании	\N	f	\N	1
487	b1f651d7-dbcd-48d2-8cbb-f29891f34d65	ru	Движение Возрождения	Возрождение искусства и науки	\N	t	a1000000-0000-0000-0000-000000000001	1
488	b1f651d7-dbcd-48d2-8cbb-f29891f34d65	en	Renaissance Movement	Возрождение искусства и науки	\N	f	\N	1
489	3b0eda53-895f-4ea5-9204-406250784d76	ru	Десятичная классификация Дьюи	Система классификации книг	\N	t	a1000000-0000-0000-0000-000000000001	1
490	3b0eda53-895f-4ea5-9204-406250784d76	en	Dewey Decimal Classification	Система классификации книг	\N	f	\N	1
491	1c9d6f07-3e36-4463-97c5-b5e92f6543a6	ru	ISO 3166	Коды стран	\N	t	a1000000-0000-0000-0000-000000000001	1
492	1c9d6f07-3e36-4463-97c5-b5e92f6543a6	en	ISO 3166	Коды стран	\N	f	\N	1
493	a853de21-1a72-4c42-9a67-e2881ca2045d	ru	Классификация ООН	Классификация экономической деятельности	\N	t	a1000000-0000-0000-0000-000000000001	1
494	a853de21-1a72-4c42-9a67-e2881ca2045d	en	UN Classification	Классификация экономической деятельности	\N	f	\N	1
495	6d983558-d3db-4047-8e24-6eed32da6c34	ru	ISO 639	Коды языков	\N	t	a1000000-0000-0000-0000-000000000001	1
496	6d983558-d3db-4047-8e24-6eed32da6c34	en	ISO 639	Коды языков	\N	f	\N	1
497	1429e676-43c3-4639-a5ed-b5aa42a0fc9f	ru	Периодическая таблица	Классификация химических элементов	\N	t	a1000000-0000-0000-0000-000000000001	1
498	1429e676-43c3-4639-a5ed-b5aa42a0fc9f	en	Periodic Table	Классификация химических элементов	\N	f	\N	1
499	2b840df2-219a-4b5c-8b08-5dddf8b262e1	ru	МКБ-10	Международная классификация болезней	\N	t	a1000000-0000-0000-0000-000000000001	1
500	2b840df2-219a-4b5c-8b08-5dddf8b262e1	en	ICD-10	Международная классификация болезней	\N	f	\N	1
501	995359be-1c66-40e0-8485-4ae46a31833d	ru	Классификация Линнея	Система классификации живых организмов	\N	t	a1000000-0000-0000-0000-000000000001	1
502	995359be-1c66-40e0-8485-4ae46a31833d	en	Linnaean Classification	Система классификации живых организмов	\N	f	\N	1
503	75d72ab4-af98-4bfb-895a-d9506b772556	ru	Библиотечная классификация	Система ББК	\N	t	a1000000-0000-0000-0000-000000000001	1
504	75d72ab4-af98-4bfb-895a-d9506b772556	en	Library Classification	Система ББК	\N	f	\N	1
505	87e67f23-ea6c-4386-8b25-d05592d13f07	ru	NACE	Европейская классификация экономической деятельности	\N	t	a1000000-0000-0000-0000-000000000001	1
506	87e67f23-ea6c-4386-8b25-d05592d13f07	en	NACE	Европейская классификация экономической деятельности	\N	f	\N	1
507	9cff73c5-192f-4c24-ae22-55410dfb84ee	ru	ATC	Анатомо-терапевтическо-химическая классификация	\N	t	a1000000-0000-0000-0000-000000000001	1
508	9cff73c5-192f-4c24-ae22-55410dfb84ee	en	ATC	Анатомо-терапевтическо-химическая классификация	\N	f	\N	1
509	32463c6e-d667-4a73-947d-f17b775cba40	ru	Розеттский камень	Ключ к расшифровке египетских иероглифов	\N	t	a1000000-0000-0000-0000-000000000001	1
510	32463c6e-d667-4a73-947d-f17b775cba40	en	Rosetta Stone	Ключ к расшифровке египетских иероглифов	\N	f	\N	1
511	53129942-9866-4b71-a11f-3fb0b46bcb90	ru	Мона Лиза	Знаменитая картина Леонардо да Винчи	\N	t	a1000000-0000-0000-0000-000000000001	1
512	53129942-9866-4b71-a11f-3fb0b46bcb90	en	Mona Lisa	Знаменитая картина Леонардо да Винчи	\N	f	\N	1
513	26cfcd3a-4a6e-4060-b5b2-869059eee7e9	ru	Великая Китайская стена	Древнее укрепление	\N	t	a1000000-0000-0000-0000-000000000001	1
514	26cfcd3a-4a6e-4060-b5b2-869059eee7e9	en	Great Wall of China	Древнее укрепление	\N	f	\N	1
515	8a45830b-ad78-4487-89b0-ee7a962015a2	ru	Пирамида Хеопса	Единственное из Семи чудес света	\N	t	a1000000-0000-0000-0000-000000000001	1
516	8a45830b-ad78-4487-89b0-ee7a962015a2	en	Great Pyramid of Giza	Единственное из Семи чудес света	\N	f	\N	1
517	f50a0a19-4fb6-4125-b054-34a59fdde08e	ru	Колизей	Древнеримский амфитеатр	\N	t	a1000000-0000-0000-0000-000000000001	1
518	f50a0a19-4fb6-4125-b054-34a59fdde08e	en	Colosseum	Древнеримский амфитеатр	\N	f	\N	1
519	16180497-666f-434d-bc7a-37bef39d6225	ru	Стоунхендж	Загадочный мегалитический памятник	\N	t	a1000000-0000-0000-0000-000000000001	1
520	16180497-666f-434d-bc7a-37bef39d6225	en	Stonehenge	Загадочный мегалитический памятник	\N	f	\N	1
521	e6f19811-6f9f-4482-a529-2f3f8fb9e149	ru	Тадж-Махал	Мавзолей в Агре	\N	t	a1000000-0000-0000-0000-000000000001	1
522	e6f19811-6f9f-4482-a529-2f3f8fb9e149	en	Taj Mahal	Мавзолей в Агре	\N	f	\N	1
523	1d2041fd-963a-4a0e-852a-b76f18b9d263	ru	Эйфелева башня	Символ Парижа	\N	t	a1000000-0000-0000-0000-000000000001	1
524	1d2041fd-963a-4a0e-852a-b76f18b9d263	en	Eiffel Tower	Символ Парижа	\N	f	\N	1
525	17eb8177-4cb8-44cc-844e-280e2b6e34c6	ru	Статуя Свободы	Символ свободы Америки	\N	t	a1000000-0000-0000-0000-000000000001	1
526	17eb8177-4cb8-44cc-844e-280e2b6e34c6	en	Statue of Liberty	Символ свободы Америки	\N	f	\N	1
527	ff76ceeb-039c-4ad8-999d-7df99e8e7a47	ru	Парфенон	Древнегреческий храм	\N	t	a1000000-0000-0000-0000-000000000001	1
528	ff76ceeb-039c-4ad8-999d-7df99e8e7a47	en	Parthenon	Древнегреческий храм	\N	f	\N	1
529	192fa802-8d30-4838-a13a-e76acd3d5da4	ru	Афганская девочка	Знаменитый портрет Стива Маккарри	\N	t	a1000000-0000-0000-0000-000000000001	1
530	192fa802-8d30-4838-a13a-e76acd3d5da4	en	Afghan Girl	Знаменитый портрет Стива Маккарри	\N	f	\N	1
531	c563b603-4af0-4b7c-9f7c-3fd70402e0d4	ru	Восход Земли	Фото Земли с Луны	\N	t	a1000000-0000-0000-0000-000000000001	1
532	c563b603-4af0-4b7c-9f7c-3fd70402e0d4	en	Earthrise	Фото Земли с Луны	\N	f	\N	1
533	7900ac07-0528-470c-aded-4760fb15d894	ru	V-J Day in Times Square	Знаменитый поцелуй на Таймс-сквер	\N	t	a1000000-0000-0000-0000-000000000001	1
534	7900ac07-0528-470c-aded-4760fb15d894	en	V-J Day in Times Square	Знаменитый поцелуй на Таймс-сквер	\N	f	\N	1
535	2c9edd9d-77c3-4839-9f12-46c2e252a5aa	ru	Бледно-голубая точка	Фото Земли с расстояния 6 млрд км	\N	t	a1000000-0000-0000-0000-000000000001	1
536	2c9edd9d-77c3-4839-9f12-46c2e252a5aa	en	Pale Blue Dot	Фото Земли с расстояния 6 млрд км	\N	f	\N	1
537	18b40d02-87ec-4497-8b58-19e8f574d6cf	ru	Мать-мигрантка	Иконическое фото Великой депрессии	\N	t	a1000000-0000-0000-0000-000000000001	1
538	18b40d02-87ec-4497-8b58-19e8f574d6cf	en	Migrant Mother	Иконическое фото Великой депрессии	\N	f	\N	1
539	8d600c86-9e46-487c-91fa-e688407d990c	ru	Обед на небоскрёбе	Рабочие на балке над Нью-Йорком	\N	t	a1000000-0000-0000-0000-000000000001	1
540	8d600c86-9e46-487c-91fa-e688407d990c	en	Lunch atop a Skyscraper	Рабочие на балке над Нью-Йорком	\N	f	\N	1
541	40a23b6d-f3b6-465f-ae9c-4b0ce56dfad2	ru	Сила цветов	Девушка с цветком против солдат	\N	t	a1000000-0000-0000-0000-000000000001	1
542	40a23b6d-f3b6-465f-ae9c-4b0ce56dfad2	en	Flower Power	Девушка с цветком против солдат	\N	f	\N	1
543	cfd62e03-5400-47f5-95b2-8f53c1f33075	ru	Поцелуй	Знаменитый поцелуй на Манхэттене	\N	t	a1000000-0000-0000-0000-000000000001	1
544	cfd62e03-5400-47f5-95b2-8f53c1f33075	en	The Kiss	Знаменитый поцелуй на Манхэттене	\N	f	\N	1
545	6b9add19-73e1-4cf3-bb86-efbc215af007	ru	Стратегия выживания	Трагическое фото из Судана	\N	t	a1000000-0000-0000-0000-000000000001	1
546	6b9add19-73e1-4cf3-bb86-efbc215af007	en	The Struggling Girl	Трагическое фото из Судана	\N	f	\N	1
547	36ea6a1f-dd51-4f8a-94c7-8d1ce60f9ce1	ru	Глубокое поле Хаббла	Фото далёких галактик	\N	t	a1000000-0000-0000-0000-000000000001	1
548	36ea6a1f-dd51-4f8a-94c7-8d1ce60f9ce1	en	Hubble Deep Field	Фото далёких галактик	\N	f	\N	1
549	30ead965-9b99-451f-b4db-2e192fb7aded	ru	Теория относительности	Статья Эйнштейна о специальной относительности	\N	t	a1000000-0000-0000-0000-000000000001	1
550	30ead965-9b99-451f-b4db-2e192fb7aded	en	Theory of Relativity	Статья Эйнштейна о специальной относительности	\N	f	\N	1
551	b1cef78e-be21-441b-9add-4af5569ac6b0	ru	Происхождение видов	Трактат Дарвина об эволюции	\N	t	a1000000-0000-0000-0000-000000000001	1
552	b1cef78e-be21-441b-9add-4af5569ac6b0	en	On the Origin of Species	Трактат Дарвина об эволюции	\N	f	\N	1
553	7d3c1b4d-0714-450f-a06b-9648b9cf2d90	ru	Манифест коммунистической партии	Политический трактат Маркса и Энгельса	\N	t	a1000000-0000-0000-0000-000000000001	1
554	7d3c1b4d-0714-450f-a06b-9648b9cf2d90	en	Communist Manifesto	Политический трактат Маркса и Энгельса	\N	f	\N	1
555	c2b27452-d479-4382-a750-93977d2b0e4a	ru	Государство	Философский диалог Платона	\N	t	a1000000-0000-0000-0000-000000000001	1
556	c2b27452-d479-4382-a750-93977d2b0e4a	en	The Republic	Философский диалог Платона	\N	f	\N	1
557	4c122d28-61f6-4d69-b58f-d1d1dec02d02	ru	Начала	Фундаментальный труд Ньютона	\N	t	a1000000-0000-0000-0000-000000000001	1
558	4c122d28-61f6-4d69-b58f-d1d1dec02d02	en	Principia Mathematica	Фундаментальный труд Ньютона	\N	f	\N	1
559	55d799fd-74d0-4545-93a0-539d3d44b700	ru	Критика чистого разума	Главный труд Канта	\N	t	a1000000-0000-0000-0000-000000000001	1
560	55d799fd-74d0-4545-93a0-539d3d44b700	en	Critique of Pure Reason	Главный труд Канта	\N	f	\N	1
561	b75c64b8-a707-41be-afc0-a585bde7e9b2	ru	Исследование о природе и богатстве народов	Основополагающий труд экономики	\N	t	a1000000-0000-0000-0000-000000000001	1
562	b75c64b8-a707-41be-afc0-a585bde7e9b2	en	The Wealth of Nations	Основополагающий труд экономики	\N	f	\N	1
563	8b15e1c0-3472-420b-9b1a-8c1d5944e62c	ru	Два трактата о правлении	Политический трактат Локка	\N	t	a1000000-0000-0000-0000-000000000001	1
564	8b15e1c0-3472-420b-9b1a-8c1d5944e62c	en	Two Treatises of Government	Политический трактат Локка	\N	f	\N	1
565	0825a264-83a9-4413-bf50-a77c31ee2580	ru	Богатство народов	Трактат о экономике	\N	t	a1000000-0000-0000-0000-000000000001	1
566	0825a264-83a9-4413-bf50-a77c31ee2580	en	The Wealth	Трактат о экономике	\N	f	\N	1
567	c770f360-33dc-45c2-b811-ab856cc0fc30	ru	Капитал	Экономический трактат Маркса	\N	t	a1000000-0000-0000-0000-000000000001	1
568	c770f360-33dc-45c2-b811-ab856cc0fc30	en	Das Kapital	Экономический трактат Маркса	\N	f	\N	1
569	42cac073-bfd6-420e-89a2-5eab703042b6	ru	Альберт Эйнштейн	Великий физик, создатель теории относительности	\N	t	a1000000-0000-0000-0000-000000000001	1
570	42cac073-bfd6-420e-89a2-5eab703042b6	en	Albert Einstein	Великий физик, создатель теории относительности	\N	f	\N	1
571	739f01e6-af8e-49b4-9834-b2d981eda3c3	ru	Леонардо да Винчи	Универсальный гений эпохи Возрождения	\N	t	a1000000-0000-0000-0000-000000000001	1
572	739f01e6-af8e-49b4-9834-b2d981eda3c3	en	Leonardo da Vinci	Универсальный гений эпохи Возрождения	\N	f	\N	1
573	4c2a367e-3250-4e23-92a7-d25231d5baef	ru	Исаак Ньютон	Основоположник классической механики	\N	t	a1000000-0000-0000-0000-000000000001	1
574	4c2a367e-3250-4e23-92a7-d25231d5baef	en	Isaac Newton	Основоположник классической механики	\N	f	\N	1
575	d0f8a70b-b1f7-48f4-95e6-3c58e4a86b2b	ru	Никола Тесла	Изобретатель и электроинженер	\N	t	a1000000-0000-0000-0000-000000000001	1
576	d0f8a70b-b1f7-48f4-95e6-3c58e4a86b2b	en	Nikola Tesla	Изобретатель и электроинженер	\N	f	\N	1
577	7f3107e7-796b-490f-869a-5d71521bc46e	ru	Мария Кюри	Первая женщина-лауреат Нобелевской премии	\N	t	a1000000-0000-0000-0000-000000000001	1
578	7f3107e7-796b-490f-869a-5d71521bc46e	en	Marie Curie	Первая женщина-лауреат Нобелевской премии	\N	f	\N	1
579	c744a36a-9aa5-4d60-8896-242132e90ac5	ru	Чарльз Дарвин	Создатель теории эволюции	\N	t	a1000000-0000-0000-0000-000000000001	1
580	c744a36a-9aa5-4d60-8896-242132e90ac5	en	Charles Darwin	Создатель теории эволюции	\N	f	\N	1
581	602e8d7d-ec89-4c85-80cf-7ae822b18f58	ru	Платон	Древнегреческий философ	\N	t	a1000000-0000-0000-0000-000000000001	1
582	602e8d7d-ec89-4c85-80cf-7ae822b18f58	en	Plato	Древнегреческий философ	\N	f	\N	1
583	92039fd9-1eaa-4d7e-ac10-268281afd9ac	ru	Уильям Шекспир	Величайший драматург мира	\N	t	a1000000-0000-0000-0000-000000000001	1
584	92039fd9-1eaa-4d7e-ac10-268281afd9ac	en	William Shakespeare	Величайший драматург мира	\N	f	\N	1
585	4ad80497-ccd6-4371-ab57-96d8b91e9a09	ru	Конфуций	Великий китайский философ	\N	t	a1000000-0000-0000-0000-000000000001	1
586	4ad80497-ccd6-4371-ab57-96d8b91e9a09	en	Confucius	Великий китайский философ	\N	f	\N	1
587	04ca95fc-d46c-41a1-bb8a-a9932fdc0fbb	ru	Махатма Ганди	Лидер движения за независимость Индии	\N	t	a1000000-0000-0000-0000-000000000001	1
588	04ca95fc-d46c-41a1-bb8a-a9932fdc0fbb	en	Mahatma Gandhi	Лидер движения за независимость Индии	\N	f	\N	1
589	8a532ed1-c830-427c-a8ad-2e73a4f3a0b2	ru	Пабло Пикассо	Испанский художник, основоположник кубизма	\N	t	a1000000-0000-0000-0000-000000000001	1
590	8a532ed1-c830-427c-a8ad-2e73a4f3a0b2	en	Pablo Picasso	Испанский художник, основоположник кубизма	\N	f	\N	1
591	f9650917-3e26-4be7-a635-ef4886cbc18f	ru	Винсент Ван Гог	Нидерландский постимпрессионист	\N	t	a1000000-0000-0000-0000-000000000001	1
592	f9650917-3e26-4be7-a635-ef4886cbc18f	en	Vincent van Gogh	Нидерландский постимпрессионист	\N	f	\N	1
593	1de91eb3-e5ed-439f-9630-b14cb1abf490	ru	Клод Моне	Основатель импрессионизма	\N	t	a1000000-0000-0000-0000-000000000001	1
594	1de91eb3-e5ed-439f-9630-b14cb1abf490	en	Claude Monet	Основатель импрессионизма	\N	f	\N	1
595	bab8e621-eb12-4d5c-9f1d-6bcdefb375a0	ru	Микеланджело	Итальянский скульптор и живописец	\N	t	a1000000-0000-0000-0000-000000000001	1
596	bab8e621-eb12-4d5c-9f1d-6bcdefb375a0	en	Michelangelo	Итальянский скульптор и живописец	\N	f	\N	1
597	6d43a160-64d9-431f-ad10-8b012f01f15b	ru	Рембрандт	Великий нидерландский живописец	\N	t	a1000000-0000-0000-0000-000000000001	1
598	6d43a160-64d9-431f-ad10-8b012f01f15b	en	Rembrandt	Великий нидерландский живописец	\N	f	\N	1
599	bea2edde-5ade-474a-b441-ff5ef24a6627	ru	Сальвадор Дали	Испанский сюрреалист	\N	t	a1000000-0000-0000-0000-000000000001	1
600	bea2edde-5ade-474a-b441-ff5ef24a6627	en	Salvador Dali	Испанский сюрреалист	\N	f	\N	1
601	ce480988-cdc7-4ce0-9e70-9d0422f85c3a	ru	Энди Уорхол	Лидер поп-арта	\N	t	a1000000-0000-0000-0000-000000000001	1
602	ce480988-cdc7-4ce0-9e70-9d0422f85c3a	en	Andy Warhol	Лидер поп-арта	\N	f	\N	1
603	5901e379-0867-4b89-aa06-5741498f67e7	ru	Фрида Кало	Мексиканская художница-сюрреалистка	\N	t	a1000000-0000-0000-0000-000000000001	1
604	5901e379-0867-4b89-aa06-5741498f67e7	en	Frida Kahlo	Мексиканская художница-сюрреалистка	\N	f	\N	1
605	29d6595c-a8df-49df-912b-555eb61dc11c	ru	Василий Кандинский	Пионер абстрактного искусства	\N	t	a1000000-0000-0000-0000-000000000001	1
606	29d6595c-a8df-49df-912b-555eb61dc11c	en	Wassily Kandinsky	Пионер абстрактного искусства	\N	f	\N	1
607	bf8fa84f-ed54-41e4-9a47-bd082fd9c6df	ru	Караваджо	Итальянский барочный живописец	\N	t	a1000000-0000-0000-0000-000000000001	1
608	bf8fa84f-ed54-41e4-9a47-bd082fd9c6df	en	Caravaggio	Итальянский барочный живописец	\N	f	\N	1
609	51db8499-cdd6-48b8-ae65-e05a29e3a2e8	ru	Стивен Хокинг	Физик-теоретик, исследователь чёрных дыр	\N	t	a1000000-0000-0000-0000-000000000001	1
610	51db8499-cdd6-48b8-ae65-e05a29e3a2e8	en	Stephen Hawking	Физик-теоретик, исследователь чёрных дыр	\N	f	\N	1
611	b5cddb03-0bb2-43d3-ac04-c7b2c70c53df	ru	Ричард Фейнман	Нобелевский лауреат по квантовой электродинамике	\N	t	a1000000-0000-0000-0000-000000000001	1
612	b5cddb03-0bb2-43d3-ac04-c7b2c70c53df	en	Richard Feynman	Нобелевский лауреат по квантовой электродинамике	\N	f	\N	1
613	1af61118-34a1-4bf9-8988-26f85ba06f48	ru	Чарльз Дарвин	Натуралист, теория эволюции	\N	t	a1000000-0000-0000-0000-000000000001	1
614	1af61118-34a1-4bf9-8988-26f85ba06f48	en	Charles Darwin	Натуралист, теория эволюции	\N	f	\N	1
615	7cc15fa4-879b-456b-8481-63cd73605e34	ru	Нильс Бор	Основоположник квантовой механики	\N	t	a1000000-0000-0000-0000-000000000001	1
616	7cc15fa4-879b-456b-8481-63cd73605e34	en	Niels Bohr	Основоположник квантовой механики	\N	f	\N	1
617	4e603c34-e64c-4cb9-bf8a-f73a36ca1b39	ru	Макс Планк	Основатель квантовой теории	\N	t	a1000000-0000-0000-0000-000000000001	1
618	4e603c34-e64c-4cb9-bf8a-f73a36ca1b39	en	Max Planck	Основатель квантовой теории	\N	f	\N	1
619	d8e2ddde-de40-40bc-a501-f9818e0b7cf6	ru	Дмитрий Менделеев	Создатель таблицы Менделеева	\N	t	a1000000-0000-0000-0000-000000000001	1
620	d8e2ddde-de40-40bc-a501-f9818e0b7cf6	en	Dmitri Mendeleev	Создатель таблицы Менделеева	\N	f	\N	1
621	31dfc80c-4ec5-43c1-ae1e-4b634c8209bd	ru	Галилео Галилей	Отец современной науки	\N	t	a1000000-0000-0000-0000-000000000001	1
622	31dfc80c-4ec5-43c1-ae1e-4b634c8209bd	en	Galileo Galilei	Отец современной науки	\N	f	\N	1
623	badce0e7-49fd-4253-8069-82e9509d4ad6	ru	Лайнус Полинг	Двукратный нобелевский лауреат	\N	t	a1000000-0000-0000-0000-000000000001	1
624	badce0e7-49fd-4253-8069-82e9509d4ad6	en	Linus Pauling	Двукратный нобелевский лауреат	\N	f	\N	1
625	6c1b7a1d-a4c5-453e-afd7-3ff02e6b1eda	ru	Розалинд Франклин	Открывшая структуру ДНК	\N	t	a1000000-0000-0000-0000-000000000001	1
626	6c1b7a1d-a4c5-453e-afd7-3ff02e6b1eda	en	Rosalind Franklin	Открывшая структуру ДНК	\N	f	\N	1
627	1458508b-bd19-4996-be27-1a87860aec35	ru	Алан Тьюринг	Отец компьютерных наук	\N	t	a1000000-0000-0000-0000-000000000001	1
628	1458508b-bd19-4996-be27-1a87860aec35	en	Alan Turing	Отец компьютерных наук	\N	f	\N	1
629	3a4da93c-0741-4717-a423-2e47c5ba8eab	ru	картинко	описание картинко	\N	t	a1000000-0000-0000-0000-000000000001	2
630	3a4da93c-0741-4717-a423-2e47c5ba8eab	en	opisanie kartinko	\N	\N	f	\N	2
631	24a3b922-3ba0-4077-b0db-6eea4d22beca	ru	Золотой.телёнок	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
632	ccfb8bb4-73cc-4269-86aa-88371c4485b6	ru	Доспехи бога	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
633	1ea63bec-f46d-43d4-bfce-ec55c7e3b96c	ru	Гремлины	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
634	8877988a-cc00-4360-902c-b9236ef36f1c	ru	Тяжелый.Металл	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
635	058e03ee-0404-4bc5-b449-260f1f29e6a1	ru	Приключения.Электроника	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
636	5ceefbba-b512-467e-9bbb-2f8a537bd2b9	ru	Taxi	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
637	387fb842-3e32-462c-a70a-714bab27a2eb	ru	Тот.самый.Мюнхгаузен	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
638	8f5afa8d-d5cf-41b8-9330-7794bdfa761e	ru	Не.бойся,.я.с.тобой.(1981)	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
639	64a2dfe2-ea09-492c-8302-3e0c92e24c8d	ru	3840x	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
640	e2c3c575-32e2-4e12-83da-f0bfb086ef24	ru	призрак в доспехах	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
641	4cb4bd5c-599a-4a8f-bfa0-44f2b5ff4ac8	ru	futurama	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
642	c7940df6-46a1-483b-a8b0-0fb0d60019f2	ru	i	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
643	eb2cb77f-513e-450a-a911-aa2fd912f5c3	ru	orig (1)	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
644	8bf8898d-097d-414e-beab-2c84e8fdd08b	ru	test cover	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
645	163f66ff-44d7-4580-85ab-39c5bfbe1e9d	ru	maxresdefault	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
646	e66174d9-06a6-4caa-b896-e954d5087cbb	ru	IMDb ID	Идентификатор в базе IMDb	\N	t	\N	2
647	a906d913-ac95-45b0-adc2-e4b08fcec21a	ru	TMDb ID		\N	t	\N	3
648	6af186bf-565b-4ca4-8799-5c309a61ea53	ru	Хронометраж	Длительность в минутах	\N	t	\N	4
649	69776eb8-9425-46fa-b3ad-f1b535135200	ru	Рейтинг MPAA		\N	t	\N	5
650	fca7cd62-58d0-4103-9ac9-916b13fa9d23	ru	Бюджет	Бюджет производства	\N	t	\N	6
651	306287a6-1851-4701-841c-43b37eba32c2	ru	Сборы	Прокатные сборы	\N	t	\N	7
652	0c26ec5b-2ee8-4642-bf05-b508dbb3ddac	ru	Места съёмок		\N	t	\N	8
653	859820dc-0724-47ce-8ede-8c7d12746963	ru	Продюсерские компании		\N	t	\N	9
654	7668d04a-c745-4083-8b6a-9d96cdb7a697	ru	Слоган		\N	t	\N	10
655	0fdf2cca-af55-44bf-a5c6-4668d35356a0	ru	Количество голосов		\N	t	\N	11
656	fc44eac6-8287-4f98-8ec1-ab2ba860b44f	ru	Кинокомпания		\N	t	\N	12
657	29028900-dfc9-4cd7-9281-cd5a37f88d9f	ru	Название	Основное название сущности	\N	t	\N	13
658	4557e26d-735b-4518-9ea4-8fce83d419ec	ru	Описание	Подробное описание	\N	t	\N	14
659	51395a55-5bcd-4ae0-b2ca-275dcbaf03fa	ru	Год	Год создания или события	\N	t	\N	15
660	87d78c11-7ba0-415c-9e72-b1863da3ca41	ru	Жанр	Творческое направление	\N	t	\N	16
661	52d3d0e2-7233-4312-904c-158bc3408aa1	ru	Рейтинг	Оценка от 0 до 10	\N	t	\N	17
662	a566d1b6-4b21-4ee3-a03b-fbf9d4b3c18d	ru	Страна	Страна происхождения	\N	t	\N	18
663	cdd8873d-72d0-44e8-b12b-dda57fefae95	ru	Язык	Язык произведения	\N	t	\N	19
664	fa0c8e75-4b32-4932-a25d-a41594e6284b	ru	Бюджет (млн)		\N	t	\N	20
665	0b81ab90-ce6e-4e5e-8372-7cedf8f1f0b0	ru	Длительность (мин)		\N	t	\N	21
666	e7f67fa4-8b5e-4a21-9ee7-1dfd016e0e79	ru	Автор		\N	t	\N	22
667	2db68426-d7fb-4558-85d6-2200c4be7483	ru	Страниц		\N	t	\N	23
668	e87f137c-0dd4-4ef1-bcab-90947f245310	ru	ISBN		\N	t	\N	24
669	7c268ffe-390a-42f6-a295-3cbaf14bd4ed	ru	Дата выхода		\N	t	\N	25
670	8083d83c-1095-4467-892b-73ab6f7b38a3	ru	Дата начала		\N	t	\N	26
671	2740d254-056a-4355-8bf6-e3f511053c7e	ru	Дата окончания		\N	t	\N	27
672	f0a5ae18-416c-4cd0-8ce8-5eae3b62a46b	ru	Цена		\N	t	\N	28
673	7a445a3b-a359-4090-b87d-56a72d2561e9	ru	Сайт		\N	t	\N	29
674	16e0ab11-a890-4a0c-9ae5-e9760dc6caba	ru	Email		\N	t	\N	30
675	50560847-3cfc-414b-8659-222fe703e181	ru	Контент (Markdown)		\N	t	\N	31
676	f8dec4ff-ef2d-4c25-9985-ce576f01fce6	ru	Возрастной рейтинг		\N	t	\N	32
677	5b3db321-e48a-4fd2-8bbf-73edb79e93c9	ru	Версия	Номер версии	\N	t	\N	33
678	3695518e-aa08-4f99-8421-62fb84454a6c	ru	Лицензия	Тип лицензии	\N	t	\N	34
679	c897e8e5-2f44-47e7-b93e-c3240967f793	ru	URL репозитория		\N	t	\N	35
680	7e1abafa-5000-47eb-96ed-f65f268d2c3f	ru	Язык программирования		\N	t	\N	36
681	e45d48bc-398f-4c4f-aa41-259ddf8fd143	ru	Платформа		\N	t	\N	37
682	6cd97c90-dd19-4c1c-848d-2dfa70eeb9c0	ru	Разработчик		\N	t	\N	38
683	621a6f31-c9b5-4a63-805e-eca92ce9814e	ru	Дата события	Дата проведения события	\N	t	\N	39
684	a2b6152e-388d-496c-9972-a3c3a7d6e6e7	ru	Дата окончания		\N	t	\N	40
685	834fa7cd-5b92-4849-9522-7d5e9d9df64b	ru	Место проведения		\N	t	\N	41
686	5db2a94e-43a7-49c7-96fa-8c60cb1152ed	ru	Организатор		\N	t	\N	42
687	efbc604f-c1e3-425d-b0d6-f3c7281c2d95	ru	Число участников		\N	t	\N	43
688	10d0b551-2b83-42d6-a983-c3465cb16f94	ru	Цена билета		\N	t	\N	44
689	8c450ef6-a30b-4fc4-a0e9-397908ac32fb	ru	Игровой движок		\N	t	\N	45
690	51611186-f6ba-473f-b5bd-92b8ac47271e	ru	Платформы		\N	t	\N	46
691	7a44f578-6a88-4b63-b0df-a69b1a0820de	ru	Кол-во игроков		\N	t	\N	47
692	cfb13f53-8d02-4bb1-a857-ae5f32400de1	ru	Рейтинг ESRB		\N	t	\N	48
693	c21b5e7b-9139-4449-9779-7e1faa9909a9	ru	Широта	Географическая широта	\N	t	\N	49
694	dd58db39-620a-4dcc-b6db-53b0d6fc6d32	ru	Долгота	Географическая долгота	\N	t	\N	50
695	672956aa-18e5-4de8-b812-0f025a815a62	ru	Высота (м)		\N	t	\N	51
696	5c7b2aab-226c-40ec-9d67-aefa5cbc5cfb	ru	Часовой пояс		\N	t	\N	52
697	83393a4c-4dac-4e25-9c5d-0992ff381746	ru	Площадь (км²)		\N	t	\N	53
698	d2356d9e-df72-4cb5-bf34-f895df20056e	ru	Население		\N	t	\N	54
699	d3313362-0c00-49e9-92e7-7bd6d47cddc1	ru	Почтовый индекс		\N	t	\N	55
700	2d134f2b-010a-4fe2-bf12-ee93dc343850	ru	ISO код		\N	t	\N	56
701	64a70b92-8c8e-4763-9542-7f520cabc9da	ru	Издатель	Издательство	\N	t	\N	57
702	41858589-b5ed-41bd-946d-e75f457e62d3	ru	Город издания		\N	t	\N	58
703	9141ee3c-c83d-4730-8828-416d8385a973	ru	Издание		\N	t	\N	59
704	b837ade1-ac04-4ed3-a631-8a6b9c2e5291	ru	Переводчик		\N	t	\N	60
705	05bac44f-54b7-42b9-8e4e-e30d0b103efb	ru	Язык оригинала		\N	t	\N	61
706	6a28f029-ddc2-4120-8fe7-28a1b361cb4d	ru	Десятичный код Дьюи		\N	t	\N	62
707	1c9f03b8-2309-4b59-ac26-ea5ba2b1024e	ru	Постер		\N	t	\N	63
708	369fe9c8-7839-432d-b1e0-b23c34ba53b3	ru	Изображения		\N	t	\N	64
709	e965c7bd-f8f4-4bbf-b4a5-1b51abf8c1fc	ru	Видео		\N	t	\N	65
710	708d1c90-2f73-4757-9a0f-3319350d3d74	ru	Аудио		\N	t	\N	66
711	8762c43d-8e8e-4977-9e69-f1c77e3baa41	ru	Файл		\N	t	\N	67
712	e2a1125f-8457-4fcc-8b2d-be5fe38d6810	ru	Название файла		\N	t	\N	68
713	9cdf7eb1-420b-4c77-9af3-8ca575b58ad8	ru	Номер эпизода		\N	t	\N	69
714	eec27388-96e1-4d80-8356-0ce7fea2bf22	ru	Номер сезона		\N	t	\N	70
715	0b25635d-07c0-424c-84c4-88c06b6231e7	ru	URL подкаста		\N	t	\N	71
716	3674cffb-1308-4671-a49d-9de30d991615	ru	URL канала		\N	t	\N	72
717	5f2fad97-43d9-463d-a326-9578ff29b8ee	ru	Исполнитель		\N	t	\N	73
718	279b4865-bd06-4be5-ab2e-03284416eb70	ru	Альбом		\N	t	\N	74
719	54db1b64-d1f1-4c4b-a51f-ff17989d10fa	ru	BPM		\N	t	\N	75
720	e4fa9e7b-84e8-4284-b09f-5ae2fc98d1d4	ru	ISRC	Международный стандартный код записи	\N	t	\N	76
721	ed532ab3-134a-4e40-8a83-82b057a0b5f5	ru	ISWC		\N	t	\N	77
722	91b6d7e4-b4b5-4604-b8d2-b0e548370229	ru	Номер трека		\N	t	\N	78
723	0c731b79-48f7-4cd5-9ee6-7cddcbc4059e	ru	Номер диска		\N	t	\N	79
724	f122a48c-6683-4cde-944e-200fadccafac	ru	Есть нецензурный контент		\N	t	\N	80
725	fde1ecd4-ccb9-48f8-bcf0-2c7b788dd6ab	ru	Тональность		\N	t	\N	81
726	65e96845-dad5-4e31-ad2e-fd8eaf9594ca	ru	Размерность		\N	t	\N	82
727	e2ba9020-2019-4ca9-a1c3-bfe04b285b0a	ru	Лейбл		\N	t	\N	83
728	e82819ac-b840-4323-8573-7e08c9d24f18	ru	Дата основания	Дата основания организации	\N	t	\N	84
729	aa8a9231-caf4-4c65-8d6b-a2cc5fd47a31	ru	Дата роспуска		\N	t	\N	85
730	84d76e43-7d13-41f1-9e85-b8e4b65e0d1c	ru	Основатель		\N	t	\N	86
731	ce740df6-b817-457a-8dc8-f47a174a45cb	ru	Отрасль		\N	t	\N	87
732	1b99e712-73f8-4f74-8ac2-2f734c21dc61	ru	Число сотрудников		\N	t	\N	88
733	aca43b1c-341f-4b10-af2a-6801719bd242	ru	Штаб-квартира		\N	t	\N	89
734	501d186a-f239-454c-ab02-dad26ab85263	ru	Имя	Личное имя	\N	t	\N	90
735	9be46b9f-0097-46ce-bb31-9b92339e3bd0	ru	Фамилия	Фамилия	\N	t	\N	91
736	c7eb9698-deeb-4f2a-8d40-4190006c55c8	ru	Отчество		\N	t	\N	92
737	cc56d0bf-a031-4ba6-8904-c14f6344d234	ru	Дата рождения	Дата рождения	\N	t	\N	93
738	10ffb420-a434-447b-b207-6b2f3c9b107f	ru	Место рождения		\N	t	\N	94
739	15352e27-8d98-42ca-adcb-78d1f7bc83df	ru	Дата смерти		\N	t	\N	95
740	7d6a7080-967b-48cc-8034-53b1662f4681	ru	Место смерти		\N	t	\N	96
741	b23c6d35-ec9a-429d-891d-aabdb23f1082	ru	Рост (см)		\N	t	\N	97
742	defed9c0-35a9-420f-afcb-a6b0180584fb	ru	Национальность		\N	t	\N	98
743	84da9ec5-cec4-4e37-acef-1c9572014138	ru	Профессия		\N	t	\N	99
744	1f5c413e-1aed-4c2e-96c7-39d8dc30d2d0	ru	Электронная конфигурация		\N	t	\N	100
745	783ef653-d827-4583-b9cb-6d3d6470ee5d	ru	Степени окисления		\N	t	\N	101
746	f763b263-01bf-4721-bbc0-8529a716c627	ru	Электроотрицательность		\N	t	\N	102
747	e802227c-4f05-446e-ac3b-b99421b1401c	ru	Плотность		\N	t	\N	103
748	14753e08-083b-4068-8e9e-ffe785b64468	ru	Температура плавления		\N	t	\N	104
749	1aa33c64-8a8b-4ef8-9f1f-99a187b1e1e3	ru	Температура кипения		\N	t	\N	105
750	257bfc6b-5728-4955-8710-c4cc18041adc	ru	Год открытия		\N	t	\N	106
25	d0000007-0000-0000-0000-000000000001	ru	моана		\N	t	\N	1
753	4cacf75e-5bde-4587-8552-102584be4e14	ru	Ð¢ÐµÑÑÐ¾Ð²ÑÐ¹ ÑÐ¸Ð»ÑÐ¼	ÐÐ¿Ð¸ÑÐ°Ð½Ð¸Ðµ	\N	t	a1000000-0000-0000-0000-000000000001	108
755	a5cf7ea3-4ce6-43fa-a34d-66173cf61b71	ru	Ð¢ÐµÑÑ Ð¿ÑÐ¾ÐµÐºÑÐ¸Ð¹	ÐÐ¿Ð¸ÑÐ°Ð½Ð¸Ðµ	\N	t	a1000000-0000-0000-0000-000000000001	109
757	87135199-274e-4cc5-9027-dc0ca71c7206	ru	ÐÑÐ»ÑÑÐ¸ÑÐ¸Ð¿ ÑÐµÑÑ	ÐÐ¿Ð¸ÑÐ°Ð½Ð¸Ðµ	\N	t	a1000000-0000-0000-0000-000000000001	110
758	afed8c62-00d3-476b-a20c-2b8173d303a6	ru	Академия ведьмочек	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
752	28bd6d73-486b-411d-a0a4-be628e8bc486	ru	Название на русском	Описание на русском	\N	t	a1000000-0000-0000-0000-000000000001	107
759	bc2e4b44-1cc5-49bd-9150-344db72a1ada	ru	cinema	Кинематограф	\N	t	\N	101
760	bb0c3817-0c84-4636-bbe4-a2e526e2ed4a	ru	literature	Литература	\N	t	\N	102
761	5f187205-5b33-4ef3-b22d-548919737ae2	ru	music	Музыка	\N	t	\N	103
762	eb270429-1d7a-40ef-99ff-febd7e3c9cfd	ru	technology	Технологии	\N	t	\N	104
763	0c0ab9ea-fabc-4497-9b2a-551bce2633aa	ru	default	Базовая модель	\N	t	\N	105
764	c204aa0c-04c6-44ef-8e86-e53ff4a4eb81	ru	field_model	Онтологическая модель для полей реестра	\N	t	\N	106
765	af903b79-d26c-48b1-973b-a1bfaa229723	ru	ontology_entity_model	Модель для онтологий как сущностей	\N	t	\N	107
766	29f93b7a-c8a0-46bb-a5b9-8c7e4bbec851	ru	science	Наука	\N	t	\N	108
767	736f1f2b-b9a0-4199-b026-410ae5d32fd0	ru	geography	География	\N	t	\N	109
770	a0c57af5-a57c-4a21-825f-5f64d0f104e8	ru	Шаблон: Человек (персона)	Шаблон для Шаблон: Человек (персона)	\N	t	\N	112
771	cf7ee646-99ca-4d12-9b58-8859b9771de6	ru	Шаблон: Альбом	Шаблон для Шаблон: Альбом	\N	t	\N	113
772	e09b6c18-7e5b-4a6b-8653-584f86c318d6	ru	Шаблон: Книга	Шаблон для Шаблон: Книга	\N	t	\N	114
773	09c95573-23ed-43ae-9b4c-a39d10c30e7c	ru	Шаблон: Клип		\N	t	\N	115
774	138b1eb4-bcb4-46c8-a608-80ae65c59654	ru	Шаблон: Человек (персона)	Шаблон для Шаблон: Человек (персона)	\N	t	\N	116
775	cddfb16e-fd93-45b8-93de-afcb0a09bc02	ru	Шаблон: Фильм	Шаблон для Шаблон: Фильм	\N	t	\N	117
776	9ce79308-04cf-4d9b-849c-5abadca3a604	ru	Шаблон: Человек (персона)	Шаблон для Шаблон: Человек (персона)	\N	t	\N	118
777	85a3fcf9-5269-45db-9635-6e28e3ebf5be	ru	Шаблон: Песня	Шаблон для Шаблон: Песня	\N	t	\N	119
778	152a73bb-f373-465c-80d5-399208c86fc5	ru	Шаблон: Человек (персона)	Шаблон для Шаблон: Человек (персона)	\N	t	\N	120
779	14c04917-f468-4f95-a512-a8645ac910bb	ru	Шаблон: Статья	Шаблон для Шаблон: Статья	\N	t	\N	121
780	4b061c8b-e244-41ce-9d09-e2f2da50521c	ru	Шаблон: Человек (персона)	Шаблон для Шаблон: Человек (персона)	\N	t	\N	122
781	5f4607e5-7201-4db5-9815-0097a92c5960	ru	Шаблон: Классификатор	Шаблон для Шаблон: Классификатор	\N	t	\N	123
782	2f6881f2-7199-4f36-8df7-e72442e331a7	ru	Шаблон: Концепция	Шаблон для Шаблон: Концепция	\N	t	\N	124
783	ff738162-46d2-4729-b625-13fb9e4a74b9	ru	Шаблон: Файл	Шаблон для Шаблон: Файл	\N	t	\N	125
784	8be3db4d-998a-407e-abbf-80c80d4bfb34	ru	Шаблон: Жанр	Шаблон для Шаблон: Жанр	\N	t	\N	126
785	8dbad62b-b97d-4b4d-9daa-2035ad88e8af	ru	Шаблон: Человек (персона)	Шаблон для Шаблон: Человек (персона)	\N	t	\N	127
786	38b8568b-f382-4b4d-b3bf-67285bd3f8df	ru	Шаблон: Движение	Шаблон для Шаблон: Движение	\N	t	\N	128
787	29a3fbd3-ef9c-4005-92a3-ffcd69b8750a	ru	Шаблон: Фото	Шаблон для Шаблон: Фото	\N	t	\N	129
788	2f24423f-b243-4349-b141-d742e7760df9	ru	Шаблон: Предмет	Шаблон для Шаблон: Предмет	\N	t	\N	130
789	a5c1e6af-ddbf-4f1c-814a-af4d72355b98	ru	Изображение	Изображения	\N	t	\N	131
790	e3a539f8-2616-48ef-9b6c-91d4e7d7fd98	ru	Шаблон: Поле	Отображение поля реестра	\N	t	\N	132
791	e9f2746c-654d-40c6-8889-d2644b716ed2	ru	Шаблон: Модель онтологии	Отображение онтологической модели	\N	t	\N	133
792	661a1a34-cabe-4d19-a233-1d615919a52d	ru	Шаблон: Шаблон онтологии	Отображение шаблона онтологии	\N	t	\N	134
793	7a309616-4834-46b7-bcdc-ba5b4bc518aa	ru	Шаблон: Животное	Шаблон для Шаблон: Животное	\N	t	\N	135
794	bae1f4a5-c622-4136-8f95-8e25917db03e	ru	Шаблон: Химический элемент	Шаблон для Шаблон: Химический элемент	\N	t	\N	136
795	00acc2db-82e9-4955-8c81-cfd4afeff149	ru	Шаблон: Явление	Шаблон для Шаблон: Явление	\N	t	\N	137
796	54ee9c51-8f8c-4811-a102-4ae1c591acfe	ru	Шаблон: Растение	Шаблон для Шаблон: Растение	\N	t	\N	138
797	26e0e57e-5d11-4a9d-80d5-f098bc5c3032	ru	Шаблон: Человек (персона)	Шаблон для Шаблон: Человек (персона)	\N	t	\N	139
798	0c3967e8-9189-40c0-bfc0-68682ddb648b	ru	Шаблон: Эпоха	Шаблон для Шаблон: Эпоха	\N	t	\N	140
799	68384b8c-39fa-4923-8c43-c2922b468d31	ru	Шаблон: Место	Шаблон для Шаблон: Место	\N	t	\N	141
803	675126c2-ba40-42d8-a669-087c992e5066	ru	Интерстеллар (TMDB Test)	Тестовый фильм из TMDB	\N	t	a1000000-0000-0000-0000-000000000001	142
804	675126c2-ba40-42d8-a669-087c992e5066	en	Interstellar	\N	\N	f	\N	142
133	687e7c72-2f0a-46c2-8dec-9762d182a87f	ru	Интерстеллар	Тест	\N	t	a1000000-0000-0000-0000-000000000001	1
65	d0000001-0000-0000-0000-000000000003	ru	Интерстеллар	Когда засуха, пыльные бури и вымирание растений приводят человечество к продовольственному кризису, коллектив исследователей и учёных отправляется сквозь червоточину в путешествие, чтобы превзойти прежние ограничения для космических путешествий человека и найти планету с подходящими для человечества условиями.	\N	t	\N	1
67	d0000001-0000-0000-0000-000000000004	ru	Бойцовский клуб	Сотрудник страховой компании страдает хронической бессонницей и отчаянно пытается вырваться из мучительно скучной жизни. Однажды в очередной командировке он встречает некоего Тайлера Дёрдена — харизматического торговца мылом с извращенной философией. Тайлер уверен, что самосовершенствование — удел слабых, а единственное, ради чего стоит жить, — саморазрушение.\r\n Проходит немного времени, и вот уже новые друзья лупят друг друга почем зря на стоянке перед баром, и очищающий мордобой доставляет им высшее блаженство. Приобщая других мужчин к простым радостям физической жестокости, они основывают тайный Бойцовский клуб, который начинает пользоваться невероятной популярностью.	\N	t	\N	1
805	316f401b-37b5-4928-bc24-4d8298e6eb73	ru	Тест	Описание	\N	t	a1000000-0000-0000-0000-000000000001	143
806	316f401b-37b5-4928-bc24-4d8298e6eb73	en	Test	\N	\N	f	\N	143
807	88d8fb43-a635-4880-ae5a-a2f966d35191	ru	Бойцовский клуб	Тест TMDB	\N	t	a1000000-0000-0000-0000-000000000001	144
808	88d8fb43-a635-4880-ae5a-a2f966d35191	en	Fight Club	\N	\N	f	\N	144
846	2519866a-6643-448a-b7d3-b715460f00b2	ru	Джоанна Кэссиди	\N	\N	t	a1000000-0000-0000-0000-000000000001	149
847	272384e9-863b-4c5c-9173-5a33e916b463	ru	Джеймс Хонг	\N	\N	t	a1000000-0000-0000-0000-000000000001	149
848	83465a83-d6cc-490d-8eb7-2ff76c09db26	ru	Морган Полл	\N	\N	t	a1000000-0000-0000-0000-000000000001	149
1	d0000001-0000-0000-0000-000000000001	ru	Матрица	Жизнь Томаса Андерсона разделена на две части: днём он — самый обычный офисный работник, получающий нагоняи от начальства, а ночью превращается в хакера по имени Нео, и нет места в сети, куда он бы не смог проникнуть. Но однажды всё меняется. Томас узнаёт ужасающую правду о реальности.	\N	t	\N	1
809	ae4f652d-0f13-4bf5-9e56-91e094533563	ru	Зверополис	Добро пожаловать в Зверополис - современный город, населённый самыми разными животными, от огромных слонов до крошечных мышек. В город приезжает новый офицер полиции, крольчиха Джуди Хоппс, которая с 1-ых дней работы понимает, как сложно быть маленькой и пушистой среди больших и сильных полицейских. Судьба сводит её с хитроватым, но обаятельным лисом Ником Уайлдом. Вместе они берутся за расследование загадочного дела о пропавших животных, которое оказывается гораздо масштабнее и опаснее, чем казалось сначала.	\N	t	a1000000-0000-0000-0000-000000000001	145
810	ae4f652d-0f13-4bf5-9e56-91e094533563	en	Zootopia	\N	\N	f	\N	145
811	3c62b9a7-7089-4dac-93ec-4a2ddecb2e96	ru	Киану Ривз	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
812	4a97d9d9-9fe6-4acf-96ad-2eb1eb2fc8ec	ru	Лоренс Фишбёрн	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
813	eba3b8f1-7030-4030-b081-7cbc1188f5c0	ru	Кэрри-Энн Мосс	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
814	40c5f5cc-2e35-4dfb-a752-594660f1b481	ru	Хьюго Уивинг	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
815	ff901aa3-31ac-4e8d-ba94-3765066ffb64	ru	Глория Фостер	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
816	c1f10e6f-a57f-41b2-98b4-2cb40142f4fa	ru	Джо Пантолиано	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
817	57bce17e-0ba5-455d-bc66-9351a10d7094	ru	Маркус Чонг	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
818	c3f22c49-3287-429b-bf3e-8e17987bc06c	ru	Джулиан Араханга	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
819	42a03e22-8ac3-4dbc-a084-9dd54dbd8dea	ru	Мэтт Доран	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
820	12d77665-1267-491a-a8ee-2d3fe2910980	ru	Белинда МакКлори	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
821	02c2a15e-b864-4c1c-bfb5-e315b4ef5582	ru	Энтони Рэй Паркер	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
822	8040279c-cfa4-46ba-84e7-ccbe4508468c	ru	Пол Годдард	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
823	859bbc34-a13f-44e0-9b68-98b77af590e4	ru	Роберт Тейлор	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
824	a419fe53-6f2e-4b32-b8dc-3aef96e52b47	ru	Дэвид Астон	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
825	07d68dbe-bec6-4dc0-af9d-430408143885	ru	Марк Аден Грей	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
826	9a49ab7f-8491-4f7b-b502-870b5e770c59	ru	Ларри Вачовски	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
827	d5837aa3-c87e-4b54-be6b-8fd1a85cd5f2	ru	Энди Вачовски	\N	\N	t	a1000000-0000-0000-0000-000000000001	146
828	14299d64-b42e-4da1-a332-17044d038483	ru	Моана	Действие происходит 2000 лет назад, в островах Тихого океана. Дочка вождя, 14-летняя мечтательница Моана Ваялики, чтобы найти свою семью, отправляется в путешествие по океану в поисках сказочного острова с её героем полубогом-трикстером Мауи, и вместе им предстоит переплыть океан, встречая по пути огромных морских существ.	\N	t	a1000000-0000-0000-0000-000000000001	147
829	14299d64-b42e-4da1-a332-17044d038483	en	Moana	\N	\N	f	\N	147
69	d0000001-0000-0000-0000-000000000005	ru	Бегущий по лезвию	Ноябрь 2019 года. Бывший охотник на андроидов Рик Декард восстановлен в полиции Лос-Анджелеса для поиска возглавляемой Роем Батти группы репликантов, совершившей побег из космической колонии на Землю. В полиции считают, что андроиды пытаются встретиться с Эндолом Тайреллом - руководителем корпорации, которая разрабатывает кибернетический интеллект. Декард получает задание выяснить мотивы репликантов и уничтожить их.	\N	t	\N	1
830	485dee97-cde2-4603-8aa3-1b9364a5cbb1	ru	Чокнутый профессор (Коллекция)2	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
831	ce6d5b1a-8536-4823-88c3-6d077da6c23c	ru	Чокнутый профессор (Коллекция)	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
832	c42af2c3-8bff-431d-84aa-31fee4e37dba	ru	Легенда о Ло Сяохэе2	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
833	9559dcd0-3ee8-4941-ac8e-65bde4b2e705	ru	Легенда о Ло Сяохэе	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
834	b56aeff9-0ebd-4687-b5f3-c7bdd8efa1a6	ru	4.Комнаты	\N	\N	t	a1000000-0000-0000-0000-000000000001	1
835	2dc022f2-ce9a-4460-961f-b0eb14940557	ru	Спаун	«Краповый берет» Эл Симмонс убит своим начальником во время выполнения очередной миссии. Попав в чистилище, он заключает сделку с Дьяволом. Сатана дает ему силу, доспехи и оружие.В обмен на то, чтобы еще раз увидеть свою жену, Симмонс должен предварить приход сил Зла на Землю. Оказавшись на свободе, он разрывает контракт в одностороннем порядке…	\N	t	a1000000-0000-0000-0000-000000000001	148
836	2dc022f2-ce9a-4460-961f-b0eb14940557	en	Spawn	\N	\N	f	\N	148
751	1ecd1e93-4eef-4ecb-9ff5-b77c1c4211c3	ru	моана		\N	t	a1000000-0000-0000-0000-000000000001	1
837	81fc4a44-8440-495a-ab10-9071e01b03f2	ru	Харрисон Форд	\N	\N	t	a1000000-0000-0000-0000-000000000001	149
838	539e17de-4a18-4fb7-9f60-1a67eb6d7342	ru	Рутгер Хауэр	\N	\N	t	a1000000-0000-0000-0000-000000000001	149
839	379e665e-a13a-4f99-b4ae-ba6d68694f79	ru	Шон Янг	\N	\N	t	a1000000-0000-0000-0000-000000000001	149
840	3723a9d9-c419-4d93-8601-213fab20f209	ru	Эдвард Джеймс Олмос	\N	\N	t	a1000000-0000-0000-0000-000000000001	149
841	dd82c80c-57d6-47df-96b9-68725482a8f9	ru	М. Эммет Уолш	\N	\N	t	a1000000-0000-0000-0000-000000000001	149
842	84a7abd7-aeaf-44d7-accb-ab32916c05ef	ru	Дэрил Ханна	\N	\N	t	a1000000-0000-0000-0000-000000000001	149
843	678fb7a5-59ea-4f96-8e18-50a3512531f3	ru	Уильям Сэндерсон	\N	\N	t	a1000000-0000-0000-0000-000000000001	149
844	0aacbfa3-02c8-47ef-b65b-b31831c5e810	ru	Брайон Джеймс	\N	\N	t	a1000000-0000-0000-0000-000000000001	149
845	da777e99-1053-4964-91ed-dd50b1ec472b	ru	Джо Тёркел	\N	\N	t	a1000000-0000-0000-0000-000000000001	149
849	3c9f167e-c3e6-4c90-b685-0c5c4140ef4a	ru	Кевин Томпсон	\N	\N	t	a1000000-0000-0000-0000-000000000001	149
850	563aa5cc-fdff-4ce9-9286-51ccac80df1c	ru	Джон Эдвард Аллен	\N	\N	t	a1000000-0000-0000-0000-000000000001	149
851	e73db3a3-7d24-448a-8dc3-a0372ee8d227	ru	Хай Пайк	\N	\N	t	a1000000-0000-0000-0000-000000000001	149
852	98c7bf0d-8906-4a15-8dc5-d93344cf713a	ru	Ридли Скотт	\N	\N	t	a1000000-0000-0000-0000-000000000001	149
853	705601a6-39ee-4e1f-b770-a13b33e90b7c	ru	Шрэк	Жил да был в сказочном государстве большой зелёный великан по имени Шрэк. Жил он в гордом одиночестве в лесу, на болоте, которое считал своим. Но однажды злобный коротышка - лорд Фаркуад, правитель волшебного королевства, безжалостно согнал на болото всех сказочных обитателей. И беспечной жизни зелёного тролля пришёл конец. Но лорд Фаркуад пообещал вернуть Шрэку болото, если великан добудет ему прекрасную принцессу Фиону , которая томится в неприступной башне, охраняемой огнедышащим драконом...	\N	t	a1000000-0000-0000-0000-000000000001	150
854	705601a6-39ee-4e1f-b770-a13b33e90b7c	en	Shrek	\N	\N	f	\N	150
855	2f182f95-9d5f-49a8-bf3c-7e859d73dcde	ru	Майк Майерс	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
856	06b10f9f-ebff-49ea-a556-a2add917fd87	ru	Эдди Мёрфи	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
857	aead556f-5a34-467c-b9f2-0ad48b737a18	ru	Кэмерон Диас	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
858	9a98109b-27bc-480f-a64a-54b4447e7c9b	ru	Джон Литгоу	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
859	689de5a6-5552-4753-8ee3-cf2e07504d06	ru	Венсан Кассель	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
860	ad7566fb-15e1-42b2-a666-336325036d7b	ru	Питер Деннис	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
861	0855aa2a-2de9-4164-8461-60001c848184	ru	Клайв Пирс	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
862	1a134efa-d413-46ea-8447-b49b1a68a2da	ru	Джим Каммингс	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
863	f73c9001-eb85-437b-83e1-0f6d280db498	ru	Бобби Блок	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
864	b545556c-bea5-42c9-bc07-5dee10fe9904	ru	Крис Миллер	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
865	8270ba47-9b11-42e4-8ffe-30f51e9f8626	ru	Коуди Камерон	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
866	fb527f7d-f74a-467c-9593-af47f5e12749	ru	Кэтлин Фримен	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
867	160fb1d4-716b-4ef7-9c90-10333879d806	ru	Michael Galasso	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
868	e033a044-0907-445a-bf36-862bfb0f6322	ru	Кристофер Найтс	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
869	6ec4fd76-0b26-4a32-9774-ac313ab191a7	ru	Саймон Дж. Смит	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
870	c83c06f0-a896-431a-b643-f0e67b0b4d11	ru	Эндрю Адамсон	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
871	b386e593-80d7-4129-b214-994ff319c9aa	ru	Vicky Jenson	\N	\N	t	a1000000-0000-0000-0000-000000000001	151
872	229c3096-e041-4990-b9a8-7d8e3e644362	ru	Шрэк 2	Шрэк и Фиона возвращаются после медового месяца и находят письмо от родителей Фионы с приглашением на ужин. Однако те не подозревают, что их дочь тоже стала огром! Вместе с Осликом счастливая пара отправляется в путешествие, полное неожиданностей, и попадает в круговорот событий, во время которых приобретает множество друзей…	\N	t	a1000000-0000-0000-0000-000000000001	152
873	229c3096-e041-4990-b9a8-7d8e3e644362	en	Shrek 2	\N	\N	f	\N	152
874	5ac853dd-6a1a-4d71-8774-578661c88632	ru	Джули Эндрюс	\N	\N	t	a1000000-0000-0000-0000-000000000001	153
875	66c1fc69-fac3-4800-a8e4-b439a25ce422	ru	Антонио Бандерас	\N	\N	t	a1000000-0000-0000-0000-000000000001	153
876	f49ff441-4222-4550-ac33-a270547cfd4d	ru	Джон Клиз	\N	\N	t	a1000000-0000-0000-0000-000000000001	153
877	11a99954-254a-4e7e-bd58-3608ad9d192b	ru	Руперт Эверетт	\N	\N	t	a1000000-0000-0000-0000-000000000001	153
878	5424ac10-6763-4503-bfd1-e0823933fee9	ru	Дженнифер Сондерс	\N	\N	t	a1000000-0000-0000-0000-000000000001	153
879	57b3dd72-a998-4438-a845-5ed8b837191e	ru	Арон Уорнер	\N	\N	t	a1000000-0000-0000-0000-000000000001	153
880	ec021e80-77ec-41fd-9871-de19afde613f	ru	Келли Эсбёри	\N	\N	t	a1000000-0000-0000-0000-000000000001	153
881	c7c27520-d78f-4443-8801-c723b1e9c02a	ru	Конрад Вернон	\N	\N	t	a1000000-0000-0000-0000-000000000001	153
882	259683c9-ad8e-410a-af06-331da98bf1e5	ru	Дэвид П. Смит	\N	\N	t	a1000000-0000-0000-0000-000000000001	153
883	40483f49-65b4-4a7b-bce7-555cd7474b4c	ru	Mark Moseley	\N	\N	t	a1000000-0000-0000-0000-000000000001	153
884	d9330950-bc06-49bc-aabc-2543652c0fa8	ru	Конрад Вернон	\N	\N	t	a1000000-0000-0000-0000-000000000001	153
885	56aa342d-fa35-4b84-96a4-75c8a4ec999e	ru	Келли Эсбёри	\N	\N	t	a1000000-0000-0000-0000-000000000001	153
901	ac29698a-8d3a-44d5-8720-40ce7c85787d	ru	Neo	\N	\N	t	a1000000-0000-0000-0000-000000000001	154
902	523a5c7b-d459-4d32-a647-d888d5f6f738	ru	Morpheus	\N	\N	t	a1000000-0000-0000-0000-000000000001	154
903	d830d8f3-593e-4195-9cbc-97c37653c14c	ru	Trinity	\N	\N	t	a1000000-0000-0000-0000-000000000001	154
904	90464e8a-fc3a-4576-bbdf-94c81971c321	ru	Agent Smith	\N	\N	t	a1000000-0000-0000-0000-000000000001	154
905	66528ea1-0831-4868-adab-f3588e2b964c	ru	Oracle	\N	\N	t	a1000000-0000-0000-0000-000000000001	154
906	d5f7dd2e-f165-4b1e-977e-6ab1ac54f5e2	ru	Cypher	\N	\N	t	a1000000-0000-0000-0000-000000000001	154
907	7becbb13-0dad-4669-8f9b-6b857799a05a	ru	Tank	\N	\N	t	a1000000-0000-0000-0000-000000000001	154
908	02ba8507-0771-481d-9a92-bdbad5658629	ru	Apoc	\N	\N	t	a1000000-0000-0000-0000-000000000001	154
909	3a647e68-82c5-4c8b-83f9-20faf8d51ec8	ru	Mouse	\N	\N	t	a1000000-0000-0000-0000-000000000001	154
910	d0b81c6a-4ada-4567-9f87-6e697c0d0efb	ru	Switch	\N	\N	t	a1000000-0000-0000-0000-000000000001	154
911	29c51f60-52c2-4e92-bf73-08c289059cf6	ru	Dozer	\N	\N	t	a1000000-0000-0000-0000-000000000001	154
914	6773e984-aa56-4c9c-99f1-deac1c967325	ru	Rhineheart	\N	\N	t	a1000000-0000-0000-0000-000000000001	154
915	a2b416c0-b4a3-4303-924a-87cbaeee7b38	ru	Choi	\N	\N	t	a1000000-0000-0000-0000-000000000001	154
916	883166fd-b28b-4e97-902d-e080991ef752	ru	Shrek (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	155
917	0983686f-848a-441c-8e62-1802e2522a20	ru	Donkey (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	155
918	7f82e79b-d981-497e-8b7a-3fa95630a433	ru	Princess Fiona (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	155
919	90fab262-c29e-4e2d-adea-5887ad1312f0	ru	Queen Lillian (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	155
920	470cd6bb-540a-4620-b8d0-45026599ce8c	ru	Puss in Boots (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	155
921	17b5a4fd-013e-4c64-a8e9-2e953f12efe1	ru	King Harold (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	155
922	6816830a-a41a-4397-8f04-75370ddf85fa	ru	Prince Charming (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	155
923	3f41d21f-8f62-4c5d-a8ff-823b0739f897	ru	Fairy Godmother (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	155
924	9a1bb389-8a7f-45a1-90c3-e9a9d5a9484b	ru	Wolf (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	155
925	e2cea8f1-7a08-4c03-b204-3ace121057cf	ru	Page / Elf / Nobleman / Nobleman's Son (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	155
926	5ed8f232-6eca-4033-bdee-725292684348	ru	Pinocchio / Three Pigs (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	155
927	6c187652-aa74-462a-8ce9-606af3e4ca49	ru	Gingerbread Man / Cedric / Announcer / Muffin Man / Mongo (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	155
928	bc7e0f85-a611-46f3-851b-5970a3ae369b	ru	Blind Mouse (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	155
929	4e8f67e3-57c9-4acb-a3c8-35063990f7e8	ru	Herald / Man with Box (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	155
930	dedb547a-ba06-4560-a1a1-44cd1eef2ac8	ru	Mirror / Dresser (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	155
931	243465dd-ea0f-47ba-a95b-8a82ea75df5e	ru	Shrek / Blind Mouse (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	156
932	d0c4d4f7-e5a9-4136-a98d-ce2523c56f52	ru	Donkey (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	156
933	344bb824-8999-4300-908a-4fd54cbf0ea6	ru	Princess Fiona (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	156
934	933317ac-7ab5-4847-97b1-ab27f87c8175	ru	Lord Farquaad (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	156
935	d5656cb6-1892-4b2f-ad26-9ab8d7b9b36f	ru	Monsieur Hood (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	156
936	29891216-e6a1-49fb-89f7-1402edf76d15	ru	Ogre Hunter (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	156
937	3240c58a-d7b5-469c-96a5-5238a42a0106	ru	Ogre Hunter (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	156
938	adaedd26-2341-410c-9568-7420219b5c9b	ru	Captain of the Guards (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	156
939	9ed7d6a4-9cfe-42de-8463-24af8f242f8a	ru	Baby Bear (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	156
940	e1d73f3b-dc6b-4f88-b42c-3ca16ded87f1	ru	Geppetto / Magic Mirror (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	156
941	ba7d4a8b-36e3-470c-a2a4-9c01bda0ad73	ru	Pinnochio / Three Pigs (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	156
942	06b01798-92f4-4cbc-97cf-9b4206bb71a6	ru	Old Woman  (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	156
943	83043a41-8c2a-49e9-ac00-bfa18d7496db	ru	Peter Pan (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	156
944	0ec21891-3421-4a67-b856-565fa413210f	ru	Blind Mouse / Thelonious (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	156
945	e2886d37-3d47-448d-a873-a88f9ee476a5	ru	Blind Mouse (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	156
946	b1bc0591-73b3-4ce3-b2a6-46167d7c781b	ru	Шаблон: Персонаж	Персонаж фильма	\N	t	a1000000-0000-0000-0000-000000000001	4
912	b5f0c24d-a156-478a-aecc-e36a066571e8	ru	Agent Brown		\N	t	a1000000-0000-0000-0000-000000000001	154
913	9ecebfcf-5ac0-4bd9-87fb-4c94eee5a7e0	ru	Agent Jones		\N	t	a1000000-0000-0000-0000-000000000001	154
949	4d51480b-62d4-4e80-9e0d-788e06b9de9e	ru	Джиннифер Гудвин	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
950	89253a08-ed05-452e-966f-d7b8115fbf03	ru	Judy Hopps (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
951	de7a2e08-de57-4c26-918b-0bc5c175760e	ru	Джейсон Бейтман	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
952	39134944-dfa8-4c1b-ba5a-887b0125c67c	ru	Nick Wilde (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
953	e7c2c4d3-cc9c-4a7e-bda0-c5a7208c2d76	ru	Идрис Эльба	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
954	8c418373-1974-4784-8fa4-ddd8d6847cdb	ru	Chief Bogo (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
955	4d282837-83a7-4203-88e6-4d4a7b00c624	ru	Дженни Слейт	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
956	758a85b5-ecd8-4c74-a4ec-571fe809c89d	ru	Bellwether (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
957	4b0bed58-440b-420e-ac2c-fd232ae80222	ru	Нэйт Торренс	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
958	6967b660-ee0c-4349-be84-c4a141974b91	ru	Clawhauser (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
959	3c62d619-d614-464c-9e6a-bf5af782d2e5	ru	Бонни Хант	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
960	baee7a49-84af-4574-a6ed-519ef8ec16d0	ru	Bonnie Hopps (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
961	768b0ca6-cd5e-421f-b1fc-37ebdf55525a	ru	Дон Лейк	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
962	336c833e-2a5d-4d89-84a5-bd439126cc41	ru	Stu Hopps (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
963	1ebc284d-9509-449e-82a9-11fbafa60126	ru	Томми Чонг	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
964	d25ceccc-8274-4b2f-a178-f3b87acbaa28	ru	Yax (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
965	28a1a6b1-1903-44a2-9e92-bb6c30ce17ad	ru	Джей Кей Симмонс	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
966	c5b29f37-2299-49b4-b42b-1891b9650e4a	ru	Mayor Lionheart (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
967	ec1e4fa0-b379-40d7-a304-53f121c7dcd1	ru	Октавия Спенсер	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
968	4aa2b2e2-0ba4-4a21-a2c3-ea96cad84fee	ru	Mrs. Otterton (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
969	2c7cae86-9da7-4161-a1dc-c61585ef73e9	ru	Алан Тьюдик	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
970	3db35cb3-700b-47e7-b923-e1e32b83bb2f	ru	Duke Weaselton (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
971	37beaa06-448e-41c1-a19b-9b90bbc5a8e2	ru	Шакира	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
972	bd7dfea1-7379-4774-9654-46ea90f5ed81	ru	Gazelle (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
973	b6e7c077-56e0-4156-88e6-05a2a6ddd2d8	ru	Рэймонд С. Перси	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
974	b56cffab-b7e8-4f68-9a91-db0e683e1232	ru	Flash (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
975	aa1a3294-70ac-4c96-99fc-160aae00c0d1	ru	Della Saba	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
976	765237cf-fbcd-4b5b-9a34-4ea0f51ea5ce	ru	Young Hopps (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
977	7d6ecb14-1cd7-41e1-8594-60efb56b832d	ru	Морис Ламарш	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
978	35b08f2f-cf9f-4af4-ba8d-6c7ee122b062	ru	Mr. Big (voice)	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
979	2c52c7a0-b375-40a7-89fb-7aa37e426655	ru	Байрон Ховард	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
980	98f27997-e5e8-47b6-93de-a2da4cda2af3	ru	Рич Мур	\N	\N	t	a1000000-0000-0000-0000-000000000001	157
137	a24f87f7-fdf0-4258-862c-c17b89acd938	ru	Криминальное чтиво	Пути двух наемных убийц, профессионального бойца, двух бандитов и жены гангстера пересекаются в этом закрученном кровавом путешествии по злачному центру Лос-Анджелеса.	\N	t	a1000000-0000-0000-0000-000000000001	1
981	87814d62-16a3-4e34-8dc0-03ec5a78f28d	ru	Джон Траволта	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
982	7c69de82-5026-43f1-a6c2-b43523920b15	ru	Vincent Vega	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
983	220e556b-14bd-48d3-9360-96018d7ac784	ru	Сэмюэл Л. Джексон	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
984	d1a6f8bc-0d39-4a37-8a58-d9f44bb87212	ru	Jules Winnfield	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
985	59fd53ef-6ef3-4881-9773-9a6db97ae7d8	ru	Ума Турман	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
986	be680376-546c-4896-aee1-b567e094396f	ru	Mia Wallace	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
987	a77e6546-5b15-4eb5-a847-7a3db999431b	ru	Брюс Уиллис	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
988	f8082a95-3a70-4103-a9ca-615731d702fe	ru	Butch Coolidge	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
989	54c31fa7-0f61-4967-8057-1acde78186c7	ru	Винг Реймз	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
990	c8d15721-a419-4cab-9bfc-b6e7249c77bb	ru	Marsellus Wallace	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
991	e09eeed4-6e9e-4ce5-a66b-3b62e9884d23	ru	Харви Кейтель	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
992	e12285f3-076b-473e-82ff-e7a8517d49ac	ru	The Wolf	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
993	fd2725fe-9094-4e29-91a4-afdfe3877e4c	ru	Эрик Штольц	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
994	ce98a882-8980-43eb-9995-019b022df28a	ru	Lance	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
995	d631016e-2a42-42af-95a8-a225eb96a473	ru	Тим Рот	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
996	60a01a47-e33f-48ec-929b-dbe3da458d08	ru	Pumpkin	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
997	86e86f24-6bda-490f-88e6-ba92c365dbd0	ru	Аманда Пламмер	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
998	b97431db-599d-4e5f-be33-19c579f1b942	ru	Honey Bunny	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
999	ad618e1d-d36b-4937-8037-515d6fad866c	ru	Мария де Медейруш	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
1000	35476ee0-ad26-4c7d-9d7d-e82f46d5b1cb	ru	Fabienne	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
1001	d99db646-f219-44f4-8ff2-387ba5ceddb6	ru	Квентин Тарантино	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
1002	7df1ed35-88e8-490e-a5dc-7791684c1cde	ru	Jimmie Dimmick	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
1003	da298a62-6ff0-43b8-b9ad-008800d934b4	ru	Кристофер Уокен	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
1004	0d569910-8953-486f-85c4-3540d8efc979	ru	Captain Koons	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
1005	adb70f3f-257f-4b66-beea-2d0ff3142eea	ru	Розанна Аркетт	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
1006	d870f544-ea59-412e-868d-8f1281cbad95	ru	Jody	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
1007	d295ce90-1f32-463b-9a7d-cb77d4ba8fe9	ru	Питер Грин	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
1008	42fb105e-da54-46c4-9612-325bb33f4512	ru	Zed	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
1009	e248cb29-34df-4aa2-bc9a-7ad069d9b043	ru	Дуан Уайтакер	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
1010	fd29096b-43b9-4e34-9f08-caeabc31b545	ru	Maynard	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
1011	2fe65b14-7a7f-4c13-868c-115bf8430f0a	ru	Квентин Тарантино	\N	\N	t	a1000000-0000-0000-0000-000000000001	158
\.


--
-- Data for Name: entity_projection; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.entity_projection (projection_id, entity_id, model_id, template_id, context_id, projection_code, projection_name, confidence, created_at, valid_from, valid_to, version_id) FROM stdin;
e0000013-0000-0000-0000-000000000002	d0000013-0000-0000-0000-000000000002	801d5718-54ec-44c7-85da-af53af4d7acc	3d22c910-caff-462e-bc8f-f156bc5479eb	\N	democracy-concept	Concept Data	0.8500	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000013-0000-0000-0000-000000000001	d0000013-0000-0000-0000-000000000001	801d5718-54ec-44c7-85da-af53af4d7acc	3d22c910-caff-462e-bc8f-f156bc5479eb	\N	cyberpunk-concept	Concept Data	0.8500	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000014-0000-0000-0000-000000000002	d0000014-0000-0000-0000-000000000002	801d5718-54ec-44c7-85da-af53af4d7acc	cf6dc12e-5888-4bce-8ee6-7ff442c338cd	\N	classical-genre	Genre Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000014-0000-0000-0000-000000000001	d0000014-0000-0000-0000-000000000001	801d5718-54ec-44c7-85da-af53af4d7acc	cf6dc12e-5888-4bce-8ee6-7ff442c338cd	\N	scifi-genre	Genre Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
f0000001-0000-0000-0000-000000000005	d0000001-0000-0000-0000-000000000005	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	\N	bladerunner2049-cinema	Cinema Data	0.9500	2026-07-18 09:57:12.860823+00	2026-07-18 09:57:12.860823+00	\N	1
f0000001-0000-0000-0000-000000000004	d0000001-0000-0000-0000-000000000004	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	\N	fight-club-cinema	Cinema Data	0.9500	2026-07-18 09:57:12.860823+00	2026-07-18 09:57:12.860823+00	\N	1
f0000001-0000-0000-0000-000000000003	d0000001-0000-0000-0000-000000000003	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	\N	interstellar-cinema	Cinema Data	0.9500	2026-07-18 09:57:12.860823+00	2026-07-18 09:57:12.860823+00	\N	1
e0000001-0000-0000-0000-000000000002	d0000001-0000-0000-0000-000000000002	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	\N	inception-cinema	Cinema Data	0.9500	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000001-0000-0000-0000-000000000001	d0000001-0000-0000-0000-000000000001	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	\N	matrix-cinema	Cinema Data	0.9500	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
f0000002-0000-0000-0000-000000000005	d0000002-0000-0000-0000-000000000005	801d5718-54ec-44c7-85da-af53af4d7acc	25155646-3c08-4147-9019-754e9967a655	\N	ryan-gosling-data	Actor Data	0.9000	2026-07-18 09:57:12.870597+00	2026-07-18 09:57:12.870597+00	\N	1
f0000002-0000-0000-0000-000000000004	d0000002-0000-0000-0000-000000000004	801d5718-54ec-44c7-85da-af53af4d7acc	25155646-3c08-4147-9019-754e9967a655	\N	scarlett-johansson-data	Actor Data	0.9000	2026-07-18 09:57:12.870597+00	2026-07-18 09:57:12.870597+00	\N	1
f0000002-0000-0000-0000-000000000003	d0000002-0000-0000-0000-000000000003	801d5718-54ec-44c7-85da-af53af4d7acc	25155646-3c08-4147-9019-754e9967a655	\N	matt-damon-data	Actor Data	0.9000	2026-07-18 09:57:12.870597+00	2026-07-18 09:57:12.870597+00	\N	1
e0000002-0000-0000-0000-000000000002	d0000002-0000-0000-0000-000000000002	801d5718-54ec-44c7-85da-af53af4d7acc	25155646-3c08-4147-9019-754e9967a655	\N	leonardo-dicaprio-data	Actor Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000002-0000-0000-0000-000000000001	d0000002-0000-0000-0000-000000000001	801d5718-54ec-44c7-85da-af53af4d7acc	25155646-3c08-4147-9019-754e9967a655	\N	keanu-reeves-data	Actor Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
f0000003-0000-0000-0000-000000000005	d0000003-0000-0000-0000-000000000005	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	\N	scott-cinema	Director Data	0.9000	2026-07-18 09:57:12.878491+00	2026-07-18 09:57:12.878491+00	\N	1
f0000003-0000-0000-0000-000000000004	d0000003-0000-0000-0000-000000000004	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	\N	villeneuve-cinema	Director Data	0.9000	2026-07-18 09:57:12.878491+00	2026-07-18 09:57:12.878491+00	\N	1
f0000003-0000-0000-0000-000000000003	d0000003-0000-0000-0000-000000000003	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	\N	fincher-cinema	Director Data	0.9000	2026-07-18 09:57:12.878491+00	2026-07-18 09:57:12.878491+00	\N	1
e0000003-0000-0000-0000-000000000002	d0000003-0000-0000-0000-000000000002	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	\N	nolan-cinema	Director Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000003-0000-0000-0000-000000000001	d0000003-0000-0000-0000-000000000001	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	\N	wachowskis-cinema	Director Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000004-0000-0000-0000-000000000002	d0000004-0000-0000-0000-000000000002	102715a7-994b-46fe-87cf-9a21487d74cd	fcf60464-178c-4b0e-b2a7-939f31f46ba9	\N	bohemian-rhapsody-music	Music Data	0.9500	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000004-0000-0000-0000-000000000001	d0000004-0000-0000-0000-000000000001	102715a7-994b-46fe-87cf-9a21487d74cd	fcf60464-178c-4b0e-b2a7-939f31f46ba9	\N	blue-danube-music	Music Data	0.9500	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000005-0000-0000-0000-000000000002	d0000005-0000-0000-0000-000000000002	102715a7-994b-46fe-87cf-9a21487d74cd	0c2ec0ab-ae2d-4cca-84cc-432cd0dd1256	\N	freddie-mercury-music	Musician Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000005-0000-0000-0000-000000000001	d0000005-0000-0000-0000-000000000001	102715a7-994b-46fe-87cf-9a21487d74cd	0c2ec0ab-ae2d-4cca-84cc-432cd0dd1256	\N	johann-strauss-music	Musician Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000007-0000-0000-0000-000000000002	d0000007-0000-0000-0000-000000000002	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	\N	dune-lit	Literature Data	0.9500	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000007-0000-0000-0000-000000000001	d0000007-0000-0000-0000-000000000001	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	\N	neuromancer-lit	Literature Data	0.9500	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
4eb56695-d7c0-4e1f-bfe5-1575009b206f	e66174d9-06a6-4caa-b896-e954d5087cbb	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_imdb_id_proj	IMDb ID	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	2
b4c7a177-eeb8-43f4-ad57-f29e2fd7c8d6	a906d913-ac95-45b0-adc2-e4b08fcec21a	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_tmdb_id_proj	TMDb ID	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	3
6c45baac-b8fe-4357-90c2-aaa236e0b3ff	6af186bf-565b-4ca4-8799-5c309a61ea53	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_runtime_proj	Хронометраж	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	4
f99a57df-602b-473d-8660-d528c1055de9	69776eb8-9425-46fa-b3ad-f1b535135200	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_mpaa_rating_proj	Рейтинг MPAA	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	5
79f5b8b8-bafe-408a-98f9-cd7052d2fabf	fca7cd62-58d0-4103-9ac9-916b13fa9d23	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_budget_proj	Бюджет	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	6
d388777c-7f10-433c-83c2-6bf149ab177e	306287a6-1851-4701-841c-43b37eba32c2	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_revenue_proj	Сборы	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	7
498db061-e8a6-44b0-a3ff-cdfd55757832	0c26ec5b-2ee8-4642-bf05-b508dbb3ddac	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_filming_locations_proj	Места съёмок	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	8
dff416d6-31f3-40fe-93d7-901a1d6188ab	859820dc-0724-47ce-8ede-8c7d12746963	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_production_companies_proj	Продюсерские компании	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	9
c868074c-92b7-4184-95a1-96585f8513b2	7668d04a-c745-4083-8b6a-9d96cdb7a697	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_tagline_proj	Слоган	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	10
35d9f784-37ad-4148-8149-1a8afd70edee	0fdf2cca-af55-44bf-a5c6-4668d35356a0	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_vote_count_proj	Количество голосов	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	11
1bfdba75-8ff4-438c-8031-fd2c458b8a3a	fc44eac6-8287-4f98-8ec1-ab2ba860b44f	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_production_company_proj	Кинокомпания	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	12
e1564c6f-9a14-49a0-b61e-ed95fa7e4dd9	29028900-dfc9-4cd7-9281-cd5a37f88d9f	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_title_proj	Название	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	13
a5712116-0fdf-463d-9675-bf679e839352	4557e26d-735b-4518-9ea4-8fce83d419ec	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_description_proj	Описание	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	14
64fc8024-97f7-4a32-bf84-92b4a3bee934	51395a55-5bcd-4ae0-b2ca-275dcbaf03fa	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_year_proj	Год	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	15
ffd77371-9d39-4909-bf65-14171c5abc6c	87d78c11-7ba0-415c-9e72-b1863da3ca41	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_genre_proj	Жанр	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	16
3ec191f4-cee3-4919-a021-167edf689348	52d3d0e2-7233-4312-904c-158bc3408aa1	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_rating_proj	Рейтинг	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	17
3ac2c5f6-98d9-48a9-8316-ec9f2f70e099	a566d1b6-4b21-4ee3-a03b-fbf9d4b3c18d	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_country_proj	Страна	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	18
49565abd-66e6-4a5d-b319-56bab7f848be	cdd8873d-72d0-44e8-b12b-dda57fefae95	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_language_proj	Язык	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	19
1c0b5716-87c6-42bd-983e-9290ad79d498	fa0c8e75-4b32-4932-a25d-a41594e6284b	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_budget_mln_proj	Бюджет (млн)	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	20
a3ce4e41-b699-4f98-bb53-cc5a5406cfe0	0b81ab90-ce6e-4e5e-8372-7cedf8f1f0b0	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_duration_min_proj	Длительность (мин)	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	21
368b6797-b54d-4b3b-9412-f0ac9b38606c	e7f67fa4-8b5e-4a21-9ee7-1dfd016e0e79	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_author_proj	Автор	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	22
c52450a3-2125-4f32-aee7-3f2614d246c5	2db68426-d7fb-4558-85d6-2200c4be7483	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_pages_proj	Страниц	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	23
746fa4bd-4206-41bd-ba53-75cfd03fa958	e87f137c-0dd4-4ef1-bcab-90947f245310	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_isbn_proj	ISBN	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	24
1d1c2087-eb53-4bc8-b8f0-6d6068af521c	7c268ffe-390a-42f6-a295-3cbaf14bd4ed	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_release_date_proj	Дата выхода	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	25
394c57ea-7e84-493f-8f9c-71a0cedc8562	3a4da93c-0741-4717-a423-2e47c5ba8eab	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	8c3f9ad2-241e-4d66-9a50-2618621356b3	kartinko_tpl_my_image	картинко	1.0000	2026-07-18 14:55:53.69052+00	2026-07-18 14:55:53.690526+00	\N	2
2aa77654-e4d5-4c0e-b784-f4218ab1ad08	8083d83c-1095-4467-892b-73ab6f7b38a3	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_start_date_proj	Дата начала	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	26
f44d5d50-c3ec-4580-afb2-d2d4f8e065b5	2740d254-056a-4355-8bf6-e3f511053c7e	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_end_date_proj	Дата окончания	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	27
da2202c1-f92d-4b1d-9f1d-107467681c8f	f0a5ae18-416c-4cd0-8ce8-5eae3b62a46b	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_price_proj	Цена	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	28
94171a6b-9bd9-4a21-8f34-d53665f35e1e	7a445a3b-a359-4090-b87d-56a72d2561e9	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_website_proj	Сайт	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	29
0a3891a7-d156-42bb-a51a-de8cd941a934	16e0ab11-a890-4a0c-9ae5-e9760dc6caba	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_email_proj	Email	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	30
319c1053-85b1-4cd4-ac52-3d1cfad2f14d	cee359fa-0d72-4624-9686-33da0e0a42f1	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	inception_2010_cinema	Начало	1.0000	2026-07-18 09:57:20.639296+00	2026-07-18 09:57:20.639296+00	\N	1
52080fdd-65e3-423c-8257-0c593aaa1fe9	eaff2e3b-3670-497e-b6d7-ca54caa660ab	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	matrix_1999_cinema	Матрица	1.0000	2026-07-18 09:57:20.650291+00	2026-07-18 09:57:20.650291+00	\N	1
5a1ced1a-f8e9-4349-a667-17a9f6ac9569	687e7c72-2f0a-46c2-8dec-9762d182a87f	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	interstellar_2014_cinema	Интерстеллар	1.0000	2026-07-18 09:57:20.663544+00	2026-07-18 09:57:20.663544+00	\N	1
08814137-6dc0-4bc3-8c2c-8bf3b44f4f45	6df04304-28f0-4f16-a958-056f3b5230bb	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	fight_club_1999_cinema	Бойцовский клуб	1.0000	2026-07-18 09:57:20.673102+00	2026-07-18 09:57:20.673102+00	\N	1
9de1b51d-ec3a-420d-babb-382618847a99	a24f87f7-fdf0-4258-862c-c17b89acd938	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	pulp_fiction_1994_cinema	Криминальное чтиво	1.0000	2026-07-18 09:57:20.681998+00	2026-07-18 09:57:20.681998+00	\N	1
e257d136-d19d-4ea1-a583-249b9c6e207e	9526ade9-abd0-4076-be6f-6fd821f33aac	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	dark_knight_2008_cinema	Тёмный рыцарь	1.0000	2026-07-18 09:57:20.690942+00	2026-07-18 09:57:20.690942+00	\N	1
1d1c22c2-59ce-438c-ac2e-8f934ab4429a	eb63ed0d-6b3d-495d-97cf-055bdc585459	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	forrest_gump_1994_cinema	Форрест Гамп	1.0000	2026-07-18 09:57:20.699631+00	2026-07-18 09:57:20.699631+00	\N	1
5f42bfe9-f1ce-4c26-8437-9d2d5f8c4b52	b6bec71b-c05d-48df-8cde-7660d1a41d52	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	schindlers_list_1993_cinema	Список Шиндлера	1.0000	2026-07-18 09:57:20.708475+00	2026-07-18 09:57:20.708475+00	\N	1
fd597312-689e-4fd2-8fcd-82adbc984d61	85161a9a-6064-4b4b-baaf-1cf838c0b50e	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	django_2012_cinema	Джанго освобождённый	1.0000	2026-07-18 09:57:20.717643+00	2026-07-18 09:57:20.717643+00	\N	1
5412b37f-befe-4023-93e0-8a648ba208dd	fdfdc747-8641-4c4c-84ea-5f31960a9efe	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	shutter_island_2010_cinema	Остров проклятых	1.0000	2026-07-18 09:57:20.726901+00	2026-07-18 09:57:20.726901+00	\N	1
ddb3b8a3-4c5b-491f-86d4-f737bc84ed9c	f542950b-2fee-47b1-94bb-73c83609167f	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	8c3f9ad2-241e-4d66-9a50-2618621356b3	leonardo_dicaprio_cinema	Леонардо ДиКаприо	1.0000	2026-07-18 09:57:20.739276+00	2026-07-18 09:57:20.739276+00	\N	1
3b467fe5-fd04-4ae7-948c-e6964af03be6	848123f3-d2f3-4a5e-a992-add89081815f	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	8c3f9ad2-241e-4d66-9a50-2618621356b3	keanu_reeves_cinema	Киану Ривз	1.0000	2026-07-18 09:57:20.749847+00	2026-07-18 09:57:20.749847+00	\N	1
5ce768b7-b7db-498e-934d-898d7b25034c	dccfaaf8-42b5-46c7-a915-f6b7d5b05fa2	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	8c3f9ad2-241e-4d66-9a50-2618621356b3	matthew_mcconaughey_cinema	Мэттью Макконахи	1.0000	2026-07-18 09:57:20.76044+00	2026-07-18 09:57:20.76044+00	\N	1
e2d9d810-d021-446b-b17f-1a543aeeaee2	ff224547-159e-403e-bd43-359c53d15ba5	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	8c3f9ad2-241e-4d66-9a50-2618621356b3	brad_pitt_cinema	Брэд Питт	1.0000	2026-07-18 09:57:20.770959+00	2026-07-18 09:57:20.770959+00	\N	1
b586787c-1e27-4245-80ea-8d432335b049	66e7dda6-fc8a-4bae-b864-c54ae4962919	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	8c3f9ad2-241e-4d66-9a50-2618621356b3	john_travolta_cinema	Джон Траволта	1.0000	2026-07-18 09:57:20.78252+00	2026-07-18 09:57:20.78252+00	\N	1
8d288041-72b0-4256-97ab-92b53f4cb5fa	f16dc2ac-4b8a-42f9-a44a-12411e90008d	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	8c3f9ad2-241e-4d66-9a50-2618621356b3	tom_hardy_cinema	Том Харди	1.0000	2026-07-18 09:57:20.792986+00	2026-07-18 09:57:20.792986+00	\N	1
606e3eac-1206-4f2e-93cb-6ae5b7d27569	73e99bfb-2168-4669-8831-071c97c4e7e4	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	8c3f9ad2-241e-4d66-9a50-2618621356b3	tom_hanks_cinema	Том Хэнкс	1.0000	2026-07-18 09:57:20.801871+00	2026-07-18 09:57:20.801871+00	\N	1
c04f634b-0391-4181-9878-e6a1d0ffdcfc	96a28808-f001-49fd-8562-834a7f77db83	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	8c3f9ad2-241e-4d66-9a50-2618621356b3	liam_neeson_cinema	Лиам Нисон	1.0000	2026-07-18 09:57:20.810926+00	2026-07-18 09:57:20.810926+00	\N	1
8b4b0977-6964-4779-9ca6-569348e4d469	8c5def46-791c-4c04-b39f-21a975b5d3da	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	8c3f9ad2-241e-4d66-9a50-2618621356b3	jamie_fox_cinema	Джейми Фокс	1.0000	2026-07-18 09:57:20.823338+00	2026-07-18 09:57:20.823338+00	\N	1
f9004d4d-f01f-44c5-9154-26d37d4c9fe5	d3dbd8f2-19e2-4329-a383-d06fc61e04cc	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	8c3f9ad2-241e-4d66-9a50-2618621356b3	mark_ruffalo_cinema	Марк Руффало	1.0000	2026-07-18 09:57:20.835976+00	2026-07-18 09:57:20.835976+00	\N	1
ee053e8b-e27e-4e4a-b540-8b38a2387ad1	60d6257f-5730-4868-8733-b3d6a310f8a2	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	8c3f9ad2-241e-4d66-9a50-2618621356b3	christopher_nolan_cinema	Кристофер Нолан	1.0000	2026-07-18 09:57:20.850182+00	2026-07-18 09:57:20.850182+00	\N	1
5d337d5f-8b03-48b7-b8ee-2724a56f83a8	23180d0b-81b1-4384-9ba7-e27206bdff02	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	8c3f9ad2-241e-4d66-9a50-2618621356b3	wachowskis_cinema	Братья Вачовски	1.0000	2026-07-18 09:57:20.861258+00	2026-07-18 09:57:20.861258+00	\N	1
36d49335-bf9d-4ca5-b276-a3239a6eb129	c7d1a5fe-d2f5-4327-8a0e-01c571310078	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	8c3f9ad2-241e-4d66-9a50-2618621356b3	david_fincher_cinema	Дэвид Финчер	1.0000	2026-07-18 09:57:20.872163+00	2026-07-18 09:57:20.872163+00	\N	1
415f017c-ea76-4539-9e57-2790b05894dd	449fbd14-7ed0-4aaa-bacf-7811bd48dc5c	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	8c3f9ad2-241e-4d66-9a50-2618621356b3	quentin_tarantino_cinema	Квентин Тарантино	1.0000	2026-07-18 09:57:20.88529+00	2026-07-18 09:57:20.88529+00	\N	1
3da51058-ec94-4c29-aba1-148714af2ab6	4d7f0c0c-de03-499b-a268-695d49237a92	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	8c3f9ad2-241e-4d66-9a50-2618621356b3	steven_spielberg_cinema	Стивен Спилберг	1.0000	2026-07-18 09:57:20.897124+00	2026-07-18 09:57:20.897124+00	\N	1
a0284d60-b6bd-4517-9fb3-43ee06a3a263	1703d7f9-ceb7-4f11-bcd3-d85e1b86b55e	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	8c3f9ad2-241e-4d66-9a50-2618621356b3	martin_scorsese_cinema	Мартин Скорсезе	1.0000	2026-07-18 09:57:20.906535+00	2026-07-18 09:57:20.906535+00	\N	1
6738d301-3f2a-4d63-83f3-32d4d2db651f	f4ee8f84-d477-465b-ab1d-d2cc5335c3ba	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	8c3f9ad2-241e-4d66-9a50-2618621356b3	ridley_scott_cinema	Ридли Скотт	1.0000	2026-07-18 09:57:20.915074+00	2026-07-18 09:57:20.915074+00	\N	1
a601ee49-27ee-463f-9bd6-fdeacfd04490	769f85f2-f19e-41c6-b099-078dd11dee55	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	8c3f9ad2-241e-4d66-9a50-2618621356b3	stanley_kubrick_cinema	Стэнли Кубрик	1.0000	2026-07-18 09:57:20.923623+00	2026-07-18 09:57:20.923623+00	\N	1
2a0bb8db-5a49-4d0c-b855-2bc3f56cf205	4a672d0d-29bb-45f3-9ff9-90fd57017633	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	8c3f9ad2-241e-4d66-9a50-2618621356b3	frank_darabont_cinema	Фрэнк Дарабонт	1.0000	2026-07-18 09:57:20.935209+00	2026-07-18 09:57:20.935209+00	\N	1
cbd9198b-9b10-49d3-81a5-21092f2c0a68	dc070982-5f72-4bec-9bc1-aa6eff656900	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	8c3f9ad2-241e-4d66-9a50-2618621356b3	denis_villeneuve_cinema	Дени Вильнёв	1.0000	2026-07-18 09:57:20.946206+00	2026-07-18 09:57:20.946206+00	\N	1
e9c2c8ca-2975-40e9-9999-a105c29f82e2	1496117c-f07f-4c35-8fd2-5b44db1604fe	102715a7-994b-46fe-87cf-9a21487d74cd	fcf60464-178c-4b0e-b2a7-939f31f46ba9	8c3f9ad2-241e-4d66-9a50-2618621356b3	bohemian_rhapsody_music	Bohemian Rhapsody	1.0000	2026-07-18 09:57:20.95993+00	2026-07-18 09:57:20.95993+00	\N	1
5e2ad7ef-9e21-4e1f-af4e-45f953b9874e	0cf39fee-0df1-44c5-96a6-81b246c1b5d4	102715a7-994b-46fe-87cf-9a21487d74cd	fcf60464-178c-4b0e-b2a7-939f31f46ba9	8c3f9ad2-241e-4d66-9a50-2618621356b3	stairway_to_heaven_music	Stairway to Heaven	1.0000	2026-07-18 09:57:20.972914+00	2026-07-18 09:57:20.972914+00	\N	1
722de5f4-01ed-404a-803a-fdc438faeb27	49dd0902-ded3-452e-9cd7-3627778d8391	102715a7-994b-46fe-87cf-9a21487d74cd	fcf60464-178c-4b0e-b2a7-939f31f46ba9	8c3f9ad2-241e-4d66-9a50-2618621356b3	imagine_music	Imagine	1.0000	2026-07-18 09:57:20.985186+00	2026-07-18 09:57:20.985186+00	\N	1
00853e1e-98e4-4512-9e81-cefd3374bb5a	a64cda25-19b1-42a6-8eed-55e0be2a9181	102715a7-994b-46fe-87cf-9a21487d74cd	fcf60464-178c-4b0e-b2a7-939f31f46ba9	8c3f9ad2-241e-4d66-9a50-2618621356b3	hotel_california_music	Hotel California	1.0000	2026-07-18 09:57:20.997302+00	2026-07-18 09:57:20.997302+00	\N	1
9456d33b-5588-4e09-a3b8-b061133feeef	80db5106-3ea1-4ef8-b8bd-a4b59250404b	102715a7-994b-46fe-87cf-9a21487d74cd	fcf60464-178c-4b0e-b2a7-939f31f46ba9	8c3f9ad2-241e-4d66-9a50-2618621356b3	smells_like_teen_spirit_music	Smells Like Teen Spirit	1.0000	2026-07-18 09:57:21.008004+00	2026-07-18 09:57:21.008004+00	\N	1
116a5ef4-839d-4859-85c3-08a69705fd39	ce8dca5d-1f89-4443-b15a-84c40a01ff40	102715a7-994b-46fe-87cf-9a21487d74cd	fcf60464-178c-4b0e-b2a7-939f31f46ba9	8c3f9ad2-241e-4d66-9a50-2618621356b3	like_a_rolling_stone_music	Like a Rolling Stone	1.0000	2026-07-18 09:57:21.021574+00	2026-07-18 09:57:21.021574+00	\N	1
db132689-4dbd-421a-9939-160954b83ed6	d27be8c9-b14a-42f4-8392-ea44372e5ed6	102715a7-994b-46fe-87cf-9a21487d74cd	fcf60464-178c-4b0e-b2a7-939f31f46ba9	8c3f9ad2-241e-4d66-9a50-2618621356b3	yesterday_music	Yesterday	1.0000	2026-07-18 09:57:21.033792+00	2026-07-18 09:57:21.033792+00	\N	1
62d87c25-37cb-4479-87d4-c811f3285061	2e74dc73-3343-4cad-9310-e1ee2303cb04	102715a7-994b-46fe-87cf-9a21487d74cd	fcf60464-178c-4b0e-b2a7-939f31f46ba9	8c3f9ad2-241e-4d66-9a50-2618621356b3	thriller_music	Thriller	1.0000	2026-07-18 09:57:21.046122+00	2026-07-18 09:57:21.046122+00	\N	1
5e3fb354-9c60-4563-ac40-1ccf2a5d2382	997258fe-8a0a-4273-bfb2-879a1057dcf9	102715a7-994b-46fe-87cf-9a21487d74cd	fcf60464-178c-4b0e-b2a7-939f31f46ba9	8c3f9ad2-241e-4d66-9a50-2618621356b3	comfortably_numb_music	Comfortably Numb	1.0000	2026-07-18 09:57:21.060291+00	2026-07-18 09:57:21.060291+00	\N	1
011b2d11-4272-4d71-99ea-1ced5c9b687a	7f559dfa-39be-4d64-ab04-b654c4611bbe	102715a7-994b-46fe-87cf-9a21487d74cd	fcf60464-178c-4b0e-b2a7-939f31f46ba9	8c3f9ad2-241e-4d66-9a50-2618621356b3	no_woman_no_cry_music	No Woman No Cry	1.0000	2026-07-18 09:57:21.074084+00	2026-07-18 09:57:21.074084+00	\N	1
b26220b9-6707-4e27-b7c4-c32d9eda2cff	69edc036-d376-4fab-8bee-67ed2eef51c3	102715a7-994b-46fe-87cf-9a21487d74cd	0c2ec0ab-ae2d-4cca-84cc-432cd0dd1256	8c3f9ad2-241e-4d66-9a50-2618621356b3	freddie_mercury_music	Фредди Меркьюри	1.0000	2026-07-18 09:57:21.088708+00	2026-07-18 09:57:21.088708+00	\N	1
fb001e2e-6858-4823-b035-b0922bc7fa93	c03b986b-dda2-4c30-9cb0-54b61e67438e	102715a7-994b-46fe-87cf-9a21487d74cd	0c2ec0ab-ae2d-4cca-84cc-432cd0dd1256	8c3f9ad2-241e-4d66-9a50-2618621356b3	jimi_hendrix_music	Джими Хендрикс	1.0000	2026-07-18 09:57:21.102351+00	2026-07-18 09:57:21.102351+00	\N	1
4ec7de9a-1df6-433d-8b87-6f8ab8b9c69b	3ea280fa-29c3-4c89-9577-6398cf756257	102715a7-994b-46fe-87cf-9a21487d74cd	0c2ec0ab-ae2d-4cca-84cc-432cd0dd1256	8c3f9ad2-241e-4d66-9a50-2618621356b3	bob_dylan_music	Боб Дилан	1.0000	2026-07-18 09:57:21.114468+00	2026-07-18 09:57:21.114468+00	\N	1
98f38e6f-0c55-4d7a-b4bf-7d9cea3d88ef	21a43fa4-af0e-4c7c-b56e-7285a1240cc6	102715a7-994b-46fe-87cf-9a21487d74cd	0c2ec0ab-ae2d-4cca-84cc-432cd0dd1256	8c3f9ad2-241e-4d66-9a50-2618621356b3	john_lennon_music	Джон Леннон	1.0000	2026-07-18 09:57:21.125811+00	2026-07-18 09:57:21.125811+00	\N	1
a8d6398b-5081-4d08-81f6-f41850070125	d9184903-40b8-49ba-908e-161fe2174b6c	102715a7-994b-46fe-87cf-9a21487d74cd	0c2ec0ab-ae2d-4cca-84cc-432cd0dd1256	8c3f9ad2-241e-4d66-9a50-2618621356b3	michael_jackson_music	Майкл Джексон	1.0000	2026-07-18 09:57:21.137597+00	2026-07-18 09:57:21.137597+00	\N	1
ba2cecc7-feb9-429d-a860-f229cd447270	fe6098a4-85c4-4762-914b-d07f94736f11	102715a7-994b-46fe-87cf-9a21487d74cd	0c2ec0ab-ae2d-4cca-84cc-432cd0dd1256	8c3f9ad2-241e-4d66-9a50-2618621356b3	bob_marley_music	Боб Марли	1.0000	2026-07-18 09:57:21.148775+00	2026-07-18 09:57:21.148775+00	\N	1
95d725d5-32ef-4b6d-8b2f-094085f0dc38	cbfaf521-05ba-4bb1-b10e-7c7cf885adbf	102715a7-994b-46fe-87cf-9a21487d74cd	0c2ec0ab-ae2d-4cca-84cc-432cd0dd1256	8c3f9ad2-241e-4d66-9a50-2618621356b3	david_gilmour_music	Дэвид Гилмор	1.0000	2026-07-18 09:57:21.15989+00	2026-07-18 09:57:21.15989+00	\N	1
02b1cdfd-f5b7-4c98-ba69-09fbcb8dce16	c45a8ad7-a307-4cd5-8a68-ad311fda0824	102715a7-994b-46fe-87cf-9a21487d74cd	0c2ec0ab-ae2d-4cca-84cc-432cd0dd1256	8c3f9ad2-241e-4d66-9a50-2618621356b3	kurt_cobain_music	Курт Кобейн	1.0000	2026-07-18 09:57:21.170826+00	2026-07-18 09:57:21.170826+00	\N	1
702d2f1a-1762-4fd7-86b4-e8e579fab677	ed04e968-a812-4eb5-8b0d-eceeb66160fe	102715a7-994b-46fe-87cf-9a21487d74cd	0c2ec0ab-ae2d-4cca-84cc-432cd0dd1256	8c3f9ad2-241e-4d66-9a50-2618621356b3	elvis_presley_music	Элвис Пресли	1.0000	2026-07-18 09:57:21.183592+00	2026-07-18 09:57:21.183592+00	\N	1
f33af756-918f-441e-b1b1-1f99b8971bed	b2122f3b-815c-471a-9e76-29e35fecee01	102715a7-994b-46fe-87cf-9a21487d74cd	0c2ec0ab-ae2d-4cca-84cc-432cd0dd1256	8c3f9ad2-241e-4d66-9a50-2618621356b3	ludwig_van_beethoven_music	Людвиг ван Бетховен	1.0000	2026-07-18 09:57:21.19793+00	2026-07-18 09:57:21.19793+00	\N	1
3ba2a862-998f-4318-a516-2b33109a995a	7fe3dd00-a021-49d1-899a-93e6818a30a9	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	8c3f9ad2-241e-4d66-9a50-2618621356b3	1984_orwell_literature	1984	1.0000	2026-07-18 09:57:21.21447+00	2026-07-18 09:57:21.21447+00	\N	1
b645c943-5630-43b7-89c9-633d4232c9d5	01648745-0c99-4cfe-bb8d-acbdeea2e6c4	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	8c3f9ad2-241e-4d66-9a50-2618621356b3	brave_new_world_literature	Дивный новый мир	1.0000	2026-07-18 09:57:21.224719+00	2026-07-18 09:57:21.224719+00	\N	1
59097e2a-2ef4-43bb-be22-5de9f19ea3b1	bbe028e9-d2b9-41bf-aefb-5f5373b616ba	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	8c3f9ad2-241e-4d66-9a50-2618621356b3	fahrenheit_451_literature	451 градус по Фаренгейту	1.0000	2026-07-18 09:57:21.236162+00	2026-07-18 09:57:21.236162+00	\N	1
a42cff73-b8c6-4414-9cf7-47aa667ac157	c42fd1c7-57e3-48f2-a429-94fe8e908f1f	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	8c3f9ad2-241e-4d66-9a50-2618621356b3	hobbit_literature	Хоббит	1.0000	2026-07-18 09:57:21.247939+00	2026-07-18 09:57:21.247939+00	\N	1
e9082ff5-1c13-4814-a195-2c953070bca9	c5803f80-ec8f-498e-a0dc-027184d0fc3d	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	8c3f9ad2-241e-4d66-9a50-2618621356b3	dune_literature	Дюна	1.0000	2026-07-18 09:57:21.25931+00	2026-07-18 09:57:21.25931+00	\N	1
42e59334-ea2b-49a7-8978-082777846f38	f05470cf-ce25-4bf3-8acf-ac54bb3d2426	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	8c3f9ad2-241e-4d66-9a50-2618621356b3	master_margarita_literature	Мастер и Маргарита	1.0000	2026-07-18 09:57:21.270622+00	2026-07-18 09:57:21.270622+00	\N	1
c6c1cd6f-ea56-4d85-8a24-7dd48e3a2419	c1605c47-91cb-4d46-8a6c-82643625caa8	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	8c3f9ad2-241e-4d66-9a50-2618621356b3	war_peace_literature	Война и мир	1.0000	2026-07-18 09:57:21.282117+00	2026-07-18 09:57:21.282117+00	\N	1
acd52774-107e-4718-9386-3d02dd77f044	3ad1b264-4c1a-4bab-a47c-7c464bd9fb75	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	8c3f9ad2-241e-4d66-9a50-2618621356b3	crime_punishment_literature	Преступление и наказание	1.0000	2026-07-18 09:57:21.292694+00	2026-07-18 09:57:21.292694+00	\N	1
55833a21-d66c-40b7-af27-e2dee8a8e7fc	5ed7d3d6-3486-43c2-bc33-13de728cc779	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	8c3f9ad2-241e-4d66-9a50-2618621356b3	solaris_literature	Солярис	1.0000	2026-07-18 09:57:21.306917+00	2026-07-18 09:57:21.306917+00	\N	1
22772cae-6136-4e93-ab66-7e1f7f0930b3	472449a5-e0c8-45a2-ba13-8e85fd837166	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	8c3f9ad2-241e-4d66-9a50-2618621356b3	harry_potter_literature	Гарри Поттер	1.0000	2026-07-18 09:57:21.320607+00	2026-07-18 09:57:21.320607+00	\N	1
7dca75ed-755c-4549-91f4-5557667b4a7c	8803fa13-24d5-4d44-902d-a7a07b54db96	4264c67d-7bbe-49af-9df3-0289d61f4477	3330b5d5-ef3c-43d5-b0e8-42f7fc6c8b1b	8c3f9ad2-241e-4d66-9a50-2618621356b3	george_orwell_literature	Джордж Оруэлл	1.0000	2026-07-18 09:57:21.338381+00	2026-07-18 09:57:21.338381+00	\N	1
2ffadf51-6896-41bf-95f8-42bbe9d2e2f8	7e50d09d-7cc0-45d7-a458-841fbc4bb306	4264c67d-7bbe-49af-9df3-0289d61f4477	3330b5d5-ef3c-43d5-b0e8-42f7fc6c8b1b	8c3f9ad2-241e-4d66-9a50-2618621356b3	tolkien_literature	Дж. Р. Р. Толкин	1.0000	2026-07-18 09:57:21.351255+00	2026-07-18 09:57:21.351255+00	\N	1
b1252f58-6ae8-4dc0-b782-f4d75299b561	8fbc5a21-3f98-40c0-a787-c43b2aa052ad	4264c67d-7bbe-49af-9df3-0289d61f4477	3330b5d5-ef3c-43d5-b0e8-42f7fc6c8b1b	8c3f9ad2-241e-4d66-9a50-2618621356b3	bulgakov_literature	Михаил Булгаков	1.0000	2026-07-18 09:57:21.360642+00	2026-07-18 09:57:21.360642+00	\N	1
97463325-3df6-4da4-aaae-49b8bd65467e	78fb1db1-d560-4ade-a8a8-46d51af4c17d	4264c67d-7bbe-49af-9df3-0289d61f4477	3330b5d5-ef3c-43d5-b0e8-42f7fc6c8b1b	8c3f9ad2-241e-4d66-9a50-2618621356b3	tolstoy_literature	Лев Толстой	1.0000	2026-07-18 09:57:21.369852+00	2026-07-18 09:57:21.369852+00	\N	1
4ebbccc4-acff-4240-8363-0b99727ce8ce	eccd785d-f09d-4eb8-88d7-61477586c60d	4264c67d-7bbe-49af-9df3-0289d61f4477	3330b5d5-ef3c-43d5-b0e8-42f7fc6c8b1b	8c3f9ad2-241e-4d66-9a50-2618621356b3	dostoevsky_literature	Фёдор Достоевский	1.0000	2026-07-18 09:57:21.379127+00	2026-07-18 09:57:21.379127+00	\N	1
19e34f62-e56d-40d8-80ac-ed43951b2490	5f4b69e6-1dcc-45eb-a6c3-190613400bc9	4264c67d-7bbe-49af-9df3-0289d61f4477	3330b5d5-ef3c-43d5-b0e8-42f7fc6c8b1b	8c3f9ad2-241e-4d66-9a50-2618621356b3	stephen_king_literature	Стивен Кинг	1.0000	2026-07-18 09:57:21.387763+00	2026-07-18 09:57:21.387763+00	\N	1
dab11d71-c331-4511-8014-87211016f552	e03d486b-140a-4554-bbe8-73a526b9f722	4264c67d-7bbe-49af-9df3-0289d61f4477	3330b5d5-ef3c-43d5-b0e8-42f7fc6c8b1b	8c3f9ad2-241e-4d66-9a50-2618621356b3	ray_bradbury_literature	Рэй Брэдбери	1.0000	2026-07-18 09:57:21.396646+00	2026-07-18 09:57:21.396646+00	\N	1
5b3e9fb0-ebbc-4d8c-a060-d53630c25de9	f95cb9e8-173b-48df-9514-5952b0a7ecd9	4264c67d-7bbe-49af-9df3-0289d61f4477	3330b5d5-ef3c-43d5-b0e8-42f7fc6c8b1b	8c3f9ad2-241e-4d66-9a50-2618621356b3	stan_lem_literature	Станислав Лем	1.0000	2026-07-18 09:57:21.405542+00	2026-07-18 09:57:21.405542+00	\N	1
0804d0c1-9161-4e46-a823-6de06630499e	01688b9c-cff6-4480-8e6f-fd665ebed28f	4264c67d-7bbe-49af-9df3-0289d61f4477	3330b5d5-ef3c-43d5-b0e8-42f7fc6c8b1b	8c3f9ad2-241e-4d66-9a50-2618621356b3	chuck_palahniuk_literature	Чак Паланик	1.0000	2026-07-18 09:57:21.415168+00	2026-07-18 09:57:21.415168+00	\N	1
d4a06d99-ed38-4c6e-9e9e-aefe971cef14	8dbaceed-a2a7-4c9c-b4cd-92202e7ec671	4264c67d-7bbe-49af-9df3-0289d61f4477	3330b5d5-ef3c-43d5-b0e8-42f7fc6c8b1b	8c3f9ad2-241e-4d66-9a50-2618621356b3	jk_rowling_literature	Дж. К. Роулинг	1.0000	2026-07-18 09:57:21.426101+00	2026-07-18 09:57:21.426101+00	\N	1
683840ba-a2d4-4ee5-9c9e-2723ff86736f	8d533df6-9672-4f7c-b1be-a853b0381959	96ffa67d-b033-4950-89e6-d35cff76da25	99662b06-1284-4d5c-878c-ef1cd804ebc3	8c3f9ad2-241e-4d66-9a50-2618621356b3	new_york_geography	Нью-Йорк	1.0000	2026-07-18 09:57:21.437713+00	2026-07-18 09:57:21.437713+00	\N	1
1be961d7-0a2b-4e8a-9d49-da9722a87195	19787a08-7bc6-46b1-9c07-9dc45148704c	96ffa67d-b033-4950-89e6-d35cff76da25	99662b06-1284-4d5c-878c-ef1cd804ebc3	8c3f9ad2-241e-4d66-9a50-2618621356b3	london_geography	Лондон	1.0000	2026-07-18 09:57:21.447257+00	2026-07-18 09:57:21.447257+00	\N	1
c1deff2b-abcb-435d-8815-14155002920f	34245b99-bf0b-4aad-8c0f-a1c26faf531b	96ffa67d-b033-4950-89e6-d35cff76da25	99662b06-1284-4d5c-878c-ef1cd804ebc3	8c3f9ad2-241e-4d66-9a50-2618621356b3	paris_geography	Париж	1.0000	2026-07-18 09:57:21.45755+00	2026-07-18 09:57:21.45755+00	\N	1
88ef987d-88ef-4b93-b090-a6d2fb03eacf	1b94695f-bb7e-4fd7-8c29-53c5a161812d	96ffa67d-b033-4950-89e6-d35cff76da25	99662b06-1284-4d5c-878c-ef1cd804ebc3	8c3f9ad2-241e-4d66-9a50-2618621356b3	tokyo_geography	Токио	1.0000	2026-07-18 09:57:21.466541+00	2026-07-18 09:57:21.466541+00	\N	1
0f63bcd0-4543-4f7f-9dba-9d999480e033	8e506f85-3b7d-4f71-93b0-bb6053188fcd	96ffa67d-b033-4950-89e6-d35cff76da25	99662b06-1284-4d5c-878c-ef1cd804ebc3	8c3f9ad2-241e-4d66-9a50-2618621356b3	moscow_geography	Москва	1.0000	2026-07-18 09:57:21.475179+00	2026-07-18 09:57:21.475179+00	\N	1
0c2ac07d-f809-4f79-8c20-4e6cf310cfa5	926600a2-baeb-40e0-a9b3-45f1981cddbc	96ffa67d-b033-4950-89e6-d35cff76da25	99662b06-1284-4d5c-878c-ef1cd804ebc3	8c3f9ad2-241e-4d66-9a50-2618621356b3	berlin_geography	Берлин	1.0000	2026-07-18 09:57:21.48365+00	2026-07-18 09:57:21.48365+00	\N	1
4d9080e5-ad25-4c76-b068-609849a86c16	15621346-ee2c-4cd0-9ed5-43532377a1cf	96ffa67d-b033-4950-89e6-d35cff76da25	99662b06-1284-4d5c-878c-ef1cd804ebc3	8c3f9ad2-241e-4d66-9a50-2618621356b3	los_angeles_geography	Лос-Анджелес	1.0000	2026-07-18 09:57:21.492362+00	2026-07-18 09:57:21.492362+00	\N	1
920267ff-8588-4e84-a17c-aa1f4bcefa5d	cddfd7b4-aec3-4010-8869-5d88317bd6fd	96ffa67d-b033-4950-89e6-d35cff76da25	99662b06-1284-4d5c-878c-ef1cd804ebc3	8c3f9ad2-241e-4d66-9a50-2618621356b3	rome_geography	Рим	1.0000	2026-07-18 09:57:21.500804+00	2026-07-18 09:57:21.500804+00	\N	1
cb99dfa6-9f37-4e04-99ba-2fe837d73d9a	1ecd1e93-4eef-4ecb-9ff5-b77c1c4211c3	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_1ecd1e934eef	моана	1.0000	2026-07-18 20:58:32.206066+00	2026-07-18 20:58:32.206071+00	\N	1
f031184e-630b-4bca-ad10-27bf6686c09f	df2cc641-dbb0-41d5-95f1-c2615f69a134	96ffa67d-b033-4950-89e6-d35cff76da25	99662b06-1284-4d5c-878c-ef1cd804ebc3	8c3f9ad2-241e-4d66-9a50-2618621356b3	sydney_geography	Сидней	1.0000	2026-07-18 09:57:21.509576+00	2026-07-18 09:57:21.509576+00	\N	1
633e5918-8550-47ac-bd45-3c9137c7c278	5c8d82b2-23a8-49c8-abea-9e8b7a351bac	96ffa67d-b033-4950-89e6-d35cff76da25	99662b06-1284-4d5c-878c-ef1cd804ebc3	8c3f9ad2-241e-4d66-9a50-2618621356b3	cairo_geography	Каир	1.0000	2026-07-18 09:57:21.51912+00	2026-07-18 09:57:21.51912+00	\N	1
662e9ab1-ca65-437c-8a24-383abc071105	e9b3e55b-2949-4199-a62f-561d4fcff81a	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	55610502-a3ce-4f51-a842-834c9fd46cc9	8c3f9ad2-241e-4d66-9a50-2618621356b3	hydrogen_science	Водород	1.0000	2026-07-18 09:57:21.530624+00	2026-07-18 09:57:21.530624+00	\N	1
1811108d-ad7d-4017-83a7-938ac721248c	e77046fa-3c1f-4f25-98c5-71fd3cc5eeb1	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	55610502-a3ce-4f51-a842-834c9fd46cc9	8c3f9ad2-241e-4d66-9a50-2618621356b3	helium_science	Гелий	1.0000	2026-07-18 09:57:21.539795+00	2026-07-18 09:57:21.539795+00	\N	1
0fb4a712-ab31-453f-b93e-08d4e0f83f4c	a8f5981e-e074-4f55-be73-7cd95387e91c	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	55610502-a3ce-4f51-a842-834c9fd46cc9	8c3f9ad2-241e-4d66-9a50-2618621356b3	carbon_science	Углерод	1.0000	2026-07-18 09:57:21.54863+00	2026-07-18 09:57:21.54863+00	\N	1
6cc33fec-18e4-48fe-9db9-020230afb680	eeccd18c-b028-4642-b73f-6027cf48de6a	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	55610502-a3ce-4f51-a842-834c9fd46cc9	8c3f9ad2-241e-4d66-9a50-2618621356b3	oxygen_science	Кислород	1.0000	2026-07-18 09:57:21.558661+00	2026-07-18 09:57:21.558661+00	\N	1
48431572-cf5d-4754-a1de-d2a01fc2c89d	4660dd15-b070-4ce6-b08d-dd04077e1dd6	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	55610502-a3ce-4f51-a842-834c9fd46cc9	8c3f9ad2-241e-4d66-9a50-2618621356b3	iron_science	Железо	1.0000	2026-07-18 09:57:21.567823+00	2026-07-18 09:57:21.567823+00	\N	1
eaa986aa-84c1-48ec-ac97-e0a23ec820aa	6f3e4fd5-05e9-4885-8ac5-9adf9930a842	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	55610502-a3ce-4f51-a842-834c9fd46cc9	8c3f9ad2-241e-4d66-9a50-2618621356b3	gold_science	Золото	1.0000	2026-07-18 09:57:21.577578+00	2026-07-18 09:57:21.577578+00	\N	1
ff7d0ff0-3495-4b2c-a23f-7e3c43c76363	b7615e44-a938-4c65-9626-747afd9f874f	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	55610502-a3ce-4f51-a842-834c9fd46cc9	8c3f9ad2-241e-4d66-9a50-2618621356b3	silver_science	Серебро	1.0000	2026-07-18 09:57:21.589756+00	2026-07-18 09:57:21.589756+00	\N	1
340d4476-80d9-420e-83ee-c1f7ed9ebb82	7a168f08-f4ae-4d92-8366-a259e41030ad	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	55610502-a3ce-4f51-a842-834c9fd46cc9	8c3f9ad2-241e-4d66-9a50-2618621356b3	copper_science	Медь	1.0000	2026-07-18 09:57:21.604304+00	2026-07-18 09:57:21.604304+00	\N	1
fbe2f02f-6182-4f5a-9486-6dd30a3bba1a	fbdeb7a4-0913-4939-ba6c-39de2943925a	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	55610502-a3ce-4f51-a842-834c9fd46cc9	8c3f9ad2-241e-4d66-9a50-2618621356b3	silicon_science	Кремний	1.0000	2026-07-18 09:57:21.617754+00	2026-07-18 09:57:21.617754+00	\N	1
ca3b66fa-10b6-403f-9292-4e876c63ce8d	1521e795-f0bf-40a4-8522-9e334399a2a1	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	55610502-a3ce-4f51-a842-834c9fd46cc9	8c3f9ad2-241e-4d66-9a50-2618621356b3	uranium_science	Уран	1.0000	2026-07-18 09:57:21.628657+00	2026-07-18 09:57:21.628657+00	\N	1
9b5004ab-ee6c-4645-ac89-42f2bc1c4e81	4260b491-39b2-4d11-98e0-c66f9b024e29	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	313cdb66-75e2-459d-9696-71785601e875	8c3f9ad2-241e-4d66-9a50-2618621356b3	african_elephant_science	Африканский слон	1.0000	2026-07-18 09:57:21.645313+00	2026-07-18 09:57:21.645313+00	\N	1
56b4c4f1-19c8-45e1-9b5c-232636e2a7fe	9fdd08c5-8ed1-41b6-a801-b05ada603e40	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	313cdb66-75e2-459d-9696-71785601e875	8c3f9ad2-241e-4d66-9a50-2618621356b3	blue_whale_science	Синий кит	1.0000	2026-07-18 09:57:21.65891+00	2026-07-18 09:57:21.65891+00	\N	1
76c3b6cb-549b-4e5e-886e-b8a7491fdd4f	6e00c01b-e63b-4d78-9601-565fc290e271	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	313cdb66-75e2-459d-9696-71785601e875	8c3f9ad2-241e-4d66-9a50-2618621356b3	golden_eagle_science	Орёл	1.0000	2026-07-18 09:57:21.672878+00	2026-07-18 09:57:21.672878+00	\N	1
ff787e6b-348f-4de9-a0d8-5b18027b84f1	178e0a06-8854-4baf-ad7f-8328c8f3da06	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	313cdb66-75e2-459d-9696-71785601e875	8c3f9ad2-241e-4d66-9a50-2618621356b3	gray_wolf_science	Серый волк	1.0000	2026-07-18 09:57:21.685736+00	2026-07-18 09:57:21.685736+00	\N	1
698d6867-9ad6-4860-bd88-cf6b699b15d8	93537e7f-6e85-407b-8f42-8791b6871e31	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	313cdb66-75e2-459d-9696-71785601e875	8c3f9ad2-241e-4d66-9a50-2618621356b3	polar_bear_science	Белый медведь	1.0000	2026-07-18 09:57:21.697874+00	2026-07-18 09:57:21.697874+00	\N	1
5d963c05-3b5b-4016-b3d7-0e1451954363	ff6c4273-2f89-447b-af80-e2a858719f5b	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	313cdb66-75e2-459d-9696-71785601e875	8c3f9ad2-241e-4d66-9a50-2618621356b3	bald_eagle_science	Орлан	1.0000	2026-07-18 09:57:21.708574+00	2026-07-18 09:57:21.708574+00	\N	1
f935e10f-3b17-4948-9fbc-0415715c71b6	ce493d5d-b11e-49b8-bfea-054988f6d50d	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	313cdb66-75e2-459d-9696-71785601e875	8c3f9ad2-241e-4d66-9a50-2618621356b3	snow_leopard_science	Снежный барс	1.0000	2026-07-18 09:57:21.719215+00	2026-07-18 09:57:21.719215+00	\N	1
e6ed7062-4701-440c-ad10-5b32894a4600	3afd0978-487a-4e25-9445-c5baedb40e00	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	313cdb66-75e2-459d-9696-71785601e875	8c3f9ad2-241e-4d66-9a50-2618621356b3	red_panda_science	Красная панда	1.0000	2026-07-18 09:57:21.729415+00	2026-07-18 09:57:21.729415+00	\N	1
0e95eb38-1845-4fd7-99d0-ca3470daaffb	70cf6c05-21e8-4a02-8977-87d94734a231	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	313cdb66-75e2-459d-9696-71785601e875	8c3f9ad2-241e-4d66-9a50-2618621356b3	bengal_tiger_science	Бенгальский тигр	1.0000	2026-07-18 09:57:21.740495+00	2026-07-18 09:57:21.740495+00	\N	1
2e216ce0-d2ca-4d47-9bf1-9a18f96f8f7f	7624f2b4-066f-4cac-ab86-766b04debc1f	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	313cdb66-75e2-459d-9696-71785601e875	8c3f9ad2-241e-4d66-9a50-2618621356b3	emperor_penguin_science	Императорский пингвин	1.0000	2026-07-18 09:57:21.752029+00	2026-07-18 09:57:21.752029+00	\N	1
691ea7b5-96c0-46b3-b1db-9747945d4a1c	2dcca74c-ae06-4a67-8189-54116ff080b1	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	a47e7939-ca26-4d11-872f-8bc573638ebf	8c3f9ad2-241e-4d66-9a50-2618621356b3	sequoia_science	Секвойя	1.0000	2026-07-18 09:57:21.76539+00	2026-07-18 09:57:21.76539+00	\N	1
bb2b1095-c577-496f-899e-5fc2f5859750	32e39547-50f5-4435-a0c6-f1f04876848b	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	a47e7939-ca26-4d11-872f-8bc573638ebf	8c3f9ad2-241e-4d66-9a50-2618621356b3	baobab_science	Баобаб	1.0000	2026-07-18 09:57:21.775937+00	2026-07-18 09:57:21.775937+00	\N	1
9e9c85a0-08a3-4493-b145-804f2d047236	494f1216-d71a-4ab7-be3e-9291040bf88e	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	a47e7939-ca26-4d11-872f-8bc573638ebf	8c3f9ad2-241e-4d66-9a50-2618621356b3	giant_kelp_science	Гигантская ламинария	1.0000	2026-07-18 09:57:21.787179+00	2026-07-18 09:57:21.787179+00	\N	1
bb132a86-fb6a-4aaa-be7d-87b9d97a0d0e	467ffb2a-3a24-4602-88bc-6e7ab40e2f4a	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	a47e7939-ca26-4d11-872f-8bc573638ebf	8c3f9ad2-241e-4d66-9a50-2618621356b3	joshua_tree_science	Дерево Иисуса	1.0000	2026-07-18 09:57:21.798267+00	2026-07-18 09:57:21.798267+00	\N	1
e820b1e0-7cd9-4812-9def-13f38b74b680	595bc463-ce69-4266-b984-623cb3fa1edd	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	a47e7939-ca26-4d11-872f-8bc573638ebf	8c3f9ad2-241e-4d66-9a50-2618621356b3	white_oak_science	Белый дуб	1.0000	2026-07-18 09:57:21.809297+00	2026-07-18 09:57:21.809297+00	\N	1
7f121e6e-8aff-4e69-bbc0-6fa87395ff72	e8886070-f942-48a8-a0ae-eb7e02cb6f02	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	a47e7939-ca26-4d11-872f-8bc573638ebf	8c3f9ad2-241e-4d66-9a50-2618621356b3	bamboo_science	Бамбук	1.0000	2026-07-18 09:57:21.820698+00	2026-07-18 09:57:21.820698+00	\N	1
14288787-14a7-4ab9-ad5c-183eddec64db	aff17dd6-73f1-4cd7-a942-ff407d1defac	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	a47e7939-ca26-4d11-872f-8bc573638ebf	8c3f9ad2-241e-4d66-9a50-2618621356b3	giant_sunflower_science	Подсолнечник	1.0000	2026-07-18 09:57:21.832935+00	2026-07-18 09:57:21.832935+00	\N	1
39685c95-2370-4220-a7cf-cd2c000c0e89	39f54e29-3882-4ecd-be12-57db727bbf86	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	a47e7939-ca26-4d11-872f-8bc573638ebf	8c3f9ad2-241e-4d66-9a50-2618621356b3	royal_palm_science	Королевская пальма	1.0000	2026-07-18 09:57:21.845364+00	2026-07-18 09:57:21.845364+00	\N	1
658b6544-3abf-4100-99da-c3582796686d	f244fdb2-7356-4cb6-ab43-6185c9d9dabd	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	a47e7939-ca26-4d11-872f-8bc573638ebf	8c3f9ad2-241e-4d66-9a50-2618621356b3	ginkgo_science	Гинкго	1.0000	2026-07-18 09:57:21.85732+00	2026-07-18 09:57:21.85732+00	\N	1
bd2ecd74-769a-4077-b2da-ae1942afbdd9	1eb8cafd-7157-438a-83c2-8b72e51fd32b	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	a47e7939-ca26-4d11-872f-8bc573638ebf	8c3f9ad2-241e-4d66-9a50-2618621356b3	venus_flytrap_science	Венерина мухоловка	1.0000	2026-07-18 09:57:21.867661+00	2026-07-18 09:57:21.867661+00	\N	1
c091d95b-4161-4182-8d81-2b3faa79ad33	0c8db544-0346-4678-b1ca-1fc1a135b3d8	102715a7-994b-46fe-87cf-9a21487d74cd	ed80002b-3429-4270-80c7-622540dddfcc	8c3f9ad2-241e-4d66-9a50-2618621356b3	abbey_road_music	Abbey Road	1.0000	2026-07-18 09:57:21.880601+00	2026-07-18 09:57:21.880601+00	\N	1
d6b119f8-2127-479c-b764-f8abe396fe7e	54b581ae-2b9b-4108-85c6-553d06429fb6	102715a7-994b-46fe-87cf-9a21487d74cd	ed80002b-3429-4270-80c7-622540dddfcc	8c3f9ad2-241e-4d66-9a50-2618621356b3	dark_side_moon_music	The Dark Side of the Moon	1.0000	2026-07-18 09:57:21.891526+00	2026-07-18 09:57:21.891526+00	\N	1
30f7c20a-be19-4c4b-9921-fcc85cb9dd7d	3b6a0e16-9e3e-4677-96b0-3805906570bb	102715a7-994b-46fe-87cf-9a21487d74cd	ed80002b-3429-4270-80c7-622540dddfcc	8c3f9ad2-241e-4d66-9a50-2618621356b3	thriller_album_music	Thriller	1.0000	2026-07-18 09:57:21.90204+00	2026-07-18 09:57:21.90204+00	\N	1
38d8fab1-ecd2-4b12-a1b2-9d2962b49444	5469017a-120f-4283-9d3a-d825191eaafd	102715a7-994b-46fe-87cf-9a21487d74cd	ed80002b-3429-4270-80c7-622540dddfcc	8c3f9ad2-241e-4d66-9a50-2618621356b3	nevermind_music	Nevermind	1.0000	2026-07-18 09:57:21.912753+00	2026-07-18 09:57:21.912753+00	\N	1
5fc5cdd8-f97a-4f31-8c32-676370d8f861	bdc5f754-0549-4710-a51e-c93b6f21b168	102715a7-994b-46fe-87cf-9a21487d74cd	ed80002b-3429-4270-80c7-622540dddfcc	8c3f9ad2-241e-4d66-9a50-2618621356b3	led_zeppelin_iv_music	Led Zeppelin IV	1.0000	2026-07-18 09:57:21.924103+00	2026-07-18 09:57:21.924103+00	\N	1
97bf1bf4-77eb-4d67-bbb3-002b55ea5f67	7e42c151-9cdf-4472-b69a-377fc72ff6b4	102715a7-994b-46fe-87cf-9a21487d74cd	ed80002b-3429-4270-80c7-622540dddfcc	8c3f9ad2-241e-4d66-9a50-2618621356b3	hotel_california_album_music	Hotel California	1.0000	2026-07-18 09:57:21.935928+00	2026-07-18 09:57:21.935928+00	\N	1
cc021081-81e6-47db-8ce0-45c289a0bf68	8db8ca3d-43d7-4dad-99b0-55c5da133298	102715a7-994b-46fe-87cf-9a21487d74cd	ed80002b-3429-4270-80c7-622540dddfcc	8c3f9ad2-241e-4d66-9a50-2618621356b3	the_wall_music	The Wall	1.0000	2026-07-18 09:57:21.946955+00	2026-07-18 09:57:21.946955+00	\N	1
796ffc37-f24a-4577-8179-8aeeae0309ac	31932ca6-473d-4016-a865-cf8f44705dc7	102715a7-994b-46fe-87cf-9a21487d74cd	ed80002b-3429-4270-80c7-622540dddfcc	8c3f9ad2-241e-4d66-9a50-2618621356b3	ok_computer_music	OK Computer	1.0000	2026-07-18 09:57:21.9564+00	2026-07-18 09:57:21.9564+00	\N	1
b46e55bb-dd8d-4604-a437-1956e242b71e	c9d9e0f0-5257-4fba-8587-303ad6fbbd27	102715a7-994b-46fe-87cf-9a21487d74cd	ed80002b-3429-4270-80c7-622540dddfcc	8c3f9ad2-241e-4d66-9a50-2618621356b3	rumours_music	Rumours	1.0000	2026-07-18 09:57:21.964841+00	2026-07-18 09:57:21.964841+00	\N	1
7505ba61-0eaa-4482-a1cf-dd135fe2a7a7	49718987-d935-42db-b3e6-3ef15651e7f1	102715a7-994b-46fe-87cf-9a21487d74cd	ed80002b-3429-4270-80c7-622540dddfcc	8c3f9ad2-241e-4d66-9a50-2618621356b3	back_in_black_music	Back in Black	1.0000	2026-07-18 09:57:21.973337+00	2026-07-18 09:57:21.973337+00	\N	1
89d59b56-c7e7-4faa-8072-3d1b54be1809	f70632ea-3cc3-41c8-b0d6-c1c81b8e733c	801d5718-54ec-44c7-85da-af53af4d7acc	3d22c910-caff-462e-bc8f-f156bc5479eb	8c3f9ad2-241e-4d66-9a50-2618621356b3	artificial_intelligence_default	Искусственный интеллект	1.0000	2026-07-18 09:57:21.985645+00	2026-07-18 09:57:21.985645+00	\N	1
c9c63950-7212-4d16-8b2a-11c2c053afbd	9693f320-3852-49e3-89dc-0dc685b3cb12	801d5718-54ec-44c7-85da-af53af4d7acc	3d22c910-caff-462e-bc8f-f156bc5479eb	8c3f9ad2-241e-4d66-9a50-2618621356b3	quantum_computing_default	Квантовые вычисления	1.0000	2026-07-18 09:57:21.997557+00	2026-07-18 09:57:21.997557+00	\N	1
d9ce1ef3-f6c2-4c02-b1af-049da351b72d	207dbab2-2833-4b41-82b3-029b50de9c3c	801d5718-54ec-44c7-85da-af53af4d7acc	3d22c910-caff-462e-bc8f-f156bc5479eb	8c3f9ad2-241e-4d66-9a50-2618621356b3	blockchain_default	Блокчейн	1.0000	2026-07-18 09:57:22.008939+00	2026-07-18 09:57:22.008939+00	\N	1
95a4d283-f9dc-4658-8b2c-4e016f11d984	3512cdda-6ede-466b-97fe-6d6e38fcd2ac	801d5718-54ec-44c7-85da-af53af4d7acc	3d22c910-caff-462e-bc8f-f156bc5479eb	8c3f9ad2-241e-4d66-9a50-2618621356b3	existentialism_default	Экзистенциализм	1.0000	2026-07-18 09:57:22.020072+00	2026-07-18 09:57:22.020072+00	\N	1
ea489444-826d-42bf-926f-cfc26a2ac273	64f99728-90df-40a1-ae15-c07e185c2eba	801d5718-54ec-44c7-85da-af53af4d7acc	3d22c910-caff-462e-bc8f-f156bc5479eb	8c3f9ad2-241e-4d66-9a50-2618621356b3	democracy_default	Демократия	1.0000	2026-07-18 09:57:22.032132+00	2026-07-18 09:57:22.032132+00	\N	1
342f4e39-d5e0-404e-a50b-31726355d4dd	6400258b-0021-4456-bea5-ad4ab07f4aed	801d5718-54ec-44c7-85da-af53af4d7acc	3d22c910-caff-462e-bc8f-f156bc5479eb	8c3f9ad2-241e-4d66-9a50-2618621356b3	globalization_default	Глобализация	1.0000	2026-07-18 09:57:22.043564+00	2026-07-18 09:57:22.043564+00	\N	1
2fb66f75-8c84-4a7d-a3be-772c11816a73	5ea88755-26e9-4ddb-a1a8-7fb956a9ae8a	801d5718-54ec-44c7-85da-af53af4d7acc	3d22c910-caff-462e-bc8f-f156bc5479eb	8c3f9ad2-241e-4d66-9a50-2618621356b3	renaissance_default	Ренессанс	1.0000	2026-07-18 09:57:22.05821+00	2026-07-18 09:57:22.05821+00	\N	1
e73db2ac-5278-4e94-9762-cb5cfbf0ec51	fb23ce73-4dbe-4dc3-bea8-35438f725765	801d5718-54ec-44c7-85da-af53af4d7acc	3d22c910-caff-462e-bc8f-f156bc5479eb	8c3f9ad2-241e-4d66-9a50-2618621356b3	climate_change_default	Изменение климата	1.0000	2026-07-18 09:57:22.0711+00	2026-07-18 09:57:22.0711+00	\N	1
59a4e861-91f7-4c7c-9d95-f71e625d2be4	7c7f0ff5-5849-47ad-bd2d-91f9fbea99a1	801d5718-54ec-44c7-85da-af53af4d7acc	3d22c910-caff-462e-bc8f-f156bc5479eb	8c3f9ad2-241e-4d66-9a50-2618621356b3	surrealism_default	Сюрреализм	1.0000	2026-07-18 09:57:22.082705+00	2026-07-18 09:57:22.082705+00	\N	1
30e2bd9e-ff63-4844-89ed-7db7a5f5ad3e	cdc02526-45c8-40c0-9648-e1301798825a	801d5718-54ec-44c7-85da-af53af4d7acc	3d22c910-caff-462e-bc8f-f156bc5479eb	8c3f9ad2-241e-4d66-9a50-2618621356b3	stoicism_default	Стоицизм	1.0000	2026-07-18 09:57:22.093446+00	2026-07-18 09:57:22.093446+00	\N	1
12834bac-4e52-44c1-98cb-1cab7f711c77	929628d4-a955-4645-9a0b-bc4a861ba8bd	801d5718-54ec-44c7-85da-af53af4d7acc	cf6dc12e-5888-4bce-8ee6-7ff442c338cd	8c3f9ad2-241e-4d66-9a50-2618621356b3	sci_fi_default	Научная фантастика	1.0000	2026-07-18 09:57:22.106285+00	2026-07-18 09:57:22.106285+00	\N	1
a548327c-970e-4dbc-a1fc-0fab50b45be0	9730c0fa-e351-4c1f-9b78-c7edd1e1337a	801d5718-54ec-44c7-85da-af53af4d7acc	cf6dc12e-5888-4bce-8ee6-7ff442c338cd	8c3f9ad2-241e-4d66-9a50-2618621356b3	noir_default	Нуар	1.0000	2026-07-18 09:57:22.117249+00	2026-07-18 09:57:22.117249+00	\N	1
72e10176-55b6-4146-8a70-8b9540a1760c	2800ae7e-b7f9-4475-9684-bbfba0dc2906	801d5718-54ec-44c7-85da-af53af4d7acc	cf6dc12e-5888-4bce-8ee6-7ff442c338cd	8c3f9ad2-241e-4d66-9a50-2618621356b3	progressive_rock_default	Прогрессивный рок	1.0000	2026-07-18 09:57:22.127841+00	2026-07-18 09:57:22.127841+00	\N	1
a0291632-4fb9-499e-b95a-64a6420e1d89	21439c77-30ed-4b20-a353-f6bf66826412	801d5718-54ec-44c7-85da-af53af4d7acc	cf6dc12e-5888-4bce-8ee6-7ff442c338cd	8c3f9ad2-241e-4d66-9a50-2618621356b3	grunge_default	Гранж	1.0000	2026-07-18 09:57:22.138961+00	2026-07-18 09:57:22.138961+00	\N	1
338c5eba-772e-46fe-b551-bb49eb38c8fb	f09dba17-9dad-4a4b-bb7c-0850f412740d	801d5718-54ec-44c7-85da-af53af4d7acc	cf6dc12e-5888-4bce-8ee6-7ff442c338cd	8c3f9ad2-241e-4d66-9a50-2618621356b3	dystopia_genre_default	Антиутопия	1.0000	2026-07-18 09:57:22.152017+00	2026-07-18 09:57:22.152017+00	\N	1
2408b634-b332-4112-a7bc-09e60702294a	7ec1f5cb-47dc-47cb-a2dd-a2c4a8c361b9	801d5718-54ec-44c7-85da-af53af4d7acc	cf6dc12e-5888-4bce-8ee6-7ff442c338cd	8c3f9ad2-241e-4d66-9a50-2618621356b3	reggae_default	Регги	1.0000	2026-07-18 09:57:22.16515+00	2026-07-18 09:57:22.16515+00	\N	1
f8810f29-7612-4de5-9943-4b7cded8e22e	8c23ab7d-4927-4cd8-baa4-c349ac078fa2	801d5718-54ec-44c7-85da-af53af4d7acc	cf6dc12e-5888-4bce-8ee6-7ff442c338cd	8c3f9ad2-241e-4d66-9a50-2618621356b3	hard_rock_default	Хард-рок	1.0000	2026-07-18 09:57:22.176697+00	2026-07-18 09:57:22.176697+00	\N	1
3feb5117-24aa-48e6-a418-4bfbbf0c5559	b78f5b78-fc9f-4bba-9d2f-be0c98a53c9b	801d5718-54ec-44c7-85da-af53af4d7acc	cf6dc12e-5888-4bce-8ee6-7ff442c338cd	8c3f9ad2-241e-4d66-9a50-2618621356b3	impressionism_default	Импрессионизм	1.0000	2026-07-18 09:57:22.187638+00	2026-07-18 09:57:22.187638+00	\N	1
d34e2a47-812c-49a8-be50-0789dccd5e15	2ec9a308-af86-4a01-a3ed-1710a5ac21dd	801d5718-54ec-44c7-85da-af53af4d7acc	cf6dc12e-5888-4bce-8ee6-7ff442c338cd	8c3f9ad2-241e-4d66-9a50-2618621356b3	baroque_default	Барокко	1.0000	2026-07-18 09:57:22.199656+00	2026-07-18 09:57:22.199656+00	\N	1
3c126f80-3c16-485d-bff6-3e4f33cc954a	94651f3c-c40a-4f85-a4e4-f21ba3737283	801d5718-54ec-44c7-85da-af53af4d7acc	cf6dc12e-5888-4bce-8ee6-7ff442c338cd	8c3f9ad2-241e-4d66-9a50-2618621356b3	cyberpunk_default	Киберпанк	1.0000	2026-07-18 09:57:22.212058+00	2026-07-18 09:57:22.212058+00	\N	1
169a1041-9c54-46ad-88ed-b629a8c0f575	e123000b-8bdb-49dc-a694-14330b7878c9	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	9b38ce00-114e-4c99-879f-90043a092471	8c3f9ad2-241e-4d66-9a50-2618621356b3	aurora_borealis_science	Северное сияние	1.0000	2026-07-18 09:57:22.226496+00	2026-07-18 09:57:22.226496+00	\N	1
f30f4ca7-c575-4f00-a5f5-dd6674882523	e7fdeb64-4db0-48fc-b2cb-bebd928dbd27	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	9b38ce00-114e-4c99-879f-90043a092471	8c3f9ad2-241e-4d66-9a50-2618621356b3	gravity_science	Гравитация	1.0000	2026-07-18 09:57:22.240063+00	2026-07-18 09:57:22.240063+00	\N	1
f0755ad0-ed8d-4ff9-ac6d-5f4d16d78395	8f6afea3-9bb8-4d9e-9265-31cf569b1c39	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	9b38ce00-114e-4c99-879f-90043a092471	8c3f9ad2-241e-4d66-9a50-2618621356b3	photosynthesis_science	Фотосинтез	1.0000	2026-07-18 09:57:22.251612+00	2026-07-18 09:57:22.251612+00	\N	1
07f2738a-6483-4614-b960-d841e7534792	afeb44a8-f93d-441b-b89f-fb51d1c9302f	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	9b38ce00-114e-4c99-879f-90043a092471	8c3f9ad2-241e-4d66-9a50-2618621356b3	evolution_science	Эволюция	1.0000	2026-07-18 09:57:22.263144+00	2026-07-18 09:57:22.263144+00	\N	1
9db0c533-dc6c-4d55-894e-b82a3dda258c	32b62974-af60-4ad1-853f-4b1e232d24a6	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	9b38ce00-114e-4c99-879f-90043a092471	8c3f9ad2-241e-4d66-9a50-2618621356b3	quantum_entanglement_science	Квантовая запутанность	1.0000	2026-07-18 09:57:22.275237+00	2026-07-18 09:57:22.275237+00	\N	1
9d44343f-0c8f-4703-b19b-9be0c3252020	f895fc34-79da-4fe2-81d9-5fc885a8096b	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	9b38ce00-114e-4c99-879f-90043a092471	8c3f9ad2-241e-4d66-9a50-2618621356b3	black_hole_science	Чёрная дыра	1.0000	2026-07-18 09:57:22.288909+00	2026-07-18 09:57:22.288909+00	\N	1
7e7f708f-f084-4de5-99e5-2314c0f22da6	23509af3-2a16-464d-ae37-17d962c7301d	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	9b38ce00-114e-4c99-879f-90043a092471	8c3f9ad2-241e-4d66-9a50-2618621356b3	tornado_science	Торнадо	1.0000	2026-07-18 09:57:22.300962+00	2026-07-18 09:57:22.300962+00	\N	1
f3229d89-5e9a-4381-9c23-77445a9dd63c	c4278647-d60c-4e2d-af89-6aae8bf5c233	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	9b38ce00-114e-4c99-879f-90043a092471	8c3f9ad2-241e-4d66-9a50-2618621356b3	continental_drift_science	Континентальный дрейф	1.0000	2026-07-18 09:57:22.313816+00	2026-07-18 09:57:22.313816+00	\N	1
92cc7207-261c-4da4-8ad5-da2a7d6da33a	21f5acd5-5d9a-414f-8692-14b59869f7f2	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	9b38ce00-114e-4c99-879f-90043a092471	8c3f9ad2-241e-4d66-9a50-2618621356b3	photosynthesis_process_science	Мечтательность	1.0000	2026-07-18 09:57:22.32488+00	2026-07-18 09:57:22.32488+00	\N	1
cadd0952-b817-4e2a-be79-241cc8884ecc	7dbf9236-1dd5-4785-abbd-92d3f0808d65	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	9b38ce00-114e-4c99-879f-90043a092471	8c3f9ad2-241e-4d66-9a50-2618621356b3	aurora_australis_science	Южное сияние	1.0000	2026-07-18 09:57:22.337182+00	2026-07-18 09:57:22.337182+00	\N	1
1f41633c-5685-41d0-9463-6444561e2361	2bd7a0b0-1e4b-4182-ab53-8f4a20e41f64	f3b13238-49e8-473a-8c6f-d424e36f197f	1fd64088-1ebc-4cbb-a6c3-5478a61edd19	8c3f9ad2-241e-4d66-9a50-2618621356b3	ancient_rome_history	Древний Рим	1.0000	2026-07-18 09:57:22.349959+00	2026-07-18 09:57:22.349959+00	\N	1
deca7c7e-7ce2-481d-b884-2b5ce6a71121	b170a449-4c28-467a-b410-611bb5c9b460	f3b13238-49e8-473a-8c6f-d424e36f197f	1fd64088-1ebc-4cbb-a6c3-5478a61edd19	8c3f9ad2-241e-4d66-9a50-2618621356b3	middle_ages_history	Средние века	1.0000	2026-07-18 09:57:22.35914+00	2026-07-18 09:57:22.35914+00	\N	1
13b03b32-816d-466e-83a9-953056d1db1c	bf444bcd-f2c5-4bd0-8d3f-503214fb8171	f3b13238-49e8-473a-8c6f-d424e36f197f	1fd64088-1ebc-4cbb-a6c3-5478a61edd19	8c3f9ad2-241e-4d66-9a50-2618621356b3	industrial_revolution_history	Промышленная революция	1.0000	2026-07-18 09:57:22.367958+00	2026-07-18 09:57:22.367958+00	\N	1
79ce2715-0539-4551-895a-5d9655496909	45457d27-05b9-4509-b7cb-445e0dd5e29a	f3b13238-49e8-473a-8c6f-d424e36f197f	1fd64088-1ebc-4cbb-a6c3-5478a61edd19	8c3f9ad2-241e-4d66-9a50-2618621356b3	cold_war_history	Холодная война	1.0000	2026-07-18 09:57:22.376491+00	2026-07-18 09:57:22.376491+00	\N	1
e1744e48-0205-4462-859a-67308c0b4972	6db2b35a-441a-4701-aef5-4a7d5a4d1887	f3b13238-49e8-473a-8c6f-d424e36f197f	1fd64088-1ebc-4cbb-a6c3-5478a61edd19	8c3f9ad2-241e-4d66-9a50-2618621356b3	renaissance_period_history	Эпоха Возрождения	1.0000	2026-07-18 09:57:22.385013+00	2026-07-18 09:57:22.385013+00	\N	1
5c283836-5b41-4203-837f-9897202e745f	8a72467e-4dfd-4696-890b-e82afd0d15ad	f3b13238-49e8-473a-8c6f-d424e36f197f	1fd64088-1ebc-4cbb-a6c3-5478a61edd19	8c3f9ad2-241e-4d66-9a50-2618621356b3	age_of_enlightenment_history	Эпоха Просвещения	1.0000	2026-07-18 09:57:22.393338+00	2026-07-18 09:57:22.393338+00	\N	1
e3a89c24-eebb-4d7c-a5c1-0d3be182d37e	cf3be10d-89e3-4104-b444-6f3161c09f6c	f3b13238-49e8-473a-8c6f-d424e36f197f	1fd64088-1ebc-4cbb-a6c3-5478a61edd19	8c3f9ad2-241e-4d66-9a50-2618621356b3	digital_age_history	Цифровая эра	1.0000	2026-07-18 09:57:22.402127+00	2026-07-18 09:57:22.402127+00	\N	1
7c7efeb5-8843-4ab1-8223-16c1dfcc3f60	b7f70d7a-6a4c-44df-ae95-b6b71cfd39b9	f3b13238-49e8-473a-8c6f-d424e36f197f	1fd64088-1ebc-4cbb-a6c3-5478a61edd19	8c3f9ad2-241e-4d66-9a50-2618621356b3	space_age_history	Эра освоения космоса	1.0000	2026-07-18 09:57:22.415702+00	2026-07-18 09:57:22.415702+00	\N	1
d31be51f-c2b2-4489-990d-e907eea9eee1	c18b2fcf-017d-464b-b29a-3c2fd2dfd156	f3b13238-49e8-473a-8c6f-d424e36f197f	1fd64088-1ebc-4cbb-a6c3-5478a61edd19	8c3f9ad2-241e-4d66-9a50-2618621356b3	world_war_2_history	Вторая мировая война	1.0000	2026-07-18 09:57:22.424673+00	2026-07-18 09:57:22.424673+00	\N	1
8255be6e-d5b3-4a82-82ab-f3c1100ffc12	8564232e-640e-42c5-a1df-0a339d9a409d	f3b13238-49e8-473a-8c6f-d424e36f197f	1fd64088-1ebc-4cbb-a6c3-5478a61edd19	8c3f9ad2-241e-4d66-9a50-2618621356b3	victorian_era_history	Викторианская эпоха	1.0000	2026-07-18 09:57:22.433955+00	2026-07-18 09:57:22.433955+00	\N	1
820103ab-0386-4a62-8f3e-e6a579dc9007	9787517a-941a-4525-af34-d54132e601d9	801d5718-54ec-44c7-85da-af53af4d7acc	89f1180b-d35f-402b-9d45-6d0d02172657	8c3f9ad2-241e-4d66-9a50-2618621356b3	readme_md_default	README.md	1.0000	2026-07-18 09:57:22.44454+00	2026-07-18 09:57:22.44454+00	\N	1
35e56d3e-ea70-4211-9982-cc6aefb0e274	ba56c9e9-ebf9-4d8c-8a23-ccfcc0951afc	801d5718-54ec-44c7-85da-af53af4d7acc	89f1180b-d35f-402b-9d45-6d0d02172657	8c3f9ad2-241e-4d66-9a50-2618621356b3	schema_sql_default	schema.sql	1.0000	2026-07-18 09:57:22.453984+00	2026-07-18 09:57:22.453984+00	\N	1
6d93b85d-a853-44e8-a52b-08f09ace7f7b	5a5da171-ced3-445b-882a-d2ec2c0873b8	801d5718-54ec-44c7-85da-af53af4d7acc	89f1180b-d35f-402b-9d45-6d0d02172657	8c3f9ad2-241e-4d66-9a50-2618621356b3	config_yaml_default	config.yaml	1.0000	2026-07-18 09:57:22.463039+00	2026-07-18 09:57:22.463039+00	\N	1
63f0b520-fb6e-4757-a25c-17ad2f056fb2	0664ab1a-77dd-46a7-a6e4-a80a7ea542d1	801d5718-54ec-44c7-85da-af53af4d7acc	89f1180b-d35f-402b-9d45-6d0d02172657	8c3f9ad2-241e-4d66-9a50-2618621356b3	docker_compose_default	docker-compose.yml	1.0000	2026-07-18 09:57:22.47219+00	2026-07-18 09:57:22.47219+00	\N	1
fadfcb95-3bfe-42e1-9d65-1cc339178d7e	3a4baf0a-e14c-4c20-a5d2-12c50e76cf57	801d5718-54ec-44c7-85da-af53af4d7acc	89f1180b-d35f-402b-9d45-6d0d02172657	8c3f9ad2-241e-4d66-9a50-2618621356b3	main_py_default	main.py	1.0000	2026-07-18 09:57:22.481811+00	2026-07-18 09:57:22.481811+00	\N	1
ef876a39-92b7-430f-8949-4a92c763a2b6	ba858154-8c3f-4f37-8bff-35c076aa8ada	801d5718-54ec-44c7-85da-af53af4d7acc	89f1180b-d35f-402b-9d45-6d0d02172657	8c3f9ad2-241e-4d66-9a50-2618621356b3	models_py_default	models.py	1.0000	2026-07-18 09:57:22.490643+00	2026-07-18 09:57:22.490643+00	\N	1
e2bcc25d-98fa-47b6-82b7-05259f93bf9e	b17d8c52-7170-4605-85a4-72531eff1b3f	801d5718-54ec-44c7-85da-af53af4d7acc	89f1180b-d35f-402b-9d45-6d0d02172657	8c3f9ad2-241e-4d66-9a50-2618621356b3	requirements_txt_default	requirements.txt	1.0000	2026-07-18 09:57:22.499927+00	2026-07-18 09:57:22.499927+00	\N	1
f0c4228a-f224-4022-a763-8e44babb1cf8	c85aa10c-655f-44f9-ae8a-1e430522ab2d	801d5718-54ec-44c7-85da-af53af4d7acc	89f1180b-d35f-402b-9d45-6d0d02172657	8c3f9ad2-241e-4d66-9a50-2618621356b3	dockerfile_default	Dockerfile	1.0000	2026-07-18 09:57:22.508514+00	2026-07-18 09:57:22.508514+00	\N	1
18a3742e-d28b-4e8d-9cc7-a3b723c7c35f	1253e359-3cf0-49d2-a279-d3153b4f00fe	801d5718-54ec-44c7-85da-af53af4d7acc	89f1180b-d35f-402b-9d45-6d0d02172657	8c3f9ad2-241e-4d66-9a50-2618621356b3	index_html_default	index.html	1.0000	2026-07-18 09:57:22.517278+00	2026-07-18 09:57:22.517278+00	\N	1
6d69a2b9-a1ad-4cb0-8e64-16f8327d1479	2b10e601-f4ac-4ae8-8ded-acb1d1571151	801d5718-54ec-44c7-85da-af53af4d7acc	89f1180b-d35f-402b-9d45-6d0d02172657	8c3f9ad2-241e-4d66-9a50-2618621356b3	style_css_default	style.css	1.0000	2026-07-18 09:57:22.525842+00	2026-07-18 09:57:22.525842+00	\N	1
1b68253c-bd69-4485-bde3-8984aa16db27	e14ae6a8-376a-4339-973c-fa37cfbb1543	801d5718-54ec-44c7-85da-af53af4d7acc	632c09d1-00d0-42ad-9faf-e30bbed6b025	8c3f9ad2-241e-4d66-9a50-2618621356b3	beat_generation_default	Поколение битников	1.0000	2026-07-18 09:57:22.537927+00	2026-07-18 09:57:22.537927+00	\N	1
2ff1ea42-8b82-4e46-bb6f-23ea77f573e6	f6ccda96-7cd1-4d68-b756-9db1d84a6f0c	801d5718-54ec-44c7-85da-af53af4d7acc	632c09d1-00d0-42ad-9faf-e30bbed6b025	8c3f9ad2-241e-4d66-9a50-2618621356b3	romanticism_default	Романтизм	1.0000	2026-07-18 09:57:22.548504+00	2026-07-18 09:57:22.548504+00	\N	1
5ce2be3e-75e7-4292-82fe-766aa1db594a	9a36665c-a89a-4829-b6a7-102628d64b9a	801d5718-54ec-44c7-85da-af53af4d7acc	632c09d1-00d0-42ad-9faf-e30bbed6b025	8c3f9ad2-241e-4d66-9a50-2618621356b3	cubism_default	Кубизм	1.0000	2026-07-18 09:57:22.557511+00	2026-07-18 09:57:22.557511+00	\N	1
2e1edec4-5526-4c1b-8bc2-fab57232bbcc	3ddb497c-72f1-4046-9264-d29911798e31	801d5718-54ec-44c7-85da-af53af4d7acc	632c09d1-00d0-42ad-9faf-e30bbed6b025	8c3f9ad2-241e-4d66-9a50-2618621356b3	punk_rock_default	Панк-рок	1.0000	2026-07-18 09:57:22.566042+00	2026-07-18 09:57:22.566042+00	\N	1
39ff10e1-4d9c-457b-af7e-4260aeac5fc4	99738373-5e27-466b-9e8c-d18b1d91e6e1	801d5718-54ec-44c7-85da-af53af4d7acc	632c09d1-00d0-42ad-9faf-e30bbed6b025	8c3f9ad2-241e-4d66-9a50-2618621356b3	impressionism_movement_default	Импрессионизм	1.0000	2026-07-18 09:57:22.577063+00	2026-07-18 09:57:22.577063+00	\N	1
add814c5-08a8-481a-ac3c-deba67a0ede0	dd3c64a4-6feb-4c74-ae8a-29764dab4e11	801d5718-54ec-44c7-85da-af53af4d7acc	632c09d1-00d0-42ad-9faf-e30bbed6b025	8c3f9ad2-241e-4d66-9a50-2618621356b3	existentialism_movement_default	Экзистенциализм	1.0000	2026-07-18 09:57:22.585409+00	2026-07-18 09:57:22.585409+00	\N	1
0f769c43-41b7-4d0f-bd9a-312563aab3b1	8483b889-21b6-4839-9b51-4845ae59e581	801d5718-54ec-44c7-85da-af53af4d7acc	632c09d1-00d0-42ad-9faf-e30bbed6b025	8c3f9ad2-241e-4d66-9a50-2618621356b3	minimalism_default	Минимализм	1.0000	2026-07-18 09:57:22.593537+00	2026-07-18 09:57:22.593537+00	\N	1
6edd0c35-7c35-4d15-b7ae-207a60091055	fc17dbbf-4e4a-48f4-aa77-28fabb1f19de	801d5718-54ec-44c7-85da-af53af4d7acc	632c09d1-00d0-42ad-9faf-e30bbed6b025	8c3f9ad2-241e-4d66-9a50-2618621356b3	hippie_movement_default	Движение хиппи	1.0000	2026-07-18 09:57:22.601696+00	2026-07-18 09:57:22.601696+00	\N	1
38a696a5-e8f0-419c-9244-eb3fd7d4a79d	387a24fa-f1d9-4737-8e54-f4a69578669b	801d5718-54ec-44c7-85da-af53af4d7acc	632c09d1-00d0-42ad-9faf-e30bbed6b025	8c3f9ad2-241e-4d66-9a50-2618621356b3	surrealism_movement_default	Сюрреализм	1.0000	2026-07-18 09:57:22.610637+00	2026-07-18 09:57:22.610637+00	\N	1
244fbf1f-1293-4478-901f-6698bc6178b7	b1f651d7-dbcd-48d2-8cbb-f29891f34d65	801d5718-54ec-44c7-85da-af53af4d7acc	632c09d1-00d0-42ad-9faf-e30bbed6b025	8c3f9ad2-241e-4d66-9a50-2618621356b3	renaissance_movement_default	Движение Возрождения	1.0000	2026-07-18 09:57:22.621208+00	2026-07-18 09:57:22.621208+00	\N	1
a787347f-b98b-4514-abe8-69369b46b9ff	3b0eda53-895f-4ea5-9204-406250784d76	801d5718-54ec-44c7-85da-af53af4d7acc	eeb13304-4fe8-49c8-8c26-f68090790677	8c3f9ad2-241e-4d66-9a50-2618621356b3	dewey_decimal_default	Десятичная классификация Дьюи	1.0000	2026-07-18 09:57:22.630945+00	2026-07-18 09:57:22.630945+00	\N	1
6709672a-8dc2-4e54-bc56-e229c0a395b9	1c9d6f07-3e36-4463-97c5-b5e92f6543a6	801d5718-54ec-44c7-85da-af53af4d7acc	eeb13304-4fe8-49c8-8c26-f68090790677	8c3f9ad2-241e-4d66-9a50-2618621356b3	iso_3166_default	ISO 3166	1.0000	2026-07-18 09:57:22.640752+00	2026-07-18 09:57:22.640752+00	\N	1
e9732eac-c03c-40ea-9d12-8067ebe90e21	a853de21-1a72-4c42-9a67-e2881ca2045d	801d5718-54ec-44c7-85da-af53af4d7acc	eeb13304-4fe8-49c8-8c26-f68090790677	8c3f9ad2-241e-4d66-9a50-2618621356b3	un_class_default	Классификация ООН	1.0000	2026-07-18 09:57:22.65244+00	2026-07-18 09:57:22.65244+00	\N	1
10584a76-69c8-4288-a2fa-4c053e179be5	6d983558-d3db-4047-8e24-6eed32da6c34	801d5718-54ec-44c7-85da-af53af4d7acc	eeb13304-4fe8-49c8-8c26-f68090790677	8c3f9ad2-241e-4d66-9a50-2618621356b3	iso_639_default	ISO 639	1.0000	2026-07-18 09:57:22.66303+00	2026-07-18 09:57:22.66303+00	\N	1
4e73f55c-87fe-48f2-b003-0ef724e011c1	1429e676-43c3-4639-a5ed-b5aa42a0fc9f	801d5718-54ec-44c7-85da-af53af4d7acc	eeb13304-4fe8-49c8-8c26-f68090790677	8c3f9ad2-241e-4d66-9a50-2618621356b3	periodic_table_default	Периодическая таблица	1.0000	2026-07-18 09:57:22.673262+00	2026-07-18 09:57:22.673262+00	\N	1
e8605b05-418d-435b-bc7c-4e52ed357ce0	2b840df2-219a-4b5c-8b08-5dddf8b262e1	801d5718-54ec-44c7-85da-af53af4d7acc	eeb13304-4fe8-49c8-8c26-f68090790677	8c3f9ad2-241e-4d66-9a50-2618621356b3	icd10_default	МКБ-10	1.0000	2026-07-18 09:57:22.683494+00	2026-07-18 09:57:22.683494+00	\N	1
bf872061-ae00-4b31-8d9a-81fb3b832099	995359be-1c66-40e0-8485-4ae46a31833d	801d5718-54ec-44c7-85da-af53af4d7acc	eeb13304-4fe8-49c8-8c26-f68090790677	8c3f9ad2-241e-4d66-9a50-2618621356b3	linnaeus_default	Классификация Линнея	1.0000	2026-07-18 09:57:22.692239+00	2026-07-18 09:57:22.692239+00	\N	1
7be545c6-e69a-4f23-b828-e8fc8ea9f400	75d72ab4-af98-4bfb-895a-d9506b772556	801d5718-54ec-44c7-85da-af53af4d7acc	eeb13304-4fe8-49c8-8c26-f68090790677	8c3f9ad2-241e-4d66-9a50-2618621356b3	bib_default	Библиотечная классификация	1.0000	2026-07-18 09:57:22.70184+00	2026-07-18 09:57:22.70184+00	\N	1
3767aa77-70b0-418a-8173-914b92356460	87e67f23-ea6c-4386-8b25-d05592d13f07	801d5718-54ec-44c7-85da-af53af4d7acc	eeb13304-4fe8-49c8-8c26-f68090790677	8c3f9ad2-241e-4d66-9a50-2618621356b3	nace_default	NACE	1.0000	2026-07-18 09:57:22.710287+00	2026-07-18 09:57:22.710287+00	\N	1
8ce61cf0-5b98-402f-867d-31ddbf0f15f6	9cff73c5-192f-4c24-ae22-55410dfb84ee	801d5718-54ec-44c7-85da-af53af4d7acc	eeb13304-4fe8-49c8-8c26-f68090790677	8c3f9ad2-241e-4d66-9a50-2618621356b3	atc_default	ATC	1.0000	2026-07-18 09:57:22.718763+00	2026-07-18 09:57:22.718763+00	\N	1
eb073520-b90b-432d-a8aa-55e1422efb7f	32463c6e-d667-4a73-947d-f17b775cba40	801d5718-54ec-44c7-85da-af53af4d7acc	2bcbb4b7-e2f1-40bb-aae6-3fc471ae31ec	8c3f9ad2-241e-4d66-9a50-2618621356b3	rosetta_stone_default	Розеттский камень	1.0000	2026-07-18 09:57:22.728546+00	2026-07-18 09:57:22.728546+00	\N	1
f676c81d-01f0-46f0-a227-c9d8e69e8eea	53129942-9866-4b71-a11f-3fb0b46bcb90	801d5718-54ec-44c7-85da-af53af4d7acc	2bcbb4b7-e2f1-40bb-aae6-3fc471ae31ec	8c3f9ad2-241e-4d66-9a50-2618621356b3	mona_lisa_default	Мона Лиза	1.0000	2026-07-18 09:57:22.736712+00	2026-07-18 09:57:22.736712+00	\N	1
35b74d23-209c-40b6-964d-deef2801855f	26cfcd3a-4a6e-4060-b5b2-869059eee7e9	801d5718-54ec-44c7-85da-af53af4d7acc	2bcbb4b7-e2f1-40bb-aae6-3fc471ae31ec	8c3f9ad2-241e-4d66-9a50-2618621356b3	great_wall_default	Великая Китайская стена	1.0000	2026-07-18 09:57:22.747956+00	2026-07-18 09:57:22.747956+00	\N	1
64a1914d-35a2-4a55-9373-670ceadca8c2	8a45830b-ad78-4487-89b0-ee7a962015a2	801d5718-54ec-44c7-85da-af53af4d7acc	2bcbb4b7-e2f1-40bb-aae6-3fc471ae31ec	8c3f9ad2-241e-4d66-9a50-2618621356b3	pyramid_giza_default	Пирамида Хеопса	1.0000	2026-07-18 09:57:22.756304+00	2026-07-18 09:57:22.756304+00	\N	1
c5d1dad4-04e1-4844-8304-4040c80c37e0	f50a0a19-4fb6-4125-b054-34a59fdde08e	801d5718-54ec-44c7-85da-af53af4d7acc	2bcbb4b7-e2f1-40bb-aae6-3fc471ae31ec	8c3f9ad2-241e-4d66-9a50-2618621356b3	colosseum_default	Колизей	1.0000	2026-07-18 09:57:22.764946+00	2026-07-18 09:57:22.764946+00	\N	1
0fff090f-f2f7-4271-b522-3909bfba4c17	16180497-666f-434d-bc7a-37bef39d6225	801d5718-54ec-44c7-85da-af53af4d7acc	2bcbb4b7-e2f1-40bb-aae6-3fc471ae31ec	8c3f9ad2-241e-4d66-9a50-2618621356b3	stonehenge_default	Стоунхендж	1.0000	2026-07-18 09:57:22.773062+00	2026-07-18 09:57:22.773062+00	\N	1
fd7800a4-ba48-4dca-a41c-1e3c237ccfd8	e6f19811-6f9f-4482-a529-2f3f8fb9e149	801d5718-54ec-44c7-85da-af53af4d7acc	2bcbb4b7-e2f1-40bb-aae6-3fc471ae31ec	8c3f9ad2-241e-4d66-9a50-2618621356b3	taj_mahal_default	Тадж-Махал	1.0000	2026-07-18 09:57:22.781448+00	2026-07-18 09:57:22.781448+00	\N	1
2b860475-e645-44f8-adc6-c67e447bbadc	1d2041fd-963a-4a0e-852a-b76f18b9d263	801d5718-54ec-44c7-85da-af53af4d7acc	2bcbb4b7-e2f1-40bb-aae6-3fc471ae31ec	8c3f9ad2-241e-4d66-9a50-2618621356b3	eiffel_tower_default	Эйфелева башня	1.0000	2026-07-18 09:57:22.792012+00	2026-07-18 09:57:22.792012+00	\N	1
a2dea906-3a9e-4e3c-8e63-15e21a2fac6c	17eb8177-4cb8-44cc-844e-280e2b6e34c6	801d5718-54ec-44c7-85da-af53af4d7acc	2bcbb4b7-e2f1-40bb-aae6-3fc471ae31ec	8c3f9ad2-241e-4d66-9a50-2618621356b3	liberty_statue_default	Статуя Свободы	1.0000	2026-07-18 09:57:22.800616+00	2026-07-18 09:57:22.800616+00	\N	1
9d015be3-a29f-4191-9f44-57a53cc20838	ff76ceeb-039c-4ad8-999d-7df99e8e7a47	801d5718-54ec-44c7-85da-af53af4d7acc	2bcbb4b7-e2f1-40bb-aae6-3fc471ae31ec	8c3f9ad2-241e-4d66-9a50-2618621356b3	parthenon_default	Парфенон	1.0000	2026-07-18 09:57:22.808756+00	2026-07-18 09:57:22.808756+00	\N	1
f7e30db2-8eac-4790-880b-6b4c0172f73e	192fa802-8d30-4838-a13a-e76acd3d5da4	801d5718-54ec-44c7-85da-af53af4d7acc	e542328a-f153-44f4-8d08-af52ac20dd63	8c3f9ad2-241e-4d66-9a50-2618621356b3	afghan_girl_default	Афганская девочка	1.0000	2026-07-18 09:57:22.81858+00	2026-07-18 09:57:22.81858+00	\N	1
b3db499b-52c6-4aa3-8332-bbdd8440c44f	c563b603-4af0-4b7c-9f7c-3fd70402e0d4	801d5718-54ec-44c7-85da-af53af4d7acc	e542328a-f153-44f4-8d08-af52ac20dd63	8c3f9ad2-241e-4d66-9a50-2618621356b3	earthrise_default	Восход Земли	1.0000	2026-07-18 09:57:22.828553+00	2026-07-18 09:57:22.828553+00	\N	1
988f7b04-9fee-4a58-a97d-05f2ec500ed3	7900ac07-0528-470c-aded-4760fb15d894	801d5718-54ec-44c7-85da-af53af4d7acc	e542328a-f153-44f4-8d08-af52ac20dd63	8c3f9ad2-241e-4d66-9a50-2618621356b3	v_j_day_default	V-J Day in Times Square	1.0000	2026-07-18 09:57:22.8372+00	2026-07-18 09:57:22.8372+00	\N	1
a48e421e-9175-4366-936e-da67380999f9	2c9edd9d-77c3-4839-9f12-46c2e252a5aa	801d5718-54ec-44c7-85da-af53af4d7acc	e542328a-f153-44f4-8d08-af52ac20dd63	8c3f9ad2-241e-4d66-9a50-2618621356b3	pale_blue_dot_default	Бледно-голубая точка	1.0000	2026-07-18 09:57:22.845756+00	2026-07-18 09:57:22.845756+00	\N	1
ee14d2c6-141d-433d-bea7-0aa723ed6cfa	18b40d02-87ec-4497-8b58-19e8f574d6cf	801d5718-54ec-44c7-85da-af53af4d7acc	e542328a-f153-44f4-8d08-af52ac20dd63	8c3f9ad2-241e-4d66-9a50-2618621356b3	migrant_mother_default	Мать-мигрантка	1.0000	2026-07-18 09:57:22.85498+00	2026-07-18 09:57:22.85498+00	\N	1
33de6134-121d-43d5-8f9f-a292cde9873e	8d600c86-9e46-487c-91fa-e688407d990c	801d5718-54ec-44c7-85da-af53af4d7acc	e542328a-f153-44f4-8d08-af52ac20dd63	8c3f9ad2-241e-4d66-9a50-2618621356b3	lunch_atop_skyscraper_default	Обед на небоскрёбе	1.0000	2026-07-18 09:57:22.864502+00	2026-07-18 09:57:22.864502+00	\N	1
30e396ec-8d08-4cd1-a2e3-41778530b690	40a23b6d-f3b6-465f-ae9c-4b0ce56dfad2	801d5718-54ec-44c7-85da-af53af4d7acc	e542328a-f153-44f4-8d08-af52ac20dd63	8c3f9ad2-241e-4d66-9a50-2618621356b3	flower_power_default	Сила цветов	1.0000	2026-07-18 09:57:22.874724+00	2026-07-18 09:57:22.874724+00	\N	1
1923538d-8765-4dde-91db-1db49b167272	cfd62e03-5400-47f5-95b2-8f53c1f33075	801d5718-54ec-44c7-85da-af53af4d7acc	e542328a-f153-44f4-8d08-af52ac20dd63	8c3f9ad2-241e-4d66-9a50-2618621356b3	the_kiss_default	Поцелуй	1.0000	2026-07-18 09:57:22.88914+00	2026-07-18 09:57:22.88914+00	\N	1
5050924d-c6a4-4b64-ab48-a3c99a24d164	6b9add19-73e1-4cf3-bb86-efbc215af007	801d5718-54ec-44c7-85da-af53af4d7acc	e542328a-f153-44f4-8d08-af52ac20dd63	8c3f9ad2-241e-4d66-9a50-2618621356b3	vulture_child_default	Стратегия выживания	1.0000	2026-07-18 09:57:22.902542+00	2026-07-18 09:57:22.902542+00	\N	1
799f49a7-e75a-4472-9e80-fe43558d3b6e	36ea6a1f-dd51-4f8a-94c7-8d1ce60f9ce1	801d5718-54ec-44c7-85da-af53af4d7acc	e542328a-f153-44f4-8d08-af52ac20dd63	8c3f9ad2-241e-4d66-9a50-2618621356b3	hubble_deep_field_default	Глубокое поле Хаббла	1.0000	2026-07-18 09:57:22.91583+00	2026-07-18 09:57:22.91583+00	\N	1
8ec1b810-4a02-4094-aa35-59bd2d164205	30ead965-9b99-451f-b4db-2e192fb7aded	801d5718-54ec-44c7-85da-af53af4d7acc	c309cf99-7d52-4cac-90b6-572abc26230d	8c3f9ad2-241e-4d66-9a50-2618621356b3	theory_relativity_default	Теория относительности	1.0000	2026-07-18 09:57:22.931832+00	2026-07-18 09:57:22.931832+00	\N	1
d98d8088-2272-4862-b6d9-7879b3eef47a	b1cef78e-be21-441b-9add-4af5569ac6b0	801d5718-54ec-44c7-85da-af53af4d7acc	c309cf99-7d52-4cac-90b6-572abc26230d	8c3f9ad2-241e-4d66-9a50-2618621356b3	origin_of_species_default	Происхождение видов	1.0000	2026-07-18 09:57:22.944099+00	2026-07-18 09:57:22.944099+00	\N	1
56157d73-329b-4f88-b899-aecbf70d2654	7d3c1b4d-0714-450f-a06b-9648b9cf2d90	801d5718-54ec-44c7-85da-af53af4d7acc	c309cf99-7d52-4cac-90b6-572abc26230d	8c3f9ad2-241e-4d66-9a50-2618621356b3	communist_manifesto_default	Манифест коммунистической партии	1.0000	2026-07-18 09:57:22.954039+00	2026-07-18 09:57:22.954039+00	\N	1
65ba9c87-4e23-4f87-8e34-2fb20ac42702	c2b27452-d479-4382-a750-93977d2b0e4a	801d5718-54ec-44c7-85da-af53af4d7acc	c309cf99-7d52-4cac-90b6-572abc26230d	8c3f9ad2-241e-4d66-9a50-2618621356b3	republic_plato_default	Государство	1.0000	2026-07-18 09:57:22.963927+00	2026-07-18 09:57:22.963927+00	\N	1
f73ddaf1-be62-46ad-893a-170d9d69d88e	4c122d28-61f6-4d69-b58f-d1d1dec02d02	801d5718-54ec-44c7-85da-af53af4d7acc	c309cf99-7d52-4cac-90b6-572abc26230d	8c3f9ad2-241e-4d66-9a50-2618621356b3	principia_default	Начала	1.0000	2026-07-18 09:57:22.972952+00	2026-07-18 09:57:22.972952+00	\N	1
1c6b2f47-da0e-4b9f-af33-9c2a6060915f	55d799fd-74d0-4545-93a0-539d3d44b700	801d5718-54ec-44c7-85da-af53af4d7acc	c309cf99-7d52-4cac-90b6-572abc26230d	8c3f9ad2-241e-4d66-9a50-2618621356b3	critique_pure_reason_default	Критика чистого разума	1.0000	2026-07-18 09:57:22.981716+00	2026-07-18 09:57:22.981716+00	\N	1
675fbc3a-84c1-4ef7-87de-e14ad644215c	b75c64b8-a707-41be-afc0-a585bde7e9b2	801d5718-54ec-44c7-85da-af53af4d7acc	c309cf99-7d52-4cac-90b6-572abc26230d	8c3f9ad2-241e-4d66-9a50-2618621356b3	wealth_of_nations_default	Исследование о природе и богатстве народов	1.0000	2026-07-18 09:57:22.99118+00	2026-07-18 09:57:22.99118+00	\N	1
789dbac1-0832-4c73-b666-377eb00af5f3	8b15e1c0-3472-420b-9b1a-8c1d5944e62c	801d5718-54ec-44c7-85da-af53af4d7acc	c309cf99-7d52-4cac-90b6-572abc26230d	8c3f9ad2-241e-4d66-9a50-2618621356b3	two_treatises_default	Два трактата о правлении	1.0000	2026-07-18 09:57:22.999753+00	2026-07-18 09:57:22.999753+00	\N	1
ab39ad23-3c9d-40c4-9b11-3b6bd47fef3f	0825a264-83a9-4413-bf50-a77c31ee2580	801d5718-54ec-44c7-85da-af53af4d7acc	c309cf99-7d52-4cac-90b6-572abc26230d	8c3f9ad2-241e-4d66-9a50-2618621356b3	the_wealth_default	Богатство народов	1.0000	2026-07-18 09:57:23.008035+00	2026-07-18 09:57:23.008035+00	\N	1
3781b6e9-be8e-4f39-a829-7a521a4a60f2	c770f360-33dc-45c2-b811-ab856cc0fc30	801d5718-54ec-44c7-85da-af53af4d7acc	c309cf99-7d52-4cac-90b6-572abc26230d	8c3f9ad2-241e-4d66-9a50-2618621356b3	das_kapital_default	Капитал	1.0000	2026-07-18 09:57:23.016573+00	2026-07-18 09:57:23.016573+00	\N	1
f2cb701c-b06e-4809-a8db-2447d463e4f2	42cac073-bfd6-420e-89a2-5eab703042b6	801d5718-54ec-44c7-85da-af53af4d7acc	7ec66c46-773b-4e6f-b12c-e448a31fe367	8c3f9ad2-241e-4d66-9a50-2618621356b3	albert_einstein_default	Альберт Эйнштейн	1.0000	2026-07-18 09:57:23.027149+00	2026-07-18 09:57:23.027149+00	\N	1
10802c9a-70df-48bf-806f-cc1c745b9094	739f01e6-af8e-49b4-9834-b2d981eda3c3	801d5718-54ec-44c7-85da-af53af4d7acc	7ec66c46-773b-4e6f-b12c-e448a31fe367	8c3f9ad2-241e-4d66-9a50-2618621356b3	leonardo_da_vinci_default	Леонардо да Винчи	1.0000	2026-07-18 09:57:23.037881+00	2026-07-18 09:57:23.037881+00	\N	1
f7184740-9ef9-4a4b-8d3e-de5d43b52c14	4c2a367e-3250-4e23-92a7-d25231d5baef	801d5718-54ec-44c7-85da-af53af4d7acc	7ec66c46-773b-4e6f-b12c-e448a31fe367	8c3f9ad2-241e-4d66-9a50-2618621356b3	isaac_newton_default	Исаак Ньютон	1.0000	2026-07-18 09:57:23.048903+00	2026-07-18 09:57:23.048903+00	\N	1
7f0cc4df-4709-40f3-869c-fbc7deb5cc1e	d0f8a70b-b1f7-48f4-95e6-3c58e4a86b2b	801d5718-54ec-44c7-85da-af53af4d7acc	7ec66c46-773b-4e6f-b12c-e448a31fe367	8c3f9ad2-241e-4d66-9a50-2618621356b3	nikola_tesla_default	Никола Тесла	1.0000	2026-07-18 09:57:23.058015+00	2026-07-18 09:57:23.058015+00	\N	1
e721b2c2-e06d-43d5-bb5c-ad59f5c71af2	7f3107e7-796b-490f-869a-5d71521bc46e	801d5718-54ec-44c7-85da-af53af4d7acc	7ec66c46-773b-4e6f-b12c-e448a31fe367	8c3f9ad2-241e-4d66-9a50-2618621356b3	marie_curie_default	Мария Кюри	1.0000	2026-07-18 09:57:23.067991+00	2026-07-18 09:57:23.067991+00	\N	1
086071ba-c0f7-4348-9b3a-12b4dc86e89b	c744a36a-9aa5-4d60-8896-242132e90ac5	801d5718-54ec-44c7-85da-af53af4d7acc	7ec66c46-773b-4e6f-b12c-e448a31fe367	8c3f9ad2-241e-4d66-9a50-2618621356b3	charles_darwin_default	Чарльз Дарвин	1.0000	2026-07-18 09:57:23.077397+00	2026-07-18 09:57:23.077397+00	\N	1
a235661b-fdc8-465b-ac30-0d6898ce5e9e	602e8d7d-ec89-4c85-80cf-7ae822b18f58	801d5718-54ec-44c7-85da-af53af4d7acc	7ec66c46-773b-4e6f-b12c-e448a31fe367	8c3f9ad2-241e-4d66-9a50-2618621356b3	plato_default	Платон	1.0000	2026-07-18 09:57:23.088636+00	2026-07-18 09:57:23.088636+00	\N	1
95391e2c-a4f6-4dce-aead-586b409ec3a2	92039fd9-1eaa-4d7e-ac10-268281afd9ac	801d5718-54ec-44c7-85da-af53af4d7acc	7ec66c46-773b-4e6f-b12c-e448a31fe367	8c3f9ad2-241e-4d66-9a50-2618621356b3	shakespeare_default	Уильям Шекспир	1.0000	2026-07-18 09:57:23.100194+00	2026-07-18 09:57:23.100194+00	\N	1
1d926d21-2f6f-4f7e-82fd-a80b9c74e842	4ad80497-ccd6-4371-ab57-96d8b91e9a09	801d5718-54ec-44c7-85da-af53af4d7acc	7ec66c46-773b-4e6f-b12c-e448a31fe367	8c3f9ad2-241e-4d66-9a50-2618621356b3	confucius_default	Конфуций	1.0000	2026-07-18 09:57:23.111276+00	2026-07-18 09:57:23.111276+00	\N	1
2070e2bd-ef21-4759-8f01-61b38932d500	04ca95fc-d46c-41a1-bb8a-a9932fdc0fbb	801d5718-54ec-44c7-85da-af53af4d7acc	7ec66c46-773b-4e6f-b12c-e448a31fe367	8c3f9ad2-241e-4d66-9a50-2618621356b3	mahatma_gandhi_default	Махатма Ганди	1.0000	2026-07-18 09:57:23.1233+00	2026-07-18 09:57:23.1233+00	\N	1
9bd52dcc-062a-488d-8651-ca4cd190e306	8a532ed1-c830-427c-a8ad-2e73a4f3a0b2	801d5718-54ec-44c7-85da-af53af4d7acc	299c6997-5335-4646-9e71-3786184ca5c9	8c3f9ad2-241e-4d66-9a50-2618621356b3	picasso_default	Пабло Пикассо	1.0000	2026-07-18 09:57:23.136543+00	2026-07-18 09:57:23.136543+00	\N	1
faa776f9-6678-4836-b937-6b245c6704c0	f9650917-3e26-4be7-a635-ef4886cbc18f	801d5718-54ec-44c7-85da-af53af4d7acc	299c6997-5335-4646-9e71-3786184ca5c9	8c3f9ad2-241e-4d66-9a50-2618621356b3	van_gogh_default	Винсент Ван Гог	1.0000	2026-07-18 09:57:23.148874+00	2026-07-18 09:57:23.148874+00	\N	1
c4502aa7-8e2e-46ce-9ecb-3a311f67ccab	1de91eb3-e5ed-439f-9630-b14cb1abf490	801d5718-54ec-44c7-85da-af53af4d7acc	299c6997-5335-4646-9e71-3786184ca5c9	8c3f9ad2-241e-4d66-9a50-2618621356b3	monet_default	Клод Моне	1.0000	2026-07-18 09:57:23.160893+00	2026-07-18 09:57:23.160893+00	\N	1
d8ce2c13-86e4-4ec3-82ed-d26909f78d1d	bab8e621-eb12-4d5c-9f1d-6bcdefb375a0	801d5718-54ec-44c7-85da-af53af4d7acc	299c6997-5335-4646-9e71-3786184ca5c9	8c3f9ad2-241e-4d66-9a50-2618621356b3	michelangelo_default	Микеланджело	1.0000	2026-07-18 09:57:23.172121+00	2026-07-18 09:57:23.172121+00	\N	1
235d5de7-86b9-4e5d-99da-014f788d8171	6d43a160-64d9-431f-ad10-8b012f01f15b	801d5718-54ec-44c7-85da-af53af4d7acc	299c6997-5335-4646-9e71-3786184ca5c9	8c3f9ad2-241e-4d66-9a50-2618621356b3	rembrandt_default	Рембрандт	1.0000	2026-07-18 09:57:23.183717+00	2026-07-18 09:57:23.183717+00	\N	1
a35eb241-6074-4428-ad18-324e0498f7dc	bea2edde-5ade-474a-b441-ff5ef24a6627	801d5718-54ec-44c7-85da-af53af4d7acc	299c6997-5335-4646-9e71-3786184ca5c9	8c3f9ad2-241e-4d66-9a50-2618621356b3	salvador_dali_default	Сальвадор Дали	1.0000	2026-07-18 09:57:23.195259+00	2026-07-18 09:57:23.195259+00	\N	1
5e504d44-75f5-4845-b518-ee7c5cf09cac	ce480988-cdc7-4ce0-9e70-9d0422f85c3a	801d5718-54ec-44c7-85da-af53af4d7acc	299c6997-5335-4646-9e71-3786184ca5c9	8c3f9ad2-241e-4d66-9a50-2618621356b3	andy_warhol_default	Энди Уорхол	1.0000	2026-07-18 09:57:23.205151+00	2026-07-18 09:57:23.205151+00	\N	1
ba3de29a-9eaa-496e-a420-939e09a9cfe8	5901e379-0867-4b89-aa06-5741498f67e7	801d5718-54ec-44c7-85da-af53af4d7acc	299c6997-5335-4646-9e71-3786184ca5c9	8c3f9ad2-241e-4d66-9a50-2618621356b3	frida_kahlo_default	Фрида Кало	1.0000	2026-07-18 09:57:23.216567+00	2026-07-18 09:57:23.216567+00	\N	1
49d0ef05-c628-4795-9b44-3f0741512e55	29d6595c-a8df-49df-912b-555eb61dc11c	801d5718-54ec-44c7-85da-af53af4d7acc	299c6997-5335-4646-9e71-3786184ca5c9	8c3f9ad2-241e-4d66-9a50-2618621356b3	kandinsky_default	Василий Кандинский	1.0000	2026-07-18 09:57:23.226228+00	2026-07-18 09:57:23.226228+00	\N	1
d636a9d1-d027-4ba0-8221-1e6948d1248a	bf8fa84f-ed54-41e4-9a47-bd082fd9c6df	801d5718-54ec-44c7-85da-af53af4d7acc	299c6997-5335-4646-9e71-3786184ca5c9	8c3f9ad2-241e-4d66-9a50-2618621356b3	caravaggio_default	Караваджо	1.0000	2026-07-18 09:57:23.235606+00	2026-07-18 09:57:23.235606+00	\N	1
49d50382-9dbe-47a7-8252-69d9d0fd4d8c	51db8499-cdd6-48b8-ae65-e05a29e3a2e8	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	f5029531-afe8-4bec-9f1b-acf88351e99b	8c3f9ad2-241e-4d66-9a50-2618621356b3	stephen_hawking_science	Стивен Хокинг	1.0000	2026-07-18 09:57:23.247664+00	2026-07-18 09:57:23.247664+00	\N	1
7889b8e3-dc41-4d5f-a819-fdfc3896c143	b5cddb03-0bb2-43d3-ac04-c7b2c70c53df	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	f5029531-afe8-4bec-9f1b-acf88351e99b	8c3f9ad2-241e-4d66-9a50-2618621356b3	richard_feynman_science	Ричард Фейнман	1.0000	2026-07-18 09:57:23.258498+00	2026-07-18 09:57:23.258498+00	\N	1
ab5d2722-934c-4119-8bf2-0827b8ad05f9	1af61118-34a1-4bf9-8988-26f85ba06f48	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	f5029531-afe8-4bec-9f1b-acf88351e99b	8c3f9ad2-241e-4d66-9a50-2618621356b3	darwin_scientist_science	Чарльз Дарвин	1.0000	2026-07-18 09:57:23.268399+00	2026-07-18 09:57:23.268399+00	\N	1
80255719-a52e-4cda-a615-8d2f5d82ae25	7cc15fa4-879b-456b-8481-63cd73605e34	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	f5029531-afe8-4bec-9f1b-acf88351e99b	8c3f9ad2-241e-4d66-9a50-2618621356b3	niels_bohr_science	Нильс Бор	1.0000	2026-07-18 09:57:23.27719+00	2026-07-18 09:57:23.27719+00	\N	1
cc67c4bb-57a8-4f7b-8a73-35953636f992	4e603c34-e64c-4cb9-bf8a-f73a36ca1b39	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	f5029531-afe8-4bec-9f1b-acf88351e99b	8c3f9ad2-241e-4d66-9a50-2618621356b3	max_planck_science	Макс Планк	1.0000	2026-07-18 09:57:23.286365+00	2026-07-18 09:57:23.286365+00	\N	1
200a298c-d70b-4397-9010-d83132d034a2	d8e2ddde-de40-40bc-a501-f9818e0b7cf6	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	f5029531-afe8-4bec-9f1b-acf88351e99b	8c3f9ad2-241e-4d66-9a50-2618621356b3	dmitri_mendeleev_science	Дмитрий Менделеев	1.0000	2026-07-18 09:57:23.295935+00	2026-07-18 09:57:23.295935+00	\N	1
542287c6-0516-46fa-9bb4-5b8b66e46a9d	31dfc80c-4ec5-43c1-ae1e-4b634c8209bd	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	f5029531-afe8-4bec-9f1b-acf88351e99b	8c3f9ad2-241e-4d66-9a50-2618621356b3	galileo_science	Галилео Галилей	1.0000	2026-07-18 09:57:23.305371+00	2026-07-18 09:57:23.305371+00	\N	1
001fa3ac-0136-4486-8026-85c1e9854d1d	badce0e7-49fd-4253-8069-82e9509d4ad6	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	f5029531-afe8-4bec-9f1b-acf88351e99b	8c3f9ad2-241e-4d66-9a50-2618621356b3	linus_pauling_science	Лайнус Полинг	1.0000	2026-07-18 09:57:23.315921+00	2026-07-18 09:57:23.315921+00	\N	1
47b53aa6-6284-4484-95bf-2e4dcd783368	6c1b7a1d-a4c5-453e-afd7-3ff02e6b1eda	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	f5029531-afe8-4bec-9f1b-acf88351e99b	8c3f9ad2-241e-4d66-9a50-2618621356b3	rosalind_franklin_science	Розалинд Франклин	1.0000	2026-07-18 09:57:23.326235+00	2026-07-18 09:57:23.326235+00	\N	1
f345eda5-502f-44f7-9c77-f086cb557db2	1458508b-bd19-4996-be27-1a87860aec35	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	f5029531-afe8-4bec-9f1b-acf88351e99b	8c3f9ad2-241e-4d66-9a50-2618621356b3	alan_turing_science	Алан Тьюринг	1.0000	2026-07-18 09:57:23.338464+00	2026-07-18 09:57:23.338464+00	\N	1
f8dd01e5-b4f2-46e3-9973-62b552dd2f83	24a3b922-3ba0-4077-b0db-6eea4d22beca	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_24a3b9223ba0	Золотой.телёнок	1.0000	2026-07-18 19:56:54.496536+00	2026-07-18 19:56:54.496539+00	\N	1
26b0c3c3-7bcf-42f4-bb74-31a20dd09a9c	ccfb8bb4-73cc-4269-86aa-88371c4485b6	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_ccfb8bb473cc	Доспехи бога	1.0000	2026-07-18 19:58:38.233924+00	2026-07-18 19:58:38.233926+00	\N	1
3a70d853-b7f1-4213-beab-7e1c5737aa52	1ea63bec-f46d-43d4-bfce-ec55c7e3b96c	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_1ea63becf46d	Гремлины	1.0000	2026-07-18 19:58:38.269759+00	2026-07-18 19:58:38.269761+00	\N	1
19c13cdf-67f8-453a-b68b-b3526271bcc4	8877988a-cc00-4360-902c-b9236ef36f1c	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_8877988acc00	Тяжелый.Металл	1.0000	2026-07-18 19:58:38.299398+00	2026-07-18 19:58:38.299402+00	\N	1
d77a6734-3389-4079-aa7e-773f2842ac5f	058e03ee-0404-4bc5-b449-260f1f29e6a1	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_058e03ee0404	Приключения.Электроника	1.0000	2026-07-18 19:58:38.330265+00	2026-07-18 19:58:38.330268+00	\N	1
ebbbff84-c895-41f5-ae0b-1bebe8e217aa	5ceefbba-b512-467e-9bbb-2f8a537bd2b9	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_5ceefbbab512	Taxi	1.0000	2026-07-18 19:58:38.357754+00	2026-07-18 19:58:38.357757+00	\N	1
6a89f51d-0834-4689-8b20-42eed4b812ae	50560847-3cfc-414b-8659-222fe703e181	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_content_proj	Контент (Markdown)	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	31
95ca7c07-bdd8-4406-b84e-28195aa9cd5e	f8dec4ff-ef2d-4c25-9985-ce576f01fce6	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_age_rating_proj	Возрастной рейтинг	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	32
4bf10d13-0ee7-4664-b4d8-b66bfafdd520	5b3db321-e48a-4fd2-8bbf-73edb79e93c9	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_version_proj	Версия	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	33
371ad544-6943-433f-b369-de19b08c5fbc	3695518e-aa08-4f99-8421-62fb84454a6c	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_license_proj	Лицензия	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	34
90a817d3-7618-4a6d-9774-8db27270da6f	c897e8e5-2f44-47e7-b93e-c3240967f793	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_repository_url_proj	URL репозитория	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	35
615434d0-7fef-4b06-b981-acd9022cc588	7e1abafa-5000-47eb-96ed-f65f268d2c3f	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_programming_language_proj	Язык программирования	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	36
484f4eae-18c0-468b-bb82-498581abebb3	e45d48bc-398f-4c4f-aa41-259ddf8fd143	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_platform_proj	Платформа	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	37
1e59b752-79f2-4c5e-8535-dc94ea6457fd	6cd97c90-dd19-4c1c-848d-2dfa70eeb9c0	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_developer_proj	Разработчик	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	38
492fc7d4-17ee-436b-839b-585911c3f534	621a6f31-c9b5-4a63-805e-eca92ce9814e	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_event_date_proj	Дата события	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	39
1fed5c68-3256-4190-974e-13aab829cd1b	a2b6152e-388d-496c-9972-a3c3a7d6e6e7	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_event_end_date_proj	Дата окончания	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	40
9cb5574a-9d68-4e52-88e6-86df8fc9c042	834fa7cd-5b92-4849-9522-7d5e9d9df64b	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_venue_proj	Место проведения	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	41
80741c32-8c89-4a1b-ba0b-dd5229c3d350	5db2a94e-43a7-49c7-96fa-8c60cb1152ed	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_organizer_proj	Организатор	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	42
2ff0d1ca-25db-4cfa-916a-3b8e7320a5dc	efbc604f-c1e3-425d-b0d6-f3c7281c2d95	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_attendee_count_proj	Число участников	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	43
67c78432-6fe5-4e99-ad28-c3b0ca0f0aed	10d0b551-2b83-42d6-a983-c3465cb16f94	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_ticket_price_proj	Цена билета	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	44
5c7bed9a-99fa-47c1-a536-93ef4efbd723	8c450ef6-a30b-4fc4-a0e9-397908ac32fb	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_game_engine_proj	Игровой движок	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	45
8337e034-fd16-4929-b347-a880acd18de7	51611186-f6ba-473f-b5bd-92b8ac47271e	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_platform_list_proj	Платформы	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	46
8e7e8675-8148-471f-a774-3c7778ca6814	7a44f578-6a88-4b63-b0df-a69b1a0820de	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_player_count_proj	Кол-во игроков	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	47
29d1489d-3e09-4344-816b-2dc40e4aaec4	cfb13f53-8d02-4bb1-a857-ae5f32400de1	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_esrb_rating_proj	Рейтинг ESRB	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	48
a9a71003-f04a-4955-8134-ab6edc4936d9	c21b5e7b-9139-4449-9779-7e1faa9909a9	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_latitude_proj	Широта	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	49
79a3c791-db99-41cf-8b1c-c36f24f2c311	dd58db39-620a-4dcc-b6db-53b0d6fc6d32	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_longitude_proj	Долгота	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	50
ab8b1931-8121-4f85-8013-74e7d8b4b030	672956aa-18e5-4de8-b812-0f025a815a62	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_elevation_m_proj	Высота (м)	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	51
384ae166-d14f-4651-9895-24eda080e68f	5c7b2aab-226c-40ec-9d67-aefa5cbc5cfb	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_timezone_proj	Часовой пояс	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	52
26de2206-78e6-4a79-b30c-13886de6b364	83393a4c-4dac-4e25-9c5d-0992ff381746	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_area_km2_proj	Площадь (км²)	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	53
e8e8e9d3-1abe-4ec6-8e9b-7fd910c1b9ed	d2356d9e-df72-4cb5-bf34-f895df20056e	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_population_proj	Население	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	54
9d229778-1624-499e-90c9-dc084b168c83	d3313362-0c00-49e9-92e7-7bd6d47cddc1	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_postal_code_proj	Почтовый индекс	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	55
2228b134-2e7a-43b7-88f8-571181f950f6	2d134f2b-010a-4fe2-bf12-ee93dc343850	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_iso_code_proj	ISO код	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	56
87c617b9-5519-4547-8ac1-f00a75a2c2b7	64a70b92-8c8e-4763-9542-7f520cabc9da	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_publisher_proj	Издатель	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	57
3a385266-3bce-4142-8fdf-621b4c8d520f	41858589-b5ed-41bd-946d-e75f457e62d3	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_publication_city_proj	Город издания	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	58
9f026194-d5d6-463c-92b9-8054457151c7	9141ee3c-c83d-4730-8828-416d8385a973	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_edition_proj	Издание	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	59
1d58a9ef-d735-4bd3-bd33-2842c8915ba1	b837ade1-ac04-4ed3-a631-8a6b9c2e5291	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_translator_proj	Переводчик	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	60
d654e391-c767-4921-8561-2c413eb1258f	05bac44f-54b7-42b9-8e4e-e30d0b103efb	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_original_language_proj	Язык оригинала	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	61
482f6a8a-b030-421c-b6fc-305ed48919a0	6a28f029-ddc2-4120-8fe7-28a1b361cb4d	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_dewey_decimal_proj	Десятичный код Дьюи	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	62
d22c2238-4232-4afe-8d00-b1693d1b30c4	1c9f03b8-2309-4b59-ac26-ea5ba2b1024e	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_poster_url_proj	Постер	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	63
b492c9c8-0350-4767-9266-fdd41792f2c2	369fe9c8-7839-432d-b1e0-b23c34ba53b3	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_images_proj	Изображения	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	64
cae416c5-f4bb-4856-8b13-ace066ab380f	e965c7bd-f8f4-4bbf-b4a5-1b51abf8c1fc	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_video_url_proj	Видео	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	65
e0000008-0000-0000-0000-000000000002	d0000008-0000-0000-0000-000000000002	4264c67d-7bbe-49af-9df3-0289d61f4477	3330b5d5-ef3c-43d5-b0e8-42f7fc6c8b1b	\N	herbert-lit	Writer Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000008-0000-0000-0000-000000000001	d0000008-0000-0000-0000-000000000001	4264c67d-7bbe-49af-9df3-0289d61f4477	3330b5d5-ef3c-43d5-b0e8-42f7fc6c8b1b	\N	gibson-lit	Writer Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000009-0000-0000-0000-000000000003	d0000009-0000-0000-0000-000000000003	96ffa67d-b033-4950-89e6-d35cff76da25	99662b06-1284-4d5c-878c-ef1cd804ebc3	\N	tokyo-geo	Geography Data	0.9500	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000009-0000-0000-0000-000000000002	d0000009-0000-0000-0000-000000000002	96ffa67d-b033-4950-89e6-d35cff76da25	99662b06-1284-4d5c-878c-ef1cd804ebc3	\N	paris-geo	Geography Data	0.9500	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000009-0000-0000-0000-000000000001	d0000009-0000-0000-0000-000000000001	96ffa67d-b033-4950-89e6-d35cff76da25	99662b06-1284-4d5c-878c-ef1cd804ebc3	\N	moscow-geo	Geography Data	0.9500	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000010-0000-0000-0000-000000000003	d0000010-0000-0000-0000-000000000003	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	55610502-a3ce-4f51-a842-834c9fd46cc9	\N	carbon-sci	Science Data	0.9800	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000010-0000-0000-0000-000000000002	d0000010-0000-0000-0000-000000000002	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	55610502-a3ce-4f51-a842-834c9fd46cc9	\N	oxygen-sci	Science Data	0.9800	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000010-0000-0000-0000-000000000001	d0000010-0000-0000-0000-000000000001	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	55610502-a3ce-4f51-a842-834c9fd46cc9	\N	hydrogen-sci	Science Data	0.9800	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000011-0000-0000-0000-000000000003	d0000011-0000-0000-0000-000000000003	801d5718-54ec-44c7-85da-af53af4d7acc	313cdb66-75e2-459d-9696-71785601e875	\N	dolphin-bio	Biology Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000011-0000-0000-0000-000000000002	d0000011-0000-0000-0000-000000000002	801d5718-54ec-44c7-85da-af53af4d7acc	313cdb66-75e2-459d-9696-71785601e875	\N	eagle-bio	Biology Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000011-0000-0000-0000-000000000001	d0000011-0000-0000-0000-000000000001	801d5718-54ec-44c7-85da-af53af4d7acc	313cdb66-75e2-459d-9696-71785601e875	\N	wolf-bio	Biology Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000006-0000-0000-0000-000000000002	d0000006-0000-0000-0000-000000000002	102715a7-994b-46fe-87cf-9a21487d74cd	ed80002b-3429-4270-80c7-622540dddfcc	\N	greatest-hits-music	Album Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000006-0000-0000-0000-000000000001	d0000006-0000-0000-0000-000000000001	102715a7-994b-46fe-87cf-9a21487d74cd	ed80002b-3429-4270-80c7-622540dddfcc	\N	night-opera-music	Album Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000013-0000-0000-0000-000000000003	d0000013-0000-0000-0000-000000000003	801d5718-54ec-44c7-85da-af53af4d7acc	3d22c910-caff-462e-bc8f-f156bc5479eb	\N	ai-concept	Concept Data	0.8500	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000026-0000-0000-0000-000000000001	d0000026-0000-0000-0000-000000000001	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	warner-bros-org	Organization Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
e0000026-0000-0000-0000-000000000002	d0000026-0000-0000-0000-000000000002	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	paris-opera-org	Organization Data	0.9000	2026-07-18 09:57:12.396086+00	2026-07-18 09:57:12.396086+00	\N	1
559d4c25-704b-4f2e-a06f-751cf9e87f24	387fb842-3e32-462c-a70a-714bab27a2eb	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_387fb8423e32	Тот.самый.Мюнхгаузен	1.0000	2026-07-18 20:05:45.203444+00	2026-07-18 20:05:45.203448+00	\N	1
f9989eb6-17c9-453a-8e19-606cb2e54766	8f5afa8d-d5cf-41b8-9330-7794bdfa761e	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_8f5afa8dd5cf	Не.бойся,.я.с.тобой.(1981)	1.0000	2026-07-18 20:05:45.235411+00	2026-07-18 20:05:45.235416+00	\N	1
e102ba10-6052-48bb-a7e1-c624a3ccd485	64a2dfe2-ea09-492c-8302-3e0c92e24c8d	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_64a2dfe2ea09	3840x	1.0000	2026-07-18 20:05:45.276837+00	2026-07-18 20:05:45.276839+00	\N	1
70cfc28d-d4b3-461a-9137-9764c3f8344c	e2c3c575-32e2-4e12-83da-f0bfb086ef24	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_e2c3c57532e2	призрак в доспехах	1.0000	2026-07-18 20:19:04.994101+00	2026-07-18 20:19:04.994104+00	\N	1
33705540-a911-4a4f-a671-11528b1721b0	708d1c90-2f73-4757-9a0f-3319350d3d74	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_audio_url_proj	Аудио	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	66
21383ea7-9d46-40aa-978f-a1b8483eed2f	8762c43d-8e8e-4977-9e69-f1c77e3baa41	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_file_url_proj	Файл	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	67
1810fe56-1c22-4e85-a4e3-b9a243b07fb5	e2a1125f-8457-4fcc-8b2d-be5fe38d6810	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_file_title_proj	Название файла	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	68
58c99745-40c2-43ac-9853-567fc2be8b91	9cdf7eb1-420b-4c77-9af3-8ca575b58ad8	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_episode_number_proj	Номер эпизода	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	69
11b4df6d-2ef1-43ae-8969-189dacad2995	eec27388-96e1-4d80-8356-0ce7fea2bf22	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_season_number_proj	Номер сезона	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	70
6777ba71-9878-4308-b161-4617e06314f3	0b25635d-07c0-424c-84c4-88c06b6231e7	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_podcast_url_proj	URL подкаста	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	71
ed260cb0-5287-455b-b965-6cdb0116c330	3674cffb-1308-4671-a49d-9de30d991615	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_channel_url_proj	URL канала	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	72
ccef9f98-353c-4c09-b4a3-65d90cd80fea	5f2fad97-43d9-463d-a326-9578ff29b8ee	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_artist_proj	Исполнитель	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	73
aecd4f88-a028-4cec-9f91-94d6ac3948c8	279b4865-bd06-4be5-ab2e-03284416eb70	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_album_proj	Альбом	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	74
8544fcbb-7059-4a63-b1b6-8186b6b576a5	54db1b64-d1f1-4c4b-a51f-ff17989d10fa	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_bpm_proj	BPM	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	75
12ef5fcd-7210-40de-abd2-4c40e8bd9a18	e4fa9e7b-84e8-4284-b09f-5ae2fc98d1d4	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_isrc_proj	ISRC	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	76
d65d5a5c-43bd-4d71-b2b7-2942b5f3476e	ed532ab3-134a-4e40-8a83-82b057a0b5f5	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_iswc_proj	ISWC	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	77
88589abb-9bec-4664-8ad8-cbd801dd0810	91b6d7e4-b4b5-4604-b8d2-b0e548370229	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_track_number_proj	Номер трека	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	78
11773243-6369-4263-876f-9db7b55cf699	0c731b79-48f7-4cd5-9ee6-7cddcbc4059e	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_disc_number_proj	Номер диска	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	79
2c57fddf-b66d-4630-a152-8b8261567361	f122a48c-6683-4cde-944e-200fadccafac	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_explicit_proj	Есть нецензурный контент	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	80
3e5da6e4-1596-4c0e-a4b9-410cb4dc5ea6	fde1ecd4-ccb9-48f8-bcf0-2c7b788dd6ab	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_key_signature_proj	Тональность	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	81
7309d0a4-4ac8-426f-8e6f-332e37491cc5	65e96845-dad5-4e31-ad2e-fd8eaf9594ca	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_time_signature_proj	Размерность	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	82
76b46f0a-9f15-4bb1-8ee7-ac707fb27182	e2ba9020-2019-4ca9-a1c3-bfe04b285b0a	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_label_name_proj	Лейбл	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	83
1b3f033f-5210-44b9-9e1c-c62e28cd4403	e82819ac-b840-4323-8573-7e08c9d24f18	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_founding_date_proj	Дата основания	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	84
cd16a2da-ac67-4906-9a7d-4016d3b0e292	aa8a9231-caf4-4c65-8d6b-a2cc5fd47a31	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_dissolution_date_proj	Дата роспуска	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	85
dcc5d2f4-6295-474d-af9a-98d3a84f646e	84d76e43-7d13-41f1-9e85-b8e4b65e0d1c	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_founder_proj	Основатель	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	86
551802fa-72aa-4092-9c0c-657d77486af8	ce740df6-b817-457a-8dc8-f47a174a45cb	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_industry_proj	Отрасль	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	87
c626d9f2-3236-41c7-b6ee-199763f329e0	1b99e712-73f8-4f74-8ac2-2f734c21dc61	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_employee_count_proj	Число сотрудников	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	88
d9741933-745a-4384-b37e-da726a36a224	aca43b1c-341f-4b10-af2a-6801719bd242	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_headquarters_proj	Штаб-квартира	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	89
a27e21d9-9ded-421f-8668-c4c2f35aaa4d	501d186a-f239-454c-ab02-dad26ab85263	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_first_name_proj	Имя	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	90
2ec64319-39be-454b-bf9a-41a61d6a5f02	9be46b9f-0097-46ce-bb31-9b92339e3bd0	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_last_name_proj	Фамилия	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	91
94d5c309-867a-4c9e-9ad1-32a5e34fd348	c7eb9698-deeb-4f2a-8d40-4190006c55c8	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_patronymic_proj	Отчество	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	92
f0000026-0000-0000-0000-000000000003	d0000026-0000-0000-0000-000000000003	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	disney-org	Organization Data	0.9000	2026-07-18 09:57:12.946973+00	2026-07-18 09:57:12.946973+00	\N	1
f0000026-0000-0000-0000-000000000004	d0000026-0000-0000-0000-000000000004	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	apple-org	Organization Data	0.9000	2026-07-18 09:57:12.946973+00	2026-07-18 09:57:12.946973+00	\N	1
f0000008-0000-0000-0000-000000000005	d0000008-0000-0000-0000-000000000005	4264c67d-7bbe-49af-9df3-0289d61f4477	3330b5d5-ef3c-43d5-b0e8-42f7fc6c8b1b	\N	huxley-lit	Writer Data	0.9000	2026-07-18 09:57:12.910741+00	2026-07-18 09:57:12.910741+00	\N	1
f0000008-0000-0000-0000-000000000004	d0000008-0000-0000-0000-000000000004	4264c67d-7bbe-49af-9df3-0289d61f4477	3330b5d5-ef3c-43d5-b0e8-42f7fc6c8b1b	\N	bradbury-lit	Writer Data	0.9000	2026-07-18 09:57:12.910741+00	2026-07-18 09:57:12.910741+00	\N	1
f0000008-0000-0000-0000-000000000003	d0000008-0000-0000-0000-000000000003	4264c67d-7bbe-49af-9df3-0289d61f4477	3330b5d5-ef3c-43d5-b0e8-42f7fc6c8b1b	\N	orwell-lit	Writer Data	0.9000	2026-07-18 09:57:12.910741+00	2026-07-18 09:57:12.910741+00	\N	1
f0000009-0000-0000-0000-000000000006	d0000009-0000-0000-0000-000000000006	96ffa67d-b033-4950-89e6-d35cff76da25	99662b06-1284-4d5c-878c-ef1cd804ebc3	\N	rome-geo	Location Data	0.9000	2026-07-18 09:57:12.918551+00	2026-07-18 09:57:12.918551+00	\N	1
f0000009-0000-0000-0000-000000000005	d0000009-0000-0000-0000-000000000005	96ffa67d-b033-4950-89e6-d35cff76da25	99662b06-1284-4d5c-878c-ef1cd804ebc3	\N	newyork-geo	Location Data	0.9000	2026-07-18 09:57:12.918551+00	2026-07-18 09:57:12.918551+00	\N	1
f0000009-0000-0000-0000-000000000004	d0000009-0000-0000-0000-000000000004	96ffa67d-b033-4950-89e6-d35cff76da25	99662b06-1284-4d5c-878c-ef1cd804ebc3	\N	london-geo	Location Data	0.9000	2026-07-18 09:57:12.918551+00	2026-07-18 09:57:12.918551+00	\N	1
f0000010-0000-0000-0000-000000000006	d0000010-0000-0000-0000-000000000006	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	55610502-a3ce-4f51-a842-834c9fd46cc9	\N	silver-sci	Science Data	0.9500	2026-07-18 09:57:12.92619+00	2026-07-18 09:57:12.92619+00	\N	1
f0000010-0000-0000-0000-000000000005	d0000010-0000-0000-0000-000000000005	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	55610502-a3ce-4f51-a842-834c9fd46cc9	\N	gold-sci	Science Data	0.9500	2026-07-18 09:57:12.92619+00	2026-07-18 09:57:12.92619+00	\N	1
f0000010-0000-0000-0000-000000000004	d0000010-0000-0000-0000-000000000004	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	55610502-a3ce-4f51-a842-834c9fd46cc9	\N	iron-sci	Science Data	0.9500	2026-07-18 09:57:12.92619+00	2026-07-18 09:57:12.92619+00	\N	1
f0000011-0000-0000-0000-000000000006	d0000011-0000-0000-0000-000000000006	801d5718-54ec-44c7-85da-af53af4d7acc	313cdb66-75e2-459d-9696-71785601e875	\N	penguin-bio	Biology Data	0.9000	2026-07-18 09:57:12.934499+00	2026-07-18 09:57:12.934499+00	\N	1
f0000011-0000-0000-0000-000000000005	d0000011-0000-0000-0000-000000000005	801d5718-54ec-44c7-85da-af53af4d7acc	313cdb66-75e2-459d-9696-71785601e875	\N	elephant-bio	Biology Data	0.9000	2026-07-18 09:57:12.934499+00	2026-07-18 09:57:12.934499+00	\N	1
f0000011-0000-0000-0000-000000000004	d0000011-0000-0000-0000-000000000004	801d5718-54ec-44c7-85da-af53af4d7acc	313cdb66-75e2-459d-9696-71785601e875	\N	tiger-bio	Biology Data	0.9000	2026-07-18 09:57:12.934499+00	2026-07-18 09:57:12.934499+00	\N	1
f0000004-0000-0000-0000-000000000005	d0000004-0000-0000-0000-000000000005	102715a7-994b-46fe-87cf-9a21487d74cd	fcf60464-178c-4b0e-b2a7-939f31f46ba9	\N	imagine-music	Music Data	0.9500	2026-07-18 09:57:12.886462+00	2026-07-18 09:57:12.886462+00	\N	1
f0000004-0000-0000-0000-000000000004	d0000004-0000-0000-0000-000000000004	102715a7-994b-46fe-87cf-9a21487d74cd	fcf60464-178c-4b0e-b2a7-939f31f46ba9	\N	hotel-california-music	Music Data	0.9500	2026-07-18 09:57:12.886462+00	2026-07-18 09:57:12.886462+00	\N	1
f0000004-0000-0000-0000-000000000003	d0000004-0000-0000-0000-000000000003	102715a7-994b-46fe-87cf-9a21487d74cd	fcf60464-178c-4b0e-b2a7-939f31f46ba9	\N	stairway-music	Music Data	0.9500	2026-07-18 09:57:12.886462+00	2026-07-18 09:57:12.886462+00	\N	1
f0000005-0000-0000-0000-000000000005	d0000005-0000-0000-0000-000000000005	102715a7-994b-46fe-87cf-9a21487d74cd	0c2ec0ab-ae2d-4cca-84cc-432cd0dd1256	\N	presley-music	Musician Data	0.9000	2026-07-18 09:57:12.894281+00	2026-07-18 09:57:12.894281+00	\N	1
f0000005-0000-0000-0000-000000000004	d0000005-0000-0000-0000-000000000004	102715a7-994b-46fe-87cf-9a21487d74cd	0c2ec0ab-ae2d-4cca-84cc-432cd0dd1256	\N	hendrix-music	Musician Data	0.9000	2026-07-18 09:57:12.894281+00	2026-07-18 09:57:12.894281+00	\N	1
f0000005-0000-0000-0000-000000000003	d0000005-0000-0000-0000-000000000003	102715a7-994b-46fe-87cf-9a21487d74cd	0c2ec0ab-ae2d-4cca-84cc-432cd0dd1256	\N	lennon-music	Musician Data	0.9000	2026-07-18 09:57:12.894281+00	2026-07-18 09:57:12.894281+00	\N	1
f0000007-0000-0000-0000-000000000005	d0000007-0000-0000-0000-000000000005	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	\N	brave-new-world-lit	Literature Data	0.9500	2026-07-18 09:57:12.903225+00	2026-07-18 09:57:12.903225+00	\N	1
f0000007-0000-0000-0000-000000000004	d0000007-0000-0000-0000-000000000004	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	\N	fahrenheit-lit	Literature Data	0.9500	2026-07-18 09:57:12.903225+00	2026-07-18 09:57:12.903225+00	\N	1
f0000007-0000-0000-0000-000000000003	d0000007-0000-0000-0000-000000000003	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	\N	1984-lit	Literature Data	0.9500	2026-07-18 09:57:12.903225+00	2026-07-18 09:57:12.903225+00	\N	1
60d5c463-28ba-436f-acae-bc99641e43a2	4cb4bd5c-599a-4a8f-bfa0-44f2b5ff4ac8	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_4cb4bd5c599a	futurama	1.0000	2026-07-18 20:22:59.45833+00	2026-07-18 20:22:59.458333+00	\N	1
2331534d-059c-4141-bd1f-6d7795b510fe	c7940df6-46a1-483b-a8b0-0fb0d60019f2	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_c7940df646a1	i	1.0000	2026-07-18 20:26:38.016193+00	2026-07-18 20:26:38.016196+00	\N	1
9e62c66f-565c-42dd-9686-ba9c5444f749	eb2cb77f-513e-450a-a911-aa2fd912f5c3	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_eb2cb77f513e	orig (1)	1.0000	2026-07-18 20:26:50.664468+00	2026-07-18 20:26:50.66447+00	\N	1
1bedc101-f24c-4dc3-982b-70e95ca48c1d	8bf8898d-097d-414e-beab-2c84e8fdd08b	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_8bf8898d097d	test_cover	1.0000	2026-07-18 20:38:28.473169+00	2026-07-18 20:38:28.473171+00	\N	1
dd31cf82-0cc3-4e03-8a38-0a592f9e3475	163f66ff-44d7-4580-85ab-39c5bfbe1e9d	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_163f66ff44d7	maxresdefault	1.0000	2026-07-18 20:40:32.703577+00	2026-07-18 20:40:32.70358+00	\N	1
f4cd7b51-6218-4555-8b8e-1cfce2564071	cc56d0bf-a031-4ba6-8904-c14f6344d234	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_birth_date_proj	Дата рождения	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	93
184292ad-1f42-4393-b1e6-3a4de1ca8b38	10ffb420-a434-447b-b207-6b2f3c9b107f	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_birth_place_proj	Место рождения	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	94
de698b95-3b52-4d96-bd3a-58c7469a4555	15352e27-8d98-42ca-adcb-78d1f7bc83df	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_death_date_proj	Дата смерти	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	95
6d7bf38c-5b10-4ebc-9aef-6d845dac8205	7d6a7080-967b-48cc-8034-53b1662f4681	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_death_place_proj	Место смерти	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	96
c1950488-6228-48f9-9a11-beb88bce58f1	b23c6d35-ec9a-429d-891d-aabdb23f1082	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_height_cm_proj	Рост (см)	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	97
003e5c0c-47e5-4492-b6b4-eb12efda80ae	defed9c0-35a9-420f-afcb-a6b0180584fb	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_nationality_proj	Национальность	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	98
5f7a5784-15a6-4f9d-9884-61bd98324ab6	84da9ec5-cec4-4e37-acef-1c9572014138	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_occupation_proj	Профессия	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	99
1567fd8a-7b94-47e8-96fe-8f8641809c8e	1f5c413e-1aed-4c2e-96c7-39d8dc30d2d0	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_electron_configuration_proj	Электронная конфигурация	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	100
686f087e-34ee-4574-8f58-9c4e2afd099c	783ef653-d827-4583-b9cb-6d3d6470ee5d	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_oxidation_states_proj	Степени окисления	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	101
b662b658-dca9-4302-aec6-6cf4e73bb496	f763b263-01bf-4721-bbc0-8529a716c627	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_electronegativity_proj	Электроотрицательность	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	102
bdd16d74-7297-4206-8d87-972230f19db8	e802227c-4f05-446e-ac3b-b99421b1401c	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_density_proj	Плотность	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	103
2449f3e9-e2d5-4977-983f-f7cce47f2ce4	14753e08-083b-4068-8e9e-ffe785b64468	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_melting_point_proj	Температура плавления	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	104
8d0976da-245a-4c4e-9c4c-1ae975251217	1aa33c64-8a8b-4ef8-9f1f-99a187b1e1e3	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_boiling_point_proj	Температура кипения	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	105
546bba61-f80f-465c-80f7-1384f129987d	257bfc6b-5728-4955-8710-c4cc18041adc	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	8a7394bb-e9b7-47e5-9729-598a3ab4154c	\N	field_discovery_year_proj	Год открытия	1.0000	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	106
8f36c2e9-61b1-4952-9304-94d0a3ec7b39	4cacf75e-5bde-4587-8552-102584be4e14	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	 -2_movie_tpl_movie	Ð¢ÐµÑÑÐ¾Ð²ÑÐ¹ ÑÐ¸Ð»ÑÐ¼	1.0000	2026-07-19 07:04:44.881638+00	2026-07-19 07:04:44.881641+00	\N	108
395510c6-4513-4f54-9236-aa9f62977416	a5cf7ea3-4ce6-43fa-a34d-66173cf61b71	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	 -3_movie_tpl_movie	Ð¢ÐµÑÑ Ð¿ÑÐ¾ÐµÐºÑÐ¸Ð¸	1.0000	2026-07-19 07:43:09.837112+00	2026-07-19 07:43:09.837116+00	\N	109
df2199cc-b9fa-40f9-ba07-a1cd538befcb	a5cf7ea3-4ce6-43fa-a34d-66173cf61b71	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	8c3f9ad2-241e-4d66-9a50-2618621356b3	 -3_book_tpl_book	 -3	1.0000	2026-07-19 07:44:38.169489+00	2026-07-19 07:44:38.169497+00	\N	110
61953102-23fb-4c7e-9dc3-d8cd6ab9cd17	d0000001-0000-0000-0000-000000000005	8c86f136-2f76-44c4-8d56-e5db5703bff6	54c9afef-b39c-4451-aa03-c6d0cc8c2077	8c3f9ad2-241e-4d66-9a50-2618621356b3	blade-runner-2049_digital_file_Clip	blade-runner-2049	1.0000	2026-07-19 07:46:45.453589+00	2026-07-19 07:46:45.453592+00	\N	110
9f298edf-a368-4c39-b24a-333b9aa1f3b2	87135199-274e-4cc5-9027-dc0ca71c7206	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	 -4_movie_tpl_movie	ÐÐ´Ð¸Ð½Ð¾ÑÐ½ÑÐ¹ ÑÐµÑÑ	1.0000	2026-07-19 07:51:47.837203+00	2026-07-19 07:51:47.837205+00	\N	110
80309641-c837-40e4-a83e-1f07f860191c	87135199-274e-4cc5-9027-dc0ca71c7206	4264c67d-7bbe-49af-9df3-0289d61f4477	a40dfdf3-4750-438f-8494-bb876cd16941	8c3f9ad2-241e-4d66-9a50-2618621356b3	 -4_book_tpl_book	 -4	1.0000	2026-07-19 07:52:26.818827+00	2026-07-19 07:52:26.81883+00	\N	111
81dd7447-5918-4549-8142-f365fcc09f5b	28bd6d73-486b-411d-a0a4-be628e8bc486	8c86f136-2f76-44c4-8d56-e5db5703bff6	54c9afef-b39c-4451-aa03-c6d0cc8c2077	8c3f9ad2-241e-4d66-9a50-2618621356b3	 _digital_file_Clip	 	1.0000	2026-07-19 08:07:03.109264+00	2026-07-19 08:07:03.109269+00	\N	111
b383f10f-0633-4e70-9967-220e96592ef2	afed8c62-00d3-476b-a20c-2b8173d303a6	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_afed8c6200d3	Академия ведьмочек	1.0000	2026-07-19 08:07:20.04816+00	2026-07-19 08:07:20.048162+00	\N	1
00ae4bbc-d0c5-4096-872d-f53ef257adef	bc2e4b44-1cc5-49bd-9150-344db72a1ada	8c86f136-2f76-44c4-8d56-e5db5703bff6	e2eb89b9-eb05-4549-82ad-2349279b1b2d	\N	ontmodel_cinema	cinema	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	101
6c06e605-d3ce-4f03-a871-ef44f689c56b	bb0c3817-0c84-4636-bbe4-a2e526e2ed4a	4264c67d-7bbe-49af-9df3-0289d61f4477	e2eb89b9-eb05-4549-82ad-2349279b1b2d	\N	ontmodel_literature	literature	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	102
7a0161b2-a41b-4bcb-93f4-7cf00ee9a854	5f187205-5b33-4ef3-b22d-548919737ae2	102715a7-994b-46fe-87cf-9a21487d74cd	e2eb89b9-eb05-4549-82ad-2349279b1b2d	\N	ontmodel_music	music	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	103
ce7ce781-ff4b-49e2-9391-5519fb4e54af	eb270429-1d7a-40ef-99ff-febd7e3c9cfd	8c6480ac-1e41-4c34-b75e-6dedab9ed913	e2eb89b9-eb05-4549-82ad-2349279b1b2d	\N	ontmodel_technology	technology	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	104
fbea994c-76c5-4d85-a287-bf04a4457e44	0c0ab9ea-fabc-4497-9b2a-551bce2633aa	801d5718-54ec-44c7-85da-af53af4d7acc	e2eb89b9-eb05-4549-82ad-2349279b1b2d	\N	ontmodel_default	default	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	105
3370b93b-389c-4ae3-a7f0-2de9cee6e930	c204aa0c-04c6-44ef-8e86-e53ff4a4eb81	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	e2eb89b9-eb05-4549-82ad-2349279b1b2d	\N	ontmodel_field_model	field_model	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	106
7e7c4fb3-8324-4934-bafe-634b3de1651f	af903b79-d26c-48b1-973b-a1bfaa229723	e7048181-8484-4cda-b47f-d966fc3cd4f6	e2eb89b9-eb05-4549-82ad-2349279b1b2d	\N	ontmodel_ontology_entity_model	ontology_entity_model	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	107
0903e6ba-2cb0-467a-90a3-aee018ca93b0	29f93b7a-c8a0-46bb-a5b9-8c7e4bbec851	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	e2eb89b9-eb05-4549-82ad-2349279b1b2d	\N	ontmodel_science	science	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	108
a7bfca28-7ce8-4289-95e8-0b47b11ed190	736f1f2b-b9a0-4199-b026-410ae5d32fd0	96ffa67d-b033-4950-89e6-d35cff76da25	e2eb89b9-eb05-4549-82ad-2349279b1b2d	\N	ontmodel_geography	geography	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	109
94c08ef8-4d15-4bad-b497-f27397da677a	1b53bbd4-9c24-407b-8af3-ed833c9f11c1	f3b13238-49e8-473a-8c6f-d424e36f197f	e2eb89b9-eb05-4549-82ad-2349279b1b2d	\N	ontmodel_history	history	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	110
e5f40263-8e70-4531-ab70-f2a4ee095e3d	a0c57af5-a57c-4a21-825f-5f64d0f104e8	8c86f136-2f76-44c4-8d56-e5db5703bff6	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_actor_tpl_person	Шаблон: Человек (персона)	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	112
27d7fe31-8197-4b46-9596-f173b3574251	cf7ee646-99ca-4d12-9b58-8859b9771de6	102715a7-994b-46fe-87cf-9a21487d74cd	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_album_tpl_album	Шаблон: Альбом	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	113
cff4ba60-3c03-4677-915e-886ee06bcaec	e09b6c18-7e5b-4a6b-8653-584f86c318d6	4264c67d-7bbe-49af-9df3-0289d61f4477	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_book_tpl_book	Шаблон: Книга	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	114
9915a57f-9fea-4ef8-9cd9-0a545be890cd	09c95573-23ed-43ae-9b4c-a39d10c30e7c	8c86f136-2f76-44c4-8d56-e5db5703bff6	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_digital_file_Clip	Шаблон: Клип	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	115
e19b828d-3d7e-413e-9d7a-97d60ce23cc6	138b1eb4-bcb4-46c8-a608-80ae65c59654	8c86f136-2f76-44c4-8d56-e5db5703bff6	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_director_tpl_person	Шаблон: Человек (персона)	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	116
92b80626-11d0-4229-b811-f81e6f7e685e	cddfb16e-fd93-45b8-93de-afcb0a09bc02	8c86f136-2f76-44c4-8d56-e5db5703bff6	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_movie_tpl_movie	Шаблон: Фильм	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	117
3cd97617-8bf2-49d4-ab45-a62a26b4bd65	9ce79308-04cf-4d9b-849c-5abadca3a604	102715a7-994b-46fe-87cf-9a21487d74cd	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_musician_tpl_person	Шаблон: Человек (персона)	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	118
572cf813-bc7f-4352-8da2-84b648cfd938	85a3fcf9-5269-45db-9635-6e28e3ebf5be	102715a7-994b-46fe-87cf-9a21487d74cd	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_song_tpl_song	Шаблон: Песня	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	119
b7956d4f-f477-453d-a0ce-2e7a431dda31	152a73bb-f373-465c-80d5-399208c86fc5	4264c67d-7bbe-49af-9df3-0289d61f4477	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_writer_tpl_person	Шаблон: Человек (персона)	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	120
78b54b36-da0b-4be0-bd46-c4ab7b64338c	14c04917-f468-4f95-a512-a8645ac910bb	801d5718-54ec-44c7-85da-af53af4d7acc	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_article_tpl_article	Шаблон: Статья	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	121
cf459fc7-7d0a-4d39-a036-1a5f8c93eb5d	4b061c8b-e244-41ce-9d09-e2f2da50521c	801d5718-54ec-44c7-85da-af53af4d7acc	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_artist_tpl_person	Шаблон: Человек (персона)	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	122
127b4031-fa26-4094-834f-092f0a95b940	5f4607e5-7201-4db5-9815-0097a92c5960	801d5718-54ec-44c7-85da-af53af4d7acc	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_classifier_tpl_classifier	Шаблон: Классификатор	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	123
3698e2e9-1d04-464e-8e08-023d1a012dcf	2f6881f2-7199-4f36-8df7-e72442e331a7	801d5718-54ec-44c7-85da-af53af4d7acc	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_concept_tpl_concept	Шаблон: Концепция	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	124
e04c7f37-1173-49e8-a384-5f4355336c4a	ff738162-46d2-4729-b625-13fb9e4a74b9	801d5718-54ec-44c7-85da-af53af4d7acc	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_digital_file_tpl_file	Шаблон: Файл	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	125
68eb8255-bb7b-47e6-990b-28529d1b3460	8be3db4d-998a-407e-abbf-80c80d4bfb34	801d5718-54ec-44c7-85da-af53af4d7acc	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_genre_tpl_genre	Шаблон: Жанр	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	126
80397f3d-e694-4a90-8150-c4bd443743cf	8dbad62b-b97d-4b4d-9daa-2035ad88e8af	801d5718-54ec-44c7-85da-af53af4d7acc	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_human_tpl_person	Шаблон: Человек (персона)	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	127
6d53a71f-ac4c-42e8-be0d-5070068d7eaa	38b8568b-f382-4b4d-b3bf-67285bd3f8df	801d5718-54ec-44c7-85da-af53af4d7acc	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_movement_tpl_movement	Шаблон: Движение	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	128
49482c2f-73be-4d60-a0d5-09f466bc51e8	29a3fbd3-ef9c-4005-92a3-ffcd69b8750a	801d5718-54ec-44c7-85da-af53af4d7acc	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_photo_tpl_photo	Шаблон: Фото	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	129
179a6a87-5962-4178-a6aa-cd1e8029d398	2f24423f-b243-4349-b141-d742e7760df9	801d5718-54ec-44c7-85da-af53af4d7acc	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_physical_item_tpl_item	Шаблон: Предмет	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	130
63531d56-6773-4429-9c39-322e819624f2	a5c1e6af-ddbf-4f1c-814a-af4d72355b98	801d5718-54ec-44c7-85da-af53af4d7acc	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_tpl_my_image	Изображение	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	131
86d133f4-303b-4005-bdda-074abb344287	e3a539f8-2616-48ef-9b6c-91d4e7d7fd98	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_field_template	Шаблон: Поле	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	132
1d30fee1-6d99-4f4e-89b6-ef56c66863bc	e9f2746c-654d-40c6-8889-d2644b716ed2	e7048181-8484-4cda-b47f-d966fc3cd4f6	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_ontology_model_tpl	Шаблон: Модель онтологии	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	133
7391b484-799a-40c6-b058-a8b5458fc818	661a1a34-cabe-4d19-a233-1d615919a52d	e7048181-8484-4cda-b47f-d966fc3cd4f6	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_ontology_template_tpl	Шаблон: Шаблон онтологии	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	134
0e5ee33d-3a48-47f1-8f0a-e2d9c1fe871a	7a309616-4834-46b7-bcdc-ba5b4bc518aa	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_animal_tpl_animal	Шаблон: Животное	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	135
c1428027-e94a-4698-832d-5846ba80e85f	bae1f4a5-c622-4136-8f95-8e25917db03e	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_chemical_element_tpl_element	Шаблон: Химический элемент	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	136
73d35e3f-f0ca-4836-8c34-31205c0255f3	00acc2db-82e9-4955-8c81-cfd4afeff149	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_phenomenon_tpl_phenomenon	Шаблон: Явление	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	137
bdce3271-881a-4ec3-9cc7-a8833f287b3c	54ee9c51-8f8c-4811-a102-4ae1c591acfe	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_plant_tpl_plant	Шаблон: Растение	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	138
1856e3d5-50b8-4225-8157-fa45af2a18a0	26e0e57e-5d11-4a9d-80d5-f098bc5c3032	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_scientist_tpl_person	Шаблон: Человек (персона)	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	139
1aeee6cc-37a4-4125-9062-114cf4aa4822	0c3967e8-9189-40c0-bfc0-68682ddb648b	f3b13238-49e8-473a-8c6f-d424e36f197f	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_period_tpl_period	Шаблон: Эпоха	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	140
5ce640d6-1243-4b80-9ac7-13b2489330c5	68384b8c-39fa-4923-8c43-c2922b468d31	96ffa67d-b033-4950-89e6-d35cff76da25	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_place_tpl_place	Шаблон: Место	1.0000	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	141
329fff68-9205-430f-8299-a7d28cee5363	d0000002-0000-0000-0000-000000000001	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	8c3f9ad2-241e-4d66-9a50-2618621356b3	keanu-reeves_director_tpl_person	keanu-reeves	1.0000	2026-07-19 10:17:47.595286+00	2026-07-19 10:17:47.59529+00	\N	142
aab4cf81-e171-48a4-82ec-7f97029f79ad	675126c2-ba40-42d8-a669-087c992e5066	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	interstellar tmdb test_movie_tpl_movie	Интерстеллар (TMDB Test)	1.0000	2026-07-19 12:07:04.306731+00	2026-07-19 12:07:04.306735+00	\N	142
ac1eed0a-ef38-48ab-ac2e-fcf6ab16e5cb	316f401b-37b5-4928-bc24-4d8298e6eb73	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	test_movie_tpl_movie	Тест	1.0000	2026-07-19 12:27:44.259475+00	2026-07-19 12:27:44.259477+00	\N	143
32996523-a5e1-4323-95a4-20de58f0d118	88d8fb43-a635-4880-ae5a-a2f966d35191	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	boytsovskiy klub_movie_tpl_movie	Бойцовский клуб	1.0000	2026-07-19 12:27:44.286202+00	2026-07-19 12:27:44.286205+00	\N	144
9cac47b2-da17-4f57-9ee2-d361f23ad6c2	ae4f652d-0f13-4bf5-9e56-91e094533563	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	zveropolis_movie_tpl_movie	Зверополис	1.0000	2026-07-19 12:53:24.175416+00	2026-07-19 12:53:24.175418+00	\N	145
9a6bc177-7cdc-4c25-aa9b-c62ac474a5dd	3c62b9a7-7089-4dac-93ec-4a2ddecb2e96	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_6384	Киану Ривз	1.0000	2026-07-19 13:48:58.026755+00	2026-07-19 13:48:58.026762+00	\N	146
706584a9-2a9f-4848-98d3-3ce09ba8f877	4a97d9d9-9fe6-4acf-96ad-2eb1eb2fc8ec	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_2975	Лоренс Фишбёрн	1.0000	2026-07-19 13:48:58.053334+00	2026-07-19 13:48:58.053338+00	\N	146
f58926e0-ae86-4cf9-9b29-52122e04ccc1	eba3b8f1-7030-4030-b081-7cbc1188f5c0	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_530	Кэрри-Энн Мосс	1.0000	2026-07-19 13:48:58.06113+00	2026-07-19 13:48:58.061132+00	\N	146
892aa355-ee57-476f-9640-009498da38df	40c5f5cc-2e35-4dfb-a752-594660f1b481	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_1331	Хьюго Уивинг	1.0000	2026-07-19 13:48:58.065702+00	2026-07-19 13:48:58.065704+00	\N	146
dd793190-1c6c-491b-8343-fd2cca3890a4	ff901aa3-31ac-4e8d-ba94-3765066ffb64	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_9364	Глория Фостер	1.0000	2026-07-19 13:48:58.069756+00	2026-07-19 13:48:58.069758+00	\N	146
aadec829-faec-400f-b176-d3377c7a7341	c1f10e6f-a57f-41b2-98b4-2cb40142f4fa	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_532	Джо Пантолиано	1.0000	2026-07-19 13:48:58.07509+00	2026-07-19 13:48:58.075093+00	\N	146
a4f99864-c2e0-4d39-ad1d-7dd743810c33	57bce17e-0ba5-455d-bc66-9351a10d7094	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_9372	Маркус Чонг	1.0000	2026-07-19 13:48:58.081588+00	2026-07-19 13:48:58.08159+00	\N	146
f7d62057-688d-4fec-b265-07e556c2dcc1	c3f22c49-3287-429b-bf3e-8e17987bc06c	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_7244	Джулиан Араханга	1.0000	2026-07-19 13:48:58.086331+00	2026-07-19 13:48:58.086334+00	\N	146
be0274e6-ae82-4af8-9516-a1cbc5ea0b5d	42a03e22-8ac3-4dbc-a084-9dd54dbd8dea	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_9374	Мэтт Доран	1.0000	2026-07-19 13:48:58.091386+00	2026-07-19 13:48:58.091389+00	\N	146
03bcc812-9a9c-4d0b-8e25-804e2e20a914	12d77665-1267-491a-a8ee-2d3fe2910980	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_9376	Белинда МакКлори	1.0000	2026-07-19 13:48:58.095248+00	2026-07-19 13:48:58.09525+00	\N	146
6a1793b8-15ff-4f6d-b265-b4618217105a	02c2a15e-b864-4c1c-bfb5-e315b4ef5582	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_9378	Энтони Рэй Паркер	1.0000	2026-07-19 13:48:58.099007+00	2026-07-19 13:48:58.099008+00	\N	146
737be451-4908-46e2-9199-b1a84a8b5d24	8040279c-cfa4-46ba-84e7-ccbe4508468c	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_9380	Пол Годдард	1.0000	2026-07-19 13:48:58.102604+00	2026-07-19 13:48:58.102605+00	\N	146
5aec146a-7b9b-4390-aaac-984e77fed718	859bbc34-a13f-44e0-9b68-98b77af590e4	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_39545	Роберт Тейлор	1.0000	2026-07-19 13:48:58.106626+00	2026-07-19 13:48:58.106628+00	\N	146
9dd57732-bf86-4a6e-85f4-2cca1a1da87c	a419fe53-6f2e-4b32-b8dc-3aef96e52b47	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_9383	Дэвид Астон	1.0000	2026-07-19 13:48:58.110374+00	2026-07-19 13:48:58.110375+00	\N	146
fcbdd077-30e8-4620-b0c9-a08b974cefaa	07d68dbe-bec6-4dc0-af9d-430408143885	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_9384	Марк Аден Грей	1.0000	2026-07-19 13:48:58.113993+00	2026-07-19 13:48:58.113995+00	\N	146
751948c6-c045-47b1-aceb-7ced3d525d20	9a49ab7f-8491-4f7b-b502-870b5e770c59	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	\N	director_9340	Ларри Вачовски	1.0000	2026-07-19 13:48:58.117681+00	2026-07-19 13:48:58.117683+00	\N	146
8324f64b-e6fd-491c-8300-d2f5a0c09201	d5837aa3-c87e-4b54-be6b-8fd1a85cd5f2	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	\N	director_9339	Энди Вачовски	1.0000	2026-07-19 13:48:58.121284+00	2026-07-19 13:48:58.121286+00	\N	146
92774323-efa4-4404-9d3e-90ec1c7bb233	14299d64-b42e-4da1-a332-17044d038483	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	moana_movie_tpl_movie	Моана	1.0000	2026-07-19 14:10:57.96389+00	2026-07-19 14:10:57.963893+00	\N	147
c34842a1-9f13-483d-be1c-a7f6eb1bcbe8	485dee97-cde2-4603-8aa3-1b9364a5cbb1	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_485dee97cde2	Чокнутый профессор (Коллекция)2	1.0000	2026-07-19 15:13:23.037275+00	2026-07-19 15:13:23.037279+00	\N	1
5dda904d-07d8-4d6a-a059-e4bcacc786b1	ce6d5b1a-8536-4823-88c3-6d077da6c23c	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_ce6d5b1a8536	Чокнутый профессор (Коллекция)	1.0000	2026-07-19 15:13:23.109994+00	2026-07-19 15:13:23.109996+00	\N	1
00a4fe02-5e60-4a30-9839-f23ec52e20a8	c42af2c3-8bff-431d-84aa-31fee4e37dba	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_c42af2c38bff	Легенда о Ло Сяохэе2	1.0000	2026-07-19 15:13:23.145612+00	2026-07-19 15:13:23.145613+00	\N	1
5820c046-43c4-496f-bfc5-9a7281c8119d	9559dcd0-3ee8-4941-ac8e-65bde4b2e705	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_9559dcd03ee8	Легенда о Ло Сяохэе	1.0000	2026-07-19 15:13:23.167785+00	2026-07-19 15:13:23.167787+00	\N	1
86b68c72-206c-45ad-af54-c36dfa3cf97f	b56aeff9-0ebd-4687-b5f3-c7bdd8efa1a6	801d5718-54ec-44c7-85da-af53af4d7acc	cccfc450-1b74-479a-ae52-33fe49a8c4ac	\N	upload_b56aeff90ebd	4.Комнаты	1.0000	2026-07-19 15:13:23.423456+00	2026-07-19 15:13:23.423457+00	\N	1
e5bb181d-736c-466e-815a-e906a706fe7e	2dc022f2-ce9a-4460-961f-b0eb14940557	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	spaun_movie_tpl_movie	Спаун	1.0000	2026-07-19 16:57:18.138411+00	2026-07-19 16:57:18.138415+00	\N	148
c5330eb1-2122-444a-aa7e-f7266a3e8aa0	81fc4a44-8440-495a-ab10-9071e01b03f2	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_3	Харрисон Форд	1.0000	2026-07-19 17:35:23.970391+00	2026-07-19 17:35:23.970393+00	\N	149
83c5ad1b-1402-4361-8371-0931292979a7	539e17de-4a18-4fb7-9f60-1a67eb6d7342	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_585	Рутгер Хауэр	1.0000	2026-07-19 17:35:23.977168+00	2026-07-19 17:35:23.97717+00	\N	149
b5bdf1b2-d6a2-4e9a-a5ae-becd088ca012	379e665e-a13a-4f99-b4ae-ba6d68694f79	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_586	Шон Янг	1.0000	2026-07-19 17:35:23.981107+00	2026-07-19 17:35:23.981108+00	\N	149
7ff31578-8b55-45d8-9bbf-91b0a7525bb7	3723a9d9-c419-4d93-8601-213fab20f209	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_587	Эдвард Джеймс Олмос	1.0000	2026-07-19 17:35:23.984946+00	2026-07-19 17:35:23.984947+00	\N	149
2f0c96a7-2ecd-46af-85e8-1f01dee00683	dd82c80c-57d6-47df-96b9-68725482a8f9	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_588	М. Эммет Уолш	1.0000	2026-07-19 17:35:23.988873+00	2026-07-19 17:35:23.988874+00	\N	149
44866e92-9bbc-490d-b669-db2707e549d2	84a7abd7-aeaf-44d7-accb-ab32916c05ef	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_589	Дэрил Ханна	1.0000	2026-07-19 17:35:23.993286+00	2026-07-19 17:35:23.993287+00	\N	149
a6017768-8eed-4bd4-8338-d45eba357abd	678fb7a5-59ea-4f96-8e18-50a3512531f3	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_590	Уильям Сэндерсон	1.0000	2026-07-19 17:35:23.997501+00	2026-07-19 17:35:23.997502+00	\N	149
8022d0fa-eb01-4385-b009-61b872e3d036	0aacbfa3-02c8-47ef-b65b-b31831c5e810	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_591	Брайон Джеймс	1.0000	2026-07-19 17:35:24.001475+00	2026-07-19 17:35:24.001477+00	\N	149
621ccdbc-1f80-4974-bc0d-e56fe0ca0ecf	da777e99-1053-4964-91ed-dd50b1ec472b	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_592	Джо Тёркел	1.0000	2026-07-19 17:35:24.005852+00	2026-07-19 17:35:24.005853+00	\N	149
58c1d656-b2e5-493a-b773-a4b678b64b2a	2519866a-6643-448a-b7d3-b715460f00b2	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_593	Джоанна Кэссиди	1.0000	2026-07-19 17:35:24.010002+00	2026-07-19 17:35:24.010004+00	\N	149
612d6657-a1f8-4846-b73b-37576f8c6304	272384e9-863b-4c5c-9173-5a33e916b463	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_20904	Джеймс Хонг	1.0000	2026-07-19 17:35:24.01407+00	2026-07-19 17:35:24.014072+00	\N	149
bf61c434-1f7e-4306-807f-68b2e27d262f	83465a83-d6cc-490d-8eb7-2ff76c09db26	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_58495	Морган Полл	1.0000	2026-07-19 17:35:24.018162+00	2026-07-19 17:35:24.018163+00	\N	149
d25b91cf-596b-459d-80f8-13ac1b083bad	3c9f167e-c3e6-4c90-b685-0c5c4140ef4a	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_53760	Кевин Томпсон	1.0000	2026-07-19 17:35:24.022069+00	2026-07-19 17:35:24.02207+00	\N	149
7881a7a1-6aea-4d8d-80d6-97793e60fad3	563aa5cc-fdff-4ce9-9286-51ccac80df1c	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_943481	Джон Эдвард Аллен	1.0000	2026-07-19 17:35:24.025965+00	2026-07-19 17:35:24.025967+00	\N	149
d65d0b30-03bb-49b1-8fd7-847edb52ebac	e73db3a3-7d24-448a-8dc3-a0372ee8d227	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_107074	Хай Пайк	1.0000	2026-07-19 17:35:24.029941+00	2026-07-19 17:35:24.029942+00	\N	149
aab7cb0d-f4ff-4769-94a6-0d570fe5e089	98c7bf0d-8906-4a15-8dc5-d93344cf713a	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	\N	director_578	Ридли Скотт	1.0000	2026-07-19 17:35:24.034071+00	2026-07-19 17:35:24.034072+00	\N	149
2819f96f-ffe2-4646-9cda-78d1c8cc1a19	705601a6-39ee-4e1f-b770-a13b33e90b7c	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	shrek_movie_tpl_movie	Шрэк	1.0000	2026-07-19 17:51:27.954594+00	2026-07-19 17:51:27.954597+00	\N	150
c0701267-0db0-4aea-a58f-b44584a0fc19	2f182f95-9d5f-49a8-bf3c-7e859d73dcde	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_12073	Майк Майерс	1.0000	2026-07-19 17:54:23.118808+00	2026-07-19 17:54:23.118812+00	\N	151
d3389f14-d9e3-4857-bb7c-4d8545a4f18a	06b10f9f-ebff-49ea-a556-a2add917fd87	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_776	Эдди Мёрфи	1.0000	2026-07-19 17:54:23.126751+00	2026-07-19 17:54:23.126753+00	\N	151
57d94611-2ac2-4118-82f7-e74d498502ad	aead556f-5a34-467c-b9f2-0ad48b737a18	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_6941	Кэмерон Диас	1.0000	2026-07-19 17:54:23.130911+00	2026-07-19 17:54:23.130912+00	\N	151
07b4d6d2-5034-4225-97a9-db05c1436a9d	9a98109b-27bc-480f-a64a-54b4447e7c9b	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_12074	Джон Литгоу	1.0000	2026-07-19 17:54:23.134841+00	2026-07-19 17:54:23.134842+00	\N	151
c62a9f19-5458-4fc7-ad15-445ead40d427	689de5a6-5552-4753-8ee3-cf2e07504d06	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_1925	Венсан Кассель	1.0000	2026-07-19 17:54:23.138665+00	2026-07-19 17:54:23.138666+00	\N	151
eb43c50e-60c1-45b5-abc7-359601b20e78	ad7566fb-15e1-42b2-a666-336325036d7b	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_12075	Питер Деннис	1.0000	2026-07-19 17:54:23.14261+00	2026-07-19 17:54:23.142612+00	\N	151
ff91f21b-087c-46f5-8972-9a86b1f0b16d	0855aa2a-2de9-4164-8461-60001c848184	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_12076	Клайв Пирс	1.0000	2026-07-19 17:54:23.146419+00	2026-07-19 17:54:23.14642+00	\N	151
107a2deb-a241-40d6-985a-f7dbfed74b7f	1a134efa-d413-46ea-8447-b49b1a68a2da	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_12077	Джим Каммингс	1.0000	2026-07-19 17:54:23.150071+00	2026-07-19 17:54:23.150073+00	\N	151
563c1151-fc87-4e3d-a620-9d8e71fb7ffc	f73c9001-eb85-437b-83e1-0f6d280db498	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_12078	Бобби Блок	1.0000	2026-07-19 17:54:23.153906+00	2026-07-19 17:54:23.153907+00	\N	151
180048a1-e479-4bdc-95da-af2c2d259d12	b545556c-bea5-42c9-bc07-5dee10fe9904	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_12098	Крис Миллер	1.0000	2026-07-19 17:54:23.157467+00	2026-07-19 17:54:23.157468+00	\N	151
08ec1204-ba11-488d-8c57-2342ea453b59	8270ba47-9b11-42e4-8ffe-30f51e9f8626	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_12095	Коуди Камерон	1.0000	2026-07-19 17:54:23.161003+00	2026-07-19 17:54:23.161005+00	\N	151
ea72f562-d8a6-41f7-a6ec-1675843be5ec	fb527f7d-f74a-467c-9593-af47f5e12749	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_7210	Кэтлин Фримен	1.0000	2026-07-19 17:54:23.164227+00	2026-07-19 17:54:23.164228+00	\N	151
cc7780ca-3303-4c64-8d1b-e6577825b3b7	160fb1d4-716b-4ef7-9c90-10333879d806	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_4865931	Michael Galasso	1.0000	2026-07-19 17:54:23.167558+00	2026-07-19 17:54:23.167559+00	\N	151
c21bcc41-b5c9-4a08-ba00-dcc52764c1e9	e033a044-0907-445a-bf36-862bfb0f6322	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_12097	Кристофер Найтс	1.0000	2026-07-19 17:54:23.170825+00	2026-07-19 17:54:23.170826+00	\N	151
02d16ff6-3ab9-480b-868c-d768f6b109b1	6ec4fd76-0b26-4a32-9774-ac313ab191a7	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_44114	Саймон Дж. Смит	1.0000	2026-07-19 17:54:23.174079+00	2026-07-19 17:54:23.174081+00	\N	151
f468530a-e9a2-4625-8a94-9d4df3466d0d	c83c06f0-a896-431a-b643-f0e67b0b4d11	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	\N	director_5524	Эндрю Адамсон	1.0000	2026-07-19 17:54:23.177323+00	2026-07-19 17:54:23.177325+00	\N	151
ce8d3db0-84eb-42e0-a493-c061fc968327	b386e593-80d7-4129-b214-994ff319c9aa	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	\N	director_12058	Vicky Jenson	1.0000	2026-07-19 17:54:23.180616+00	2026-07-19 17:54:23.180617+00	\N	151
a1ba2b71-6feb-4a36-af15-33ea4a5037e0	229c3096-e041-4990-b9a8-7d8e3e644362	8c86f136-2f76-44c4-8d56-e5db5703bff6	7784c033-1ca7-4714-95c7-8110d5d5a496	8c3f9ad2-241e-4d66-9a50-2618621356b3	shrek 2_movie_tpl_movie	Шрэк 2	1.0000	2026-07-19 18:00:09.24871+00	2026-07-19 18:00:09.248713+00	\N	152
cc9b7dd3-40dd-4195-b7cd-c126d41258f7	5ac853dd-6a1a-4d71-8774-578661c88632	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_5823	Джули Эндрюс	1.0000	2026-07-19 18:00:17.264461+00	2026-07-19 18:00:17.264463+00	\N	153
a8ed4e63-c56f-4f31-a238-e751b6c435f7	66c1fc69-fac3-4800-a8e4-b439a25ce422	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_3131	Антонио Бандерас	1.0000	2026-07-19 18:00:17.268968+00	2026-07-19 18:00:17.26897+00	\N	153
52ee8010-258e-450f-b4d5-5a890a15aa2d	f49ff441-4222-4550-ac33-a270547cfd4d	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_8930	Джон Клиз	1.0000	2026-07-19 18:00:17.272884+00	2026-07-19 18:00:17.272885+00	\N	153
e3a0c507-987f-4199-a278-2b2d5a247702	11a99954-254a-4e7e-bd58-3608ad9d192b	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_4757	Руперт Эверетт	1.0000	2026-07-19 18:00:17.277188+00	2026-07-19 18:00:17.27719+00	\N	153
4063e7b6-8904-4253-862a-b5bb7f6cab5e	5424ac10-6763-4503-bfd1-e0823933fee9	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_12094	Дженнифер Сондерс	1.0000	2026-07-19 18:00:17.282078+00	2026-07-19 18:00:17.282079+00	\N	153
069115c4-0d7d-44a1-bc86-b3b2b32ceecc	57b3dd72-a998-4438-a845-5ed8b837191e	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_12106	Арон Уорнер	1.0000	2026-07-19 18:00:17.285916+00	2026-07-19 18:00:17.285917+00	\N	153
098f43d4-255f-4ca1-acd7-2d173b75ebcb	ec021e80-77ec-41fd-9871-de19afde613f	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_12079	Келли Эсбёри	1.0000	2026-07-19 18:00:17.289514+00	2026-07-19 18:00:17.289515+00	\N	153
d9670e8a-00d6-428f-ae57-d1c27c4165e9	c7c27520-d78f-4443-8801-c723b1e9c02a	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_12080	Конрад Вернон	1.0000	2026-07-19 18:00:17.29483+00	2026-07-19 18:00:17.294831+00	\N	153
19818e98-346f-4cd0-9534-4f2a0d66a3d3	259683c9-ad8e-410a-af06-331da98bf1e5	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_1077844	Дэвид П. Смит	1.0000	2026-07-19 18:00:17.300067+00	2026-07-19 18:00:17.300068+00	\N	153
b23c4bca-c593-43bc-a23d-02d8d19d6418	40483f49-65b4-4a7b-bce7-555cd7474b4c	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_71857	Mark Moseley	1.0000	2026-07-19 18:00:17.303316+00	2026-07-19 18:00:17.303317+00	\N	153
e996ca57-23ba-4752-aebf-75828de3ffbb	d9330950-bc06-49bc-aabc-2543652c0fa8	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	\N	director_12080	Конрад Вернон	1.0000	2026-07-19 18:00:17.306564+00	2026-07-19 18:00:17.306565+00	\N	153
feb7943f-7b21-4115-a93f-1c2324d1bc59	56aa342d-fa35-4b84-96a4-75c8a4ec999e	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	\N	director_12079	Келли Эсбёри	1.0000	2026-07-19 18:00:17.310087+00	2026-07-19 18:00:17.310088+00	\N	153
d9cf88f8-0597-4ce3-a92d-63cc1465e370	ac29698a-8d3a-44d5-8720-40ce7c85787d	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_603_6384	Neo	1.0000	2026-07-19 18:56:27.732257+00	2026-07-19 18:56:27.732259+00	\N	154
97921b0b-4188-45ca-ae5f-f927e7b6def0	523a5c7b-d459-4d32-a647-d888d5f6f738	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_603_2975	Morpheus	1.0000	2026-07-19 18:56:27.741944+00	2026-07-19 18:56:27.741946+00	\N	154
ceff0138-d38a-4abb-9cec-e7d7dbef171c	d830d8f3-593e-4195-9cbc-97c37653c14c	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_603_530	Trinity	1.0000	2026-07-19 18:56:27.748786+00	2026-07-19 18:56:27.748787+00	\N	154
d2fbd49c-b31e-4da0-8d1f-3195197ff396	90464e8a-fc3a-4576-bbdf-94c81971c321	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_603_1331	Agent Smith	1.0000	2026-07-19 18:56:27.755234+00	2026-07-19 18:56:27.755235+00	\N	154
5020c846-3bde-4aba-8ce7-fef4bc15b075	66528ea1-0831-4868-adab-f3588e2b964c	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_603_9364	Oracle	1.0000	2026-07-19 18:56:27.761443+00	2026-07-19 18:56:27.761444+00	\N	154
5257a443-20b5-4331-825a-d8fb1f43eb37	d5f7dd2e-f165-4b1e-977e-6ab1ac54f5e2	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_603_532	Cypher	1.0000	2026-07-19 18:56:27.768046+00	2026-07-19 18:56:27.768048+00	\N	154
977c75f1-743e-40b6-b308-a93c0e2ff195	7becbb13-0dad-4669-8f9b-6b857799a05a	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_603_9372	Tank	1.0000	2026-07-19 18:56:27.774128+00	2026-07-19 18:56:27.774129+00	\N	154
2f4c6d3c-bbc2-461b-8088-1a14c0b018ab	02ba8507-0771-481d-9a92-bdbad5658629	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_603_7244	Apoc	1.0000	2026-07-19 18:56:27.779917+00	2026-07-19 18:56:27.779918+00	\N	154
c1b51ade-a25a-4e04-a8da-2773d699b48e	3a647e68-82c5-4c8b-83f9-20faf8d51ec8	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_603_9374	Mouse	1.0000	2026-07-19 18:56:27.786024+00	2026-07-19 18:56:27.786025+00	\N	154
b7061ee7-f373-4b43-b56d-cab2f9dcb895	d0b81c6a-4ada-4567-9f87-6e697c0d0efb	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_603_9376	Switch	1.0000	2026-07-19 18:56:27.791876+00	2026-07-19 18:56:27.791877+00	\N	154
0c8d8a8e-2521-4dfc-a392-9084a8498230	29c51f60-52c2-4e92-bf73-08c289059cf6	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_603_9378	Dozer	1.0000	2026-07-19 18:56:27.797665+00	2026-07-19 18:56:27.797667+00	\N	154
13b8e6df-c5c4-43d8-ac0d-a08220eabed8	6773e984-aa56-4c9c-99f1-deac1c967325	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_603_9383	Rhineheart	1.0000	2026-07-19 18:56:27.815597+00	2026-07-19 18:56:27.815599+00	\N	154
5b94ada5-9d41-4c0c-be33-534db9b41ec0	a2b416c0-b4a3-4303-924a-87cbaeee7b38	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_603_9384	Choi	1.0000	2026-07-19 18:56:27.822938+00	2026-07-19 18:56:27.82294+00	\N	154
30eb75f8-d8d0-4524-b3e2-138db4604559	883166fd-b28b-4e97-902d-e080991ef752	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_809_12073	Shrek (voice)	1.0000	2026-07-19 18:59:48.508057+00	2026-07-19 18:59:48.508059+00	\N	155
db332f76-589d-4e7b-9864-eab3571ef0e4	0983686f-848a-441c-8e62-1802e2522a20	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_809_776	Donkey (voice)	1.0000	2026-07-19 18:59:48.515761+00	2026-07-19 18:59:48.515763+00	\N	155
5c33b912-a978-47b0-b9d8-4ad469c810c9	7f82e79b-d981-497e-8b7a-3fa95630a433	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_809_6941	Princess Fiona (voice)	1.0000	2026-07-19 18:59:48.522666+00	2026-07-19 18:59:48.522668+00	\N	155
02eb93b4-c73e-4c96-a701-111808e28ab8	90fab262-c29e-4e2d-adea-5887ad1312f0	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_809_5823	Queen Lillian (voice)	1.0000	2026-07-19 18:59:48.532586+00	2026-07-19 18:59:48.532588+00	\N	155
6fe6d5c2-0a4e-4bf0-9481-74f6339d16f8	470cd6bb-540a-4620-b8d0-45026599ce8c	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_809_3131	Puss in Boots (voice)	1.0000	2026-07-19 18:59:48.539576+00	2026-07-19 18:59:48.539577+00	\N	155
2e9ef9fc-59b4-42a6-b119-21f68cf0efb9	17b5a4fd-013e-4c64-a8e9-2e953f12efe1	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_809_8930	King Harold (voice)	1.0000	2026-07-19 18:59:48.546424+00	2026-07-19 18:59:48.546426+00	\N	155
180c5397-e1f2-4dfc-8803-f0f524667761	6816830a-a41a-4397-8f04-75370ddf85fa	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_809_4757	Prince Charming (voice)	1.0000	2026-07-19 18:59:48.553161+00	2026-07-19 18:59:48.553163+00	\N	155
8c065b5a-60ef-4585-b272-cb021f7c264d	3f41d21f-8f62-4c5d-a8ff-823b0739f897	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_809_12094	Fairy Godmother (voice)	1.0000	2026-07-19 18:59:48.560257+00	2026-07-19 18:59:48.560259+00	\N	155
6630f199-08f3-4bb0-bc09-8e1ae0ca884d	9a1bb389-8a7f-45a1-90c3-e9a9d5a9484b	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_809_12106	Wolf (voice)	1.0000	2026-07-19 18:59:48.567265+00	2026-07-19 18:59:48.567266+00	\N	155
c2f0c449-e228-4cfa-a2ac-0425aa4ad10c	e2cea8f1-7a08-4c03-b204-3ace121057cf	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_809_12079	Page / Elf / Nobleman / Nobleman's Son (voice)	1.0000	2026-07-19 18:59:48.574684+00	2026-07-19 18:59:48.574686+00	\N	155
b7bd9346-0a67-44aa-9d22-0f0fff577c70	5ed8f232-6eca-4033-bdee-725292684348	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_809_12095	Pinocchio / Three Pigs (voice)	1.0000	2026-07-19 18:59:48.58094+00	2026-07-19 18:59:48.580942+00	\N	155
97b40ffe-2d44-4260-a644-7ce53b3519f0	6c187652-aa74-462a-8ce9-606af3e4ca49	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_809_12080	Gingerbread Man / Cedric / Announcer / Muffin Man / Mongo (voice)	1.0000	2026-07-19 18:59:48.587799+00	2026-07-19 18:59:48.5878+00	\N	155
1ba5945b-a622-4164-b2a7-116a9db35201	bc7e0f85-a611-46f3-851b-5970a3ae369b	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_809_12097	Blind Mouse (voice)	1.0000	2026-07-19 18:59:48.593949+00	2026-07-19 18:59:48.593951+00	\N	155
13a57abd-ff73-4536-bf0e-a14cb8c7e0f7	4e8f67e3-57c9-4acb-a3c8-35063990f7e8	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_809_1077844	Herald / Man with Box (voice)	1.0000	2026-07-19 18:59:48.600607+00	2026-07-19 18:59:48.600608+00	\N	155
fc37ff77-e9cd-4411-95e2-f48e05c3d6ef	dedb547a-ba06-4560-a1a1-44cd1eef2ac8	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_809_71857	Mirror / Dresser (voice)	1.0000	2026-07-19 18:59:48.60717+00	2026-07-19 18:59:48.607171+00	\N	155
af8499a8-5fe9-4d0f-96a9-537c15fc2b81	243465dd-ea0f-47ba-a95b-8a82ea75df5e	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_808_12073	Shrek / Blind Mouse (voice)	1.0000	2026-07-19 19:00:09.522922+00	2026-07-19 19:00:09.522926+00	\N	156
37ba971e-2a02-43ee-937b-295df2b89dbb	d0c4d4f7-e5a9-4136-a98d-ce2523c56f52	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_808_776	Donkey (voice)	1.0000	2026-07-19 19:00:09.532594+00	2026-07-19 19:00:09.532595+00	\N	156
5af53614-0b0b-4410-9215-7368eb07e348	344bb824-8999-4300-908a-4fd54cbf0ea6	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_808_6941	Princess Fiona (voice)	1.0000	2026-07-19 19:00:09.539275+00	2026-07-19 19:00:09.539277+00	\N	156
41e3ebb7-7e87-420b-a048-2ddb0802cced	933317ac-7ab5-4847-97b1-ab27f87c8175	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_808_12074	Lord Farquaad (voice)	1.0000	2026-07-19 19:00:09.54566+00	2026-07-19 19:00:09.545662+00	\N	156
54a1bc1b-9f2a-407b-a101-a38a7b6f64e1	d5656cb6-1892-4b2f-ad26-9ab8d7b9b36f	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_808_1925	Monsieur Hood (voice)	1.0000	2026-07-19 19:00:09.55183+00	2026-07-19 19:00:09.551832+00	\N	156
0a4812b1-25fb-4722-ba1c-299ba936f018	29891216-e6a1-49fb-89f7-1402edf76d15	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_808_12075	Ogre Hunter (voice)	1.0000	2026-07-19 19:00:09.558936+00	2026-07-19 19:00:09.558939+00	\N	156
bf8f9398-aeee-469d-ba79-7a3013a9663c	3240c58a-d7b5-469c-96a5-5238a42a0106	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_808_12076	Ogre Hunter (voice)	1.0000	2026-07-19 19:00:09.5686+00	2026-07-19 19:00:09.568601+00	\N	156
73a692e5-1287-4cf1-836b-4505963848c6	adaedd26-2341-410c-9568-7420219b5c9b	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_808_12077	Captain of the Guards (voice)	1.0000	2026-07-19 19:00:09.575786+00	2026-07-19 19:00:09.575788+00	\N	156
c361e975-ebce-456e-b13c-c8171b27c183	9ed7d6a4-9cfe-42de-8463-24af8f242f8a	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_808_12078	Baby Bear (voice)	1.0000	2026-07-19 19:00:09.581744+00	2026-07-19 19:00:09.581746+00	\N	156
b35b2264-99b7-4692-b71a-52a3b6400344	e1d73f3b-dc6b-4f88-b42c-3ca16ded87f1	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_808_12098	Geppetto / Magic Mirror (voice)	1.0000	2026-07-19 19:00:09.587628+00	2026-07-19 19:00:09.58763+00	\N	156
8ac53ce1-018f-4f39-957f-52aaed4554a2	ba7d4a8b-36e3-470c-a2a4-9c01bda0ad73	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_808_12095	Pinnochio / Three Pigs (voice)	1.0000	2026-07-19 19:00:09.59354+00	2026-07-19 19:00:09.593541+00	\N	156
3c8a53a8-ce96-4362-b48a-7656a9bc4f5c	06b01798-92f4-4cbc-97cf-9b4206bb71a6	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_808_7210	Old Woman  (voice)	1.0000	2026-07-19 19:00:09.599471+00	2026-07-19 19:00:09.599473+00	\N	156
2a8c0373-d4ab-4644-a92b-c91c7d6d93dd	83043a41-8c2a-49e9-ac00-bfa18d7496db	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_808_4865931	Peter Pan (voice)	1.0000	2026-07-19 19:00:09.604899+00	2026-07-19 19:00:09.6049+00	\N	156
9f22f322-665a-4f02-9902-803885828421	0ec21891-3421-4a67-b856-565fa413210f	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_808_12097	Blind Mouse / Thelonious (voice)	1.0000	2026-07-19 19:00:09.610782+00	2026-07-19 19:00:09.610783+00	\N	156
fcfd7d95-f4ee-4ea1-bbf6-a0120209771c	e2886d37-3d47-448d-a873-a88f9ee476a5	801d5718-54ec-44c7-85da-af53af4d7acc	\N	\N	character_808_44114	Blind Mouse (voice)	1.0000	2026-07-19 19:00:09.617391+00	2026-07-19 19:00:09.617392+00	\N	156
0bc444bd-8e8c-4528-856d-c62ede688596	b1bc0591-73b3-4ce3-b2a6-46167d7c781b	8c86f136-2f76-44c4-8d56-e5db5703bff6	353e45c6-d01f-4f01-96bb-82558d68f234	\N	onttmpl_charaster_cinema	Шаблон: Персонаж	1.0000	2026-07-19 19:05:43.798642+00	2026-07-19 19:05:43.798644+00	\N	4
d22f2ed3-803a-41d9-b9b8-529945ebc076	b5f0c24d-a156-478a-aecc-e36a066571e8	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	8c3f9ad2-241e-4d66-9a50-2618621356b3	character_603_9380_charaster_cinema	character_603_9380	1.0000	2026-07-19 19:18:06.190172+00	2026-07-19 19:18:06.190183+00	\N	157
b29803f0-f257-4530-9c9c-de1ad01ea561	9ecebfcf-5ac0-4bd9-87fb-4c94eee5a7e0	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	8c3f9ad2-241e-4d66-9a50-2618621356b3	character_603_39545_charaster_cinema	character_603_39545	1.0000	2026-07-19 19:43:42.302719+00	2026-07-19 19:43:42.302723+00	\N	157
9b4b190b-7734-443e-b3e0-3900b78219d5	4d51480b-62d4-4e80-9e0d-788e06b9de9e	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_417	Джиннифер Гудвин	1.0000	2026-07-19 19:48:41.500292+00	2026-07-19 19:48:41.500297+00	\N	157
da161a64-29c2-4aab-9a82-39052d22ffa1	89253a08-ed05-452e-966f-d7b8115fbf03	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_269149_417	Judy Hopps (voice)	1.0000	2026-07-19 19:48:41.51255+00	2026-07-19 19:48:41.512552+00	\N	157
92fb377c-ac7f-4c80-9678-270ec3e66f88	de7a2e08-de57-4c26-918b-0bc5c175760e	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_23532	Джейсон Бейтман	1.0000	2026-07-19 19:48:41.519559+00	2026-07-19 19:48:41.51956+00	\N	157
b4be05d9-ff7d-453f-8c20-dabc50c1076b	39134944-dfa8-4c1b-ba5a-887b0125c67c	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_269149_23532	Nick Wilde (voice)	1.0000	2026-07-19 19:48:41.52294+00	2026-07-19 19:48:41.522941+00	\N	157
7bf3a464-0efd-46e7-89f3-0b93fc8cbfec	e7c2c4d3-cc9c-4a7e-bda0-c5a7208c2d76	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_17605	Идрис Эльба	1.0000	2026-07-19 19:48:41.527407+00	2026-07-19 19:48:41.527408+00	\N	157
ac4fd994-cd7f-4210-ad16-3f6ddcc04dfb	8c418373-1974-4784-8fa4-ddd8d6847cdb	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_269149_17605	Chief Bogo (voice)	1.0000	2026-07-19 19:48:41.531647+00	2026-07-19 19:48:41.531649+00	\N	157
e1141415-42c8-4e7e-ad71-8a9d7949af2b	4d282837-83a7-4203-88e6-4d4a7b00c624	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_213001	Дженни Слейт	1.0000	2026-07-19 19:48:41.536137+00	2026-07-19 19:48:41.536138+00	\N	157
64557dc0-c440-49ae-830d-1fb7b8bc7cd4	758a85b5-ecd8-4c74-a4ec-571fe809c89d	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_269149_213001	Bellwether (voice)	1.0000	2026-07-19 19:48:41.539499+00	2026-07-19 19:48:41.539501+00	\N	157
8c2e35b8-9457-423b-8107-ff861a32ada8	4b0bed58-440b-420e-ac2c-fd232ae80222	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_41565	Нэйт Торренс	1.0000	2026-07-19 19:48:41.54479+00	2026-07-19 19:48:41.544791+00	\N	157
7991833c-a5a2-47f2-810e-577ca04f19ab	6967b660-ee0c-4349-be84-c4a141974b91	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_269149_41565	Clawhauser (voice)	1.0000	2026-07-19 19:48:41.548456+00	2026-07-19 19:48:41.548458+00	\N	157
264ef215-8f96-4cba-a23c-5be136094a44	3c62d619-d614-464c-9e6a-bf5af782d2e5	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_5149	Бонни Хант	1.0000	2026-07-19 19:48:41.553233+00	2026-07-19 19:48:41.553235+00	\N	157
8009dcc2-8de4-4cb1-b19c-9a730c66be8e	baee7a49-84af-4574-a6ed-519ef8ec16d0	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_269149_5149	Bonnie Hopps (voice)	1.0000	2026-07-19 19:48:41.556692+00	2026-07-19 19:48:41.556694+00	\N	157
62a456b7-2791-4c6b-9e6e-d4bd41360679	768b0ca6-cd5e-421f-b1fc-37ebdf55525a	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_27530	Дон Лейк	1.0000	2026-07-19 19:48:41.561358+00	2026-07-19 19:48:41.561359+00	\N	157
914f7b6a-c092-4a86-a316-f3540f598cc3	336c833e-2a5d-4d89-84a5-bd439126cc41	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_269149_27530	Stu Hopps (voice)	1.0000	2026-07-19 19:48:41.564705+00	2026-07-19 19:48:41.564706+00	\N	157
af267160-e15e-4b14-a47f-48ab7b959736	1ebc284d-9509-449e-82a9-11fbafa60126	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_63208	Томми Чонг	1.0000	2026-07-19 19:48:41.569361+00	2026-07-19 19:48:41.569362+00	\N	157
54ab11f2-cc7f-4ec9-8fdf-3a5b1cfa49ce	d25ceccc-8274-4b2f-a178-f3b87acbaa28	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_269149_63208	Yax (voice)	1.0000	2026-07-19 19:48:41.572788+00	2026-07-19 19:48:41.572789+00	\N	157
c458c1e4-f199-495a-bdc4-562391032b77	28a1a6b1-1903-44a2-9e92-bb6c30ce17ad	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_18999	Джей Кей Симмонс	1.0000	2026-07-19 19:48:41.577309+00	2026-07-19 19:48:41.57731+00	\N	157
35cd9130-4138-4d44-ab5c-6dd21091016a	c5b29f37-2299-49b4-b42b-1891b9650e4a	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_269149_18999	Mayor Lionheart (voice)	1.0000	2026-07-19 19:48:41.58071+00	2026-07-19 19:48:41.580711+00	\N	157
39e404d1-d653-47ac-ae0b-fc78906edca1	ec1e4fa0-b379-40d7-a304-53f121c7dcd1	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_6944	Октавия Спенсер	1.0000	2026-07-19 19:48:41.585379+00	2026-07-19 19:48:41.585381+00	\N	157
74404fe0-601d-40bd-a806-3ccd33c7b253	4aa2b2e2-0ba4-4a21-a2c3-ea96cad84fee	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_269149_6944	Mrs. Otterton (voice)	1.0000	2026-07-19 19:48:41.588734+00	2026-07-19 19:48:41.588736+00	\N	157
17596c41-45c8-4194-b5b9-8ad59de8023c	2c7cae86-9da7-4161-a1dc-c61585ef73e9	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_21088	Алан Тьюдик	1.0000	2026-07-19 19:48:41.593265+00	2026-07-19 19:48:41.593266+00	\N	157
fcb69ad1-6d9e-49ba-bd05-93d6b53ef1f7	3db35cb3-700b-47e7-b923-e1e32b83bb2f	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_269149_21088	Duke Weaselton (voice)	1.0000	2026-07-19 19:48:41.596302+00	2026-07-19 19:48:41.596304+00	\N	157
a06660e0-613e-4ee1-be30-f46394bccacb	37beaa06-448e-41c1-a19b-9b90bbc5a8e2	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_446511	Шакира	1.0000	2026-07-19 19:48:41.60098+00	2026-07-19 19:48:41.600981+00	\N	157
1dd7a142-9b0d-47b7-832e-bd03833212a1	bd7dfea1-7379-4774-9654-46ea90f5ed81	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_269149_446511	Gazelle (voice)	1.0000	2026-07-19 19:48:41.604164+00	2026-07-19 19:48:41.604165+00	\N	157
3893ce3f-1cb6-4736-aad0-23de74a265bf	b6e7c077-56e0-4156-88e6-05a2a6ddd2d8	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_1223658	Рэймонд С. Перси	1.0000	2026-07-19 19:48:41.608276+00	2026-07-19 19:48:41.608277+00	\N	157
1460e1da-0058-4c32-ab21-ad0f0ac86630	b56cffab-b7e8-4f68-9a91-db0e683e1232	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_269149_1223658	Flash (voice)	1.0000	2026-07-19 19:48:41.61152+00	2026-07-19 19:48:41.611522+00	\N	157
d146a201-ff80-48ca-bea8-2d893c6d460b	aa1a3294-70ac-4c96-99fc-160aae00c0d1	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_1610446	Della Saba	1.0000	2026-07-19 19:48:41.615685+00	2026-07-19 19:48:41.615686+00	\N	157
502a57b2-0c2c-4671-a64a-f92efbfbbb04	765237cf-fbcd-4b5b-9a34-4ea0f51ea5ce	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_269149_1610446	Young Hopps (voice)	1.0000	2026-07-19 19:48:41.618759+00	2026-07-19 19:48:41.618761+00	\N	157
f5661936-9491-4aee-84ae-5068eb7128e0	7d6ecb14-1cd7-41e1-8594-60efb56b832d	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_34521	Морис Ламарш	1.0000	2026-07-19 19:48:41.622886+00	2026-07-19 19:48:41.622887+00	\N	157
91ec158e-f1aa-43ca-93b4-46d9dc975a6d	35b08f2f-cf9f-4af4-ba8d-6c7ee122b062	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_269149_34521	Mr. Big (voice)	1.0000	2026-07-19 19:48:41.625906+00	2026-07-19 19:48:41.625907+00	\N	157
f818e778-d141-461a-827a-fed2c0fca280	2c52c7a0-b375-40a7-89fb-7aa37e426655	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	\N	director_76595	Байрон Ховард	1.0000	2026-07-19 19:48:41.630024+00	2026-07-19 19:48:41.630026+00	\N	157
0abba340-8d2f-4ed7-9f6b-e6cfe890f527	98f27997-e5e8-47b6-93de-a2da4cda2af3	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	\N	director_165787	Рич Мур	1.0000	2026-07-19 19:48:41.633344+00	2026-07-19 19:48:41.633345+00	\N	157
67c9f624-5a95-4306-bffd-20d073d71275	87814d62-16a3-4e34-8dc0-03ec5a78f28d	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_8891	Джон Траволта	1.0000	2026-07-19 19:59:31.90367+00	2026-07-19 19:59:31.903686+00	\N	158
273d5a5e-c088-44ed-a37a-b1526d123c81	7c69de82-5026-43f1-a6c2-b43523920b15	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_680_8891	Vincent Vega	1.0000	2026-07-19 19:59:31.911188+00	2026-07-19 19:59:31.91119+00	\N	158
f274b66c-aa34-4977-8718-f93a90504eff	220e556b-14bd-48d3-9360-96018d7ac784	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_2231	Сэмюэл Л. Джексон	1.0000	2026-07-19 19:59:31.915829+00	2026-07-19 19:59:31.91583+00	\N	158
93d6ae16-d715-48ef-ae0a-9c952d301899	d1a6f8bc-0d39-4a37-8a58-d9f44bb87212	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_680_2231	Jules Winnfield	1.0000	2026-07-19 19:59:31.918986+00	2026-07-19 19:59:31.918987+00	\N	158
07c72226-91da-4cce-b159-bbb3fe96af0d	59fd53ef-6ef3-4881-9773-9a6db97ae7d8	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_139	Ума Турман	1.0000	2026-07-19 19:59:31.923086+00	2026-07-19 19:59:31.923087+00	\N	158
af4ee5a7-87f5-41d9-833b-2f427eba1d60	be680376-546c-4896-aee1-b567e094396f	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_680_139	Mia Wallace	1.0000	2026-07-19 19:59:31.926073+00	2026-07-19 19:59:31.926074+00	\N	158
a80e64cf-6154-4b65-8cc8-49ecb5eefbe3	a77e6546-5b15-4eb5-a847-7a3db999431b	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_62	Брюс Уиллис	1.0000	2026-07-19 19:59:31.930179+00	2026-07-19 19:59:31.93018+00	\N	158
8b80bc82-fad2-4183-b3c5-236ef2445d8b	f8082a95-3a70-4103-a9ca-615731d702fe	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_680_62	Butch Coolidge	1.0000	2026-07-19 19:59:31.933192+00	2026-07-19 19:59:31.933193+00	\N	158
aeff218b-e7a7-4aa3-982c-1db5190eea43	54c31fa7-0f61-4967-8057-1acde78186c7	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_10182	Винг Реймз	1.0000	2026-07-19 19:59:31.937148+00	2026-07-19 19:59:31.93715+00	\N	158
4ed26f91-d573-48d1-bd0b-e81e1700ba1e	c8d15721-a419-4cab-9bfc-b6e7249c77bb	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_680_10182	Marsellus Wallace	1.0000	2026-07-19 19:59:31.940684+00	2026-07-19 19:59:31.940685+00	\N	158
3f7b450d-cc20-43e5-afcf-9b2f2ffefa67	e09eeed4-6e9e-4ce5-a66b-3b62e9884d23	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_1037	Харви Кейтель	1.0000	2026-07-19 19:59:31.944747+00	2026-07-19 19:59:31.944748+00	\N	158
0368dac9-cff7-482e-bf94-547f63a89d16	e12285f3-076b-473e-82ff-e7a8517d49ac	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_680_1037	The Wolf	1.0000	2026-07-19 19:59:31.947757+00	2026-07-19 19:59:31.947758+00	\N	158
c9c1bdc9-3797-4400-9f7d-bb9db9735f45	fd2725fe-9094-4e29-91a4-afdfe3877e4c	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_7036	Эрик Штольц	1.0000	2026-07-19 19:59:31.951892+00	2026-07-19 19:59:31.951893+00	\N	158
3cc77c76-08e4-47cd-986a-92a5d027ed6e	ce98a882-8980-43eb-9995-019b022df28a	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_680_7036	Lance	1.0000	2026-07-19 19:59:31.954995+00	2026-07-19 19:59:31.954996+00	\N	158
9ff87f0f-0980-42b8-b126-c9babc559538	d631016e-2a42-42af-95a8-a225eb96a473	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_3129	Тим Рот	1.0000	2026-07-19 19:59:31.959108+00	2026-07-19 19:59:31.959109+00	\N	158
6d7de9d2-72e7-42e2-bdb4-8240914e16c8	60a01a47-e33f-48ec-929b-dbe3da458d08	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_680_3129	Pumpkin	1.0000	2026-07-19 19:59:31.962135+00	2026-07-19 19:59:31.962136+00	\N	158
f09b19fd-2f9c-4978-862b-6dba4039f12f	86e86f24-6bda-490f-88e6-ba92c365dbd0	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_99	Аманда Пламмер	1.0000	2026-07-19 19:59:31.966142+00	2026-07-19 19:59:31.966143+00	\N	158
95f9f6bf-0762-41a4-bd7d-fc0174610ed4	b97431db-599d-4e5f-be33-19c579f1b942	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_680_99	Honey Bunny	1.0000	2026-07-19 19:59:31.969125+00	2026-07-19 19:59:31.969126+00	\N	158
fc0a62fb-ca91-4b8f-aa90-09817fdb2aae	ad618e1d-d36b-4937-8037-515d6fad866c	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_2319	Мария де Медейруш	1.0000	2026-07-19 19:59:31.97766+00	2026-07-19 19:59:31.977662+00	\N	158
7a928702-5d9a-4c9d-8edc-802af6044700	35476ee0-ad26-4c7d-9d7d-e82f46d5b1cb	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_680_2319	Fabienne	1.0000	2026-07-19 19:59:31.983599+00	2026-07-19 19:59:31.9836+00	\N	158
8eb99f48-0448-4835-9bb8-95440e9d84c4	d99db646-f219-44f4-8ff2-387ba5ceddb6	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_138	Квентин Тарантино	1.0000	2026-07-19 19:59:31.990839+00	2026-07-19 19:59:31.990841+00	\N	158
18bf1029-f72e-4c7e-9f1b-267acefa7bdd	7df1ed35-88e8-490e-a5dc-7791684c1cde	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_680_138	Jimmie Dimmick	1.0000	2026-07-19 19:59:31.99802+00	2026-07-19 19:59:31.998022+00	\N	158
011abc73-09cd-496a-830e-2c18ceba5709	da298a62-6ff0-43b8-b9ad-008800d934b4	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_4690	Кристофер Уокен	1.0000	2026-07-19 19:59:32.004138+00	2026-07-19 19:59:32.00414+00	\N	158
eb724143-0021-4367-9398-73d93c7ddf2b	0d569910-8953-486f-85c4-3540d8efc979	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_680_4690	Captain Koons	1.0000	2026-07-19 19:59:32.007843+00	2026-07-19 19:59:32.007845+00	\N	158
5ab4456c-f3b0-4f3c-9133-51f341cfd762	adb70f3f-257f-4b66-beea-2d0ff3142eea	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_2165	Розанна Аркетт	1.0000	2026-07-19 19:59:32.014202+00	2026-07-19 19:59:32.014204+00	\N	158
19572261-c80f-48d5-85fc-08403eecfa24	d870f544-ea59-412e-868d-8f1281cbad95	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_680_2165	Jody	1.0000	2026-07-19 19:59:32.019329+00	2026-07-19 19:59:32.019331+00	\N	158
aa3aee87-0fe7-4dd3-8aa4-a2113673916d	d295ce90-1f32-463b-9a7d-cb77d4ba8fe9	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_11803	Питер Грин	1.0000	2026-07-19 19:59:32.023934+00	2026-07-19 19:59:32.023935+00	\N	158
c8260e42-a05c-457d-a614-54c14a2b71ce	42fb105e-da54-46c4-9612-325bb33f4512	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_680_11803	Zed	1.0000	2026-07-19 19:59:32.027163+00	2026-07-19 19:59:32.027164+00	\N	158
db0a812a-b276-48f4-866b-a2d1d57ab6b1	e248cb29-34df-4aa2-bc9a-7ad069d9b043	8c86f136-2f76-44c4-8d56-e5db5703bff6	25155646-3c08-4147-9019-754e9967a655	\N	actor_11804	Дуан Уайтакер	1.0000	2026-07-19 19:59:32.032757+00	2026-07-19 19:59:32.032759+00	\N	158
71b9c2c8-db71-44b6-808a-ad43ac25d6e5	fd29096b-43b9-4e34-9f08-caeabc31b545	8c86f136-2f76-44c4-8d56-e5db5703bff6	d2996896-e993-4cc1-947f-8880a340cb2a	\N	character_680_11804	Maynard	1.0000	2026-07-19 19:59:32.035991+00	2026-07-19 19:59:32.035993+00	\N	158
a507779e-40a9-4731-abbf-96c9d9f90d2e	2fe65b14-7a7f-4c13-868c-115bf8430f0a	8c86f136-2f76-44c4-8d56-e5db5703bff6	18ddf8f2-d7b7-4a52-911c-48756f13c292	\N	director_138	Квентин Тарантино	1.0000	2026-07-19 19:59:32.040016+00	2026-07-19 19:59:32.040017+00	\N	158
\.


--
-- Data for Name: entity_template_assignment; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.entity_template_assignment (assignment_id, entity_id, template_id, assigned_at, valid_from, valid_to, version_id) FROM stdin;
\.


--
-- Data for Name: event_log; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.event_log (event_id, entity_id, projection_id, relation_id, asset_id, event_type, payload, caused_by, occurred_at, version_id) FROM stdin;
6edde6e5-7fe1-44c2-a80a-574ee5363044	d0000001-0000-0000-0000-000000000005	\N	\N	\N	state_transition	{"new": {"workflow_state": "archived"}, "old": {"workflow_state": "published"}}	admin	2026-07-20 10:07:29.604763+00	1
a9246675-65a2-42ce-b063-51f5ec23bd3b	d0000001-0000-0000-0000-000000000005	\N	\N	\N	state_transition	{"new": {"workflow_state": "published"}, "old": {"workflow_state": "archived"}}	admin	2026-07-20 10:08:33.541667+00	1
\.


--
-- Data for Name: field_registry; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.field_registry (field_id, field_key, field_label, field_type, category, default_value, options, sort_order, is_active, created_at) FROM stdin;
428e23ce-84b3-41a6-9f82-5e63c2d0facd	title	Название	string	common	\N	[]	1	t	2026-07-18 09:56:49.730033+00
51dbe5a1-7a86-44f5-812c-a2a0b2b828bc	description	Описание	textarea	common	\N	[]	2	t	2026-07-18 09:56:49.730033+00
291b0a5a-803d-4592-8ea4-0a261d55c1f7	year	Год	integer	common	\N	[]	3	t	2026-07-18 09:56:49.730033+00
40a1395b-5155-4f73-bfba-f9b99e47abae	genre	Жанр	string	common	\N	[]	4	t	2026-07-18 09:56:49.730033+00
09bb8c88-658c-472b-af4e-dfbf8259692c	rating	Рейтинг	number	common	\N	[]	5	t	2026-07-18 09:56:49.730033+00
fda6f45c-5d1a-4cfd-9ba6-23648041a446	country	Страна	string	common	\N	[]	6	t	2026-07-18 09:56:49.730033+00
80564c9a-5599-4ea6-94f7-421884ff6c89	language	Язык	string	common	\N	[]	7	t	2026-07-18 09:56:49.730033+00
c6a7c8a6-0053-4915-9437-2d1bea8befa7	budget_mln	Бюджет (млн)	currency	common	\N	[]	8	t	2026-07-18 09:56:49.730033+00
29dfaec9-c496-4d3a-8090-71dc0c054e4b	duration_min	Длительность (мин)	integer	common	\N	[]	9	t	2026-07-18 09:56:49.730033+00
bda122fd-478d-46f6-85ca-9ad9238f4189	author	Автор	string	common	\N	[]	10	t	2026-07-18 09:56:49.730033+00
b9ba75a0-11d3-4568-ac0e-5f90bb0d7b5f	pages	Страниц	integer	common	\N	[]	11	t	2026-07-18 09:56:49.730033+00
26e9b1b7-37a8-42b2-8f40-a5aa2cb82780	isbn	ISBN	string	common	\N	[]	12	t	2026-07-18 09:56:49.730033+00
3afb5c9c-c887-4d90-be99-9074df4df542	artist	Исполнитель	string	music	\N	[]	13	t	2026-07-18 09:56:49.730033+00
3254d763-e424-495f-b98d-1330df82b826	album	Альбом	string	music	\N	[]	14	t	2026-07-18 09:56:49.730033+00
bf9450bf-8e84-4900-ac3d-b75d2de015e8	bpm	BPM	integer	music	\N	[]	15	t	2026-07-18 09:56:49.730033+00
45c07be8-295a-4a35-ac8f-d9607ff4a9e1	release_date	Дата выхода	date	common	\N	[]	16	t	2026-07-18 09:56:49.730033+00
0b494842-2785-49c3-9394-0c3fd936d444	start_date	Дата начала	date	common	\N	[]	17	t	2026-07-18 09:56:49.730033+00
0535c473-8d0c-440f-b268-f85079acda69	end_date	Дата окончания	date	common	\N	[]	18	t	2026-07-18 09:56:49.730033+00
1a6a704f-aac1-453c-bde8-555444d72d3f	price	Цена	currency	common	\N	[]	19	t	2026-07-18 09:56:49.730033+00
2e6394b3-c1ea-4b44-b079-12aa396e1a8f	website	Сайт	url	common	\N	[]	20	t	2026-07-18 09:56:49.730033+00
e5ff7079-1bf5-4255-a7ab-af237c5d3889	email	Email	email	common	\N	[]	21	t	2026-07-18 09:56:49.730033+00
09c2c957-4c67-4bf0-b1df-30e3e55477d3	content	Контент (Markdown)	textarea	common	\N	[]	22	t	2026-07-18 09:56:49.730033+00
2fd1cdc5-4faa-4594-bdda-042ee0470e6e	poster_url	Постер	image	media	\N	[]	23	t	2026-07-18 09:56:49.730033+00
9ab0aba5-2ccc-44e5-8a00-47f206c92513	images	Изображения	gallery	media	\N	[]	24	t	2026-07-18 09:56:49.730033+00
962dc7ec-1623-42f2-af82-40775b3236eb	video_url	Видео	video	media	\N	[]	25	t	2026-07-18 09:56:49.730033+00
0a1aa9e5-253d-440a-bbe3-2d316a16aff1	audio_url	Аудио	audio	media	\N	[]	26	t	2026-07-18 09:56:49.730033+00
0d0084bc-08a2-4d9c-8fac-b1c08e4e9d29	file_url	Файл	file	media	\N	[]	27	t	2026-07-18 09:56:49.730033+00
b29d9171-c3ab-421d-a5ed-4417a17101f0	file_title	Название файла	string	media	\N	[]	28	t	2026-07-18 09:56:49.730033+00
ce8b30a9-a39c-42bf-92dd-4a1e4214f85c	imdb_id	IMDb ID	string	cinema	\N	[]	29	t	2026-07-18 09:56:49.730033+00
ee8c8567-7f11-4f91-827e-e0b6d3c4e6be	tmdb_id	TMDb ID	string	cinema	\N	[]	30	t	2026-07-18 09:56:49.730033+00
59a5ed15-ceb9-4dac-8be8-d2df2ace5af5	runtime	Хронометраж (мин)	integer	cinema	\N	[]	31	t	2026-07-18 09:56:49.730033+00
5a34ba9b-4f41-4a5d-ad47-3bbf05298dda	mpaa_rating	Рейтинг MPAA	select	cinema	\N	[]	32	t	2026-07-18 09:56:49.730033+00
a1a03cf3-850a-4b16-81d2-2ed62079c36a	budget	Бюджет	currency	cinema	\N	[]	33	t	2026-07-18 09:56:49.730033+00
0bfac275-4672-49f0-80ad-86509972ce01	revenue	Сборы	currency	cinema	\N	[]	34	t	2026-07-18 09:56:49.730033+00
f2ec643c-aaf3-476c-9317-0654ce029c1d	filming_locations	Места съёмок	textarea	cinema	\N	[]	35	t	2026-07-18 09:56:49.730033+00
cc760d71-ad6a-4c09-b156-882914f638c9	production_companies	Продюсерские компании	textarea	cinema	\N	[]	36	t	2026-07-18 09:56:49.730033+00
5343ce0e-b4ac-4276-9d9f-9cc79edcf8bd	tagline	Слоган	string	cinema	\N	[]	37	t	2026-07-18 09:56:49.730033+00
eacfe4db-d735-4f4c-9bc5-66999e1d6798	vote_count	Количество голосов	integer	cinema	\N	[]	38	t	2026-07-18 09:56:49.730033+00
c24afabc-0f70-4a88-b491-ecb4be2e362c	isrc	ISRC	string	music	\N	[]	39	t	2026-07-18 09:56:49.730033+00
f64c5973-80d3-4013-9163-7ef1aa42ef51	iswc	ISWC	string	music	\N	[]	40	t	2026-07-18 09:56:49.730033+00
8cfdde53-b0f8-46d4-aa8d-74874a8c675a	track_number	Номер трека	integer	music	\N	[]	41	t	2026-07-18 09:56:49.730033+00
abb05f0b-befc-40c9-a73b-2a56b57ddc3e	disc_number	Номер диска	integer	music	\N	[]	42	t	2026-07-18 09:56:49.730033+00
324a61c3-7c8a-43ba-ae64-007792a09330	explicit	Есть нецензурный контент	boolean	music	\N	[]	43	t	2026-07-18 09:56:49.730033+00
92d069c2-e981-495d-b121-548ddb38fd65	key_signature	Тональность	string	music	\N	[]	44	t	2026-07-18 09:56:49.730033+00
c7a44a64-12d1-4a96-8d96-dce69e6f6a1f	time_signature	Размерность	string	music	\N	[]	45	t	2026-07-18 09:56:49.730033+00
69a549ba-969e-4800-95ff-f5d6cb786cc1	label_name	Лейбл	string	music	\N	[]	46	t	2026-07-18 09:56:49.730033+00
54fb4732-2c23-4409-88cf-e0b377200bfa	publisher	Издатель	string	literature	\N	[]	47	t	2026-07-18 09:56:49.730033+00
b5adbac4-ad8d-4e41-a01c-b3d8d2ad4189	publication_city	Город издания	string	literature	\N	[]	48	t	2026-07-18 09:56:49.730033+00
9cf1b7d0-8c3c-42d4-8bb6-49f9f08dcaed	edition	Издание	string	literature	\N	[]	49	t	2026-07-18 09:56:49.730033+00
3c3e0ed9-2394-43f0-9578-1de0f0ec7fc1	translator	Переводчик	string	literature	\N	[]	50	t	2026-07-18 09:56:49.730033+00
67a622b6-0fea-40b0-9fa2-387fcd3e2af3	original_language	Язык оригинала	string	literature	\N	[]	51	t	2026-07-18 09:56:49.730033+00
b5261ddb-0950-4cfb-9402-fb62a18cf3a3	dewey_decimal	Десятичный код Дьюи	string	literature	\N	[]	52	t	2026-07-18 09:56:49.730033+00
13c904f7-d3e5-4d58-a8a7-06e16daba976	electron_configuration	Электронная конфигурация	string	science	\N	[]	53	t	2026-07-18 09:56:49.730033+00
61cd232a-12a0-4b93-b839-71bd87cc18cd	oxidation_states	Степени окисления	string	science	\N	[]	54	t	2026-07-18 09:56:49.730033+00
3f4341d1-383c-468c-82c5-6b4130fdb18c	electronegativity	Электроотрицательность	number	science	\N	[]	55	t	2026-07-18 09:56:49.730033+00
cfd20cad-a70d-45b6-82d2-d961478f3337	density	Плотность	number	science	\N	[]	56	t	2026-07-18 09:56:49.730033+00
67e79910-2266-452d-acdc-92bc32cd01fd	melting_point	Температура плавления	number	science	\N	[]	57	t	2026-07-18 09:56:49.730033+00
6eede514-ca58-48af-ac12-3fd650b5466c	boiling_point	Температура кипения	number	science	\N	[]	58	t	2026-07-18 09:56:49.730033+00
4f9283f4-6f9b-4bdc-af77-c5da93c0f282	discovery_year	Год открытия	integer	science	\N	[]	59	t	2026-07-18 09:56:49.730033+00
a99ae69b-5283-4695-8cbd-936c713ef4e5	first_name	Имя	string	people	\N	[]	60	t	2026-07-18 09:56:49.730033+00
505a88af-2cfb-4bca-89ef-12bb3cd8f982	last_name	Фамилия	string	people	\N	[]	61	t	2026-07-18 09:56:49.730033+00
f0ff0d45-e8fe-4054-aea6-0ae0209970cd	patronymic	Отчество	string	people	\N	[]	62	t	2026-07-18 09:56:49.730033+00
61bf231c-c521-43b4-bf34-fd2666e72e58	birth_date	Дата рождения	date	people	\N	[]	63	t	2026-07-18 09:56:49.730033+00
0d692aa6-8915-4e67-94c5-76d703858c34	birth_place	Место рождения	string	people	\N	[]	64	t	2026-07-18 09:56:49.730033+00
765fc0c1-8dc3-45dc-be49-52a35e33b8de	death_date	Дата смерти	date	people	\N	[]	65	t	2026-07-18 09:56:49.730033+00
f38bda94-148d-44f8-893c-38388187b087	death_place	Место смерти	string	people	\N	[]	66	t	2026-07-18 09:56:49.730033+00
a7ec0dea-9217-41f8-b5cb-6a34a81e6d1e	height_cm	Рост (см)	integer	people	\N	[]	67	t	2026-07-18 09:56:49.730033+00
794826f7-dcf5-4ae0-8402-933964ca3540	nationality	Национальность	string	people	\N	[]	68	t	2026-07-18 09:56:49.730033+00
fbab8a9c-3449-432b-bd32-425b46a255ef	occupation	Профессия	string	people	\N	[]	69	t	2026-07-18 09:56:49.730033+00
fcc71d68-5512-42dc-b797-42dacb24b1a5	latitude	Широта	number	geography	\N	[]	70	t	2026-07-18 09:56:49.730033+00
d5478745-2a7a-4bdf-81a1-d08440e8223a	longitude	Долгота	number	geography	\N	[]	71	t	2026-07-18 09:56:49.730033+00
aabef921-f94a-41a9-b11a-db65af43e270	elevation_m	Высота (м)	number	geography	\N	[]	72	t	2026-07-18 09:56:49.730033+00
1c4d28f0-e73c-4de0-8646-ecd75d061ec6	timezone	Часовой пояс	string	geography	\N	[]	73	t	2026-07-18 09:56:49.730033+00
e698827a-9cb3-43d2-af70-cb3dd45dad34	area_km2	Площадь (км²)	number	geography	\N	[]	74	t	2026-07-18 09:56:49.730033+00
07eb1217-5d13-4fe4-b735-e86b1b2e76d7	population	Население	integer	geography	\N	[]	75	t	2026-07-18 09:56:49.730033+00
9b5866d9-8c10-4255-a676-adea0008d0d5	postal_code	Почтовый индекс	string	geography	\N	[]	76	t	2026-07-18 09:56:49.730033+00
410a244a-839d-40f4-8902-7e701d77b0d0	iso_code	ISO код	string	geography	\N	[]	77	t	2026-07-18 09:56:49.730033+00
c0a58b2b-4e2d-427d-a2ae-b3a2653db963	founding_date	Дата основания	date	organization	\N	[]	78	t	2026-07-18 09:56:49.730033+00
2dd87db5-f203-4bcf-a0f7-c551acfade51	dissolution_date	Дата роспуска	date	organization	\N	[]	79	t	2026-07-18 09:56:49.730033+00
957419bf-2481-4363-857b-e7c7f0ad7fc7	founder	Основатель	string	organization	\N	[]	80	t	2026-07-18 09:56:49.730033+00
c7470a3a-d2e5-42e8-b125-bc95ddb29d9f	industry	Отрасль	string	organization	\N	[]	81	t	2026-07-18 09:56:49.730033+00
86098b74-c870-40ac-8cdc-d66eb213acf4	employee_count	Число сотрудников	integer	organization	\N	[]	82	t	2026-07-18 09:56:49.730033+00
7d50642c-ab8f-4ef2-9635-941c077a238f	headquarters	Штаб-квартира	string	organization	\N	[]	83	t	2026-07-18 09:56:49.730033+00
d51f69f3-3888-4769-a1f6-e8409fb0a7fd	event_date	Дата события	date	events	\N	[]	84	t	2026-07-18 09:56:49.730033+00
ce1ec429-9ef8-426c-b2af-e647c62a9d67	event_end_date	Дата окончания	date	events	\N	[]	85	t	2026-07-18 09:56:49.730033+00
8af3744c-fc2e-4136-a9ac-988eb2905ff5	venue	Место проведения	string	events	\N	[]	86	t	2026-07-18 09:56:49.730033+00
ade580c1-77d7-47e4-9c5a-1b19aad5b852	organizer	Организатор	string	events	\N	[]	87	t	2026-07-18 09:56:49.730033+00
bc1264a4-f9e4-4e6d-aa9e-1ec9e9075264	attendee_count	Число участников	integer	events	\N	[]	88	t	2026-07-18 09:56:49.730033+00
fc86fbd1-6f66-43f7-af32-3a39f8e628d4	ticket_price	Цена билета	currency	events	\N	[]	89	t	2026-07-18 09:56:49.730033+00
d6bde740-bfdc-41df-b65a-ec906f387e44	version	Версия	string	digital	\N	[]	90	t	2026-07-18 09:56:49.730033+00
9077acf9-52d6-484a-89f7-136dcba107c8	license	Лицензия	string	digital	\N	[]	91	t	2026-07-18 09:56:49.730033+00
71c89252-d02f-4666-abad-9df3129812c2	repository_url	URL репозитория	url	digital	\N	[]	92	t	2026-07-18 09:56:49.730033+00
ee34d02c-d0a2-49b0-b7ea-9463bf87ed54	programming_language	Язык программирования	string	digital	\N	[]	93	t	2026-07-18 09:56:49.730033+00
6a1f5286-41fc-4f07-92e1-55c2cc01f92f	platform	Платформа	string	digital	\N	[]	94	t	2026-07-18 09:56:49.730033+00
93f1439f-554b-431c-833a-5ad451e84867	developer	Разработчик	string	digital	\N	[]	95	t	2026-07-18 09:56:49.730033+00
db822709-45d6-4c8e-90d1-3044a287148e	game_engine	Игровой движок	string	gaming	\N	[]	96	t	2026-07-18 09:56:49.730033+00
ce8f5b27-d227-4721-ab9b-ef201421ab53	platform_list	Платформы	textarea	gaming	\N	[]	97	t	2026-07-18 09:56:49.730033+00
1bf79c60-3147-4c4a-ac14-d698b7323453	player_count	Кол-во игроков	string	gaming	\N	[]	98	t	2026-07-18 09:56:49.730033+00
cdc38243-dec2-45c4-bc52-356358c2a796	esrb_rating	Рейтинг ESRB	select	gaming	\N	[]	99	t	2026-07-18 09:56:49.730033+00
0657ca17-41a0-4423-99ca-b7f55a8345d6	episode_number	Номер эпизода	integer	media	\N	[]	100	t	2026-07-18 09:56:49.730033+00
0251943a-169e-410b-a286-2cfe1cca2c19	season_number	Номер сезона	integer	media	\N	[]	101	t	2026-07-18 09:56:49.730033+00
43485aa2-e1f6-4410-bf92-e05dcb6652f5	podcast_url	URL подкаста	url	media	\N	[]	102	t	2026-07-18 09:56:49.730033+00
9db16770-385b-40b5-a3e3-59b4a424987a	channel_url	URL канала	url	media	\N	[]	103	t	2026-07-18 09:56:49.730033+00
c3e19c55-a0d1-4080-b391-83e085998bf6	age_rating	Возрастной рейтинг	string	common	\N	[]	104	t	2026-07-18 12:50:45.913219+00
1bbf210e-2302-4a98-8f84-665ca3d92e99	production_company	Кинокомпания	string	cinema	\N	[]	105	t	2026-07-18 12:52:01.054965+00
\.


--
-- Data for Name: field_registry_label; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.field_registry_label (field_id, language, label, description) FROM stdin;
428e23ce-84b3-41a6-9f82-5e63c2d0facd	ru	Название	Основное название сущности
428e23ce-84b3-41a6-9f82-5e63c2d0facd	en	Title	Main title of the entity
51dbe5a1-7a86-44f5-812c-a2a0b2b828bc	ru	Описание	Подробное описание
51dbe5a1-7a86-44f5-812c-a2a0b2b828bc	en	Description	Detailed description
291b0a5a-803d-4592-8ea4-0a261d55c1f7	ru	Год	Год создания или события
291b0a5a-803d-4592-8ea4-0a261d55c1f7	en	Year	Year of creation or event
40a1395b-5155-4f73-bfba-f9b99e47abae	ru	Жанр	Творческое направление
40a1395b-5155-4f73-bfba-f9b99e47abae	en	Genre	Creative direction
09bb8c88-658c-472b-af4e-dfbf8259692c	ru	Рейтинг	Оценка от 0 до 10
09bb8c88-658c-472b-af4e-dfbf8259692c	en	Rating	Score from 0 to 10
fda6f45c-5d1a-4cfd-9ba6-23648041a446	ru	Страна	Страна происхождения
fda6f45c-5d1a-4cfd-9ba6-23648041a446	en	Country	Country of origin
80564c9a-5599-4ea6-94f7-421884ff6c89	ru	Язык	Язык произведения
80564c9a-5599-4ea6-94f7-421884ff6c89	en	Language	Language of the work
ce8b30a9-a39c-42bf-92dd-4a1e4214f85c	ru	IMDb ID	Идентификатор в базе IMDb
ce8b30a9-a39c-42bf-92dd-4a1e4214f85c	en	IMDb ID	IMDb database identifier
59a5ed15-ceb9-4dac-8be8-d2df2ace5af5	ru	Хронометраж	Длительность в минутах
59a5ed15-ceb9-4dac-8be8-d2df2ace5af5	en	Runtime	Duration in minutes
a1a03cf3-850a-4b16-81d2-2ed62079c36a	ru	Бюджет	Бюджет производства
a1a03cf3-850a-4b16-81d2-2ed62079c36a	en	Budget	Production budget
0bfac275-4672-49f0-80ad-86509972ce01	ru	Сборы	Прокатные сборы
0bfac275-4672-49f0-80ad-86509972ce01	en	Revenue	Box office revenue
c24afabc-0f70-4a88-b491-ecb4be2e362c	ru	ISRC	Международный стандартный код записи
c24afabc-0f70-4a88-b491-ecb4be2e362c	en	ISRC	International Standard Recording Code
54fb4732-2c23-4409-88cf-e0b377200bfa	ru	Издатель	Издательство
54fb4732-2c23-4409-88cf-e0b377200bfa	en	Publisher	Publishing house
a99ae69b-5283-4695-8cbd-936c713ef4e5	ru	Имя	Личное имя
a99ae69b-5283-4695-8cbd-936c713ef4e5	en	First Name	Given name
505a88af-2cfb-4bca-89ef-12bb3cd8f982	ru	Фамилия	Фамилия
505a88af-2cfb-4bca-89ef-12bb3cd8f982	en	Last Name	Family name
61bf231c-c521-43b4-bf34-fd2666e72e58	ru	Дата рождения	Дата рождения
61bf231c-c521-43b4-bf34-fd2666e72e58	en	Birth Date	Date of birth
fcc71d68-5512-42dc-b797-42dacb24b1a5	ru	Широта	Географическая широта
fcc71d68-5512-42dc-b797-42dacb24b1a5	en	Latitude	Geographic latitude
d5478745-2a7a-4bdf-81a1-d08440e8223a	ru	Долгота	Географическая долгота
d5478745-2a7a-4bdf-81a1-d08440e8223a	en	Longitude	Geographic longitude
c0a58b2b-4e2d-427d-a2ae-b3a2653db963	ru	Дата основания	Дата основания организации
c0a58b2b-4e2d-427d-a2ae-b3a2653db963	en	Founding Date	Organization founding date
d51f69f3-3888-4769-a1f6-e8409fb0a7fd	ru	Дата события	Дата проведения события
d51f69f3-3888-4769-a1f6-e8409fb0a7fd	en	Event Date	Date of the event
d6bde740-bfdc-41df-b65a-ec906f387e44	ru	Версия	Номер версии
d6bde740-bfdc-41df-b65a-ec906f387e44	en	Version	Version number
9077acf9-52d6-484a-89f7-136dcba107c8	ru	Лицензия	Тип лицензии
9077acf9-52d6-484a-89f7-136dcba107c8	en	License	License type
\.


--
-- Data for Name: import_batch; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.import_batch (batch_id, source_id, batch_code, started_at, finished_at, items_total, items_success, items_failed, error_log) FROM stdin;
\.


--
-- Data for Name: media_asset; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.media_asset (asset_id, entity_id, original_name, mime_type, size_bytes, file_hash, storage_backend, storage_key, width, height, duration_secs, metadata, is_processed, processing_log, created_at, version_id) FROM stdin;
c4964752-a9aa-4699-8745-1f901b894a9f	d0000001-0000-0000-0000-000000000003	poster_interstellar.jpg	image/jpeg	\N	0057874e8e36016989a2e11a657506ea	s3	entities/interstellar/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
32b5acd2-5c89-4d73-bbee-65b939490e52	d0000001-0000-0000-0000-000000000004	poster_fight-club.jpg	image/jpeg	\N	89e3cb706e391bf82a5da8119cbb8e3f	s3	entities/fight-club/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
b1b8415a-5585-4890-b45a-d70573982ae9	d0000001-0000-0000-0000-000000000005	poster_blade-runner-2049.jpg	image/jpeg	\N	1a122ba6c2e61161d3cda755f225b744	s3	entities/blade-runner-2049/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
653a4f28-7065-426d-b1d7-8e3f01a9eae2	d0000002-0000-0000-0000-000000000003	poster_matt-damon.jpg	image/jpeg	\N	a7ab94d638da6097057ab9a9e208fd69	s3	entities/matt-damon/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
46d8d2c8-ea35-4e4b-8e79-8844915a7452	d0000002-0000-0000-0000-000000000004	poster_scarlett-johansson.jpg	image/jpeg	\N	852645b8baf37740058af312f53aaff0	s3	entities/scarlett-johansson/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
ed767a9b-4612-454f-80a1-b18e36f9d5eb	d0000002-0000-0000-0000-000000000005	poster_ryan-gosling.jpg	image/jpeg	\N	3cdde9a90f7b60b5144212da351c3349	s3	entities/ryan-gosling/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
0931f4ce-ef0a-4b47-86dd-7cce3b855916	d0000003-0000-0000-0000-000000000003	poster_david-fincher.jpg	image/jpeg	\N	866485d98379e2ece597be97d8ae2d4b	s3	entities/david-fincher/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
d5bcd093-625c-42d9-aff0-9d7e0aa42ef0	d0000003-0000-0000-0000-000000000004	poster_denis-villeneuve.jpg	image/jpeg	\N	3bd9a597ce94c767fe15797157398479	s3	entities/denis-villeneuve/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
30d9a1d5-2248-48b9-852d-33981b119539	d0000003-0000-0000-0000-000000000005	poster_ridley-scott.jpg	image/jpeg	\N	67bdc16d3ea42a3c627fbecbece21453	s3	entities/ridley-scott/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
9b1bec23-7acc-4143-9c77-496e01ceab64	d0000005-0000-0000-0000-000000000003	poster_john-lennon.jpg	image/jpeg	\N	b61f614bb835f00deef2699201acef82	s3	entities/john-lennon/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
2a5832e1-9d1c-4971-a53e-9c02488fee68	d0000005-0000-0000-0000-000000000004	poster_jimi-hendrix.jpg	image/jpeg	\N	29ab0b7856f9f810f5b1f91b60848441	s3	entities/jimi-hendrix/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
2bf53730-9c44-41c8-853d-35888b57d91a	d0000005-0000-0000-0000-000000000005	poster_elvis-presley.jpg	image/jpeg	\N	be1a439c6e4eeaef02582d4ff74573f2	s3	entities/elvis-presley/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
3109a7f1-2e99-4557-bdbe-2fd30a674b8b	d0000007-0000-0000-0000-000000000003	poster_1984.jpg	image/jpeg	\N	e9c559b4637eb01d8322d18d01acf48f	s3	entities/1984/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
66dc2115-5325-48fc-b01e-4382518d9135	d0000007-0000-0000-0000-000000000004	poster_fahrenheit-451.jpg	image/jpeg	\N	463c11445ff77f9c972f12562d457ed2	s3	entities/fahrenheit-451/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
b664054b-2fe8-4845-8517-a4fb1584fd9f	d0000007-0000-0000-0000-000000000005	poster_brave-new-world.jpg	image/jpeg	\N	9cf0b9a149aad191026f8128a3776915	s3	entities/brave-new-world/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
eee7e1c4-164c-445b-aa90-7ada3a34782e	d0000008-0000-0000-0000-000000000003	poster_george-orwell.jpg	image/jpeg	\N	29045502f3af0f57b2a07056092f9a49	s3	entities/george-orwell/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
ea2c8ff5-b846-4a0f-8b14-bc226e73e808	d0000008-0000-0000-0000-000000000004	poster_ray-bradbury.jpg	image/jpeg	\N	1a04c97e9cc9135166d6262975351420	s3	entities/ray-bradbury/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
75ebba58-0bd0-494b-8f23-701daba5dc3b	d0000008-0000-0000-0000-000000000005	poster_aldous-huxley.jpg	image/jpeg	\N	fb068cb9a2eb195a7b8b6642c15849d8	s3	entities/aldous-huxley/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
710391af-07d9-48c0-b6f2-b9563fdfb197	d0000009-0000-0000-0000-000000000004	poster_london.jpg	image/jpeg	\N	0ca061b776066e2df8b502e09f6eb530	s3	entities/london/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
ea67d5b8-1a51-461a-bec5-ac7fb3c25684	d0000009-0000-0000-0000-000000000005	poster_new-york.jpg	image/jpeg	\N	d47da763e9af65c06f7791adc55f22ea	s3	entities/new-york/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
f3f58a5a-0a8c-4f5b-a5b1-32883bd95a4d	d0000009-0000-0000-0000-000000000006	poster_rome.jpg	image/jpeg	\N	06f2ded2fdb96878318e32c85d700ee8	s3	entities/rome/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
f0db6e4e-c96e-4dda-a0ce-d260b3b5a619	d0000011-0000-0000-0000-000000000004	poster_tiger.jpg	image/jpeg	\N	341428a92a575844681b990a721c8b26	s3	entities/tiger/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
26f2a9ff-d096-4cc3-8615-5ea405ff57a5	d0000011-0000-0000-0000-000000000005	poster_elephant.jpg	image/jpeg	\N	d3fd4e72b3dbfbf032ed46e71388d975	s3	entities/elephant/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
093f40ca-3102-4ff4-90db-fc6c2f6cf813	d0000011-0000-0000-0000-000000000006	poster_penguin.jpg	image/jpeg	\N	7a1017fbe18525810458314de5bb07dc	s3	entities/penguin/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
438d61e4-a528-40d3-b46e-b6bfee1711c9	d0000026-0000-0000-0000-000000000003	poster_disney.jpg	image/jpeg	\N	8883d00bf7efdcdeecd009fa72d3693a	s3	entities/disney/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
c3bbfd39-f7a6-46c3-9423-7a01cfba7888	d0000026-0000-0000-0000-000000000004	poster_apple-inc.jpg	image/jpeg	\N	bc404027dcd76bdf1ca617ecfb7eb3bc	s3	entities/apple-inc/poster.jpg	\N	\N	\N	{}	f	\N	2026-07-18 09:59:11.929593+00	1
8ae1eaf2-c997-417f-9db1-b1f77369f963	24a3b922-3ba0-4077-b0db-6eea4d22beca	Золотой.телёнок.webp	image/webp	67968	69de2d693d20c531336b6828b3e6e131e1e5c5f2dc057759fbbc7e6a6622832c	local	entities/24a3b922-3ba0-4077-b0db-6eea4d22beca/Золотой.телёнок.webp	\N	\N	\N	{}	f	\N	2026-07-18 19:56:54.499094+00	1
30b0c45c-be6f-4e5e-8b00-f28f6679fa5f	ccfb8bb4-73cc-4269-86aa-88371c4485b6	Доспехи бога.webp	image/webp	104982	5955ab0ede65c46707337a6fe22f218dbfd8b64a06a2845fbba310d4d1290295	local	entities/ccfb8bb4-73cc-4269-86aa-88371c4485b6/Доспехи_бога.webp	\N	\N	\N	{}	f	\N	2026-07-18 19:58:38.234728+00	1
dd77de31-0e53-4a71-a534-2cc1a4d946ea	1ea63bec-f46d-43d4-bfce-ec55c7e3b96c	Гремлины.jpeg	image/jpeg	193927	a6009646a42c2c8320b1f3a534a149e4f1cdc99ef1e061e5efddd69577ed6b9c	local	entities/1ea63bec-f46d-43d4-bfce-ec55c7e3b96c/Гремлины.jpeg	\N	\N	\N	{}	f	\N	2026-07-18 19:58:38.270391+00	1
9bec9552-5185-4542-80ae-cb4f4e550354	8877988a-cc00-4360-902c-b9236ef36f1c	Тяжелый.Металл.jpeg	image/jpeg	261132	9c79b5c68a8ed5b386a0797e4667d5a4a3f9529f0df02f9a2328bdc5e757c2c5	local	entities/8877988a-cc00-4360-902c-b9236ef36f1c/Тяжелый.Металл.jpeg	\N	\N	\N	{}	f	\N	2026-07-18 19:58:38.300313+00	1
a4130c13-8726-4c62-aefc-61b75f1f80f2	058e03ee-0404-4bc5-b449-260f1f29e6a1	Приключения.Электроника.jpg	image/jpeg	223144	832c676640e199b323ae930164919e9d6f72708c3dd18930fadf2f5640390066	local	entities/058e03ee-0404-4bc5-b449-260f1f29e6a1/Приключения.Электроника.jpg	\N	\N	\N	{}	f	\N	2026-07-18 19:58:38.331428+00	1
89b33dae-ddf3-4670-8a57-eee90cc947cb	5ceefbba-b512-467e-9bbb-2f8a537bd2b9	Taxi.jpg	image/jpeg	146543	d664ba7613bf212dc3685bed60918b22b4f8a3554247d6d4da7cad2cb9f7d9a8	local	entities/5ceefbba-b512-467e-9bbb-2f8a537bd2b9/Taxi.jpg	\N	\N	\N	{}	f	\N	2026-07-18 19:58:38.358739+00	1
55e4adc2-e979-4686-8579-c5985f4632b8	387fb842-3e32-462c-a70a-714bab27a2eb	Тот.самый.Мюнхгаузен.jpeg	image/jpeg	564525	d4ace36e90a1e18cf72ce03f6b060b03aab4a0e8720b7c8cd185c2afd3bacb24	local	entities/387fb842-3e32-462c-a70a-714bab27a2eb/Тот.самый.Мюнхгаузен.jpeg	\N	\N	\N	{}	f	\N	2026-07-18 20:05:45.206413+00	1
d5ffd0f8-55e4-4e11-8224-2f34f1486ff3	8f5afa8d-d5cf-41b8-9330-7794bdfa761e	Не.бойся,.я.с.тобой.(1981).webp	image/webp	92258	a2a80fd690b2ac72f672674614e7df2464ce578afe792dc0620b2398fe494516	local	entities/8f5afa8d-d5cf-41b8-9330-7794bdfa761e/Не.бойся,.я.с.тобой.(1981).webp	\N	\N	\N	{}	f	\N	2026-07-18 20:05:45.236529+00	1
6936407e-5b2b-4735-87b8-8743ccba871e	64a2dfe2-ea09-492c-8302-3e0c92e24c8d	3840x.webp	image/webp	446230	42ad42d60ef490abf3a00e958eadd752c398dfe1efd442dde1c33520ace3c074	local	entities/64a2dfe2-ea09-492c-8302-3e0c92e24c8d/3840x.webp	\N	\N	\N	{}	f	\N	2026-07-18 20:05:45.277477+00	1
51cb9eef-4b6e-4205-a14c-747cfca1b4a2	e2c3c575-32e2-4e12-83da-f0bfb086ef24	призрак в доспехах.jpg	image/jpeg	499802	a3a275b6642a34e61ff1325d04b992d49e541fccdaba71735e0b61cd21627a80	local	entities/e2c3c575-32e2-4e12-83da-f0bfb086ef24/призрак_в_доспехах.jpg	\N	\N	\N	{}	f	\N	2026-07-18 20:19:04.995308+00	1
62373dbe-b98b-4d06-8f98-80040fff7e7a	4cb4bd5c-599a-4a8f-bfa0-44f2b5ff4ac8	futurama.jpg	image/jpeg	182042	c02fa6311539f171bbe2821540ba7e2de5437571afd32c3af1f27e81b5192fe5	local	entities/4cb4bd5c-599a-4a8f-bfa0-44f2b5ff4ac8/futurama.jpg	\N	\N	\N	{}	f	\N	2026-07-18 20:22:59.460712+00	1
9f935b53-2ea8-4ef3-8b2d-898c564be168	c7940df6-46a1-483b-a8b0-0fb0d60019f2	i.jpg	image/jpeg	139142	7edf3ae9ea172c7e6dcc436a272afc1f2a24fb0af2be6e545b0a9b73760f5801	local	entities/c7940df6-46a1-483b-a8b0-0fb0d60019f2/i.jpg	\N	\N	\N	{}	f	\N	2026-07-18 20:26:38.01715+00	1
932d1c9c-7ccb-4ee3-8ed7-b29459394fae	eb2cb77f-513e-450a-a911-aa2fd912f5c3	orig (1).jpg	image/jpeg	355629	b142ea3ecc4877278d5b631e62f0869da7904d9b055387e9a0eadba0b07d5af5	local	entities/eb2cb77f-513e-450a-a911-aa2fd912f5c3/orig_(1).jpg	\N	\N	\N	{}	f	\N	2026-07-18 20:26:50.665076+00	1
36d98634-6511-4272-bac3-d4191b9591ae	8bf8898d-097d-414e-beab-2c84e8fdd08b	test_cover.jpg	image/jpeg	0	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855	local	entities/8bf8898d-097d-414e-beab-2c84e8fdd08b/test_cover.jpg	\N	\N	\N	{}	f	\N	2026-07-18 20:38:28.473894+00	1
3277ffbc-c1b2-4fc7-9d35-5f87c942055a	163f66ff-44d7-4580-85ab-39c5bfbe1e9d	maxresdefault.jpg	image/jpeg	176919	f49c0da28976a9963ce6956b8303f24889ac8aee881e716319014181e65f7a24	local	entities/163f66ff-44d7-4580-85ab-39c5bfbe1e9d/maxresdefault.jpg	\N	\N	\N	{}	f	\N	2026-07-18 20:40:32.704661+00	1
0ef0e740-f2fb-4577-ba75-cb85cd81c05a	1ecd1e93-4eef-4ecb-9ff5-b77c1c4211c3	моана.webp	image/webp	80774	d6b20650564a76ba1bc367df4c527115acf2bd313633da250e629fcec96370b4	local	entities/1ecd1e93-4eef-4ecb-9ff5-b77c1c4211c3/моана.webp	\N	\N	\N	{}	f	\N	2026-07-18 20:58:32.208094+00	1
0e15ce8a-eab7-49b1-913e-e1674c5eef67	afed8c62-00d3-476b-a20c-2b8173d303a6	Академия ведьмочек.webp	image/webp	151186	494cff95e28a57b86a100e869559e938036d1a1a14b2244231937bbfb78b931e	local	entities/afed8c62-00d3-476b-a20c-2b8173d303a6/Академия_ведьмочек.webp	\N	\N	\N	{}	f	\N	2026-07-19 08:07:20.04923+00	1
17596a6e-42d6-4834-baa4-3fd65af9eef8	485dee97-cde2-4603-8aa3-1b9364a5cbb1	Чокнутый профессор (Коллекция)2.png	image/png	1785146	82f32c33d0c99c9bad3836c0b275bd2208712bf5b1affea97bc8281446ea7b7b	local	entities/485dee97-cde2-4603-8aa3-1b9364a5cbb1/Чокнутый_профессор_(Коллекция)2.png	\N	\N	\N	{}	f	\N	2026-07-19 15:13:23.039067+00	1
1c964783-e9e7-41c8-ae28-37b56f9dfce7	ce6d5b1a-8536-4823-88c3-6d077da6c23c	Чокнутый профессор (Коллекция).jpg	image/jpeg	231615	f19589332f4763250d8161fb32894fa23babe24c232abf2f6cbcec11606a03f3	local	entities/ce6d5b1a-8536-4823-88c3-6d077da6c23c/Чокнутый_профессор_(Коллекция).jpg	\N	\N	\N	{}	f	\N	2026-07-19 15:13:23.110593+00	1
2fb85e03-74ba-4b65-b6a3-3e66e10b77c5	c42af2c3-8bff-431d-84aa-31fee4e37dba	Легенда о Ло Сяохэе2.jpg	image/jpeg	181485	8396a193f89abae66242f2fb21ffdeb6482041748c9f5a219ccb2c49e322a04b	local	entities/c42af2c3-8bff-431d-84aa-31fee4e37dba/Легенда_о_Ло_Сяохэе2.jpg	\N	\N	\N	{}	f	\N	2026-07-19 15:13:23.146206+00	1
83cf9c9f-5c2c-4c5e-afeb-dbedf4b579d2	9559dcd0-3ee8-4941-ac8e-65bde4b2e705	Легенда о Ло Сяохэе.jpg	image/jpeg	89544	3781d9a6e9eaa0e720f34d511bbb43ea2e4ed4ba9388e97fdea6bad1114a5abc	local	entities/9559dcd0-3ee8-4941-ac8e-65bde4b2e705/Легенда_о_Ло_Сяохэе.jpg	\N	\N	\N	{}	f	\N	2026-07-19 15:13:23.168488+00	1
61c94238-4053-451a-89fa-5ffd05f261c6	b56aeff9-0ebd-4687-b5f3-c7bdd8efa1a6	4.Комнаты.jpg	image/jpeg	128671	2e68dc2d485e7f3328c97e05ac1a92826cdbebafdb670ce5619d3ba4bc7ef5d6	local	entities/b56aeff9-0ebd-4687-b5f3-c7bdd8efa1a6/4.Комнаты.jpg	\N	\N	\N	{}	f	\N	2026-07-19 15:13:23.424057+00	1
\.


--
-- Data for Name: menu_item; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.menu_item (menu_id, parent_id, menu_code, label, label_en, url, icon, sort_order, is_visible, required_role, css_class, created_at) FROM stdin;
f0000001-0000-0000-0000-000000000001	\N	main	Главная	Home	/	\N	1	t	\N	\N	2026-07-18 09:57:12.408593+00
f0000002-0000-0000-0000-000000000001	\N	main	Каталог	Catalog	/entities	\N	2	t	\N	\N	2026-07-18 09:57:12.408593+00
f0000003-0000-0000-0000-000000000001	\N	main	Поиск	Search	/search	\N	3	t	\N	\N	2026-07-18 09:57:12.408593+00
f0000004-0000-0000-0000-000000000001	\N	main	Карта знаний	Knowledge Graph	/graph	\N	4	t	\N	\N	2026-07-18 09:57:12.408593+00
f0000005-0000-0000-0000-000000000001	\N	main	Загрузка файлов	File Upload	/upload	\N	5	t	\N	\N	2026-07-18 09:57:12.408593+00
f0000006-0000-0000-0000-000000000001	\N	main	Настройки	Settings	/settings	\N	6	t	\N	\N	2026-07-18 09:57:12.408593+00
f0000007-0000-0000-0000-000000000001	\N	main	Справочники	Classifiers	/classifiers	\N	7	t	\N	\N	2026-07-18 09:57:12.408593+00
\.


--
-- Data for Name: ontology_model; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.ontology_model (model_id, model_code, domain, description, version_id, created_at) FROM stdin;
801d5718-54ec-44c7-85da-af53af4d7acc	default	general	Базовая модель	1	2026-07-18 09:56:49.890643+00
8c86f136-2f76-44c4-8d56-e5db5703bff6	cinema	art	Кинематограф	1	2026-07-18 09:56:49.890643+00
102715a7-994b-46fe-87cf-9a21487d74cd	music	art	Музыка	1	2026-07-18 09:56:49.890643+00
4264c67d-7bbe-49af-9df3-0289d61f4477	literature	art	Литература	1	2026-07-18 09:56:49.890643+00
a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	science	science	Наука	1	2026-07-18 09:56:49.890643+00
96ffa67d-b033-4950-89e6-d35cff76da25	geography	social	География	1	2026-07-18 09:56:49.890643+00
f3b13238-49e8-473a-8c6f-d424e36f197f	history	social	История	1	2026-07-18 09:56:49.890643+00
8c6480ac-1e41-4c34-b75e-6dedab9ed913	technology	digital	Технологии	1	2026-07-18 09:56:49.890643+00
83587ae4-80a5-4ed1-ab6f-a71920f3ad87	field_model	meta	Онтологическая модель для полей реестра	1	2026-07-18 20:51:32.208375+00
e7048181-8484-4cda-b47f-d966fc3cd4f6	ontology_entity_model	meta	Модель для онтологий как сущностей	1	2026-07-19 08:16:43.681148+00
\.


--
-- Data for Name: ontology_template; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.ontology_template (template_id, model_id, kind_id, template_code, template_name, description, schema_definition, layout_definition, is_active, constraints_definition, version_id, created_at) FROM stdin;
54c9afef-b39c-4451-aa03-c6d0cc8c2077	8c86f136-2f76-44c4-8d56-e5db5703bff6	a0000000-0000-0000-0000-000000000001	digital_file_Clip	Шаблон: Клип		{"required": [], "properties": {"year": {"type": "integer", "title": "Год"}, "genre": {"type": "string", "title": "Жанр"}, "budget": {"type": "string", "title": "Бюджет"}, "rating": {"type": "number", "title": "Рейтинг"}, "country": {"type": "string", "title": "Страна"}, "imdb_id": {"type": "string", "title": "IMDb ID"}, "tagline": {"type": "string", "title": "Слоган"}, "tmdb_id": {"type": "string", "title": "TMDb ID"}, "director": {"type": "string", "title": "Режиссёр"}, "duration": {"type": "string", "title": "Длительность"}, "language": {"type": "string", "title": "Язык"}, "age_rating": {"type": "string", "title": "Возрастной рейтинг"}, "description": {"type": "string", "title": "Описание"}, "production_company": {"type": "string", "title": "Кинокомпания"}}, "field_order": ["year", "genre", "budget", "rating", "country", "tagline", "director", "duration", "language", "production_company", "age_rating", "imdb_id", "tmdb_id", "description"]}	[{"type": "image_data_row", "config": {"fields": [], "alt_field": "title", "image_source": "poster"}}]	t	{}	3	2026-07-19 07:21:35.298625+00
a47e7939-ca26-4d11-872f-8bc573638ebf	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	\N	plant_tpl_plant	Шаблон: Растение	Шаблон для Шаблон: Растение	{"type": "object", "properties": {"name": {"type": "string"}, "family": {"type": "string"}, "habitat": {"type": "string"}, "species": {"type": "string"}, "height_cm": {"type": "integer"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "name", "field_key": "name"}, {"label": "family", "field_key": "family"}, {"label": "habitat", "field_key": "habitat"}, {"label": "species", "field_key": "species"}, {"label": "height_cm", "field_key": "height_cm"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:21.756311+00
9b38ce00-114e-4c99-879f-90043a092471	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	\N	phenomenon_tpl_phenomenon	Шаблон: Явление	Шаблон для Шаблон: Явление	{"type": "object", "properties": {"name": {"type": "string"}, "category": {"type": "string"}, "description": {"type": "string"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "name", "field_key": "name"}, {"label": "category", "field_key": "category"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:22.21688+00
1fd64088-1ebc-4cbb-a6c3-5478a61edd19	f3b13238-49e8-473a-8c6f-d424e36f197f	\N	period_tpl_period	Шаблон: Эпоха	Шаблон для Шаблон: Эпоха	{"type": "object", "properties": {"name": {"type": "string"}, "region": {"type": "string"}, "end_year": {"type": "integer"}, "start_year": {"type": "integer"}, "significance": {"type": "string"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "name", "field_key": "name"}, {"label": "region", "field_key": "region"}, {"label": "end_year", "field_key": "end_year"}, {"label": "start_year", "field_key": "start_year"}, {"label": "significance", "field_key": "significance"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:22.341623+00
89f1180b-d35f-402b-9d45-6d0d02172657	801d5718-54ec-44c7-85da-af53af4d7acc	\N	digital_file_tpl_file	Шаблон: Файл	Шаблон для Шаблон: Файл	{"type": "object", "properties": {"name": {"type": "string"}, "format": {"type": "string"}, "size_kb": {"type": "number"}, "category": {"type": "string"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "name", "field_key": "name"}, {"label": "format", "field_key": "format"}, {"label": "size_kb", "field_key": "size_kb"}, {"label": "category", "field_key": "category"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:22.437632+00
f5029531-afe8-4bec-9f1b-acf88351e99b	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	\N	scientist_tpl_person	Шаблон: Человек (персона)	Шаблон для Шаблон: Человек (персона)	{"type": "object", "properties": {"last_name": {"type": "string"}, "birth_date": {"type": "string"}, "first_name": {"type": "string"}, "occupation": {"type": "string"}, "birth_place": {"type": "string"}, "nationality": {"type": "string"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "last_name", "field_key": "last_name"}, {"label": "birth_date", "field_key": "birth_date"}, {"label": "first_name", "field_key": "first_name"}, {"label": "occupation", "field_key": "occupation"}, {"label": "birth_place", "field_key": "birth_place"}, {"label": "nationality", "field_key": "nationality"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:23.239381+00
a40dfdf3-4750-438f-8494-bb876cd16941	4264c67d-7bbe-49af-9df3-0289d61f4477	a0000000-0000-0000-0000-000000000007	book_tpl_book	Шаблон: Книга	Шаблон для Шаблон: Книга	{"isbn": {"type": "string", "title": "ISBN"}, "year": {"type": "integer", "title": "Год"}, "genre": {"type": "string", "title": "Жанр"}, "pages": {"type": "integer", "title": "Страниц"}, "title": {"type": "string", "title": "Название"}, "author": {"type": "string", "title": "Автор"}, "language": {"type": "string", "title": "Язык"}, "publisher": {"type": "string", "title": "Издательство"}}	[{"type": "image_data_row", "config": {"fields": [{"label": "Автор", "field_key": "author"}, {"label": "Год", "field_key": "year"}, {"label": "Жанр", "field_key": "genre"}, {"label": "Страниц", "field_key": "pages"}, {"label": "Издательство", "field_key": "publisher"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:21.20342+00
d2996896-e993-4cc1-947f-8880a340cb2a	8c86f136-2f76-44c4-8d56-e5db5703bff6	e0480aef-9629-440d-b15f-15f8f20f20b0	charaster_cinema	Шаблон: Персонаж	Персонаж фильма	{"required": [], "properties": {"name": "Имя", "tmdb_id": "TMDB_ID", "character_of": "Актёр"}}	[{"type": "image_data_row", "config": {"fields": "[{\\"key\\":\\"name\\",\\"label\\":\\"Название\\",\\"type\\":\\"string\\"},{\\"key\\":\\"tmdb_id\\",\\"label\\":\\"tmdb_id\\",\\"type\\":\\"string\\"},{\\"key\\":\\"character_of\\",\\"label\\":\\"character_of\\",\\"type\\":\\"string\\"}]", "alt_field": "title", "image_source": "poster"}}]	t	{}	4	2026-07-19 19:05:43.794821+00
632c09d1-00d0-42ad-9faf-e30bbed6b025	801d5718-54ec-44c7-85da-af53af4d7acc	\N	movement_tpl_movement	Шаблон: Движение	Шаблон для Шаблон: Движение	{"type": "object", "properties": {"name": {"type": "string"}, "origin": {"type": "string"}, "period": {"type": "string"}, "description": {"type": "string"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "name", "field_key": "name"}, {"label": "origin", "field_key": "origin"}, {"label": "period", "field_key": "period"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:22.530188+00
eeb13304-4fe8-49c8-8c26-f68090790677	801d5718-54ec-44c7-85da-af53af4d7acc	\N	classifier_tpl_classifier	Шаблон: Классификатор	Шаблон для Шаблон: Классификатор	{"type": "object", "properties": {"code": {"type": "string"}, "name": {"type": "string"}, "version": {"type": "string"}, "description": {"type": "string"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "code", "field_key": "code"}, {"label": "name", "field_key": "name"}, {"label": "version", "field_key": "version"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:22.624423+00
2bcbb4b7-e2f1-40bb-aae6-3fc471ae31ec	801d5718-54ec-44c7-85da-af53af4d7acc	\N	physical_item_tpl_item	Шаблон: Предмет	Шаблон для Шаблон: Предмет	{"type": "object", "properties": {"name": {"type": "string"}, "origin": {"type": "string"}, "material": {"type": "string"}, "year_made": {"type": "integer"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "name", "field_key": "name"}, {"label": "origin", "field_key": "origin"}, {"label": "material", "field_key": "material"}, {"label": "year_made", "field_key": "year_made"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:22.721961+00
e542328a-f153-44f4-8d08-af52ac20dd63	801d5718-54ec-44c7-85da-af53af4d7acc	\N	photo_tpl_photo	Шаблон: Фото	Шаблон для Шаблон: Фото	{"type": "object", "properties": {"year": {"type": "integer"}, "title": {"type": "string"}, "subject": {"type": "string"}, "photographer": {"type": "string"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "subject", "field_key": "subject"}, {"label": "photographer", "field_key": "photographer"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:22.812029+00
c309cf99-7d52-4cac-90b6-572abc26230d	801d5718-54ec-44c7-85da-af53af4d7acc	\N	article_tpl_article	Шаблон: Статья	Шаблон для Шаблон: Статья	{"type": "object", "properties": {"title": {"type": "string"}, "author": {"type": "string"}, "source": {"type": "string"}, "published": {"type": "string"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "author", "field_key": "author"}, {"label": "source", "field_key": "source"}, {"label": "published", "field_key": "published"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:22.920795+00
7ec66c46-773b-4e6f-b12c-e448a31fe367	801d5718-54ec-44c7-85da-af53af4d7acc	\N	human_tpl_person	Шаблон: Человек (персона)	Шаблон для Шаблон: Человек (персона)	{"type": "object", "properties": {"last_name": {"type": "string"}, "birth_date": {"type": "string"}, "first_name": {"type": "string"}, "occupation": {"type": "string"}, "birth_place": {"type": "string"}, "nationality": {"type": "string"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "last_name", "field_key": "last_name"}, {"label": "birth_date", "field_key": "birth_date"}, {"label": "first_name", "field_key": "first_name"}, {"label": "occupation", "field_key": "occupation"}, {"label": "birth_place", "field_key": "birth_place"}, {"label": "nationality", "field_key": "nationality"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:23.019901+00
299c6997-5335-4646-9e71-3786184ca5c9	801d5718-54ec-44c7-85da-af53af4d7acc	\N	artist_tpl_person	Шаблон: Человек (персона)	Шаблон для Шаблон: Человек (персона)	{"type": "object", "properties": {"last_name": {"type": "string"}, "birth_date": {"type": "string"}, "first_name": {"type": "string"}, "occupation": {"type": "string"}, "birth_place": {"type": "string"}, "nationality": {"type": "string"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "last_name", "field_key": "last_name"}, {"label": "birth_date", "field_key": "birth_date"}, {"label": "first_name", "field_key": "first_name"}, {"label": "occupation", "field_key": "occupation"}, {"label": "birth_place", "field_key": "birth_place"}, {"label": "nationality", "field_key": "nationality"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:23.127581+00
313cdb66-75e2-459d-9696-71785601e875	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	a0000000-0000-0000-0000-000000000011	animal_tpl_animal	Шаблон: Животное	Шаблон для Шаблон: Животное	{"type": "object", "properties": {"diet": {"type": "string"}, "name": {"type": "string"}, "class": {"type": "string"}, "habitat": {"type": "string"}, "species": {"type": "string"}, "lifespan_years": {"type": "integer"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "diet", "field_key": "diet"}, {"label": "name", "field_key": "name"}, {"label": "class", "field_key": "class"}, {"label": "habitat", "field_key": "habitat"}, {"label": "species", "field_key": "species"}, {"label": "lifespan_years", "field_key": "lifespan_years"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:21.634549+00
3d22c910-caff-462e-bc8f-f156bc5479eb	801d5718-54ec-44c7-85da-af53af4d7acc	a0000000-0000-0000-0000-000000000013	concept_tpl_concept	Шаблон: Концепция	Шаблон для Шаблон: Концепция	{"type": "object", "properties": {"name": {"type": "string"}, "domain": {"type": "string"}, "definition": {"type": "string"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "name", "field_key": "name"}, {"label": "domain", "field_key": "domain"}, {"label": "definition", "field_key": "definition"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:21.976882+00
cf6dc12e-5888-4bce-8ee6-7ff442c338cd	801d5718-54ec-44c7-85da-af53af4d7acc	a0000000-0000-0000-0000-000000000014	genre_tpl_genre	Шаблон: Жанр	Шаблон для Шаблон: Жанр	{"type": "object", "properties": {"name": {"type": "string"}, "category": {"type": "string"}, "origin_period": {"type": "string"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "name", "field_key": "name"}, {"label": "category", "field_key": "category"}, {"label": "origin_period", "field_key": "origin_period"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:22.097813+00
0c2ec0ab-ae2d-4cca-84cc-432cd0dd1256	102715a7-994b-46fe-87cf-9a21487d74cd	a0000000-0000-0000-0000-000000000005	musician_tpl_person	Шаблон: Человек (персона)	Шаблон для Шаблон: Человек (персона)	{"last_name": {"type": "string", "title": "Фамилия"}, "birth_date": {"type": "string", "title": "Дата рождения"}, "death_date": {"type": "string", "title": "Дата смерти"}, "first_name": {"type": "string", "title": "Имя"}, "occupation": {"type": "string", "title": "Профессия"}, "birth_place": {"type": "string", "title": "Место рождения"}}	[{"type": "image_data_row", "config": {"fields": [{"label": "Фамилия", "field_key": "last_name"}, {"label": "Дата рождения", "field_key": "birth_date"}, {"label": "Дата смерти", "field_key": "death_date"}, {"label": "Место рождения", "field_key": "birth_place"}, {"label": "Профессия", "field_key": "occupation"}], "alt_field": "first_name", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:21.078998+00
3330b5d5-ef3c-43d5-b0e8-42f7fc6c8b1b	4264c67d-7bbe-49af-9df3-0289d61f4477	a0000000-0000-0000-0000-000000000008	writer_tpl_person	Шаблон: Человек (персона)	Шаблон для Шаблон: Человек (персона)	{"type": "object", "properties": {"last_name": {"type": "string"}, "birth_date": {"type": "string"}, "first_name": {"type": "string"}, "occupation": {"type": "string"}, "birth_place": {"type": "string"}, "nationality": {"type": "string"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "last_name", "field_key": "last_name"}, {"label": "birth_date", "field_key": "birth_date"}, {"label": "first_name", "field_key": "first_name"}, {"label": "occupation", "field_key": "occupation"}, {"label": "birth_place", "field_key": "birth_place"}, {"label": "nationality", "field_key": "nationality"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:21.326429+00
cccfc450-1b74-479a-ae52-33fe49a8c4ac	801d5718-54ec-44c7-85da-af53af4d7acc	a0000000-0000-0000-0000-000000000021	tpl_my_image	Изображение	Изображения	{"title": {"type": "string", "title": "Название"}, "description": {"type": "string", "title": "Описание"}}	[{"type": "image_data_row", "config": {"fields": "[{\\"key\\":\\"images\\",\\"label\\":\\"Изображения\\",\\"type\\":\\"gallery\\"},{\\"key\\":\\"file_title\\",\\"label\\":\\"Название файла\\",\\"type\\":\\"string\\"},{\\"key\\":\\"channel_url\\",\\"label\\":\\"URL канала\\",\\"type\\":\\"url\\"}]", "alt_field": "title", "image_source": "poster"}}, {"id": "block_2", "type": "markdown", "config": {"title": "Описание", "source": "тут данные", "content": ""}}, {"id": "block_3", "type": "relation_list", "config": {"display": "list", "relation_type": ""}}]	t	{}	2	2026-07-18 14:51:14.231007+00
55610502-a3ce-4f51-a842-834c9fd46cc9	a906e5f0-3ad8-48d2-8fa7-e3d9840b3531	a0000000-0000-0000-0000-000000000010	chemical_element_tpl_element	Шаблон: Химический элемент	Шаблон для Шаблон: Химический элемент	{"type": "object", "properties": {"name": {"type": "string"}, "group": {"type": "integer"}, "period": {"type": "integer"}, "symbol": {"type": "string"}, "category": {"type": "string"}, "atomic_mass": {"type": "number"}, "atomic_number": {"type": "integer"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "name", "field_key": "name"}, {"label": "group", "field_key": "group"}, {"label": "period", "field_key": "period"}, {"label": "symbol", "field_key": "symbol"}, {"label": "category", "field_key": "category"}, {"label": "atomic_mass", "field_key": "atomic_mass"}, {"label": "atomic_number", "field_key": "atomic_number"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:21.523033+00
ed80002b-3429-4270-80c7-622540dddfcc	102715a7-994b-46fe-87cf-9a21487d74cd	a0000000-0000-0000-0000-000000000006	album_tpl_album	Шаблон: Альбом	Шаблон для Шаблон: Альбом	{"type": "object", "properties": {"year": {"type": "integer"}, "genre": {"type": "string"}, "label": {"type": "string"}, "title": {"type": "string"}, "artist": {"type": "string"}, "tracks": {"type": "integer"}}}	[{"type": "image_data_row", "config": {"fields": [{"label": "label", "field_key": "label"}, {"label": "artist", "field_key": "artist"}, {"label": "tracks", "field_key": "tracks"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:21.87227+00
8a7394bb-e9b7-47e5-9729-598a3ab4154c	83587ae4-80a5-4ed1-ab6f-a71920f3ad87	06125618-0d99-40fc-ac91-44cc8207a434	field_template	Шаблон: Поле	Отображение поля реестра	{"required": ["field_key"], "properties": {"category": {"type": "string", "title": "Категория"}, "field_key": {"type": "string", "title": "Ключ"}, "field_type": {"type": "string", "title": "Тип"}, "description": {"type": "string", "title": "Описание"}, "default_value": {"type": "string", "title": "По умолчанию"}}}	[{"type": "info_table", "config": {"style": "table", "fields": [{"key": "field_key", "label": "Ключ"}, {"key": "field_type", "label": "Тип"}, {"key": "category", "label": "Категория"}, {"key": "default_value", "label": "По умолчанию"}]}}]	t	{}	1	2026-07-18 20:52:54.535731+00
18ddf8f2-d7b7-4a52-911c-48756f13c292	8c86f136-2f76-44c4-8d56-e5db5703bff6	a0000000-0000-0000-0000-000000000003	director_tpl_person	Шаблон: Человек (персона)	Шаблон для Шаблон: Человек (персона)	{"last_name": {"type": "string", "title": "Фамилия"}, "birth_date": {"type": "string", "title": "Дата рождения"}, "first_name": {"type": "string", "title": "Имя"}, "birth_place": {"type": "string", "title": "Место рождения"}, "nationality": {"type": "string", "title": "Национальность"}}	[{"type": "image_data_row", "config": {"fields": [{"label": "Фамилия", "field_key": "last_name"}, {"label": "Дата рождения", "field_key": "birth_date"}, {"label": "Место рождения", "field_key": "birth_place"}, {"label": "Национальность", "field_key": "nationality"}], "alt_field": "first_name", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:20.840643+00
25155646-3c08-4147-9019-754e9967a655	8c86f136-2f76-44c4-8d56-e5db5703bff6	a0000000-0000-0000-0000-000000000002	actor_tpl_person	Шаблон: Человек (персона)	Шаблон для Шаблон: Человек (персона)	{"height_cm": {"type": "integer", "title": "Рост (см)"}, "last_name": {"type": "string", "title": "Фамилия"}, "birth_date": {"type": "string", "title": "Дата рождения"}, "first_name": {"type": "string", "title": "Имя"}, "birth_place": {"type": "string", "title": "Место рождения"}, "nationality": {"type": "string", "title": "Национальность"}}	[{"type": "image_data_row", "config": {"fields": [{"label": "Фамилия", "field_key": "last_name"}, {"label": "Дата рождения", "field_key": "birth_date"}, {"label": "Место рождения", "field_key": "birth_place"}, {"label": "Национальность", "field_key": "nationality"}, {"label": "Рост (см)", "field_key": "height_cm"}], "alt_field": "first_name", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:20.730797+00
99662b06-1284-4d5c-878c-ef1cd804ebc3	96ffa67d-b033-4950-89e6-d35cff76da25	a0000000-0000-0000-0000-000000000009	place_tpl_place	Шаблон: Место	Шаблон для Шаблон: Место	{"name": {"type": "string", "title": "Название"}, "country": {"type": "string", "title": "Страна"}, "area_km2": {"type": "number", "title": "Площадь (км²)"}, "latitude": {"type": "number", "title": "Широта"}, "timezone": {"type": "string", "title": "Часовой пояс"}, "longitude": {"type": "number", "title": "Долгота"}, "population": {"type": "integer", "title": "Население"}}	[{"type": "image_data_row", "config": {"fields": [{"label": "Страна", "field_key": "country"}, {"label": "Население", "field_key": "population"}, {"label": "Широта", "field_key": "latitude"}, {"label": "Долгота", "field_key": "longitude"}, {"label": "Часовой пояс", "field_key": "timezone"}], "alt_field": "name", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:21.430086+00
fcf60464-178c-4b0e-b2a7-939f31f46ba9	102715a7-994b-46fe-87cf-9a21487d74cd	a0000000-0000-0000-0000-000000000004	song_tpl_song	Шаблон: Песня	Шаблон для Шаблон: Песня	{"key": {"type": "string", "title": "Тональность"}, "year": {"type": "integer", "title": "Год"}, "album": {"type": "string", "title": "Альбом"}, "title": {"type": "string", "title": "Название"}, "artist": {"type": "string", "title": "Исполнитель"}, "duration": {"type": "integer", "title": "Длительность (сек)"}}	[{"type": "image_data_row", "config": {"fields": [{"label": "Исполнитель", "field_key": "artist"}, {"label": "Альбом", "field_key": "album"}, {"label": "Год", "field_key": "year"}, {"label": "Длительность (сек)", "field_key": "duration"}, {"label": "Тональность", "field_key": "key"}], "alt_field": "title", "image_source": "poster"}}]	t	{}	1	2026-07-18 09:57:20.950481+00
e2eb89b9-eb05-4549-82ad-2349279b1b2d	e7048181-8484-4cda-b47f-d966fc3cd4f6	92f3be1c-718d-4059-9485-80c75fa959e5	ontology_model_tpl	Шаблон: Модель онтологии	Отображение онтологической модели	{"required": ["model_code", "domain"], "properties": {"domain": {"type": "string", "title": "Домен"}, "model_code": {"type": "string", "title": "Код модели"}, "description": {"type": "string", "title": "Описание"}, "template_count": {"type": "integer", "title": "Количество шаблонов"}}}	[{"type": "info_table", "config": {"style": "table", "fields": [{"key": "model_code", "label": "Код модели"}, {"key": "domain", "label": "Домен"}, {"key": "description", "label": "Описание"}, {"key": "template_count", "label": "Шаблонов"}]}}]	t	{}	1	2026-07-19 08:16:43.681148+00
353e45c6-d01f-4f01-96bb-82558d68f234	e7048181-8484-4cda-b47f-d966fc3cd4f6	1f541075-7f9d-4cf6-a1d0-a7e5b476f1e4	ontology_template_tpl	Шаблон: Шаблон онтологии	Отображение шаблона онтологии	{"required": ["template_code", "template_name"], "properties": {"is_active": {"type": "boolean", "title": "Активен"}, "kind_code": {"type": "string", "title": "Тип сущности"}, "model_code": {"type": "string", "title": "Модель"}, "description": {"type": "string", "title": "Описание"}, "template_code": {"type": "string", "title": "Код шаблона"}, "template_name": {"type": "string", "title": "Название"}}}	[{"type": "info_table", "config": {"style": "table", "fields": [{"key": "template_code", "label": "Код шаблона"}, {"key": "template_name", "label": "Название"}, {"key": "description", "label": "Описание"}, {"key": "kind_code", "label": "Тип сущности"}, {"key": "model_code", "label": "Модель"}, {"key": "is_active", "label": "Активен"}]}}]	t	{}	1	2026-07-19 08:16:43.681148+00
7784c033-1ca7-4714-95c7-8110d5d5a496	8c86f136-2f76-44c4-8d56-e5db5703bff6	a0000000-0000-0000-0000-000000000001	movie_tpl_movie	Шаблон: Фильм	Шаблон для Шаблон: Фильм	{"required": [], "properties": {"year": {"type": "integer", "title": "Год"}, "genre": {"type": "string", "title": "Жанр"}, "budget": {"type": "string", "title": "Бюджет"}, "rating": {"type": "number", "title": "Рейтинг"}, "country": {"type": "string", "title": "Страна"}, "imdb_id": {"type": "string", "title": "IMDb ID"}, "tagline": {"type": "string", "title": "Слоган"}, "tmdb_id": {"type": "string", "title": "TMDb ID"}, "director": {"type": "string", "title": "Режиссёр"}, "duration": {"type": "string", "title": "Длительность"}, "language": {"type": "string", "title": "Язык"}, "age_rating": {"type": "string", "title": "Возрастной рейтинг"}, "description": {"type": "string", "title": "Описание"}, "production_company": {"type": "string", "title": "Кинокомпания"}}, "field_order": ["year", "genre", "budget", "rating", "country", "tagline", "director", "duration", "language", "production_company", "age_rating", "imdb_id", "tmdb_id", "description"]}	[{"type": "image_data_row", "config": {"fields": "[{\\"key\\":\\"year\\",\\"label\\":\\"Год\\",\\"type\\":\\"integer\\"},{\\"key\\":\\"genre\\",\\"label\\":\\"Жанр\\",\\"type\\":\\"string\\"},{\\"key\\":\\"budget\\",\\"label\\":\\"Бюджет\\",\\"type\\":\\"string\\"},{\\"key\\":\\"rating\\",\\"label\\":\\"Рейтинг\\",\\"type\\":\\"number\\"},{\\"key\\":\\"country\\",\\"label\\":\\"Страна\\",\\"type\\":\\"string\\"},{\\"key\\":\\"tagline\\",\\"label\\":\\"Слоган\\",\\"type\\":\\"string\\"},{\\"key\\":\\"director\\",\\"label\\":\\"Режиссёр\\",\\"type\\":\\"string\\"},{\\"key\\":\\"duration\\",\\"label\\":\\"Длительность\\",\\"type\\":\\"string\\"},{\\"key\\":\\"language\\",\\"label\\":\\"Язык\\",\\"type\\":\\"string\\"},{\\"key\\":\\"production_company\\",\\"label\\":\\"Кинокомпания\\",\\"type\\":\\"string\\"},{\\"key\\":\\"age_rating\\",\\"label\\":\\"Возрастной рейтинг\\",\\"type\\":\\"string\\"},{\\"key\\":\\"imdb_id\\",\\"label\\":\\"IMDb ID\\",\\"type\\":\\"string\\"},{\\"key\\":\\"tmdb_id\\",\\"label\\":\\"TMDb ID\\",\\"type\\":\\"string\\"}]", "alt_field": "title", "image_source": "poster"}}, {"type": "aggregated_relations", "config": {"label": "Актёры", "max_items": "10", "relation_type": "acted_in"}}, {"id": "block_7", "type": "aggregated_relations", "config": {"label": "Режисёр", "max_items": "10", "relation_type": "directed_by"}}, {"id": "block_7", "type": "divider", "config": {}}, {"id": "block_4", "type": "text_block", "config": {}}, {"id": "block_2", "type": "gallery", "config": {"title": "Галерея изображений", "height": "200", "source": "images"}}]	t	{}	1	2026-07-18 09:57:20.629452+00
\.


--
-- Data for Name: page_registry; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.page_registry (page_id, page_code, title, title_en, template_name, content, meta_title, meta_description, is_published, sort_order, created_by, created_at, updated_at) FROM stdin;
60000001-0000-0000-0000-000000000001	home	Главная страница	Home Page	default	{"blocks": [{"type": "hero", "title": "META-SYSTEM", "subtitle": "Universal Knowledge Storage"}]}	\N	\N	t	1	\N	2026-07-18 09:57:12.410507+00	2026-07-18 09:57:12.410507+00
60000002-0000-0000-0000-000000000001	catalog	Каталог сущностей	Entity Catalog	catalog	{"pagination": 20, "show_filters": true}	\N	\N	t	2	\N	2026-07-18 09:57:12.410507+00	2026-07-18 09:57:12.410507+00
60000003-0000-0000-0000-000000000001	search	Поиск	Search	search	{"search_types": ["fulltext", "vector", "ai"]}	\N	\N	t	3	\N	2026-07-18 09:57:12.410507+00	2026-07-18 09:57:12.410507+00
\.


--
-- Data for Name: permission; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.permission (permission_id, permission_code, description, created_at) FROM stdin;
d23b25f9-dd74-459d-8121-7ee05667a4ce	entity.create	Создание сущностей	2026-07-20 09:06:27.017003+00
b09dc37f-74ad-4a05-a4c1-e09d532c47b7	entity.read	Просмотр сущностей	2026-07-20 09:06:27.017003+00
9380f0b4-ca3e-4cfc-8a89-053dd980aab9	entity.update	Редактирование сущностей	2026-07-20 09:06:27.017003+00
d694204d-a6b8-430f-8808-7e2116fe1775	entity.delete	Удаление сущностей	2026-07-20 09:06:27.017003+00
77e3227a-041c-453d-9104-7e5aa513504a	entity.import	Импорт сущностей из внешних источников	2026-07-20 09:06:27.017003+00
d9c6524c-97f9-46de-a344-8de88f0b9985	admin.access	Доступ к админ-панели	2026-07-20 09:06:27.017003+00
d5883945-1b1a-4680-8c70-898f8a538e06	admin.kinds	Управление типами сущностей	2026-07-20 09:06:27.017003+00
fc3b62c5-9788-4f87-8e7d-0f1e6440a000	admin.templates	Управление шаблонами	2026-07-20 09:06:27.017003+00
0537782a-bdfc-46f1-b7cb-8fa07a066626	admin.fields	Управление реестром полей	2026-07-20 09:06:27.017003+00
e3ece527-b80a-4378-a85d-713c13287b30	admin.relations	Управление типами связей	2026-07-20 09:06:27.017003+00
9c0d69e4-5aae-4b42-9dd7-79f9c92c0a62	admin.users	Управление пользователями	2026-07-20 09:06:27.017003+00
92838e2f-a73b-4ed3-8310-0dbf96b654a7	admin.ai	Настройка AI	2026-07-20 09:06:27.017003+00
9baefc18-3bd5-4d0e-a24c-7cdfc4ea25a8	plugin.manage	Управление плагинами	2026-07-20 09:06:27.017003+00
\.


--
-- Data for Name: projection_state; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.projection_state (state_id, projection_id, state_data, state_hash, embedding, is_current, created_at, valid_from, valid_to, version_id) FROM stdin;
8f5b0913-b0c7-4e51-ab9e-c0276b55bfda	e0000001-0000-0000-0000-000000000001	{"year": 1999, "genre": "боевик, фантастика", "title": "The Matrix", "budget": "63.0M", "images": "", "poster": "https://image.tmdb.org/t/p/w500/kEDbym5htJgDQNenjUtSJxAHysB.jpg", "rating": 8.251, "content": "", "country": "United States of America", "imdb_id": "tt0133093", "revenue": 467200000, "runtime": 136, "tagline": "«Добро пожаловать в реальный мир»", "tmdb_id": "603", "director": "Ларри Вачовски", "duration": "136 мин", "file_url": "", "language": "English", "audio_url": "", "age_rating": "", "file_title": "", "description": "Жизнь Томаса Андерсона разделена на две части: днём он — самый обычный офисный работник, получающий нагоняи от начальства, а ночью превращается в хакера по имени Нео, и нет места в сети, куда он бы не смог проникнуть. Но однажды всё меняется. Томас узнаёт ужасающую правду о реальности.", "mpaa_rating": "R", "production_company": "Village Roadshow Pictures, Groucho II Film Partnership, Silver Pictures, Warner Bros. Pictures", "production_companies": ["Warner Bros.", "Village Roadshow Pictures"]}	f652764f574fe941afe71d8e557ed23add7ecd0f4f1ca27e7cc09d47e6ea39a0	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
04a6388a-b358-4df5-8463-c85951965064	e0000002-0000-0000-0000-000000000002	{"height_cm": 183, "last_name": "DiCaprio", "birth_date": "1974-11-11", "first_name": "Leonardo", "birth_place": "Los Angeles, USA", "nationality": "American"}	hash4	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
ed18999b-c87d-4848-a2e1-fe40b6e32058	92b80626-11d0-4229-b811-f81e6f7e685e	{"is_active": true, "kind_code": "movie", "model_code": "cinema", "description": "Шаблон для Шаблон: Фильм", "template_code": "movie_tpl_movie", "template_name": "Шаблон: Фильм"}	5a0d005db4e724e822a6e256bd9127217eb722c71a1f9822175d6789366a2bc9	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	117
a2109647-42ee-414a-b9d1-76aeff88cd49	e0000014-0000-0000-0000-000000000002	{"name": "Classical Music", "periods": ["Baroque", "Classical", "Romantic", "Modern"], "description": "Art music rooted in Western tradition"}	hash30	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
331fde60-f836-4902-9269-17f44bebeb0a	e0000026-0000-0000-0000-000000000001	{"name": "Warner Bros.", "type": "Film studio", "founded": 1923, "founders": ["Harry Warner", "Albert Warner", "Sam Warner", "Jack Warner"], "headquarters": "Burbank, California"}	hash31	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
30c01dec-d021-4c80-b3aa-c15f4e4552e6	9a6bc177-7cdc-4c25-aa9b-c62ac474a5dd	{"name": "Киану Ривз", "poster": "https://image.tmdb.org/t/p/w185/8RZLOyYGsoRe9p44q3xin9QkMHv.jpg", "tmdb_id": 6384}	24b0e3605f60209a1593576a8cc2763f1769b275ca380dce7102b0a20d11de83	\N	t	2026-07-19 13:48:58.030416+00	2026-07-19 13:48:58.03042+00	\N	146
92953437-c9a0-4d48-990f-55dd8fe7db42	706584a9-2a9f-4848-98d3-3ce09ba8f877	{"name": "Лоренс Фишбёрн", "poster": "https://image.tmdb.org/t/p/w185/2GbXERENPpl5MmlqOLlPVaVtifD.jpg", "tmdb_id": 2975}	b131a265010e085e5ea4c42271f473519deb3927f176df84affac3e24e7338d9	\N	t	2026-07-19 13:48:58.054461+00	2026-07-19 13:48:58.054464+00	\N	146
5c11a12c-77fe-4cf9-b00e-d8b87cbcb935	f58926e0-ae86-4cf9-9b29-52122e04ccc1	{"name": "Кэрри-Энн Мосс", "poster": "https://image.tmdb.org/t/p/w185/xD4jTA3KmVp5Rq3aHcymL9DUGjD.jpg", "tmdb_id": 530}	d16e7bfb5310d437b917ff1b2b1681a892f76486953f81f104968ba19fbff6e4	\N	t	2026-07-19 13:48:58.061843+00	2026-07-19 13:48:58.061844+00	\N	146
17e1511d-60c6-4225-addc-9f671407304a	892aa355-ee57-476f-9640-009498da38df	{"name": "Хьюго Уивинг", "poster": "https://image.tmdb.org/t/p/w185/lSC8Et0PYi5zeQb3IpPkFje7hgR.jpg", "tmdb_id": 1331}	fbef320287a76643d8f6bfce9dc04cb865f0e6b30b71d7fc3d36c8312f76612b	\N	t	2026-07-19 13:48:58.066203+00	2026-07-19 13:48:58.066204+00	\N	146
be4d72ec-b37c-4d81-8928-fa43fa477ab1	dd793190-1c6c-491b-8343-fd2cca3890a4	{"name": "Глория Фостер", "poster": "https://image.tmdb.org/t/p/w185/AriGXtC9fjBOia9Zr8CZjn4o3rx.jpg", "tmdb_id": 9364}	5f5c1c46c14abbcde3878ea08ee7aa63787334768af709dab2f282b763357a9d	\N	t	2026-07-19 13:48:58.070225+00	2026-07-19 13:48:58.070227+00	\N	146
177564ba-1b7a-45a4-9ac2-48cdee586f06	f0000009-0000-0000-0000-000000000005	{"area": "783.8 км²", "city": "New York", "poster": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/New_york_times_square-terabass.jpg/1280px-New_york_times_square-terabass.jpg", "country": "USA", "population": "8.3 млн"}	hash_p2	\N	t	2026-07-18 09:57:12.920593+00	2026-07-18 09:57:12.920593+00	\N	1
ae4c107a-faf9-4f63-8039-e55f0008847e	f0000009-0000-0000-0000-000000000006	{"area": "1285 км²", "city": "Rome", "poster": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/Colosseo_2020.jpg/1280px-Colosseo_2020.jpg", "country": "Italy", "population": "2.8 млн"}	hash_p3	\N	t	2026-07-18 09:57:12.920593+00	2026-07-18 09:57:12.920593+00	\N	1
687f49a6-2983-4d5f-844b-efb1ff923770	f0000010-0000-0000-0000-000000000004	{"symbol": "Fe", "category": "Переходный металл", "atomic_mass": 55.845, "atomic_number": 26, "electron_config": "[Ar] 3d6 4s2"}	hash_e1	\N	t	2026-07-18 09:57:12.92833+00	2026-07-18 09:57:12.92833+00	\N	1
e8cdc84f-a5b4-45ed-802c-cbb611c89802	aadec829-faec-400f-b176-d3377c7a7341	{"name": "Джо Пантолиано", "poster": "https://image.tmdb.org/t/p/w185/3OHUI3nX4SYGGItDk3xqeIvWtIf.jpg", "tmdb_id": 532}	7a0d4de7a4ca51fdd5024a5a3f139a2dc953de8b8d83c02185ee3cce67178e46	\N	t	2026-07-19 13:48:58.076116+00	2026-07-19 13:48:58.076118+00	\N	146
3de46956-2bb4-4534-abe7-7bde387b5c22	a4f99864-c2e0-4d39-ad1d-7dd743810c33	{"name": "Маркус Чонг", "poster": "https://image.tmdb.org/t/p/w185/q9HQttibTj2MoXVtLjq2kKqmPrE.jpg", "tmdb_id": 9372}	82eb48541fb8002be84dd9b0945ac9255055581228a99db3348d852228618c81	\N	t	2026-07-19 13:48:58.08213+00	2026-07-19 13:48:58.082131+00	\N	146
5c143316-44c0-4bc8-ac34-82be6c83e6cf	f7d62057-688d-4fec-b265-07e556c2dcc1	{"name": "Джулиан Араханга", "poster": "https://image.tmdb.org/t/p/w185/g2YkF3PWSJU1vTKuURBH0DOMblm.jpg", "tmdb_id": 7244}	91aabad4503d637b8ae4e8bdd08f9595e910d0e071b8a70aef0357aff20edc07	\N	t	2026-07-19 13:48:58.087058+00	2026-07-19 13:48:58.08706+00	\N	146
a04ec00a-d8f0-4d97-9194-73bc47c20a8f	be0274e6-ae82-4af8-9516-a1cbc5ea0b5d	{"name": "Мэтт Доран", "poster": "https://image.tmdb.org/t/p/w185/4HtMShAbsZ2AyFtq5z3bOVrvw2s.jpg", "tmdb_id": 9374}	ae2d8e5c05642d0f18209c31df5ba933b9329a26e5984888f224e242c264da61	\N	t	2026-07-19 13:48:58.091913+00	2026-07-19 13:48:58.091914+00	\N	146
af543e9b-db34-428f-883e-6f7b5318b8cd	03bcc812-9a9c-4d0b-8e25-804e2e20a914	{"name": "Белинда МакКлори", "poster": "https://image.tmdb.org/t/p/w185/wfTCwkIDJjH5k5DtuvcjP52PrLc.jpg", "tmdb_id": 9376}	05fe42967e447755902f78986c55c33d10e755ff0ac47a09ac9691532fd0bb0c	\N	t	2026-07-19 13:48:58.095708+00	2026-07-19 13:48:58.095709+00	\N	146
2127a3b5-0a46-4f13-9dde-295ca6782698	92774323-efa4-4404-9d3e-90ec1c7bb233	{"year": 2016, "genre": "приключения, комедия, семейный, мультфильм", "title": "Моана", "budget": "150.0M", "images": "", "poster": "https://image.tmdb.org/t/p/w500/drbVlDdeqRLoxylGpym4dECh5ai.jpg", "rating": 7.566, "content": "", "country": "United States of America", "imdb_id": "tt3521164", "tagline": "«Океан Зовёт»", "tmdb_id": "277834", "director": "Рон Клементс", "duration": "103 мин", "file_url": "", "language": "English", "audio_url": "", "age_rating": "", "file_title": "", "description": "Действие происходит 2000 лет назад, в островах Тихого океана. Дочка вождя, 14-летняя мечтательница Моана Ваялики, чтобы найти свою семью, отправляется в путешествие по океану в поисках сказочного острова с её героем полубогом-трикстером Мауи, и вместе им предстоит переплыть океан, встречая по пути огромных морских существ.", "production_company": "Walt Disney Animation Studios"}	cbe9f4a0da6532ebc11017305b1dc09a2954d80e559f10d6b443182c8158c910	\N	t	2026-07-19 14:10:57.965205+00	2026-07-19 14:10:57.965207+00	\N	147
75e51cf5-d814-47be-b6bf-a7b0f3d3baca	61953102-23fb-4c7e-9dc3-d8cd6ab9cd17	{"year": 1982, "genre": "фантастика, драма, триллер", "budget": "28.0M", "poster": "https://image.tmdb.org/t/p/w500/gajva2L0rPYkEWjzgFlBXCAVBE5.jpg", "rating": 7.9, "country": "United States of America, Hong Kong, United Kingdom", "imdb_id": "tt0083658", "tagline": "«Человек нашёл себе достойную замену... теперь это его проблема»", "tmdb_id": "78", "director": "Ридли Скотт", "duration": "117 мин", "language": "English, Deutsch, 广州话 / 廣州話, 日本語, Magyar", "age_rating": "12", "description": "Ноябрь 2019 года. Бывший охотник на андроидов Рик Декард восстановлен в полиции Лос-Анджелеса для поиска возглавляемой Роем Батти группы репликантов, совершившей побег из космической колонии на Землю. В полиции считают, что андроиды пытаются встретиться с Эндолом Тайреллом - руководителем корпорации, которая разрабатывает кибернетический интеллект. Декард получает задание выяснить мотивы репликантов и уничтожить их.", "production_company": "Shaw Brothers, The Ladd Company, Warner Bros. Pictures"}	c2c8b5a889fcfb6afd7526cd97f14d19feecc41abf73adcfc1b7e6d2672019d3	\N	t	2026-07-19 07:46:45.454249+00	2026-07-19 07:46:45.45425+00	\N	110
d115ed7f-cec2-4831-bc41-a5ad5f533779	62d87c25-37cb-4479-87d4-c811f3285061	{"bpm": 118, "year": 1982, "album": "Thriller", "genre": "Pop", "title": "Thriller", "artist": "Michael Jackson", "duration_sec": 357}	ab2663a0bc6b21b5b6eea4e47b63758551153a41214676a628b7b2c415f6b7ac	\N	t	2026-07-18 09:57:21.04899+00	2026-07-18 09:57:21.04899+00	\N	1
764319f3-da35-46b2-820d-5a1a68bcb064	c34842a1-9f13-483d-be1c-a7f6eb1bcbe8	{"title": "Чокнутый профессор (Коллекция)2", "poster": "http://localhost:9000/dwmb-media/entities/485dee97-cde2-4603-8aa3-1b9364a5cbb1/%D0%A7%D0%BE%D0%BA%D0%BD%D1%83%D1%82%D1%8B%D0%B9_%D0%BF%D1%80%D0%BE%D1%84%D0%B5%D1%81%D1%81%D0%BE%D1%80_%28%D0%9A%D0%BE%D0%BB%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F%292.png?AWSAccessKeyId=dwmb_minio&Signature=SMIqsHe3htpwlN8efdvU3n5AA%2FY%3D&Expires=1784477603"}	d184dbc3bf6cc6b5c5a56915b5ce0a998f9e457de7f438297b38ee050f53120f	\N	t	2026-07-19 15:13:23.04008+00	2026-07-19 15:13:23.040082+00	\N	1
72f64b0a-64f7-4bcd-8a9b-5fe20833d440	5dda904d-07d8-4d6a-a059-e4bcacc786b1	{"title": "Чокнутый профессор (Коллекция)", "poster": "http://localhost:9000/dwmb-media/entities/ce6d5b1a-8536-4823-88c3-6d077da6c23c/%D0%A7%D0%BE%D0%BA%D0%BD%D1%83%D1%82%D1%8B%D0%B9_%D0%BF%D1%80%D0%BE%D1%84%D0%B5%D1%81%D1%81%D0%BE%D1%80_%28%D0%9A%D0%BE%D0%BB%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F%29.jpg?AWSAccessKeyId=dwmb_minio&Signature=UPrqAxAKo3tpyFpiE3E0VlMWaDQ%3D&Expires=1784477603"}	b5e711bacc18fb0e83189d98eccc5ebfc51a8f7e844999843b84408c70d784ea	\N	t	2026-07-19 15:13:23.110872+00	2026-07-19 15:13:23.110873+00	\N	1
8ff3250e-3e89-4ea9-b5b2-d7157a99412e	00a4fe02-5e60-4a30-9839-f23ec52e20a8	{"title": "Легенда о Ло Сяохэе2", "poster": "http://localhost:9000/dwmb-media/entities/c42af2c3-8bff-431d-84aa-31fee4e37dba/%D0%9B%D0%B5%D0%B3%D0%B5%D0%BD%D0%B4%D0%B0_%D0%BE_%D0%9B%D0%BE_%D0%A1%D1%8F%D0%BE%D1%85%D1%8D%D0%B52.jpg?AWSAccessKeyId=dwmb_minio&Signature=dsdEV0rVheyXLSEOoGaQb3fjYgA%3D&Expires=1784477603"}	6b55da8993b8dbb74004391733f6865cff0eb0f85eaf84180c0b3ec6ad7ddd3b	\N	t	2026-07-19 15:13:23.146473+00	2026-07-19 15:13:23.146474+00	\N	1
944a1a24-6a4e-4169-a690-7aa618f1c1c6	5820c046-43c4-496f-bfc5-9a7281c8119d	{"title": "Легенда о Ло Сяохэе", "poster": "http://localhost:9000/dwmb-media/entities/9559dcd0-3ee8-4941-ac8e-65bde4b2e705/%D0%9B%D0%B5%D0%B3%D0%B5%D0%BD%D0%B4%D0%B0_%D0%BE_%D0%9B%D0%BE_%D0%A1%D1%8F%D0%BE%D1%85%D1%8D%D0%B5.jpg?AWSAccessKeyId=dwmb_minio&Signature=HhcUx7OyP8irbInbOgH3V%2BgbO8E%3D&Expires=1784477603"}	c6b9e222c9a0a03f0ba4838ac9517868eed1acaa36ffc02242e49027ac00eb5a	\N	t	2026-07-19 15:13:23.168866+00	2026-07-19 15:13:23.168867+00	\N	1
1e470dff-0f72-43c5-acdc-59607213a205	86b68c72-206c-45ad-af54-c36dfa3cf97f	{"title": "4.Комнаты", "poster": "http://localhost:9000/dwmb-media/entities/b56aeff9-0ebd-4687-b5f3-c7bdd8efa1a6/4.%D0%9A%D0%BE%D0%BC%D0%BD%D0%B0%D1%82%D1%8B.jpg?AWSAccessKeyId=dwmb_minio&Signature=zbOg52splongeakg3tXTQF%2FNbIM%3D&Expires=1784477603"}	6b4c93026d389a1b468f9d78f9965a6895431b902f29aca1eeb9de575233e365	\N	t	2026-07-19 15:13:23.424309+00	2026-07-19 15:13:23.424311+00	\N	1
eadcf808-48e3-4c6e-9766-8c6ce3fe3426	2ffadf51-6896-41bf-95f8-42bbe9d2e2f8	{"last_name": "Tolkien", "birth_date": "1892-01-03", "first_name": "John Ronald Reuel", "occupation": "Writer", "birth_place": "Bloemfontein, South Africa", "nationality": "British"}	202e8bdaaf15a64125f80613f58f7eec9dc135bcbd38c6a6dd361d483b6cf1ea	\N	t	2026-07-18 09:57:21.353025+00	2026-07-18 09:57:21.353025+00	\N	1
5a5a59a4-c120-4d42-9872-79d8696d14e4	e5bb181d-736c-466e-815a-e906a706fe7e	{"year": 1997, "genre": "боевик, приключения, фэнтези, ужасы, фантастика, триллер", "budget": "40.0M", "poster": "https://image.tmdb.org/t/p/w500/tOj9xaHzUX4sbHvXsfilxR2xQfT.jpg", "rating": 5.46, "country": "United States of America", "imdb_id": "tt0120177", "tagline": "«Рождённый в темноте, осужденный на справедливость»", "tmdb_id": "10336", "director": "Марк А. З. Диппе", "duration": "93 мин", "language": "English", "description": "«Краповый берет» Эл Симмонс убит своим начальником во время выполнения очередной миссии. Попав в чистилище, он заключает сделку с Дьяволом. Сатана дает ему силу, доспехи и оружие.В обмен на то, чтобы еще раз увидеть свою жену, Симмонс должен предварить приход сил Зла на Землю. Оказавшись на свободе, он разрывает контракт в одностороннем порядке…", "production_company": "New Line Cinema, Pull Down Your Pants Pictures, Todd McFarlane Entertainment, Juno Pix"}	7c75547931e476fd90472e578670119fc0023b1652684918e1b3fca601048608	\N	t	2026-07-19 16:57:18.140875+00	2026-07-19 16:57:18.140877+00	\N	148
f8a80e96-b2a9-4314-9622-ab198979f616	cb99dfa6-9f37-4e04-99ba-2fe837d73d9a	{"title": "моана", "poster": "http://localhost:9000/dwmb-media/entities/1ecd1e93-4eef-4ecb-9ff5-b77c1c4211c3/%D0%BC%D0%BE%D0%B0%D0%BD%D0%B0.webp?AWSAccessKeyId=dwmb_minio&Signature=tFS7at0Lpk70OYKc3kAkG0qjbdU%3D&Expires=1784411912", "тут данные": ""}	c0d439f1f182376820065a027a721055af9cd2ac3866420ae7ee9bbf3ee9bbae	\N	t	2026-07-18 20:58:32.209307+00	2026-07-18 20:58:32.209314+00	\N	1
ca118f43-92e5-4feb-a229-75be43c92bfa	c5330eb1-2122-444a-aa7e-f7266a3e8aa0	{"tmdb_id": "3"}	0bfe43af09e8418ca4055f5b80ca6741b340ace0c86960a2262978224ff62de4	\N	t	2026-07-19 17:35:23.971578+00	2026-07-19 17:35:23.97158+00	\N	149
e303c232-abb8-46a7-9cc2-10f1a6b06fac	83c5ad1b-1402-4361-8371-0931292979a7	{"tmdb_id": "585"}	6a2d756b4abf816c18a821607a022f5fe847f4c08b113786cf3c7ce03311d5fa	\N	t	2026-07-19 17:35:23.977704+00	2026-07-19 17:35:23.977706+00	\N	149
93de28ff-3aaa-4ff2-8c1e-79722d238ba9	b5bdf1b2-d6a2-4e9a-a5ae-becd088ca012	{"tmdb_id": "586"}	89d61efb847a072a30d13480bbd043cbeea3c05733017000de0521c8d835b054	\N	t	2026-07-19 17:35:23.981606+00	2026-07-19 17:35:23.981607+00	\N	149
6a2f4570-d2c5-4136-85a7-4490da1d42de	7ff31578-8b55-45d8-9bbf-91b0a7525bb7	{"tmdb_id": "587"}	e1bd8b4a1cf307e2a8c8dc42ec7d65afa9a21d1ca6ed5b214d982152253ddd94	\N	t	2026-07-19 17:35:23.985438+00	2026-07-19 17:35:23.985439+00	\N	149
06722618-83e3-4e8c-b632-49207150eac7	2f0c96a7-2ecd-46af-85e8-1f01dee00683	{"tmdb_id": "588"}	a755952695dd22e467238dc5e10266f407ebf960f94333d29e94b656f2acd60f	\N	t	2026-07-19 17:35:23.989357+00	2026-07-19 17:35:23.989358+00	\N	149
2ab1e2dc-2917-4a3c-bd87-7f13f96559bd	44866e92-9bbc-490d-b669-db2707e549d2	{"tmdb_id": "589"}	df80c2755fd815ebf03684aa529790a592534cbb5d07ca33288ebd351292f3b9	\N	t	2026-07-19 17:35:23.993836+00	2026-07-19 17:35:23.993837+00	\N	149
b0773c85-ea9a-4656-b114-3d8607a16135	a6017768-8eed-4bd4-8338-d45eba357abd	{"tmdb_id": "590"}	925cc8b94468cb5acf5697be2823c9f37f6b045b413e3ee502e360aa8ddb717b	\N	t	2026-07-19 17:35:23.997976+00	2026-07-19 17:35:23.997977+00	\N	149
af50127d-90c5-4ec8-8da7-a9a9db02a536	8022d0fa-eb01-4385-b009-61b872e3d036	{"tmdb_id": "591"}	8e1c142f1a1b1717a1d0187f2023b6113a423336e8a7dcd09aa94ed3236458c1	\N	t	2026-07-19 17:35:24.002019+00	2026-07-19 17:35:24.002021+00	\N	149
a64aed17-1891-4bac-b31a-38ef900096ba	621ccdbc-1f80-4974-bc0d-e56fe0ca0ecf	{"tmdb_id": "592"}	8c63901df51779a88153f68832b87f2937ddf29d3a2b45182c460d429d214fda	\N	t	2026-07-19 17:35:24.006364+00	2026-07-19 17:35:24.006365+00	\N	149
79b41f54-cf64-4175-ae16-6a51cd6724cb	58c1d656-b2e5-493a-b773-a4b678b64b2a	{"tmdb_id": "593"}	d5fdc60a4d8b20a15a1d65c65ebf840509f3eeeeb4552045259261b70f6f7bb3	\N	t	2026-07-19 17:35:24.010501+00	2026-07-19 17:35:24.010502+00	\N	149
8cde99b2-eb9b-4c0c-9216-db8c93f2dec1	612d6657-a1f8-4846-b73b-37576f8c6304	{"tmdb_id": "20904"}	a9393894216f5f197bbee4e20fbf0b83e012795668dce45b2e8d5b49c0c5dd81	\N	t	2026-07-19 17:35:24.014572+00	2026-07-19 17:35:24.014574+00	\N	149
96dd2658-55c9-4b38-92b3-125630b5516e	bf61c434-1f7e-4306-807f-68b2e27d262f	{"tmdb_id": "58495"}	6f0f9238f8315c7501b52d9259351863f25f084b5196ba763aed20f1f0a9188d	\N	t	2026-07-19 17:35:24.018678+00	2026-07-19 17:35:24.01868+00	\N	149
b00652bc-72ca-4b0a-a880-9dc5bd02bd70	d25b91cf-596b-459d-80f8-13ac1b083bad	{"tmdb_id": "53760"}	fd15e73b2b75d2fb90f045326d2b8c7084afe3b8b009a403105e70b4b773fd8c	\N	t	2026-07-19 17:35:24.022529+00	2026-07-19 17:35:24.02253+00	\N	149
24d5b261-30ea-4a7b-8cb3-4a2fd3e29f00	7881a7a1-6aea-4d8d-80d6-97793e60fad3	{"tmdb_id": "943481"}	0cf9f33f201e0114d826d7b5ee11b937fd81786dce1c7cba9d15d364f395d47e	\N	t	2026-07-19 17:35:24.026426+00	2026-07-19 17:35:24.026427+00	\N	149
a70b4f3b-9294-478e-93d0-f40799eaf1aa	d65d0b30-03bb-49b1-8fd7-847edb52ebac	{"tmdb_id": "107074"}	2c861dfec43be18d502e5dbb0c71cc4b821b349c5b5d3c48de7ca4c292f2c2e0	\N	t	2026-07-19 17:35:24.030451+00	2026-07-19 17:35:24.030452+00	\N	149
57f24a1e-5cc8-42ab-b89a-064243cd31f4	aab7cb0d-f4ff-4769-94a6-0d570fe5e089	{"tmdb_id": "578"}	67397f1bb08062a400d90111df3fd8d3088937f4e006652082496fe0cc456277	\N	t	2026-07-19 17:35:24.034579+00	2026-07-19 17:35:24.034581+00	\N	149
1b9b5fab-2635-4e62-8701-39ceed29267c	2fb66f75-8c84-4a7d-a3be-772c11816a73	{"name": "Renaissance", "domain": "History", "definition": "Cultural rebirth in Europe"}	4f5494b6e3dcedb93dccb23d65dd15076f517fa47a64486855bf7e69e943e792	\N	t	2026-07-18 09:57:22.060887+00	2026-07-18 09:57:22.060887+00	\N	1
6c18251e-836e-4af3-a7d1-d7e19e8bbaa7	cc7780ca-3303-4c64-8d1b-e6577825b3b7	{"tmdb_id": "4865931"}	be4d78ad3a5b23e82415f414002d0631599240607812b98c94be6751eecb24b2	\N	t	2026-07-19 17:54:23.168022+00	2026-07-19 17:54:23.168023+00	\N	151
39ce6c1d-51ee-4312-8c8b-5d1ef0630c56	c0701267-0db0-4aea-a58f-b44584a0fc19	{"poster": "https://image.tmdb.org/t/p/w185/gjfDl52Kk02MPgUYFjs9bOy33OY.jpg", "tmdb_id": "12073"}	b5b78fd2f11a0d19d02ab6ff8fc2a17281ae9e92ed2a856184170f69c6c89dd8	\N	t	2026-07-19 17:54:23.1205+00	2026-07-19 17:54:23.120502+00	\N	151
0cc8909f-d7ee-4287-abf7-cc65e68906c4	d3389f14-d9e3-4857-bb7c-4d8545a4f18a	{"poster": "https://image.tmdb.org/t/p/w185/qgjMfefsKwSYsyCaIX46uyOXIpy.jpg", "tmdb_id": "776"}	cdf7a30ce4fc72898f53251d070fbbabb0f232acb5a760ab560b30b9a9642bc0	\N	t	2026-07-19 17:54:23.127252+00	2026-07-19 17:54:23.127253+00	\N	151
2bf95bcf-70eb-4cbf-b892-8686ca756438	57d94611-2ac2-4118-82f7-e74d498502ad	{"poster": "https://image.tmdb.org/t/p/w185/tTpQSKwdLrR6xBGHCqg8VcVQZzH.jpg", "tmdb_id": "6941"}	b61d5b96e7b5ec2a89c474719de8b815dad191e591fdc3578bbc7f40d1e5d54a	\N	t	2026-07-19 17:54:23.131431+00	2026-07-19 17:54:23.131432+00	\N	151
a5a05447-ee33-466b-8bda-048a1b1eccce	07b4d6d2-5034-4225-97a9-db05c1436a9d	{"poster": "https://image.tmdb.org/t/p/w185/ajfuBSm1HuVqFJlbTmAlza62Xxr.jpg", "tmdb_id": "12074"}	e76cb77e3c34917e20a97f28c04fa3af7b258654c639daf86fa3e70d549e117c	\N	t	2026-07-19 17:54:23.135312+00	2026-07-19 17:54:23.135313+00	\N	151
e4d07119-a493-468c-a970-6af788f3e6c3	c62a9f19-5458-4fc7-ad15-445ead40d427	{"poster": "https://image.tmdb.org/t/p/w185/ivUQfhn5olOmR5hthN8C8GThBV4.jpg", "tmdb_id": "1925"}	9157c14637e7824c6ec5cee92bb283ce1fc66c4b32fa0e5b61c244599c92e237	\N	t	2026-07-19 17:54:23.139146+00	2026-07-19 17:54:23.139147+00	\N	151
4a9acbd3-bb06-4d46-a092-672a8fd1db5e	eb43c50e-60c1-45b5-abc7-359601b20e78	{"poster": "https://image.tmdb.org/t/p/w185/A2lPsbLYrhXcKL82byfU8FAfaMY.jpg", "tmdb_id": "12075"}	4e0ff1390ececc347107bf39a422786b04a9c48f04d00ad3de38fd8514c383a9	\N	t	2026-07-19 17:54:23.143112+00	2026-07-19 17:54:23.143113+00	\N	151
27948b18-caf6-4a52-93f0-d4952674c87f	ff91f21b-087c-46f5-8972-9a86b1f0b16d	{"poster": "https://image.tmdb.org/t/p/w185/aRwEqA2YmmymjuJ0lheFKLE6gwU.jpg", "tmdb_id": "12076"}	d6803d9e47e307aad6adf942742960242c9a3fa214c54d1c48997bab7f8c905e	\N	t	2026-07-19 17:54:23.146884+00	2026-07-19 17:54:23.146885+00	\N	151
54c2a196-5af3-41da-a36a-0696ddcc861b	107a2deb-a241-40d6-985a-f7dbfed74b7f	{"poster": "https://image.tmdb.org/t/p/w185/c0sQPRCM5Ri3F4gVyxPr4AcPmIq.jpg", "tmdb_id": "12077"}	02beea65930bcc487787c1e69fd42b3b5e9e94a29c30a879263fd429ea0eb25f	\N	t	2026-07-19 17:54:23.15051+00	2026-07-19 17:54:23.150511+00	\N	151
255c7dce-4a74-47c8-a988-41afd4982295	563c1151-fc87-4e3d-a620-9d8e71fb7ffc	{"poster": "https://image.tmdb.org/t/p/w185/l4ktDZmixDQIhXfDsyLvTGANXiy.jpg", "tmdb_id": "12078"}	2963a5238a705c78cbfd9a6adc316dad766106ac65c0310518db0bd6ad9a0a3c	\N	t	2026-07-19 17:54:23.154318+00	2026-07-19 17:54:23.154319+00	\N	151
668a0aaa-e6a1-4a48-8acc-742a787dd63b	180048a1-e479-4bdc-95da-af2c2d259d12	{"poster": "https://image.tmdb.org/t/p/w185/qKdbhP9amIRlydcoivWlTx3szuS.jpg", "tmdb_id": "12098"}	a2af31fe7fdfbc4cfd97edf0a416a1de872e67d1b6d9554353bf2536215c5847	\N	t	2026-07-19 17:54:23.157907+00	2026-07-19 17:54:23.157908+00	\N	151
900c9aa7-94a9-458b-a2f0-593590c75212	08ec1204-ba11-488d-8c57-2342ea453b59	{"poster": "https://image.tmdb.org/t/p/w185/gmlav8ikKPojgvQOQ8vQSQt9hoj.jpg", "tmdb_id": "12095"}	0acaf8904ceb74ea76b50b6f0d5d65990e3d9d4c24f64b4ee2b2c5466c7ae574	\N	t	2026-07-19 17:54:23.161415+00	2026-07-19 17:54:23.161416+00	\N	151
c3ed0d40-2e0c-4657-907e-ac82987f1a32	ea72f562-d8a6-41f7-a6ec-1675843be5ec	{"poster": "https://image.tmdb.org/t/p/w185/pAlKHL8sshImJPCN45iQ5PGuURZ.jpg", "tmdb_id": "7210"}	c4f43f52340a9f159b51a790da5569b5fa89f4aa914f954e5989b00f97b51391	\N	t	2026-07-19 17:54:23.16471+00	2026-07-19 17:54:23.164711+00	\N	151
6539377f-5f8e-4a41-970f-5a7e6d7538b5	c21bcc41-b5c9-4a08-ba00-dcc52764c1e9	{"poster": "https://image.tmdb.org/t/p/w185/fsdaXx2ytNx2KEW438mlFfSSzkc.jpg", "tmdb_id": "12097"}	1e6e60ee2fc1432ab83586acc59c15a9ea59c46fbe385d341ec4ade2958fac26	\N	t	2026-07-19 17:54:23.1712+00	2026-07-19 17:54:23.171201+00	\N	151
c3809833-2f1f-45e3-bc39-8e4178d20eb3	02d16ff6-3ab9-480b-868c-d768f6b109b1	{"poster": "https://image.tmdb.org/t/p/w185/puCP7MQ8Gm9aKGcQiOcLiKIKcpJ.jpg", "tmdb_id": "44114"}	ea23b886b26efa619382fdf8a396f7bb797ef1b8c5090b30093cef405de4c583	\N	t	2026-07-19 17:54:23.174467+00	2026-07-19 17:54:23.174468+00	\N	151
01770a4c-006b-4566-bcca-8ef2c3dc6d3b	f468530a-e9a2-4625-8a94-9d4df3466d0d	{"poster": "https://image.tmdb.org/t/p/w185/qqIAVKAe5LHRbPyZUlptsqlo4Kb.jpg", "tmdb_id": "5524"}	545fff74dd3e9b607c4d3c4e1538fb58bf7cba1744f1e45b93a83ddc2de166f3	\N	t	2026-07-19 17:54:23.177722+00	2026-07-19 17:54:23.177723+00	\N	151
b40a8fee-e88b-4929-8922-e5883c672e40	ce8d3db0-84eb-42e0-a493-c061fc968327	{"poster": "https://image.tmdb.org/t/p/w185/dDSlofPZbJxtYBO2f73XjNwcFVT.jpg", "tmdb_id": "12058"}	e579313b08a97a70c6b95ba15d8c6cc6b4d75ae989dd75bac1ca1c6a4b27c477	\N	t	2026-07-19 17:54:23.180994+00	2026-07-19 17:54:23.180995+00	\N	151
55d746ed-ef5e-432a-80ba-0c1c70d105ff	cc9b7dd3-40dd-4195-b7cd-c126d41258f7	{"poster": "https://image.tmdb.org/t/p/w185/yQ0J92DMiLtQYoytLJ6CuBkdeN0.jpg", "tmdb_id": "5823"}	252a336b96535fd39217b1061cf1299893cf79ca9052d94dc337008fcffd90d8	\N	t	2026-07-19 18:00:17.264999+00	2026-07-19 18:00:17.265001+00	\N	153
e992dfda-fcad-4cc3-ac3b-80be8e1a0497	a8ed4e63-c56f-4f31-a238-e751b6c435f7	{"poster": "https://image.tmdb.org/t/p/w185/fce7zl6elUzsv7wudHFc7RgFtjD.jpg", "tmdb_id": "3131"}	07ec48d763a9c98f79a00295fc693b5b3c814cf5056f2f201a7a9a532227534a	\N	t	2026-07-19 18:00:17.269459+00	2026-07-19 18:00:17.26946+00	\N	153
446425a9-7106-4549-ae20-4fae47f49a52	52ee8010-258e-450f-b4d5-5a890a15aa2d	{"poster": "https://image.tmdb.org/t/p/w185/nQpBf77cStmR35V0XOinm2zZMWG.jpg", "tmdb_id": "8930"}	f2e4dcefcf445c54051f5f70be868dff5908d8cc3c7b3c6b77543fe349fd792f	\N	t	2026-07-19 18:00:17.273496+00	2026-07-19 18:00:17.273497+00	\N	153
53393b0d-689f-489b-84b0-2b6171e12a48	e3a0c507-987f-4199-a278-2b2d5a247702	{"poster": "https://image.tmdb.org/t/p/w185/g0kqfIxf9eIV7rOMQcbebsgMS9Z.jpg", "tmdb_id": "4757"}	a8060c0088f6d3b195e85c271f6eeed88650a7283a0ad42eacd3c677e3b7b4d3	\N	t	2026-07-19 18:00:17.277841+00	2026-07-19 18:00:17.277843+00	\N	153
807c0141-65eb-46d1-b38c-d4b242fec456	4063e7b6-8904-4253-862a-b5bb7f6cab5e	{"poster": "https://image.tmdb.org/t/p/w185/pTgxwHcz9L8SNVYvPJS0o0lgHya.jpg", "tmdb_id": "12094"}	63d68bb441ec761f61cc9e0b49fbe027589a7c3227e9742ab0e1a6ae06700edc	\N	t	2026-07-19 18:00:17.282597+00	2026-07-19 18:00:17.282598+00	\N	153
7427a2e7-c9f1-43ac-b1f7-1335b14f0d9b	069115c4-0d7d-44a1-bc86-b3b2b32ceecc	{"poster": "https://image.tmdb.org/t/p/w185/xufgIi9MJIuLmn3q4qi3AMmFtkM.jpg", "tmdb_id": "12106"}	8ba2f778aa6f49bcaac6021d99e1b59e3af5285a94ce43e3ebcb5cd1bbafa614	\N	t	2026-07-19 18:00:17.286361+00	2026-07-19 18:00:17.286362+00	\N	153
8fcba13a-3a07-4f0f-9691-8b9c4eab02a4	098f43d4-255f-4ca1-acd7-2d173b75ebcb	{"poster": "https://image.tmdb.org/t/p/w185/fzHQFYLc1zVVn3dUjr6pMuKdE0U.jpg", "tmdb_id": "12079"}	6f5fc266628b1581444b8c1610cbaec39d62d1ffe2b5152e51e72ca18a24f654	\N	t	2026-07-19 18:00:17.289961+00	2026-07-19 18:00:17.289962+00	\N	153
fa53f597-3e3d-4291-b06d-ab293ee874b3	d9670e8a-00d6-428f-ae57-d1c27c4165e9	{"poster": "https://image.tmdb.org/t/p/w185/2fhutx4eTBE6UR3eIRfYozKsUjk.jpg", "tmdb_id": "12080"}	6a5af247d3afae19b98782670ad3dc36403aa1a57114af2b2fb32bcc84159303	\N	t	2026-07-19 18:00:17.295289+00	2026-07-19 18:00:17.29529+00	\N	153
21f44458-076b-4543-a926-e8e8b6d3f717	19818e98-346f-4cd0-9534-4f2a0d66a3d3	{"poster": "https://image.tmdb.org/t/p/w185/aStDapu9EAObbEwXyE1L2tDs7qN.jpg", "tmdb_id": "1077844"}	c4c9f7173dd359558de826739636393edf3be35dbb3dc48ae7ead82fb6270da4	\N	t	2026-07-19 18:00:17.30047+00	2026-07-19 18:00:17.300471+00	\N	153
83a58f34-759c-4cd3-bce7-f239916fe92a	b23c4bca-c593-43bc-a23d-02d8d19d6418	{"poster": "https://image.tmdb.org/t/p/w185/1I65kWE6cM25G14Wz3TanpTtYev.jpg", "tmdb_id": "71857"}	71b00dc23d8961fa69c60177c138afd592f90b051db20784b3c4128e8062a57d	\N	t	2026-07-19 18:00:17.303721+00	2026-07-19 18:00:17.303721+00	\N	153
110f7d44-4ff7-4a80-abe4-182f7aec39d5	e996ca57-23ba-4752-aebf-75828de3ffbb	{"poster": "https://image.tmdb.org/t/p/w185/2fhutx4eTBE6UR3eIRfYozKsUjk.jpg", "tmdb_id": "12080"}	6a5af247d3afae19b98782670ad3dc36403aa1a57114af2b2fb32bcc84159303	\N	t	2026-07-19 18:00:17.306966+00	2026-07-19 18:00:17.306967+00	\N	153
846d02ba-b1e3-42cc-b903-f8f33c619a50	feb7943f-7b21-4115-a93f-1c2324d1bc59	{"poster": "https://image.tmdb.org/t/p/w185/fzHQFYLc1zVVn3dUjr6pMuKdE0U.jpg", "tmdb_id": "12079"}	6f5fc266628b1581444b8c1610cbaec39d62d1ffe2b5152e51e72ca18a24f654	\N	t	2026-07-19 18:00:17.310481+00	2026-07-19 18:00:17.310482+00	\N	153
4db3cef1-c496-4de7-98fb-c074952988fb	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	{"year": 2004, "genre": "мультфильм, комедия, семейный, фэнтези, мелодрама", "budget": "150.0M", "images": "", "poster": "https://image.tmdb.org/t/p/w500/vALSn7rJEuX742gWKcmCVLquw5J.jpg", "rating": 7.325, "content": "", "country": "United States of America", "imdb_id": "tt0298148", "tagline": "«Не тот Принц»", "tmdb_id": "809", "director": "Конрад Вернон", "duration": "93 мин", "language": "English", "age_rating": "", "description": "Шрэк и Фиона возвращаются после медового месяца и находят письмо от родителей Фионы с приглашением на ужин. Однако те не подозревают, что их дочь тоже стала огром! Вместе с Осликом счастливая пара отправляется в путешествие, полное неожиданностей, и попадает в круговорот событий, во время которых приобретает множество друзей…", "production_company": "DreamWorks Animation, Pacific Data Images"}	13b38e89885da67c606dfe17503e07557065da6e7a103d6a1c42a56535cd4d1b	\N	t	2026-07-19 18:00:09.249804+00	2026-07-19 18:00:09.249806+00	\N	152
ebaba17e-2fc2-4948-9c4c-4e2d613b1b1c	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	{"year": 2001, "genre": "мультфильм, комедия, фэнтези, приключения, семейный", "budget": "60.0M", "images": "", "poster": "https://image.tmdb.org/t/p/w500/5OPCH713UIEeWuvRZpVkkzrZ3Hd.jpg", "rating": 7.773, "content": "", "country": "United States of America", "imdb_id": "tt0126029", "tagline": "«Большой Зелёный Великан»", "tmdb_id": "808", "director": "Эндрю Адамсон", "duration": "90 мин", "language": "English", "age_rating": "", "description": "Жил да был в сказочном государстве большой зелёный великан по имени Шрэк. Жил он в гордом одиночестве в лесу, на болоте, которое считал своим. Но однажды злобный коротышка - лорд Фаркуад, правитель волшебного королевства, безжалостно согнал на болото всех сказочных обитателей. И беспечной жизни зелёного тролля пришёл конец. Но лорд Фаркуад пообещал вернуть Шрэку болото, если великан добудет ему прекрасную принцессу Фиону , которая томится в неприступной башне, охраняемой огнедышащим драконом...", "production_company": "Pacific Data Images, DreamWorks Animation, DreamWorks Pictures"}	cc729e18c5274dab6a76d3b17a94d72a6d1b8c49c80313c83c2f74074f7a9a3d	\N	t	2026-07-19 17:51:27.956861+00	2026-07-19 17:51:27.956863+00	\N	150
524b342f-9b88-4add-9eb3-3eb87f0436ec	6a1793b8-15ff-4f6d-b265-b4618217105a	{"name": "Энтони Рэй Паркер", "poster": "https://image.tmdb.org/t/p/w185/k03O1ClFvGRSedUnK0sAjTkrogX.jpg", "tmdb_id": 9378}	7749f4fb4ad93c63fb7fce743eb75ca965f688587f00624f34c07bb7464c3bf4	\N	t	2026-07-19 13:48:58.099464+00	2026-07-19 13:48:58.099466+00	\N	146
2e0d72c1-48ac-4545-8dae-56ca08eb40fb	737be451-4908-46e2-9199-b1a84a8b5d24	{"name": "Пол Годдард", "poster": "https://image.tmdb.org/t/p/w185/z6XP6Xhkh5ZE88gBOz2FnVQaKuf.jpg", "tmdb_id": 9380}	c8788f9c89f368319e0c709bd984264d62c454db57b577130436da270c205f38	\N	t	2026-07-19 13:48:58.103163+00	2026-07-19 13:48:58.103164+00	\N	146
20a78f33-2a69-4cb3-929f-01a9e19266c9	5aec146a-7b9b-4390-aaac-984e77fed718	{"name": "Роберт Тейлор", "poster": "https://image.tmdb.org/t/p/w185/wjeEGFarZNyvrqLL4W52eXnAnXe.jpg", "tmdb_id": 39545}	970f75c200d7e66402df3998444a18b6042d46157bd4feecce7f6d0a1202548b	\N	t	2026-07-19 13:48:58.107152+00	2026-07-19 13:48:58.107153+00	\N	146
74bb06d4-498d-4c52-97c7-96efdce0cd70	9dd57732-bf86-4a6e-85f4-2cca1a1da87c	{"name": "Дэвид Астон", "poster": "https://image.tmdb.org/t/p/w185/98TG57IaWdMGBG41NHsUIWtecPX.jpg", "tmdb_id": 9383}	5dbf144e7e445359424b8e4ab21e1ae80b402a9167ff2487ebd62fdd280470a2	\N	t	2026-07-19 13:48:58.110839+00	2026-07-19 13:48:58.11084+00	\N	146
31c07af8-8221-418a-9112-c3d29593d7df	fcbdd077-30e8-4620-b0c9-a08b974cefaa	{"name": "Марк Аден Грей", "poster": "https://image.tmdb.org/t/p/w185/veXu6ByX3OKooI9WBX6dg9U75B5.jpg", "tmdb_id": 9384}	3d706436e5a0e2def45e3717caa7439ee1c7b23a1206d357db1d87232e3105d3	\N	t	2026-07-19 13:48:58.114467+00	2026-07-19 13:48:58.114469+00	\N	146
84f7a7a1-f05a-47cc-9e15-96ff3e941852	751948c6-c045-47b1-aceb-7ced3d525d20	{"name": "Ларри Вачовски", "poster": "https://image.tmdb.org/t/p/w185/4nE4ttPQBuw1virOz0LYT08c1Vm.jpg", "tmdb_id": 9340}	f5335392677fb8fc1c8f901ca4b9b62202ac851b9fdb009d4b18993f589011d8	\N	t	2026-07-19 13:48:58.118118+00	2026-07-19 13:48:58.11812+00	\N	146
01481169-f4ef-46e5-b872-162ee57ec3b4	8324f64b-e6fd-491c-8300-d2f5a0c09201	{"name": "Энди Вачовски", "poster": "https://image.tmdb.org/t/p/w185/rCScAjSpeKA19BLNR07MqNNeeTT.jpg", "tmdb_id": 9339}	ac2a9834110f87437252b7a9d28f6d3ecd66d05aa997cfff4de053739fa4ff4e	\N	t	2026-07-19 13:48:58.121758+00	2026-07-19 13:48:58.12176+00	\N	146
e40a77ba-7a5d-4c3c-83c5-12675403f232	f345eda5-502f-44f7-9c77-f086cb557db2	{"last_name": "Turing", "birth_date": "1912-06-23", "first_name": "Alan", "occupation": "Mathematician", "birth_place": "London, UK", "nationality": "British"}	5d344c44a338acfbd5c51961ba59f33c8c6813c281cfa7532a82fa999b46c570	\N	t	2026-07-18 09:57:23.340288+00	2026-07-18 09:57:23.340288+00	\N	1
f064b82e-8645-4b04-ab5d-45da7ebd66b0	e0000001-0000-0000-0000-000000000002	{"year": 2010, "genre": "Action/Sci-Fi", "title": "Inception", "budget": 160000000, "images": ["https://image.tmdb.org/t/p/w780/edN6Wd9rkNlkrc9KbWYq9ZJTCHq.jpg", "https://image.tmdb.org/t/p/w780/ljsZTbVsrQSqZgWeep2B1QiDKuh.jpg", "https://image.tmdb.org/t/p/w780/9gkR4RMFNDPWthNG4Vz1nMWcKoM.jpg"], "rating": 8.8, "revenue": 839000000, "runtime": 148, "tagline": "Your mind is the scene of the crime", "mpaa_rating": "PG-13"}	hash2	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
79ce59f0-eef7-476e-a41d-fc29d3547e73	394c57ea-7e84-493f-8f9c-71a0cedc8562	{"poster": "http://localhost:9000/dwmb-media/entities/3af7fa9a-477d-40c9-bbd5-b64242435cd7/%D0%93%D1%80%D0%B5%D0%BC%D0%BB%D0%B8%D0%BD%D1%8B.jpeg?AWSAccessKeyId=dwmb_minio&Signature=3OnSx8jT%2BnD3H%2Bp4rc0Ucs36hCA%3D&Expires=1784404611", "тут данные": "тут текст маркдаун"}	f33f79dbdbdee699a7704dbe8d3340f1d313aedbe15b2ecdc2b46f726b76f05b	\N	t	2026-07-18 14:55:53.694157+00	2026-07-18 14:55:53.694161+00	\N	2
86df9e9f-5778-419d-a428-d0dd732b4c17	26b0c3c3-7bcf-42f4-bb74-31a20dd09a9c	{"title": "Доспехи бога", "poster": "http://localhost:9000/dwmb-media/entities/ccfb8bb4-73cc-4269-86aa-88371c4485b6/%D0%94%D0%BE%D1%81%D0%BF%D0%B5%D1%85%D0%B8_%D0%B1%D0%BE%D0%B3%D0%B0.webp?AWSAccessKeyId=dwmb_minio&Signature=V1OyDm030LFx18evpLSXTTjGJ4M%3D&Expires=1784408318"}	0dc69c69a32d92041016a328ed38352ed53f8a93dfa9d2ed160ca66e1fa22f3e	\N	t	2026-07-18 19:58:38.235004+00	2026-07-18 19:58:38.235005+00	\N	1
da59d12c-8c70-47e9-bcdc-c83941106afe	f8dd01e5-b4f2-46e3-9973-62b552dd2f83	{"title": "Золотой.телёнок", "poster": "http://localhost:9000/dwmb-media/entities/24a3b922-3ba0-4077-b0db-6eea4d22beca/%D0%97%D0%BE%D0%BB%D0%BE%D1%82%D0%BE%D0%B9.%D1%82%D0%B5%D0%BB%D1%91%D0%BD%D0%BE%D0%BA.webp?AWSAccessKeyId=dwmb_minio&Signature=x9ceVcNemkDuXU8seLGSvFkoQjk%3D&Expires=1784408214"}	1735469ec98e5d1899f201fafa4b6ad6a55a82257044ef1f73786415ffc537f3	\N	t	2026-07-18 19:56:54.501773+00	2026-07-18 19:56:54.501775+00	\N	1
71460ca4-4404-4b2e-a2a9-245383dcc35d	d9cf88f8-0597-4ce3-a92d-63cc1465e370	{"name": "Neo", "tmdb_id": "603", "character_of": "Киану Ривз"}	10d809eda9fb1b7856265a9444069d49380b9faa63d4c60ea322faebdae7f8e4	\N	t	2026-07-19 18:56:27.73373+00	2026-07-19 18:56:27.733731+00	\N	154
c4524aa8-0fc8-4f2e-bc79-26785b8745c3	97921b0b-4188-45ca-ae5f-f927e7b6def0	{"name": "Morpheus", "tmdb_id": "603", "character_of": "Лоренс Фишбёрн"}	6edfefc8f1be993615e0414a1a9983083d452189a25c3344c42c3ea4082a8520	\N	t	2026-07-19 18:56:27.74246+00	2026-07-19 18:56:27.742461+00	\N	154
67f151e0-b452-43fe-a857-bda6c6ab67de	ceff0138-d38a-4abb-9cec-e7d7dbef171c	{"name": "Trinity", "tmdb_id": "603", "character_of": "Кэрри-Энн Мосс"}	766e497aaeebb18aee4e56c412b61837f3c4bbc1580fdc0f0e9d40b09538b4a9	\N	t	2026-07-19 18:56:27.749237+00	2026-07-19 18:56:27.749238+00	\N	154
1deed027-bdfb-450d-a1de-abbc08673ee6	d2fbd49c-b31e-4da0-8d1f-3195197ff396	{"name": "Agent Smith", "tmdb_id": "603", "character_of": "Хьюго Уивинг"}	14687ae71bd26175bbcf145be12d0fdeddabf2ce51f760210091ee9be06dc973	\N	t	2026-07-19 18:56:27.755719+00	2026-07-19 18:56:27.75572+00	\N	154
2cb73a92-7629-429e-ac40-24bcfa71f74f	5020c846-3bde-4aba-8ce7-fef4bc15b075	{"name": "Oracle", "tmdb_id": "603", "character_of": "Глория Фостер"}	4c67d41d49996400a9c103b6fe5ce0f55b39518f0d08d672afe1c3a7b0bbf72b	\N	t	2026-07-19 18:56:27.761923+00	2026-07-19 18:56:27.761924+00	\N	154
0ccbdd85-7750-47c1-916d-34d52e3b2160	5257a443-20b5-4331-825a-d8fb1f43eb37	{"name": "Cypher", "tmdb_id": "603", "character_of": "Джо Пантолиано"}	26293872391f7eea7e927b5a889bd33d66ce78268bfd9455e2dd974debd7906c	\N	t	2026-07-19 18:56:27.768586+00	2026-07-19 18:56:27.768587+00	\N	154
8cad2298-b173-412e-aa35-640bd3ae12b0	977c75f1-743e-40b6-b308-a93c0e2ff195	{"name": "Tank", "tmdb_id": "603", "character_of": "Маркус Чонг"}	4e44b57e517389234a0acc866b67d1ffae1d7d3be73de74bebbea067ab3ae039	\N	t	2026-07-19 18:56:27.774553+00	2026-07-19 18:56:27.774554+00	\N	154
64523b7d-47f6-40cd-bf6c-0da31943b16e	2f4c6d3c-bbc2-461b-8088-1a14c0b018ab	{"name": "Apoc", "tmdb_id": "603", "character_of": "Джулиан Араханга"}	d790a61217c3c6e5bce347f98e46a24ba041f4f17b13cfc516b4abad24d349d0	\N	t	2026-07-19 18:56:27.780327+00	2026-07-19 18:56:27.780328+00	\N	154
a21ecc2e-feb9-447f-9ebd-7c376ce109a1	c1b51ade-a25a-4e04-a8da-2773d699b48e	{"name": "Mouse", "tmdb_id": "603", "character_of": "Мэтт Доран"}	683798bac47c457ffe279a3582df275cb0dbc00fca93e6a8f9966814de9e9adc	\N	t	2026-07-19 18:56:27.786472+00	2026-07-19 18:56:27.786473+00	\N	154
7360be08-cbe9-46b8-b310-4d5e07900099	b7061ee7-f373-4b43-b56d-cab2f9dcb895	{"name": "Switch", "tmdb_id": "603", "character_of": "Белинда МакКлори"}	1e2ff720ec683d9ae27197820a8e88e68ee9db44e918ae5dfa6e35aeac03fd67	\N	t	2026-07-19 18:56:27.792288+00	2026-07-19 18:56:27.792289+00	\N	154
ee4f6292-ccec-433d-9c5e-56dbe6963ef2	0c8d8a8e-2521-4dfc-a392-9084a8498230	{"name": "Dozer", "tmdb_id": "603", "character_of": "Энтони Рэй Паркер"}	772de389844cf766cca44d7b9dd20c5ae5a9d77497fe49f5617a7893ead96a9f	\N	t	2026-07-19 18:56:27.798078+00	2026-07-19 18:56:27.798079+00	\N	154
32fa91f4-7472-4fb6-9475-89146a0a64ae	19c13cdf-67f8-453a-b68b-b3526271bcc4	{"title": "Тяжелый.Металл", "poster": "http://localhost:9000/dwmb-media/entities/8877988a-cc00-4360-902c-b9236ef36f1c/%D0%A2%D1%8F%D0%B6%D0%B5%D0%BB%D1%8B%D0%B9.%D0%9C%D0%B5%D1%82%D0%B0%D0%BB%D0%BB.jpeg?AWSAccessKeyId=dwmb_minio&Signature=zJwiI49QEJ2IzT2WxOCEp3J5ocw%3D&Expires=1784408318"}	c8a0dcfb5f9163495af5fcaf5770fed6ff3bab0d6d5ca5adb6511201d59cc566	\N	t	2026-07-18 19:58:38.300769+00	2026-07-18 19:58:38.300772+00	\N	1
9e0b7ec3-fd3f-45dd-82a8-23c3a88ac4cc	ebbbff84-c895-41f5-ae0b-1bebe8e217aa	{"title": "Taxi", "poster": "http://localhost:9000/dwmb-media/entities/5ceefbba-b512-467e-9bbb-2f8a537bd2b9/Taxi.jpg?AWSAccessKeyId=dwmb_minio&Signature=3lP%2BYQ5Eh%2BWLvKL1C%2BmLAtjarmk%3D&Expires=1784408318"}	71ae82bbe382c8805a4b47716ec18e1622ca78ff580db77ab445046caa7dcf7f	\N	t	2026-07-18 19:58:38.359164+00	2026-07-18 19:58:38.359166+00	\N	1
98bd9602-1a13-4680-aa6f-9c4ff80f5d07	e102ba10-6052-48bb-a7e1-c624a3ccd485	{"title": "3840x", "poster": "http://localhost:9000/dwmb-media/entities/64a2dfe2-ea09-492c-8302-3e0c92e24c8d/3840x.webp?AWSAccessKeyId=dwmb_minio&Signature=o6OWzdpeVA6%2B1asbgtHnaJFXXeQ%3D&Expires=1784408745"}	dc50c3dd8c892430b308de68020065953c4bc8a4470e63c8303ee10359f51bd5	\N	t	2026-07-18 20:05:45.278111+00	2026-07-18 20:05:45.278113+00	\N	1
826b4e9b-78dc-4a6d-bbb5-4acba82a399b	f9989eb6-17c9-453a-8e19-606cb2e54766	{"title": "Не.бойся,.я.с.тобой.(1981)", "poster": "http://localhost:9000/dwmb-media/entities/8f5afa8d-d5cf-41b8-9330-7794bdfa761e/%D0%9D%D0%B5.%D0%B1%D0%BE%D0%B9%D1%81%D1%8F%2C.%D1%8F.%D1%81.%D1%82%D0%BE%D0%B1%D0%BE%D0%B9.%281981%29.webp?AWSAccessKeyId=dwmb_minio&Signature=39Re8aPdwY3p7iM9JUHMwiaDveY%3D&Expires=1784408745"}	634cc8c8fa53b6f284b5da089b2782a446e0099f95996ecec085a176e0640977	\N	t	2026-07-18 20:05:45.237128+00	2026-07-18 20:05:45.237131+00	\N	1
2ac9fa91-c7b3-439e-a580-043fcd5250be	13b8e6df-c5c4-43d8-ac0d-a08220eabed8	{"name": "Rhineheart", "tmdb_id": "603", "character_of": "Дэвид Астон"}	e7ed533b1584d73b447cce706f7bb97ecc38e74ff34af08c522347e8f0fe5598	\N	t	2026-07-19 18:56:27.816092+00	2026-07-19 18:56:27.816094+00	\N	154
c95c2b84-dd61-46d3-b123-59ecb5e268ea	5b94ada5-9d41-4c0c-be33-534db9b41ec0	{"name": "Choi", "tmdb_id": "603", "character_of": "Марк Аден Грей"}	57242cbd858c753ab45d29cf16b3365350b7f8e35035bb6f23765583c36a0b76	\N	t	2026-07-19 18:56:27.823412+00	2026-07-19 18:56:27.823413+00	\N	154
b1a5fe7f-9682-468e-bfe3-6e52688f353c	30eb75f8-d8d0-4524-b3e2-138db4604559	{"name": "Shrek (voice)", "tmdb_id": "809", "character_of": "Майк Майерс"}	867c844f741cb6e51611aac378c8a3210b4e722a8721c650e05583384968c08d	\N	t	2026-07-19 18:59:48.50863+00	2026-07-19 18:59:48.508632+00	\N	155
86ba620f-dc71-4bdc-92de-2e1e80ab3c41	db332f76-589d-4e7b-9864-eab3571ef0e4	{"name": "Donkey (voice)", "tmdb_id": "809", "character_of": "Эдди Мёрфи"}	939aa4f2cecb9c39b0c52b1a4deecf93a9349949711250b7c80665d5dec30f36	\N	t	2026-07-19 18:59:48.516289+00	2026-07-19 18:59:48.51629+00	\N	155
e4889e32-a517-4b51-8683-eeeedb345b65	5c33b912-a978-47b0-b9d8-4ad469c810c9	{"name": "Princess Fiona (voice)", "tmdb_id": "809", "character_of": "Кэмерон Диас"}	d46029e7c0bea9ee40e4bba2fcfa50106d1260d7c862e4ae8c357a64b4f0db10	\N	t	2026-07-19 18:59:48.523218+00	2026-07-19 18:59:48.523219+00	\N	155
2536fdbb-d26c-4767-99a0-a2110230562c	02eb93b4-c73e-4c96-a701-111808e28ab8	{"name": "Queen Lillian (voice)", "tmdb_id": "809", "character_of": "Джули Эндрюс"}	fc89bb3c8d9b263940af91f35aa4464ba0a2d8892637294221c1288b52e01353	\N	t	2026-07-19 18:59:48.53309+00	2026-07-19 18:59:48.533091+00	\N	155
4d10ee9d-9891-40c6-aeb7-45c486f0f0d6	6fe6d5c2-0a4e-4bf0-9481-74f6339d16f8	{"name": "Puss in Boots (voice)", "tmdb_id": "809", "character_of": "Антонио Бандерас"}	32bc7ccea7e7de25a514edb468846c8a51938bee1f8e1379dd844db07d292859	\N	t	2026-07-19 18:59:48.540056+00	2026-07-19 18:59:48.540057+00	\N	155
4ae6678f-c3df-42f4-af1a-4f60f5f4bf42	2e9ef9fc-59b4-42a6-b119-21f68cf0efb9	{"name": "King Harold (voice)", "tmdb_id": "809", "character_of": "Джон Клиз"}	dba5763177594d563de89b4c41fd819bae1198fe93d19cb64254de6dd6295f25	\N	t	2026-07-19 18:59:48.546895+00	2026-07-19 18:59:48.546896+00	\N	155
18640b49-380e-430c-89d7-2ffee554dd1f	180c5397-e1f2-4dfc-8803-f0f524667761	{"name": "Prince Charming (voice)", "tmdb_id": "809", "character_of": "Руперт Эверетт"}	44326234db97c0c20367b66a6c6c8fe0529e80742b178f87e6cf5d3ded5a8b85	\N	t	2026-07-19 18:59:48.553617+00	2026-07-19 18:59:48.553618+00	\N	155
e356bd82-c139-4904-9ea9-af2f3c7ddbd5	8c065b5a-60ef-4585-b272-cb021f7c264d	{"name": "Fairy Godmother (voice)", "tmdb_id": "809", "character_of": "Дженнифер Сондерс"}	d07bc582e52d5cd29cf54baf8d49d548cbe117e6e37436d99770298da683716f	\N	t	2026-07-19 18:59:48.560741+00	2026-07-19 18:59:48.560742+00	\N	155
12ceace7-ec11-401b-a4e4-91c91f7f2b57	6630f199-08f3-4bb0-bc09-8e1ae0ca884d	{"name": "Wolf (voice)", "tmdb_id": "809", "character_of": "Арон Уорнер"}	c2fbdc3db50e2688c59c935e1fc6497d65865fb47e36bd8cd3f5a67a90ea8c3e	\N	t	2026-07-19 18:59:48.567826+00	2026-07-19 18:59:48.567827+00	\N	155
6e24416f-4b58-4301-9484-6f480de09480	c2f0c449-e228-4cfa-a2ac-0425aa4ad10c	{"name": "Page / Elf / Nobleman / Nobleman's Son (voice)", "tmdb_id": "809", "character_of": "Келли Эсбёри"}	206f2904a75e019fc7c69c0d2b8ef9e7346b1c804306609d362fed62844e8212	\N	t	2026-07-19 18:59:48.575129+00	2026-07-19 18:59:48.57513+00	\N	155
2130d860-72d8-4a76-9911-3043ecebec88	b7bd9346-0a67-44aa-9d22-0f0fff577c70	{"name": "Pinocchio / Three Pigs (voice)", "tmdb_id": "809", "character_of": "Коуди Камерон"}	1f582a88424ee3b65b54011e9a6d3e3121a134f95cff6f8c9e6f4c9cd98d9c7d	\N	t	2026-07-19 18:59:48.581418+00	2026-07-19 18:59:48.581419+00	\N	155
5433b7da-408e-45d6-9dc1-0906c667f052	97b40ffe-2d44-4260-a644-7ce53b3519f0	{"name": "Gingerbread Man / Cedric / Announcer / Muffin Man / Mongo (voice)", "tmdb_id": "809", "character_of": "Конрад Вернон"}	9bed6aa472a2fe990e92da895c36e2804a6c5395b7ec2cb19bdb1ae8baeb433c	\N	t	2026-07-19 18:59:48.588229+00	2026-07-19 18:59:48.58823+00	\N	155
abfed66b-51a6-4743-b67d-150dae1dd0c9	1ba5945b-a622-4164-b2a7-116a9db35201	{"name": "Blind Mouse (voice)", "tmdb_id": "809", "character_of": "Кристофер Найтс"}	a23f4b19684216b955e0ef0ec343a70f6de67df65ec4b2cccf1ffd06bf8cc9cb	\N	t	2026-07-19 18:59:48.594398+00	2026-07-19 18:59:48.594399+00	\N	155
bdd719ab-362a-4c93-9dda-16e0936a1e17	70cfc28d-d4b3-461a-9137-9764c3f8344c	{"title": "призрак в доспехах", "poster": "http://localhost:9000/dwmb-media/entities/e2c3c575-32e2-4e12-83da-f0bfb086ef24/%D0%BF%D1%80%D0%B8%D0%B7%D1%80%D0%B0%D0%BA_%D0%B2_%D0%B4%D0%BE%D1%81%D0%BF%D0%B5%D1%85%D0%B0%D1%85.jpg?AWSAccessKeyId=dwmb_minio&Signature=56Gv7iC%2FLv9vP6Ztp7%2FdGFs008g%3D&Expires=1784409544"}	69e29a4cd3faf170e83fd737fbff8af572c97024bf1c7523823493a762b1523d	\N	t	2026-07-18 20:19:04.995872+00	2026-07-18 20:19:04.995875+00	\N	1
6937c81e-5bce-4156-a2f7-02412e43fd1e	13a57abd-ff73-4536-bf0e-a14cb8c7e0f7	{"name": "Herald / Man with Box (voice)", "tmdb_id": "809", "character_of": "Дэвид П. Смит"}	6c1af05c0a512781ab9e71f1c14444c7b22eb85ebfb924aa8cab0422e69af661	\N	t	2026-07-19 18:59:48.601057+00	2026-07-19 18:59:48.601058+00	\N	155
dcb74548-ef01-40a2-b072-287e74e7e6bd	fc37ff77-e9cd-4411-95e2-f48e05c3d6ef	{"name": "Mirror / Dresser (voice)", "tmdb_id": "809", "character_of": "Mark Moseley"}	c3d4053230d101fcf267f3b64ece5140fc5b432c5a71fea7f1c9b52c83936c7f	\N	t	2026-07-19 18:59:48.607571+00	2026-07-19 18:59:48.607572+00	\N	155
1d2f6157-f718-4095-887f-92e073737f79	60d5c463-28ba-436f-acae-bc99641e43a2	{"title": "futurama", "poster": "http://localhost:9000/dwmb-media/entities/4cb4bd5c-599a-4a8f-bfa0-44f2b5ff4ac8/futurama.jpg?AWSAccessKeyId=dwmb_minio&Signature=Z2X15AEZqsUzyLb71Q5uGd54cAM%3D&Expires=1784409779"}	7f6d127e6e4fec427f163e24c692cbc21ba97441ff4aa7764e8c607e65570912	\N	t	2026-07-18 20:22:59.461995+00	2026-07-18 20:22:59.461998+00	\N	1
066260c7-cfe1-468a-8fff-9fce3aab5a1f	af8499a8-5fe9-4d0f-96a9-537c15fc2b81	{"name": "Shrek / Blind Mouse (voice)", "tmdb_id": "808", "character_of": "Майк Майерс"}	7761c20da726388ca3d3d1181d656c4eb1de2bf1af7c3d5dbcc54537b0afa296	\N	t	2026-07-19 19:00:09.524783+00	2026-07-19 19:00:09.524786+00	\N	156
1d52e339-7780-42ba-b15b-47f2af96af0a	37ba971e-2a02-43ee-937b-295df2b89dbb	{"name": "Donkey (voice)", "tmdb_id": "808", "character_of": "Эдди Мёрфи"}	13ae2653c9ff731cac193cf41660d6b96e49efdbd7154d23da987d3a1a0a507c	\N	t	2026-07-19 19:00:09.533077+00	2026-07-19 19:00:09.533078+00	\N	156
05a43164-80d2-42de-b8e7-2882095f8515	5af53614-0b0b-4410-9215-7368eb07e348	{"name": "Princess Fiona (voice)", "tmdb_id": "808", "character_of": "Кэмерон Диас"}	3d2f1ae20d73f94b312dde5bddd267240295ac7c44391e7e6ec8290bf287dd9a	\N	t	2026-07-19 19:00:09.53976+00	2026-07-19 19:00:09.539762+00	\N	156
a7d98a9a-6163-4c72-9a5d-371d7dcc884c	41e3ebb7-7e87-420b-a048-2ddb0802cced	{"name": "Lord Farquaad (voice)", "tmdb_id": "808", "character_of": "Джон Литгоу"}	6e0770d21c94ea41670a1d5eda3eb6a8746e9148a9bf64cef30dd89fab64887a	\N	t	2026-07-19 19:00:09.546143+00	2026-07-19 19:00:09.546144+00	\N	156
3c970d04-0f4c-4bdf-8949-c4ab0dd784a7	54a1bc1b-9f2a-407b-a101-a38a7b6f64e1	{"name": "Monsieur Hood (voice)", "tmdb_id": "808", "character_of": "Венсан Кассель"}	3b5b42b1cb886f5d5aeae4863e3601f0e7df5b9229dceb723d1a4091061d4a7c	\N	t	2026-07-19 19:00:09.552283+00	2026-07-19 19:00:09.552284+00	\N	156
2bcb8731-70d7-4a26-b8e8-eb816b5ac3c3	0a4812b1-25fb-4722-ba1c-299ba936f018	{"name": "Ogre Hunter (voice)", "tmdb_id": "808", "character_of": "Питер Деннис"}	d0b01f58d7906a0faa488e8277a25ba2c6013a94ebde49dbc38fdc7b1e37e586	\N	t	2026-07-19 19:00:09.559848+00	2026-07-19 19:00:09.55985+00	\N	156
61a0de01-133e-4556-9acc-9c1c542c238f	bf8f9398-aeee-469d-ba79-7a3013a9663c	{"name": "Ogre Hunter (voice)", "tmdb_id": "808", "character_of": "Клайв Пирс"}	d0b01f58d7906a0faa488e8277a25ba2c6013a94ebde49dbc38fdc7b1e37e586	\N	t	2026-07-19 19:00:09.569161+00	2026-07-19 19:00:09.569162+00	\N	156
a3f9d454-cbe5-48b8-87e1-88bb5cbe29d6	73a692e5-1287-4cf1-836b-4505963848c6	{"name": "Captain of the Guards (voice)", "tmdb_id": "808", "character_of": "Джим Каммингс"}	c851dfa7e71b9d33c4f0384829b11d1dbaf3275bc35eb476c14e8ae7c8385ff1	\N	t	2026-07-19 19:00:09.576199+00	2026-07-19 19:00:09.576201+00	\N	156
09a5dc44-aef1-4f59-b55f-f8ae3487cd74	c361e975-ebce-456e-b13c-c8171b27c183	{"name": "Baby Bear (voice)", "tmdb_id": "808", "character_of": "Бобби Блок"}	accd1791b895506ce3d7adb62352536560c5fed652c40b6706c32759f16ebc3a	\N	t	2026-07-19 19:00:09.582138+00	2026-07-19 19:00:09.582139+00	\N	156
671a4f44-347b-44d4-ae47-5c2d88f35a61	b35b2264-99b7-4692-b71a-52a3b6400344	{"name": "Geppetto / Magic Mirror (voice)", "tmdb_id": "808", "character_of": "Крис Миллер"}	85b5eed65cd20a85ebb1bea33d1adcac60f1f9baa8a5ba98e8752bbf321144b5	\N	t	2026-07-19 19:00:09.588048+00	2026-07-19 19:00:09.588049+00	\N	156
33089bba-b07b-41e3-b08f-0b4d163d8dd4	8ac53ce1-018f-4f39-957f-52aaed4554a2	{"name": "Pinnochio / Three Pigs (voice)", "tmdb_id": "808", "character_of": "Коуди Камерон"}	b986fb5fe07adef51739203749326fff64c6505f6061323743d3c2db1e5dbd90	\N	t	2026-07-19 19:00:09.593982+00	2026-07-19 19:00:09.593983+00	\N	156
dd7a6de3-3b87-4604-a194-f9e8883e48c9	3c8a53a8-ce96-4362-b48a-7656a9bc4f5c	{"name": "Old Woman  (voice)", "tmdb_id": "808", "character_of": "Кэтлин Фримен"}	4233825a3a5854eb1cf799ca17df18ff60165525314bc942a3c2f9b8ecd023ae	\N	t	2026-07-19 19:00:09.599925+00	2026-07-19 19:00:09.599926+00	\N	156
86f45584-496a-4de6-b839-bf14e5644301	2a8c0373-d4ab-4644-a92b-c91c7d6d93dd	{"name": "Peter Pan (voice)", "tmdb_id": "808", "character_of": "Michael Galasso"}	c527915b4484705a019420d4e93fd099ba80a7676bb26afe049cdb5048b40329	\N	t	2026-07-19 19:00:09.605285+00	2026-07-19 19:00:09.605286+00	\N	156
88e8c8e4-70e8-4afb-a5ce-1a4ab93a6747	9f22f322-665a-4f02-9902-803885828421	{"name": "Blind Mouse / Thelonious (voice)", "tmdb_id": "808", "character_of": "Кристофер Найтс"}	9d783844627eb72a122267262d7bb81188f0f590a33816338122298ea681eae0	\N	t	2026-07-19 19:00:09.611225+00	2026-07-19 19:00:09.611227+00	\N	156
302434e1-37e4-4539-b8be-0e50aac2a190	fcfd7d95-f4ee-4ea1-bbf6-a0120209771c	{"name": "Blind Mouse (voice)", "tmdb_id": "808", "character_of": "Саймон Дж. Смит"}	bc84980aafd436dca284dea5fa98d67d3cff63461d03b2eac664db6f4eed4a88	\N	t	2026-07-19 19:00:09.617941+00	2026-07-19 19:00:09.617942+00	\N	156
fe0c8ab8-5fcd-4e85-8414-564d14a2df63	0bc444bd-8e8c-4528-856d-c62ede688596	{"is_active": true, "kind_code": "character", "model_code": "cinema", "description": "Персонаж фильма", "template_code": "charaster_cinema", "template_name": "Шаблон: Персонаж"}	d7e8d519c73d98e167958b88e5b10c366f47bcf09e994c9541f275909f60ffbe	\N	t	2026-07-19 19:05:43.799151+00	2026-07-19 19:05:43.799152+00	\N	4
cf6bd44d-1d43-46ef-a826-928b1bffbb35	d22f2ed3-803a-41d9-b9b8-529945ebc076	{"name": "Agent Brown", "poster": "", "tmdb_id": "603", "character_of": "Пол Годдард"}	85fc5d6f46d1ee3319bd79164c4911185ee687b53b43c660f67cbff989aa2536	\N	t	2026-07-19 19:18:06.197049+00	2026-07-19 19:18:06.197054+00	\N	157
50cb495d-6514-44e6-9822-3dd7bf774e54	b29803f0-f257-4530-9c9c-de1ad01ea561	{"name": "", "poster": "", "tmdb_id": "", "character_of": ""}	e918c9914d698ece5cb22f3d773a4835f6ba7bef79817b7f5f5a8c3634aa6802	\N	t	2026-07-19 19:43:42.304545+00	2026-07-19 19:43:42.304546+00	\N	157
e400f004-0202-41bd-b2bd-c80cdfb5e702	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	{"year": 2016, "genre": "мультфильм, приключения, семейный, комедия", "title": "Зверополис", "budget": "150.0M", "images": "", "poster": "https://image.tmdb.org/t/p/w500/5qcww3ZqlpCqPrUessuFkdwsDL2.jpg", "rating": 7.765, "content": "", "country": "United States of America", "imdb_id": "tt2948356", "tagline": "«Добро пожаловать в городские джунгли»", "tmdb_id": "269149", "director": "Байрон Ховард", "duration": "109 мин", "language": "English", "age_rating": "", "description": "Добро пожаловать в Зверополис - современный город, населённый самыми разными животными, от огромных слонов до крошечных мышек. В город приезжает новый офицер полиции, крольчиха Джуди Хоппс, которая с 1-ых дней работы понимает, как сложно быть маленькой и пушистой среди больших и сильных полицейских. Судьба сводит её с хитроватым, но обаятельным лисом Ником Уайлдом. Вместе они берутся за расследование загадочного дела о пропавших животных, которое оказывается гораздо масштабнее и опаснее, чем казалось сначала.", "production_company": "Walt Disney Animation Studios"}	10abc4c574378637c7acea1164f2ab866338c6295b22bb64f327149874913ca3	\N	t	2026-07-19 12:53:24.176528+00	2026-07-19 12:53:24.17653+00	\N	145
63c4b7b9-949e-45fd-9e7c-e2edaefb85ac	9b4b190b-7734-443e-b3e0-3900b78219d5	{"poster": "https://image.tmdb.org/t/p/w185/n8XOnjgyfYvqRUDcnkAckRqSaNN.jpg", "tmdb_id": "417"}	6967647908c365fbf5522f020b72298d9543ba15439ace738be2bb447205ec62	\N	t	2026-07-19 19:48:41.50358+00	2026-07-19 19:48:41.503583+00	\N	157
55bcc5c4-48ec-4d20-b6f3-39191cd677ff	da161a64-29c2-4aab-9a82-39052d22ffa1	{"name": "Judy Hopps (voice)", "tmdb_id": "269149", "character_of": "Джиннифер Гудвин"}	f7e8e7b8e795df429c452d5560c7e3e44c36722ecfdda648dbb71d835b37ff8c	\N	t	2026-07-19 19:48:41.514661+00	2026-07-19 19:48:41.514662+00	\N	157
b2594f17-5f09-4988-925e-3e392f079ba1	92fb377c-ac7f-4c80-9678-270ec3e66f88	{"poster": "https://image.tmdb.org/t/p/w185/wS22fofYtUf4aGXACFwhkTjUk6a.jpg", "tmdb_id": "23532"}	9e11f18955b904872eef66fc62ea2eb9eb049af84b5c2ed9fab0191d3ea88b17	\N	t	2026-07-19 19:48:41.520032+00	2026-07-19 19:48:41.520033+00	\N	157
47ab08cb-e5a7-43e8-af10-8a4ad450d86f	b4be05d9-ff7d-453f-8c20-dabc50c1076b	{"name": "Nick Wilde (voice)", "tmdb_id": "269149", "character_of": "Джейсон Бейтман"}	65630f7d4e84cb5abe4c49a485c9a1a126067b55c5310c26a8287bc2045291e7	\N	t	2026-07-19 19:48:41.523398+00	2026-07-19 19:48:41.523399+00	\N	157
812154df-0cb4-49f4-9c80-7f54afe2fa3f	7bf3a464-0efd-46e7-89f3-0b93fc8cbfec	{"poster": "https://image.tmdb.org/t/p/w185/be1bVF7qGX91a6c5WeRPs5pKXln.jpg", "tmdb_id": "17605"}	f6f5194d020872547216b2d9fd9e83a968102eab13b296a88ca40ce657c3621f	\N	t	2026-07-19 19:48:41.527891+00	2026-07-19 19:48:41.527891+00	\N	157
5e8d4def-ddfe-4e94-afc8-0f79e9355121	ac4fd994-cd7f-4210-ad16-3f6ddcc04dfb	{"name": "Chief Bogo (voice)", "tmdb_id": "269149", "character_of": "Идрис Эльба"}	44cbdf72feccaa254524457a3708035fd03993055a48a74c83de555abcffa5cc	\N	t	2026-07-19 19:48:41.532105+00	2026-07-19 19:48:41.532106+00	\N	157
2385e0e7-5849-4f06-a986-b7c7cc72aa48	e1141415-42c8-4e7e-ad71-8a9d7949af2b	{"poster": "https://image.tmdb.org/t/p/w185/iNpXig5Djkh5moYG4TCekIATs5B.jpg", "tmdb_id": "213001"}	7bb5b8b0f0cf6d370b5726acdf05973b4965dd864c9b1f97b02dafd4feac2321	\N	t	2026-07-19 19:48:41.536615+00	2026-07-19 19:48:41.536616+00	\N	157
fefd6333-2d5d-4f6d-90b1-121d5b422b0a	64557dc0-c440-49ae-830d-1fb7b8bc7cd4	{"name": "Bellwether (voice)", "tmdb_id": "269149", "character_of": "Дженни Слейт"}	1e7c18b0db60fac7f7c10c52ba9e75cb116f4c35a54f3e2fee47ea575b239da7	\N	t	2026-07-19 19:48:41.539936+00	2026-07-19 19:48:41.539937+00	\N	157
d1fb5cea-43e6-47a6-a006-eefb379c94f2	8c2e35b8-9457-423b-8107-ff861a32ada8	{"poster": "https://image.tmdb.org/t/p/w185/yT9o149xPygdY0NsF9sNgiQwuru.jpg", "tmdb_id": "41565"}	79562bfff32d050c917aa93a040e7806c88b0554e29419440da10350febf1c93	\N	t	2026-07-19 19:48:41.54529+00	2026-07-19 19:48:41.545291+00	\N	157
68e00c29-02e7-43d0-abfd-7dc7193acf63	7991833c-a5a2-47f2-810e-577ca04f19ab	{"name": "Clawhauser (voice)", "tmdb_id": "269149", "character_of": "Нэйт Торренс"}	26c917996e689fe5b7165218abb7a3b611059fbe293981ba0739c6f8d22e6c06	\N	t	2026-07-19 19:48:41.548948+00	2026-07-19 19:48:41.548949+00	\N	157
0b757218-e414-4d79-b895-8d8a8887e6c2	264ef215-8f96-4cba-a23c-5be136094a44	{"poster": "https://image.tmdb.org/t/p/w185/tT9C6uLztgN8OxJULq6F9iEzqlA.jpg", "tmdb_id": "5149"}	e885870eb1c2475734d85e120a4bdc6b56774c0dc290a5555d0afc67ea2712eb	\N	t	2026-07-19 19:48:41.55368+00	2026-07-19 19:48:41.553681+00	\N	157
ba8228e6-7f3f-478e-9ff4-f67dcc6dfde3	8009dcc2-8de4-4cb1-b19c-9a730c66be8e	{"name": "Bonnie Hopps (voice)", "tmdb_id": "269149", "character_of": "Бонни Хант"}	5f8c11d6d370a68a2db164b218e092028d5eede4430ca9c87845b4e5de8fe5ba	\N	t	2026-07-19 19:48:41.557145+00	2026-07-19 19:48:41.557146+00	\N	157
75bdf09e-1dcc-4cdb-b6c3-2b0d099b45cf	62a456b7-2791-4c6b-9e6e-d4bd41360679	{"poster": "https://image.tmdb.org/t/p/w185/zVcMF2Jtv1W3mvzYDE3JiFfw2PG.jpg", "tmdb_id": "27530"}	6ca287dd2f3f88d307fe84e7a78658721c8e177f51502420ae0078be394b27f0	\N	t	2026-07-19 19:48:41.561815+00	2026-07-19 19:48:41.561816+00	\N	157
6efb9a42-3fff-401e-adaa-db46517b9910	914f7b6a-c092-4a86-a316-f3540f598cc3	{"name": "Stu Hopps (voice)", "tmdb_id": "269149", "character_of": "Дон Лейк"}	36b5e294a7f4a4015443a3d2ec0cc7cf72922cb1bc0d37ca106e7554810fb827	\N	t	2026-07-19 19:48:41.56515+00	2026-07-19 19:48:41.565151+00	\N	157
24de5b41-ad7e-4280-bf8e-87f828c523db	af267160-e15e-4b14-a47f-48ab7b959736	{"poster": "https://image.tmdb.org/t/p/w185/4jCJpbssCSGc5jhmrBMoGvWNQDf.jpg", "tmdb_id": "63208"}	1529395640282ffb4c759eed76e6a7b3116d20c3dd8f8b5cc0b6bd882d4d9d9b	\N	t	2026-07-19 19:48:41.569832+00	2026-07-19 19:48:41.569833+00	\N	157
a69080a3-c739-4e32-b463-402985972888	54ab11f2-cc7f-4ec9-8fdf-3a5b1cfa49ce	{"name": "Yax (voice)", "tmdb_id": "269149", "character_of": "Томми Чонг"}	ea87d1f035700026f47ebe7b1794aafe3b1b9bf330f60f32d57fe41101857ad1	\N	t	2026-07-19 19:48:41.573216+00	2026-07-19 19:48:41.573217+00	\N	157
3c86132a-4e2c-48ee-acf7-2386a91f8de2	c458c1e4-f199-495a-bdc4-562391032b77	{"poster": "https://image.tmdb.org/t/p/w185/ScmKoJ9eiSUOthAt1PDNLi8Fkw.jpg", "tmdb_id": "18999"}	f9e500f474aeec30fb5589c33ada8bfe3a3f21816fe9f3ac899c7d89b69f730f	\N	t	2026-07-19 19:48:41.577766+00	2026-07-19 19:48:41.577767+00	\N	157
d7cd1b0f-6e85-43fa-8548-4ca95ffebd23	35cd9130-4138-4d44-ab5c-6dd21091016a	{"name": "Mayor Lionheart (voice)", "tmdb_id": "269149", "character_of": "Джей Кей Симмонс"}	f0d5c7a63a506750be050256019b037c716bfab182251a7f7d00a14ad46718a1	\N	t	2026-07-19 19:48:41.581236+00	2026-07-19 19:48:41.581237+00	\N	157
bd6e849a-c6f1-4475-bdf7-4b22c037928e	39e404d1-d653-47ac-ae0b-fc78906edca1	{"poster": "https://image.tmdb.org/t/p/w185/zDGydyM1fmvNWzQlTAns9IZjNxT.jpg", "tmdb_id": "6944"}	e5284c169d57d0997ef4b54b350bdb62e9e6b0a8b6d8534c3b29331879bce73b	\N	t	2026-07-19 19:48:41.585832+00	2026-07-19 19:48:41.585833+00	\N	157
f4848637-6050-4d2c-80c7-7a190d65a80a	74404fe0-601d-40bd-a806-3ccd33c7b253	{"name": "Mrs. Otterton (voice)", "tmdb_id": "269149", "character_of": "Октавия Спенсер"}	9657657c5e2ad59dc9ce77028b11c9d4a2de5ebf7a4c24bb40cab17ff93f7416	\N	t	2026-07-19 19:48:41.589156+00	2026-07-19 19:48:41.589157+00	\N	157
a54a5de8-0f39-4fd1-bd03-ddbff6487530	17596c41-45c8-4194-b5b9-8ad59de8023c	{"poster": "https://image.tmdb.org/t/p/w185/jUuUbPuMGonFT5E2pcs4alfqaCN.jpg", "tmdb_id": "21088"}	a9202f632d39b9fd92bffbb09781da01eef123f5a8a107d54159b4696e89483b	\N	t	2026-07-19 19:48:41.593662+00	2026-07-19 19:48:41.593663+00	\N	157
39d993e2-d819-4a42-afc0-72c58247e0c6	fcb69ad1-6d9e-49ba-bd05-93d6b53ef1f7	{"name": "Duke Weaselton (voice)", "tmdb_id": "269149", "character_of": "Алан Тьюдик"}	73d13a47786eb98a11cf45463defe667fd42f3f8547ba0eb6023eac63fd672b2	\N	t	2026-07-19 19:48:41.596722+00	2026-07-19 19:48:41.596723+00	\N	157
3dc17be1-bd06-4e71-99c0-39f323c5c65f	a06660e0-613e-4ee1-be30-f46394bccacb	{"poster": "https://image.tmdb.org/t/p/w185/AcOA8MbRrDswt6w3TmCBYl7TNOu.jpg", "tmdb_id": "446511"}	a1ad0286abed2589993e9e8397dde830703167df700fdfe4165845ba11d8026b	\N	t	2026-07-19 19:48:41.601396+00	2026-07-19 19:48:41.601398+00	\N	157
a7f468e3-5e8c-411a-a3b0-616d56fd0fa3	1dd7a142-9b0d-47b7-832e-bd03833212a1	{"name": "Gazelle (voice)", "tmdb_id": "269149", "character_of": "Шакира"}	77ca3829dc16aea484bcc052830a1d1719383edff6aef2b59e13a9853d3cf242	\N	t	2026-07-19 19:48:41.604583+00	2026-07-19 19:48:41.604584+00	\N	157
c0ca6b6b-5981-4488-948d-b760072af685	3893ce3f-1cb6-4736-aad0-23de74a265bf	{"poster": "https://image.tmdb.org/t/p/w185/37HnYfTAHhtAmWdl4NlVAOR7vCW.jpg", "tmdb_id": "1223658"}	f2719fc0a8662e788293054b75e75da3eee76d43b185d6d6dde7fea2f75cd432	\N	t	2026-07-19 19:48:41.608743+00	2026-07-19 19:48:41.608744+00	\N	157
94ed54d0-030d-40e2-9be2-273a45b36fbd	1460e1da-0058-4c32-ab21-ad0f0ac86630	{"name": "Flash (voice)", "tmdb_id": "269149", "character_of": "Рэймонд С. Перси"}	cb2d509b305ad91a75678e48c58735f7ff0857e0e691f7010234a859ecf8e496	\N	t	2026-07-19 19:48:41.611946+00	2026-07-19 19:48:41.611947+00	\N	157
3a5256af-5ee2-4866-9edc-9e9f8171036d	d146a201-ff80-48ca-bea8-2d893c6d460b	{"poster": "https://image.tmdb.org/t/p/w185/q2ksier0nLdvKbGUzVmpblgl8NT.jpg", "tmdb_id": "1610446"}	9f2e189c2af938e1e5750e2886a7e5ab10b75fd4ceeadc9e977e4aa75bb9e296	\N	t	2026-07-19 19:48:41.616096+00	2026-07-19 19:48:41.616097+00	\N	157
4ddfc407-d1d8-482a-acf8-05ce1a5eeb0f	502a57b2-0c2c-4671-a64a-f92efbfbbb04	{"name": "Young Hopps (voice)", "tmdb_id": "269149", "character_of": "Della Saba"}	5aa2886a303ac4c6ad00387126d675372eaf1d12e9c942266bf46ebb8714efcd	\N	t	2026-07-19 19:48:41.619136+00	2026-07-19 19:48:41.619137+00	\N	157
439643e7-5faa-449e-99ba-614df94660c8	df2199cc-b9fa-40f9-ba07-a1cd538befcb	{"title": "Test Projections"}	9012848e469bdb1003e3c9aca0dc1ff15547555100165da7dc67c3438fc67a49	\N	t	2026-07-19 07:44:38.175505+00	2026-07-19 07:44:38.175512+00	\N	110
7d96ad64-53a6-4dc8-b4d0-b0f1f09d5da7	f5661936-9491-4aee-84ae-5068eb7128e0	{"poster": "https://image.tmdb.org/t/p/w185/qCiL3EYAhLcNo0rNj5pczWo9MwG.jpg", "tmdb_id": "34521"}	95353ca7173bf68654575bda51448119d435b6bb32acb12eba169b1c8b5b01cf	\N	t	2026-07-19 19:48:41.623266+00	2026-07-19 19:48:41.623267+00	\N	157
afefc8fa-23ec-4543-b9ce-6a781da1432f	91ec158e-f1aa-43ca-93b4-46d9dc975a6d	{"name": "Mr. Big (voice)", "tmdb_id": "269149", "character_of": "Морис Ламарш"}	abf83cf5375b6299378f513822ef16f666add8e76ed29abc029c59355942d071	\N	t	2026-07-19 19:48:41.626323+00	2026-07-19 19:48:41.626324+00	\N	157
379e36cd-883f-453e-8f8e-a309e4530d64	f818e778-d141-461a-827a-fed2c0fca280	{"poster": "https://image.tmdb.org/t/p/w185/ePJXkxrD44nM0VB7Xx9Q4ityzfT.jpg", "tmdb_id": "76595"}	b42af7280b77d38b4891b8c586b71fbf7a80dc6e288e637c10db86231ef3e4e0	\N	t	2026-07-19 19:48:41.630426+00	2026-07-19 19:48:41.630427+00	\N	157
4fcf9206-9b8f-49ee-9663-e74d1d1d5697	0abba340-8d2f-4ed7-9f6b-e6cfe890f527	{"poster": "https://image.tmdb.org/t/p/w185/oIAmkZf9LuJuMqR8zSchoD3FJT8.jpg", "tmdb_id": "165787"}	2cd1161dd8fead0b4a15b2d349a097370e5b67c9871d781a83aae9ff714b59a2	\N	t	2026-07-19 19:48:41.633747+00	2026-07-19 19:48:41.633749+00	\N	157
82e70b12-91c7-4994-862f-20597a161089	0903e6ba-2cb0-467a-90a3-aee018ca93b0	{"domain": "science", "model_code": "science", "description": "Наука", "template_count": 5}	0c767c89f56f5ea42409a8ca24391ed0bb8ba81c9fbd3495f3fab9e548b7d441	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	108
9cd0a658-98df-4a2a-ac3d-79d25828aebb	67c9f624-5a95-4306-bffd-20d073d71275	{"poster": "https://image.tmdb.org/t/p/w185/ap8eEYfBKTLixmVVpRlq4NslDD5.jpg", "tmdb_id": "8891"}	56042297b1bb80bca846fad46080cffbc92b581fede2bb2ef9120d82c639a110	\N	t	2026-07-19 19:59:31.905033+00	2026-07-19 19:59:31.905035+00	\N	158
cf584528-67cd-462c-9c5a-c1e45565aa89	273d5a5e-c088-44ed-a37a-b1526d123c81	{"name": "Vincent Vega", "tmdb_id": "680", "character_of": "Джон Траволта"}	35ed8b4a974ef6a2d3b8e9dc52bf343e90dc841495fcc9dc4a125db7b7c772df	\N	t	2026-07-19 19:59:31.911777+00	2026-07-19 19:59:31.911779+00	\N	158
15dcfea2-ca06-46fa-b3b0-df5118fec99e	f274b66c-aa34-4977-8718-f93a90504eff	{"poster": "https://image.tmdb.org/t/p/w185/qdfRtvPCj51C9Uy5VEgjgj69JyV.jpg", "tmdb_id": "2231"}	52e82e40ed1cae524fbbca8c22c4e9179d823aa14cd0c15ec4731d6476dfec42	\N	t	2026-07-19 19:59:31.91628+00	2026-07-19 19:59:31.916281+00	\N	158
9e14d334-dffb-4155-af1a-9037717b312c	93d6ae16-d715-48ef-ae0a-9c952d301899	{"name": "Jules Winnfield", "tmdb_id": "680", "character_of": "Сэмюэл Л. Джексон"}	2c2b7679e7b1b5b90d8055a2f2125ba44f768199d9a5271ce19183e9cc80a11a	\N	t	2026-07-19 19:59:31.919398+00	2026-07-19 19:59:31.919399+00	\N	158
ef9674a3-ce77-47b7-895f-ec55724dbee7	07c72226-91da-4cce-b159-bbb3fe96af0d	{"poster": "https://image.tmdb.org/t/p/w185/hlYG0MC6im0MHNq1xixxVilfwyR.jpg", "tmdb_id": "139"}	141d3adc2457265aee81bc2a4e55d61c13aa151284f682613bce70574c8dce58	\N	t	2026-07-19 19:59:31.92348+00	2026-07-19 19:59:31.923481+00	\N	158
17f8715b-a14a-456b-bc91-061da4b5deab	af4ee5a7-87f5-41d9-833b-2f427eba1d60	{"name": "Mia Wallace", "tmdb_id": "680", "character_of": "Ума Турман"}	9f6c71eae1ce63d7671e0184585dbe09a8021ce90eaea63c776491ff51e2707e	\N	t	2026-07-19 19:59:31.92648+00	2026-07-19 19:59:31.926481+00	\N	158
e3365844-7ecb-4268-b0b0-089a003b3d52	a80e64cf-6154-4b65-8cc8-49ecb5eefbe3	{"poster": "https://image.tmdb.org/t/p/w185/w3aXr1e7gQCn8MSp1vW4sXHn99P.jpg", "tmdb_id": "62"}	ef7cf3d0606f77629a1a017d8aefdcff17222dbcbec6afd19fd0ed6691f32c97	\N	t	2026-07-19 19:59:31.930573+00	2026-07-19 19:59:31.930574+00	\N	158
3b1e63bc-7ab6-4fac-911e-aa20ddc3c9bc	8b80bc82-fad2-4183-b3c5-236ef2445d8b	{"name": "Butch Coolidge", "tmdb_id": "680", "character_of": "Брюс Уиллис"}	bc68b07ccef1cb97d361cf30b7870b7cd702d472d86bb10d86c29b55ac2d8342	\N	t	2026-07-19 19:59:31.933581+00	2026-07-19 19:59:31.933582+00	\N	158
ca33d656-65f7-4682-a483-38a370a89615	aeff218b-e7a7-4aa3-982c-1db5190eea43	{"poster": "https://image.tmdb.org/t/p/w185/tOVDvu1EQP78AwaUw6uh1wN818E.jpg", "tmdb_id": "10182"}	655f3dcbeb64ed60625acad7d4e2a464fd06ee35bba0044367b20478040e0ffd	\N	t	2026-07-19 19:59:31.937537+00	2026-07-19 19:59:31.937538+00	\N	158
d4e667c2-2ae1-4d97-bf83-62794dc35086	4ed26f91-d573-48d1-bd0b-e81e1700ba1e	{"name": "Marsellus Wallace", "tmdb_id": "680", "character_of": "Винг Реймз"}	45d005300225d8afe04a1841eb38fd1e8b5fbeae6044c7e6eeca8c99848a0696	\N	t	2026-07-19 19:59:31.941122+00	2026-07-19 19:59:31.941123+00	\N	158
9c3e0b3e-5014-4945-8015-01bdb06c310e	3f7b450d-cc20-43e5-afcf-9b2f2ffefa67	{"poster": "https://image.tmdb.org/t/p/w185/7P30hza1neYWW3r7rSQOC736K2Z.jpg", "tmdb_id": "1037"}	77cab564126c727ca9209c5356195f837fa042df5bf24ae4cf54171acc8613fa	\N	t	2026-07-19 19:59:31.945143+00	2026-07-19 19:59:31.945144+00	\N	158
c6a113ad-ffd0-4454-8855-2d3a7fe64250	0368dac9-cff7-482e-bf94-547f63a89d16	{"name": "The Wolf", "tmdb_id": "680", "character_of": "Харви Кейтель"}	dd5aba8ab21559561d961e338ed53bca18bb57aa1d25ea627e69d7aa7b0cbc4f	\N	t	2026-07-19 19:59:31.94813+00	2026-07-19 19:59:31.94813+00	\N	158
720504ae-323d-49da-955e-34ef1596ea80	c9c1bdc9-3797-4400-9f7d-bb9db9735f45	{"poster": "https://image.tmdb.org/t/p/w185/idFuM00MeVmwGAiqvDaJcBiLAmD.jpg", "tmdb_id": "7036"}	ae0db8452405cc5d4b5a93898e8fba326ffb49c8d3aace16585e4703c12c6092	\N	t	2026-07-19 19:59:31.952285+00	2026-07-19 19:59:31.952286+00	\N	158
594fad6c-a742-40b0-9637-6316f8b8f908	3cc77c76-08e4-47cd-986a-92a5d027ed6e	{"name": "Lance", "tmdb_id": "680", "character_of": "Эрик Штольц"}	8cea0b08c54a7ce64bacff65408d1093be497c774d26555bd2bc25d767d07dc5	\N	t	2026-07-19 19:59:31.955396+00	2026-07-19 19:59:31.955397+00	\N	158
7f1a5232-6c10-4855-8f49-716dd42ae53e	9ff87f0f-0980-42b8-b126-c9babc559538	{"poster": "https://image.tmdb.org/t/p/w185/qSizF2i9gz6c6DbAC5RoIq8sVqX.jpg", "tmdb_id": "3129"}	d198f6fa245f6e5099e707f8be17bd70d03625ebd1f1152c2e9944b04bdf2921	\N	t	2026-07-19 19:59:31.959516+00	2026-07-19 19:59:31.959517+00	\N	158
e48e4d65-48bc-4262-83d4-4715c6d684f9	6d7de9d2-72e7-42e2-bdb4-8240914e16c8	{"name": "Pumpkin", "tmdb_id": "680", "character_of": "Тим Рот"}	e2259679437ae188259bc59b22706579b158ee8f672cdc7964410d1b98590447	\N	t	2026-07-19 19:59:31.962526+00	2026-07-19 19:59:31.962528+00	\N	158
fa734310-c4dc-4ecc-ac7c-6193c6493248	f09b19fd-2f9c-4978-862b-6dba4039f12f	{"poster": "https://image.tmdb.org/t/p/w185/wEwyajjePFVVn2wFdH1NH7z9Qn5.jpg", "tmdb_id": "99"}	a09f5cab60b3b733e4a892d5d89f9b510b63b1f14160d2db14fec01ffcac10ca	\N	t	2026-07-19 19:59:31.966518+00	2026-07-19 19:59:31.966519+00	\N	158
723e29b5-2ea9-4bca-bad1-e022f46e4ca1	95f9f6bf-0762-41a4-bd7d-fc0174610ed4	{"name": "Honey Bunny", "tmdb_id": "680", "character_of": "Аманда Пламмер"}	e642c096e7f3d6dbfb6d403ff104634bbf2b0499a45b5dcfbcced5c844abb69f	\N	t	2026-07-19 19:59:31.969508+00	2026-07-19 19:59:31.969509+00	\N	158
263755be-ccdf-4170-92f1-57687e5b724f	fc0a62fb-ca91-4b8f-aa90-09817fdb2aae	{"poster": "https://image.tmdb.org/t/p/w185/v53G55qSYaVRvbgUZ2uch4gVHT6.jpg", "tmdb_id": "2319"}	06005ae855513d50c1e10052ccc81b2fb58d2b30d9114e5f997a345f15a88025	\N	t	2026-07-19 19:59:31.978502+00	2026-07-19 19:59:31.978504+00	\N	158
7b0de9e1-94bf-46f9-9331-b791bdc9e4a9	7a928702-5d9a-4c9d-8edc-802af6044700	{"name": "Fabienne", "tmdb_id": "680", "character_of": "Мария де Медейруш"}	0d32e6048b91f1d5c75eab921bf0fa180eee214eff7401134efffaac5cafc99a	\N	t	2026-07-19 19:59:31.98422+00	2026-07-19 19:59:31.984221+00	\N	158
336207d0-e82c-41a7-a519-eca9c207eed0	8eb99f48-0448-4835-9bb8-95440e9d84c4	{"poster": "https://image.tmdb.org/t/p/w185/1gjcpAa99FAOWGnrUvHEXXsRs7o.jpg", "tmdb_id": "138"}	835d63020975a0e6c55d8115f1744cabc9193ac61f78fe91564a05b9f4b924d7	\N	t	2026-07-19 19:59:31.991632+00	2026-07-19 19:59:31.991634+00	\N	158
57262df6-5299-42c3-807b-11a2ddb83ec9	e0000013-0000-0000-0000-000000000002	{"name": "Democracy", "origins": "Ancient Greece", "variants": ["Direct", "Representative"], "description": "A system of government by the whole population"}	hash27	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
2c88dc50-6ede-4633-b603-7599be004f96	18bf1029-f72e-4c7e-9f1b-267acefa7bdd	{"name": "Jimmie Dimmick", "tmdb_id": "680", "character_of": "Квентин Тарантино"}	872fb05d84e38e8c8a4970b8e6ad22a010cf1ff93c4df42cd17273ea18e18087	\N	t	2026-07-19 19:59:31.998868+00	2026-07-19 19:59:31.99887+00	\N	158
b78a19c7-b0de-4f57-af68-b00d90839acc	011abc73-09cd-496a-830e-2c18ceba5709	{"poster": "https://image.tmdb.org/t/p/w185/ApgDL7nudR9T2GpjCG4vESgymO2.jpg", "tmdb_id": "4690"}	9f1e83a150c06867ce8651648a021884cebf7f1d16cd467ab1839f1591676ed5	\N	t	2026-07-19 19:59:32.004558+00	2026-07-19 19:59:32.004559+00	\N	158
b9713096-869a-4513-bc9d-ec78416afa9d	eb724143-0021-4367-9398-73d93c7ddf2b	{"name": "Captain Koons", "tmdb_id": "680", "character_of": "Кристофер Уокен"}	de0fa8206d316877e37fcd96ba74dedf83d2a453d84f8804be7fd31149c48ba6	\N	t	2026-07-19 19:59:32.008313+00	2026-07-19 19:59:32.008314+00	\N	158
06895436-53e8-428c-b1d2-51791ed5c0ed	5ab4456c-f3b0-4f3c-9133-51f341cfd762	{"poster": "https://image.tmdb.org/t/p/w185/qfS5G5VHW2gz2sYGDhIYRBoy3vY.jpg", "tmdb_id": "2165"}	9acb2ce0775a6f58200e274f1deafa8bcfadfc736bf10558d0f3bf5033ab405e	\N	t	2026-07-19 19:59:32.014959+00	2026-07-19 19:59:32.014961+00	\N	158
2fc6e90b-23b3-44f4-97ad-40b33ed067ce	19572261-c80f-48d5-85fc-08403eecfa24	{"name": "Jody", "tmdb_id": "680", "character_of": "Розанна Аркетт"}	911bf2f3e5a029392539e4b43a41ace037e8a5aa39affbfccf85b59fa5083ee0	\N	t	2026-07-19 19:59:32.019764+00	2026-07-19 19:59:32.019765+00	\N	158
12b79da0-f179-4eae-bbd5-817848f46d9f	aa3aee87-0fe7-4dd3-8aa4-a2113673916d	{"poster": "https://image.tmdb.org/t/p/w185/n49XdJsMwNRdc4qT9XVAGb3fIQW.jpg", "tmdb_id": "11803"}	cae238bde26c93264c69d1fce0b6f467c7d046a01fc5ed9c0729e00f0711143a	\N	t	2026-07-19 19:59:32.024326+00	2026-07-19 19:59:32.024327+00	\N	158
6a0af882-2911-49c5-b8e5-955c00e86d0c	c8260e42-a05c-457d-a614-54c14a2b71ce	{"name": "Zed", "tmdb_id": "680", "character_of": "Питер Грин"}	837cebdd89dbc8646d1bb0e5f4cb4e2b2b6cc7e0c34a659811f5faeda16fede6	\N	t	2026-07-19 19:59:32.027654+00	2026-07-19 19:59:32.027655+00	\N	158
850a8f0f-1606-4571-be02-d8a1b19dfa9c	db0a812a-b276-48f4-866b-a2d1d57ab6b1	{"poster": "https://image.tmdb.org/t/p/w185/83nCcAaMYim24qWRwJcC1ZvfgK5.jpg", "tmdb_id": "11804"}	958a3255ca6ca53423c6f3e4eb6cd0bb90212844c5b62d0a0994ff345457e7d0	\N	t	2026-07-19 19:59:32.033235+00	2026-07-19 19:59:32.033236+00	\N	158
0ef209bd-bead-4dcc-8d49-f2716173c20f	e0000003-0000-0000-0000-000000000001	{"members": ["Lana Wachowski", "Lily Wachowski"], "nationality": "American", "notable_works": ["The Matrix", "Cloud Atlas"]}	hash5	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
40d77e9e-fbe3-4d77-87cc-d58250a88989	e0000003-0000-0000-0000-000000000002	{"last_name": "Nolan", "birth_date": "1970-07-30", "first_name": "Christopher", "birth_place": "London, UK", "nationality": "British-American"}	hash6	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
5ace336f-523a-4889-a701-8d14096e37de	e0000004-0000-0000-0000-000000000001	{"op": "Op. 314", "key": "D major", "year": 1867, "title": "The Blue Danube", "composer": "Johann Strauss II"}	hash7	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
6cc458e2-d6b5-4c3e-871e-661132ef8205	e0000004-0000-0000-0000-000000000002	{"key": "Bb major", "year": 1975, "album": "A Night at the Opera", "title": "Bohemian Rhapsody", "artist": "Queen", "duration": 355}	hash8	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
9cd7b6c6-d9f5-43a7-9071-df2deea878a0	e0000005-0000-0000-0000-000000000001	{"nickname": "The Waltz King", "last_name": "Strauss II", "birth_date": "1825-10-25", "death_date": "1899-05-03", "first_name": "Johann", "birth_place": "Vienna, Austria"}	hash9	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
458c33cb-9163-4650-9bfa-4f0fece00608	e0000005-0000-0000-0000-000000000002	{"last_name": "Mercury", "birth_date": "1946-09-05", "death_date": "1991-11-24", "first_name": "Freddie", "occupation": "Singer, songwriter", "birth_place": "Zanzibar"}	hash10	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
911515b4-065b-414c-a602-85da3004cacf	e0000006-0000-0000-0000-000000000001	{"year": 1975, "genre": "Rock", "label": "EMI", "title": "A Night at the Opera", "artist": "Queen", "tracks": 12}	hash11	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
18758a32-a459-462b-bdaa-241da81e5588	e0000006-0000-0000-0000-000000000002	{"year": 1981, "genre": "Rock", "label": "EMI", "title": "Greatest Hits", "artist": "Queen", "tracks": 17}	hash12	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
f8df76c9-83d5-476c-b51b-5032b6648da8	e0000007-0000-0000-0000-000000000002	{"isbn": "978-0-441-17271-9", "year": 1965, "genre": "Science Fiction", "pages": 412, "title": "Dune", "author": "Frank Herbert", "publisher": "Chilton Books"}	hash14	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
6f56a682-2d02-4fca-90e7-1d2273c2309a	e0000008-0000-0000-0000-000000000001	{"last_name": "Gibson", "birth_date": "1948-03-17", "first_name": "William", "occupation": "Writer", "birth_place": "Portsmouth, USA", "nationality": "American-Canadian"}	hash15	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
bdd5432b-4ad5-4a70-b553-a8a97c247eff	e0000008-0000-0000-0000-000000000002	{"last_name": "Herbert", "birth_date": "1920-10-08", "death_date": "1986-02-11", "first_name": "Frank", "occupation": "Writer", "birth_place": "Tacoma, USA"}	hash16	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
b7a540f4-1b01-4a0e-87ac-5efb316b9470	e0000009-0000-0000-0000-000000000001	{"city": "Moscow", "country": "Russia", "latitude": 55.7558, "timezone": "UTC+3", "longitude": 37.6173, "population": 12600000}	hash17	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
66c4bdcd-56a6-4ee8-bcdf-02e35a4d1c4f	e0000009-0000-0000-0000-000000000002	{"city": "Paris", "country": "France", "latitude": 48.8566, "timezone": "UTC+1", "longitude": 2.3522, "population": 2161000}	hash18	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
fa71dc14-f4c0-4aa6-86a5-b2241f9e9903	e0000009-0000-0000-0000-000000000003	{"city": "Tokyo", "country": "Japan", "latitude": 35.6762, "timezone": "UTC+9", "longitude": 139.6503, "population": 13960000}	hash19	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
7d17cefa-ed47-4449-94eb-e552a6349f66	e0000010-0000-0000-0000-000000000001	{"symbol": "H", "element": "Hydrogen", "atomic_mass": 1.008, "atomic_number": 1, "boiling_point": -252.87, "melting_point": -259.16, "electron_configuration": "1s1"}	hash20	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
05b3c573-5e9e-426c-84af-25d1f17bdcde	e0000010-0000-0000-0000-000000000002	{"symbol": "O", "element": "Oxygen", "atomic_mass": 15.999, "atomic_number": 8, "boiling_point": -182.96, "melting_point": -218.79, "electron_configuration": "[He] 2s2 2p4"}	hash21	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
7c742c95-6a87-47e3-a5dd-6970420eda4f	e0000010-0000-0000-0000-000000000003	{"symbol": "C", "element": "Carbon", "atomic_mass": 12.011, "atomic_number": 6, "boiling_point": 4027, "melting_point": 3550, "electron_configuration": "[He] 2s2 2p2"}	hash22	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
fda1bb6d-d973-4e9c-9bfb-0809ffbc7657	e0000011-0000-0000-0000-000000000001	{"class": "Mammalia", "order": "Carnivora", "family": "Canidae", "habitat": "Forests, tundra", "common_name": "Wolf", "scientific_name": "Canis lupus"}	hash23	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
0a78d7da-f19c-4ebf-9a14-ab0c09980583	e0000011-0000-0000-0000-000000000002	{"class": "Aves", "order": "Accipitriformes", "family": "Accipitridae", "habitat": "Mountains, open areas", "common_name": "Eagle", "scientific_name": "Aquila chrysaetos"}	hash24	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
f95fd133-833e-48f6-953e-a78c665ac07d	e0000011-0000-0000-0000-000000000003	{"class": "Mammalia", "order": "Artiodactyla", "family": "Delphinidae", "habitat": "Oceans worldwide", "common_name": "Bottlenose Dolphin", "scientific_name": "Tursiops truncatus"}	hash25	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
fdb8dea5-63c9-4205-9383-b32e28e6fe4d	e0000013-0000-0000-0000-000000000001	{"name": "Cyberpunk", "origins": "1980s", "key_works": ["Neuromancer", "Blade Runner"], "description": "A subgenre of science fiction set in a lawless digital world"}	hash26	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
cdee1c05-a543-4b2b-9aaf-9cad84210104	71b9c2c8-db71-44b6-808a-ad43ac25d6e5	{"name": "Maynard", "tmdb_id": "680", "character_of": "Дуан Уайтакер"}	f7391c5a568582599430abd0879cc077f05e48ae2d38be452e1055733140d6a9	\N	t	2026-07-19 19:59:32.036381+00	2026-07-19 19:59:32.036382+00	\N	158
53b59742-8f39-455b-b67f-e6aa8f7de389	a507779e-40a9-4731-abbf-96c9d9f90d2e	{"poster": "https://image.tmdb.org/t/p/w185/1gjcpAa99FAOWGnrUvHEXXsRs7o.jpg", "tmdb_id": "138"}	835d63020975a0e6c55d8115f1744cabc9193ac61f78fe91564a05b9f4b924d7	\N	t	2026-07-19 19:59:32.040414+00	2026-07-19 19:59:32.040415+00	\N	158
a0a238ba-c633-4c6a-b41a-5bb27d7a9835	9de1b51d-ec3a-420d-babb-382618847a99	{"year": 1994, "genre": "триллер, криминал, комедия", "title": "Pulp Fiction", "budget": "8.0M", "images": "", "poster": "https://image.tmdb.org/t/p/w500/dzkW0SKRUaQ46PruMA9lQscgQl4.jpg", "rating": 8.481, "country": "United States of America", "imdb_id": "tt0110912", "tagline": "«То, что ты персонаж, еще не значит, что у тебя есть характер»", "tmdb_id": "680", "director": "Квентин Тарантино", "duration": "154 мин", "language": "English, Español, Français", "age_rating": "", "description": "Пути двух наемных убийц, профессионального бойца, двух бандитов и жены гангстера пересекаются в этом закрученном кровавом путешествии по злачному центру Лос-Анджелеса.", "production_company": "Miramax, A Band Apart, Jersey Films"}	c1bf6c59b3255d3e74ece9059106307185d9c95743d99db1a7001a47230e9dfb	\N	t	2026-07-18 09:57:20.683843+00	2026-07-18 09:57:20.683843+00	\N	1
cdb3fd7f-c86b-42c5-b4b6-4aafe1cd8341	e0000013-0000-0000-0000-000000000003	{"name": "Artificial Intelligence", "subfields": ["Machine Learning", "NLP", "Computer Vision"], "description": "Intelligence demonstrated by machines"}	hash28	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
d620d282-632a-463b-92e7-a98c8ceb1a65	e0000014-0000-0000-0000-000000000001	{"name": "Science Fiction", "subgenres": ["Cyberpunk", "Space Opera", "Dystopian"], "description": "Speculative fiction dealing with futuristic concepts"}	hash29	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
c88a8786-3c75-42f1-a91a-a35723509cbf	e0000002-0000-0000-0000-000000000001	{"poster": "", "height_cm": 186, "last_name": "Reeves", "birth_date": "1964-09-02", "first_name": "Keanu", "birth_place": "Beirut, Lebanon", "nationality": "Canadian"}	a94a72f9b5304cd30ac324d4a8a9ad13383c44304e4bce1b25f737ddd99e8cc4	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
92e4fe3b-059c-4f9e-b0f3-98b8e6a62447	e0000026-0000-0000-0000-000000000002	{"name": "Paris Opera", "type": "Opera house", "founded": 1669, "location": "Paris, France", "notable_architect": "Charles Garnier"}	hash32	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
8410fa6c-82d4-49a3-b6c7-fefa2c37692d	f0000002-0000-0000-0000-000000000003	{"poster": "https://image.tmdb.org/t/p/w186/elSlNgV8xVifsbHpFsqrPGxJToZ.jpg", "last_name": "Damon", "birth_year": 1970, "birthplace": "Кембридж, Массачусетс", "first_name": "Matt"}	hash_a1	\N	t	2026-07-18 09:57:12.872762+00	2026-07-18 09:57:12.872762+00	\N	1
82d05d29-435d-49d6-acd9-4e6bdbddae5b	f0000002-0000-0000-0000-000000000004	{"poster": "https://image.tmdb.org/t/p/w186/y3dKXy5LMhLlJpLmPQNyDlKdOkr.jpg", "last_name": "Johansson", "birth_year": 1984, "birthplace": "Нью-Йорк, США", "first_name": "Scarlett"}	hash_a2	\N	t	2026-07-18 09:57:12.872762+00	2026-07-18 09:57:12.872762+00	\N	1
79bf9d28-b12b-4155-aa16-b6d3c9a42db9	f0000002-0000-0000-0000-000000000005	{"poster": "https://image.tmdb.org/t/p/w186/l4wHk6a2v89Ehv1pMv3Rvh9c9w5.jpg", "last_name": "Gosling", "birth_year": 1980, "birthplace": "Лондон, Онтарио", "first_name": "Ryan"}	hash_a3	\N	t	2026-07-18 09:57:12.872762+00	2026-07-18 09:57:12.872762+00	\N	1
08950d0c-4a5d-4cd1-a037-96fb90350f11	f0000003-0000-0000-0000-000000000003	{"poster": "https://image.tmdb.org/t/p/w186/3o6TjuWZEOwUDIX1GNVnpHDi42r.jpg", "last_name": "Fincher", "birth_year": 1962, "birthplace": "Денвер, Колорадо", "first_name": "David", "notable_works": "Социальная сеть, Игра в имитацию"}	hash_d1	\N	t	2026-07-18 09:57:12.880537+00	2026-07-18 09:57:12.880537+00	\N	1
3a4e6a97-f10d-4c3f-9806-158be7c03cfc	f0000003-0000-0000-0000-000000000004	{"poster": "https://image.tmdb.org/t/p/w186/gXjWLd2VjV0v0Bk5b6k6T9gP0Dq.jpg", "last_name": "Villeneuve", "birth_year": 1967, "birthplace": "Квебек, Канада", "first_name": "Denis", "notable_works": "Дюна, Пленники"}	hash_d2	\N	t	2026-07-18 09:57:12.880537+00	2026-07-18 09:57:12.880537+00	\N	1
089cc197-d6ec-426a-83f6-82485c1d4361	f0000003-0000-0000-0000-000000000005	{"poster": "https://image.tmdb.org/t/p/w186/4bpcE8xqIh4pMSx0rQxYp4R5FmH.jpg", "last_name": "Scott", "birth_year": 1937, "birthplace": "Саут-Шилдс, Англия", "first_name": "Ridley", "notable_works": "Чужой, Бегущий по лезвию"}	hash_d3	\N	t	2026-07-18 09:57:12.880537+00	2026-07-18 09:57:12.880537+00	\N	1
a8fd1024-ae02-4a4d-af4d-1f0d1ef8ec44	f0000004-0000-0000-0000-000000000003	{"year": 1971, "album": "Led Zeppelin IV", "genre": "Rock", "title": "Stairway to Heaven", "artist": "Led Zeppelin", "duration": "8:02"}	hash_s1	\N	t	2026-07-18 09:57:12.888696+00	2026-07-18 09:57:12.888696+00	\N	1
7ca4307f-dc01-4a39-9bdd-612de2d8a341	f0000004-0000-0000-0000-000000000004	{"year": 1977, "album": "Hotel California", "genre": "Rock", "title": "Hotel California", "artist": "Eagles", "duration": "6:30"}	hash_s2	\N	t	2026-07-18 09:57:12.888696+00	2026-07-18 09:57:12.888696+00	\N	1
3474496f-ded2-40c7-870d-d2f1d461aa38	f0000004-0000-0000-0000-000000000005	{"year": 1971, "album": "Imagine", "genre": "Pop, Rock", "title": "Imagine", "artist": "John Lennon", "duration": "3:07"}	hash_s3	\N	t	2026-07-18 09:57:12.888696+00	2026-07-18 09:57:12.888696+00	\N	1
efdd99bf-f789-4958-9f2c-0f20b08f9dce	f0000005-0000-0000-0000-000000000003	{"poster": "https://image.tmdb.org/t/p/w186/xFJlZVFOeUptftr9JZgKKsMGnGw.jpg", "last_name": "Lennon", "birth_year": 1940, "birthplace": "Ливерпуль, Англия", "death_year": 1980, "first_name": "John"}	hash_m1	\N	t	2026-07-18 09:57:12.896869+00	2026-07-18 09:57:12.896869+00	\N	1
c04dd1e2-3b2a-4616-8c6f-e8cc4b3a95bb	f0000005-0000-0000-0000-000000000004	{"poster": "https://image.tmdb.org/t/p/w186/kkDPnGnMzB3e9D0kP7JUaEVp1gn.jpg", "last_name": "Hendrix", "birth_year": 1942, "birthplace": "Сиэтл, Вашингтон", "death_year": 1970, "first_name": "Jimi"}	hash_m2	\N	t	2026-07-18 09:57:12.896869+00	2026-07-18 09:57:12.896869+00	\N	1
06f82de9-39d6-4aa6-9a5e-021a91acd409	f0000005-0000-0000-0000-000000000005	{"poster": "https://image.tmdb.org/t/p/w186/jRJVLKwh1v5OJx1yVc8x8IcI3bZ.jpg", "last_name": "Presley", "birth_year": 1935, "birthplace": "Тупело, Миссисипи", "death_year": 1977, "first_name": "Elvis"}	hash_m3	\N	t	2026-07-18 09:57:12.896869+00	2026-07-18 09:57:12.896869+00	\N	1
66f2d36d-dfb5-4dd0-b046-f4460b695005	f0000007-0000-0000-0000-000000000004	{"year": 1953, "genre": "Антиутопия", "pages": 194, "title": "Fahrenheit 451", "author": "Ray Bradbury", "poster": "https://covers.openlibrary.org/b/id/11153207-L.jpg"}	hash_b2	\N	t	2026-07-18 09:57:12.90511+00	2026-07-18 09:57:12.90511+00	\N	1
92ae2830-2ce0-46a0-85ea-280ea7b38733	f0000007-0000-0000-0000-000000000005	{"year": 1932, "genre": "Антиутопия", "pages": 311, "title": "Brave New World", "author": "Aldous Huxley", "poster": "https://covers.openlibrary.org/b/id/8102119-L.jpg"}	hash_b3	\N	t	2026-07-18 09:57:12.90511+00	2026-07-18 09:57:12.90511+00	\N	1
b124ee2d-64f6-420a-b723-8d0594478212	f0000008-0000-0000-0000-000000000003	{"poster": "https://image.tmdb.org/t/p/w186/7eyEsh1zSzsAR6ajqIrc6PXQ1pI.jpg", "last_name": "Orwell", "birth_year": 1903, "birthplace": "Мотихари, Индия", "death_year": 1950, "first_name": "George", "notable_works": "1984, скотный двор"}	hash_w1	\N	t	2026-07-18 09:57:12.912728+00	2026-07-18 09:57:12.912728+00	\N	1
2a097372-e4dc-4561-8be8-7f8826fc3d94	f0000008-0000-0000-0000-000000000004	{"poster": "https://image.tmdb.org/t/p/w186/yFCxw6yMmMCmrxvX0F3b3e3nO8e.jpg", "last_name": "Bradbury", "birth_year": 1920, "birthplace": "Уокиган, Иллинойс", "death_year": 2012, "first_name": "Ray", "notable_works": "451 градус по Фаренгейту, Вино из одуванчиков"}	hash_w2	\N	t	2026-07-18 09:57:12.912728+00	2026-07-18 09:57:12.912728+00	\N	1
ac7bb7f4-ada7-47e0-9e9b-b4cd26bd04b4	f0000008-0000-0000-0000-000000000005	{"poster": "https://image.tmdb.org/t/p/w186/4JfgNMore4R3DaU30U4CpMvMfJq.jpg", "last_name": "Huxley", "birth_year": 1894, "birthplace": "Годалминг, Англия", "death_year": 1963, "first_name": "Aldous", "notable_works": "Дивный новый мир, О дивный новый мир"}	hash_w3	\N	t	2026-07-18 09:57:12.912728+00	2026-07-18 09:57:12.912728+00	\N	1
8c2de036-8157-4719-9e61-cd47852bb826	f0000009-0000-0000-0000-000000000004	{"area": "1572 км²", "city": "London", "poster": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/London_Skyline_%28125508654%29.jpeg/1280px-London_Skyline_%28125508654%29.jpeg", "country": "United Kingdom", "population": "8.9 млн"}	hash_p1	\N	t	2026-07-18 09:57:12.920593+00	2026-07-18 09:57:12.920593+00	\N	1
6f0c0ef8-a3e2-45fc-928f-dfc0b9c2dadc	f0000007-0000-0000-0000-000000000003	{"year": 1949, "genre": "Антиутопия", "pages": 328, "title": "1984", "author": "George Orwell", "poster": "http://localhost:9000/dwmb-media/entities/5ceefbba-b512-467e-9bbb-2f8a537bd2b9/Taxi.jpg?AWSAccessKeyId=dwmb_minio&Signature=OOvWy%2Fcnvc84JPuLsKzXMPUZHxw%3D&Expires=1784410805"}	07382d04d989b28428131a0e9ee6d7569bdbac76fc9f39a20f7f7a35af1720d3	\N	t	2026-07-18 09:57:12.90511+00	2026-07-18 09:57:12.90511+00	\N	1
c956cb53-bef5-4267-8fa6-64a4864b1804	f0000010-0000-0000-0000-000000000005	{"symbol": "Au", "category": "Переходный металл", "atomic_mass": 196.967, "atomic_number": 79, "electron_config": "[Xe] 4f14 5d10 6s1"}	hash_e2	\N	t	2026-07-18 09:57:12.92833+00	2026-07-18 09:57:12.92833+00	\N	1
8f529844-06cd-4aa6-bad2-1de2b651a7d2	f0000010-0000-0000-0000-000000000006	{"symbol": "Ag", "category": "Переходный металл", "atomic_mass": 107.868, "atomic_number": 47, "electron_config": "[Kr] 4d10 5s1"}	hash_e3	\N	t	2026-07-18 09:57:12.92833+00	2026-07-18 09:57:12.92833+00	\N	1
83973d30-3ab5-4f8b-ab9c-418496e635a0	f0000011-0000-0000-0000-000000000004	{"class": "Mammalia", "order": "Carnivora", "family": "Felidae", "poster": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Cat03.jpg/1200px-Cat03.jpg", "habitat": "Тропические леса", "conservation": "Endangered"}	hash_an1	\N	t	2026-07-18 09:57:12.937822+00	2026-07-18 09:57:12.937822+00	\N	1
a88b6e4e-f56a-4ea8-a382-37a71344e525	f0000011-0000-0000-0000-000000000005	{"class": "Mammalia", "order": "Proboscidea", "family": "Elephantidae", "poster": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/African_Bush_Elephant.jpg/1200px-African_Bush_Elephant.jpg", "habitat": "Саванны, леса", "conservation": "Endangered"}	hash_an2	\N	t	2026-07-18 09:57:12.937822+00	2026-07-18 09:57:12.937822+00	\N	1
be6f224e-d399-4b8d-a066-0ec36a5d5767	f0000011-0000-0000-0000-000000000006	{"class": "Aves", "order": "Sphenisciformes", "family": "Spheniscidae", "poster": "https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Emperor_Penguins_at_Snow_Hill_Island.jpg/1200px-Emperor_Penguins_at_Snow_Hill_Island.jpg", "habitat": "Антарктика", "conservation": "Various"}	hash_an3	\N	t	2026-07-18 09:57:12.937822+00	2026-07-18 09:57:12.937822+00	\N	1
aac9f619-5a06-47eb-b998-7563c8320a03	f0000026-0000-0000-0000-000000000003	{"name": "The Walt Disney Company", "poster": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/43/Disney_Plus_logo.svg/1200px-Disney_Plus_logo.svg.png", "founded": 1923, "industry": "Медиа, развлечения", "headquarters": "Бербанк, Калифорния"}	hash_o1	\N	t	2026-07-18 09:57:12.949624+00	2026-07-18 09:57:12.949624+00	\N	1
ba3b1ed0-c425-4b67-aaf5-0c9eb684ec85	f0000026-0000-0000-0000-000000000004	{"name": "Apple Inc.", "poster": "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Apple_logo_black.svg/1200px-Apple_logo_black.svg.png", "founded": 1976, "industry": "Технологии", "headquarters": "Купертино, Калифорния"}	hash_o2	\N	t	2026-07-18 09:57:12.949624+00	2026-07-18 09:57:12.949624+00	\N	1
5fd94e87-41cf-4064-bed2-65ba25d8a92d	ddb3b8a3-4c5b-491f-86d4-f737bc84ed9c	{"last_name": "DiCaprio", "birth_date": "1974-11-11", "first_name": "Leonardo", "occupation": "Actor", "birth_place": "Los Angeles, USA", "nationality": "American"}	520e36d69c4ac839a923789878d3ddb78dda690783002fbfb401f334cb9d7b60	\N	t	2026-07-18 09:57:20.741418+00	2026-07-18 09:57:20.741418+00	\N	1
70ea9375-db20-4ae9-bc4b-0cae4ce4714a	3b467fe5-fd04-4ae7-948c-e6964af03be6	{"last_name": "Reeves", "birth_date": "1964-09-02", "first_name": "Keanu", "occupation": "Actor", "birth_place": "Beirut, Lebanon", "nationality": "Canadian"}	0addcd035ea689eaa8bdf8b6ac8ef2eb676566ae0b009edfe3c9271949fb0ab2	\N	t	2026-07-18 09:57:20.751984+00	2026-07-18 09:57:20.751984+00	\N	1
688a42dd-3ae7-4001-b89a-b11e95879e5b	5ce768b7-b7db-498e-934d-898d7b25034c	{"last_name": "McConaughey", "birth_date": "1969-11-04", "first_name": "Matthew", "occupation": "Actor", "birth_place": "Uvalde, Texas", "nationality": "American"}	fdbe27f0c3c57d6932397c9b551c3212e68e9aeaf56301ce1e1bac0a5be390bf	\N	t	2026-07-18 09:57:20.762451+00	2026-07-18 09:57:20.762451+00	\N	1
bac8cde9-fb66-4b7a-9b2c-d8c82be11110	e2d9d810-d021-446b-b17f-1a543aeeaee2	{"last_name": "Pitt", "birth_date": "1963-12-18", "first_name": "Brad", "occupation": "Actor", "birth_place": "Shawnee, Oklahoma", "nationality": "American"}	b3907f70a9787df983d22f29c5a37da8541f89e48528d28103955634f1afbf1b	\N	t	2026-07-18 09:57:20.77303+00	2026-07-18 09:57:20.77303+00	\N	1
34885d4c-4233-4332-b894-216afa1d9512	b586787c-1e27-4245-80ea-8d432335b049	{"last_name": "Travolta", "birth_date": "1954-02-18", "first_name": "John", "occupation": "Actor", "birth_place": "Englewood, New Jersey", "nationality": "American"}	60862a30096a44d9764c2281ca3f8802969f0b289b0e6e0a739be44ceadff2dc	\N	t	2026-07-18 09:57:20.784991+00	2026-07-18 09:57:20.784991+00	\N	1
ba3e3a2a-f037-405b-b4c7-9b5fd206327b	8d288041-72b0-4256-97ab-92b53f4cb5fa	{"last_name": "Hardy", "birth_date": "1977-09-15", "first_name": "Tom", "occupation": "Actor", "birth_place": "London, UK", "nationality": "British"}	a0a8c962a83322304730b3324f0762e7b058f000814d6224f3b086dbef09bfb2	\N	t	2026-07-18 09:57:20.79483+00	2026-07-18 09:57:20.79483+00	\N	1
2fac6e8e-5769-4003-a68c-c59326bebe98	606e3eac-1206-4f2e-93cb-6ae5b7d27569	{"last_name": "Hanks", "birth_date": "1956-07-09", "first_name": "Tom", "occupation": "Actor", "birth_place": "Concord, California", "nationality": "American"}	055aed1d8671fb64245d52a20c7f181a4f711d74798acbe30c2d2e251dfd1eb3	\N	t	2026-07-18 09:57:20.803597+00	2026-07-18 09:57:20.803597+00	\N	1
18683a02-8f2e-4100-ba01-b11d8cd8f4df	c04f634b-0391-4181-9878-e6a1d0ffdcfc	{"last_name": "Neeson", "birth_date": "1952-06-07", "first_name": "Liam", "occupation": "Actor", "birth_place": "Ballymena, UK", "nationality": "Irish"}	caa569e17a841a3b1629edfbaed30709c19577fb136b7b459528fcee80a40b5d	\N	t	2026-07-18 09:57:20.81287+00	2026-07-18 09:57:20.81287+00	\N	1
0b245f47-84d7-43c3-bbe9-19606daa84b1	8b4b0977-6964-4779-9ca6-569348e4d469	{"last_name": "Foxx", "birth_date": "1967-12-13", "first_name": "Jamie", "occupation": "Actor", "birth_place": "Terrell, Texas", "nationality": "American"}	d51c714fc3ca8b13a3e475853715436979b5146b5c325f2eb567a1e668ad8c6b	\N	t	2026-07-18 09:57:20.825626+00	2026-07-18 09:57:20.825626+00	\N	1
b3c4ca31-a90f-4f83-9dfb-0eb91e28d32a	f9004d4d-f01f-44c5-9154-26d37d4c9fe5	{"last_name": "Ruffalo", "birth_date": "1967-11-22", "first_name": "Mark", "occupation": "Actor", "birth_place": "Kenosha, Wisconsin", "nationality": "American"}	ea55c646c695bf233c2d9b33b36f39c5a2aa40ac01105a5133f8030b8de847ea	\N	t	2026-07-18 09:57:20.838489+00	2026-07-18 09:57:20.838489+00	\N	1
b251eb5c-3acf-4b1b-b326-a7c862ee3559	ee053e8b-e27e-4e4a-b540-8b38a2387ad1	{"last_name": "Nolan", "birth_date": "1970-07-30", "first_name": "Christopher", "occupation": "Director", "birth_place": "London, UK", "nationality": "British-American"}	98618a44ec7cc9d31c84b5f7d874b8e6e154a4bba40d20aa2ec4d8dcec577308	\N	t	2026-07-18 09:57:20.852535+00	2026-07-18 09:57:20.852535+00	\N	1
888cc3e1-b1d3-4d65-8c8c-3d644b645fcc	5d337d5f-8b03-48b7-b8ee-2724a56f83a8	{"last_name": "Wachowski", "birth_date": "1965-06-21", "first_name": "Lana & Lilly", "occupation": "Director", "birth_place": "Chicago, USA", "nationality": "American"}	7bc277cfb97dfb93ce86ac2eb69ce830c490fe01cb6fcfb5980e1c5a87a65e84	\N	t	2026-07-18 09:57:20.863527+00	2026-07-18 09:57:20.863527+00	\N	1
38d4f411-faca-46f6-94d3-be238bded914	36d49335-bf9d-4ca5-b276-a3239a6eb129	{"last_name": "Fincher", "birth_date": "1962-08-28", "first_name": "David", "occupation": "Director", "birth_place": "Denver, Colorado", "nationality": "American"}	8d96af53f946bcb2d263203561cbc387a7936233c7f670045e95709b1763379a	\N	t	2026-07-18 09:57:20.87452+00	2026-07-18 09:57:20.87452+00	\N	1
def25855-60af-4355-8b44-cacd801c2747	415f017c-ea76-4539-9e57-2790b05894dd	{"last_name": "Tarantino", "birth_date": "1963-03-27", "first_name": "Quentin", "occupation": "Director", "birth_place": "Knoxville, Tennessee", "nationality": "American"}	55649f510190819ae02c4bdd07379fb3947f1ea1022cf6b8eb5735230621bc5f	\N	t	2026-07-18 09:57:20.88761+00	2026-07-18 09:57:20.88761+00	\N	1
a4c94bbb-5e9f-4778-bcc6-5289c10ceecc	3da51058-ec94-4c29-aba1-148714af2ab6	{"last_name": "Spielberg", "birth_date": "1946-12-18", "first_name": "Steven", "occupation": "Director", "birth_place": "Cincinnati, Ohio", "nationality": "American"}	2ee34efab7481d8a6a9499daaf5919f75d949d019eb360afa2c71dbe65adcb6a	\N	t	2026-07-18 09:57:20.899384+00	2026-07-18 09:57:20.899384+00	\N	1
5363a07f-7103-42f4-be5b-b51c37ea358a	a0284d60-b6bd-4517-9fb3-43ee06a3a263	{"last_name": "Scorsese", "birth_date": "1942-11-17", "first_name": "Martin", "occupation": "Director", "birth_place": "Queens, New York", "nationality": "American"}	f3af81d2b4f2d8b504a878d4dacfc1f56ecfe1df840821363c2310bf460b0201	\N	t	2026-07-18 09:57:20.908251+00	2026-07-18 09:57:20.908251+00	\N	1
9c7884d0-7e0f-497b-bda3-b4e4540f5d83	6738d301-3f2a-4d63-83f3-32d4d2db651f	{"last_name": "Scott", "birth_date": "1937-11-30", "first_name": "Ridley", "occupation": "Director", "birth_place": "South Shields, UK", "nationality": "British"}	d995f14bda00eac8cf634032eda219970bcf7a90560e95834d8d84bd72bcea1d	\N	t	2026-07-18 09:57:20.916764+00	2026-07-18 09:57:20.916764+00	\N	1
9e444c7f-bd8c-4e57-99fa-e7d3eb7802f8	a601ee49-27ee-463f-9bd6-fdeacfd04490	{"last_name": "Kubrick", "birth_date": "1928-07-26", "first_name": "Stanley", "occupation": "Director", "birth_place": "Bronx, New York", "nationality": "American"}	336ba66c9a87412cbf6e5ba13f792519c2d84cf0815a7cb3ccd64a0db6d10edb	\N	t	2026-07-18 09:57:20.925902+00	2026-07-18 09:57:20.925902+00	\N	1
8565d39c-7a76-41d2-9992-4b109223a200	2a0bb8db-5a49-4d0c-b855-2bc3f56cf205	{"last_name": "Darabont", "birth_date": "1959-01-28", "first_name": "Frank", "occupation": "Director", "birth_place": "Montbéliard, France", "nationality": "American"}	23fa64cdbf159beb23b937116addbf1523d102eea708d9dbb480ca68dee7dfb5	\N	t	2026-07-18 09:57:20.937343+00	2026-07-18 09:57:20.937343+00	\N	1
e7eb77ed-eae9-474e-abb2-44328540cff1	cbd9198b-9b10-49d3-81a5-21092f2c0a68	{"last_name": "Villeneuve", "birth_date": "1967-10-03", "first_name": "Denis", "occupation": "Director", "birth_place": "Quebec, Canada", "nationality": "Canadian"}	ec4a3ec258d1f8a227d57ef5524602b3f2a41d96e28c2224b3701e639a126ece	\N	t	2026-07-18 09:57:20.948394+00	2026-07-18 09:57:20.948394+00	\N	1
50c3addd-009a-4c44-aa61-aa0b15782b9f	e9c2c8ca-2975-40e9-9999-a105c29f82e2	{"bpm": 72, "year": 1975, "album": "A Night at the Opera", "genre": "Rock", "title": "Bohemian Rhapsody", "artist": "Queen", "duration_sec": 355}	fd3e3d1497d2915a1f1b7b897933c92b5e41e39a121fa37fb0ab788fd405b803	\N	t	2026-07-18 09:57:20.963078+00	2026-07-18 09:57:20.963078+00	\N	1
04e32d79-2c07-4438-9050-12f9686c7715	5e2ad7ef-9e21-4e1f-af4e-45f953b9874e	{"bpm": 82, "year": 1971, "album": "Led Zeppelin IV", "genre": "Rock", "title": "Stairway to Heaven", "artist": "Led Zeppelin", "duration_sec": 482}	a2bb5d5ff2acebaae7d4883371c61c19a16b6f19d470928fe751e6beed2dc290	\N	t	2026-07-18 09:57:20.975585+00	2026-07-18 09:57:20.975585+00	\N	1
e6680ec6-4e03-4c7d-8d58-a77fa5edcb11	722de5f4-01ed-404a-803a-fdc438faeb27	{"bpm": 76, "year": 1971, "album": "Imagine", "genre": "Pop", "title": "Imagine", "artist": "John Lennon", "duration_sec": 187}	30e82a7d6dfae6b94b2a8d9fa73d506e770eddd1fa02db5987ce0b2ca9e3e793	\N	t	2026-07-18 09:57:20.987717+00	2026-07-18 09:57:20.987717+00	\N	1
96124b7f-e689-4bc1-8f4d-31bc8e405be7	00853e1e-98e4-4512-9e81-cefd3374bb5a	{"bpm": 74, "year": 1977, "album": "Hotel California", "genre": "Rock", "title": "Hotel California", "artist": "Eagles", "duration_sec": 391}	c64819c29c329a94ebc31c6994424799b90a71fb00614becbd8042e0b8268fe4	\N	t	2026-07-18 09:57:20.999417+00	2026-07-18 09:57:20.999417+00	\N	1
c1943cc7-8857-43c7-b3bc-f23d3cc19627	9456d33b-5588-4e09-a3b8-b061133feeef	{"bpm": 117, "year": 1991, "album": "Nevermind", "genre": "Grunge", "title": "Smells Like Teen Spirit", "artist": "Nirvana", "duration_sec": 301}	0a071efc3939bd7f2f3d5788a503eb4cbb02692d482bf803dc1938d106d9391f	\N	t	2026-07-18 09:57:21.01097+00	2026-07-18 09:57:21.01097+00	\N	1
ce6875f6-049c-49e2-868c-1c24248aa4d3	116a5ef4-839d-4859-85c3-08a69705fd39	{"bpm": 95, "year": 1965, "album": "Highway 61 Revisited", "genre": "Rock", "title": "Like a Rolling Stone", "artist": "Bob Dylan", "duration_sec": 369}	7075464ba18275a7eca6430d8bc7c439095d89a0adc108773cf0dad630438725	\N	t	2026-07-18 09:57:21.02411+00	2026-07-18 09:57:21.02411+00	\N	1
042cef6c-4ea5-4f1e-b52b-dfa1220d0db8	db132689-4dbd-421a-9939-160954b83ed6	{"bpm": 96, "year": 1965, "album": "Help!", "genre": "Pop", "title": "Yesterday", "artist": "The Beatles", "duration_sec": 125}	52ee7b48f16b879947bfc9950eee78e3cd803471c6413d58f18be346985424b7	\N	t	2026-07-18 09:57:21.036268+00	2026-07-18 09:57:21.036268+00	\N	1
89bdce48-d2e1-4253-9e74-fbe2d91cd45d	5e3fb354-9c60-4563-ac40-1ccf2a5d2382	{"bpm": 63, "year": 1979, "album": "The Wall", "genre": "Progressive Rock", "title": "Comfortably Numb", "artist": "Pink Floyd", "duration_sec": 382}	518a188d7128119231b02bc463dc6161c9e9fb010a3182782a1a4e4c1dfa8380	\N	t	2026-07-18 09:57:21.063096+00	2026-07-18 09:57:21.063096+00	\N	1
b49c076a-3230-42aa-abfc-5f36ca274653	011b2d11-4272-4d71-99ea-1ced5c9b687a	{"bpm": 78, "year": 1974, "album": "Natty Dread", "genre": "Reggae", "title": "No Woman No Cry", "artist": "Bob Marley", "duration_sec": 285}	8f50f478e2c7169701f92529521de4ee7fe0ac1af4b7b666a001c73ad75a3307	\N	t	2026-07-18 09:57:21.076511+00	2026-07-18 09:57:21.076511+00	\N	1
465d1512-ff56-4b60-bd52-03d9c8c27d6f	b26220b9-6707-4e27-b7c4-c32d9eda2cff	{"last_name": "Mercury", "birth_date": "1946-09-05", "first_name": "Freddie", "occupation": "Musician", "birth_place": "Stone Town, Tanzania", "nationality": "British"}	f2aed291cc117633420e5d8e4294f2a7f0907a9eca212420624aaa3705669157	\N	t	2026-07-18 09:57:21.091444+00	2026-07-18 09:57:21.091444+00	\N	1
f0cfdeca-f6b0-472c-99ba-586b9a584c91	fb001e2e-6858-4823-b035-b0922bc7fa93	{"last_name": "Hendrix", "birth_date": "1942-11-27", "first_name": "Jimi", "occupation": "Musician", "birth_place": "Seattle, USA", "nationality": "American"}	51da022c323949e77d70ab03a60e11b5c2c02db5d77edc47488db0b514aef24d	\N	t	2026-07-18 09:57:21.105022+00	2026-07-18 09:57:21.105022+00	\N	1
75ac80b0-f47b-41c7-91ad-037e439bc767	4ec7de9a-1df6-433d-8b87-6f8ab8b9c69b	{"last_name": "Dylan", "birth_date": "1941-05-24", "first_name": "Bob", "occupation": "Musician", "birth_place": "Duluth, Minnesota", "nationality": "American"}	01541c23a1ae0620bd816025e9b5cb7803502d605982a675dc02acc50dcb7ce0	\N	t	2026-07-18 09:57:21.116847+00	2026-07-18 09:57:21.116847+00	\N	1
e0f7639f-e425-4a33-b247-0d1a1d9edc1f	98f38e6f-0c55-4d7a-b4bf-7d9cea3d88ef	{"last_name": "Lennon", "birth_date": "1940-10-09", "first_name": "John", "occupation": "Musician", "birth_place": "Liverpool, UK", "nationality": "British"}	e43f8ed730b710360e80457cd4662f31176180e9d6066fccf64da89cbf2e01c1	\N	t	2026-07-18 09:57:21.128241+00	2026-07-18 09:57:21.128241+00	\N	1
7ee58cf0-8e16-4e5a-bfe4-af97370395c5	a8d6398b-5081-4d08-81f6-f41850070125	{"last_name": "Jackson", "birth_date": "1958-08-29", "first_name": "Michael", "occupation": "Musician", "birth_place": "Gary, Indiana", "nationality": "American"}	f0968ee967cbe23dc7441509f2abf4990550a7c4fa28563386e4d66ebe0af659	\N	t	2026-07-18 09:57:21.139929+00	2026-07-18 09:57:21.139929+00	\N	1
1283a852-9abf-438d-b72c-b22871491605	ba2cecc7-feb9-429d-a860-f229cd447270	{"last_name": "Marley", "birth_date": "1945-02-06", "first_name": "Bob", "occupation": "Musician", "birth_place": "Nine Mile, Jamaica", "nationality": "Jamaican"}	a4b9e28ef2bf9f9cbc6e7bb06ca52bf78c3aee27b5794492ecd2c4ed5cbf3fa9	\N	t	2026-07-18 09:57:21.151034+00	2026-07-18 09:57:21.151034+00	\N	1
43ca8907-79ba-4a57-b1ea-e4a4a8727ba2	95d725d5-32ef-4b6d-8b2f-094085f0dc38	{"last_name": "Gilmour", "birth_date": "1946-03-06", "first_name": "David", "occupation": "Musician", "birth_place": "Cambridge, UK", "nationality": "British"}	09663d4f8ba5539266fc8d38647b13fd51fd31af465e8b859e6891f8b2aedbea	\N	t	2026-07-18 09:57:21.162149+00	2026-07-18 09:57:21.162149+00	\N	1
0c7fd831-98e7-4339-b7ab-c10333c62695	02b1cdfd-f5b7-4c98-ba69-09fbcb8dce16	{"last_name": "Cobain", "birth_date": "1967-02-20", "first_name": "Kurt", "occupation": "Musician", "birth_place": "Aberdeen, Washington", "nationality": "American"}	37208e3ab40f299f28bed68e914111bf402c5cc4e8a23cc9b422b2eb56003f77	\N	t	2026-07-18 09:57:21.172977+00	2026-07-18 09:57:21.172977+00	\N	1
dc8cd26d-ab12-498d-aad9-37bb415eeebf	702d2f1a-1762-4fd7-86b4-e8e579fab677	{"last_name": "Presley", "birth_date": "1935-01-08", "first_name": "Elvis", "occupation": "Musician", "birth_place": "Tupelo, Mississippi", "nationality": "American"}	48f5a8f19da3cfafbfcef9545589cf10ef05b29db98e70337f96ed809d46d6f5	\N	t	2026-07-18 09:57:21.186588+00	2026-07-18 09:57:21.186588+00	\N	1
e287d075-bcf8-40e4-a4e4-948f6f2f2daa	f33af756-918f-441e-b1b1-1f99b8971bed	{"last_name": "van Beethoven", "birth_date": "1770-12-17", "first_name": "Ludwig", "occupation": "Musician", "birth_place": "Bonn, Germany", "nationality": "German"}	b2f01eab4044b18688c02203a2cc23a874b417082e2f13b51ec93cc1894bc510	\N	t	2026-07-18 09:57:21.200804+00	2026-07-18 09:57:21.200804+00	\N	1
7ea954a9-6042-4a6b-abc1-63c0ab6492e5	b645c943-5630-43b7-89c9-633d4232c9d5	{"isbn": "978-0060850524", "year": 1932, "genre": "Dystopia", "pages": 311, "title": "A Brave New World", "author": "Aldous Huxley", "language": "English"}	f3a1466e9ff35b89f829291194e2b55017e2d88f01428e2a804c33796deaf05d	\N	t	2026-07-18 09:57:21.227014+00	2026-07-18 09:57:21.227014+00	\N	1
d8e96d13-39d6-4f59-ba3b-be84d6ddb4da	59097e2a-2ef4-43bb-be22-5de9f19ea3b1	{"isbn": "978-1451673319", "year": 1953, "genre": "Dystopia", "pages": 194, "title": "Fahrenheit 451", "author": "Ray Bradbury", "language": "English"}	74c7b74b436f124e681819e6e6367f18763296a3422b81237344306070278af5	\N	t	2026-07-18 09:57:21.238351+00	2026-07-18 09:57:21.238351+00	\N	1
0f6ffe68-c554-4dd5-8951-55bded616c1c	a42cff73-b8c6-4414-9cf7-47aa667ac157	{"isbn": "978-0547928227", "year": 1937, "genre": "Fantasy", "pages": 310, "title": "The Hobbit", "author": "J.R.R. Tolkien", "language": "English"}	61e51ed0f2984afb86b11f5278d3afbb419d6ca99404fa9101540b7f9e4e4ab8	\N	t	2026-07-18 09:57:21.250628+00	2026-07-18 09:57:21.250628+00	\N	1
b06966d2-f1ec-4047-a1aa-e831bb73c26b	e9082ff5-1c13-4814-a195-2c953070bca9	{"isbn": "978-0441013593", "year": 1965, "genre": "Sci-Fi", "pages": 688, "title": "Dune", "author": "Frank Herbert", "language": "English"}	52a28698fda9348e33c030ed4ee82f17d85233a6d6c448e61ce001e792b61b5d	\N	t	2026-07-18 09:57:21.261519+00	2026-07-18 09:57:21.261519+00	\N	1
dc6df7dd-d531-4404-ba2a-8d28a24ecc4d	42e59334-ea2b-49a7-8978-082777846f38	{"isbn": "978-5170802890", "year": 1967, "genre": "Novel", "pages": 480, "title": "Мастер и Маргарита", "author": "Михаил Булгаков", "language": "Russian"}	41bc35120ff056911de24d026e18b401fb76fae3932b8be12c6aed114999e208	\N	t	2026-07-18 09:57:21.273023+00	2026-07-18 09:57:21.273023+00	\N	1
9c19f53f-0243-4a67-a050-505ef1dbf81d	c6c1cd6f-ea56-4d85-8a24-7dd48e3a2419	{"isbn": "978-5170774753", "year": 1869, "genre": "Historical Novel", "pages": 1225, "title": "Война и мир", "author": "Лев Толстой", "language": "Russian"}	0a8cf238249e3cf15ec0bfcbaeb9f97596d02a0f79edb399a4f7e1f99bfce444	\N	t	2026-07-18 09:57:21.284367+00	2026-07-18 09:57:21.284367+00	\N	1
880d2d09-688d-4835-8f91-07dec41e8361	acd52774-107e-4718-9386-3d02dd77f044	{"isbn": "978-5170774760", "year": 1866, "genre": "Psychological Novel", "pages": 671, "title": "Преступление и наказание", "author": "Фёдор Достоевский", "language": "Russian"}	c2f05e22df7026b6ccf121a43f7a0fe3b3d4781a1124a5c6d3b5b121d709133c	\N	t	2026-07-18 09:57:21.295509+00	2026-07-18 09:57:21.295509+00	\N	1
ace8d64e-5661-4cdb-b64e-a0c86d1afee0	55833a21-d66c-40b7-af27-e2dee8a8e7fc	{"isbn": "978-0156007528", "year": 1961, "genre": "Sci-Fi", "pages": 204, "title": "Solaris", "author": "Stanislaw Lem", "language": "Polish"}	440a8e9498953469a671f2ddee19328cd23b34268653c3a7f68b2097f1eff378	\N	t	2026-07-18 09:57:21.309843+00	2026-07-18 09:57:21.309843+00	\N	1
09b10909-24d6-4866-9a7d-28355d247b48	22772cae-6136-4e93-ab66-7e1f7f0930b3	{"isbn": "978-0747532699", "year": 1997, "genre": "Fantasy", "pages": 309, "title": "Harry Potter and the Philosopher's Stone", "author": "J.K. Rowling", "language": "English"}	d5929d88df9bc389acfd9f646df42e0cbf8756b6cdb3e127182c550f322237bd	\N	t	2026-07-18 09:57:21.323342+00	2026-07-18 09:57:21.323342+00	\N	1
eac1c1b3-93a4-432d-a812-ef3b929c533f	7dca75ed-755c-4549-91f4-5557667b4a7c	{"last_name": "Orwell", "birth_date": "1903-06-25", "first_name": "George", "occupation": "Writer", "birth_place": "Motihari, India", "nationality": "British"}	ba4d2682b875bf97881cc75bb2cefc628007d1ccc72608243c8deb9b634d9023	\N	t	2026-07-18 09:57:21.341327+00	2026-07-18 09:57:21.341327+00	\N	1
0a849702-bd71-4d5d-9188-44c836116f62	b1252f58-6ae8-4dc0-b782-f4d75299b561	{"last_name": "Bulgakov", "birth_date": "1891-05-15", "first_name": "Mikhail", "occupation": "Writer", "birth_place": "Kiev, Ukraine", "nationality": "Russian"}	e70e3300d16c3c656a35bf2cd052da23555823844907d31aa859713c724d9b3c	\N	t	2026-07-18 09:57:21.362544+00	2026-07-18 09:57:21.362544+00	\N	1
457932cd-bf38-4ad3-ae02-f91c1fdfdf24	97463325-3df6-4da4-aaae-49b8bd65467e	{"last_name": "Tolstoy", "birth_date": "1828-09-09", "first_name": "Lev", "occupation": "Writer", "birth_place": "Yasnaya Polyana, Russia", "nationality": "Russian"}	6961ed7873ec7cd20b12fdf96f577d676f33b3ed87857c330a06db52e64b463e	\N	t	2026-07-18 09:57:21.371967+00	2026-07-18 09:57:21.371967+00	\N	1
7efc2b5c-1a47-4357-a22f-a82e5f2c4d91	4ebbccc4-acff-4240-8363-0b99727ce8ce	{"last_name": "Dostoevsky", "birth_date": "1821-11-11", "first_name": "Fyodor", "occupation": "Writer", "birth_place": "Moscow, Russia", "nationality": "Russian"}	6a50281d773d4f56121f92ad5cfb1740a55f28415cc5e0700434c4d8c73128f8	\N	t	2026-07-18 09:57:21.38089+00	2026-07-18 09:57:21.38089+00	\N	1
80b03bef-b1bd-4499-aa20-32982753b526	19e34f62-e56d-40d8-80ac-ed43951b2490	{"last_name": "King", "birth_date": "1947-09-21", "first_name": "Stephen", "occupation": "Writer", "birth_place": "Portland, Maine", "nationality": "American"}	4509847452d4032498428ddeb9c4be54676142c410968767400c4354746c422b	\N	t	2026-07-18 09:57:21.389653+00	2026-07-18 09:57:21.389653+00	\N	1
5f289e31-6228-4c16-9df1-458eb4fec8b0	dab11d71-c331-4511-8014-87211016f552	{"last_name": "Bradbury", "birth_date": "1920-08-22", "first_name": "Ray", "occupation": "Writer", "birth_place": "Waukegan, Illinois", "nationality": "American"}	870484a0eedca27fa56646b2904a51987cd070e6a8fc978ca84a4aa301572d34	\N	t	2026-07-18 09:57:21.398524+00	2026-07-18 09:57:21.398524+00	\N	1
91747469-dcdd-4fcb-a801-746d5a6e2070	5b3e9fb0-ebbc-4d8c-a060-d53630c25de9	{"last_name": "Lem", "birth_date": "1921-09-12", "first_name": "Stanislaw", "occupation": "Writer", "birth_place": "Lviv, Ukraine", "nationality": "Polish"}	727f9da179f9096c20292d0627f4b078b5e7750a2b279033f2bf38fbcdb4d45b	\N	t	2026-07-18 09:57:21.407418+00	2026-07-18 09:57:21.407418+00	\N	1
e11b8129-a71f-44a1-9c49-47a5e685a668	0804d0c1-9161-4e46-a823-6de06630499e	{"last_name": "Palahniuk", "birth_date": "1962-02-21", "first_name": "Chuck", "occupation": "Writer", "birth_place": "Pasco, Washington", "nationality": "American"}	e8fed32bd03a35c9e98d65312ac256eb1fa9b9caa9bfdea361aa49a435efcddb	\N	t	2026-07-18 09:57:21.417123+00	2026-07-18 09:57:21.417123+00	\N	1
41ffaa27-a9a1-4615-9ed9-e9cd69c927c2	683840ba-a2d4-4ee5-9c9e-2723ff86736f	{"name": "New York", "country": "USA", "area_km2": 783.8, "latitude": 40.7128, "timezone": "EST", "longitude": -74.006, "population": 8336817}	7857a0d08a034816ee7c3c5fdbb2858b0ae9383b5eeaaa27ff7a918c9680b3d5	\N	t	2026-07-18 09:57:21.439626+00	2026-07-18 09:57:21.439626+00	\N	1
e1b0b4d4-a060-4cfd-94b4-33e323e114a4	1be961d7-0a2b-4e8a-9d49-da9722a87195	{"name": "London", "country": "UK", "area_km2": 1572, "latitude": 51.5074, "timezone": "GMT", "longitude": -0.1278, "population": 8982000}	3f32a0298d408a773c14eacf4f9966bea6e7acd70eb97a4d3a603c9a793ae6b4	\N	t	2026-07-18 09:57:21.449143+00	2026-07-18 09:57:21.449143+00	\N	1
23fea4ce-80ba-4946-a9d1-d29c73bfc016	c1deff2b-abcb-435d-8815-14155002920f	{"name": "Paris", "country": "France", "area_km2": 105.4, "latitude": 48.8566, "timezone": "CET", "longitude": 2.3522, "population": 2161000}	042ed60f1fd6755e7c8ceec38a41f0bfc3ce727952c47d797a478f43db5ae0f6	\N	t	2026-07-18 09:57:21.459602+00	2026-07-18 09:57:21.459602+00	\N	1
0bd668d3-0de5-4a1d-be8a-cc02ecc953b8	88ef987d-88ef-4b93-b090-a6d2fb03eacf	{"name": "Tokyo", "country": "Japan", "area_km2": 2194, "latitude": 35.6762, "timezone": "JST", "longitude": 139.6503, "population": 13960000}	f64cd065bbc5fda153d6c5b50f8ff69b6ee85480f60637207bc8e703dbd15da7	\N	t	2026-07-18 09:57:21.468246+00	2026-07-18 09:57:21.468246+00	\N	1
3c40bf73-efc0-4706-b01a-d5502b46a6d8	0f63bcd0-4543-4f7f-9dba-9d999480e033	{"name": "Moscow", "country": "Russia", "area_km2": 2511, "latitude": 55.7558, "timezone": "MSK", "longitude": 37.6173, "population": 12500000}	6d820c8ab90906c3ab6e6259f4cd54bfed4027bc7c1e766da39eead567a6bdce	\N	t	2026-07-18 09:57:21.476897+00	2026-07-18 09:57:21.476897+00	\N	1
35278afe-b55b-489a-a382-d8e1b57dded8	0c2ac07d-f809-4f79-8c20-4e6cf310cfa5	{"name": "Berlin", "country": "Germany", "area_km2": 891.7, "latitude": 52.52, "timezone": "CET", "longitude": 13.405, "population": 3645000}	b4e2f4de7d80e91346ead6fa9cc74469397e84ac39d7bd96d0deafa2759b1d5b	\N	t	2026-07-18 09:57:21.485382+00	2026-07-18 09:57:21.485382+00	\N	1
e06606ec-34f0-4c21-82d8-82c7c1533a43	4d9080e5-ad25-4c76-b068-609849a86c16	{"name": "Los Angeles", "country": "USA", "area_km2": 1302, "latitude": 34.0522, "timezone": "PST", "longitude": -118.2437, "population": 3979576}	15f8b0557de7d1e37c8c6cb3b7cb7d97693db7b0d63c2195f2ebed1b65993781	\N	t	2026-07-18 09:57:21.494112+00	2026-07-18 09:57:21.494112+00	\N	1
fab59162-dbd6-4007-ba29-aee141fd8f4a	920267ff-8588-4e84-a17c-aa1f4bcefa5d	{"name": "Rome", "country": "Italy", "area_km2": 1285, "latitude": 41.9028, "timezone": "CET", "longitude": 12.4964, "population": 2873000}	c754a12f0bcec09a3202104f6b5d5b8306b27dcf20733c3d9908d5eebbfd0b0a	\N	t	2026-07-18 09:57:21.50253+00	2026-07-18 09:57:21.50253+00	\N	1
05853647-eba5-41c0-97ec-de094a7b0078	f031184e-630b-4bca-ad10-27bf6686c09f	{"name": "Sydney", "country": "Australia", "area_km2": 12368, "latitude": -33.8688, "timezone": "AEST", "longitude": 151.2093, "population": 5312000}	26d01ce61dddc7532b9db3685e50736b9b2a9c7303a592ac4268e31a3134bbc9	\N	t	2026-07-18 09:57:21.511492+00	2026-07-18 09:57:21.511492+00	\N	1
2d40cdcc-9c78-4443-ad5b-97a7e77878f9	633e5918-8550-47ac-bd45-3c9137c7c278	{"name": "Cairo", "country": "Egypt", "area_km2": 3085, "latitude": 30.0444, "timezone": "EET", "longitude": 31.2357, "population": 10100000}	a9cb10bd926e6272ba62b47cb35c26cc8ef71c841fa27db8ee33522d01d42001	\N	t	2026-07-18 09:57:21.521016+00	2026-07-18 09:57:21.521016+00	\N	1
08226ffc-aa98-4e13-bcab-b9618572bb80	662e9ab1-ca65-437c-8a24-383abc071105	{"name": "Hydrogen", "group": 1, "period": 1, "symbol": "H", "category": "Nonmetal", "atomic_mass": 1.008, "atomic_number": 1}	6947a5b695ee48d723b337ec2643d223568372d8c1bca8644727adfb81f80a46	\N	t	2026-07-18 09:57:21.532746+00	2026-07-18 09:57:21.532746+00	\N	1
e232f409-52ea-4094-8d78-bd7a47c37d92	1811108d-ad7d-4017-83a7-938ac721248c	{"name": "Helium", "group": 18, "period": 1, "symbol": "He", "category": "Noble gas", "atomic_mass": 4.003, "atomic_number": 2}	5666c1084b72d9bc7ed5c5dae8b639c9454f57313f7925b98fc7c5a1d87c3bd6	\N	t	2026-07-18 09:57:21.541647+00	2026-07-18 09:57:21.541647+00	\N	1
8990ca5f-6683-4844-820d-c0451ac1a9bc	0fb4a712-ab31-453f-b93e-08d4e0f83f4c	{"name": "Carbon", "group": 14, "period": 2, "symbol": "C", "category": "Nonmetal", "atomic_mass": 12.011, "atomic_number": 6}	8bce96ddec15c594033cf62ce2d3a693c6be2f6ffde6489cfb5cf846eca27d8e	\N	t	2026-07-18 09:57:21.550508+00	2026-07-18 09:57:21.550508+00	\N	1
6d85d1aa-2268-479b-ac18-618e20b375e0	6cc33fec-18e4-48fe-9db9-020230afb680	{"name": "Oxygen", "group": 16, "period": 2, "symbol": "O", "category": "Nonmetal", "atomic_mass": 15.999, "atomic_number": 8}	b5d94e3aea18cfa3b08ea4b8c4aa7aae8f0dae630b6a44267c4ef614534b0746	\N	t	2026-07-18 09:57:21.560478+00	2026-07-18 09:57:21.560478+00	\N	1
df500c35-9f75-421b-940a-859413a24065	48431572-cf5d-4754-a1de-d2a01fc2c89d	{"name": "Iron", "group": 8, "period": 4, "symbol": "Fe", "category": "Transition metal", "atomic_mass": 55.845, "atomic_number": 26}	db99fa6937bb0a94d9def71dbab0ecc12dc7d2553f10b18458fd7d26d304bf60	\N	t	2026-07-18 09:57:21.569757+00	2026-07-18 09:57:21.569757+00	\N	1
34ab053e-48c8-422e-a327-1107426a5c6f	eaa986aa-84c1-48ec-ac97-e0a23ec820aa	{"name": "Gold", "group": 11, "period": 6, "symbol": "Au", "category": "Transition metal", "atomic_mass": 196.967, "atomic_number": 79}	2c8b55e43cc3829f34b378bfa39ddef89935a96d70f01b8418cac45e7ddd96f8	\N	t	2026-07-18 09:57:21.579716+00	2026-07-18 09:57:21.579716+00	\N	1
7105bcbf-64bf-4b26-972f-1655713e2b2b	ff7d0ff0-3495-4b2c-a23f-7e3c43c76363	{"name": "Silver", "group": 11, "period": 5, "symbol": "Ag", "category": "Transition metal", "atomic_mass": 107.868, "atomic_number": 47}	e820fa7462ab45af6b07bdfda55cf56a0a88f6a064149c2e3a84bcc6f0c7c25c	\N	t	2026-07-18 09:57:21.59274+00	2026-07-18 09:57:21.59274+00	\N	1
c79078ef-0a24-4d9c-809d-ac4235538f34	340d4476-80d9-420e-83ee-c1f7ed9ebb82	{"name": "Copper", "group": 11, "period": 4, "symbol": "Cu", "category": "Transition metal", "atomic_mass": 63.546, "atomic_number": 29}	0cc28ff024cfbbbcb80248b8880dc39631a99ef892cb2075e48a500195211466	\N	t	2026-07-18 09:57:21.60735+00	2026-07-18 09:57:21.60735+00	\N	1
fb3f67c1-a807-491c-85d4-9719e344d469	fbe2f02f-6182-4f5a-9486-6dd30a3bba1a	{"name": "Silicon", "group": 14, "period": 3, "symbol": "Si", "category": "Metalloid", "atomic_mass": 28.086, "atomic_number": 14}	cdee9c53879f73513ec8d28f231a7e578e7e4499c8835991c0a0866030f7af1a	\N	t	2026-07-18 09:57:21.62033+00	2026-07-18 09:57:21.62033+00	\N	1
8c773f24-2d0d-4179-bdd7-041f441cc1b3	ca3b66fa-10b6-403f-9292-4e876c63ce8d	{"name": "Uranium", "group": 0, "period": 7, "symbol": "U", "category": "Actinide", "atomic_mass": 238.029, "atomic_number": 92}	9fd08eaf314c0466d86f077efad50694762f55f8a94a64a0387ae9d7cd16fb98	\N	t	2026-07-18 09:57:21.631722+00	2026-07-18 09:57:21.631722+00	\N	1
2ddc1e54-b3df-41bf-8148-a094dc77284a	9b5004ab-ee6c-4645-ac89-42f2bc1c4e81	{"diet": "Herbivore", "name": "African Elephant", "class": "Mammalia", "habitat": "Savanna", "species": "Loxodonta africana", "lifespan_years": 70}	e052d22ef74c8c9fb9de74b648d8b65186b4f64583fbc6f2e754f5bb54355c6c	\N	t	2026-07-18 09:57:21.648077+00	2026-07-18 09:57:21.648077+00	\N	1
c3f704c7-653c-48d1-a878-a11b7e1a2469	56b4c4f1-19c8-45e1-9b5c-232636e2a7fe	{"diet": "Krill", "name": "Blue Whale", "class": "Mammalia", "habitat": "Ocean", "species": "Balaenoptera musculus", "lifespan_years": 90}	eaa6c06bfc4db1c4dbeec7194aeb87912d40c00055692bfd5db766a0b88482bf	\N	t	2026-07-18 09:57:21.66177+00	2026-07-18 09:57:21.66177+00	\N	1
ca657812-c695-4f3f-84e6-35415e60a593	76c3b6cb-549b-4e5e-886e-b8a7491fdd4f	{"diet": "Carnivore", "name": "Golden Eagle", "class": "Aves", "habitat": "Mountains", "species": "Aquila chrysaetos", "lifespan_years": 30}	2502a175149776104d07d241918998e64d33c3e41f6086d00da83910f7d228ab	\N	t	2026-07-18 09:57:21.675625+00	2026-07-18 09:57:21.675625+00	\N	1
d590d37a-a12d-4c9c-9b22-c1cf9e5dbcb9	ff787e6b-348f-4de9-a0d8-5b18027b84f1	{"diet": "Carnivore", "name": "Gray Wolf", "class": "Mammalia", "habitat": "Forest", "species": "Canis lupus", "lifespan_years": 8}	4b3bacf6a3fdbd59ed51ed433301f1c819dff9507c52f11e88764207225358c0	\N	t	2026-07-18 09:57:21.688292+00	2026-07-18 09:57:21.688292+00	\N	1
fb216036-23a4-4707-b83c-2bbc2aee8848	698d6867-9ad6-4860-bd88-cf6b699b15d8	{"diet": "Carnivore", "name": "Polar Bear", "class": "Mammalia", "habitat": "Arctic", "species": "Ursus maritimus", "lifespan_years": 25}	f89145d5a49f62c77a0c23df1da82ee1a9fbd7a9139e4142e035fe524f6159e5	\N	t	2026-07-18 09:57:21.700227+00	2026-07-18 09:57:21.700227+00	\N	1
4d14796b-4a10-4248-9994-17dc406708cc	5d963c05-3b5b-4016-b3d7-0e1451954363	{"diet": "Carnivore", "name": "Bald Eagle", "class": "Aves", "habitat": "Coastal", "species": "Haliaeetus leucocephalus", "lifespan_years": 20}	a9ca87447af6e58ffc27563d32e98376dac58ef1159b9491bba9bfc6fec5aa1f	\N	t	2026-07-18 09:57:21.710945+00	2026-07-18 09:57:21.710945+00	\N	1
217793df-0bc1-42bd-8730-11a0f3107588	f935e10f-3b17-4948-9fbc-0415715c71b6	{"diet": "Carnivore", "name": "Snow Leopard", "class": "Mammalia", "habitat": "Mountains", "species": "Panthera uncia", "lifespan_years": 15}	03a3075cdf28316b0e072d5b3b0ad9a94a7ce2f97e94209b4797d932c0ba614f	\N	t	2026-07-18 09:57:21.721277+00	2026-07-18 09:57:21.721277+00	\N	1
a92f731a-c488-4bc7-9ec8-a75d171f9356	e6ed7062-4701-440c-ad10-5b32894a4600	{"diet": "Herbivore", "name": "Red Panda", "class": "Mammalia", "habitat": "Forest", "species": "Ailurus fulgens", "lifespan_years": 12}	fe140ee290b6e45ad09242a76ef4d3a4acb607ab3f4aa6eb8ebe67d51c0329af	\N	t	2026-07-18 09:57:21.731751+00	2026-07-18 09:57:21.731751+00	\N	1
e4581d20-4dfb-485c-ba10-b625e93b94f8	0e95eb38-1845-4fd7-99d0-ca3470daaffb	{"diet": "Carnivore", "name": "Bengal Tiger", "class": "Mammalia", "habitat": "Jungle", "species": "Panthera tigris tigris", "lifespan_years": 15}	dea5c4f15635eaf96d9dea64e17d28ab660351536609d74cbbdde67ec7179ac1	\N	t	2026-07-18 09:57:21.742899+00	2026-07-18 09:57:21.742899+00	\N	1
98ce3b19-b288-42be-af0d-5b5f3ae6dedf	2e216ce0-d2ca-4d47-9bf1-9a18f96f8f7f	{"diet": "Piscivore", "name": "Emperor Penguin", "class": "Aves", "habitat": "Antarctic", "species": "Aptenodytes forsteri", "lifespan_years": 20}	64e95492f623811297f3fd6c88f6253ea89996ff43e76d96c96745d4fa7adb65	\N	t	2026-07-18 09:57:21.75427+00	2026-07-18 09:57:21.75427+00	\N	1
96682176-cc63-4eed-b3f3-f94a9c009445	691ea7b5-96c0-46b3-b1db-9747945d4a1c	{"name": "Giant Sequoia", "family": "Cupressaceae", "habitat": "California mountains", "species": "Sequoiadendron giganteum", "height_cm": 84000}	2f035e57d33c6cc31187cddf04759d0ea51517649265052eff01a00356cdba76	\N	t	2026-07-18 09:57:21.767591+00	2026-07-18 09:57:21.767591+00	\N	1
2e80b37a-82d1-4b97-a8df-a157703736af	bb2b1095-c577-496f-899e-5fc2f5859750	{"name": "Baobab", "family": "Malvaceae", "habitat": "African savanna", "species": "Adansonia digitata", "height_cm": 2500}	9eb14ef86800cf404760db40d87c3da8d1aecc4b037687b0d7ff815a05d2b045	\N	t	2026-07-18 09:57:21.778655+00	2026-07-18 09:57:21.778655+00	\N	1
d903bd01-b76e-449d-abf1-47f45c72960c	9e9c85a0-08a3-4493-b145-804f2d047236	{"name": "Giant Kelp", "family": "Laminariaceae", "habitat": "Ocean", "species": "Macrocystis pyrifera", "height_cm": 4500}	52ab9190b9765da4497f47d7b6a71ff5a8e71340b31314eaa87645c95db99fa0	\N	t	2026-07-18 09:57:21.789219+00	2026-07-18 09:57:21.789219+00	\N	1
4b676d9a-70b1-4d4e-bfa9-90c436ebcfad	bb132a86-fb6a-4aaa-be7d-87b9d97a0d0e	{"name": "Joshua Tree", "family": "Asparagaceae", "habitat": "Desert", "species": "Yucca brevifolia", "height_cm": 1500}	1b6d285119d35e579d881e577a89a3839e7a367072da7cf388b8e867cf6068d7	\N	t	2026-07-18 09:57:21.800738+00	2026-07-18 09:57:21.800738+00	\N	1
462379e4-397b-4a99-98b1-02bc235c0885	e820b1e0-7cd9-4812-9def-13f38b74b680	{"name": "White Oak", "family": "Fagaceae", "habitat": "Eastern North America", "species": "Quercus alba", "height_cm": 3000}	fae9a71f339d8f0a33f561b52ee13ba7111ab189a9443c1f09bea64db94558e1	\N	t	2026-07-18 09:57:21.81176+00	2026-07-18 09:57:21.81176+00	\N	1
bd41a1cf-8628-4b3f-9902-f0d1d9d301f3	7f121e6e-8aff-4e69-bbc0-6fa87395ff72	{"name": "Bamboo", "family": "Poaceae", "habitat": "Asia", "species": "Bambusoideae", "height_cm": 3000}	de89068e568b196a7e33d950322dae2e67d3e48e7e8073a8b2dc2432667a120c	\N	t	2026-07-18 09:57:21.822909+00	2026-07-18 09:57:21.822909+00	\N	1
2fe6f9f2-e1ea-4382-ad55-271638b02bd8	14288787-14a7-4ab9-ad5c-183eddec64db	{"name": "Sunflower", "family": "Asteraceae", "habitat": "Fields", "species": "Helianthus annuus", "height_cm": 300}	3a0a91aec1509420dec671f0f1c95212bf535b1a0fd6c8886c2748ded5468f78	\N	t	2026-07-18 09:57:21.835272+00	2026-07-18 09:57:21.835272+00	\N	1
62a51e15-fc41-47ee-afa9-b1984073d7a9	39685c95-2370-4220-a7cf-cd2c000c0e89	{"name": "Royal Palm", "family": "Arecaceae", "habitat": "Tropics", "species": "Roystonea regia", "height_cm": 2500}	8668ea60137941c125a20b60e9639c5b48f82240f5c31cdb351640d1d0e63022	\N	t	2026-07-18 09:57:21.847608+00	2026-07-18 09:57:21.847608+00	\N	1
4cde88b2-dca0-4608-8e62-c1c27f9fbe62	658b6544-3abf-4100-99da-c3582796686d	{"name": "Ginkgo", "family": "Ginkgoaceae", "habitat": "China", "species": "Ginkgo biloba", "height_cm": 3500}	c6c706a0767d113e06cf06325f016f6b014ef07d0c7ce0d70e518b4b04c0192d	\N	t	2026-07-18 09:57:21.85965+00	2026-07-18 09:57:21.85965+00	\N	1
4e61a4b9-4a9a-4d8b-bd88-03a696fe3ce3	bd2ecd74-769a-4077-b2da-ae1942afbdd9	{"name": "Venus Flytrap", "family": "Droseraceae", "habitat": "Wetlands", "species": "Dionaea muscipula", "height_cm": 15}	ee8f1c09f14d6480cdbb5da2e6c0ff009d74ab60dea9b0c4913558cd69edf832	\N	t	2026-07-18 09:57:21.869769+00	2026-07-18 09:57:21.869769+00	\N	1
b744adee-98cf-4803-a75d-f60fa9d5595e	c091d95b-4161-4182-8d81-2b3faa79ad33	{"year": 1969, "genre": "Rock", "label": "Apple Records", "title": "Abbey Road", "artist": "The Beatles", "tracks": 17}	966a2e4bcd786453629486520437a4f9e0bd04681f7171bfb399e3eedc05a719	\N	t	2026-07-18 09:57:21.882773+00	2026-07-18 09:57:21.882773+00	\N	1
bed7fbee-aac4-42c2-9a66-67d25457fa8a	d6b119f8-2127-479c-b764-f8abe396fe7e	{"year": 1973, "genre": "Progressive Rock", "label": "Harvest", "title": "The Dark Side of the Moon", "artist": "Pink Floyd", "tracks": 10}	ca5aca3572159a53e7d635c52cbe67a3f8d248297dff31c8d0f2877e258b6168	\N	t	2026-07-18 09:57:21.893759+00	2026-07-18 09:57:21.893759+00	\N	1
4adb3221-5025-4834-8572-d58660914a5f	30f7c20a-be19-4c4b-9921-fcc85cb9dd7d	{"year": 1982, "genre": "Pop", "label": "Epic", "title": "Thriller", "artist": "Michael Jackson", "tracks": 9}	867363f2e2975eecc768315d7eb129e7432dec003107048ee682732b0d9a25dd	\N	t	2026-07-18 09:57:21.904368+00	2026-07-18 09:57:21.904368+00	\N	1
afbad02e-a01e-4c95-9d6e-7c2483ad8d8e	38d8fab1-ecd2-4b12-a1b2-9d2962b49444	{"year": 1991, "genre": "Grunge", "label": "DGC", "title": "Nevermind", "artist": "Nirvana", "tracks": 12}	61ce559f08b0ceda03d0e58f9dc1e1646055e1e7baf0976638d9850895fb0453	\N	t	2026-07-18 09:57:21.915053+00	2026-07-18 09:57:21.915053+00	\N	1
bfefae80-082e-46f8-82a5-e52ed94ee186	5fc5cdd8-f97a-4f31-8c32-676370d8f861	{"year": 1971, "genre": "Rock", "label": "Atlantic", "title": "Led Zeppelin IV", "artist": "Led Zeppelin", "tracks": 8}	70780abe9edde4dba0c65706ac4e2469dd6818a7938424caa6afeae760c5dc29	\N	t	2026-07-18 09:57:21.926473+00	2026-07-18 09:57:21.926473+00	\N	1
272b943a-c623-4eb5-b878-e157ca7ad5cf	97bf1bf4-77eb-4d67-bbb3-002b55ea5f67	{"year": 1977, "genre": "Rock", "label": "Asylum", "title": "Hotel California", "artist": "Eagles", "tracks": 9}	5f0df256496f7656d3d9e71dcecd021f777fb3760cd108089c72a24df6bc2924	\N	t	2026-07-18 09:57:21.938184+00	2026-07-18 09:57:21.938184+00	\N	1
bb8ddeca-2edf-47bd-8c7d-18364569f241	cc021081-81e6-47db-8ce0-45c289a0bf68	{"year": 1979, "genre": "Progressive Rock", "label": "Harvest", "title": "The Wall", "artist": "Pink Floyd", "tracks": 26}	2dc4d756270db6a5b3f8164447c3a34e22eac36339318c14fa7316dda9a401d1	\N	t	2026-07-18 09:57:21.948988+00	2026-07-18 09:57:21.948988+00	\N	1
656ee4f8-0ef5-4e9d-b73d-9fe72a169f0c	796ffc37-f24a-4577-8179-8aeeae0309ac	{"year": 1997, "genre": "Alternative Rock", "label": "Parlophone", "title": "OK Computer", "artist": "Radiohead", "tracks": 12}	6b22715df81b0e0c8682e6cdbbecb37afd6c2ad33e2d0f1fabb4aa37620b0030	\N	t	2026-07-18 09:57:21.958116+00	2026-07-18 09:57:21.958116+00	\N	1
12c81eec-000c-484e-8838-47b76f41d585	b46e55bb-dd8d-4604-a437-1956e242b71e	{"year": 1977, "genre": "Rock", "label": "Warner Bros.", "title": "Rumours", "artist": "Fleetwood Mac", "tracks": 11}	0f0ffaa5fb78901d515d167e772c9ec8c45b1dc4ac61c99b37227dc41e770174	\N	t	2026-07-18 09:57:21.966491+00	2026-07-18 09:57:21.966491+00	\N	1
63e0b739-c3d7-4e92-9abd-7e20a8e29882	7505ba61-0eaa-4482-a1cf-dd135fe2a7a7	{"year": 1980, "genre": "Hard Rock", "label": "Atlantic", "title": "Back in Black", "artist": "AC/DC", "tracks": 10}	4bf604cd896ec92678d97a69e93fe76388a32ac3d0e2b8bd3dc7add3618d3da9	\N	t	2026-07-18 09:57:21.975101+00	2026-07-18 09:57:21.975101+00	\N	1
e6cd4527-a4f3-4356-a165-f2c466c6afbd	89d59b56-c7e7-4faa-8072-3d1b54be1809	{"name": "Artificial Intelligence", "domain": "Technology", "definition": "Field of computer science creating intelligent machines"}	c88f99b0b4247f083b9192db44e9d6c7e73cf6106905b58d7c5fac3ec951c5fc	\N	t	2026-07-18 09:57:21.987963+00	2026-07-18 09:57:21.987963+00	\N	1
4cc8746d-9594-41ff-a735-e1e079b2ec3d	c9c63950-7212-4d16-8b2a-11c2c053afbd	{"name": "Quantum Computing", "domain": "Technology", "definition": "Computing using quantum mechanical phenomena"}	142e82631545519d8ddf95b46f36acd5b180fcbb3c75eb68e6cd654c8c5907f2	\N	t	2026-07-18 09:57:22.000404+00	2026-07-18 09:57:22.000404+00	\N	1
182f0171-b10d-4db9-b7bb-76c79a37b7db	d9ce1ef3-f6c2-4c02-b1af-049da351b72d	{"name": "Blockchain", "domain": "Technology", "definition": "Distributed ledger technology"}	67f5078f2803a59f4cda674b050a46a341d7e1068cf71c01b48d5f9b427e6357	\N	t	2026-07-18 09:57:22.011023+00	2026-07-18 09:57:22.011023+00	\N	1
5f56d142-e94e-4b19-8b88-ef746d37bb9d	95a4d283-f9dc-4658-8b2c-4e016f11d984	{"name": "Existentialism", "domain": "Philosophy", "definition": "Philosophy focusing on individual freedom and responsibility"}	a6ff41140063fc6b7263fc8f7b7dbb796e4ca810fc9e4d02b4de1434879d3441	\N	t	2026-07-18 09:57:22.022467+00	2026-07-18 09:57:22.022467+00	\N	1
bda78736-14de-4b8c-8465-27c20d8873d4	ea489444-826d-42bf-926f-cfc26a2ac273	{"name": "Democracy", "domain": "Politics", "definition": "System of government by the people"}	bc7006a7ae08ecadcdaac4e215af639fc76daa6878eee10bcf10340747699a54	\N	t	2026-07-18 09:57:22.034581+00	2026-07-18 09:57:22.034581+00	\N	1
fe652c2a-ed8c-457a-bd1b-0bb422606705	342f4e39-d5e0-404e-a50b-31726355d4dd	{"name": "Globalization", "domain": "Economics", "definition": "Process of increasing world interconnectedness"}	d4e3477c0ecf9174acf917204305ddefe089c86cd9d204af794f4d41c660a078	\N	t	2026-07-18 09:57:22.046629+00	2026-07-18 09:57:22.046629+00	\N	1
eb0080d8-93f2-47c1-a580-769ef47dc91e	e73db2ac-5278-4e94-9762-cb5cfbf0ec51	{"name": "Climate Change", "domain": "Science", "definition": "Long-term change in Earth's climate system"}	3fb0872ee6ef4cba497cdf0f4c837d10066f4f37fd23164383ce7a71db50e38d	\N	t	2026-07-18 09:57:22.073401+00	2026-07-18 09:57:22.073401+00	\N	1
273016cd-71d9-4dee-9adf-e66831a9bb2a	59a4e861-91f7-4c7c-9d95-f71e625d2be4	{"name": "Surrealism", "domain": "Art", "definition": "Art movement based on the unconscious mind"}	3f7ddb1df71dfd99d1cfb1754ead8d490515f5ad5d005a8183d1f55790e18b66	\N	t	2026-07-18 09:57:22.084898+00	2026-07-18 09:57:22.084898+00	\N	1
f4107b52-796c-4784-9bc4-82a5ed6ba133	30e2bd9e-ff63-4844-89ed-7db7a5f5ad3e	{"name": "Stoicism", "domain": "Philosophy", "definition": "Ancient Greek philosophy of self-control"}	f99157fd66a0ccb2586735bcbeb0f6f701e07b139f3d80c4c608d209b2e75f41	\N	t	2026-07-18 09:57:22.095595+00	2026-07-18 09:57:22.095595+00	\N	1
92d349d5-8c47-4c46-b8a7-0f84061d25ba	12834bac-4e52-44c1-98cb-1cab7f711c77	{"name": "Science Fiction", "category": "Literature/Cinema", "origin_period": "19th century"}	1e7a2176e47e8697e15cdbf17a41c7f8b6d51823c4f58c12871b60b00d45fe3f	\N	t	2026-07-18 09:57:22.108347+00	2026-07-18 09:57:22.108347+00	\N	1
01cef49b-3ed2-4248-b796-4f2ae9750c62	a548327c-970e-4dbc-a1fc-0fab50b45be0	{"name": "Film Noir", "category": "Cinema", "origin_period": "1940s"}	eac56ba43fbf919ff7e95b31a41be7e08e1915e675d6a55f20951d091fb6db0f	\N	t	2026-07-18 09:57:22.119442+00	2026-07-18 09:57:22.119442+00	\N	1
5ca0dc4e-c7bc-4787-95c2-a78953905e1a	72e10176-55b6-4146-8a70-8b9540a1760c	{"name": "Progressive Rock", "category": "Music", "origin_period": "Late 1960s"}	f8fb7aa5c179b4549791e5543c8da3f407592d745c844254b12c52740703492c	\N	t	2026-07-18 09:57:22.130376+00	2026-07-18 09:57:22.130376+00	\N	1
4f2f58ce-3787-4ee4-9593-d7adce20a8e8	a0291632-4fb9-499e-b95a-64a6420e1d89	{"name": "Grunge", "category": "Music", "origin_period": "Mid-1980s"}	9c61319518dfb79e5b437e6642dfe90a55835847401b25696ac6d301daf79618	\N	t	2026-07-18 09:57:22.141034+00	2026-07-18 09:57:22.141034+00	\N	1
4fa6511f-a71a-4047-ac86-8a91ffc1305d	338c5eba-772e-46fe-b551-bb49eb38c8fb	{"name": "Dystopia", "category": "Literature", "origin_period": "20th century"}	b046b9d59c499e1536d2d6e8bfe8f2066692d99986b5e48aa4c390a1c11acc31	\N	t	2026-07-18 09:57:22.154716+00	2026-07-18 09:57:22.154716+00	\N	1
ca21fa0f-1223-4851-ad05-4ce7e6b02351	2408b634-b332-4112-a7bc-09e60702294a	{"name": "Reggae", "category": "Music", "origin_period": "Late 1960s"}	3a5c17e26015f67258f223899e095eaa34c499df1dfda1e463d203d2e2e8821f	\N	t	2026-07-18 09:57:22.167583+00	2026-07-18 09:57:22.167583+00	\N	1
3f738259-12d1-4b18-b767-71542c03f3c8	f8810f29-7612-4de5-9943-4b7cded8e22e	{"name": "Hard Rock", "category": "Music", "origin_period": "Mid-1960s"}	b8a279824cd1cede5874e5f48a0f118281d596423282c91140855a3500324d6b	\N	t	2026-07-18 09:57:22.179007+00	2026-07-18 09:57:22.179007+00	\N	1
c61a4d7b-047e-42d4-bab1-59bae1501dea	3feb5117-24aa-48e6-a418-4bfbbf0c5559	{"name": "Impressionism", "category": "Visual Art", "origin_period": "1860s"}	ad65c0004c8cfe3ec7cbaeefbec2c0cae28e38dbf2b9d623e2a9a61599711609	\N	t	2026-07-18 09:57:22.189693+00	2026-07-18 09:57:22.189693+00	\N	1
f89de155-3693-4cd2-b655-33e2297b5288	d34e2a47-812c-49a8-be50-0789dccd5e15	{"name": "Baroque", "category": "Art/Music", "origin_period": "17th century"}	bd0c1d69f891ebbd1bc51cada2ee6d243ed41d81e5a28b55d0613fec14427eb8	\N	t	2026-07-18 09:57:22.202084+00	2026-07-18 09:57:22.202084+00	\N	1
8fb8aa49-8cc7-4aae-aa83-ec25b7893651	3c126f80-3c16-485d-bff6-3e4f33cc954a	{"name": "Cyberpunk", "category": "Literature/Cinema", "origin_period": "1980s"}	6de98806de6c2ed5b57fb2290599e42c29b4281f969f14b7d94221af854db2df	\N	t	2026-07-18 09:57:22.214286+00	2026-07-18 09:57:22.214286+00	\N	1
c114c269-891f-4208-ba06-f1cf2f7bc638	169a1041-9c54-46ad-88ed-b629a8c0f575	{"name": "Aurora Borealis", "category": "Natural", "description": "Light display in polar regions caused by charged particles"}	450670070b81440e3d819fdbefb93242d5947ad4247c122de887fa56f98f9bec	\N	t	2026-07-18 09:57:22.229266+00	2026-07-18 09:57:22.229266+00	\N	1
1f57c311-3592-4e6a-a0ea-349fdf10e2b1	f30f4ca7-c575-4f00-a5f5-dd6674882523	{"name": "Gravity", "category": "Physical", "description": "Force of attraction between objects with mass"}	2ee893ac44fa97bb47bdf9cd906b25404a6f018d3632fc3dca8bf00efa83714a	\N	t	2026-07-18 09:57:22.242832+00	2026-07-18 09:57:22.242832+00	\N	1
6f9b22bf-a9bc-42d9-a915-995b8d3342b8	f0755ad0-ed8d-4ff9-ac6d-5f4d16d78395	{"name": "Photosynthesis", "category": "Biological", "description": "Process converting light energy to chemical energy in plants"}	457686da587ae95667c81a7460e9ec01c9ddfc516c08dba0804305c7d5a53703	\N	t	2026-07-18 09:57:22.254089+00	2026-07-18 09:57:22.254089+00	\N	1
2c4e1ee8-598a-44fd-989c-9930b9fa41bd	07f2738a-6483-4614-b960-d841e7534792	{"name": "Evolution", "category": "Biological", "description": "Process of change in living organisms over generations"}	7a84a4b814afb91dbf746f34874880245c9231b5d78be4afb223e9dfe8e5bc36	\N	t	2026-07-18 09:57:22.265373+00	2026-07-18 09:57:22.265373+00	\N	1
7d3b2c28-4643-4b88-af3c-0dcd6e162eba	9db0c533-dc6c-4d55-894e-b82a3dda258c	{"name": "Quantum Entanglement", "category": "Physical", "description": "Quantum phenomenon where particles become correlated"}	77ce1004ab3ab45ccd22bce1479664d072ac5ce4d14a9f6a5296dfe756f9964d	\N	t	2026-07-18 09:57:22.278207+00	2026-07-18 09:57:22.278207+00	\N	1
5024706a-e93b-4c7c-ada0-3c933267fbdc	9d44343f-0c8f-4703-b19b-9be0c3252020	{"name": "Black Hole", "category": "Astronomical", "description": "Region of spacetime with extreme gravitational pull"}	a8c062639e3817383db0ae454a071f9091b4e95448f68c7a4ee726207059c866	\N	t	2026-07-18 09:57:22.29154+00	2026-07-18 09:57:22.29154+00	\N	1
b8cfec6c-0519-49d4-aa99-5cccfd83b6a2	7e7f708f-f084-4de5-99e5-2314c0f22da6	{"name": "Tornado", "category": "Meteorological", "description": "Violently rotating column of air"}	3b797cb3ec8fe51ca5ce53bfd6483bce592a71933f8fc504c907e7d4b3253246	\N	t	2026-07-18 09:57:22.30361+00	2026-07-18 09:57:22.30361+00	\N	1
77d4a300-ef55-40cf-ac85-63355b88fd69	f3229d89-5e9a-4381-9c23-77445a9dd63c	{"name": "Continental Drift", "category": "Geological", "description": "Movement of Earth's continents over geological time"}	fb8cc05e89c95762c829aa899b6dc6eb2e13cb1a78d3f3e85c4f1cf06237bb6a	\N	t	2026-07-18 09:57:22.316103+00	2026-07-18 09:57:22.316103+00	\N	1
e9dbac78-e489-4577-b6a6-85601b7cf553	92cc7207-261c-4da4-8ad5-da2a7d6da33a	{"name": "Dreaminess", "category": "Psychological", "description": "State of being lost in pleasant thoughts"}	f732e171fb3aa6997df638c3d340deaa020666fa44849cf76f83fe07e370d243	\N	t	2026-07-18 09:57:22.327524+00	2026-07-18 09:57:22.327524+00	\N	1
d8e9fbc2-4760-4f56-ad65-004abfb2346d	cadd0952-b817-4e2a-be79-241cc8884ecc	{"name": "Aurora Australis", "category": "Natural", "description": "Southern hemisphere light display"}	32349716bff5458f52832bb93284c7be1607a0bc497a0cd894f31ed2e85be1c1	\N	t	2026-07-18 09:57:22.339452+00	2026-07-18 09:57:22.339452+00	\N	1
e28e0350-7c06-4bb9-8304-bb6c657f1171	1f41633c-5685-41d0-9463-6444561e2361	{"name": "Ancient Rome", "region": "Mediterranean", "end_year": 476, "start_year": -753, "significance": "Foundation of Western civilization"}	e776a95e0888a21c4dd1196d40d4d023e2025350656199b5b67dbe275cc2a723	\N	t	2026-07-18 09:57:22.351858+00	2026-07-18 09:57:22.351858+00	\N	1
58c93a30-de6a-4162-b5ba-ec7509eb4228	deca7c7e-7ce2-481d-b884-2b5ce6a71121	{"name": "Middle Ages", "region": "Europe", "end_year": 1500, "start_year": 500, "significance": "Feudalism and religious influence"}	782e8779eef31113d02d926b460413963f8c251f66b16c6c043172029fd8b881	\N	t	2026-07-18 09:57:22.360793+00	2026-07-18 09:57:22.360793+00	\N	1
0213d872-40de-46b8-bfca-27ad9c991f47	13b03b32-816d-466e-83a9-953056d1db1c	{"name": "Industrial Revolution", "region": "Worldwide", "end_year": 1840, "start_year": 1760, "significance": "Transformation of manufacturing"}	82dde7097c18c6aaad7becfb8751863ff7c1123eb1bf1f41832ceee883b50e52	\N	t	2026-07-18 09:57:22.369719+00	2026-07-18 09:57:22.369719+00	\N	1
c0ba0bf6-2de7-44b6-a31d-14b5617be7cf	79ce2715-0539-4551-895a-5d9655496909	{"name": "Cold War", "region": "Worldwide", "end_year": 1991, "start_year": 1947, "significance": "Bipolar world order"}	43eb139a3be8d742a27a91ea037a564807b59c69ec9fcb3990cc825fc3f2ec1a	\N	t	2026-07-18 09:57:22.378225+00	2026-07-18 09:57:22.378225+00	\N	1
c843b12d-eed4-45b4-b377-0f085b59d350	e1744e48-0205-4462-859a-67308c0b4972	{"name": "Renaissance", "region": "Europe", "end_year": 1600, "start_year": 1300, "significance": "Cultural and intellectual rebirth"}	33b948391095be440a39115561cc333dbdcc393bb822b541f92669d19ef27b94	\N	t	2026-07-18 09:57:22.386631+00	2026-07-18 09:57:22.386631+00	\N	1
3cbb2a7e-3545-444e-abc1-c8ad60b7e21b	5c283836-5b41-4203-837f-9897202e745f	{"name": "Age of Enlightenment", "region": "Europe", "end_year": 1815, "start_year": 1685, "significance": "Rise of reason and science"}	26041dc9f890683380b33fb6c5abb9416f6dd6c1fab7e2d8fc36e8af312ddd57	\N	t	2026-07-18 09:57:22.395043+00	2026-07-18 09:57:22.395043+00	\N	1
2e281501-4bcb-42e7-abd7-3de506fad797	e3a89c24-eebb-4d7c-a5c1-0d3be182d37e	{"name": "Digital Age", "region": "Worldwide", "end_year": 2026, "start_year": 1970, "significance": "Information technology revolution"}	82b10fa84621ebd30057d628bae236811dab04c5ee3a9d549dcece4f8aadb16a	\N	t	2026-07-18 09:57:22.405351+00	2026-07-18 09:57:22.405351+00	\N	1
3a238516-7021-40e5-8204-db410b8c2056	7c7efeb5-8843-4ab1-8223-16c1dfcc3f60	{"name": "Space Age", "region": "Worldwide", "end_year": 2026, "start_year": 1957, "significance": "Human space exploration"}	aa0701972375feafec7b034fe9267ff51376c48ec37152e5c75ed25d59121064	\N	t	2026-07-18 09:57:22.417593+00	2026-07-18 09:57:22.417593+00	\N	1
4270d084-7f1e-4a0a-93e8-ed2350d2e30b	d31be51f-c2b2-4489-990d-e907eea9eee1	{"name": "World War II", "region": "Worldwide", "end_year": 1945, "start_year": 1939, "significance": "Largest conflict in human history"}	59924a7e9fe98eac49bb61f1ea2067590b242ebc9ad5b653a6bab625605a9607	\N	t	2026-07-18 09:57:22.426562+00	2026-07-18 09:57:22.426562+00	\N	1
3679f6f8-b40a-493c-a1e1-2ce882293525	8255be6e-d5b3-4a82-82ab-f3c1100ffc12	{"name": "Victorian Era", "region": "British Empire", "end_year": 1901, "start_year": 1837, "significance": "Peak of British Empire"}	039cc1b4e7b4ac96386df3f20b8414731f5c6c0765a8f91e63a0194781bcdada	\N	t	2026-07-18 09:57:22.435838+00	2026-07-18 09:57:22.435838+00	\N	1
74ce8889-7fec-4bce-aad6-1eb495056617	820103ab-0386-4a62-8f3e-e6a579dc9007	{"name": "README.md", "format": "Markdown", "size_kb": 15.3, "category": "Documentation"}	5b3b00040daf616c81abbaf1da9a817d7565fb9d02052f80146f6702c92fa370	\N	t	2026-07-18 09:57:22.446485+00	2026-07-18 09:57:22.446485+00	\N	1
24c3b758-b344-4ad8-a596-c6c00a7e4e8c	35e56d3e-ea70-4211-9982-cc6aefb0e274	{"name": "schema.sql", "format": "SQL", "size_kb": 48.7, "category": "Database"}	955b95b1c0cab4c08b586f9596568089870ebfbf0247081b32be3753ff39dabd	\N	t	2026-07-18 09:57:22.455775+00	2026-07-18 09:57:22.455775+00	\N	1
72de272d-5e4b-4c8e-91bc-326bddb2fa02	6d93b85d-a853-44e8-a52b-08f09ace7f7b	{"name": "config.yaml", "format": "YAML", "size_kb": 2.1, "category": "Configuration"}	80c53a9420fb3235aee151e99921f60aec31cb3635dd4b2eb50fa2bae67e1cdb	\N	t	2026-07-18 09:57:22.465059+00	2026-07-18 09:57:22.465059+00	\N	1
d1d50126-fe86-4c60-b85f-42bfa16283fb	63f0b520-fb6e-4757-a25c-17ad2f056fb2	{"name": "docker-compose.yml", "format": "YAML", "size_kb": 1.8, "category": "Infrastructure"}	6b0ae5fbaab9310ac9ea84eaa79e0571823f093127f0c29948a17a0cca492f90	\N	t	2026-07-18 09:57:22.47405+00	2026-07-18 09:57:22.47405+00	\N	1
978f3768-7070-4e93-864d-5c956a16b7dc	fadfcb95-3bfe-42e1-9d65-1cc339178d7e	{"name": "main.py", "format": "Python", "size_kb": 12.5, "category": "Source Code"}	dd76631e56ef3526847619d8cf7b53146cb59b1517260a4b19992bcf0dc04900	\N	t	2026-07-18 09:57:22.483669+00	2026-07-18 09:57:22.483669+00	\N	1
09f85c9d-76c9-4c86-a484-4042a3f212bd	ef876a39-92b7-430f-8949-4a92c763a2b6	{"name": "models.py", "format": "Python", "size_kb": 8.2, "category": "Source Code"}	99cc11812fa77b21f8939894d3bc3ee40be53d6d9781c079537134e42baacafc	\N	t	2026-07-18 09:57:22.492496+00	2026-07-18 09:57:22.492496+00	\N	1
0904d409-7946-49a2-8a0d-e7eb357f0a82	e2bcc25d-98fa-47b6-82b7-05259f93bf9e	{"name": "requirements.txt", "format": "Text", "size_kb": 0.5, "category": "Configuration"}	a73be9c9a17385ee7420697058f98657090c7a5b352d06dd741626131cd0c9ff	\N	t	2026-07-18 09:57:22.501782+00	2026-07-18 09:57:22.501782+00	\N	1
10b8a296-edfa-45bd-9454-433162e5f864	f0c4228a-f224-4022-a763-8e44babb1cf8	{"name": "Dockerfile", "format": "Docker", "size_kb": 0.8, "category": "Infrastructure"}	357be3595d98fc8216f3798685615df7bc358e2189b8de75b01dff251d2ed31f	\N	t	2026-07-18 09:57:22.51033+00	2026-07-18 09:57:22.51033+00	\N	1
a890c48c-e7da-4ef2-9f9f-428a6e6f3303	18a3742e-d28b-4e8d-9cc7-a3b723c7c35f	{"name": "index.html", "format": "HTML", "size_kb": 5.4, "category": "Frontend"}	992ecd154340d52510755921c7b4074a3662a670839ec0ba00f25824017c3ea5	\N	t	2026-07-18 09:57:22.518925+00	2026-07-18 09:57:22.518925+00	\N	1
d41c8dd1-4d06-450d-8a63-25fc81e08250	6d69a2b9-a1ad-4cb0-8e64-16f8327d1479	{"name": "style.css", "format": "CSS", "size_kb": 3.7, "category": "Frontend"}	a3982b072cafc947527881eac5a1e55fd29b63086f6be283c51b66c47230b1a5	\N	t	2026-07-18 09:57:22.528109+00	2026-07-18 09:57:22.528109+00	\N	1
6954ce17-b23e-45cc-930c-46a628e18521	1b68253c-bd69-4485-bde3-8984aa16db27	{"name": "Beat Generation", "origin": "USA", "period": "1950s", "description": "Rebellious literary movement"}	6aedc1eb59731b0f21d30770bac38586a020d60d6f6a87f0745c0c7430821f20	\N	t	2026-07-18 09:57:22.540359+00	2026-07-18 09:57:22.540359+00	\N	1
1b350de5-4b0e-4c94-b5e5-20d7dda3c1fc	2ff1ea42-8b82-4e46-bb6f-23ea77f573e6	{"name": "Romanticism", "origin": "Europe", "period": "Late 18th century", "description": "Emphasis on emotion and individualism"}	cceadf64e72d13e6734308bdd2543ca6919857e6264340be808aa25a87de9a97	\N	t	2026-07-18 09:57:22.550279+00	2026-07-18 09:57:22.550279+00	\N	1
547dfb8d-2da6-40ee-858a-ad050947c885	5ce2be3e-75e7-4292-82fe-766aa1db594a	{"name": "Cubism", "origin": "France", "period": "1907-1920s", "description": "Geometric abstraction in art"}	374c4e6ba1d8aee11de9b3305628d8444ed41747908808e7dfee1029e6f9e4b2	\N	t	2026-07-18 09:57:22.559363+00	2026-07-18 09:57:22.559363+00	\N	1
cb8f3040-84bc-4aa3-9ca0-ae94708f757d	2e1edec4-5526-4c1b-8bc2-fab57232bbcc	{"name": "Punk Rock", "origin": "UK/USA", "period": "1970s", "description": "Raw, energetic protest music"}	38d5b63622a2c0a18f4f90c67fbd720ed38a8aebda9ac3821406fbc11c05b2bb	\N	t	2026-07-18 09:57:22.567693+00	2026-07-18 09:57:22.567693+00	\N	1
a5b8a6c1-b682-4951-ad34-603969385a53	39ff10e1-4d9c-457b-af7e-4260aeac5fc4	{"name": "Impressionism", "origin": "France", "period": "1860s-1880s", "description": "Capturing light and movement"}	724147f00fac7c4fc9759f0562fb4d34fa4608682caf09fe8c2d943e519aab07	\N	t	2026-07-18 09:57:22.578921+00	2026-07-18 09:57:22.578921+00	\N	1
1ad7327b-4ec7-4f0a-bd56-4fbf9d228bf7	add814c5-08a8-481a-ac3c-deba67a0ede0	{"name": "Existentialism", "origin": "Europe", "period": "1930s-1960s", "description": "Focus on individual existence and freedom"}	8b7c9c425ca3071b6803e66bae766abfecd0c8bf2cbd5c07f4735021a76a6e39	\N	t	2026-07-18 09:57:22.586959+00	2026-07-18 09:57:22.586959+00	\N	1
c343ea44-a965-43d0-bd18-6a17eb010100	0f769c43-41b7-4d0f-bd9a-312563aab3b1	{"name": "Minimalism", "origin": "USA", "period": "1960s-present", "description": "Reduction to essential elements"}	5c02bb7f9139e06aa11bafbf6f24e0f0907dda5f5013d32a3ae68aa4a5722706	\N	t	2026-07-18 09:57:22.59527+00	2026-07-18 09:57:22.59527+00	\N	1
9644bf23-d8fd-4728-9ed2-a3aa77c0c0c5	6edd0c35-7c35-4d15-b7ae-207a60091055	{"name": "Hippie Movement", "origin": "USA", "period": "1960s-1970s", "description": "Peace, love, and counterculture"}	45b744e9e9624069a39b2541aa5d80e1be3603474cce3b75bfb7388fbab9c471	\N	t	2026-07-18 09:57:22.603364+00	2026-07-18 09:57:22.603364+00	\N	1
22b507fa-9c8f-4367-9c6f-566b45cb6507	38a696a5-e8f0-419c-9244-eb3fd7d4a79d	{"name": "Surrealism", "origin": "France", "period": "1920s-1950s", "description": "Art from the unconscious mind"}	bd4c4094ee72d5327742c6bfeb5db0001487d978386a4ef63f5c0e78807743c4	\N	t	2026-07-18 09:57:22.6124+00	2026-07-18 09:57:22.6124+00	\N	1
04ad0bd4-c347-4dd4-92ae-48aa170649fb	244fbf1f-1293-4478-901f-6698bc6178b7	{"name": "Renaissance Movement", "origin": "Italy", "period": "14th-17th century", "description": "Rebirth of art and learning"}	4ea4f4790073d4401d67c32c448efc0cee65a72aea6a324bd64b0e48de7f3b11	\N	t	2026-07-18 09:57:22.622812+00	2026-07-18 09:57:22.622812+00	\N	1
a65d7312-112d-4687-aa34-e508b8fa8860	a787347f-b98b-4514-abe8-69369b46b9ff	{"code": "DDC", "name": "Dewey Decimal Classification", "version": "23", "description": "Library book classification system"}	83a10e044f0b1f2e11abee715f17d4870264c1a6d6353a63ef2caf7dc14a084d	\N	t	2026-07-18 09:57:22.632588+00	2026-07-18 09:57:22.632588+00	\N	1
a335b236-50e6-4294-a057-b3377ffba036	6709672a-8dc2-4e54-bc56-e229c0a395b9	{"code": "ISO-3166", "name": "ISO 3166", "version": "2023", "description": "Country codes standard"}	1104e5282efad830756a70c9505d8855c79b86b0ebec19a203bd851ea495b056	\N	t	2026-07-18 09:57:22.642766+00	2026-07-18 09:57:22.642766+00	\N	1
272922ba-19a4-446e-93f8-34928b05ca01	e9732eac-c03c-40ea-9d12-8067ebe90e21	{"code": "ISIC", "name": "UN Classification", "version": "4", "description": "International economic activity classification"}	d0a23b0f846da5c100a9e7be5b56a76b072e7af99f7eef34eb249172d1c1f048	\N	t	2026-07-18 09:57:22.654508+00	2026-07-18 09:57:22.654508+00	\N	1
1be5220e-4cb6-4437-b7fe-5367edd5d5a2	10584a76-69c8-4288-a2fa-4c053e179be5	{"code": "ISO-639", "name": "ISO 639", "version": "2023", "description": "Language codes standard"}	d398a24d938265e288909c934fe79984010e8cc5f5dcbb12f7a53e7a2c602584	\N	t	2026-07-18 09:57:22.665051+00	2026-07-18 09:57:22.665051+00	\N	1
d74bef82-951c-4c30-bcbc-9b83015f76fb	4e73f55c-87fe-48f2-b003-0ef724e011c1	{"code": "IUPAC", "name": "Periodic Table", "version": "2024", "description": "Chemical element classification"}	40f2b7726d9e80ef9f859fc6f3045fc71bcde35e6362b6ecdca20996cb3bff95	\N	t	2026-07-18 09:57:22.675092+00	2026-07-18 09:57:22.675092+00	\N	1
b88e76f0-c1f9-41b1-b8d9-17e4a0faa84f	e8605b05-418d-435b-bc7c-4e52ed357ce0	{"code": "ICD-10", "name": "ICD-10", "version": "10", "description": "Disease classification"}	8767aa8434143fc94f91efb840c9aed72bb6deec45986c7c29dc0904357bce75	\N	t	2026-07-18 09:57:22.68518+00	2026-07-18 09:57:22.68518+00	\N	1
75eedbc1-079b-4cf4-a2e4-11d90b51e8b8	bf872061-ae00-4b31-8d9a-81fb3b832099	{"code": "TAXONOMY", "name": "Linnaean Classification", "version": "10th", "description": "Biological taxonomy system"}	f4504979bff0a0ca0c19e26a01d250726f334c6eb8db65f809c16144a425b03b	\N	t	2026-07-18 09:57:22.695231+00	2026-07-18 09:57:22.695231+00	\N	1
8b850f03-873c-4fb2-8d82-82199ccdd78c	7be545c6-e69a-4f23-b828-e8fc8ea9f400	{"code": "BBK", "name": "Library Classification", "version": "2023", "description": "Russian library classification"}	d9a4ec70e4c0b0b5d010011d84f0b1e70c951e2b70c3fcffb258d981fe6060fa	\N	t	2026-07-18 09:57:22.703823+00	2026-07-18 09:57:22.703823+00	\N	1
4c59dce1-59c6-4435-9ab2-38df74fa0226	3767aa77-70b0-418a-8173-914b92356460	{"code": "NACE", "name": "NACE", "version": "2.1", "description": "European economic activity classification"}	aebdbcdfc96669ab46ec4243121cb2f29694e3bcb3b5fc81cc0af25dc86cc859	\N	t	2026-07-18 09:57:22.712047+00	2026-07-18 09:57:22.712047+00	\N	1
b59b8423-77ac-4b6a-8eee-c444dd1dfdb3	8ce61cf0-5b98-402f-867d-31ddbf0f15f6	{"code": "ATC", "name": "ATC", "version": "2024", "description": "Drug classification system"}	61a1e89d1bf58e2234ff06386bc7f3abd27fe7cbab0b0df5613e7dab202ba17a	\N	t	2026-07-18 09:57:22.720377+00	2026-07-18 09:57:22.720377+00	\N	1
605b0c10-2c4f-4a7a-86c8-73abfc651a81	eb073520-b90b-432d-a8aa-55e1422efb7f	{"name": "Rosetta Stone", "origin": "Egypt", "material": "Granodiorite", "year_made": -196}	591efae4ec7e0866f6c0a62781d56bc67ca06a971f4185d153f454e18dfdca56	\N	t	2026-07-18 09:57:22.730265+00	2026-07-18 09:57:22.730265+00	\N	1
7bc81aa8-779f-44ae-bb65-437f76242759	f676c81d-01f0-46f0-a227-c9d8e69e8eea	{"name": "Mona Lisa", "origin": "Italy", "material": "Oil on poplar", "year_made": 1503}	ef4e3734f9ac6188ad592307169d59868273e13ed7a45b829b5a2182c2ea5b36	\N	t	2026-07-18 09:57:22.738395+00	2026-07-18 09:57:22.738395+00	\N	1
3f45ce0f-93bf-43fb-9ccd-d5c89cde1aaa	35b74d23-209c-40b6-964d-deef2801855f	{"name": "Great Wall", "origin": "China", "material": "Stone, brick", "year_made": -700}	ab1227d5a98be9c011977b7aaf9138a5e43708d4332328581d792fdb234f3516	\N	t	2026-07-18 09:57:22.749612+00	2026-07-18 09:57:22.749612+00	\N	1
7b281ef2-c61f-45c2-bf01-b275e2e191f9	64a1914d-35a2-4a55-9373-670ceadca8c2	{"name": "Great Pyramid", "origin": "Egypt", "material": "Limestone", "year_made": -2560}	4a1590d9633fe592d234af1543eec7a9102bc7235f17eac1eacb04df7dbd7315	\N	t	2026-07-18 09:57:22.758135+00	2026-07-18 09:57:22.758135+00	\N	1
d92a8ce4-9f22-43eb-abf4-8e78be22e253	c5d1dad4-04e1-4844-8304-4040c80c37e0	{"name": "Colosseum", "origin": "Italy", "material": "Travertine", "year_made": 80}	a8254e1c5f4345a4314c80c3dd685b2b5fb30d21f426f3d5c4efb04970fe9ac4	\N	t	2026-07-18 09:57:22.76659+00	2026-07-18 09:57:22.76659+00	\N	1
93a823a0-2087-4aaf-8286-2b97a58abf1c	0fff090f-f2f7-4271-b522-3909bfba4c17	{"name": "Stonehenge", "origin": "UK", "material": "Sarsen stone", "year_made": -3000}	8f20edde7b4b964a19f478b815d17f79fd6a34a176d7039d266fc887d37cb178	\N	t	2026-07-18 09:57:22.774732+00	2026-07-18 09:57:22.774732+00	\N	1
119b9ef0-fb6a-40ce-be6b-852f73dcbf83	fd7800a4-ba48-4dca-a41c-1e3c237ccfd8	{"name": "Taj Mahal", "origin": "India", "material": "White marble", "year_made": 1653}	5a775e3f0dd19006943819cb63681a984f1c79c255a3f0353cc4ace394361d28	\N	t	2026-07-18 09:57:22.785058+00	2026-07-18 09:57:22.785058+00	\N	1
570ed4d1-da99-4221-999a-76d97476a8f0	2b860475-e645-44f8-adc6-c67e447bbadc	{"name": "Eiffel Tower", "origin": "France", "material": "Iron", "year_made": 1889}	b3e80399a50ca09474237723cadac8fb52ab9ad74dd734daaff382be865a4f3a	\N	t	2026-07-18 09:57:22.793874+00	2026-07-18 09:57:22.793874+00	\N	1
b7cf35c7-708b-4034-bb61-800443848dce	a2dea906-3a9e-4e3c-8e63-15e21a2fac6c	{"name": "Statue of Liberty", "origin": "USA", "material": "Copper", "year_made": 1886}	6ea09d6b2fda77bb1cdf735a2d3d597694129e28e15af1763dfb29c93b0b190d	\N	t	2026-07-18 09:57:22.802364+00	2026-07-18 09:57:22.802364+00	\N	1
bf123793-65a0-4a4b-810c-a3d86d208cc8	9d015be3-a29f-4191-9f44-57a53cc20838	{"name": "Parthenon", "origin": "Greece", "material": "Marble", "year_made": -438}	c9aed5ef2c89671bf6b2f8e74058a6eafce44046517cbba19c5db94c44310669	\N	t	2026-07-18 09:57:22.810446+00	2026-07-18 09:57:22.810446+00	\N	1
d0f5599a-bda2-46b3-b23a-436ec4f89a3c	f7e30db2-8eac-4790-880b-6b4c0172f73e	{"year": 1984, "title": "Afghan Girl", "subject": "Portrait", "photographer": "Steve McCurry"}	cdc792edc2e55475908d637fd8053cd5b34893287e43b63156fc6c6499f4d241	\N	t	2026-07-18 09:57:22.820266+00	2026-07-18 09:57:22.820266+00	\N	1
8e22172f-3070-467c-96cf-491ae39eed4f	b3db499b-52c6-4aa3-8332-bbdd8440c44f	{"year": 1968, "title": "Earthrise", "subject": "Space", "photographer": "William Anders"}	5be3932e555687ce549e41d459075264e831ed25505d0e2ba308f2d5d28b6a79	\N	t	2026-07-18 09:57:22.830406+00	2026-07-18 09:57:22.830406+00	\N	1
abaa7baf-68dc-4288-aa20-f7612314a47f	988f7b04-9fee-4a58-a97d-05f2ec500ed3	{"year": 1945, "title": "V-J Day", "subject": "Historical", "photographer": "Alfred Eisenstaedt"}	d452341068029e9f8ab94801a85c39d7347e8078350bb5de8b6ad490f4e8820c	\N	t	2026-07-18 09:57:22.838892+00	2026-07-18 09:57:22.838892+00	\N	1
7456a045-2f98-4f58-b800-5a20b5ee7c73	a48e421e-9175-4366-936e-da67380999f9	{"year": 1990, "title": "Pale Blue Dot", "subject": "Space", "photographer": "Voyager 1"}	8923dce140c7089143598772e9a901995f6649469c5472af9bbc338d7f440997	\N	t	2026-07-18 09:57:22.847538+00	2026-07-18 09:57:22.847538+00	\N	1
d6e60eef-1cc4-4b2d-86a4-98c31ac549ef	ee14d2c6-141d-433d-bea7-0aa723ed6cfa	{"year": 1936, "title": "Migrant Mother", "subject": "Social", "photographer": "Dorothea Lange"}	99310e425f963eb912b94fb52c9d50e0dae633883d436befc23f20c62361c9e8	\N	t	2026-07-18 09:57:22.856835+00	2026-07-18 09:57:22.856835+00	\N	1
2637a546-b950-4cb5-816f-437fa564cb45	33de6134-121d-43d5-8f9f-a292cde9873e	{"year": 1932, "title": "Lunch atop a Skyscraper", "subject": "Construction", "photographer": "Unknown"}	3b0cab11d981783d8083f814d8deb3ffaefe6fee9c3aebd08fa71b8f0245c6dc	\N	t	2026-07-18 09:57:22.866576+00	2026-07-18 09:57:22.866576+00	\N	1
e9da6928-3e74-4aa3-90a3-81c069eea77f	30e396ec-8d08-4cd1-a2e3-41778530b690	{"year": 1967, "title": "Flower Power", "subject": "Protest", "photographer": "Marc Riboud"}	b3ebfa7097d093e718678202cbd9e4261b67bbe093566a613278855af557e685	\N	t	2026-07-18 09:57:22.877887+00	2026-07-18 09:57:22.877887+00	\N	1
6d569f31-d5dc-4a6f-8fce-fee720bc7d20	1923538d-8765-4dde-91db-1db49b167272	{"year": 1945, "title": "The Kiss", "subject": "Celebration", "photographer": "Alfred Eisenstaedt"}	fdd1eb322abc69644996709ae017cdd0f7ebde2bfaa29727bd7f2108f2e2dd34	\N	t	2026-07-18 09:57:22.8919+00	2026-07-18 09:57:22.8919+00	\N	1
042f815b-e511-4cfd-bca8-0634f7d722bf	5050924d-c6a4-4b64-ab48-a3c99a24d164	{"year": 1993, "title": "Struggling Girl", "subject": "Conflict", "photographer": "Kevin Carter"}	09cb5a491644a01a2491e1362386b74a15b7a74a7f56368a2eca47b0131de06b	\N	t	2026-07-18 09:57:22.905291+00	2026-07-18 09:57:22.905291+00	\N	1
e1946496-dc79-4d40-9b7f-a8c02eacc16a	799f49a7-e75a-4472-9e80-fe43558d3b6e	{"year": 1995, "title": "Hubble Deep Field", "subject": "Space", "photographer": "Hubble Telescope"}	c34f71886958fb344d88c016ef5460fad48c5733a03f74792deba4444a4d7eac	\N	t	2026-07-18 09:57:22.918289+00	2026-07-18 09:57:22.918289+00	\N	1
158fcd0d-7600-44e7-b37b-778654f665aa	8ec1b810-4a02-4094-aa35-59bd2d164205	{"title": "Zur Elektrodynamik bewegter Körper", "author": "Albert Einstein", "source": "Annalen der Physik", "published": "1905-06-30"}	4346476ea97766b14eecc3b3c3a8d943ca72db9d9f5cd8e96f3547a3f2cee08d	\N	t	2026-07-18 09:57:22.934577+00	2026-07-18 09:57:22.934577+00	\N	1
2ee42b51-f863-4930-8b14-609ede16de86	d98d8088-2272-4862-b6d9-7879b3eef47a	{"title": "On the Origin of Species", "author": "Charles Darwin", "source": "John Murray", "published": "1859-11-24"}	43be0e577720e450a92dc91f76feedda1605b9d3fe7423dea309cefeb6522c70	\N	t	2026-07-18 09:57:22.946403+00	2026-07-18 09:57:22.946403+00	\N	1
000ef003-eb67-4c36-947e-1c58134a8e9a	56157d73-329b-4f88-b899-aecbf70d2654	{"title": "Manifest der Kommunistischen Partei", "author": "Karl Marx & Friedrich Engels", "source": "London", "published": "1848-02-21"}	ae95d16bdc517852c3a36e01fe9c9bcd8d21b59676637ccad20a98e83e888c22	\N	t	2026-07-18 09:57:22.955933+00	2026-07-18 09:57:22.955933+00	\N	1
e6a50aad-b5eb-4048-941e-4bc4513defd8	65ba9c87-4e23-4f87-8e34-2fb20ac42702	{"title": "The Republic", "author": "Plato", "source": "Athens", "published": "-380"}	912746db59d9a79a026d4ba649a068545f61810628719eceafaebff6922195f9	\N	t	2026-07-18 09:57:22.965751+00	2026-07-18 09:57:22.965751+00	\N	1
97d3be40-502e-4ba2-bc55-185788f0b7cc	f73ddaf1-be62-46ad-893a-170d9d69d88e	{"title": "Philosophiæ Naturalis Principia Mathematica", "author": "Isaac Newton", "source": "London", "published": "1687-07-05"}	1f34cc8a401e69b8dfa1e268ce88084bbe9445f950bed1c87cd2b1df9fd1df03	\N	t	2026-07-18 09:57:22.974835+00	2026-07-18 09:57:22.974835+00	\N	1
727348b5-6e18-47cd-bb79-dc8a694e5dbc	1c6b2f47-da0e-4b9f-af33-9c2a6060915f	{"title": "Kritik der reinen Vernunft", "author": "Immanuel Kant", "source": "Riga", "published": "1781-01-01"}	896d50a756a1b6b8d407f630483b80060247418e4f2995e3155304f4994e45b1	\N	t	2026-07-18 09:57:22.983605+00	2026-07-18 09:57:22.983605+00	\N	1
93aa542c-6d87-4bc8-9fec-874acf205d61	675fbc3a-84c1-4ef7-87de-e14ad644215c	{"title": "An Inquiry into the Nature and Causes of the Wealth of Nations", "author": "Adam Smith", "source": "London", "published": "1776-03-09"}	b36436d01ef64e7a237688b0510bbe9a4cdea14889ee007f6e10870bc3352fff	\N	t	2026-07-18 09:57:22.992975+00	2026-07-18 09:57:22.992975+00	\N	1
5027b919-4409-450b-b8c1-ba22943462fa	789dbac1-0832-4c73-b666-377eb00af5f3	{"title": "Two Treatises of Government", "author": "John Locke", "source": "London", "published": "1689-01-01"}	02b413e6f849bc25b95f6bbbc57209bcd1b22e9317f7f561668b72afc196e1ed	\N	t	2026-07-18 09:57:23.001395+00	2026-07-18 09:57:23.001395+00	\N	1
7cff9bb4-85a0-49cc-bfb6-a7ce34cd7702	ab39ad23-3c9d-40c4-9b11-3b6bd47fef3f	{"title": "The Wealth", "author": "Adam Smith", "source": "London", "published": "1776-03-09"}	05c258f5108a092bc5bbffdd580225cb50e9db3b65f5a70e01245cb661988512	\N	t	2026-07-18 09:57:23.009757+00	2026-07-18 09:57:23.009757+00	\N	1
13a78738-3ac3-4be0-bec0-e877a6809c73	3781b6e9-be8e-4f39-a829-7a521a4a60f2	{"title": "Das Kapital", "author": "Karl Marx", "source": "Hamburg", "published": "1867-09-14"}	137c119325e084c876e21cdae6b6cc4bc6e2e977c57676ad3bc388654c2ad3da	\N	t	2026-07-18 09:57:23.018274+00	2026-07-18 09:57:23.018274+00	\N	1
c86e6b22-1344-4e13-84b7-4711a16fd38c	f2cb701c-b06e-4809-a8db-2447d463e4f2	{"last_name": "Einstein", "birth_date": "1879-03-14", "first_name": "Albert", "occupation": "Physicist", "birth_place": "Ulm, Germany", "nationality": "German-Swiss"}	7a21a3c4f625a9bec01d8eb547764d25cd32978b577e32c0f39fa182684c4462	\N	t	2026-07-18 09:57:23.029587+00	2026-07-18 09:57:23.029587+00	\N	1
4aa1f839-027f-4ec1-b97b-7bf2835800ee	10802c9a-70df-48bf-806f-cc1c745b9094	{"last_name": "da Vinci", "birth_date": "1452-04-15", "first_name": "Leonardo", "occupation": "Polymath", "birth_place": "Anchiano, Italy", "nationality": "Italian"}	278e1535c21ff6198839a63160e9c3da7369f59ee0ee38b2180355058a8a71cb	\N	t	2026-07-18 09:57:23.040153+00	2026-07-18 09:57:23.040153+00	\N	1
e0b76af4-fd05-4b48-99ec-b2c0daeb96b5	f7184740-9ef9-4a4b-8d3e-de5d43b52c14	{"last_name": "Newton", "birth_date": "1643-01-04", "first_name": "Isaac", "occupation": "Physicist", "birth_place": "Woolsthorpe, UK", "nationality": "British"}	5d9ded7984f70fa6f9bbb0ab4eb7ecf58cea75d06909849fae446d6c33959edd	\N	t	2026-07-18 09:57:23.050861+00	2026-07-18 09:57:23.050861+00	\N	1
1fb81ee0-896f-46bd-9f04-ae0b7d24df65	7f0cc4df-4709-40f3-869c-fbc7deb5cc1e	{"last_name": "Tesla", "birth_date": "1856-07-10", "first_name": "Nikola", "occupation": "Inventor", "birth_place": "Smiljan, Croatia", "nationality": "Serbian-American"}	84e003c5601f948cc6466eeb191a95a32904913ff2d6bfad91947b5a9fe14d24	\N	t	2026-07-18 09:57:23.06018+00	2026-07-18 09:57:23.06018+00	\N	1
903e397b-58b1-481c-ae32-930fd6881d3b	e721b2c2-e06d-43d5-bb5c-ad59f5c71af2	{"last_name": "Curie", "birth_date": "1867-11-07", "first_name": "Marie", "occupation": "Physicist", "birth_place": "Warsaw, Poland", "nationality": "Polish-French"}	449fef5261857f2d2a26d50b81144c8f5903920fb43c83a41f5c2fcd05e68c24	\N	t	2026-07-18 09:57:23.069841+00	2026-07-18 09:57:23.069841+00	\N	1
8050e119-40c9-4639-b69a-421f129b33bc	086071ba-c0f7-4348-9b3a-12b4dc86e89b	{"last_name": "Darwin", "birth_date": "1809-02-12", "first_name": "Charles", "occupation": "Naturalist", "birth_place": "Shrewsbury, UK", "nationality": "British"}	435100a9de61a3c8a61a3904e22ab27c9a629a7d2971be4f2e7147d401505059	\N	t	2026-07-18 09:57:23.079877+00	2026-07-18 09:57:23.079877+00	\N	1
6b9d0b11-c112-4ab2-8b47-6cd0c103f9cb	a235661b-fdc8-465b-ac30-0d6898ce5e9e	{"last_name": "", "birth_date": "-427", "first_name": "Plato", "occupation": "Philosopher", "birth_place": "Athens, Greece", "nationality": "Greek"}	3251eada4220c83c52b853df92d386f06da79e08a99dc50a01177503e85effca	\N	t	2026-07-18 09:57:23.091014+00	2026-07-18 09:57:23.091014+00	\N	1
8105f189-337a-44d2-93fd-8d13001e8976	95391e2c-a4f6-4dce-aead-586b409ec3a2	{"last_name": "Shakespeare", "birth_date": "1564-04-26", "first_name": "William", "occupation": "Playwright", "birth_place": "Stratford-upon-Avon, UK", "nationality": "British"}	ba75341a18d53faea1ba65d21453aca5fbabf3e88665ffc36089c8630f440851	\N	t	2026-07-18 09:57:23.102565+00	2026-07-18 09:57:23.102565+00	\N	1
074d7898-ece3-4a59-9f56-babfa11dc1df	1d926d21-2f6f-4f7e-82fd-a80b9c74e842	{"last_name": "Qiu", "birth_date": "-551", "first_name": "Kong", "occupation": "Philosopher", "birth_place": "Qufu, China", "nationality": "Chinese"}	f92b7603a3683e029f154bffd673524de99c289147e92869c7a4a94ec84d2b26	\N	t	2026-07-18 09:57:23.114244+00	2026-07-18 09:57:23.114244+00	\N	1
f9309ff3-3d31-4a05-aa61-5de2e62b1e68	2070e2bd-ef21-4759-8f01-61b38932d500	{"last_name": "Gandhi", "birth_date": "1869-10-02", "first_name": "Mahatma", "occupation": "Political leader", "birth_place": "Porbandar, India", "nationality": "Indian"}	72598c86b87b1efff0abcdfe831db5d9a65b7a132a62bcc7efe92ac8be90bf4b	\N	t	2026-07-18 09:57:23.125437+00	2026-07-18 09:57:23.125437+00	\N	1
d21d297e-ce1b-4937-82d0-a0f3b1a17ab7	9bd52dcc-062a-488d-8651-ca4cd190e306	{"last_name": "Picasso", "birth_date": "1881-10-25", "first_name": "Pablo", "occupation": "Artist", "birth_place": "Malaga, Spain", "nationality": "Spanish"}	a89d4acdc741fd6a26d90cc8570b3cdd0d0739f298edd50e73255a9d12cba620	\N	t	2026-07-18 09:57:23.138856+00	2026-07-18 09:57:23.138856+00	\N	1
7e8e0bae-f545-490b-acb0-bcbe8b622ade	faa776f9-6678-4836-b937-6b245c6704c0	{"last_name": "van Gogh", "birth_date": "1853-03-30", "first_name": "Vincent", "occupation": "Artist", "birth_place": "Groot-Zundert, Netherlands", "nationality": "Dutch"}	106dbfd0367e70d5ba19d5a6c61f01f20426df519bb32937f8c7362ab593a973	\N	t	2026-07-18 09:57:23.151423+00	2026-07-18 09:57:23.151423+00	\N	1
4b0974ca-5d3d-4493-8ddb-7d9520b93ff6	c4502aa7-8e2e-46ce-9ecb-3a311f67ccab	{"last_name": "Monet", "birth_date": "1840-11-14", "first_name": "Claude", "occupation": "Artist", "birth_place": "Paris, France", "nationality": "French"}	7a93859bb2c392a96a3772ce85ea4da4ed480b8b6bd647258ee68ebe77c8dd12	\N	t	2026-07-18 09:57:23.163344+00	2026-07-18 09:57:23.163344+00	\N	1
ed7a877d-349f-4c03-960a-9a5d7c09b7a1	d8ce2c13-86e4-4ec3-82ed-d26909f78d1d	{"last_name": "di Lodovico Buonarroti Simoni", "birth_date": "1475-03-06", "first_name": "Michelangelo", "occupation": "Artist", "birth_place": "Caprese, Italy", "nationality": "Italian"}	d4316c2548210791a6f8256e47c65974585f4fc4d8304f0753c2deb1e9c84731	\N	t	2026-07-18 09:57:23.17445+00	2026-07-18 09:57:23.17445+00	\N	1
4b874a89-620b-4e47-8e63-9cef2b54fa10	235d5de7-86b9-4e5d-99da-014f788d8171	{"last_name": "van Rijn", "birth_date": "1606-07-15", "first_name": "Rembrandt", "occupation": "Artist", "birth_place": "Leiden, Netherlands", "nationality": "Dutch"}	a870089dce5761dbfc5837dfbd5c115a14b6682da93add6dc55045e5dde1582a	\N	t	2026-07-18 09:57:23.185873+00	2026-07-18 09:57:23.185873+00	\N	1
340be7ca-07a6-47f2-a7ec-5d2e06275dab	a35eb241-6074-4428-ad18-324e0498f7dc	{"last_name": "Dali", "birth_date": "1904-05-11", "first_name": "Salvador", "occupation": "Artist", "birth_place": "Figueres, Spain", "nationality": "Spanish"}	653bc6ddf8c316694cd167a63b86fb6240cf6a50155cd3d1db4d4c29b4840181	\N	t	2026-07-18 09:57:23.197582+00	2026-07-18 09:57:23.197582+00	\N	1
3e87c8c7-0ffc-4dd4-b65f-3ed7a140e1b8	1fed5c68-3256-4190-974e-13aab829cd1b	{"category": "events", "field_key": "event_end_date", "field_type": "date", "description": "", "default_value": ""}	53bbd33fb566d25f1ac8eb1908347cbf045125b6989e22c717fcc5e831177b7b	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	40
5090e52c-f783-4f25-9536-f894b3bd829c	5e504d44-75f5-4845-b518-ee7c5cf09cac	{"last_name": "Warhol", "birth_date": "1928-08-06", "first_name": "Andy", "occupation": "Artist", "birth_place": "Pittsburgh, USA", "nationality": "American"}	00e5e76e1d56d434f2d3279834741ca258e210f51b5526e28a8b7c3c2597b731	\N	t	2026-07-18 09:57:23.207616+00	2026-07-18 09:57:23.207616+00	\N	1
744b15cc-00d8-43f8-823e-3d91862bf45e	ba3de29a-9eaa-496e-a420-939e09a9cfe8	{"last_name": "Kahlo", "birth_date": "1907-07-06", "first_name": "Frida", "occupation": "Artist", "birth_place": "Mexico City, Mexico", "nationality": "Mexican"}	63dfadd9dd5530b5425ee0326c35e6d6e1507690c11bb3375a0a80e2b4bdce81	\N	t	2026-07-18 09:57:23.218554+00	2026-07-18 09:57:23.218554+00	\N	1
f83aa34c-7981-4aa4-9d39-6624e17f593e	49d0ef05-c628-4795-9b44-3f0741512e55	{"last_name": "Kandinsky", "birth_date": "1866-12-16", "first_name": "Wassily", "occupation": "Artist", "birth_place": "Moscow, Russia", "nationality": "Russian-French"}	d2166a23cc8363beb3ed1f0418802ca867bc3a45c5f94efde96c511036fcca4c	\N	t	2026-07-18 09:57:23.228428+00	2026-07-18 09:57:23.228428+00	\N	1
0f1bf5c0-08fe-4163-a261-d575902b98dc	d636a9d1-d027-4ba0-8221-1e6948d1248a	{"last_name": "Merisi da Caravaggio", "birth_date": "1571-09-29", "first_name": "Michelangelo", "occupation": "Artist", "birth_place": "Milan, Italy", "nationality": "Italian"}	36464f5b6c1ab21818e8130c80f2207eead8ba2e4a577f99400f0b674b3814dd	\N	t	2026-07-18 09:57:23.237532+00	2026-07-18 09:57:23.237532+00	\N	1
d070d7e1-3c88-4abf-9653-80dd13dece09	49d50382-9dbe-47a7-8252-69d9d0fd4d8c	{"last_name": "Hawking", "birth_date": "1942-01-08", "first_name": "Stephen", "occupation": "Physicist", "birth_place": "Oxford, UK", "nationality": "British"}	5ddf295fa9e6b5911c6320889d7d3ae8ebbe6089cb3570808db8154bf1b348b9	\N	t	2026-07-18 09:57:23.249905+00	2026-07-18 09:57:23.249905+00	\N	1
338abe5f-2e31-40c1-90b4-a00199953188	7889b8e3-dc41-4d5f-a819-fdfc3896c143	{"last_name": "Feynman", "birth_date": "1918-05-11", "first_name": "Richard", "occupation": "Physicist", "birth_place": "New York, USA", "nationality": "American"}	b93a70912f226be7d7ffa848db379182c610a69f47ec15973ff9418fc8804d9c	\N	t	2026-07-18 09:57:23.260857+00	2026-07-18 09:57:23.260857+00	\N	1
b0f98263-30df-42e8-ae9d-c0ed343b1475	ab5d2722-934c-4119-8bf2-0827b8ad05f9	{"last_name": "Darwin", "birth_date": "1809-02-12", "first_name": "Charles", "occupation": "Naturalist", "birth_place": "Shrewsbury, UK", "nationality": "British"}	435100a9de61a3c8a61a3904e22ab27c9a629a7d2971be4f2e7147d401505059	\N	t	2026-07-18 09:57:23.270259+00	2026-07-18 09:57:23.270259+00	\N	1
69442f8b-5b5d-4292-a53f-d3a70ec5b385	80255719-a52e-4cda-a615-8d2f5d82ae25	{"last_name": "Bohr", "birth_date": "1885-10-07", "first_name": "Niels", "occupation": "Physicist", "birth_place": "Copenhagen, Denmark", "nationality": "Danish"}	92b605e8eda87a1db7d6195dfc921db57de6ef8c67d62a72fa4ec58890a9490e	\N	t	2026-07-18 09:57:23.279059+00	2026-07-18 09:57:23.279059+00	\N	1
2acbcc3b-5501-477f-a60a-6fbbd66554d3	cc67c4bb-57a8-4f7b-8a73-35953636f992	{"last_name": "Planck", "birth_date": "1858-04-23", "first_name": "Max", "occupation": "Physicist", "birth_place": "Kiel, Germany", "nationality": "German"}	a95ad25b1da2adb607b03df9104d96ac050c3e7a07cf04f23056781620ab3055	\N	t	2026-07-18 09:57:23.28829+00	2026-07-18 09:57:23.28829+00	\N	1
055459ce-3a72-4f88-9a47-d35a199154af	200a298c-d70b-4397-9010-d83132d034a2	{"last_name": "Mendeleev", "birth_date": "1834-02-08", "first_name": "Dmitri", "occupation": "Chemist", "birth_place": "Tobolsk, Russia", "nationality": "Russian"}	c5530e8b0a12367b95c7f36ccdd6cb2a2ade56ebffaedf4d839e1231fde46c49	\N	t	2026-07-18 09:57:23.297912+00	2026-07-18 09:57:23.297912+00	\N	1
7992cfaa-8b90-4c27-92db-0d0914325ccf	542287c6-0516-46fa-9bb4-5b8b66e46a9d	{"last_name": "Galilei", "birth_date": "1564-02-15", "first_name": "Galileo", "occupation": "Astronomer", "birth_place": "Pisa, Italy", "nationality": "Italian"}	994ab29a362e4710b99565ce2c7bca89ef5f70cc955bd7cd1a45d45739ede783	\N	t	2026-07-18 09:57:23.307533+00	2026-07-18 09:57:23.307533+00	\N	1
81cefc1f-bef7-4bfa-94d6-e0beb4c76c99	001fa3ac-0136-4486-8026-85c1e9854d1d	{"last_name": "Pauling", "birth_date": "1901-02-28", "first_name": "Linus", "occupation": "Chemist", "birth_place": "Portland, Oregon", "nationality": "American"}	476390101b03024453eba0a1020de18dd37077bc2c8039c56f5271774eb43f9e	\N	t	2026-07-18 09:57:23.317892+00	2026-07-18 09:57:23.317892+00	\N	1
164bbe02-0795-4c06-a33d-459290b7533e	47b53aa6-6284-4484-95bf-2e4dcd783368	{"last_name": "Franklin", "birth_date": "1920-07-25", "first_name": "Rosalind", "occupation": "Chemist", "birth_place": "London, UK", "nationality": "British"}	0d2a6950fc12c1859b9ca8663042e8c7957c6eb59e6246551cf109e1860c0b02	\N	t	2026-07-18 09:57:23.329356+00	2026-07-18 09:57:23.329356+00	\N	1
ea84bfd4-f37e-4de0-89b6-64453974f95f	3a70d853-b7f1-4213-beab-7e1c5737aa52	{"title": "Гремлины", "poster": "http://localhost:9000/dwmb-media/entities/1ea63bec-f46d-43d4-bfce-ec55c7e3b96c/%D0%93%D1%80%D0%B5%D0%BC%D0%BB%D0%B8%D0%BD%D1%8B.jpeg?AWSAccessKeyId=dwmb_minio&Signature=bFDoW3yUPrF9AsPQFqoWX4AOdb0%3D&Expires=1784408318"}	331daf77eba739c15f10ba87c5ddeee1f2c340bde442e42f7ab7121182a6d788	\N	t	2026-07-18 19:58:38.270682+00	2026-07-18 19:58:38.270683+00	\N	1
646d1981-319d-47c5-99b2-b7fffabe9fd9	559d4c25-704b-4f2e-a06f-751cf9e87f24	{"title": "Тот.самый.Мюнхгаузен", "poster": "http://localhost:9000/dwmb-media/entities/387fb842-3e32-462c-a70a-714bab27a2eb/%D0%A2%D0%BE%D1%82.%D1%81%D0%B0%D0%BC%D1%8B%D0%B9.%D0%9C%D1%8E%D0%BD%D1%85%D0%B3%D0%B0%D1%83%D0%B7%D0%B5%D0%BD.jpeg?AWSAccessKeyId=dwmb_minio&Signature=9hZOH0PnGMSJ03Q55siVQhzuvOQ%3D&Expires=1784408745"}	d2fca5b9c541a4646e37d6483a8d18529c0ed19338675a620f08d5261d78e1ab	\N	t	2026-07-18 20:05:45.208089+00	2026-07-18 20:05:45.208093+00	\N	1
b280338a-5bbc-406c-8496-3156d747f725	f0000001-0000-0000-0000-000000000005	{"year": 1982, "genre": "фантастика, драма, триллер", "title": "Бегущий по лезвию 2049", "budget": "28.0M", "images": "http://localhost:9000/dwmb-media/entities/afed8c62-00d3-476b-a20c-2b8173d303a6/%D0%90%D0%BA%D0%B0%D0%B4%D0%B5%D0%BC%D0%B8%D1%8F_%D0%B2%D0%B5%D0%B4%D1%8C%D0%BC%D0%BE%D1%87%D0%B5%D0%BA.webp?AWSAccessKeyId=dwmb_minio&Signature=V5aQx9HGib%2Fgk%2Bgw5zQswnVh3k0%3D&Expires=1784477602\\r\\nhttp://localhost:9000/dwmb-media/entities/485dee97-cde2-4603-8aa3-1b9364a5cbb1/%D0%A7%D0%BE%D0%BA%D0%BD%D1%83%D1%82%D1%8B%D0%B9_%D0%BF%D1%80%D0%BE%D1%84%D0%B5%D1%81%D1%81%D0%BE%D1%80_%28%D0%9A%D0%BE%D0%BB%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F%292.png?AWSAccessKeyId=dwmb_minio&Signature=SMIqsHe3htpwlN8efdvU3n5AA%2FY%3D&Expires=1784477603\\r\\nhttp://localhost:9000/dwmb-media/entities/ce6d5b1a-8536-4823-88c3-6d077da6c23c/%D0%A7%D0%BE%D0%BA%D0%BD%D1%83%D1%82%D1%8B%D0%B9_%D0%BF%D1%80%D0%BE%D1%84%D0%B5%D1%81%D1%81%D0%BE%D1%80_%28%D0%9A%D0%BE%D0%BB%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F%29.jpg?AWSAccessKeyId=dwmb_minio&Signature=UPrqAxAKo3tpyFpiE3E0VlMWaDQ%3D&Expires=1784477603\\r\\nhttp://localhost:9000/dwmb-media/entities/c42af2c3-8bff-431d-84aa-31fee4e37dba/%D0%9B%D0%B5%D0%B3%D0%B5%D0%BD%D0%B4%D0%B0_%D0%BE_%D0%9B%D0%BE_%D0%A1%D1%8F%D0%BE%D1%85%D1%8D%D0%B52.jpg?AWSAccessKeyId=dwmb_minio&Signature=dsdEV0rVheyXLSEOoGaQb3fjYgA%3D&Expires=1784477603\\r\\nhttp://localhost:9000/dwmb-media/entities/9559dcd0-3ee8-4941-ac8e-65bde4b2e705/%D0%9B%D0%B5%D0%B3%D0%B5%D0%BD%D0%B4%D0%B0_%D0%BE_%D0%9B%D0%BE_%D0%A1%D1%8F%D0%BE%D1%85%D1%8D%D0%B5.jpg?AWSAccessKeyId=dwmb_minio&Signature=HhcUx7OyP8irbInbOgH3V%2BgbO8E%3D&Expires=1784477603\\r\\nhttp://localhost:9000/dwmb-media/entities/b56aeff9-0ebd-4687-b5f3-c7bdd8efa1a6/4.%D0%9A%D0%BE%D0%BC%D0%BD%D0%B0%D1%82%D1%8B.jpg?AWSAccessKeyId=dwmb_minio&Signature=zbOg52splongeakg3tXTQF%2FNbIM%3D&Expires=1784477603", "poster": "https://image.tmdb.org/t/p/w500/gajva2L0rPYkEWjzgFlBXCAVBE5.jpg", "rating": 7.9, "content": "**1. Галерея изображений** — Проблема была двойная: (а) шаблон фильма имел блок gallery, но данные `images` были только у `blade-runner-2049` с внутренними Docker URL (`minio:9000`). Добавлен `MINIO_PUBLIC_ENDPOINT` в config.py/docker-compose.yml, `get_presigned_url()` теперь подменяет внутренний хостст на `localhost:9000`. Также добавлены тестовые галереи (TMDB URL) для Interstellar и Inception.\\r\\n\\r\\n**2. Markdown блок** — Блок markdown имел только поле `source` (ссылка на поле данных), без статического контента. Добавлено поле `content` в редактор шаблонов, и renderer теперь: сначала ищет `source` в state_data, потом fallback на `config.content`. Тест проходит: статический markdown и source из данных оба работают.\\r\\n\\r\\n**3. Прокрутка левого меню** — `<aside id=\\"left-sidebar\\">` имел `min-h-[calc(100vh-3.5rem)]` (минимальная высота), но не `max-height`. Overflow срабатывал только когда контент превышал явную высоту. Заменено на `h-[calc(100vh-3.5rem)]` — фиксированная высота = overflow работает.\\r\\n\\r\\n**4. Кнопка «Каталог»** — В `/admin/dashboard.html` добавлена синяя кнопка «Каталог» → `/entities`.\\r\\n\\r\\n**5. Текстовый блок** — `text_block` переименован в «Описание» с фиксированным чтением из `state_data.description` (без настроек). Добавлен новый блок «Текстовый блок» (`richtext`) с настраиваемым заголовком, полем данных и статическим текстом. Markdown блок теперь также поддерживает статический контент.", "country": "United States of America, Hong Kong, United Kingdom", "imdb_id": "tt0083658", "tagline": "«Человек нашёл себе достойную замену... теперь это его проблема»", "tmdb_id": "78", "director": "Ридли Скотт", "duration": "117 мин", "file_url": "", "language": "English, Deutsch, 广州话 / 廣州話, 日本語, Magyar", "audio_url": "", "age_rating": "12", "file_title": "", "description": "Ноябрь 2019 года. Бывший охотник на андроидов Рик Декард восстановлен в полиции Лос-Анджелеса для поиска возглавляемой Роем Батти группы репликантов, совершившей побег из космической колонии на Землю. В полиции считают, что андроиды пытаются встретиться с Эндолом Тайреллом - руководителем корпорации, которая разрабатывает кибернетический интеллект. Декард получает задание выяснить мотивы репликантов и уничтожить их.", "production_company": "Shaw Brothers, The Ladd Company, Warner Bros. Pictures", "Здесь будет контент [year] или не будет": "Здесь будет текст [year] или не будет.\\r\\n1. **Duplicate `admin_kinds` route** — merged the new kind-schema-aware route with the existing one, removed unreachable duplicate\\r\\n2. **`_replace_variables` regex bug** — regex had 2 groups but code referenced `m.group(3)`; fixed to use `group(2)` with correct regex pattern\\r\\n3. **`_replace_variables` early return** — `not state_data` prevented default value replacement on empty dicts; removed the guard\\r\\n4. **`field_key` vs `key` mismatch** — layout config uses `field_key` but rendering code read `key`; added fallback `f.get(\\"field_key\\") or f.get(\\"key\\", \\"\\")`\\r\\n5. **Empty template layout_definitions** — all 25 templates had lost their layout; re-populated with `image_data_row` blocks\\r\\n6. **Template `kind_id` was NULL** — all 25 templates had NULL `kind_id`; populated from template code naming convention; re-linked 64 entity projections to templates\\r\\n7. **Schema/data key mismatch** — updated movie, actor, director, musician, book, song, place schemas to match actual state_data keys (e.g. `budget_mln` → `budget`)\\r\\n8. **Template layout fields populated** — auto-filled `config.fields` from schema properties for all 25 templates"}	e7b5e887b66d143406701af6e4998a76e2a0c107217fadcc18505d54d8de5c34	\N	t	2026-07-18 09:57:12.863712+00	2026-07-18 09:57:12.863712+00	\N	1
667c1c89-464c-4a51-a3ad-900f4a56ebe2	d77a6734-3389-4079-aa7e-773f2842ac5f	{"title": "Приключения.Электроника", "poster": "http://localhost:9000/dwmb-media/entities/058e03ee-0404-4bc5-b449-260f1f29e6a1/%D0%9F%D1%80%D0%B8%D0%BA%D0%BB%D1%8E%D1%87%D0%B5%D0%BD%D0%B8%D1%8F.%D0%AD%D0%BB%D0%B5%D0%BA%D1%82%D1%80%D0%BE%D0%BD%D0%B8%D0%BA%D0%B0.jpg?AWSAccessKeyId=dwmb_minio&Signature=2oYwKNXlkYk7%2FxrrH33E5855O2E%3D&Expires=1784408318"}	c09ce665d5bde53e2ee44db0b7328b9d90d20d826af96f3a33e7f051fa57c8d8	\N	t	2026-07-18 19:58:38.331949+00	2026-07-18 19:58:38.331951+00	\N	1
f52abfb3-5b18-4d78-a6db-617570ee863e	2331534d-059c-4141-bd1f-6d7795b510fe	{"title": "i", "poster": "http://localhost:9000/dwmb-media/entities/c7940df6-46a1-483b-a8b0-0fb0d60019f2/i.jpg?AWSAccessKeyId=dwmb_minio&Signature=4ayaYAhnD33eeiZklYuTkrRxfJk%3D&Expires=1784409998"}	db846a54117b6ea1426bc922ebcf404e3df6ae4ce6be724471e48878e88418e3	\N	t	2026-07-18 20:26:38.017592+00	2026-07-18 20:26:38.017594+00	\N	1
272d5369-7bd5-4c9d-930b-7cf4aa08fb79	9e62c66f-565c-42dd-9686-ba9c5444f749	{"title": "orig (1)", "poster": "http://localhost:9000/dwmb-media/entities/eb2cb77f-513e-450a-a911-aa2fd912f5c3/orig_%281%29.jpg?AWSAccessKeyId=dwmb_minio&Signature=5bw0jfaZSZ3ISe%2BcpKqNRalHp38%3D&Expires=1784410010"}	53c316d25fedfcb42c3b17fb58941b98bc828813c822d2d13f4dc42beb033483	\N	t	2026-07-18 20:26:50.665357+00	2026-07-18 20:26:50.665357+00	\N	1
343e543a-547c-4b17-8519-4a61a74944fb	3ba2a862-998f-4318-a516-2b33109a995a	{"isbn": "978-0451524935", "year": 1949, "genre": "Dystopia", "pages": 328, "title": "1984", "author": "George Orwell", "poster": "", "language": "English", "publisher": ""}	d04634ecb2a845b602db000acb7c1f3c7978dbb597888328f68bc16bb29c8ba8	\N	t	2026-07-18 09:57:21.216918+00	2026-07-18 09:57:21.216918+00	\N	1
9a94bded-56f6-4778-8960-53b1291136bf	1bedc101-f24c-4dc3-982b-70e95ca48c1d	{"title": "test cover", "poster": "http://localhost:9000/dwmb-media/entities/8bf8898d-097d-414e-beab-2c84e8fdd08b/test_cover.jpg?AWSAccessKeyId=dwmb_minio&Signature=gwPK7Iel8kJnS%2FS7DL%2BPlWANY54%3D&Expires=1784410708"}	e47e326a85d0ce3be6728919b81f2d8791c93a28f0099d2d561a8025bf604b2e	\N	t	2026-07-18 20:38:28.474175+00	2026-07-18 20:38:28.474176+00	\N	1
b77ec49d-e635-43c8-bf3d-a15282a2e23e	dd31cf82-0cc3-4e03-8a38-0a592f9e3475	{"title": "maxresdefault", "poster": "http://localhost:9000/dwmb-media/entities/163f66ff-44d7-4580-85ab-39c5bfbe1e9d/maxresdefault.jpg?AWSAccessKeyId=dwmb_minio&Signature=Z%2BqlqVuW%2F%2BQ%2BSC2hIEHmrMFBwT8%3D&Expires=1784410832"}	eb09fb6f5e61851bf6ec15d717542cb09e822f5a3a547cdd94e6d6e0a89da544	\N	t	2026-07-18 20:40:32.705155+00	2026-07-18 20:40:32.705156+00	\N	1
84051653-793b-4e13-9e5a-00732e9998dd	d4a06d99-ed38-4c6e-9e9e-aefe971cef14	{"poster": "http://localhost:9000/dwmb-media/entities/163f66ff-44d7-4580-85ab-39c5bfbe1e9d/maxresdefault.jpg?AWSAccessKeyId=dwmb_minio&Signature=Z%2BqlqVuW%2F%2BQ%2BSC2hIEHmrMFBwT8%3D&Expires=1784410832", "last_name": "Rowling", "birth_date": "1965-07-31", "first_name": "Joanne", "occupation": "Writer", "birth_place": "Yate, UK", "nationality": "British"}	b5ad6f2cc9b5c0bf4eba33feda9ee198a77a1292ad0bfe7afa1537ac8609dd25	\N	t	2026-07-18 09:57:21.428081+00	2026-07-18 09:57:21.428081+00	\N	1
527d0707-deaf-4306-8a56-47659bde395b	4eb56695-d7c0-4e1f-bfe5-1575009b206f	{"category": "cinema", "field_key": "imdb_id", "field_type": "string", "description": "Идентификатор в базе IMDb", "default_value": ""}	b7a924b3acb8440b12fb751b8475eb9b2c6c10e2e9067993d852da1361fa1b68	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	2
35a2ffe1-c35e-48e7-a9b3-5f6d65bc5490	b4c7a177-eeb8-43f4-ad57-f29e2fd7c8d6	{"category": "cinema", "field_key": "tmdb_id", "field_type": "string", "description": "", "default_value": ""}	a5df38466d989c526faff830858fde292c92b7b46183a80bd688f49b44f430e4	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	3
65b66f7b-9398-4171-99ed-6be6140f694e	6c45baac-b8fe-4357-90c2-aaa236e0b3ff	{"category": "cinema", "field_key": "runtime", "field_type": "integer", "description": "Длительность в минутах", "default_value": ""}	91565f23de61af0911422c269a8c556f8d3b83101476009736150b46ade8d06c	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	4
4201989f-b3e8-4730-af1d-d67321d9cdef	f99a57df-602b-473d-8660-d528c1055de9	{"category": "cinema", "field_key": "mpaa_rating", "field_type": "select", "description": "", "default_value": ""}	b621a69b76a4a5b77a3023ef58d485be5011ca597b32c9d014817caff6fddae0	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	5
7523c347-b404-46a5-b57c-a40cccd97677	79f5b8b8-bafe-408a-98f9-cd7052d2fabf	{"category": "cinema", "field_key": "budget", "field_type": "currency", "description": "Бюджет производства", "default_value": ""}	02e30083fd6cc8f7c1d1edacf56b7ffbc03f056b5bcacf7b835c53013b3c878b	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	6
15a036db-3113-40b2-a874-f43a6273cca6	d388777c-7f10-433c-83c2-6bf149ab177e	{"category": "cinema", "field_key": "revenue", "field_type": "currency", "description": "Прокатные сборы", "default_value": ""}	a4979f71137cde51cd4ef258832ba69ddba2c8652a33362daa07d06a2b185dad	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	7
979a2c29-edd7-4e67-8d4f-a7dee7ba130f	498db061-e8a6-44b0-a3ff-cdfd55757832	{"category": "cinema", "field_key": "filming_locations", "field_type": "textarea", "description": "", "default_value": ""}	14891b4955a30787dd0b44dae133504200fc6a342ac3421aa37b173beb80eef0	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	8
d8b3e29b-3ec8-4797-97d3-9b8db494c400	dff416d6-31f3-40fe-93d7-901a1d6188ab	{"category": "cinema", "field_key": "production_companies", "field_type": "textarea", "description": "", "default_value": ""}	e9a946a764c2c200fce12496c9eafece0e03a0e5d5c01c49a42eeaf80287c1bd	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	9
df33ce66-a8c5-4f50-81f3-505d22357025	c868074c-92b7-4184-95a1-96585f8513b2	{"category": "cinema", "field_key": "tagline", "field_type": "string", "description": "", "default_value": ""}	7094e73f83ef4ec4dcef8b314f2260f61996b3ee8beef2e1fa7477986752b040	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	10
8eb7bdac-38bd-43bd-94a4-978e9a4aed6e	35d9f784-37ad-4148-8149-1a8afd70edee	{"category": "cinema", "field_key": "vote_count", "field_type": "integer", "description": "", "default_value": ""}	a1f97aee85f5f0c24464f05468fb9d60f6c80df35b90ff4daae1e240786db5be	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	11
503b6b78-4dd6-43f9-be50-7b88be1d5865	1bfdba75-8ff4-438c-8031-fd2c458b8a3a	{"category": "cinema", "field_key": "production_company", "field_type": "string", "description": "", "default_value": ""}	327cfc4930bb9f61c744041c3821cf505a12a3d92c96e51fb2204c992ff54c32	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	12
a0e8ba35-7996-4f8b-8505-6825caf99f13	e1564c6f-9a14-49a0-b61e-ed95fa7e4dd9	{"category": "common", "field_key": "title", "field_type": "string", "description": "Основное название сущности", "default_value": ""}	c23af4deb7ef4afa49c6d7581971ddb08b547d5297a68ff68344a949febcf71f	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	13
c9c97d59-d635-4105-9774-c7a99330d77c	a5712116-0fdf-463d-9675-bf679e839352	{"category": "common", "field_key": "description", "field_type": "textarea", "description": "Подробное описание", "default_value": ""}	c7980742bb5d40bd4e5f94734d2fe709c8cb852c73957f8a843d3fbcfd89485a	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	14
46285506-b9c4-4784-876e-288cf3bfb428	64fc8024-97f7-4a32-bf84-92b4a3bee934	{"category": "common", "field_key": "year", "field_type": "integer", "description": "Год создания или события", "default_value": ""}	73f69a6b58ee28538623fe1b252d778baf0d2eed4ed9a94357aef59f90ac735a	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	15
070dc9a7-03ed-4fac-9b68-3c99a8efd629	ffd77371-9d39-4909-bf65-14171c5abc6c	{"category": "common", "field_key": "genre", "field_type": "string", "description": "Творческое направление", "default_value": ""}	69bebd5d78f88d9477b01ccdd13a60a3ecfa6f449a3c04496d3658add2bcbe89	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	16
20022299-3be8-4aab-9010-15cf22baab0d	3ec191f4-cee3-4919-a021-167edf689348	{"category": "common", "field_key": "rating", "field_type": "number", "description": "Оценка от 0 до 10", "default_value": ""}	d43ce08c679a8b16c43a12e67921bf3f703dbf79b0bae8705550084d2127b6a5	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	17
6e6d778c-9966-4a6f-89b8-673d584e2173	3ac2c5f6-98d9-48a9-8316-ec9f2f70e099	{"category": "common", "field_key": "country", "field_type": "string", "description": "Страна происхождения", "default_value": ""}	00c85bd60f168f36d899cd0bcfde7b411bbf1efb08dadda89faec4577ebce9c7	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	18
1e535d61-4dcf-44bf-8df2-aec44149e41b	49565abd-66e6-4a5d-b319-56bab7f848be	{"category": "common", "field_key": "language", "field_type": "string", "description": "Язык произведения", "default_value": ""}	c4fea0be9f81912a9cb0cf56bdebb94502ab2339b1885ea8fc9d33ba4c7975d0	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	19
80a83159-32f3-4af2-80ef-d5a043f42131	1c0b5716-87c6-42bd-983e-9290ad79d498	{"category": "common", "field_key": "budget_mln", "field_type": "currency", "description": "", "default_value": ""}	ff3f3e6f5df7481aae09a6e5a4cbecbe978032f7d4729a29f4d3748958344a4f	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	20
b4223a7f-62ad-4376-91da-1740d77aaa4b	a3ce4e41-b699-4f98-bb53-cc5a5406cfe0	{"category": "common", "field_key": "duration_min", "field_type": "integer", "description": "", "default_value": ""}	621acff52bbbf86e7840fd6c201fb72fac37fd5dbe13e41c7506fc453805e46b	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	21
7c8a7e41-0142-4adf-b297-291ae0fe9242	368b6797-b54d-4b3b-9412-f0ac9b38606c	{"category": "common", "field_key": "author", "field_type": "string", "description": "", "default_value": ""}	bfcbb6593a8dc9097a400c87248c9520411239472fc8b6c165266357fe353db4	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	22
61638e73-a4be-40cd-a58e-081ce0a907b1	c52450a3-2125-4f32-aee7-3f2614d246c5	{"category": "common", "field_key": "pages", "field_type": "integer", "description": "", "default_value": ""}	61c8a9882f9dece1b7bbd5056ff3d4d76c8c9febf2fbf55eaf00cc97dc7b1f84	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	23
ad7a8845-1943-48e7-b35a-5c95cbd1aa96	746fa4bd-4206-41bd-ba53-75cfd03fa958	{"category": "common", "field_key": "isbn", "field_type": "string", "description": "", "default_value": ""}	249ebd46a18fa9b1c12d4eff065521dc722eaa7c1db50e1070961b982b295e00	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	24
fd8ca4c5-56e0-4b0b-8f47-b8c2ab89181b	1d1c2087-eb53-4bc8-b8f0-6d6068af521c	{"category": "common", "field_key": "release_date", "field_type": "date", "description": "", "default_value": ""}	7868658936ebab877fbbbe909fb0838af9fa7882c2038567e8f7b98f038e64f0	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	25
62289299-e172-4d10-8003-5bf56a74b9db	2aa77654-e4d5-4c0e-b784-f4218ab1ad08	{"category": "common", "field_key": "start_date", "field_type": "date", "description": "", "default_value": ""}	a181bc36ac7962e997538bddb6a77079b216b18d96873b92a00a56d2524bd738	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	26
7dc9dcba-ea6e-498c-a1bb-33162f12d27f	f44d5d50-c3ec-4580-afb2-d2d4f8e065b5	{"category": "common", "field_key": "end_date", "field_type": "date", "description": "", "default_value": ""}	d8a79ea47ae3c82b6f1be335a3dd41143a3a02e7dc67cba3b82a9fb40d7a193e	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	27
c84a6d1d-51e9-42d6-a261-f97a2b9508c2	da2202c1-f92d-4b1d-9f1d-107467681c8f	{"category": "common", "field_key": "price", "field_type": "currency", "description": "", "default_value": ""}	699ec5299468310e22197ee356ab490885d1904e748a68fb87d1a1badc63f3ab	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	28
b04626ff-ec1e-4c35-99db-77c660e6d4b4	94171a6b-9bd9-4a21-8f34-d53665f35e1e	{"category": "common", "field_key": "website", "field_type": "url", "description": "", "default_value": ""}	e3cdebba74416355064bdcf48ae82725ce3c3a936e4bd9a02d3130baa37f57bc	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	29
b84bdc6f-0c84-41da-81a9-8b3ab7832566	0a3891a7-d156-42bb-a51a-de8cd941a934	{"category": "common", "field_key": "email", "field_type": "email", "description": "", "default_value": ""}	0fe0fc44d867bfceea9cb787b612f1f9107aa07e9ad05431163a6e77c3009ec2	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	30
11a27cf8-e21b-4490-9d39-800ca4e117e5	6a89f51d-0834-4689-8b20-42eed4b812ae	{"category": "common", "field_key": "content", "field_type": "textarea", "description": "", "default_value": ""}	cfeb3f00fb72c08bd872a1fdccf2120de5caf8a63782ee4e2b648643f00ad92e	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	31
e799237a-c641-4504-97bc-301dca702194	95ca7c07-bdd8-4406-b84e-28195aa9cd5e	{"category": "common", "field_key": "age_rating", "field_type": "string", "description": "", "default_value": ""}	82d49bd41f5892e26a118496fa083cb433fb24f623221b8641b0a5f7c18ab5b6	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	32
58d06f8a-8ad9-46fc-98a6-25ae2b050d06	4bf10d13-0ee7-4664-b4d8-b66bfafdd520	{"category": "digital", "field_key": "version", "field_type": "string", "description": "Номер версии", "default_value": ""}	5dc16e0f309befc7461085bc95b6dabb8ad39ba365e1e232dad8c46bb382642c	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	33
c42d9456-d13e-48a7-a0d9-fb6e929f4de8	371ad544-6943-433f-b369-de19b08c5fbc	{"category": "digital", "field_key": "license", "field_type": "string", "description": "Тип лицензии", "default_value": ""}	44ec1b653414748757cb388c9872b50e22735e7d05b4f298e2c0da9f83e077aa	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	34
c15ea7b9-a30b-4176-97da-b45c42547f19	90a817d3-7618-4a6d-9774-8db27270da6f	{"category": "digital", "field_key": "repository_url", "field_type": "url", "description": "", "default_value": ""}	0d81540c43655732148010657c71e26615c3c54b1ce8804216f02bd5157c3e43	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	35
f5e2b4f3-3000-4bad-8859-d18758363d0e	615434d0-7fef-4b06-b981-acd9022cc588	{"category": "digital", "field_key": "programming_language", "field_type": "string", "description": "", "default_value": ""}	11f9a8cdf974536dc57c755f68b4a1209d4bd3180dbeb15eb958da86bb44e9b0	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	36
9f8a2805-60f5-422c-84c4-56a9a0f776cb	484f4eae-18c0-468b-bb82-498581abebb3	{"category": "digital", "field_key": "platform", "field_type": "string", "description": "", "default_value": ""}	f5e93671c8f93c8cb262746d16f5f2ad0e88d9182356d7f2d7b098cdce9aed34	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	37
0a404649-0185-4dcf-b13b-a7fa644b4605	1e59b752-79f2-4c5e-8535-dc94ea6457fd	{"category": "digital", "field_key": "developer", "field_type": "string", "description": "", "default_value": ""}	2fba5d83f2642e7b8e5cbe1602ce1a76548cb94fa34fcb05c0226c12eb045b61	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	38
fd15e8e2-d706-4c5e-8b86-c76dbb2d6405	492fc7d4-17ee-436b-839b-585911c3f534	{"category": "events", "field_key": "event_date", "field_type": "date", "description": "Дата проведения события", "default_value": ""}	d6048b7677c99fdedbb64d40d869d9c048d70e8dfea7828ac36eb80eebd5633c	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	39
3d8206af-38fb-4b6c-8d65-3c00059a6aef	9cb5574a-9d68-4e52-88e6-86df8fc9c042	{"category": "events", "field_key": "venue", "field_type": "string", "description": "", "default_value": ""}	4d2446dad72bea58fc2073fd0101a78bdb562d4662e5c9fdd4bf0e5640bb94d3	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	41
d05e7593-6daf-4050-a03d-92cd55b7f4ec	80741c32-8c89-4a1b-ba0b-dd5229c3d350	{"category": "events", "field_key": "organizer", "field_type": "string", "description": "", "default_value": ""}	cf28fc7e6c3a8c075d3fc74aa30c62cf5b5d5a604144dbbec2a044b0b3dba2f3	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	42
d9118374-a9b7-49c0-9312-815b3653a9da	2ff0d1ca-25db-4cfa-916a-3b8e7320a5dc	{"category": "events", "field_key": "attendee_count", "field_type": "integer", "description": "", "default_value": ""}	bdbbafb4ed7c7488ccf33b6265e2c2dbc806bd9f9117073ab35ab4e0bdbd2629	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	43
77cfe33a-a0d9-44e2-9a82-b91e926d0d57	67c78432-6fe5-4e99-ad28-c3b0ca0f0aed	{"category": "events", "field_key": "ticket_price", "field_type": "currency", "description": "", "default_value": ""}	395d38eb4da32debbc32365ace21b702929f94c1bff22605f32d19267229ce88	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	44
1fff2c62-24a3-452a-bd63-1baab0bae4d8	5c7bed9a-99fa-47c1-a536-93ef4efbd723	{"category": "gaming", "field_key": "game_engine", "field_type": "string", "description": "", "default_value": ""}	d71b150fc6a275a347bd133b2ff326e8bf1e0d7f178db63e9135456302e08525	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	45
4bd6ac19-1230-4a9d-b27d-60504cc52011	8337e034-fd16-4929-b347-a880acd18de7	{"category": "gaming", "field_key": "platform_list", "field_type": "textarea", "description": "", "default_value": ""}	6635a768e0f6c609d93110b5b8b85d737386e5bc6c71d973bf4149d79ee28d4d	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	46
9631f2a8-38d1-4023-8e09-3b3efae43c1b	8e7e8675-8148-471f-a774-3c7778ca6814	{"category": "gaming", "field_key": "player_count", "field_type": "string", "description": "", "default_value": ""}	bbc16ca1c9e4c9bed4f2ab5056569d986b2e0647ff987bd8ccf0fe797395b469	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	47
1c33801e-886e-4854-a378-25c35d296281	29d1489d-3e09-4344-816b-2dc40e4aaec4	{"category": "gaming", "field_key": "esrb_rating", "field_type": "select", "description": "", "default_value": ""}	ac11cd99c41bb9bbcff83cb7e2ca68a11b4491c6a206042c30b3495d48560f0d	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	48
ca5be4e1-b8ea-4d45-b98f-4387d72c7311	a9a71003-f04a-4955-8134-ab6edc4936d9	{"category": "geography", "field_key": "latitude", "field_type": "number", "description": "Географическая широта", "default_value": ""}	98c1adf53a5a51cadac30f85a162e17ad1e2ed7249ccd6eab82b8fa1c12295b6	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	49
84438eb7-a191-47c2-a721-9bb2bf16f1ad	79a3c791-db99-41cf-8b1c-c36f24f2c311	{"category": "geography", "field_key": "longitude", "field_type": "number", "description": "Географическая долгота", "default_value": ""}	4e8a6d0193d96912b5e5687764b5410786408b8d5aebd0948123d3e4b497d709	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	50
682f1ec7-0084-4935-8c7e-dfb6d4ce6ee1	ab8b1931-8121-4f85-8013-74e7d8b4b030	{"category": "geography", "field_key": "elevation_m", "field_type": "number", "description": "", "default_value": ""}	6b088ca8f11fc727bf067e44a4c5ce7f85c946fdcf8192ecb1165b075721f827	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	51
8512957e-e09d-498a-aa40-e0673098edca	384ae166-d14f-4651-9895-24eda080e68f	{"category": "geography", "field_key": "timezone", "field_type": "string", "description": "", "default_value": ""}	23a5a3f532fde7258693d3e8c6326a6538b2d5e39c0ca4bb679bf8aa1f628b3f	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	52
ec883bda-5bcf-4d79-a254-5ff77b777df1	26de2206-78e6-4a79-b30c-13886de6b364	{"category": "geography", "field_key": "area_km2", "field_type": "number", "description": "", "default_value": ""}	3187f1e65809d74def4af5b617856544cd5f95996592b092f6a4a6ab37167d42	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	53
626a88ef-9fb7-47d2-a586-4a306cb2c40a	e8e8e9d3-1abe-4ec6-8e9b-7fd910c1b9ed	{"category": "geography", "field_key": "population", "field_type": "integer", "description": "", "default_value": ""}	fb78f542e4338ae755d6be98053bba201bdb8b0fb952e2654c19cf0100ae5060	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	54
e88f02a1-3a59-447c-a3b5-57621baad5a9	9d229778-1624-499e-90c9-dc084b168c83	{"category": "geography", "field_key": "postal_code", "field_type": "string", "description": "", "default_value": ""}	441321a26781e95b6cf5eee63470e19bb9e9bec8c87363304d1ae646cb93a896	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	55
6ddafb59-ea90-4e26-be95-f5223c7d619c	2228b134-2e7a-43b7-88f8-571181f950f6	{"category": "geography", "field_key": "iso_code", "field_type": "string", "description": "", "default_value": ""}	1f137214211c8e0bf08c7a69c7c5da8339715fa4d319769c2d78682ca19394e7	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	56
44f667d5-7bf3-40fb-94b6-c6cc0e603167	87c617b9-5519-4547-8ac1-f00a75a2c2b7	{"category": "literature", "field_key": "publisher", "field_type": "string", "description": "Издательство", "default_value": ""}	2a9c3b3785beeb8e36aa12d96ea9cc9807a7d37ec69d16608c30badab691a0b3	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	57
601327dc-e340-47fa-949f-52d8df4adf47	3a385266-3bce-4142-8fdf-621b4c8d520f	{"category": "literature", "field_key": "publication_city", "field_type": "string", "description": "", "default_value": ""}	a318dabced1a8c9a78cc7ac5e2e62125be09462c4468d0fddc5872aab0d26d93	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	58
90188d6f-5879-4141-b51f-3dfb7fa73698	9f026194-d5d6-463c-92b9-8054457151c7	{"category": "literature", "field_key": "edition", "field_type": "string", "description": "", "default_value": ""}	9cba0550915f8358d91bdd61f35eb4595b1f2afc89ba29312905e6b5d7746340	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	59
191ea1ce-444d-4a60-9fda-c721e246594d	1d58a9ef-d735-4bd3-bd33-2842c8915ba1	{"category": "literature", "field_key": "translator", "field_type": "string", "description": "", "default_value": ""}	27bb3b911818c2a61c666e574c17b5d499eda052361093ff4a32fb73986926e4	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	60
c21af767-8123-49c0-b7dc-a15c8e909f31	d654e391-c767-4921-8561-2c413eb1258f	{"category": "literature", "field_key": "original_language", "field_type": "string", "description": "", "default_value": ""}	afd501976148507e3ac5c7dbb99580a48b3e9420d984c0fb077a3cfcfc4d4fb8	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	61
560dd2ec-fd03-483d-8745-162e4b337674	482f6a8a-b030-421c-b6fc-305ed48919a0	{"category": "literature", "field_key": "dewey_decimal", "field_type": "string", "description": "", "default_value": ""}	24b42e0ce88ddc927230469c902f3a755e647a117af8d98eefd6554fe43d3de9	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	62
c6a65c80-3d2b-4e8b-958c-ed954a4cd834	d22c2238-4232-4afe-8d00-b1693d1b30c4	{"category": "media", "field_key": "poster_url", "field_type": "image", "description": "", "default_value": ""}	048430ce9294bf7afd1a961782f3f7da75abed6252a8d7ebb727a1ed46b317f7	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	63
92b3ed66-3f09-4c6e-a6e9-631ec12f126b	b492c9c8-0350-4767-9266-fdd41792f2c2	{"category": "media", "field_key": "images", "field_type": "gallery", "description": "", "default_value": ""}	08948132739fe20186937d26579ced9b6f529dac80b0e7b2fef002d3ba7a825b	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	64
5ebcb20b-cffc-4621-94f8-a062b332dcb7	cae416c5-f4bb-4856-8b13-ace066ab380f	{"category": "media", "field_key": "video_url", "field_type": "video", "description": "", "default_value": ""}	bf887a7b5acea2ce40805a3d317d0c832195551104cd06112a359f11c0a1f3c4	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	65
cc55c935-19e9-4c07-9ef6-5c4d1a793016	33705540-a911-4a4f-a671-11528b1721b0	{"category": "media", "field_key": "audio_url", "field_type": "audio", "description": "", "default_value": ""}	53e27d16595e656e6e589d9f6b32108bdc9b56e387f05ec804de50d4eef53284	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	66
5b043be9-4460-4735-b78d-9ac026a3b50c	21383ea7-9d46-40aa-978f-a1b8483eed2f	{"category": "media", "field_key": "file_url", "field_type": "file", "description": "", "default_value": ""}	fe2114f6edcf54949bc9fc65fd14380e89c11767f4778a97fc41a8c24ab72564	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	67
12334217-c598-45ed-b5a2-23c7a1eca81f	1810fe56-1c22-4e85-a4e3-b9a243b07fb5	{"category": "media", "field_key": "file_title", "field_type": "string", "description": "", "default_value": ""}	6459d0bd7bfd63761aa83846feece03fe9331bcae2bb2b605c6298cb54b08455	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	68
abca6627-d67e-4307-b7fb-c0eb0f62a109	58c99745-40c2-43ac-9853-567fc2be8b91	{"category": "media", "field_key": "episode_number", "field_type": "integer", "description": "", "default_value": ""}	1d29ed8dfece356349846eb14032766d2adf9a4dbde8cb391aa591444b6ee424	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	69
8382417b-ce11-4f3c-928b-507e323ae6a7	11b4df6d-2ef1-43ae-8969-189dacad2995	{"category": "media", "field_key": "season_number", "field_type": "integer", "description": "", "default_value": ""}	2bc7132008be91891c24719aa070768f8fbf21ed45bdb166cc4dd006513eedff	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	70
36cba080-2c1c-4022-87b7-71c4645beaff	6777ba71-9878-4308-b161-4617e06314f3	{"category": "media", "field_key": "podcast_url", "field_type": "url", "description": "", "default_value": ""}	a295ebb1c43ef0f59fa92dcb97b04a7d6f18220605f1fd866654c65c33e4ad99	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	71
9f4a450a-0ee4-4db8-8535-11e53a937b32	ed260cb0-5287-455b-b965-6cdb0116c330	{"category": "media", "field_key": "channel_url", "field_type": "url", "description": "", "default_value": ""}	5f34ddfd7ff9d5c40a04b87e32afa4e2fec69b8a6387cad8a80df759272eeabb	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	72
40834f47-981f-4021-9213-bf28aa0d85de	ccef9f98-353c-4c09-b4a3-65d90cd80fea	{"category": "music", "field_key": "artist", "field_type": "string", "description": "", "default_value": ""}	bb2b787610ee01233b84c5a3b6be56998fe67e8e8d68fb1187395bfa823c9e73	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	73
f42d842e-645f-49a5-93c3-b62c8a9d9930	aecd4f88-a028-4cec-9f91-94d6ac3948c8	{"category": "music", "field_key": "album", "field_type": "string", "description": "", "default_value": ""}	74f9ff837afcd650f34a7b6cfb95c37a553815403f7c4243ea06cb6fd58991b9	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	74
8ff1bff0-f73d-4d5e-a047-a136e7a90925	8544fcbb-7059-4a63-b1b6-8186b6b576a5	{"category": "music", "field_key": "bpm", "field_type": "integer", "description": "", "default_value": ""}	12b82e2588ad5dbda87676026ff49400393431068f4c2647650901ed5a2d623e	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	75
6b7e8b0d-9a62-4c00-9cb8-ad0bd3b5688c	12ef5fcd-7210-40de-abd2-4c40e8bd9a18	{"category": "music", "field_key": "isrc", "field_type": "string", "description": "Международный стандартный код записи", "default_value": ""}	366cd789725f9c8ece698bdc80f84993d35f3b9b66b42b1829c9c43d6092d022	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	76
5730b76f-1b7f-4116-b5b1-e41811194be2	d65d5a5c-43bd-4d71-b2b7-2942b5f3476e	{"category": "music", "field_key": "iswc", "field_type": "string", "description": "", "default_value": ""}	7e4b0f534a1bb91be27f3f5756925f4db1f6ff3e14b435e53c221c7322961ac9	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	77
b01fcba8-cb54-46cd-bfb3-50e983ef2f12	88589abb-9bec-4664-8ad8-cbd801dd0810	{"category": "music", "field_key": "track_number", "field_type": "integer", "description": "", "default_value": ""}	0ae82ceda34d3139d462d7e6a77cf08881e8856cb592fe7bc2c369c7446f8911	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	78
4bc87937-bf28-459b-a2c9-2728ae5ff877	11773243-6369-4263-876f-9db7b55cf699	{"category": "music", "field_key": "disc_number", "field_type": "integer", "description": "", "default_value": ""}	b68aeeb9ddcf0738ac766198e4a61eecd0d7f43ab564309e45075030aab56b94	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	79
b4ee78db-4c16-4630-a6ff-331e15596aaa	2c57fddf-b66d-4630-a152-8b8261567361	{"category": "music", "field_key": "explicit", "field_type": "boolean", "description": "", "default_value": ""}	4dcf7126760148daf3e71dd1a90cd5cc40a8d8f5736a4b3e0fa56526d5fde098	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	80
7143f87b-6ea8-4c15-a461-aa82e6c7069d	3e5da6e4-1596-4c0e-a4b9-410cb4dc5ea6	{"category": "music", "field_key": "key_signature", "field_type": "string", "description": "", "default_value": ""}	15f095cb0353ba3303ca012a8043cae9c795724fc97bf187cb898fa24f037c53	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	81
7f6c2e02-69d6-4c83-9984-87a7f7d1d495	7309d0a4-4ac8-426f-8e6f-332e37491cc5	{"category": "music", "field_key": "time_signature", "field_type": "string", "description": "", "default_value": ""}	1a34d59d01215f7eca1c615db05296eec71d31270599c49c98f9f738ff4d9a1e	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	82
456e5c03-3456-4498-8d40-34e920cb49c0	76b46f0a-9f15-4bb1-8ee7-ac707fb27182	{"category": "music", "field_key": "label_name", "field_type": "string", "description": "", "default_value": ""}	d492a0c8b03be70904daf17cb1246d3bc92939e36ae1b7c5de75d4cf8b9c3c2e	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	83
133e7704-759f-4615-b178-74008990f6a1	1b3f033f-5210-44b9-9e1c-c62e28cd4403	{"category": "organization", "field_key": "founding_date", "field_type": "date", "description": "Дата основания организации", "default_value": ""}	3e4c59a4cdf3a75043c8e661a4e107e2876aa7195c663a2cd57b029fccd73c64	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	84
4ff9a69a-9a07-43ae-9334-7392c1059ffb	cd16a2da-ac67-4906-9a7d-4016d3b0e292	{"category": "organization", "field_key": "dissolution_date", "field_type": "date", "description": "", "default_value": ""}	5dd5ec1901cb1f9f064ef5c790ef4a279f6af3d1ea699ff11927757b89368473	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	85
70efd255-800c-4662-a4be-0a5546d5bbf6	dcc5d2f4-6295-474d-af9a-98d3a84f646e	{"category": "organization", "field_key": "founder", "field_type": "string", "description": "", "default_value": ""}	d410d80cadf7329d556579ffc51d1c0b3edbbfaf914f68ee3d8efecfaf7c3c13	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	86
db765273-8883-470e-ad89-082faf6d7a16	551802fa-72aa-4092-9c0c-657d77486af8	{"category": "organization", "field_key": "industry", "field_type": "string", "description": "", "default_value": ""}	d0080224fdaed5e1fedce52c8591eaa0c3936bf0fba4b75fee441a6bd40b784d	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	87
15c7ad44-92d6-43a9-a8f7-bb4fae36e715	c626d9f2-3236-41c7-b6ee-199763f329e0	{"category": "organization", "field_key": "employee_count", "field_type": "integer", "description": "", "default_value": ""}	70a8ceff090159479320a91e2542ecc697f596b55342f518a4ace8efa57b8c79	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	88
6d264625-47b9-40b8-84de-87ce6b0f33c7	d9741933-745a-4384-b37e-da726a36a224	{"category": "organization", "field_key": "headquarters", "field_type": "string", "description": "", "default_value": ""}	54f860857bc83b5f8a102fb9d113840b014e5e7052ef7256247b3821d377cfcf	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	89
fd96bd11-0791-42e4-b2f3-14e906309fab	a27e21d9-9ded-421f-8668-c4c2f35aaa4d	{"category": "people", "field_key": "first_name", "field_type": "string", "description": "Личное имя", "default_value": ""}	07ef3ea18a7f3d4e97a6b4df8beab11dc2f7808ae1285f8da948a7d40ae5a2a1	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	90
0a75f1a1-3a83-4bda-a347-44a9cd7d8c6b	2ec64319-39be-454b-bf9a-41a61d6a5f02	{"category": "people", "field_key": "last_name", "field_type": "string", "description": "Фамилия", "default_value": ""}	0ed4f9604b0247a72fb2547c5c55d89081bbef2cfcc1d632b1ce42cd235f2802	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	91
5977b5c2-ee32-4472-9745-0914329c33bd	94d5c309-867a-4c9e-9ad1-32a5e34fd348	{"category": "people", "field_key": "patronymic", "field_type": "string", "description": "", "default_value": ""}	014625623277ba67d5fb2bf6ef13c0f4ffed1ae704ae38f69c395630e8600152	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	92
708c1edb-6da0-4b2c-9630-f44488edbf5b	f4cd7b51-6218-4555-8b8e-1cfce2564071	{"category": "people", "field_key": "birth_date", "field_type": "date", "description": "Дата рождения", "default_value": ""}	24e2cf8c41d5cd9552cf6e4c353a04aeeaa9584d597a12c1febad10bd5667cc6	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	93
69d6da85-954a-4cc7-b093-798daba89f21	184292ad-1f42-4393-b1e6-3a4de1ca8b38	{"category": "people", "field_key": "birth_place", "field_type": "string", "description": "", "default_value": ""}	4e47560c67984bbdaa1e4f597e60f42a18d33fa7bfa9b803151c97827411949b	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	94
32886ab8-a58c-4205-9f4d-e5f6eacc97e1	de698b95-3b52-4d96-bd3a-58c7469a4555	{"category": "people", "field_key": "death_date", "field_type": "date", "description": "", "default_value": ""}	1ef5299c3c668386d00a283c9caf549b1421d68f5ea4385f7fd007bc15c20881	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	95
49c0d1e8-dbd2-4759-978c-babf45d35bbb	6d7bf38c-5b10-4ebc-9aef-6d845dac8205	{"category": "people", "field_key": "death_place", "field_type": "string", "description": "", "default_value": ""}	e015323948d1077e905d66aaead6987f2988ea5baf3e64eadecae8107eda92ea	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	96
8bde76a9-2484-4a02-97d7-ce28c4b266ec	c1950488-6228-48f9-9a11-beb88bce58f1	{"category": "people", "field_key": "height_cm", "field_type": "integer", "description": "", "default_value": ""}	3f058cde9cb69d547d5f2e66874ab316369e1cb3c08d767e13ba2459a6a377dd	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	97
69b36ff7-9357-4f69-9537-216284cdb5a4	003e5c0c-47e5-4492-b6b4-eb12efda80ae	{"category": "people", "field_key": "nationality", "field_type": "string", "description": "", "default_value": ""}	fd356a76eeda92f11b8ffeb755e9d3493f2149fb98f0cd3a8e2e8f2f0d197275	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	98
f6bfd515-8d4b-48b6-9547-164be5132638	5f7a5784-15a6-4f9d-9884-61bd98324ab6	{"category": "people", "field_key": "occupation", "field_type": "string", "description": "", "default_value": ""}	ecf6b1dc9e3a5784d201b85b0a0ac704006e1f2d09fa4fa52ffaafd0f07fa070	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	99
fc31e543-6629-40b7-95b3-c44a9d50ce2d	1567fd8a-7b94-47e8-96fe-8f8641809c8e	{"category": "science", "field_key": "electron_configuration", "field_type": "string", "description": "", "default_value": ""}	13ec07bcec6e632e5e54f1f78336adb3b285e9f64edfc4076f62830efef073a9	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	100
e346b10c-209d-4461-b329-bbac4db05e6a	686f087e-34ee-4574-8f58-9c4e2afd099c	{"category": "science", "field_key": "oxidation_states", "field_type": "string", "description": "", "default_value": ""}	a5f365d7718a6600f7d8c24e0c49d88bf6046f2a97800bebbe1d75bdbade1422	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	101
e9a5d252-651a-419d-aee1-73b33b5ffc84	b662b658-dca9-4302-aec6-6cf4e73bb496	{"category": "science", "field_key": "electronegativity", "field_type": "number", "description": "", "default_value": ""}	f970368e504e15ce6b5260dd0dbd86a1b15764a049b7f0619b10449200c6c6a8	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	102
01135dcc-195b-45a8-919e-ba74840938e9	bdd16d74-7297-4206-8d87-972230f19db8	{"category": "science", "field_key": "density", "field_type": "number", "description": "", "default_value": ""}	922e5159c2ead25991ceee679e4b7e6beacec93bce2fc14be30b40886a1b3ada	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	103
d44400c1-d04f-4d5e-9540-03dba22f1da1	2449f3e9-e2d5-4977-983f-f7cce47f2ce4	{"category": "science", "field_key": "melting_point", "field_type": "number", "description": "", "default_value": ""}	65a4dbb499cd14b52ff8d08066c7f60ff4b1d05ac45c3557ef464608ed837fb9	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	104
2d806c89-f25b-41c2-90a3-8f6571c1d887	8d0976da-245a-4c4e-9c4c-1ae975251217	{"category": "science", "field_key": "boiling_point", "field_type": "number", "description": "", "default_value": ""}	4db8ed15c6dc670332763cfa991f0c94d747a538bf44d80202098e8eb773e3ca	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	105
75fb8a61-49c9-41a5-bfae-e452be3fbc63	546bba61-f80f-465c-80f7-1384f129987d	{"category": "science", "field_key": "discovery_year", "field_type": "integer", "description": "", "default_value": ""}	631766cff27b5b2692fae1d302fc880e5e7e31ddd3a097fe90ccdddbc0d67b4a	\N	t	2026-07-18 20:54:48.348206+00	2026-07-18 20:54:48.348206+00	\N	106
fee53706-9a7c-4d0a-a14d-d4ef16ca974c	e0000007-0000-0000-0000-000000000001	{"isbn": "978-0-441-56956-4", "year": 1984, "genre": "Cyberpunk", "pages": 271, "title": "Neuromancer", "author": "William Gibson", "poster": "http://localhost:9000/dwmb-media/entities/1ecd1e93-4eef-4ecb-9ff5-b77c1c4211c3/%D0%BC%D0%BE%D0%B0%D0%BD%D0%B0.webp?AWSAccessKeyId=dwmb_minio&Signature=tFS7at0Lpk70OYKc3kAkG0qjbdU%3D&Expires=1784411912", "publisher": "Ace Books"}	6e29c57d3aaef0e242ef204c3d86e62460eda5d0842f02c090fcfe9306ffd4c6	\N	t	2026-07-18 09:57:12.402007+00	2026-07-18 09:57:12.402007+00	\N	1
ea007d9c-d225-4bef-9562-36b834047b6c	8f36c2e9-61b1-4952-9304-94d0a3ec7b39	{"year": 2025, "genre": "Sci-Fi", "title": "Test Movie", "budget": "100M", "rating": 8.5, "country": "USA", "tagline": "Test tagline", "director": "Test Director", "duration": "120 min", "language": "English", "age_rating": "PG-13", "description": "ÐÐ¿Ð¸ÑÐ°Ð½Ð¸Ðµ ÑÐ¸Ð»ÑÐ¼Ð°", "production_company": "Test Studios"}	032a2d3ccbcaf2e73b36e7805237e1503ed57f7e7a8233fd3b207cc5ee362b18	\N	t	2026-07-19 07:04:44.883534+00	2026-07-19 07:04:44.883535+00	\N	108
b26eba65-f109-4df5-8e95-b35af579a4f8	395510c6-4513-4f54-9236-aa9f62977416	{"year": 2025, "genre": "Sci-Fi", "title": "Test Projections", "budget": "50M", "rating": 8.0, "country": "USA", "tagline": "Test", "director": "Test Dir", "duration": "100 min", "language": "EN", "age_rating": "PG-13", "description": "Test desc", "production_company": "Test Studios"}	b19f5dbd2bf9efcc3739902e9a086f9afe8f5cb695721e6edc7c48a919580a19	\N	t	2026-07-19 07:43:09.84009+00	2026-07-19 07:43:09.840094+00	\N	109
8ba2227b-afa4-47fa-b4c8-7991c49801d6	80309641-c837-40e4-a83e-1f07f860191c	{"title": "Multi Type Test"}	fd139b1663f735164a0792c03c31b1519780d64ba6347aa93a4d34d7f4a28879	\N	t	2026-07-19 07:52:26.819453+00	2026-07-19 07:52:26.819454+00	\N	111
ce16d25c-33f3-4aa0-a481-c392ec2e88d7	9f298edf-a368-4c39-b24a-333b9aa1f3b2	{"year": 2026, "genre": "Sci-Fi", "title": "Multi Type Test", "budget": "100M", "rating": 9.0, "country": "Ð Ð¾ÑÑÐ¸Ñ", "tagline": "Ð¢ÐµÑÑÐ¾Ð²ÑÐ¹ ÑÐ»Ð¾Ð³Ð°Ð½", "director": "Ð¢ÐµÑÑÐ¾Ð²ÑÐ¹ ÑÐµÐ¶Ð¸ÑÑÑÑ", "duration": "120 Ð¼Ð¸Ð½", "language": "Ð ÑÑÑÐºÐ¸Ð¹", "age_rating": "12 ", "description": "ÐÐ¿Ð¸ÑÐ°Ð½Ð¸Ðµ ÑÐ¸Ð»ÑÐ¼Ð°", "production_company": "Ð¢ÐµÑÑÐ¾Ð²Ð°Ñ ÑÑÑÐ´Ð¸Ñ"}	804885e2a195c852a105f3a0bb502da96537d4022e13b558aeb90405926b7b24	\N	t	2026-07-19 07:51:47.83779+00	2026-07-19 07:51:47.837792+00	\N	110
d35865cd-5c4e-4db7-8319-94c848faced7	b383f10f-0633-4e70-9967-220e96592ef2	{"title": "Академия ведьмочек", "poster": "http://localhost:9000/dwmb-media/entities/afed8c62-00d3-476b-a20c-2b8173d303a6/%D0%90%D0%BA%D0%B0%D0%B4%D0%B5%D0%BC%D0%B8%D1%8F_%D0%B2%D0%B5%D0%B4%D1%8C%D0%BC%D0%BE%D1%87%D0%B5%D0%BA.webp?AWSAccessKeyId=dwmb_minio&Signature=oWdRJrhdannybl03Irt348BEJLY%3D&Expires=1784452040"}	5939d5008c470310fb1a115fb44bb8ff6f782565ee84237e11a8db10edf56aab	\N	t	2026-07-19 08:07:20.049965+00	2026-07-19 08:07:20.049966+00	\N	1
88d576d1-6d0b-4a5f-8645-5cd303f40d6d	81dd7447-5918-4549-8142-f365fcc09f5b	{"poster": "http://localhost:9000/dwmb-media/entities/afed8c62-00d3-476b-a20c-2b8173d303a6/%D0%90%D0%BA%D0%B0%D0%B4%D0%B5%D0%BC%D0%B8%D1%8F_%D0%B2%D0%B5%D0%B4%D1%8C%D0%BC%D0%BE%D1%87%D0%B5%D0%BA.webp?AWSAccessKeyId=dwmb_minio&Signature=oWdRJrhdannybl03Irt348BEJLY%3D&Expires=1784452040"}	06268536b3e8899e2eaa9fb5ec3f49eab28e1dd3d375a6a5eafcdc973b8e9ddb	\N	t	2026-07-19 08:07:03.111061+00	2026-07-19 08:07:03.111063+00	\N	111
0cf26b8d-5568-4557-b509-2a85ae25a3d0	00ae4bbc-d0c5-4096-872d-f53ef257adef	{"domain": "art", "model_code": "cinema", "description": "Кинематограф", "template_count": 4}	fd0652312c54bc820e4a83837f3c366630ca09c246d8c12e0e1c7a0ceac116b4	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	101
bbb51c6a-c862-418a-bd34-bb1feaf34418	6c06e605-d3ce-4f03-a871-ef44f689c56b	{"domain": "art", "model_code": "literature", "description": "Литература", "template_count": 2}	839e582a1e95b61dbea2e11b99cc5911a1683bfe9ee685588c1c87d7eb609d67	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	102
6eee69d9-010b-4f4f-a55d-9c649a7a6fbb	7a0161b2-a41b-4bcb-93f4-7cf00ee9a854	{"domain": "art", "model_code": "music", "description": "Музыка", "template_count": 3}	d34c38ef5bb8312b7d8481c88c380281cef0e6c14074e0197285b1276acf297a	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	103
070a005a-c600-4d3a-854b-48f577195006	ce7ce781-ff4b-49e2-9391-5519fb4e54af	{"domain": "digital", "model_code": "technology", "description": "Технологии", "template_count": 0}	a8966f2c204a6c08bdcd87ae9af3f2085f961bba9cee2965cc975c3b4280b56d	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	104
ec5e0589-4575-498f-b4f0-1b8fc516cc61	fbea994c-76c5-4d85-a287-bf04a4457e44	{"domain": "general", "model_code": "default", "description": "Базовая модель", "template_count": 11}	518741b3fe6f884a189ce0bc303a3e5d0fbef40f72b77fd2c898d8b92d24f784	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	105
9bf28f6c-db34-4090-a13b-a32801220119	3370b93b-389c-4ae3-a7f0-2de9cee6e930	{"domain": "meta", "model_code": "field_model", "description": "Онтологическая модель для полей реестра", "template_count": 1}	606fbff106932cc4d8947f4d33026c746a6d3a94e9e46f51db71b91233fd0d86	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	106
8590424e-01d3-41fb-97d9-6b4f73e6fd66	7e7c4fb3-8324-4934-bafe-634b3de1651f	{"domain": "meta", "model_code": "ontology_entity_model", "description": "Модель для онтологий как сущностей", "template_count": 2}	7f6b685e7d113341e76af0fcc0d98a70365a4fa33740832eae0dd9b1849b00a4	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	107
74772623-c1db-487a-a417-16eaede36236	a7bfca28-7ce8-4289-95e8-0b47b11ed190	{"domain": "social", "model_code": "geography", "description": "География", "template_count": 1}	df43ae6bc8d40e93663d0b119908e908be255b149d4dca83d724b9d182acc852	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	109
52b89efa-9e2e-4a18-9c34-e2d1ead12ed0	94c08ef8-4d15-4bad-b497-f27397da677a	{"domain": "social", "model_code": "history", "description": "История", "template_count": 1}	b1eb2b51bb272293f39c9e993b88292a24e3f1da72d5aa739fb998ec9fc87d34	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	110
5a6eced6-f4d4-4688-baaa-618908074c44	e5f40263-8e70-4531-ab70-f2a4ee095e3d	{"is_active": true, "kind_code": "actor", "model_code": "cinema", "description": "Шаблон для Шаблон: Человек (персона)", "template_code": "actor_tpl_person", "template_name": "Шаблон: Человек (персона)"}	6a5c120835535e617a69f687286ca33fe94c75a2cce23924af96997a12a0d639	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	112
91443d60-f134-4721-8928-25250c2e495e	27d7fe31-8197-4b46-9596-f173b3574251	{"is_active": true, "kind_code": "album", "model_code": "music", "description": "Шаблон для Шаблон: Альбом", "template_code": "album_tpl_album", "template_name": "Шаблон: Альбом"}	e0e2cada12d6d0553a7f3b2c570314613defc5d76b8908919dca0786a806b8b9	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	113
456d2a54-794e-4d78-8eaa-15cab5ee94b1	cff4ba60-3c03-4677-915e-886ee06bcaec	{"is_active": true, "kind_code": "book", "model_code": "literature", "description": "Шаблон для Шаблон: Книга", "template_code": "book_tpl_book", "template_name": "Шаблон: Книга"}	8e26e91a800051af74e44fefaba17277b31e07578db9f12867eb0e56ccfa555b	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	114
bd0cf6ef-7655-4e78-b098-02a2c3bde666	9915a57f-9fea-4ef8-9cd9-0a545be890cd	{"is_active": true, "kind_code": "movie", "model_code": "cinema", "description": "", "template_code": "digital_file_Clip", "template_name": "Шаблон: Клип"}	93e2c705a7258eaffac860e8b7f3282172da4500bb1c2f4c2f96840b3ce8de5e	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	115
56dbed0f-54f6-4333-8249-305cb3ad53a4	e19b828d-3d7e-413e-9d7a-97d60ce23cc6	{"is_active": true, "kind_code": "director", "model_code": "cinema", "description": "Шаблон для Шаблон: Человек (персона)", "template_code": "director_tpl_person", "template_name": "Шаблон: Человек (персона)"}	ae811fdf85845f12e3c7afc922292e59c4f7e546026224475a4b408b493a03e9	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	116
aadffc93-613a-4b2b-91d2-2590e512e451	3cd97617-8bf2-49d4-ab45-a62a26b4bd65	{"is_active": true, "kind_code": "musician", "model_code": "music", "description": "Шаблон для Шаблон: Человек (персона)", "template_code": "musician_tpl_person", "template_name": "Шаблон: Человек (персона)"}	9a36c9f49d555890ee6ef2a0e87f4e5bcb12754672c9a704d969a2647beb334c	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	118
023c589b-8af4-42de-8f59-08bcb44e9a70	572cf813-bc7f-4352-8da2-84b648cfd938	{"is_active": true, "kind_code": "song", "model_code": "music", "description": "Шаблон для Шаблон: Песня", "template_code": "song_tpl_song", "template_name": "Шаблон: Песня"}	e8ff227857505eb55365fdbea2e591a8728cf84d5ae6c600b06a171bb4c8fcbd	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	119
dfe0313b-1869-4b8e-b521-acd3c0c070d2	b7956d4f-f477-453d-a0ce-2e7a431dda31	{"is_active": true, "kind_code": "writer", "model_code": "literature", "description": "Шаблон для Шаблон: Человек (персона)", "template_code": "writer_tpl_person", "template_name": "Шаблон: Человек (персона)"}	ddee356522bf5a862dab9067b024f3b83831c156e7afddc2ec198429ce24215a	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	120
41296222-d9cc-412d-804e-198381a2f149	78b54b36-da0b-4be0-bd46-c4ab7b64338c	{"is_active": true, "kind_code": "", "model_code": "default", "description": "Шаблон для Шаблон: Статья", "template_code": "article_tpl_article", "template_name": "Шаблон: Статья"}	a72d251a6342471780da145bec1bebaa7f3905b3633e53830bc6b7e4ea907d1e	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	121
d24f4ba4-c305-427d-a26f-d0d2ee76b878	cf459fc7-7d0a-4d39-a036-1a5f8c93eb5d	{"is_active": true, "kind_code": "", "model_code": "default", "description": "Шаблон для Шаблон: Человек (персона)", "template_code": "artist_tpl_person", "template_name": "Шаблон: Человек (персона)"}	dd59638f4537bdf58b4a6fa0e5fa3997b7dfab17c1c5ca455eb536a0659689a5	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	122
f473634b-e84c-47d9-b1fd-b6a433fe2329	127b4031-fa26-4094-834f-092f0a95b940	{"is_active": true, "kind_code": "", "model_code": "default", "description": "Шаблон для Шаблон: Классификатор", "template_code": "classifier_tpl_classifier", "template_name": "Шаблон: Классификатор"}	cddf8c6c0364e688b0fc6416daf4ef78a1f2c08eb3c318f9d3b845018a14ad52	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	123
9d67f197-1b19-407d-ad0e-2c2b4145cb4a	3698e2e9-1d04-464e-8e08-023d1a012dcf	{"is_active": true, "kind_code": "concept", "model_code": "default", "description": "Шаблон для Шаблон: Концепция", "template_code": "concept_tpl_concept", "template_name": "Шаблон: Концепция"}	b79d111690f614fbe0549781abe5bd09578e5454de63581824aa95715bfe63d1	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	124
c763c69c-b023-411e-b653-18eb9ed3b282	e04c7f37-1173-49e8-a384-5f4355336c4a	{"is_active": true, "kind_code": "", "model_code": "default", "description": "Шаблон для Шаблон: Файл", "template_code": "digital_file_tpl_file", "template_name": "Шаблон: Файл"}	249612580fa04277481d5adca8445aaf18e6b9d2bf7045175aa05d262e115e90	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	125
247bf88b-2c81-4c95-8ad8-4e156fbae47f	68eb8255-bb7b-47e6-990b-28529d1b3460	{"is_active": true, "kind_code": "genre", "model_code": "default", "description": "Шаблон для Шаблон: Жанр", "template_code": "genre_tpl_genre", "template_name": "Шаблон: Жанр"}	eb0bad689f049d5c2f3ef0a6a93c9ee4da915913290988caf9e4fbc4d2ba6623	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	126
8b6ab46b-9cec-4f52-8ce9-d1d92e9c6451	80397f3d-e694-4a90-8150-c4bd443743cf	{"is_active": true, "kind_code": "", "model_code": "default", "description": "Шаблон для Шаблон: Человек (персона)", "template_code": "human_tpl_person", "template_name": "Шаблон: Человек (персона)"}	b1866171b41784aa1d3be793ab38627e9fb3ee404172c0aca8acc5d2ae3fa217	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	127
665c1acf-610a-46f8-a616-b3f93a1c9a22	6d53a71f-ac4c-42e8-be0d-5070068d7eaa	{"is_active": true, "kind_code": "", "model_code": "default", "description": "Шаблон для Шаблон: Движение", "template_code": "movement_tpl_movement", "template_name": "Шаблон: Движение"}	4ee08a8aba60b2be07fe66deaa05ef20bb046304eb8c3f088365cce79a913223	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	128
aa8bd20b-c241-4d14-9403-202972d36bfb	49482c2f-73be-4d60-a0d5-09f466bc51e8	{"is_active": true, "kind_code": "", "model_code": "default", "description": "Шаблон для Шаблон: Фото", "template_code": "photo_tpl_photo", "template_name": "Шаблон: Фото"}	e58e53aec915fb27aa6b0269115bfbb6384239dd93357d415317bc0301c2732e	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	129
ea86c035-cbf0-4ef4-8c77-005396a9ae27	179a6a87-5962-4178-a6aa-cd1e8029d398	{"is_active": true, "kind_code": "", "model_code": "default", "description": "Шаблон для Шаблон: Предмет", "template_code": "physical_item_tpl_item", "template_name": "Шаблон: Предмет"}	8f40a39841be4b348b5c5fb4cf4f2be91e7af9f946306b3c78a16c0fdb2d2ba0	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	130
eeee1a06-1674-436e-a13a-03f2a83fb5f8	63531d56-6773-4429-9c39-322e819624f2	{"is_active": true, "kind_code": "photo", "model_code": "default", "description": "Изображения", "template_code": "tpl_my_image", "template_name": "Изображение"}	2f3c58a26240f1750b4b08c59de1d8e6bc5cb0bd24592b7a97de505fe3b034f4	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	131
48992239-f1f1-429c-9961-5a949865e64a	86d133f4-303b-4005-bdda-074abb344287	{"is_active": true, "kind_code": "field", "model_code": "field_model", "description": "Отображение поля реестра", "template_code": "field_template", "template_name": "Шаблон: Поле"}	b03b34e2e411b1c16d3b604aefd1159d80563f72a08e0b63f132b7af67ee2107	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	132
66a31259-bfba-4078-8a7f-f53757878278	1d30fee1-6d99-4f4e-89b6-ef56c66863bc	{"is_active": true, "kind_code": "ontology_model", "model_code": "ontology_entity_model", "description": "Отображение онтологической модели", "template_code": "ontology_model_tpl", "template_name": "Шаблон: Модель онтологии"}	fb6a9a892ef1f57cbb853b3a9adb5ee07714b4f94242fffcb55ee8fcceaab7e9	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	133
50ef0cb5-d4cb-438d-949f-d06abebfd321	7391b484-799a-40c6-b058-a8b5458fc818	{"is_active": true, "kind_code": "ontology_template", "model_code": "ontology_entity_model", "description": "Отображение шаблона онтологии", "template_code": "ontology_template_tpl", "template_name": "Шаблон: Шаблон онтологии"}	3080ef20f9bdb02d10d2fbad4aa8cc84837c6ab0b4b0b8dccdfaf1b3808c7c84	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	134
e68ff6bf-19d1-4faf-8fb1-628ef507f962	0e5ee33d-3a48-47f1-8f0a-e2d9c1fe871a	{"is_active": true, "kind_code": "animal", "model_code": "science", "description": "Шаблон для Шаблон: Животное", "template_code": "animal_tpl_animal", "template_name": "Шаблон: Животное"}	b3bfeceddf4806224648ab169b07131f9d6998b938964bf6c6573363e450b6f1	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	135
4ce84e45-4002-4317-bfd9-3a0c608aa3ca	c1428027-e94a-4698-832d-5846ba80e85f	{"is_active": true, "kind_code": "chemical_element", "model_code": "science", "description": "Шаблон для Шаблон: Химический элемент", "template_code": "chemical_element_tpl_element", "template_name": "Шаблон: Химический элемент"}	b06ce3f6486c84fb72312a5e4704104fcae8ed81a4423560e06b66b4dcafce97	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	136
b403294e-3e84-4b9d-b740-d65be550ac2a	73d35e3f-f0ca-4836-8c34-31205c0255f3	{"is_active": true, "kind_code": "", "model_code": "science", "description": "Шаблон для Шаблон: Явление", "template_code": "phenomenon_tpl_phenomenon", "template_name": "Шаблон: Явление"}	433d6e38ce7896288d591573ab4b1332894802b273fd7b021aa95d2d21dc4c69	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	137
4d7d2105-509f-4f61-89e5-725d92871636	bdce3271-881a-4ec3-9cc7-a8833f287b3c	{"is_active": true, "kind_code": "", "model_code": "science", "description": "Шаблон для Шаблон: Растение", "template_code": "plant_tpl_plant", "template_name": "Шаблон: Растение"}	36167485975f04f26d76251f461f7cfb31b7ec60e56d7bbc2af1fa046d962810	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	138
a84bd03f-ed9b-4652-8861-55d7986200f7	1856e3d5-50b8-4225-8157-fa45af2a18a0	{"is_active": true, "kind_code": "", "model_code": "science", "description": "Шаблон для Шаблон: Человек (персона)", "template_code": "scientist_tpl_person", "template_name": "Шаблон: Человек (персона)"}	2f29025c93be5256ade23c8554cae07e86db3a07b118013eed67a21440cc9eaf	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	139
33e66bc8-6011-4eae-8fa4-154a49eafc88	1aeee6cc-37a4-4125-9062-114cf4aa4822	{"is_active": true, "kind_code": "", "model_code": "history", "description": "Шаблон для Шаблон: Эпоха", "template_code": "period_tpl_period", "template_name": "Шаблон: Эпоха"}	89c202a770e8cd7ee867349222ca27d2ccf2e0f6271e85baf8b51d1cfe4f3e89	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	140
b63e418c-4de8-4ead-8ad3-4f1bcee36e41	5ce640d6-1243-4b80-9ac7-13b2489330c5	{"is_active": true, "kind_code": "place", "model_code": "geography", "description": "Шаблон для Шаблон: Место", "template_code": "place_tpl_place", "template_name": "Шаблон: Место"}	a8c86bb736e8a7c9bbf6d5e3ccf03dfdbf8df2cd856ac1782f8236166bcb079b	\N	t	2026-07-19 08:17:03.063725+00	2026-07-19 08:17:03.063725+00	\N	141
3964d763-994e-420e-a969-50feb758bda6	329fff68-9205-430f-8299-a7d28cee5363	{"poster": ""}	c34c707c68649a4aa5be6bcd3c3256bff7e933b4ae632c780a0a22eadd4e1e25	\N	t	2026-07-19 10:17:47.59996+00	2026-07-19 10:17:47.599969+00	\N	142
642e7c44-8449-4ca3-a0bd-a9026125b831	aab4cf81-e171-48a4-82ec-7f97029f79ad	{"year": 2014, "genre": "Sci-Fi, Drama", "title": "Interstellar", "budget": "165M", "rating": 8.6, "country": "USA", "tagline": "Mankind was born on Earth. It was never meant to die here.", "director": "Christopher Nolan", "duration": "169 мин", "language": "English", "production_company": "Paramount Pictures"}	271ff9189faff8738209edfa6040259bc199f6fa854c2d7d11a564b6082599c3	\N	t	2026-07-19 12:07:04.310131+00	2026-07-19 12:07:04.310133+00	\N	142
68114d01-65f4-4994-9baa-922d17ea7d82	f0000001-0000-0000-0000-000000000003	{"year": 2014, "genre": "Приключения, Драма, Фантастика", "title": "Interstellar", "budget": "165M", "images": "https://image.tmdb.org/t/p/w780/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg\\r\\nhttps://image.tmdb.org/t/p/w780/xJHokMbljvjADYdit5fK5VQsXEG.jpg\\r\\nhttps://image.tmdb.org/t/p/w780/p9fmuz2Oj3HtEJ4OAtI5pShGpG.jpg", "poster": "https://image.tmdb.org/t/p/w500/vReLRjDV9XPhiOSEW7QWow4DXwf.jpg", "rating": 8.482, "content": "", "country": "USA", "tagline": "Человек родился на Земле. Ему не суждено умереть здесь.", "director": "Christopher Nolan", "duration": "169 мин", "file_url": "", "language": "en", "audio_url": "", "age_rating": "", "file_title": "", "description": "Когда засуха, пыльные бури и вымирание растений приводят человечество к продовольственному кризису, коллектив исследователей и учёных отправляется сквозь червоточину в путешествие, чтобы превзойти прежние ограничения для космических путешествий человека и найти планету с подходящими для человечества условиями.", "production_company": "Paramount Pictures"}	f9925376058636ca113e47d6ffcfdf036e00d743a2c8113b60ddf28a395d9d4c	\N	t	2026-07-18 09:57:12.863712+00	2026-07-18 09:57:12.863712+00	\N	1
46562be9-735a-410f-beb9-2d631d605b99	f0000001-0000-0000-0000-000000000004	{"year": 1999, "genre": "Драма, Триллер", "title": "бойцовский клуб", "budget": "", "images": "", "poster": "https://image.tmdb.org/t/p/w500/66RvLrRJTm4J8l3uHXWF09AICol.jpg", "rating": 8.438, "content": "", "country": "", "tagline": "", "director": "David Fincher", "duration": "139 мин", "file_url": "", "language": "en", "audio_url": "", "age_rating": "", "file_title": "", "description": "Сотрудник страховой компании страдает хронической бессонницей и отчаянно пытается вырваться из мучительно скучной жизни. Однажды в очередной командировке он встречает некоего Тайлера Дёрдена — харизматического торговца мылом с извращенной философией. Тайлер уверен, что самосовершенствование — удел слабых, а единственное, ради чего стоит жить, — саморазрушение.\\r\\n Проходит немного времени, и вот уже новые друзья лупят друг друга почем зря на стоянке перед баром, и очищающий мордобой доставляет им высшее блаженство. Приобщая других мужчин к простым радостям физической жестокости, они основывают тайный Бойцовский клуб, который начинает пользоваться невероятной популярностью.", "production_company": ""}	937c5e0294c0e98af216433096917451812435c0e12bf4e4f2060dedae58cc3d	\N	t	2026-07-18 09:57:12.863712+00	2026-07-18 09:57:12.863712+00	\N	1
552dfe5d-4abf-4624-b5da-a89c21f06a09	ac1eed0a-ef38-48ab-ac2e-fcf6ab16e5cb	{}	44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a	\N	t	2026-07-19 12:27:44.260063+00	2026-07-19 12:27:44.260064+00	\N	143
b96a9616-19e9-4fc9-99b8-9178a7b40203	32996523-a5e1-4323-95a4-20de58f0d118	{"year": 1999, "genre": "Drama, Thriller", "title": "Fight Club", "budget": "63M", "rating": 8.4, "country": "USA", "tagline": "Mischief. Mayhem. Soap.", "director": "David Fincher", "duration": "139 мин", "production_company": "Fox 2000 Pictures"}	794a1c8b94cc11bb8344506b7ebe1e49c30000c71fcddf2b60cb8ab3e6f93f85	\N	t	2026-07-19 12:27:44.28762+00	2026-07-19 12:27:44.287624+00	\N	144
26bc7e30-ca20-443e-adf6-eb2295a38cde	319c1053-85b1-4cd4-ac52-3d1cfad2f14d	{"year": 2010, "genre": "Sci-Fi", "title": "Inception", "budget": "160M", "rating": 8.8, "country": "USA", "duration": "148 мин", "language": "English"}	c9320125910f0d738f8af6998443f60704afd5ac331475802a995ffd951cbd11	\N	t	2026-07-18 09:57:20.641726+00	2026-07-18 09:57:20.641726+00	\N	1
9e903e67-e946-4d2c-9f10-b2f5948b0084	e257d136-d19d-4ea1-a583-249b9c6e207e	{"year": 2008, "genre": "Action", "title": "The Dark Knight", "budget": "185M", "rating": 9.0, "country": "USA", "duration": "152 мин", "language": "English"}	1f486ac84866f23ed015399c557fc0dadb34e4f870d497a69abc414bd59d0732	\N	t	2026-07-18 09:57:20.692749+00	2026-07-18 09:57:20.692749+00	\N	1
85b0a2ad-0d7d-40c2-a952-78d74b45644b	1d1c22c2-59ce-438c-ac2e-8f934ab4429a	{"year": 1994, "genre": "Drama", "title": "Forrest Gump", "budget": "55M", "rating": 8.8, "country": "USA", "duration": "142 мин", "language": "English"}	6d9cbd2ee6b09429cf718cf116d2ec4112bc7a4f108ef930f96332e94b6e966d	\N	t	2026-07-18 09:57:20.70148+00	2026-07-18 09:57:20.70148+00	\N	1
35408788-fbd2-4550-89dd-2710511fb8cb	5f42bfe9-f1ce-4c26-8437-9d2d5f8c4b52	{"year": 1993, "genre": "Drama", "title": "Schindler's List", "budget": "22M", "rating": 9.0, "country": "USA", "duration": "195 мин", "language": "English"}	f8c4b026653a79e8dac63e08f1b091438bb284906173678034452c10e9f8feea	\N	t	2026-07-18 09:57:20.710429+00	2026-07-18 09:57:20.710429+00	\N	1
b57e66b8-bf52-4f9c-86ab-1dc6d27ba0e5	5412b37f-befe-4023-93e0-8a648ba208dd	{"year": 2010, "genre": "Thriller", "title": "Shutter Island", "budget": "80M", "rating": 8.2, "country": "USA", "duration": "138 мин", "language": "English"}	c4cf0b0900edeeab8e6ca2f9a40562aef25d576519881c56786559381ee89c22	\N	t	2026-07-18 09:57:20.728801+00	2026-07-18 09:57:20.728801+00	\N	1
a94f91ee-d799-4bfd-bc97-a81b5f5be54f	52080fdd-65e3-423c-8257-0c593aaa1fe9	{"year": 1999, "genre": "Sci-Fi", "title": "The Matrix", "budget": "63M", "images": "", "poster": "", "rating": 8.7, "content": "", "country": "USA", "tagline": "", "director": "", "duration": "136 мин", "file_url": "", "language": "English", "audio_url": "", "age_rating": "", "file_title": "", "description": "", "production_company": ""}	7f69fef555ac3663557ed13b3b1ccb095a415783465975018f9948accd2c9ce6	\N	t	2026-07-18 09:57:20.652437+00	2026-07-18 09:57:20.652437+00	\N	1
57c10c36-a0f4-4915-8fc0-ea03bd772e1c	fd597312-689e-4fd2-8fcd-82adbc984d61	{"year": 2012, "genre": "Western", "title": "Django Unchained", "budget": "100M", "images": "http://localhost:9000/dwmb-media/entities/ccfb8bb4-73cc-4269-86aa-88371c4485b6/%D0%94%D0%BE%D1%81%D0%BF%D0%B5%D1%85%D0%B8_%D0%B1%D0%BE%D0%B3%D0%B0.webp?AWSAccessKeyId=dwmb_minio&Signature=V1OyDm030LFx18evpLSXTTjGJ4M%3D&Expires=1784408318\\r\\nhttp://localhost:9000/dwmb-media/entities/1ea63bec-f46d-43d4-bfce-ec55c7e3b96c/%D0%93%D1%80%D0%B5%D0%BC%D0%BB%D0%B8%D0%BD%D1%8B.jpeg?AWSAccessKeyId=dwmb_minio&Signature=bFDoW3yUPrF9AsPQFqoWX4AOdb0%3D&Expires=1784408318\\r\\nhttp://localhost:9000/dwmb-media/entities/8877988a-cc00-4360-902c-b9236ef36f1c/%D0%A2%D1%8F%D0%B6%D0%B5%D0%BB%D1%8B%D0%B9.%D0%9C%D0%B5%D1%82%D0%B0%D0%BB%D0%BB.jpeg?AWSAccessKeyId=dwmb_minio&Signature=zJwiI49QEJ2IzT2WxOCEp3J5ocw%3D&Expires=1784408318\\r\\nhttp://localhost:9000/dwmb-media/entities/058e03ee-0404-4bc5-b449-260f1f29e6a1/%D0%9F%D1%80%D0%B8%D0%BA%D0%BB%D1%8E%D1%87%D0%B5%D0%BD%D0%B8%D1%8F.%D0%AD%D0%BB%D0%B5%D0%BA%D1%82%D1%80%D0%BE%D0%BD%D0%B8%D0%BA%D0%B0.jpg?AWSAccessKeyId=dwmb_minio&Signature=2oYwKNXlkYk7%2FxrrH33E5855O2E%3D&Expires=1784408318\\r\\nhttp://localhost:9000/dwmb-media/entities/5ceefbba-b512-467e-9bbb-2f8a537bd2b9/Taxi.jpg?AWSAccessKeyId=dwmb_minio&Signature=3lP%2BYQ5Eh%2BWLvKL1C%2BmLAtjarmk%3D&Expires=1784408318", "poster": "http://localhost:9000/dwmb-media/entities/e2c3c575-32e2-4e12-83da-f0bfb086ef24/%D0%BF%D1%80%D0%B8%D0%B7%D1%80%D0%B0%D0%BA_%D0%B2_%D0%B4%D0%BE%D1%81%D0%BF%D0%B5%D1%85%D0%B0%D1%85.jpg?AWSAccessKeyId=dwmb_minio&Signature=56Gv7iC%2FLv9vP6Ztp7%2FdGFs008g%3D&Expires=1784409544", "rating": 8.4, "content": "", "country": "USA", "tagline": "телёнок золотой", "director": "", "duration": "165 мин", "file_url": "", "language": "English", "audio_url": "", "age_rating": "", "file_title": "", "description": "", "production_company": ""}	47449e885e01b92a2e88b3ec60499629b38b75a12b55bda097620d241a0f7da4	\N	t	2026-07-18 09:57:20.719541+00	2026-07-18 09:57:20.719541+00	\N	1
964c644f-5a99-46fe-91ec-4d63a61b0231	5a1ced1a-f8e9-4349-a667-17a9f6ac9569	{"year": 2014, "genre": "Sci-Fi, Drama", "title": "Interstellar", "budget": "165M", "images": "http://localhost:9000/dwmb-media/entities/77a5a242-8469-4414-aa38-0cd19b769b6d/%D0%A7%D0%BE%D0%BA%D0%BD%D1%83%D1%82%D1%8B%D0%B9_%D0%BF%D1%80%D0%BE%D1%84%D0%B5%D1%81%D1%81%D0%BE%D1%80_%28%D0%9A%D0%BE%D0%BB%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F%292.png?AWSAccessKeyId=dwmb_minio&Signature=O5U2PgLVxbeB0sFgog1BnwcsXcs%3D&Expires=1784382428\\r\\nhttp://localhost:9000/dwmb-media/entities/34a6826f-3c82-4341-b099-119b9a3c5270/%D0%A7%D0%BE%D0%BA%D0%BD%D1%83%D1%82%D1%8B%D0%B9_%D0%BF%D1%80%D0%BE%D1%84%D0%B5%D1%81%D1%81%D0%BE%D1%80_%28%D0%9A%D0%BE%D0%BB%D0%BB%D0%B5%D0%BA%D1%86%D0%B8%D1%8F%29.jpg?AWSAccessKeyId=dwmb_minio&Signature=IM%2BIMwIp8%2BKK%2BALTs%2FUip70ZSBE%3D&Expires=1784382428\\r\\nhttp://localhost:9000/dwmb-media/entities/1d7d5d85-786a-446b-80d2-acb0a90f8c06/%D0%9B%D0%B5%D0%B3%D0%B5%D0%BD%D0%B4%D0%B0_%D0%BE_%D0%9B%D0%BE_%D0%A1%D1%8F%D0%BE%D1%85%D1%8D%D0%B52.jpg?AWSAccessKeyId=dwmb_minio&Signature=nETYfjxzfjmyOReQv5mmXQKIuVA%3D&Expires=1784382428\\r\\nhttp://localhost:9000/dwmb-media/entities/ff1c3312-df78-440e-a3f1-aa347c2d0bc4/%D0%9B%D0%B5%D0%B3%D0%B5%D0%BD%D0%B4%D0%B0_%D0%BE_%D0%9B%D0%BE_%D0%A1%D1%8F%D0%BE%D1%85%D1%8D%D0%B5.jpg?AWSAccessKeyId=dwmb_minio&Signature=jLor8uv4NbbTZlTGmaj5t9X9lC4%3D&Expires=1784382428\\r\\nhttp://localhost:9000/dwmb-media/entities/8b5b8796-5629-4de4-8877-36a1bd6222d8/4.%D0%9A%D0%BE%D0%BC%D0%BD%D0%B0%D1%82%D1%8B.jpg?AWSAccessKeyId=dwmb_minio&Signature=mfINwdbYdzyPJWdnmgZyPYgMf5Y%3D&Expires=1784382428\\r\\nhttp://localhost:9000/dwmb-media/entities/0d322d5e-0620-4a1a-9a6d-a7025a42ff28/i.webp?AWSAccessKeyId=dwmb_minio&Signature=samLBrEnE7U1jcJEHzAe2GXrp0Q%3D&Expires=1784382428\\r\\nhttp://localhost:9000/dwmb-media/entities/977790a7-d7bf-438a-8d03-b576aa43e4bc/%D0%97%D0%BE%D0%BB%D0%BE%D1%82%D1%8B%D0%B5_%D0%BF%D1%80%D0%B8%D0%B8%D1%81%D0%BA%D0%B8_%D0%9A%D0%B0%D0%BB%D0%BE%D1%80%D0%B0%3A_%D0%93%D0%BB%D0%B0%D0%B2%D0%B0_1.webp?AWSAccessKeyId=dwmb_minio&Signature=e%2BrsYeADIJKuaSWfyg48X%2B48vqk%3D&Expires=1784382428", "poster": "", "rating": 8.6, "content": "", "country": "USA", "tagline": "Test tagline", "director": "", "duration": "169 мин", "language": "English", "description": "", "production_company": "Paramount"}	24e08b0081c2866938df4b158b36ec04e97dba8d4b7cf555c7dd5b24a6119ee8	\N	t	2026-07-18 09:57:20.665705+00	2026-07-18 09:57:20.665705+00	\N	1
32d7b4b0-4e82-4fd4-9c15-f5a072761a56	08814137-6dc0-4bc3-8c2c-8bf3b44f4f45	{"year": 1999, "genre": "Drama", "title": "Fight Club", "budget": "63M", "images": "http://localhost:9000/dwmb-media/entities/24a3b922-3ba0-4077-b0db-6eea4d22beca/%D0%97%D0%BE%D0%BB%D0%BE%D1%82%D0%BE%D0%B9.%D1%82%D0%B5%D0%BB%D1%91%D0%BD%D0%BE%D0%BA.webp?AWSAccessKeyId=dwmb_minio&Signature=tmeiN2q5CpO4B9JvPYehZwO6%2B54%3D&Expires=1784408745\\r\\nhttp://localhost:9000/dwmb-media/entities/387fb842-3e32-462c-a70a-714bab27a2eb/%D0%A2%D0%BE%D1%82.%D1%81%D0%B0%D0%BC%D1%8B%D0%B9.%D0%9C%D1%8E%D0%BD%D1%85%D0%B3%D0%B0%D1%83%D0%B7%D0%B5%D0%BD.jpeg?AWSAccessKeyId=dwmb_minio&Signature=9hZOH0PnGMSJ03Q55siVQhzuvOQ%3D&Expires=1784408745\\r\\nhttp://localhost:9000/dwmb-media/entities/8f5afa8d-d5cf-41b8-9330-7794bdfa761e/%D0%9D%D0%B5.%D0%B1%D0%BE%D0%B9%D1%81%D1%8F%2C.%D1%8F.%D1%81.%D1%82%D0%BE%D0%B1%D0%BE%D0%B9.%281981%29.webp?AWSAccessKeyId=dwmb_minio&Signature=39Re8aPdwY3p7iM9JUHMwiaDveY%3D&Expires=1784408745\\r\\nhttp://localhost:9000/dwmb-media/entities/64a2dfe2-ea09-492c-8302-3e0c92e24c8d/3840x.webp?AWSAccessKeyId=dwmb_minio&Signature=o6OWzdpeVA6%2B1asbgtHnaJFXXeQ%3D&Expires=1784408745", "poster": "http://localhost:9000/dwmb-media/entities/4cb4bd5c-599a-4a8f-bfa0-44f2b5ff4ac8/futurama.jpg?AWSAccessKeyId=dwmb_minio&Signature=Z2X15AEZqsUzyLb71Q5uGd54cAM%3D&Expires=1784409779", "rating": 8.8, "content": "", "country": "USA", "tagline": "", "director": "", "duration": "139 мин", "file_url": "", "language": "English", "audio_url": "", "age_rating": "", "file_title": "", "description": "", "production_company": ""}	45dbd860fa284af3c475304077aea2d06764aaeeaaf84cfcd9b9cdb869cc65ac	\N	t	2026-07-18 09:57:20.674866+00	2026-07-18 09:57:20.674866+00	\N	1
\.


--
-- Data for Name: relation_type; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.relation_type (relation_type_id, relation_code, relation_name, description, from_kind_id, to_kind_id, directionality, transitive_relation, symmetric_relation, inverse_type_id, version_id) FROM stdin;
c0000000-0000-0000-0000-000000000002	directed_by	Режиссёр	\N	\N	\N	directed	f	f	76b7c699-d299-4aed-b387-f41158fa7fff	1
76b7c699-d299-4aed-b387-f41158fa7fff	directs	Режиссировал	Человек режиссировал фильм	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000002	1
c0000000-0000-0000-0000-000000000006	acted_in	Сыграл в	\N	\N	\N	directed	f	f	3d27947a-60e3-45bc-b4ca-c80e0636226d	1
3d27947a-60e3-45bc-b4ca-c80e0636226d	acts_in	Сыграл в	Человек сыграл в фильме	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000006	1
c0000000-0000-0000-0000-000000000003	wrote	Написал	\N	\N	\N	directed	f	f	fc0c7097-8561-49bb-a966-b515a3ad3339	1
fc0c7097-8561-49bb-a966-b515a3ad3339	author_of	Автор	Автор написал произведение	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000003	1
c0000000-0000-0000-0000-000000000004	composed_by	Композитор	\N	\N	\N	directed	f	f	794472bb-eff7-4124-97e8-cdccb483e608	1
794472bb-eff7-4124-97e8-cdccb483e608	composer_of	Композитор	Композитор написал музыку	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000004	1
c0000000-0000-0000-0000-000000000005	produced_by	Продюсер	\N	\N	\N	directed	f	f	f5e230f5-a733-4e66-bbc2-c9e03c134e73	1
f5e230f5-a733-4e66-bbc2-c9e03c134e73	producer_of	Продюсер	Продюсер создал фильм	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000005	1
c0000000-0000-0000-0000-000000000001	performed_in	Исполнил в	\N	\N	\N	directed	f	f	60bb2c94-d976-4b36-bfa2-bdb90d6513df	1
60bb2c94-d976-4b36-bfa2-bdb90d6513df	performed_by	Исполнитель	Песня исполнена артистом	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000001	1
c0000000-0000-0000-0000-000000000007	narrated_by	Озвучил	\N	\N	\N	directed	f	f	52000b54-4639-4e83-ae69-1de1f3b6dcb0	1
52000b54-4639-4e83-ae69-1de1f3b6dcb0	narrator_of	Рассказчик	Рассказчик озвучил произведение	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000007	1
c0000000-0000-0000-0000-000000000008	based_on	Основано на	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000012	1
c0000000-0000-0000-0000-000000000012	adaptation_of	Экранизация	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000008	1
c0000000-0000-0000-0000-000000000009	sequel_of	Сиквел	\N	\N	\N	directed	f	f	3d45e0ae-f0c5-44f2-b2db-0112d6425d2f	1
3d45e0ae-f0c5-44f2-b2db-0112d6425d2f	has_sequel	Имеет сиквел	Произведение имеет сиквел	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000009	1
c0000000-0000-0000-0000-000000000010	prequel_of	Приквел	\N	\N	\N	directed	f	f	9536fb97-bf89-4ad2-9f07-4982a58ad042	1
9536fb97-bf89-4ad2-9f07-4982a58ad042	has_prequel	Имеет приквел	Произведение имеет приквел	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000010	1
c0000000-0000-0000-0000-000000000011	spin_off_of	Спин-офф	\N	\N	\N	directed	f	f	0247cdd0-6525-4e72-b03d-b8c81ad79628	1
0247cdd0-6525-4e72-b03d-b8c81ad79628	has_spin_off	Имеет спин-офф	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000011	1
c0000000-0000-0000-0000-000000000013	influenced_by	Под влиянием	\N	\N	\N	directed	f	f	66a2edee-3021-43c7-ba5f-8025362499c4	1
66a2edee-3021-43c7-ba5f-8025362499c4	influences	Влияет на	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000013	1
c0000000-0000-0000-0000-000000000014	member_of	Член	\N	\N	\N	directed	f	f	11a5b200-a8c3-4602-8b9b-0b42c00effa5	1
11a5b200-a8c3-4602-8b9b-0b42c00effa5	has_member	Имеет члена	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000014	1
c0000000-0000-0000-0000-000000000015	founded	Основал	\N	\N	\N	directed	f	f	42082ea0-9c96-43cb-a29e-20ee548f4d9a	1
42082ea0-9c96-43cb-a29e-20ee548f4d9a	founder_of	Основатель	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000015	1
c0000000-0000-0000-0000-000000000016	located_in	Расположен в	\N	\N	\N	directed	f	f	6b7e7aac-bc41-48ab-9a57-8ee46e38dadb	1
6b7e7aac-bc41-48ab-9a57-8ee46e38dadb	location_of	Местоположение	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000016	1
c0000000-0000-0000-0000-000000000017	born_in	Родился в	\N	\N	\N	directed	f	f	448481f3-23c2-4f60-bd27-a65aab184656	1
448481f3-23c2-4f60-bd27-a65aab184656	birthplace_of	Место рождения	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000017	1
c0000000-0000-0000-0000-000000000018	died_in	Умер в	\N	\N	\N	directed	f	f	1406581e-600c-466a-9638-07acfbab93d4	1
1406581e-600c-466a-9638-07acfbab93d4	deathplace_of	Место смерти	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000018	1
c0000000-0000-0000-0000-000000000019	has_genre	Жанр	\N	\N	\N	directed	f	f	56034b26-cf05-4b9b-8b24-706d315c6f66	1
56034b26-cf05-4b9b-8b24-706d315c6f66	genre_of	Жанр для	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000019	1
c0000000-0000-0000-0000-000000000020	has_theme	Тема	\N	\N	\N	directed	f	f	d4c4e7cb-2288-4a7f-a751-ea160d96463b	1
d4c4e7cb-2288-4a7f-a751-ea160d96463b	theme_of	Тема для	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000020	1
c0000000-0000-0000-0000-000000000022	part_of	Часть	\N	\N	\N	directed	f	f	843b725a-d5cd-4858-a968-a6eb1093c2de	1
843b725a-d5cd-4858-a968-a6eb1093c2de	has_part	Имеет часть	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000022	1
c0000000-0000-0000-0000-000000000023	contains	Содержит	\N	\N	\N	directed	f	f	6deb818c-aff3-4f92-836a-dc35e37cf558	1
6deb818c-aff3-4f92-836a-dc35e37cf558	contained_in	Содержится в	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000023	1
c0000000-0000-0000-0000-000000000024	references	Упоминает	\N	\N	\N	directed	f	f	95c00448-5100-4806-9d30-16635f786897	1
95c00448-5100-4806-9d30-16635f786897	referenced_by	Упоминается в	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000024	1
c0000000-0000-0000-0000-000000000025	has_asset	Имеет файл	\N	\N	\N	directed	f	f	d704c4e8-ad24-4a49-a1f3-37e814ac6d74	1
d704c4e8-ad24-4a49-a1f3-37e814ac6d74	asset_of	Файл принадлежит	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000025	1
c0000000-0000-0000-0000-000000000026	won_award	Победил в	\N	\N	\N	directed	f	f	bbbbe3d5-7976-487d-8877-5ea9967d384a	1
bbbbe3d5-7976-487d-8877-5ea9967d384a	award_won_by	Награда получена	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000026	1
c0000000-0000-0000-0000-000000000027	nominated_for	Номинирован на	\N	\N	\N	directed	f	f	7002adfd-2580-4252-a2b5-947bcec20b5a	1
7002adfd-2580-4252-a2b5-947bcec20b5a	has_nomination	Номинация	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000027	1
c0000000-0000-0000-0000-000000000028	distributed_by	Дистрибьютор	\N	\N	\N	directed	f	f	f6363dbc-396d-494e-b427-7eae7639d811	1
f6363dbc-396d-494e-b427-7eae7639d811	distributes	Дистрибьюция	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000028	1
c0000000-0000-0000-0000-000000000029	published_by	Издатель	\N	\N	\N	directed	f	f	41d4ba1a-b27b-4442-b115-651b41a5da8f	1
41d4ba1a-b27b-4442-b115-651b41a5da8f	publishes	Издает	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000029	1
44e171b6-3f07-4c76-a7bb-c24c37b2b85a	has_alternative_title	Имеет альтернативное название	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000031	1
c0000000-0000-0000-0000-000000000032	covers	Кавер	\N	\N	\N	directed	f	f	3a12fcff-3e21-4d43-b9ed-f71e8fe0ad80	1
3a12fcff-3e21-4d43-b9ed-f71e8fe0ad80	covered_by	Кавер-версия	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000032	1
c0000000-0000-0000-0000-000000000033	remix_of	Ремикс	\N	\N	\N	directed	f	f	53d6283f-d2cf-4dd7-b1dd-29e08be694c2	1
53d6283f-d2cf-4dd7-b1dd-29e08be694c2	has_remix	Имеет ремикс	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000033	1
c0000000-0000-0000-0000-000000000034	sampled_in	Сэмпл в	\N	\N	\N	directed	f	f	7d561556-2881-4b90-9df7-e46db8046295	1
7d561556-2881-4b90-9df7-e46db8046295	has_sample	Имеет сэмпл	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000034	1
c0000000-0000-0000-0000-000000000035	developed_by	Разработчик	\N	\N	\N	directed	f	f	c0841d49-cc61-4eeb-bfbe-c57852a0dc38	1
c0841d49-cc61-4eeb-bfbe-c57852a0dc38	develops	Разрабатывает	\N	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000035	1
ea0fb078-5f06-4976-b6af-b31924ae53ef	has_adaptation	Имеет экранизацию	Произведение экранизировано	\N	\N	directed	f	f	c0000000-0000-0000-0000-000000000012	1
c0000000-0000-0000-0000-000000000021	related_to	Связано с	\N	\N	\N	undirected	f	f	c0000000-0000-0000-0000-000000000021	1
c0000000-0000-0000-0000-000000000030	similar_to	Похоже на	\N	\N	\N	undirected	f	f	c0000000-0000-0000-0000-000000000030	1
c0000000-0000-0000-0000-000000000031	alternative_title	Альтернативное название	\N	\N	\N	undirected	f	f	c0000000-0000-0000-0000-000000000031	1
16e737e7-2336-44f2-b0fd-0bdc7c434fa2	played_by	played_by	Auto-created inverse	\N	\N	directed	f	f	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	1
4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	plays	plays	Auto-created	\N	\N	directed	f	f	16e737e7-2336-44f2-b0fd-0bdc7c434fa2	1
6cc26927-30b1-4a5d-a99a-48ee3571d10c	features	features	Auto-created inverse	\N	\N	directed	f	f	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	1
4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	appears_in	appears_in	Auto-created	\N	\N	directed	f	f	6cc26927-30b1-4a5d-a99a-48ee3571d10c	1
\.


--
-- Data for Name: role; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.role (role_id, role_code, role_name, description, created_at) FROM stdin;
ac4e8822-c70a-47f5-994d-dde5953ff4c9	admin	Администратор	Полный доступ ко всем функциям	2026-07-20 09:06:27.015017+00
cc157fd8-3ac8-4839-8518-4ea257cf04c6	editor	Редактор	Создание и редактирование сущностей	2026-07-20 09:06:27.015017+00
70658006-2c64-4a01-9faf-92a6040b151d	viewer	Наблюдатель	Только просмотр сущностей	2026-07-20 09:06:27.015017+00
\.


--
-- Data for Name: role_permission; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.role_permission (role_id, permission_id) FROM stdin;
ac4e8822-c70a-47f5-994d-dde5953ff4c9	d23b25f9-dd74-459d-8121-7ee05667a4ce
ac4e8822-c70a-47f5-994d-dde5953ff4c9	b09dc37f-74ad-4a05-a4c1-e09d532c47b7
ac4e8822-c70a-47f5-994d-dde5953ff4c9	9380f0b4-ca3e-4cfc-8a89-053dd980aab9
ac4e8822-c70a-47f5-994d-dde5953ff4c9	d694204d-a6b8-430f-8808-7e2116fe1775
ac4e8822-c70a-47f5-994d-dde5953ff4c9	77e3227a-041c-453d-9104-7e5aa513504a
ac4e8822-c70a-47f5-994d-dde5953ff4c9	d9c6524c-97f9-46de-a344-8de88f0b9985
ac4e8822-c70a-47f5-994d-dde5953ff4c9	d5883945-1b1a-4680-8c70-898f8a538e06
ac4e8822-c70a-47f5-994d-dde5953ff4c9	fc3b62c5-9788-4f87-8e7d-0f1e6440a000
ac4e8822-c70a-47f5-994d-dde5953ff4c9	0537782a-bdfc-46f1-b7cb-8fa07a066626
ac4e8822-c70a-47f5-994d-dde5953ff4c9	e3ece527-b80a-4378-a85d-713c13287b30
ac4e8822-c70a-47f5-994d-dde5953ff4c9	9c0d69e4-5aae-4b42-9dd7-79f9c92c0a62
ac4e8822-c70a-47f5-994d-dde5953ff4c9	92838e2f-a73b-4ed3-8310-0dbf96b654a7
ac4e8822-c70a-47f5-994d-dde5953ff4c9	9baefc18-3bd5-4d0e-a24c-7cdfc4ea25a8
cc157fd8-3ac8-4839-8518-4ea257cf04c6	d23b25f9-dd74-459d-8121-7ee05667a4ce
cc157fd8-3ac8-4839-8518-4ea257cf04c6	b09dc37f-74ad-4a05-a4c1-e09d532c47b7
cc157fd8-3ac8-4839-8518-4ea257cf04c6	9380f0b4-ca3e-4cfc-8a89-053dd980aab9
cc157fd8-3ac8-4839-8518-4ea257cf04c6	77e3227a-041c-453d-9104-7e5aa513504a
70658006-2c64-4a01-9faf-92a6040b151d	b09dc37f-74ad-4a05-a4c1-e09d532c47b7
\.


--
-- Data for Name: semantic_relation; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.semantic_relation (relation_id, source_projection_id, relation_type_id, target_projection_id, context_id, weight, confidence, metadata, created_at, valid_from, valid_to, version_id) FROM stdin;
1d41ef0f-9157-42dc-804b-90f7db671c52	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000006	e0000002-0000-0000-0000-000000000001	\N	\N	0.99000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
9423c770-81ec-4112-bd15-e9dd625cf049	e0000001-0000-0000-0000-000000000002	c0000000-0000-0000-0000-000000000006	e0000002-0000-0000-0000-000000000002	\N	\N	0.99000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
b17cfc5c-ef3a-48d4-bde7-d67f97beb1ab	e0000001-0000-0000-0000-000000000002	c0000000-0000-0000-0000-000000000002	e0000003-0000-0000-0000-000000000002	\N	\N	0.99000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
1d410b5c-9a0e-4072-b90a-e66256bcb7cc	e0000004-0000-0000-0000-000000000002	c0000000-0000-0000-0000-000000000004	e0000005-0000-0000-0000-000000000002	\N	\N	0.98000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
fbd954b0-8b03-4124-90c9-323a0c715416	e0000004-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000004	e0000005-0000-0000-0000-000000000001	\N	\N	0.99000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
683718c1-2f50-46bc-badc-1ed49f02d4c3	e0000004-0000-0000-0000-000000000002	c0000000-0000-0000-0000-000000000022	e0000006-0000-0000-0000-000000000001	\N	\N	0.99000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
094ed928-528e-4652-bcbf-24ae65d5b2a0	e0000007-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000003	e0000008-0000-0000-0000-000000000001	\N	\N	0.99000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
a3644c1b-6bcc-4b9e-b142-0690a97d395d	e0000007-0000-0000-0000-000000000002	c0000000-0000-0000-0000-000000000003	e0000008-0000-0000-0000-000000000002	\N	\N	0.99000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
9bc5113b-b5ed-44d9-abb3-e2238a561126	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000019	e0000014-0000-0000-0000-000000000001	\N	\N	0.95000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
a879a6fc-890b-4572-aff4-5f7b0f29d32c	e0000001-0000-0000-0000-000000000002	c0000000-0000-0000-0000-000000000019	e0000014-0000-0000-0000-000000000001	\N	\N	0.95000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
0fcff13b-eac6-4d63-a5a9-4baa2d647884	e0000007-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000019	e0000014-0000-0000-0000-000000000001	\N	\N	0.95000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
6543aa6c-4621-4d82-b069-97abcd3b52fd	e0000004-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000019	e0000014-0000-0000-0000-000000000002	\N	\N	0.98000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
54ed1675-9b17-4826-b9aa-5de667a88d1f	e0000006-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000019	e0000014-0000-0000-0000-000000000002	\N	\N	0.95000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
63d36d2d-23bc-4abe-8ccf-7fb59bb9f3d9	e0000011-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000021	e0000011-0000-0000-0000-000000000003	\N	\N	0.60000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
63632623-d357-4df1-875f-8f3f753ab057	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000005	e0000026-0000-0000-0000-000000000001	\N	\N	0.90000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
5cd18923-0c3a-43de-9776-0da7632e6e8b	e0000001-0000-0000-0000-000000000002	c0000000-0000-0000-0000-000000000005	e0000026-0000-0000-0000-000000000001	\N	\N	0.90000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
38cc2bb7-a8eb-4cab-82dc-445872d6b05b	e0000004-0000-0000-0000-000000000002	c0000000-0000-0000-0000-000000000029	e0000026-0000-0000-0000-000000000002	\N	\N	0.85000	{}	2026-07-18 09:57:12.405638+00	2026-07-18 09:57:12.405638+00	\N	1
b7923ab7-cbc0-4bd4-acc7-50aee1a06fe7	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000002-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 09:30:57.015815+00	2026-07-19 09:30:57.015818+00	\N	2
12845828-796c-4413-8796-c959642e4648	e0000002-0000-0000-0000-000000000001	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 09:30:57.015822+00	2026-07-19 09:30:57.015823+00	\N	2
48492a90-8518-4d03-a3f6-90cb333888ca	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000003-0000-0000-0000-000000000002	\N	\N	1.00000	{}	2026-07-19 09:33:52.575426+00	2026-07-19 09:33:52.575428+00	\N	3
106239ef-4a9b-4d20-93c1-eb28933b850c	e0000003-0000-0000-0000-000000000002	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 09:33:52.575431+00	2026-07-19 09:33:52.575431+00	\N	3
23023866-de3a-4fda-84d3-373e35889305	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000002-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 09:57:16.045118+00	2026-07-19 09:57:16.045121+00	\N	4
bdebafb5-0b61-4e4f-a07a-9119178d9f12	e0000002-0000-0000-0000-000000000001	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 09:57:16.045126+00	2026-07-19 09:57:16.045127+00	\N	4
feb0a1b3-8c79-4e9a-bdc8-63fb511a001c	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000001-0000-0000-0000-000000000002	\N	0.80000	0.95000	{}	2026-07-19 10:06:34.125293+00	2026-07-19 10:06:34.125297+00	\N	5
20b7b525-be04-4ecb-88ab-369f14c2c9b6	e0000001-0000-0000-0000-000000000002	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	0.80000	0.95000	{}	2026-07-19 10:06:34.125301+00	2026-07-19 10:06:34.125302+00	\N	5
6ba5ec73-d7d1-4bce-bcb1-8de67015ad7e	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000001-0000-0000-0000-000000000002	\N	0.70000	0.90000	{}	2026-07-19 10:07:41.548329+00	2026-07-19 10:07:41.548332+00	\N	6
7325adcc-e1f8-4c35-ad59-eb373fca8b15	e0000001-0000-0000-0000-000000000002	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	0.70000	0.90000	{}	2026-07-19 10:07:41.548336+00	2026-07-19 10:07:41.548337+00	\N	6
23d0e78e-8baf-483b-8077-48065f8d3ea9	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000001-0000-0000-0000-000000000002	\N	0.80000	0.95000	{}	2026-07-19 10:07:56.307625+00	2026-07-19 10:07:56.307628+00	\N	7
4d3628d3-fff1-41e7-8a40-a6bce3eaf9f9	e0000001-0000-0000-0000-000000000002	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	0.80000	0.95000	{}	2026-07-19 10:07:56.307631+00	2026-07-19 10:07:56.307632+00	\N	7
c8ad32cb-309e-4aa6-99b4-a515962d3f13	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000001-0000-0000-0000-000000000002	\N	0.60000	0.85000	{}	2026-07-19 10:08:29.046792+00	2026-07-19 10:08:29.046794+00	\N	8
a9b93daa-91e3-453c-ac68-e4b5c9eb87be	e0000001-0000-0000-0000-000000000002	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	0.60000	0.85000	{}	2026-07-19 10:08:29.046797+00	2026-07-19 10:08:29.046797+00	\N	8
772e9621-08fb-45be-978d-58f1764126c5	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000001-0000-0000-0000-000000000002	\N	0.70000	0.90000	{}	2026-07-19 10:08:37.890095+00	2026-07-19 10:08:37.890097+00	\N	9
f6703596-4934-40aa-b80f-a5d0d33b786e	e0000001-0000-0000-0000-000000000002	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	0.70000	0.90000	{}	2026-07-19 10:08:37.8901+00	2026-07-19 10:08:37.890101+00	\N	9
89fa0c9a-bd28-4f71-b228-ea82ebbe9c22	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000001-0000-0000-0000-000000000002	\N	0.50000	0.75000	{}	2026-07-19 10:09:00.42632+00	2026-07-19 10:09:00.426322+00	\N	10
df262560-9bd2-48dc-b6d2-2781166a294f	e0000001-0000-0000-0000-000000000002	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	0.50000	0.75000	{}	2026-07-19 10:09:00.426326+00	2026-07-19 10:09:00.426326+00	\N	10
35f24a00-1d37-4c41-8fbb-9d289035368b	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000001-0000-0000-0000-000000000002	\N	1.00000	1.00000	{}	2026-07-19 10:09:51.076238+00	2026-07-19 10:09:51.076242+00	\N	11
ceeea7ee-3417-4d86-b560-ca2870cf6293	e0000001-0000-0000-0000-000000000002	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	1.00000	1.00000	{}	2026-07-19 10:09:51.076248+00	2026-07-19 10:09:51.076248+00	\N	11
3bd32359-7fcf-4c3b-b114-5b63b07e34d6	e0000001-0000-0000-0000-000000000002	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	0.70000	0.90000	{}	2026-07-19 10:10:14.026607+00	2026-07-19 10:10:14.026607+00	\N	12
07e1419c-5bcf-4435-8152-5a7e06e94e5c	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000001-0000-0000-0000-000000000002	\N	0.70000	0.90000	{"role": "test_role_value"}	2026-07-19 10:10:14.026597+00	2026-07-19 10:10:14.026601+00	\N	12
aa8553ac-d12c-4189-a1e6-c7d30c6516e4	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000001-0000-0000-0000-000000000002	\N	0.60000	0.85000	{}	2026-07-19 10:11:23.737271+00	2026-07-19 10:11:23.737275+00	\N	13
b7863cab-44ef-4802-9c6e-7aea3bc37518	e0000001-0000-0000-0000-000000000002	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	0.60000	0.85000	{}	2026-07-19 10:11:23.737284+00	2026-07-19 10:11:23.737285+00	\N	13
95149099-257d-495c-90b8-713f4c2c3806	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000001-0000-0000-0000-000000000002	\N	0.60000	0.85000	{}	2026-07-19 10:11:35.057527+00	2026-07-19 10:11:35.057534+00	\N	14
6de11f5c-345d-48a2-afa2-fd1282824897	e0000001-0000-0000-0000-000000000002	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	0.60000	0.85000	{}	2026-07-19 10:11:35.057543+00	2026-07-19 10:11:35.057545+00	\N	14
1a8cb6d3-4c08-445e-81dd-f10719665139	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000001-0000-0000-0000-000000000002	\N	0.60000	0.85000	{}	2026-07-19 10:12:16.893156+00	2026-07-19 10:12:16.89316+00	\N	15
bdd7b72c-fa21-43a6-895a-79bccaba187c	e0000001-0000-0000-0000-000000000002	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	0.60000	0.85000	{}	2026-07-19 10:12:16.893166+00	2026-07-19 10:12:16.893167+00	\N	15
dd5ae257-ebf6-418b-a029-85544015b29d	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000001-0000-0000-0000-000000000002	\N	0.80000	0.95000	{"role": "главная роль", "weight": 0.8, "confidence": 0.95}	2026-07-19 10:13:12.676277+00	2026-07-19 10:13:12.676285+00	\N	16
b6cbf4ae-3499-4899-bfd6-3b4e8f198bb5	e0000001-0000-0000-0000-000000000002	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	0.80000	0.95000	{"role": "главная роль", "weight": 0.8, "confidence": 0.95}	2026-07-19 10:13:12.676298+00	2026-07-19 10:13:12.6763+00	\N	16
68723a81-2dfc-4ae3-ad57-4ecbf0822055	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000001-0000-0000-0000-000000000002	\N	0.95000	0.99000	{"role": "финальный тест", "weight": 0.95, "confidence": 0.99}	2026-07-19 10:13:59.724504+00	2026-07-19 10:13:59.724509+00	\N	17
2a8a6d83-6a9d-4208-94eb-4b48cc299cf6	e0000001-0000-0000-0000-000000000002	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	0.95000	0.99000	{"role": "финальный тест", "weight": 0.95, "confidence": 0.99}	2026-07-19 10:13:59.724517+00	2026-07-19 10:13:59.724518+00	\N	17
ea764585-7023-4dc2-aa43-768cb8dce347	52080fdd-65e3-423c-8257-0c593aaa1fe9	c0000000-0000-0000-0000-000000000002	e0000002-0000-0000-0000-000000000001	\N	1.00000	1.00000	{"role": "Режисёр"}	2026-07-19 10:16:00.798278+00	2026-07-19 10:16:00.79828+00	\N	18
8a840306-35da-4401-ac1f-8a67742a3220	e0000002-0000-0000-0000-000000000001	76b7c699-d299-4aed-b387-f41158fa7fff	52080fdd-65e3-423c-8257-0c593aaa1fe9	\N	1.00000	1.00000	{"role": "Режисёр"}	2026-07-19 10:16:00.798283+00	2026-07-19 10:16:00.798283+00	\N	18
5b71962f-9f08-4d6d-9665-66eeab70faaf	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000021	e0000001-0000-0000-0000-000000000002	\N	1.00000	1.00000	{}	2026-07-19 10:45:47.310762+00	2026-07-19 10:45:47.310767+00	\N	19
2ca4b926-ffd9-4830-9f26-801c75572147	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	e0000001-0000-0000-0000-000000000002	\N	1.00000	1.00000	{}	2026-07-19 10:46:00.217647+00	2026-07-19 10:46:00.21765+00	\N	20
87903861-18ba-472e-92bb-e3922d831982	e0000001-0000-0000-0000-000000000002	76b7c699-d299-4aed-b387-f41158fa7fff	e0000001-0000-0000-0000-000000000001	\N	1.00000	1.00000	{}	2026-07-19 10:46:00.217653+00	2026-07-19 10:46:00.217653+00	\N	20
c73f016f-d3c7-493d-aa83-11f4340a81a2	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000006	9a6bc177-7cdc-4c25-aa9b-c62ac474a5dd	\N	\N	1.00000	{}	2026-07-19 13:48:58.045816+00	2026-07-19 13:48:58.045823+00	\N	146
7f937b46-d031-4cfd-9551-f4983058e4ae	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000006	706584a9-2a9f-4848-98d3-3ce09ba8f877	\N	\N	1.00000	{}	2026-07-19 13:48:58.056979+00	2026-07-19 13:48:58.056981+00	\N	146
c75284fc-f3db-4f00-ba36-bdfccd6ef70c	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000006	f58926e0-ae86-4cf9-9b29-52122e04ccc1	\N	\N	1.00000	{}	2026-07-19 13:48:58.063498+00	2026-07-19 13:48:58.063499+00	\N	146
2de5e63a-e750-4f91-9386-eaab2154995e	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000006	892aa355-ee57-476f-9640-009498da38df	\N	\N	1.00000	{}	2026-07-19 13:48:58.067574+00	2026-07-19 13:48:58.067575+00	\N	146
c053cb19-524f-4466-8550-345e2607e7ac	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000006	dd793190-1c6c-491b-8343-fd2cca3890a4	\N	\N	1.00000	{}	2026-07-19 13:48:58.071646+00	2026-07-19 13:48:58.071648+00	\N	146
9ac2fc6a-eaee-49b8-ae90-761136c3e6cc	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000006	aadec829-faec-400f-b176-d3377c7a7341	\N	\N	1.00000	{}	2026-07-19 13:48:58.078537+00	2026-07-19 13:48:58.078539+00	\N	146
01a94edb-39a5-49d4-8746-3e44d34a5139	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000006	a4f99864-c2e0-4d39-ad1d-7dd743810c33	\N	\N	1.00000	{}	2026-07-19 13:48:58.083645+00	2026-07-19 13:48:58.083647+00	\N	146
d582133e-ba04-442e-99ff-dba9be37c23e	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000006	f7d62057-688d-4fec-b265-07e556c2dcc1	\N	\N	1.00000	{}	2026-07-19 13:48:58.088949+00	2026-07-19 13:48:58.088951+00	\N	146
b382205d-980e-4ca5-8d70-6d409f1db45c	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000006	be0274e6-ae82-4af8-9516-a1cbc5ea0b5d	\N	\N	1.00000	{}	2026-07-19 13:48:58.093229+00	2026-07-19 13:48:58.09323+00	\N	146
201f2046-1856-4858-ab73-13e78b9e56f9	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000006	03bcc812-9a9c-4d0b-8e25-804e2e20a914	\N	\N	1.00000	{}	2026-07-19 13:48:58.097005+00	2026-07-19 13:48:58.097006+00	\N	146
e700db93-3a24-428c-bc32-6254210aea37	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000006	6a1793b8-15ff-4f6d-b265-b4618217105a	\N	\N	1.00000	{}	2026-07-19 13:48:58.100773+00	2026-07-19 13:48:58.100774+00	\N	146
25174015-84f0-4691-8665-163ca84f4c11	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000006	737be451-4908-46e2-9199-b1a84a8b5d24	\N	\N	1.00000	{}	2026-07-19 13:48:58.104438+00	2026-07-19 13:48:58.104439+00	\N	146
daf34ede-95c6-40f6-b522-cee06e6eae7b	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000006	5aec146a-7b9b-4390-aaac-984e77fed718	\N	\N	1.00000	{}	2026-07-19 13:48:58.108494+00	2026-07-19 13:48:58.108496+00	\N	146
c235e161-d483-4370-83d3-0ffa9f90e4e5	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000006	9dd57732-bf86-4a6e-85f4-2cca1a1da87c	\N	\N	1.00000	{}	2026-07-19 13:48:58.112105+00	2026-07-19 13:48:58.112106+00	\N	146
b24328a9-de26-4e20-af88-e9e42a5b184c	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000006	fcbdd077-30e8-4620-b0c9-a08b974cefaa	\N	\N	1.00000	{}	2026-07-19 13:48:58.115768+00	2026-07-19 13:48:58.115769+00	\N	146
e19e0608-2e9e-40d7-b22c-91dd3533319d	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	751948c6-c045-47b1-aceb-7ced3d525d20	\N	\N	1.00000	{}	2026-07-19 13:48:58.119404+00	2026-07-19 13:48:58.119406+00	\N	146
065a9d65-c788-4f33-a094-6b19d9544bfd	e0000001-0000-0000-0000-000000000001	c0000000-0000-0000-0000-000000000002	8324f64b-e6fd-491c-8300-d2f5a0c09201	\N	\N	1.00000	{}	2026-07-19 13:48:58.122955+00	2026-07-19 13:48:58.122956+00	\N	146
6a79e7f9-a099-4d93-9f8b-ff8a5f5c157d	f0000001-0000-0000-0000-000000000005	c0000000-0000-0000-0000-000000000006	c5330eb1-2122-444a-aa7e-f7266a3e8aa0	\N	\N	1.00000	{}	2026-07-19 17:35:23.97434+00	2026-07-19 17:35:23.974342+00	\N	149
fd89da12-61a6-492e-9900-78cfe26e4db0	f0000001-0000-0000-0000-000000000005	c0000000-0000-0000-0000-000000000006	83c5ad1b-1402-4361-8371-0931292979a7	\N	\N	1.00000	{}	2026-07-19 17:35:23.978775+00	2026-07-19 17:35:23.978777+00	\N	149
e60b9ade-616e-4c24-9e77-0244753b1c3f	f0000001-0000-0000-0000-000000000005	c0000000-0000-0000-0000-000000000006	b5bdf1b2-d6a2-4e9a-a5ae-becd088ca012	\N	\N	1.00000	{}	2026-07-19 17:35:23.982662+00	2026-07-19 17:35:23.982663+00	\N	149
f104ace0-2a62-48b1-bff8-4fe4dc027a62	f0000001-0000-0000-0000-000000000005	c0000000-0000-0000-0000-000000000006	7ff31578-8b55-45d8-9bbf-91b0a7525bb7	\N	\N	1.00000	{}	2026-07-19 17:35:23.986513+00	2026-07-19 17:35:23.986514+00	\N	149
01ac0b1d-3b6f-49d1-a457-05724f86efb7	f0000001-0000-0000-0000-000000000005	c0000000-0000-0000-0000-000000000006	2f0c96a7-2ecd-46af-85e8-1f01dee00683	\N	\N	1.00000	{}	2026-07-19 17:35:23.990481+00	2026-07-19 17:35:23.990482+00	\N	149
896780cb-96c6-4331-9cf9-f88548473cad	f0000001-0000-0000-0000-000000000005	c0000000-0000-0000-0000-000000000006	44866e92-9bbc-490d-b669-db2707e549d2	\N	\N	1.00000	{}	2026-07-19 17:35:23.995045+00	2026-07-19 17:35:23.995046+00	\N	149
00e7ac0a-0bfd-4695-ae64-ac2924b2f196	f0000001-0000-0000-0000-000000000005	c0000000-0000-0000-0000-000000000006	a6017768-8eed-4bd4-8338-d45eba357abd	\N	\N	1.00000	{}	2026-07-19 17:35:23.99897+00	2026-07-19 17:35:23.998971+00	\N	149
5a8e9758-b45d-4023-ba09-bb4a151be6b1	f0000001-0000-0000-0000-000000000005	c0000000-0000-0000-0000-000000000006	8022d0fa-eb01-4385-b009-61b872e3d036	\N	\N	1.00000	{}	2026-07-19 17:35:24.003137+00	2026-07-19 17:35:24.003139+00	\N	149
e40740e9-e03d-4184-b991-70a2e4a74b2f	f0000001-0000-0000-0000-000000000005	c0000000-0000-0000-0000-000000000006	621ccdbc-1f80-4974-bc0d-e56fe0ca0ecf	\N	\N	1.00000	{}	2026-07-19 17:35:24.007429+00	2026-07-19 17:35:24.00743+00	\N	149
89d7c451-3338-48ad-8339-1e2253c42af8	f0000001-0000-0000-0000-000000000005	c0000000-0000-0000-0000-000000000006	58c1d656-b2e5-493a-b773-a4b678b64b2a	\N	\N	1.00000	{}	2026-07-19 17:35:24.011569+00	2026-07-19 17:35:24.011571+00	\N	149
8abd308f-9e12-430c-8886-a8fe6a25de84	f0000001-0000-0000-0000-000000000005	c0000000-0000-0000-0000-000000000006	612d6657-a1f8-4846-b73b-37576f8c6304	\N	\N	1.00000	{}	2026-07-19 17:35:24.015625+00	2026-07-19 17:35:24.015626+00	\N	149
b01e2778-0483-4e4f-be59-2468ca10eace	f0000001-0000-0000-0000-000000000005	c0000000-0000-0000-0000-000000000006	bf61c434-1f7e-4306-807f-68b2e27d262f	\N	\N	1.00000	{}	2026-07-19 17:35:24.019719+00	2026-07-19 17:35:24.019721+00	\N	149
89b5cfff-c729-4b5f-a572-4bd95f3c6f4c	f0000001-0000-0000-0000-000000000005	c0000000-0000-0000-0000-000000000006	d25b91cf-596b-459d-80f8-13ac1b083bad	\N	\N	1.00000	{}	2026-07-19 17:35:24.023525+00	2026-07-19 17:35:24.023526+00	\N	149
2434cc6e-b859-4041-aa48-87aa2a891be3	f0000001-0000-0000-0000-000000000005	c0000000-0000-0000-0000-000000000006	7881a7a1-6aea-4d8d-80d6-97793e60fad3	\N	\N	1.00000	{}	2026-07-19 17:35:24.027426+00	2026-07-19 17:35:24.027427+00	\N	149
09129f3d-e779-4c77-9c7d-f3a14f661644	f0000001-0000-0000-0000-000000000005	c0000000-0000-0000-0000-000000000006	d65d0b30-03bb-49b1-8fd7-847edb52ebac	\N	\N	1.00000	{}	2026-07-19 17:35:24.031542+00	2026-07-19 17:35:24.031544+00	\N	149
b091c941-abc8-48c1-a0ab-6dab021ef776	f0000001-0000-0000-0000-000000000005	c0000000-0000-0000-0000-000000000002	aab7cb0d-f4ff-4769-94a6-0d570fe5e089	\N	\N	1.00000	{}	2026-07-19 17:35:24.035629+00	2026-07-19 17:35:24.035631+00	\N	149
83972ab5-1f49-42ef-ad1e-665497b952dc	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000006	c0701267-0db0-4aea-a58f-b44584a0fc19	\N	\N	1.00000	{}	2026-07-19 17:54:23.123836+00	2026-07-19 17:54:23.123838+00	\N	151
4030679f-3a59-4924-ae83-a85c02601c20	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000006	d3389f14-d9e3-4857-bb7c-4d8545a4f18a	\N	\N	1.00000	{}	2026-07-19 17:54:23.128267+00	2026-07-19 17:54:23.128268+00	\N	151
185f9160-6b3f-44b1-bc41-bc206729f614	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000006	57d94611-2ac2-4118-82f7-e74d498502ad	\N	\N	1.00000	{}	2026-07-19 17:54:23.132511+00	2026-07-19 17:54:23.132512+00	\N	151
cda87972-58f5-482e-8193-498cbc33f01d	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000006	07b4d6d2-5034-4225-97a9-db05c1436a9d	\N	\N	1.00000	{}	2026-07-19 17:54:23.13636+00	2026-07-19 17:54:23.136361+00	\N	151
793d4aee-da0c-4918-a2f4-bb39326fa9e3	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000006	c62a9f19-5458-4fc7-ad15-445ead40d427	\N	\N	1.00000	{}	2026-07-19 17:54:23.140195+00	2026-07-19 17:54:23.140197+00	\N	151
c68afb47-3ad2-4a93-9cd4-516adf911a1f	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000006	eb43c50e-60c1-45b5-abc7-359601b20e78	\N	\N	1.00000	{}	2026-07-19 17:54:23.144191+00	2026-07-19 17:54:23.144192+00	\N	151
33f38403-792a-4478-8042-aa04f8035bce	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000006	ff91f21b-087c-46f5-8972-9a86b1f0b16d	\N	\N	1.00000	{}	2026-07-19 17:54:23.147851+00	2026-07-19 17:54:23.147852+00	\N	151
721a8c57-99de-4445-b006-dbac45cd1166	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000006	107a2deb-a241-40d6-985a-f7dbfed74b7f	\N	\N	1.00000	{}	2026-07-19 17:54:23.151488+00	2026-07-19 17:54:23.15149+00	\N	151
24d56656-b636-4e86-922c-9cf20e20098f	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000006	563c1151-fc87-4e3d-a620-9d8e71fb7ffc	\N	\N	1.00000	{}	2026-07-19 17:54:23.155293+00	2026-07-19 17:54:23.155294+00	\N	151
094fc860-04dc-426c-80e2-c03205436555	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000006	180048a1-e479-4bdc-95da-af2c2d259d12	\N	\N	1.00000	{}	2026-07-19 17:54:23.158882+00	2026-07-19 17:54:23.158883+00	\N	151
533c5fbd-9890-483f-a345-10ba96552ea2	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000006	08ec1204-ba11-488d-8c57-2342ea453b59	\N	\N	1.00000	{}	2026-07-19 17:54:23.162284+00	2026-07-19 17:54:23.162285+00	\N	151
3ecf72b6-ecd5-465e-a78b-b6d314a54284	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000006	ea72f562-d8a6-41f7-a6ec-1675843be5ec	\N	\N	1.00000	{}	2026-07-19 17:54:23.16556+00	2026-07-19 17:54:23.165561+00	\N	151
ccf999f7-5625-4e4b-9f0b-1e4458111307	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000006	cc7780ca-3303-4c64-8d1b-e6577825b3b7	\N	\N	1.00000	{}	2026-07-19 17:54:23.168871+00	2026-07-19 17:54:23.168872+00	\N	151
f00aa1f0-9794-4c83-95f2-b1320240fb15	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000006	c21bcc41-b5c9-4a08-ba00-dcc52764c1e9	\N	\N	1.00000	{}	2026-07-19 17:54:23.172125+00	2026-07-19 17:54:23.172126+00	\N	151
b763be01-d674-4580-8cd2-3d7f90d59d63	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000006	02d16ff6-3ab9-480b-868c-d768f6b109b1	\N	\N	1.00000	{}	2026-07-19 17:54:23.175325+00	2026-07-19 17:54:23.175326+00	\N	151
f9143aac-4b63-4568-bc82-d31c8989941b	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000002	f468530a-e9a2-4625-8a94-9d4df3466d0d	\N	\N	1.00000	{}	2026-07-19 17:54:23.178603+00	2026-07-19 17:54:23.178604+00	\N	151
50190099-fed9-4061-8904-74567f3c3085	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	c0000000-0000-0000-0000-000000000002	ce8d3db0-84eb-42e0-a493-c061fc968327	\N	\N	1.00000	{}	2026-07-19 17:54:23.181927+00	2026-07-19 17:54:23.181928+00	\N	151
1b5f3aca-e7b3-4036-ba46-2507d866900e	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000006	c0701267-0db0-4aea-a58f-b44584a0fc19	\N	\N	1.00000	{"role": "Shrek (voice)"}	2026-07-19 18:00:17.256476+00	2026-07-19 18:00:17.256478+00	\N	153
56de1397-aae2-4576-81e7-b92e0efaffeb	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000006	d3389f14-d9e3-4857-bb7c-4d8545a4f18a	\N	\N	1.00000	{"role": "Donkey (voice)"}	2026-07-19 18:00:17.25955+00	2026-07-19 18:00:17.259552+00	\N	153
4979486e-441b-44f8-b87b-dddc3ea499c7	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000006	57d94611-2ac2-4118-82f7-e74d498502ad	\N	\N	1.00000	{"role": "Princess Fiona (voice)"}	2026-07-19 18:00:17.261317+00	2026-07-19 18:00:17.261318+00	\N	153
313bdc8a-33a2-4a89-bcf4-e89839147343	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000006	cc9b7dd3-40dd-4195-b7cd-c126d41258f7	\N	\N	1.00000	{"role": "Queen Lillian (voice)"}	2026-07-19 18:00:17.266278+00	2026-07-19 18:00:17.266279+00	\N	153
659e573b-c50e-49af-b7e4-b7fc0f1d716e	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000006	a8ed4e63-c56f-4f31-a238-e751b6c435f7	\N	\N	1.00000	{"role": "Puss in Boots (voice)"}	2026-07-19 18:00:17.270502+00	2026-07-19 18:00:17.270504+00	\N	153
d8071a9b-c4d6-4e2d-b01a-33b9b6a08751	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000006	52ee8010-258e-450f-b4d5-5a890a15aa2d	\N	\N	1.00000	{"role": "King Harold (voice)"}	2026-07-19 18:00:17.274548+00	2026-07-19 18:00:17.27455+00	\N	153
8454f50e-edf4-47db-ab0c-4d66cba5606c	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000006	e3a0c507-987f-4199-a278-2b2d5a247702	\N	\N	1.00000	{"role": "Prince Charming (voice)"}	2026-07-19 18:00:17.27922+00	2026-07-19 18:00:17.279222+00	\N	153
358a1c6c-3e3e-4469-b805-74569ae6cf61	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000006	4063e7b6-8904-4253-862a-b5bb7f6cab5e	\N	\N	1.00000	{"role": "Fairy Godmother (voice)"}	2026-07-19 18:00:17.28368+00	2026-07-19 18:00:17.283681+00	\N	153
70e96d31-e1b4-4b2d-a56f-8511bb831c5d	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000006	069115c4-0d7d-44a1-bc86-b3b2b32ceecc	\N	\N	1.00000	{"role": "Wolf (voice)"}	2026-07-19 18:00:17.287357+00	2026-07-19 18:00:17.287358+00	\N	153
ee40c9cb-c084-4ce4-adf4-c7db7166e18e	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000006	098f43d4-255f-4ca1-acd7-2d173b75ebcb	\N	\N	1.00000	{"role": "Page / Elf / Nobleman / Nobleman's Son (voice)"}	2026-07-19 18:00:17.290955+00	2026-07-19 18:00:17.290956+00	\N	153
1ca25042-7a8a-400d-972f-cd9da6dacdbf	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000006	08ec1204-ba11-488d-8c57-2342ea453b59	\N	\N	1.00000	{"role": "Pinocchio / Three Pigs (voice)"}	2026-07-19 18:00:17.292664+00	2026-07-19 18:00:17.292665+00	\N	153
53ff9dcd-d79c-4e0a-b0ab-76f98f60fa36	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000006	d9670e8a-00d6-428f-ae57-d1c27c4165e9	\N	\N	1.00000	{"role": "Gingerbread Man / Cedric / Announcer / Muffin Man / Mongo (voice)"}	2026-07-19 18:00:17.296256+00	2026-07-19 18:00:17.296257+00	\N	153
ec4aafd9-971f-4413-9d2e-bb27d3f619af	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000006	c21bcc41-b5c9-4a08-ba00-dcc52764c1e9	\N	\N	1.00000	{"role": "Blind Mouse (voice)"}	2026-07-19 18:00:17.297969+00	2026-07-19 18:00:17.29797+00	\N	153
a4c7169f-c9ab-4f4a-a842-7db69afd04e0	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000006	19818e98-346f-4cd0-9534-4f2a0d66a3d3	\N	\N	1.00000	{"role": "Herald / Man with Box (voice)"}	2026-07-19 18:00:17.30132+00	2026-07-19 18:00:17.301321+00	\N	153
9cfc2a7e-85ba-41ba-b557-c7336acdf1d9	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000006	b23c4bca-c593-43bc-a23d-02d8d19d6418	\N	\N	1.00000	{"role": "Mirror / Dresser (voice)"}	2026-07-19 18:00:17.304588+00	2026-07-19 18:00:17.304589+00	\N	153
0954bbae-7330-4d1e-a9ba-79acc3d592d6	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000002	e996ca57-23ba-4752-aebf-75828de3ffbb	\N	\N	1.00000	{}	2026-07-19 18:00:17.308052+00	2026-07-19 18:00:17.308054+00	\N	153
820e03ce-9bb7-479d-8ac5-f5a0f8502c46	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000002	feb7943f-7b21-4115-a93f-1c2324d1bc59	\N	\N	1.00000	{}	2026-07-19 18:00:17.311362+00	2026-07-19 18:00:17.311363+00	\N	153
a077b4f5-7e2d-40f2-9132-efa030362734	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	c0000000-0000-0000-0000-000000000002	f468530a-e9a2-4625-8a94-9d4df3466d0d	\N	\N	1.00000	{}	2026-07-19 18:00:17.312901+00	2026-07-19 18:00:17.312902+00	\N	153
f1b0c1c6-8189-4bac-963b-22b8d1994e68	9a6bc177-7cdc-4c25-aa9b-c62ac474a5dd	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	d9cf88f8-0597-4ce3-a92d-63cc1465e370	\N	\N	1.00000	{}	2026-07-19 18:56:27.735968+00	2026-07-19 18:56:27.73597+00	\N	154
505e8dce-94ec-4287-9176-bab0cc5ce3b7	d9cf88f8-0597-4ce3-a92d-63cc1465e370	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	e0000001-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 18:56:27.737093+00	2026-07-19 18:56:27.737095+00	\N	154
32752677-de10-4029-bd68-b935b95b65e0	706584a9-2a9f-4848-98d3-3ce09ba8f877	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	97921b0b-4188-45ca-ae5f-f927e7b6def0	\N	\N	1.00000	{}	2026-07-19 18:56:27.74378+00	2026-07-19 18:56:27.743781+00	\N	154
11106891-2b01-45c3-b492-b31c53cdb2fb	97921b0b-4188-45ca-ae5f-f927e7b6def0	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	e0000001-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 18:56:27.744481+00	2026-07-19 18:56:27.744482+00	\N	154
11e6a93d-f957-4929-a2d0-8aa6369a583f	f58926e0-ae86-4cf9-9b29-52122e04ccc1	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	ceff0138-d38a-4abb-9cec-e7d7dbef171c	\N	\N	1.00000	{}	2026-07-19 18:56:27.750384+00	2026-07-19 18:56:27.750386+00	\N	154
4f3c256d-c60a-4e66-9493-a36f6202fc5b	ceff0138-d38a-4abb-9cec-e7d7dbef171c	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	e0000001-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 18:56:27.751077+00	2026-07-19 18:56:27.751079+00	\N	154
657d48f8-0dfa-4b7f-9800-1fce5dba2bbf	892aa355-ee57-476f-9640-009498da38df	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	d2fbd49c-b31e-4da0-8d1f-3195197ff396	\N	\N	1.00000	{}	2026-07-19 18:56:27.756967+00	2026-07-19 18:56:27.756969+00	\N	154
2fbe7bb8-7421-4232-bc14-292aa3d44d0a	d2fbd49c-b31e-4da0-8d1f-3195197ff396	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	e0000001-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 18:56:27.757596+00	2026-07-19 18:56:27.757597+00	\N	154
085ac16c-81f5-41f5-9349-5fe9de258716	dd793190-1c6c-491b-8343-fd2cca3890a4	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	5020c846-3bde-4aba-8ce7-fef4bc15b075	\N	\N	1.00000	{}	2026-07-19 18:56:27.763136+00	2026-07-19 18:56:27.763137+00	\N	154
14ba566f-6631-41c4-90bc-f19f92bb8bd4	5020c846-3bde-4aba-8ce7-fef4bc15b075	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	e0000001-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 18:56:27.763724+00	2026-07-19 18:56:27.763725+00	\N	154
fb8e2679-996d-4c9f-aedc-35f1f68b9ae2	aadec829-faec-400f-b176-d3377c7a7341	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	5257a443-20b5-4331-825a-d8fb1f43eb37	\N	\N	1.00000	{}	2026-07-19 18:56:27.769838+00	2026-07-19 18:56:27.769839+00	\N	154
00fcc04e-4b6f-40c6-9832-d9b2be9cae32	5257a443-20b5-4331-825a-d8fb1f43eb37	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	e0000001-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 18:56:27.770396+00	2026-07-19 18:56:27.770397+00	\N	154
23f72b4f-3764-498f-930a-5e93b943125a	a4f99864-c2e0-4d39-ad1d-7dd743810c33	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	977c75f1-743e-40b6-b308-a93c0e2ff195	\N	\N	1.00000	{}	2026-07-19 18:56:27.775685+00	2026-07-19 18:56:27.775686+00	\N	154
432f9a55-b4a6-4154-8582-3d3b86e7e9eb	977c75f1-743e-40b6-b308-a93c0e2ff195	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	e0000001-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 18:56:27.776276+00	2026-07-19 18:56:27.776277+00	\N	154
ffb3c065-c457-4fc9-8cf8-26f172392b8f	f7d62057-688d-4fec-b265-07e556c2dcc1	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	2f4c6d3c-bbc2-461b-8088-1a14c0b018ab	\N	\N	1.00000	{}	2026-07-19 18:56:27.781439+00	2026-07-19 18:56:27.78144+00	\N	154
cd9b814e-e1db-4ba0-b879-3ca25cea5a77	2f4c6d3c-bbc2-461b-8088-1a14c0b018ab	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	e0000001-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 18:56:27.782018+00	2026-07-19 18:56:27.782019+00	\N	154
cdf22b19-7adf-4015-8240-dbb5dcf634d2	be0274e6-ae82-4af8-9516-a1cbc5ea0b5d	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	c1b51ade-a25a-4e04-a8da-2773d699b48e	\N	\N	1.00000	{}	2026-07-19 18:56:27.7876+00	2026-07-19 18:56:27.787601+00	\N	154
41a4165f-2414-4907-9dee-4c271df6a0bc	c1b51ade-a25a-4e04-a8da-2773d699b48e	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	e0000001-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 18:56:27.788216+00	2026-07-19 18:56:27.788217+00	\N	154
00e260bb-f185-4049-983d-a8c51e9ce04e	03bcc812-9a9c-4d0b-8e25-804e2e20a914	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	b7061ee7-f373-4b43-b56d-cab2f9dcb895	\N	\N	1.00000	{}	2026-07-19 18:56:27.793423+00	2026-07-19 18:56:27.793424+00	\N	154
fa810d5a-5e0a-430a-8d70-d491ab4d6942	b7061ee7-f373-4b43-b56d-cab2f9dcb895	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	e0000001-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 18:56:27.794003+00	2026-07-19 18:56:27.794004+00	\N	154
aff1f221-c77e-45ac-a2b7-567467575b90	6a1793b8-15ff-4f6d-b265-b4618217105a	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	0c8d8a8e-2521-4dfc-a392-9084a8498230	\N	\N	1.00000	{}	2026-07-19 18:56:27.799218+00	2026-07-19 18:56:27.799219+00	\N	154
db3436fc-35e4-4e01-9713-086d2f8f6871	0c8d8a8e-2521-4dfc-a392-9084a8498230	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	e0000001-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 18:56:27.799823+00	2026-07-19 18:56:27.799825+00	\N	154
8d3de61c-d6e6-469f-b546-e62ffe72a7cb	9dd57732-bf86-4a6e-85f4-2cca1a1da87c	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	13b8e6df-c5c4-43d8-ac0d-a08220eabed8	\N	\N	1.00000	{}	2026-07-19 18:56:27.817442+00	2026-07-19 18:56:27.817444+00	\N	154
2080adaa-0529-43e8-b618-12a6f81107e4	13b8e6df-c5c4-43d8-ac0d-a08220eabed8	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	e0000001-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 18:56:27.818376+00	2026-07-19 18:56:27.818378+00	\N	154
8f341c77-dccc-49a6-81c8-2b1bbaad647b	fcbdd077-30e8-4620-b0c9-a08b974cefaa	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	5b94ada5-9d41-4c0c-be33-534db9b41ec0	\N	\N	1.00000	{}	2026-07-19 18:56:27.824682+00	2026-07-19 18:56:27.824683+00	\N	154
5c9a37cf-d91a-4adc-86d8-f9d918e565e4	5b94ada5-9d41-4c0c-be33-534db9b41ec0	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	e0000001-0000-0000-0000-000000000001	\N	\N	1.00000	{}	2026-07-19 18:56:27.825344+00	2026-07-19 18:56:27.825345+00	\N	154
74414824-ead7-4c3d-857e-7b55781c1270	c0701267-0db0-4aea-a58f-b44584a0fc19	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	30eb75f8-d8d0-4524-b3e2-138db4604559	\N	\N	1.00000	{}	2026-07-19 18:59:48.509945+00	2026-07-19 18:59:48.509946+00	\N	155
8be46cc4-ff64-461f-8070-d052c20ce2ba	30eb75f8-d8d0-4524-b3e2-138db4604559	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	\N	\N	1.00000	{}	2026-07-19 18:59:48.510861+00	2026-07-19 18:59:48.510862+00	\N	155
b9e62e86-fb55-479f-89e4-77f10270c411	d3389f14-d9e3-4857-bb7c-4d8545a4f18a	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	db332f76-589d-4e7b-9864-eab3571ef0e4	\N	\N	1.00000	{}	2026-07-19 18:59:48.517602+00	2026-07-19 18:59:48.517603+00	\N	155
9ed4de5a-e0c9-4477-b2a2-2895699a8be8	db332f76-589d-4e7b-9864-eab3571ef0e4	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	\N	\N	1.00000	{}	2026-07-19 18:59:48.518274+00	2026-07-19 18:59:48.518275+00	\N	155
9cd79e80-d1a3-42cc-b005-1c718fcf6068	57d94611-2ac2-4118-82f7-e74d498502ad	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	5c33b912-a978-47b0-b9d8-4ad469c810c9	\N	\N	1.00000	{}	2026-07-19 18:59:48.52451+00	2026-07-19 18:59:48.524511+00	\N	155
994234c8-20cf-48f3-8f8d-9acf90f7d9d4	5c33b912-a978-47b0-b9d8-4ad469c810c9	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	\N	\N	1.00000	{}	2026-07-19 18:59:48.525201+00	2026-07-19 18:59:48.525202+00	\N	155
1d4edaf8-0001-4510-bb4e-c00cd8af9643	cc9b7dd3-40dd-4195-b7cd-c126d41258f7	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	02eb93b4-c73e-4c96-a701-111808e28ab8	\N	\N	1.00000	{}	2026-07-19 18:59:48.53437+00	2026-07-19 18:59:48.534371+00	\N	155
dc039d91-793c-488b-a9a6-e09fe6c18b9a	02eb93b4-c73e-4c96-a701-111808e28ab8	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	\N	\N	1.00000	{}	2026-07-19 18:59:48.535051+00	2026-07-19 18:59:48.535052+00	\N	155
f03a25f0-d90d-4632-8979-66814d4355a6	a8ed4e63-c56f-4f31-a238-e751b6c435f7	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	6fe6d5c2-0a4e-4bf0-9481-74f6339d16f8	\N	\N	1.00000	{}	2026-07-19 18:59:48.54133+00	2026-07-19 18:59:48.541332+00	\N	155
e93be6bd-d2ab-49ed-978a-6de048e1442b	6fe6d5c2-0a4e-4bf0-9481-74f6339d16f8	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	\N	\N	1.00000	{}	2026-07-19 18:59:48.541991+00	2026-07-19 18:59:48.541992+00	\N	155
08355c6c-f6d5-4ed6-bf2e-97e7029c833b	52ee8010-258e-450f-b4d5-5a890a15aa2d	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	2e9ef9fc-59b4-42a6-b119-21f68cf0efb9	\N	\N	1.00000	{}	2026-07-19 18:59:48.548086+00	2026-07-19 18:59:48.548087+00	\N	155
041936fa-1469-4e37-a99c-f8fbd2438464	2e9ef9fc-59b4-42a6-b119-21f68cf0efb9	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	\N	\N	1.00000	{}	2026-07-19 18:59:48.548756+00	2026-07-19 18:59:48.548757+00	\N	155
2f228736-4ab2-4b32-a5ca-6e2aa2af0969	e3a0c507-987f-4199-a278-2b2d5a247702	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	180c5397-e1f2-4dfc-8803-f0f524667761	\N	\N	1.00000	{}	2026-07-19 18:59:48.554966+00	2026-07-19 18:59:48.554967+00	\N	155
abf653b8-42e8-49fb-9ba1-b09e693e5864	180c5397-e1f2-4dfc-8803-f0f524667761	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	\N	\N	1.00000	{}	2026-07-19 18:59:48.555656+00	2026-07-19 18:59:48.555657+00	\N	155
aba0f696-d939-4d72-9f1b-d24d7f162628	4063e7b6-8904-4253-862a-b5bb7f6cab5e	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	8c065b5a-60ef-4585-b272-cb021f7c264d	\N	\N	1.00000	{}	2026-07-19 18:59:48.562016+00	2026-07-19 18:59:48.562018+00	\N	155
ea664e18-150f-46ba-935e-c51802d0c793	8c065b5a-60ef-4585-b272-cb021f7c264d	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	\N	\N	1.00000	{}	2026-07-19 18:59:48.562727+00	2026-07-19 18:59:48.562728+00	\N	155
8b292bee-7c3f-4648-997a-fce9ec94f8de	069115c4-0d7d-44a1-bc86-b3b2b32ceecc	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	6630f199-08f3-4bb0-bc09-8e1ae0ca884d	\N	\N	1.00000	{}	2026-07-19 18:59:48.56923+00	2026-07-19 18:59:48.569231+00	\N	155
817d3ba8-8941-4adf-96be-6d35dcbe8538	6630f199-08f3-4bb0-bc09-8e1ae0ca884d	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	\N	\N	1.00000	{}	2026-07-19 18:59:48.569917+00	2026-07-19 18:59:48.569918+00	\N	155
28d34591-0c79-456f-8338-22b033470c47	098f43d4-255f-4ca1-acd7-2d173b75ebcb	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	c2f0c449-e228-4cfa-a2ac-0425aa4ad10c	\N	\N	1.00000	{}	2026-07-19 18:59:48.57638+00	2026-07-19 18:59:48.576381+00	\N	155
d7c83fd1-e7d0-4d54-8c11-93c3afe763dc	c2f0c449-e228-4cfa-a2ac-0425aa4ad10c	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	\N	\N	1.00000	{}	2026-07-19 18:59:48.577015+00	2026-07-19 18:59:48.577017+00	\N	155
783d470f-b913-43ad-86da-27d5aa494d31	08ec1204-ba11-488d-8c57-2342ea453b59	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	b7bd9346-0a67-44aa-9d22-0f0fff577c70	\N	\N	1.00000	{}	2026-07-19 18:59:48.582643+00	2026-07-19 18:59:48.582644+00	\N	155
d097d107-c636-46aa-aa9b-56fd498eaaf5	b7bd9346-0a67-44aa-9d22-0f0fff577c70	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	\N	\N	1.00000	{}	2026-07-19 18:59:48.583329+00	2026-07-19 18:59:48.58333+00	\N	155
7e6a1a23-79b5-46e0-aa21-94da6d7c659d	d9670e8a-00d6-428f-ae57-d1c27c4165e9	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	97b40ffe-2d44-4260-a644-7ce53b3519f0	\N	\N	1.00000	{}	2026-07-19 18:59:48.589433+00	2026-07-19 18:59:48.589435+00	\N	155
89add9a9-4445-49b9-a927-34c39e157d6c	97b40ffe-2d44-4260-a644-7ce53b3519f0	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	\N	\N	1.00000	{}	2026-07-19 18:59:48.590077+00	2026-07-19 18:59:48.590078+00	\N	155
87bebb30-4202-43c7-9653-c9edbd302ed8	c21bcc41-b5c9-4a08-ba00-dcc52764c1e9	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	1ba5945b-a622-4164-b2a7-116a9db35201	\N	\N	1.00000	{}	2026-07-19 18:59:48.595659+00	2026-07-19 18:59:48.595661+00	\N	155
b1be50fd-b418-4cb0-9c8c-6947896fd87e	1ba5945b-a622-4164-b2a7-116a9db35201	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	\N	\N	1.00000	{}	2026-07-19 18:59:48.596306+00	2026-07-19 18:59:48.596307+00	\N	155
869d6183-04e9-4e9d-a1d7-71706a4d10d2	19818e98-346f-4cd0-9534-4f2a0d66a3d3	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	13a57abd-ff73-4536-bf0e-a14cb8c7e0f7	\N	\N	1.00000	{}	2026-07-19 18:59:48.602306+00	2026-07-19 18:59:48.602307+00	\N	155
4d535aea-0973-4766-b235-e0aacc0b4f5e	13a57abd-ff73-4536-bf0e-a14cb8c7e0f7	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	\N	\N	1.00000	{}	2026-07-19 18:59:48.602937+00	2026-07-19 18:59:48.602938+00	\N	155
c7584b18-c873-415f-ba60-4c34df3765d6	b23c4bca-c593-43bc-a23d-02d8d19d6418	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	fc37ff77-e9cd-4411-95e2-f48e05c3d6ef	\N	\N	1.00000	{}	2026-07-19 18:59:48.608656+00	2026-07-19 18:59:48.608657+00	\N	155
e579afd6-161f-4391-97be-bec374f54763	fc37ff77-e9cd-4411-95e2-f48e05c3d6ef	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	a1ba2b71-6feb-4a36-af15-33ea4a5037e0	\N	\N	1.00000	{}	2026-07-19 18:59:48.609201+00	2026-07-19 18:59:48.609202+00	\N	155
ea389d7d-ad60-44ba-add0-72380210b5a2	c0701267-0db0-4aea-a58f-b44584a0fc19	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	af8499a8-5fe9-4d0f-96a9-537c15fc2b81	\N	\N	1.00000	{}	2026-07-19 19:00:09.527353+00	2026-07-19 19:00:09.527354+00	\N	156
23e52922-2364-476e-b35c-12b5a289832d	af8499a8-5fe9-4d0f-96a9-537c15fc2b81	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	\N	\N	1.00000	{}	2026-07-19 19:00:09.528364+00	2026-07-19 19:00:09.528365+00	\N	156
944e0c87-93a9-471c-91d2-7929f2e2cde2	d3389f14-d9e3-4857-bb7c-4d8545a4f18a	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	37ba971e-2a02-43ee-937b-295df2b89dbb	\N	\N	1.00000	{}	2026-07-19 19:00:09.534331+00	2026-07-19 19:00:09.534332+00	\N	156
85d580a9-9061-47e1-8b0f-b3485c9bfeb5	37ba971e-2a02-43ee-937b-295df2b89dbb	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	\N	\N	1.00000	{}	2026-07-19 19:00:09.535026+00	2026-07-19 19:00:09.535027+00	\N	156
2e60fff6-e1d2-4931-bb31-9502997534fd	57d94611-2ac2-4118-82f7-e74d498502ad	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	5af53614-0b0b-4410-9215-7368eb07e348	\N	\N	1.00000	{}	2026-07-19 19:00:09.541017+00	2026-07-19 19:00:09.541019+00	\N	156
34670e57-a0d9-4b8e-9c64-658fcc2c9cd7	5af53614-0b0b-4410-9215-7368eb07e348	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	\N	\N	1.00000	{}	2026-07-19 19:00:09.541649+00	2026-07-19 19:00:09.54165+00	\N	156
73db21b7-d72f-4f4a-bc88-66825f2e1e2d	07b4d6d2-5034-4225-97a9-db05c1436a9d	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	41e3ebb7-7e87-420b-a048-2ddb0802cced	\N	\N	1.00000	{}	2026-07-19 19:00:09.547332+00	2026-07-19 19:00:09.547333+00	\N	156
bfa281d9-07a8-48b0-b3fb-f22d608f844f	41e3ebb7-7e87-420b-a048-2ddb0802cced	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	\N	\N	1.00000	{}	2026-07-19 19:00:09.54794+00	2026-07-19 19:00:09.547941+00	\N	156
b7ef977d-ff77-44c8-99ce-3e2ae5728393	c62a9f19-5458-4fc7-ad15-445ead40d427	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	54a1bc1b-9f2a-407b-a101-a38a7b6f64e1	\N	\N	1.00000	{}	2026-07-19 19:00:09.5535+00	2026-07-19 19:00:09.553501+00	\N	156
d7e16b21-38ef-4c4c-9f35-baef64e2d0f6	54a1bc1b-9f2a-407b-a101-a38a7b6f64e1	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	\N	\N	1.00000	{}	2026-07-19 19:00:09.554135+00	2026-07-19 19:00:09.554137+00	\N	156
d5505020-a5a4-42fd-816f-5b7a5aea294d	eb43c50e-60c1-45b5-abc7-359601b20e78	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	0a4812b1-25fb-4722-ba1c-299ba936f018	\N	\N	1.00000	{}	2026-07-19 19:00:09.562092+00	2026-07-19 19:00:09.562095+00	\N	156
7ce66ed7-7a9b-4b64-b79c-42e7e870d130	0a4812b1-25fb-4722-ba1c-299ba936f018	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	\N	\N	1.00000	{}	2026-07-19 19:00:09.563143+00	2026-07-19 19:00:09.563146+00	\N	156
3307fb4a-1711-499a-8227-1dda30fd99ac	ff91f21b-087c-46f5-8972-9a86b1f0b16d	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	bf8f9398-aeee-469d-ba79-7a3013a9663c	\N	\N	1.00000	{}	2026-07-19 19:00:09.570776+00	2026-07-19 19:00:09.570777+00	\N	156
2a5cbb45-a43f-4836-898f-4f59329084d9	bf8f9398-aeee-469d-ba79-7a3013a9663c	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	\N	\N	1.00000	{}	2026-07-19 19:00:09.571573+00	2026-07-19 19:00:09.571575+00	\N	156
8ae59709-b6a6-476d-a073-95623bc5de32	107a2deb-a241-40d6-985a-f7dbfed74b7f	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	73a692e5-1287-4cf1-836b-4505963848c6	\N	\N	1.00000	{}	2026-07-19 19:00:09.577361+00	2026-07-19 19:00:09.577362+00	\N	156
a6d01f58-8626-4dec-8214-96f8ddf374d7	73a692e5-1287-4cf1-836b-4505963848c6	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	\N	\N	1.00000	{}	2026-07-19 19:00:09.57797+00	2026-07-19 19:00:09.577971+00	\N	156
90208f8d-d4bc-40fc-8966-c1ec8c0fecf2	563c1151-fc87-4e3d-a620-9d8e71fb7ffc	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	c361e975-ebce-456e-b13c-c8171b27c183	\N	\N	1.00000	{}	2026-07-19 19:00:09.583275+00	2026-07-19 19:00:09.583276+00	\N	156
6352acc9-1b6d-46d6-a100-6ac4b7c86882	c361e975-ebce-456e-b13c-c8171b27c183	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	\N	\N	1.00000	{}	2026-07-19 19:00:09.583875+00	2026-07-19 19:00:09.583876+00	\N	156
f60ec300-77a5-45e5-86a3-db8ff68dcbc5	180048a1-e479-4bdc-95da-af2c2d259d12	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	b35b2264-99b7-4692-b71a-52a3b6400344	\N	\N	1.00000	{}	2026-07-19 19:00:09.589224+00	2026-07-19 19:00:09.589225+00	\N	156
2f6e46dd-b9c2-4798-8763-7e447a76ef1c	b35b2264-99b7-4692-b71a-52a3b6400344	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	\N	\N	1.00000	{}	2026-07-19 19:00:09.589836+00	2026-07-19 19:00:09.589837+00	\N	156
576e6e2c-bed8-43cd-a8ea-60344199e224	08ec1204-ba11-488d-8c57-2342ea453b59	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	8ac53ce1-018f-4f39-957f-52aaed4554a2	\N	\N	1.00000	{}	2026-07-19 19:00:09.595133+00	2026-07-19 19:00:09.595134+00	\N	156
f9ad45c1-7587-4c69-bfdd-95e122bd4177	8ac53ce1-018f-4f39-957f-52aaed4554a2	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	\N	\N	1.00000	{}	2026-07-19 19:00:09.595742+00	2026-07-19 19:00:09.595743+00	\N	156
53684ddc-5c8d-4203-bb8e-97c17bfbc02a	ea72f562-d8a6-41f7-a6ec-1675843be5ec	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	3c8a53a8-ce96-4362-b48a-7656a9bc4f5c	\N	\N	1.00000	{}	2026-07-19 19:00:09.601129+00	2026-07-19 19:00:09.601131+00	\N	156
ad8fea06-af13-4516-9b2b-97be7f36d9e9	3c8a53a8-ce96-4362-b48a-7656a9bc4f5c	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	\N	\N	1.00000	{}	2026-07-19 19:00:09.601723+00	2026-07-19 19:00:09.601724+00	\N	156
b65746bd-edf7-43b4-883e-b0bb2d2696e3	cc7780ca-3303-4c64-8d1b-e6577825b3b7	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	2a8c0373-d4ab-4644-a92b-c91c7d6d93dd	\N	\N	1.00000	{}	2026-07-19 19:00:09.606411+00	2026-07-19 19:00:09.606412+00	\N	156
5b7bcb2d-6ec2-4a2a-aef4-e869a0c471c6	2a8c0373-d4ab-4644-a92b-c91c7d6d93dd	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	\N	\N	1.00000	{}	2026-07-19 19:00:09.606997+00	2026-07-19 19:00:09.606998+00	\N	156
ce799998-9968-4864-8571-20356ea145bf	c21bcc41-b5c9-4a08-ba00-dcc52764c1e9	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	9f22f322-665a-4f02-9902-803885828421	\N	\N	1.00000	{}	2026-07-19 19:00:09.612479+00	2026-07-19 19:00:09.61248+00	\N	156
6ea96274-9713-4e35-a71e-a7047aaaebe0	9f22f322-665a-4f02-9902-803885828421	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	\N	\N	1.00000	{}	2026-07-19 19:00:09.613144+00	2026-07-19 19:00:09.613145+00	\N	156
5ef77a8a-fa00-4d6b-b9d0-edd1d0a2307f	02d16ff6-3ab9-480b-868c-d768f6b109b1	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	fcfd7d95-f4ee-4ea1-bbf6-a0120209771c	\N	\N	1.00000	{}	2026-07-19 19:00:09.619462+00	2026-07-19 19:00:09.619463+00	\N	156
0143b9e5-5578-4937-a33f-47e0d2224599	fcfd7d95-f4ee-4ea1-bbf6-a0120209771c	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	2819f96f-ffe2-4646-9cda-78d1c8cc1a19	\N	\N	1.00000	{}	2026-07-19 19:00:09.62028+00	2026-07-19 19:00:09.620281+00	\N	156
5ad57c68-2e71-4460-afc2-e07b11dd3452	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000006	9b4b190b-7734-443e-b3e0-3900b78219d5	\N	\N	1.00000	{"role": "Judy Hopps (voice)"}	2026-07-19 19:48:41.509359+00	2026-07-19 19:48:41.509361+00	\N	157
cf5e020f-b7ec-4df0-a1af-28e2ac0b98c5	9b4b190b-7734-443e-b3e0-3900b78219d5	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	da161a64-29c2-4aab-9a82-39052d22ffa1	\N	\N	1.00000	{}	2026-07-19 19:48:41.516495+00	2026-07-19 19:48:41.516496+00	\N	157
eb3f6d57-4e81-4806-bbc0-d54a91330a56	da161a64-29c2-4aab-9a82-39052d22ffa1	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	\N	\N	1.00000	{}	2026-07-19 19:48:41.517282+00	2026-07-19 19:48:41.517283+00	\N	157
7b838efb-9c41-4606-a95e-05d7807f3fc7	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000006	92fb377c-ac7f-4c80-9678-270ec3e66f88	\N	\N	1.00000	{"role": "Nick Wilde (voice)"}	2026-07-19 19:48:41.520973+00	2026-07-19 19:48:41.520974+00	\N	157
5e4f5fac-5573-4a07-9598-acd2bcbe2b01	92fb377c-ac7f-4c80-9678-270ec3e66f88	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	b4be05d9-ff7d-453f-8c20-dabc50c1076b	\N	\N	1.00000	{}	2026-07-19 19:48:41.524611+00	2026-07-19 19:48:41.524612+00	\N	157
5d1e8429-cd17-4310-9500-73b24dd1c612	b4be05d9-ff7d-453f-8c20-dabc50c1076b	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	\N	\N	1.00000	{}	2026-07-19 19:48:41.525259+00	2026-07-19 19:48:41.52526+00	\N	157
87b6135b-20b8-45ac-91f9-937ca430721d	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000006	7bf3a464-0efd-46e7-89f3-0b93fc8cbfec	\N	\N	1.00000	{"role": "Chief Bogo (voice)"}	2026-07-19 19:48:41.529139+00	2026-07-19 19:48:41.52914+00	\N	157
abc3c1dd-cd3b-46e9-851e-9bf6ec779b3c	7bf3a464-0efd-46e7-89f3-0b93fc8cbfec	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	ac4fd994-cd7f-4210-ad16-3f6ddcc04dfb	\N	\N	1.00000	{}	2026-07-19 19:48:41.533317+00	2026-07-19 19:48:41.533318+00	\N	157
913baf66-2a70-4976-afd1-010772019326	ac4fd994-cd7f-4210-ad16-3f6ddcc04dfb	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	\N	\N	1.00000	{}	2026-07-19 19:48:41.533968+00	2026-07-19 19:48:41.533969+00	\N	157
74adcf91-e7b9-46d4-820d-181fef73f414	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000006	e1141415-42c8-4e7e-ad71-8a9d7949af2b	\N	\N	1.00000	{"role": "Bellwether (voice)"}	2026-07-19 19:48:41.53764+00	2026-07-19 19:48:41.537641+00	\N	157
0d6e94ba-6be0-47ff-8599-69e647f14386	e1141415-42c8-4e7e-ad71-8a9d7949af2b	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	64557dc0-c440-49ae-830d-1fb7b8bc7cd4	\N	\N	1.00000	{}	2026-07-19 19:48:41.541138+00	2026-07-19 19:48:41.541139+00	\N	157
a6c9054e-c14b-4766-98c2-8b142dbfce7e	64557dc0-c440-49ae-830d-1fb7b8bc7cd4	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	\N	\N	1.00000	{}	2026-07-19 19:48:41.541773+00	2026-07-19 19:48:41.541774+00	\N	157
b5768764-f8ac-4f06-ad43-47feaf69fd41	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000006	8c2e35b8-9457-423b-8107-ff861a32ada8	\N	\N	1.00000	{"role": "Clawhauser (voice)"}	2026-07-19 19:48:41.546401+00	2026-07-19 19:48:41.546402+00	\N	157
2731b770-95a6-4a8e-a519-67a1359f9453	8c2e35b8-9457-423b-8107-ff861a32ada8	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	7991833c-a5a2-47f2-810e-577ca04f19ab	\N	\N	1.00000	{}	2026-07-19 19:48:41.550315+00	2026-07-19 19:48:41.550316+00	\N	157
202c1cbc-c7ed-44a4-bf9a-df9ef165b1c0	7991833c-a5a2-47f2-810e-577ca04f19ab	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	\N	\N	1.00000	{}	2026-07-19 19:48:41.550997+00	2026-07-19 19:48:41.550998+00	\N	157
7ce01ada-3d98-456a-876b-48569ad150d3	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000006	264ef215-8f96-4cba-a23c-5be136094a44	\N	\N	1.00000	{"role": "Bonnie Hopps (voice)"}	2026-07-19 19:48:41.554629+00	2026-07-19 19:48:41.55463+00	\N	157
efd2adff-c87b-4818-b8b7-18ce80c824e3	264ef215-8f96-4cba-a23c-5be136094a44	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	8009dcc2-8de4-4cb1-b19c-9a730c66be8e	\N	\N	1.00000	{}	2026-07-19 19:48:41.558454+00	2026-07-19 19:48:41.558455+00	\N	157
85af5360-a67b-4647-b547-80816eb6668c	8009dcc2-8de4-4cb1-b19c-9a730c66be8e	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	\N	\N	1.00000	{}	2026-07-19 19:48:41.559139+00	2026-07-19 19:48:41.55914+00	\N	157
6f295e59-ed1e-4abc-84af-5d95e9014a54	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000006	62a456b7-2791-4c6b-9e6e-d4bd41360679	\N	\N	1.00000	{"role": "Stu Hopps (voice)"}	2026-07-19 19:48:41.562774+00	2026-07-19 19:48:41.562776+00	\N	157
a2779467-5688-4602-be73-66ea73f2925e	62a456b7-2791-4c6b-9e6e-d4bd41360679	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	914f7b6a-c092-4a86-a316-f3540f598cc3	\N	\N	1.00000	{}	2026-07-19 19:48:41.566425+00	2026-07-19 19:48:41.566426+00	\N	157
b993dd27-92ab-40b2-a0d8-68549a5950b4	914f7b6a-c092-4a86-a316-f3540f598cc3	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	\N	\N	1.00000	{}	2026-07-19 19:48:41.56707+00	2026-07-19 19:48:41.567072+00	\N	157
28c981f6-887a-438d-aa21-ac82886230b2	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000006	af267160-e15e-4b14-a47f-48ab7b959736	\N	\N	1.00000	{"role": "Yax (voice)"}	2026-07-19 19:48:41.570823+00	2026-07-19 19:48:41.570825+00	\N	157
07428aa5-5072-43af-b1fd-eea6fdc72ad4	af267160-e15e-4b14-a47f-48ab7b959736	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	54ab11f2-cc7f-4ec9-8fdf-3a5b1cfa49ce	\N	\N	1.00000	{}	2026-07-19 19:48:41.574491+00	2026-07-19 19:48:41.574492+00	\N	157
2efa16c2-bf31-4ef3-b740-625fca23f268	54ab11f2-cc7f-4ec9-8fdf-3a5b1cfa49ce	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	\N	\N	1.00000	{}	2026-07-19 19:48:41.575142+00	2026-07-19 19:48:41.575144+00	\N	157
1359ffde-241f-4506-a345-4dcc2d6c779f	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000006	c458c1e4-f199-495a-bdc4-562391032b77	\N	\N	1.00000	{"role": "Mayor Lionheart (voice)"}	2026-07-19 19:48:41.578719+00	2026-07-19 19:48:41.57872+00	\N	157
cc1630a6-1896-4733-8518-70cf210ef20d	c458c1e4-f199-495a-bdc4-562391032b77	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	35cd9130-4138-4d44-ab5c-6dd21091016a	\N	\N	1.00000	{}	2026-07-19 19:48:41.582531+00	2026-07-19 19:48:41.582532+00	\N	157
8c23366f-3ad9-4e2e-99bd-662bde76b9b4	35cd9130-4138-4d44-ab5c-6dd21091016a	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	\N	\N	1.00000	{}	2026-07-19 19:48:41.583194+00	2026-07-19 19:48:41.583195+00	\N	157
e1c483c6-9d7c-40a9-98f8-4666feeb68b3	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000006	39e404d1-d653-47ac-ae0b-fc78906edca1	\N	\N	1.00000	{"role": "Mrs. Otterton (voice)"}	2026-07-19 19:48:41.586748+00	2026-07-19 19:48:41.58675+00	\N	157
0b57ca52-3163-4242-9401-fdc6a3b861ee	39e404d1-d653-47ac-ae0b-fc78906edca1	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	74404fe0-601d-40bd-a806-3ccd33c7b253	\N	\N	1.00000	{}	2026-07-19 19:48:41.59045+00	2026-07-19 19:48:41.590451+00	\N	157
da179bc7-6833-4144-9a49-e1836b3b8987	74404fe0-601d-40bd-a806-3ccd33c7b253	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	\N	\N	1.00000	{}	2026-07-19 19:48:41.591099+00	2026-07-19 19:48:41.591101+00	\N	157
e47d9207-3762-4f5e-999b-a84b2fb725f2	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000006	17596c41-45c8-4194-b5b9-8ad59de8023c	\N	\N	1.00000	{"role": "Duke Weaselton (voice)"}	2026-07-19 19:48:41.594496+00	2026-07-19 19:48:41.594497+00	\N	157
881732ed-1112-411d-9e90-a2b9b552f3f5	17596c41-45c8-4194-b5b9-8ad59de8023c	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	fcb69ad1-6d9e-49ba-bd05-93d6b53ef1f7	\N	\N	1.00000	{}	2026-07-19 19:48:41.597874+00	2026-07-19 19:48:41.597875+00	\N	157
f1095473-366f-492a-a735-f9f21b9ffa60	fcb69ad1-6d9e-49ba-bd05-93d6b53ef1f7	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	\N	\N	1.00000	{}	2026-07-19 19:48:41.598558+00	2026-07-19 19:48:41.598559+00	\N	157
b310a421-2a2e-45af-aedb-8d3e24284e0a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000006	a06660e0-613e-4ee1-be30-f46394bccacb	\N	\N	1.00000	{"role": "Gazelle (voice)"}	2026-07-19 19:48:41.602357+00	2026-07-19 19:48:41.602358+00	\N	157
0c37b89c-3a6a-4eec-9a54-dfd83ad50604	a06660e0-613e-4ee1-be30-f46394bccacb	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	1dd7a142-9b0d-47b7-832e-bd03833212a1	\N	\N	1.00000	{}	2026-07-19 19:48:41.605736+00	2026-07-19 19:48:41.605738+00	\N	157
1a9fd99d-750c-40c4-8e48-9efb03e52e2f	1dd7a142-9b0d-47b7-832e-bd03833212a1	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	\N	\N	1.00000	{}	2026-07-19 19:48:41.606302+00	2026-07-19 19:48:41.606303+00	\N	157
b925ac27-92ed-4f6b-b395-dd185c211dc7	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000006	3893ce3f-1cb6-4736-aad0-23de74a265bf	\N	\N	1.00000	{"role": "Flash (voice)"}	2026-07-19 19:48:41.609665+00	2026-07-19 19:48:41.609666+00	\N	157
9827bc6f-c326-439c-868a-e52e9b7c650b	3893ce3f-1cb6-4736-aad0-23de74a265bf	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	1460e1da-0058-4c32-ab21-ad0f0ac86630	\N	\N	1.00000	{}	2026-07-19 19:48:41.613131+00	2026-07-19 19:48:41.613132+00	\N	157
f530260a-e73a-4eb0-a26f-de43a8af3893	1460e1da-0058-4c32-ab21-ad0f0ac86630	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	\N	\N	1.00000	{}	2026-07-19 19:48:41.613726+00	2026-07-19 19:48:41.613727+00	\N	157
24d3b5df-b6be-4fa3-9b71-fc1955ad453a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000006	d146a201-ff80-48ca-bea8-2d893c6d460b	\N	\N	1.00000	{"role": "Young Hopps (voice)"}	2026-07-19 19:48:41.616967+00	2026-07-19 19:48:41.616969+00	\N	157
a3766f6f-81a7-4c28-a4bc-078034880f8d	d146a201-ff80-48ca-bea8-2d893c6d460b	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	502a57b2-0c2c-4671-a64a-f92efbfbbb04	\N	\N	1.00000	{}	2026-07-19 19:48:41.620288+00	2026-07-19 19:48:41.620289+00	\N	157
80e70e29-3b50-4129-b347-c99a7d369f19	502a57b2-0c2c-4671-a64a-f92efbfbbb04	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	\N	\N	1.00000	{}	2026-07-19 19:48:41.620886+00	2026-07-19 19:48:41.620887+00	\N	157
bf5bbf34-c8aa-40e9-92f6-189061c1e721	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000006	f5661936-9491-4aee-84ae-5068eb7128e0	\N	\N	1.00000	{"role": "Mr. Big (voice)"}	2026-07-19 19:48:41.624136+00	2026-07-19 19:48:41.624138+00	\N	157
4a05ea45-1d6b-4499-86d8-d74a7a1469fb	f5661936-9491-4aee-84ae-5068eb7128e0	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	91ec158e-f1aa-43ca-93b4-46d9dc975a6d	\N	\N	1.00000	{}	2026-07-19 19:48:41.627443+00	2026-07-19 19:48:41.627444+00	\N	157
ad20be51-c027-4856-aa7c-a6574579d801	91ec158e-f1aa-43ca-93b4-46d9dc975a6d	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	\N	\N	1.00000	{}	2026-07-19 19:48:41.62805+00	2026-07-19 19:48:41.628051+00	\N	157
c3338023-9de7-4834-94d1-5bdc0c8ad504	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000002	f818e778-d141-461a-827a-fed2c0fca280	\N	\N	1.00000	{}	2026-07-19 19:48:41.631326+00	2026-07-19 19:48:41.631327+00	\N	157
2d136952-6873-4f8b-b1f5-6b45ed71fc04	9cac47b2-da17-4f57-9ee2-d361f23ad6c2	c0000000-0000-0000-0000-000000000002	0abba340-8d2f-4ed7-9f6b-e6cfe890f527	\N	\N	1.00000	{}	2026-07-19 19:48:41.634636+00	2026-07-19 19:48:41.634637+00	\N	157
99d8f352-35f4-40f0-b19d-620abb640f6e	9de1b51d-ec3a-420d-babb-382618847a99	c0000000-0000-0000-0000-000000000006	67c9f624-5a95-4306-bffd-20d073d71275	\N	\N	1.00000	{"role": "Vincent Vega"}	2026-07-19 19:59:31.90755+00	2026-07-19 19:59:31.907553+00	\N	158
988f88b6-be8a-49b7-b89b-7e411a8dd93c	67c9f624-5a95-4306-bffd-20d073d71275	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	273d5a5e-c088-44ed-a37a-b1526d123c81	\N	\N	1.00000	{}	2026-07-19 19:59:31.913153+00	2026-07-19 19:59:31.913154+00	\N	158
54350382-8d4c-4689-a478-e5c61a7dd331	273d5a5e-c088-44ed-a37a-b1526d123c81	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9de1b51d-ec3a-420d-babb-382618847a99	\N	\N	1.00000	{}	2026-07-19 19:59:31.913822+00	2026-07-19 19:59:31.913823+00	\N	158
bc62ecc7-f636-4aa9-886b-004b60e316b5	9de1b51d-ec3a-420d-babb-382618847a99	c0000000-0000-0000-0000-000000000006	f274b66c-aa34-4977-8718-f93a90504eff	\N	\N	1.00000	{"role": "Jules Winnfield"}	2026-07-19 19:59:31.917214+00	2026-07-19 19:59:31.917215+00	\N	158
6ab7857c-ee11-4f84-b4c4-d0a0090aff74	f274b66c-aa34-4977-8718-f93a90504eff	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	93d6ae16-d715-48ef-ae0a-9c952d301899	\N	\N	1.00000	{}	2026-07-19 19:59:31.920522+00	2026-07-19 19:59:31.920523+00	\N	158
9b15c2c5-ed61-4947-82b8-085941dee178	93d6ae16-d715-48ef-ae0a-9c952d301899	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9de1b51d-ec3a-420d-babb-382618847a99	\N	\N	1.00000	{}	2026-07-19 19:59:31.921132+00	2026-07-19 19:59:31.921133+00	\N	158
b585542d-41a3-45dd-8c82-33e838687be0	9de1b51d-ec3a-420d-babb-382618847a99	c0000000-0000-0000-0000-000000000006	07c72226-91da-4cce-b159-bbb3fe96af0d	\N	\N	1.00000	{"role": "Mia Wallace"}	2026-07-19 19:59:31.92434+00	2026-07-19 19:59:31.924341+00	\N	158
f48639c5-bb3e-4415-82e6-10b4cf45f488	07c72226-91da-4cce-b159-bbb3fe96af0d	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	af4ee5a7-87f5-41d9-833b-2f427eba1d60	\N	\N	1.00000	{}	2026-07-19 19:59:31.927649+00	2026-07-19 19:59:31.92765+00	\N	158
b96b47df-476c-4bcc-975b-18a35f7a0d09	af4ee5a7-87f5-41d9-833b-2f427eba1d60	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9de1b51d-ec3a-420d-babb-382618847a99	\N	\N	1.00000	{}	2026-07-19 19:59:31.928261+00	2026-07-19 19:59:31.928262+00	\N	158
de6a56f1-3f24-4325-b898-47e575bc0c68	9de1b51d-ec3a-420d-babb-382618847a99	c0000000-0000-0000-0000-000000000006	a80e64cf-6154-4b65-8cc8-49ecb5eefbe3	\N	\N	1.00000	{"role": "Butch Coolidge"}	2026-07-19 19:59:31.931446+00	2026-07-19 19:59:31.931447+00	\N	158
ebb1a401-77c1-4506-9f16-2ef41e43480e	a80e64cf-6154-4b65-8cc8-49ecb5eefbe3	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	8b80bc82-fad2-4183-b3c5-236ef2445d8b	\N	\N	1.00000	{}	2026-07-19 19:59:31.93468+00	2026-07-19 19:59:31.934681+00	\N	158
8e3d5647-a15c-40b6-9922-301c1ba93412	8b80bc82-fad2-4183-b3c5-236ef2445d8b	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9de1b51d-ec3a-420d-babb-382618847a99	\N	\N	1.00000	{}	2026-07-19 19:59:31.93521+00	2026-07-19 19:59:31.935211+00	\N	158
e0465395-02bb-4509-9824-45187d18016e	9de1b51d-ec3a-420d-babb-382618847a99	c0000000-0000-0000-0000-000000000006	aeff218b-e7a7-4aa3-982c-1db5190eea43	\N	\N	1.00000	{"role": "Marsellus Wallace"}	2026-07-19 19:59:31.938413+00	2026-07-19 19:59:31.938414+00	\N	158
370021bd-2f97-409b-b247-232c8357c485	aeff218b-e7a7-4aa3-982c-1db5190eea43	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	4ed26f91-d573-48d1-bd0b-e81e1700ba1e	\N	\N	1.00000	{}	2026-07-19 19:59:31.942214+00	2026-07-19 19:59:31.942215+00	\N	158
572f7357-c3af-480c-8d55-3a06503fd8e1	4ed26f91-d573-48d1-bd0b-e81e1700ba1e	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9de1b51d-ec3a-420d-babb-382618847a99	\N	\N	1.00000	{}	2026-07-19 19:59:31.942808+00	2026-07-19 19:59:31.942809+00	\N	158
d3e0b896-4c76-4b2a-bf3d-60efcc46cf22	9de1b51d-ec3a-420d-babb-382618847a99	c0000000-0000-0000-0000-000000000006	3f7b450d-cc20-43e5-afcf-9b2f2ffefa67	\N	\N	1.00000	{"role": "The Wolf"}	2026-07-19 19:59:31.946004+00	2026-07-19 19:59:31.946005+00	\N	158
f844f6b6-6c08-425d-9566-291cdc9462ef	3f7b450d-cc20-43e5-afcf-9b2f2ffefa67	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	0368dac9-cff7-482e-bf94-547f63a89d16	\N	\N	1.00000	{}	2026-07-19 19:59:31.949298+00	2026-07-19 19:59:31.949299+00	\N	158
afa37fa1-1005-4d53-9e52-49deb9700b12	0368dac9-cff7-482e-bf94-547f63a89d16	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9de1b51d-ec3a-420d-babb-382618847a99	\N	\N	1.00000	{}	2026-07-19 19:59:31.949889+00	2026-07-19 19:59:31.94989+00	\N	158
cce1ad91-fad2-4dde-891b-acca9b49bc2a	9de1b51d-ec3a-420d-babb-382618847a99	c0000000-0000-0000-0000-000000000006	c9c1bdc9-3797-4400-9f7d-bb9db9735f45	\N	\N	1.00000	{"role": "Lance"}	2026-07-19 19:59:31.953185+00	2026-07-19 19:59:31.953186+00	\N	158
2af13088-3814-4b5a-a696-48b03c07807e	c9c1bdc9-3797-4400-9f7d-bb9db9735f45	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	3cc77c76-08e4-47cd-986a-92a5d027ed6e	\N	\N	1.00000	{}	2026-07-19 19:59:31.956524+00	2026-07-19 19:59:31.956525+00	\N	158
83177908-ae3e-4f24-893b-639f9fbfe638	3cc77c76-08e4-47cd-986a-92a5d027ed6e	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9de1b51d-ec3a-420d-babb-382618847a99	\N	\N	1.00000	{}	2026-07-19 19:59:31.957148+00	2026-07-19 19:59:31.957149+00	\N	158
2a2218d0-b6c5-4ffc-8170-e00e730acd0f	9de1b51d-ec3a-420d-babb-382618847a99	c0000000-0000-0000-0000-000000000006	9ff87f0f-0980-42b8-b126-c9babc559538	\N	\N	1.00000	{"role": "Pumpkin"}	2026-07-19 19:59:31.96041+00	2026-07-19 19:59:31.960411+00	\N	158
b02ee717-1832-4cf4-a72c-02ff18804c1d	9ff87f0f-0980-42b8-b126-c9babc559538	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	6d7de9d2-72e7-42e2-bdb4-8240914e16c8	\N	\N	1.00000	{}	2026-07-19 19:59:31.963644+00	2026-07-19 19:59:31.963645+00	\N	158
9378f398-fc04-4eb6-bc6f-f726ab8b5c41	6d7de9d2-72e7-42e2-bdb4-8240914e16c8	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9de1b51d-ec3a-420d-babb-382618847a99	\N	\N	1.00000	{}	2026-07-19 19:59:31.964228+00	2026-07-19 19:59:31.964229+00	\N	158
e9ad2b35-2e07-4881-a472-c93761b4d0b2	9de1b51d-ec3a-420d-babb-382618847a99	c0000000-0000-0000-0000-000000000006	f09b19fd-2f9c-4978-862b-6dba4039f12f	\N	\N	1.00000	{"role": "Honey Bunny"}	2026-07-19 19:59:31.967395+00	2026-07-19 19:59:31.967396+00	\N	158
ee539bcb-5787-423e-a56e-42ba64831492	f09b19fd-2f9c-4978-862b-6dba4039f12f	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	95f9f6bf-0762-41a4-bd7d-fc0174610ed4	\N	\N	1.00000	{}	2026-07-19 19:59:31.972057+00	2026-07-19 19:59:31.972059+00	\N	158
00d2587b-abf0-45fc-9383-d8b7f9f2aae3	95f9f6bf-0762-41a4-bd7d-fc0174610ed4	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9de1b51d-ec3a-420d-babb-382618847a99	\N	\N	1.00000	{}	2026-07-19 19:59:31.973361+00	2026-07-19 19:59:31.973363+00	\N	158
0d31041e-4770-4474-b871-3fa323c467d6	9de1b51d-ec3a-420d-babb-382618847a99	c0000000-0000-0000-0000-000000000006	fc0a62fb-ca91-4b8f-aa90-09817fdb2aae	\N	\N	1.00000	{"role": "Fabienne"}	2026-07-19 19:59:31.980315+00	2026-07-19 19:59:31.980317+00	\N	158
ffc1eb77-3030-4143-8d89-af15609a255a	fc0a62fb-ca91-4b8f-aa90-09817fdb2aae	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	7a928702-5d9a-4c9d-8edc-802af6044700	\N	\N	1.00000	{}	2026-07-19 19:59:31.986152+00	2026-07-19 19:59:31.986154+00	\N	158
44f29730-7ad3-4be7-b18a-a9c2ebfc0fee	7a928702-5d9a-4c9d-8edc-802af6044700	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9de1b51d-ec3a-420d-babb-382618847a99	\N	\N	1.00000	{}	2026-07-19 19:59:31.987219+00	2026-07-19 19:59:31.98722+00	\N	158
e6b6ffc1-b1fb-4d72-ab62-7529b542835c	9de1b51d-ec3a-420d-babb-382618847a99	c0000000-0000-0000-0000-000000000006	8eb99f48-0448-4835-9bb8-95440e9d84c4	\N	\N	1.00000	{"role": "Jimmie Dimmick"}	2026-07-19 19:59:31.993708+00	2026-07-19 19:59:31.993711+00	\N	158
717d26ec-29ef-4294-b237-eb9001722853	8eb99f48-0448-4835-9bb8-95440e9d84c4	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	18bf1029-f72e-4c7e-9f1b-267acefa7bdd	\N	\N	1.00000	{}	2026-07-19 19:59:32.000792+00	2026-07-19 19:59:32.000794+00	\N	158
b9a4751e-702c-4357-9dcf-ef15952b9b9a	18bf1029-f72e-4c7e-9f1b-267acefa7bdd	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9de1b51d-ec3a-420d-babb-382618847a99	\N	\N	1.00000	{}	2026-07-19 19:59:32.001724+00	2026-07-19 19:59:32.001726+00	\N	158
24a00218-7473-464d-8f20-0f85db30be78	9de1b51d-ec3a-420d-babb-382618847a99	c0000000-0000-0000-0000-000000000006	011abc73-09cd-496a-830e-2c18ceba5709	\N	\N	1.00000	{"role": "Captain Koons"}	2026-07-19 19:59:32.005732+00	2026-07-19 19:59:32.005734+00	\N	158
c241f251-e392-4716-99c6-abdf2103d486	011abc73-09cd-496a-830e-2c18ceba5709	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	eb724143-0021-4367-9398-73d93c7ddf2b	\N	\N	1.00000	{}	2026-07-19 19:59:32.009751+00	2026-07-19 19:59:32.009752+00	\N	158
c0dfdb6c-9918-440a-a887-fd60db135ca1	eb724143-0021-4367-9398-73d93c7ddf2b	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9de1b51d-ec3a-420d-babb-382618847a99	\N	\N	1.00000	{}	2026-07-19 19:59:32.010432+00	2026-07-19 19:59:32.010433+00	\N	158
5db4fb2b-8f8a-4f26-8224-dc9f310e693a	9de1b51d-ec3a-420d-babb-382618847a99	c0000000-0000-0000-0000-000000000006	5ab4456c-f3b0-4f3c-9133-51f341cfd762	\N	\N	1.00000	{"role": "Jody"}	2026-07-19 19:59:32.016627+00	2026-07-19 19:59:32.016629+00	\N	158
f60eef05-1f53-498e-ac71-eb8ddff5646d	5ab4456c-f3b0-4f3c-9133-51f341cfd762	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	19572261-c80f-48d5-85fc-08403eecfa24	\N	\N	1.00000	{}	2026-07-19 19:59:32.021196+00	2026-07-19 19:59:32.021197+00	\N	158
1bccb431-ab60-4933-9771-dfc880a98876	19572261-c80f-48d5-85fc-08403eecfa24	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9de1b51d-ec3a-420d-babb-382618847a99	\N	\N	1.00000	{}	2026-07-19 19:59:32.02194+00	2026-07-19 19:59:32.021942+00	\N	158
e80ae662-4801-4966-bfa7-1595be45027f	9de1b51d-ec3a-420d-babb-382618847a99	c0000000-0000-0000-0000-000000000006	aa3aee87-0fe7-4dd3-8aa4-a2113673916d	\N	\N	1.00000	{"role": "Zed"}	2026-07-19 19:59:32.025198+00	2026-07-19 19:59:32.025199+00	\N	158
c1be9f61-6544-4c02-b7ec-f589ad3c6fb5	aa3aee87-0fe7-4dd3-8aa4-a2113673916d	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	c8260e42-a05c-457d-a614-54c14a2b71ce	\N	\N	1.00000	{}	2026-07-19 19:59:32.029181+00	2026-07-19 19:59:32.029183+00	\N	158
10678d36-7d93-45df-a79d-a54d8cebf2c8	c8260e42-a05c-457d-a614-54c14a2b71ce	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9de1b51d-ec3a-420d-babb-382618847a99	\N	\N	1.00000	{}	2026-07-19 19:59:32.030051+00	2026-07-19 19:59:32.030053+00	\N	158
a2aec818-5dcb-4a84-99f2-651bad33bd3f	9de1b51d-ec3a-420d-babb-382618847a99	c0000000-0000-0000-0000-000000000006	db0a812a-b276-48f4-866b-a2d1d57ab6b1	\N	\N	1.00000	{"role": "Maynard"}	2026-07-19 19:59:32.034191+00	2026-07-19 19:59:32.034192+00	\N	158
8c0851a9-68a8-470c-9be7-c775ad7a68f5	db0a812a-b276-48f4-866b-a2d1d57ab6b1	4b5f3ec1-35fe-46a2-849f-da4b019ae8cb	71b9c2c8-db71-44b6-808a-ad43ac25d6e5	\N	\N	1.00000	{}	2026-07-19 19:59:32.037492+00	2026-07-19 19:59:32.037493+00	\N	158
400e3002-9822-4586-b4d5-11ee403fe6a7	71b9c2c8-db71-44b6-808a-ad43ac25d6e5	4a667207-4b8f-47f4-bb1c-c5e0c975ee5a	9de1b51d-ec3a-420d-babb-382618847a99	\N	\N	1.00000	{}	2026-07-19 19:59:32.038089+00	2026-07-19 19:59:32.03809+00	\N	158
b7325aa7-791f-4a48-85d8-4bf0c65e36c8	9de1b51d-ec3a-420d-babb-382618847a99	c0000000-0000-0000-0000-000000000002	a507779e-40a9-4731-abbf-96c9d9f90d2e	\N	\N	1.00000	{}	2026-07-19 19:59:32.04122+00	2026-07-19 19:59:32.041221+00	\N	158
\.


--
-- Data for Name: source_system; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.source_system (source_id, source_code, description, is_trusted, created_at) FROM stdin;
07cf887d-2773-4450-8605-9ec40d159d95	manual	Ручной ввод через интерфейс	t	2026-07-18 09:56:49.885843+00
d3b92f5a-7058-41a4-a312-c2a664f4fcc9	system	Системная запись	t	2026-07-18 09:56:49.885843+00
acec3c30-fef6-4734-84e1-96d8c44878f0	import	Импорт из внешнего источника	f	2026-07-18 09:56:49.885843+00
\.


--
-- Data for Name: user_account; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.user_account (user_id, username, email, display_name, password_hash, auth_provider, external_id, is_active, is_admin, phone, bio, avatar_url, language_preference, theme_id, created_at) FROM stdin;
a1000000-0000-0000-0000-000000000001	admin		Administrator	$2b$12$HSJOBFaP9ckt9WT3WNqJcuRJLiQXrDnP4gufdD7NvZXp7fLbxTz9y	local	\N	t	t			\N	ru	e0000002-0000-0000-0000-000000000001	2026-07-18 09:56:49.87916+00
\.


--
-- Data for Name: user_role; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.user_role (user_id, role_id) FROM stdin;
a1000000-0000-0000-0000-000000000001	ac4e8822-c70a-47f5-994d-dde5953ff4c9
\.


--
-- Data for Name: user_theme; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.user_theme (theme_id, user_id, theme_name, is_dark, is_active, colors, fonts, created_at) FROM stdin;
e0000001-0000-0000-0000-000000000001	a1000000-0000-0000-0000-000000000001	Светлая	f	f	{"text": "#111827", "error": "#ef4444", "accent": "#f59e0b", "border": "#e5e7eb", "primary": "#3b82f6", "success": "#10b981", "surface": "#f9fafb", "secondary": "#6366f1", "background": "#ffffff", "text_secondary": "#6b7280"}	{"body": "Inter, sans-serif", "mono": "JetBrains Mono, monospace", "heading": "Inter, sans-serif", "body_size": "0.875rem", "heading_size": "1.5rem"}	2026-07-18 09:56:49.881418+00
e0000002-0000-0000-0000-000000000001	a1000000-0000-0000-0000-000000000001	Тёмная	t	t	{"text": "#c0caf5", "error": "#f7768e", "accent": "#fbbf24", "border": "#3b4261", "primary": "#7c3aed", "success": "#9ece6a", "surface": "#24283b", "secondary": "#a78bfa", "background": "#1a1b26", "text_secondary": "#737aa2"}	{"body": "Inter, sans-serif", "mono": "JetBrains Mono, monospace", "heading": "Inter, sans-serif", "body_size": "0.875rem", "heading_size": "1.5rem"}	2026-07-18 09:56:49.881418+00
\.


--
-- Data for Name: version_registry; Type: TABLE DATA; Schema: meta; Owner: dwmb
--

COPY meta.version_registry (version_id, created_at, created_by, description) FROM stdin;
\.


--
-- Name: entity_label_entity_label_id_seq; Type: SEQUENCE SET; Schema: meta; Owner: dwmb
--

SELECT pg_catalog.setval('meta.entity_label_entity_label_id_seq', 1011, true);


--
-- Name: entity_template_assignment_assignment_id_seq; Type: SEQUENCE SET; Schema: meta; Owner: dwmb
--

SELECT pg_catalog.setval('meta.entity_template_assignment_assignment_id_seq', 1, false);


--
-- Name: version_registry_version_id_seq; Type: SEQUENCE SET; Schema: meta; Owner: dwmb
--

SELECT pg_catalog.setval('meta.version_registry_version_id_seq', 1, false);


--
-- Name: ai_config ai_config_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.ai_config
    ADD CONSTRAINT ai_config_pkey PRIMARY KEY (config_id);


--
-- Name: ai_suggestion ai_suggestion_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.ai_suggestion
    ADD CONSTRAINT ai_suggestion_pkey PRIMARY KEY (suggestion_id);


--
-- Name: ai_task_log ai_task_log_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.ai_task_log
    ADD CONSTRAINT ai_task_log_pkey PRIMARY KEY (task_id);


--
-- Name: comment comment_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.comment
    ADD CONSTRAINT comment_pkey PRIMARY KEY (comment_id);


--
-- Name: context context_context_code_key; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.context
    ADD CONSTRAINT context_context_code_key UNIQUE (context_code);


--
-- Name: context context_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.context
    ADD CONSTRAINT context_pkey PRIMARY KEY (context_id);


--
-- Name: entity_kind entity_kind_kind_code_key; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_kind
    ADD CONSTRAINT entity_kind_kind_code_key UNIQUE (kind_code);


--
-- Name: entity_kind_label entity_kind_label_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_kind_label
    ADD CONSTRAINT entity_kind_label_pkey PRIMARY KEY (kind_id, language);


--
-- Name: entity_kind entity_kind_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_kind
    ADD CONSTRAINT entity_kind_pkey PRIMARY KEY (kind_id);


--
-- Name: entity_kind_relation_constraint entity_kind_relation_constrai_from_kind_id_relation_code_to_key; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_kind_relation_constraint
    ADD CONSTRAINT entity_kind_relation_constrai_from_kind_id_relation_code_to_key UNIQUE (from_kind_id, relation_code, to_kind_id);


--
-- Name: entity_kind_relation_constraint entity_kind_relation_constraint_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_kind_relation_constraint
    ADD CONSTRAINT entity_kind_relation_constraint_pkey PRIMARY KEY (constraint_id);


--
-- Name: entity_label entity_label_entity_id_language_label_key; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_label
    ADD CONSTRAINT entity_label_entity_id_language_label_key UNIQUE (entity_id, language, label);


--
-- Name: entity_label entity_label_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_label
    ADD CONSTRAINT entity_label_pkey PRIMARY KEY (entity_label_id);


--
-- Name: entity entity_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity
    ADD CONSTRAINT entity_pkey PRIMARY KEY (entity_id);


--
-- Name: entity_projection entity_projection_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_projection
    ADD CONSTRAINT entity_projection_pkey PRIMARY KEY (projection_id);


--
-- Name: entity_projection entity_projection_projection_code_key; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_projection
    ADD CONSTRAINT entity_projection_projection_code_key UNIQUE (projection_code);


--
-- Name: entity_template_assignment entity_template_assignment_entity_id_template_id_key; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_template_assignment
    ADD CONSTRAINT entity_template_assignment_entity_id_template_id_key UNIQUE (entity_id, template_id);


--
-- Name: entity_template_assignment entity_template_assignment_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_template_assignment
    ADD CONSTRAINT entity_template_assignment_pkey PRIMARY KEY (assignment_id);


--
-- Name: event_log event_log_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.event_log
    ADD CONSTRAINT event_log_pkey PRIMARY KEY (event_id);


--
-- Name: field_registry field_registry_field_key_key; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.field_registry
    ADD CONSTRAINT field_registry_field_key_key UNIQUE (field_key);


--
-- Name: field_registry_label field_registry_label_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.field_registry_label
    ADD CONSTRAINT field_registry_label_pkey PRIMARY KEY (field_id, language);


--
-- Name: field_registry field_registry_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.field_registry
    ADD CONSTRAINT field_registry_pkey PRIMARY KEY (field_id);


--
-- Name: import_batch import_batch_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.import_batch
    ADD CONSTRAINT import_batch_pkey PRIMARY KEY (batch_id);


--
-- Name: media_asset media_asset_file_hash_key; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.media_asset
    ADD CONSTRAINT media_asset_file_hash_key UNIQUE (file_hash);


--
-- Name: media_asset media_asset_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.media_asset
    ADD CONSTRAINT media_asset_pkey PRIMARY KEY (asset_id);


--
-- Name: menu_item menu_item_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.menu_item
    ADD CONSTRAINT menu_item_pkey PRIMARY KEY (menu_id);


--
-- Name: ontology_model ontology_model_model_code_key; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.ontology_model
    ADD CONSTRAINT ontology_model_model_code_key UNIQUE (model_code);


--
-- Name: ontology_model ontology_model_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.ontology_model
    ADD CONSTRAINT ontology_model_pkey PRIMARY KEY (model_id);


--
-- Name: ontology_template ontology_template_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.ontology_template
    ADD CONSTRAINT ontology_template_pkey PRIMARY KEY (template_id);


--
-- Name: ontology_template ontology_template_template_code_key; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.ontology_template
    ADD CONSTRAINT ontology_template_template_code_key UNIQUE (template_code);


--
-- Name: page_registry page_registry_page_code_key; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.page_registry
    ADD CONSTRAINT page_registry_page_code_key UNIQUE (page_code);


--
-- Name: page_registry page_registry_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.page_registry
    ADD CONSTRAINT page_registry_pkey PRIMARY KEY (page_id);


--
-- Name: permission permission_permission_code_key; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.permission
    ADD CONSTRAINT permission_permission_code_key UNIQUE (permission_code);


--
-- Name: permission permission_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.permission
    ADD CONSTRAINT permission_pkey PRIMARY KEY (permission_id);


--
-- Name: projection_state projection_state_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.projection_state
    ADD CONSTRAINT projection_state_pkey PRIMARY KEY (state_id);


--
-- Name: relation_type relation_type_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.relation_type
    ADD CONSTRAINT relation_type_pkey PRIMARY KEY (relation_type_id);


--
-- Name: relation_type relation_type_relation_code_key; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.relation_type
    ADD CONSTRAINT relation_type_relation_code_key UNIQUE (relation_code);


--
-- Name: role_permission role_permission_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.role_permission
    ADD CONSTRAINT role_permission_pkey PRIMARY KEY (role_id, permission_id);


--
-- Name: role role_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (role_id);


--
-- Name: role role_role_code_key; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.role
    ADD CONSTRAINT role_role_code_key UNIQUE (role_code);


--
-- Name: semantic_relation semantic_relation_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.semantic_relation
    ADD CONSTRAINT semantic_relation_pkey PRIMARY KEY (relation_id);


--
-- Name: source_system source_system_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.source_system
    ADD CONSTRAINT source_system_pkey PRIMARY KEY (source_id);


--
-- Name: source_system source_system_source_code_key; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.source_system
    ADD CONSTRAINT source_system_source_code_key UNIQUE (source_code);


--
-- Name: user_account user_account_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.user_account
    ADD CONSTRAINT user_account_pkey PRIMARY KEY (user_id);


--
-- Name: user_account user_account_username_key; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.user_account
    ADD CONSTRAINT user_account_username_key UNIQUE (username);


--
-- Name: user_role user_role_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.user_role
    ADD CONSTRAINT user_role_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: user_theme user_theme_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.user_theme
    ADD CONSTRAINT user_theme_pkey PRIMARY KEY (theme_id);


--
-- Name: version_registry version_registry_pkey; Type: CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.version_registry
    ADD CONSTRAINT version_registry_pkey PRIMARY KEY (version_id);


--
-- Name: idx_ai_sug_entity; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_ai_sug_entity ON meta.ai_suggestion USING btree (entity_id);


--
-- Name: idx_ai_sug_type; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_ai_sug_type ON meta.ai_suggestion USING btree (suggestion_type);


--
-- Name: idx_ai_task_time; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_ai_task_time ON meta.ai_task_log USING btree (created_at DESC);


--
-- Name: idx_ai_task_type; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_ai_task_type ON meta.ai_task_log USING btree (task_type);


--
-- Name: idx_comment_entity; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_comment_entity ON meta.comment USING btree (entity_id);


--
-- Name: idx_comment_parent; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_comment_parent ON meta.comment USING btree (parent_id);


--
-- Name: idx_comment_user; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_comment_user ON meta.comment USING btree (user_id);


--
-- Name: idx_entity_code; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_entity_code ON meta.entity USING btree (entity_code);


--
-- Name: idx_entity_kind; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_entity_kind ON meta.entity USING btree (kind_id);


--
-- Name: idx_entity_owner; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_entity_owner ON meta.entity USING btree (owner_id) WHERE (owner_id IS NOT NULL);


--
-- Name: idx_entity_source; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_entity_source ON meta.entity USING btree (source_id);


--
-- Name: idx_entity_status; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_entity_status ON meta.entity USING btree (status);


--
-- Name: idx_entity_updated; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_entity_updated ON meta.entity USING btree (updated_at DESC);


--
-- Name: idx_event_entity; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_event_entity ON meta.event_log USING btree (entity_id);


--
-- Name: idx_event_time; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_event_time ON meta.event_log USING btree (occurred_at DESC);


--
-- Name: idx_event_type; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_event_type ON meta.event_log USING btree (event_type);


--
-- Name: idx_kind_constraint_from; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_kind_constraint_from ON meta.entity_kind_relation_constraint USING btree (from_kind_id);


--
-- Name: idx_kind_constraint_to; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_kind_constraint_to ON meta.entity_kind_relation_constraint USING btree (to_kind_id);


--
-- Name: idx_kind_parent; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_kind_parent ON meta.entity_kind USING btree (parent_kind_id);


--
-- Name: idx_label_entity; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_label_entity ON meta.entity_label USING btree (entity_id);


--
-- Name: idx_label_fts_en; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_label_fts_en ON meta.entity_label USING gin (to_tsvector('english'::regconfig, ((((label || ' '::text) || COALESCE(description, ''::text)) || ' '::text) || COALESCE(content, ''::text))));


--
-- Name: idx_label_fts_ru; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_label_fts_ru ON meta.entity_label USING gin (to_tsvector('russian'::regconfig, ((((label || ' '::text) || COALESCE(description, ''::text)) || ' '::text) || COALESCE(content, ''::text))));


--
-- Name: idx_label_language; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_label_language ON meta.entity_label USING btree (language);


--
-- Name: idx_label_trgm; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_label_trgm ON meta.entity_label USING gin (label public.gin_trgm_ops);


--
-- Name: idx_media_entity; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_media_entity ON meta.media_asset USING btree (entity_id);


--
-- Name: idx_media_hash; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_media_hash ON meta.media_asset USING btree (file_hash);


--
-- Name: idx_media_mime; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_media_mime ON meta.media_asset USING btree (mime_type);


--
-- Name: idx_menu_code; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_menu_code ON meta.menu_item USING btree (menu_code);


--
-- Name: idx_menu_parent; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_menu_parent ON meta.menu_item USING btree (parent_id);


--
-- Name: idx_proj_context; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_proj_context ON meta.entity_projection USING btree (context_id);


--
-- Name: idx_proj_entity; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_proj_entity ON meta.entity_projection USING btree (entity_id);


--
-- Name: idx_proj_entity_model; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_proj_entity_model ON meta.entity_projection USING btree (entity_id, model_id);


--
-- Name: idx_proj_model; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_proj_model ON meta.entity_projection USING btree (model_id);


--
-- Name: idx_rel_source; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_rel_source ON meta.semantic_relation USING btree (source_projection_id);


--
-- Name: idx_rel_source_type; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_rel_source_type ON meta.semantic_relation USING btree (source_projection_id, relation_type_id);


--
-- Name: idx_rel_target; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_rel_target ON meta.semantic_relation USING btree (target_projection_id);


--
-- Name: idx_rel_type; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_rel_type ON meta.semantic_relation USING btree (relation_type_id);


--
-- Name: idx_state_current; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_state_current ON meta.projection_state USING btree (projection_id) WHERE (is_current = true);


--
-- Name: idx_state_embedding; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_state_embedding ON meta.projection_state USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: idx_state_jsonb; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_state_jsonb ON meta.projection_state USING gin (state_data jsonb_path_ops);


--
-- Name: idx_state_projection; Type: INDEX; Schema: meta; Owner: dwmb
--

CREATE INDEX idx_state_projection ON meta.projection_state USING btree (projection_id);


--
-- Name: ai_suggestion ai_suggestion_entity_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.ai_suggestion
    ADD CONSTRAINT ai_suggestion_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES meta.entity(entity_id) ON DELETE CASCADE;


--
-- Name: ai_suggestion ai_suggestion_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.ai_suggestion
    ADD CONSTRAINT ai_suggestion_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES meta.user_account(user_id);


--
-- Name: ai_task_log ai_task_log_entity_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.ai_task_log
    ADD CONSTRAINT ai_task_log_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES meta.entity(entity_id);


--
-- Name: comment comment_entity_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.comment
    ADD CONSTRAINT comment_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES meta.entity(entity_id) ON DELETE CASCADE;


--
-- Name: comment comment_parent_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.comment
    ADD CONSTRAINT comment_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES meta.comment(comment_id) ON DELETE CASCADE;


--
-- Name: comment comment_user_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.comment
    ADD CONSTRAINT comment_user_id_fkey FOREIGN KEY (user_id) REFERENCES meta.user_account(user_id) ON DELETE SET NULL;


--
-- Name: context context_parent_context_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.context
    ADD CONSTRAINT context_parent_context_id_fkey FOREIGN KEY (parent_context_id) REFERENCES meta.context(context_id);


--
-- Name: entity entity_batch_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity
    ADD CONSTRAINT entity_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES meta.import_batch(batch_id);


--
-- Name: entity entity_kind_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity
    ADD CONSTRAINT entity_kind_id_fkey FOREIGN KEY (kind_id) REFERENCES meta.entity_kind(kind_id);


--
-- Name: entity_kind_label entity_kind_label_kind_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_kind_label
    ADD CONSTRAINT entity_kind_label_kind_id_fkey FOREIGN KEY (kind_id) REFERENCES meta.entity_kind(kind_id) ON DELETE CASCADE;


--
-- Name: entity_kind entity_kind_parent_kind_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_kind
    ADD CONSTRAINT entity_kind_parent_kind_id_fkey FOREIGN KEY (parent_kind_id) REFERENCES meta.entity_kind(kind_id);


--
-- Name: entity_kind_relation_constraint entity_kind_relation_constraint_from_kind_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_kind_relation_constraint
    ADD CONSTRAINT entity_kind_relation_constraint_from_kind_id_fkey FOREIGN KEY (from_kind_id) REFERENCES meta.entity_kind(kind_id);


--
-- Name: entity_kind_relation_constraint entity_kind_relation_constraint_to_kind_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_kind_relation_constraint
    ADD CONSTRAINT entity_kind_relation_constraint_to_kind_id_fkey FOREIGN KEY (to_kind_id) REFERENCES meta.entity_kind(kind_id);


--
-- Name: entity_label entity_label_entity_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_label
    ADD CONSTRAINT entity_label_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES meta.entity(entity_id) ON DELETE CASCADE;


--
-- Name: entity_label entity_label_owner_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_label
    ADD CONSTRAINT entity_label_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES meta.user_account(user_id);


--
-- Name: entity entity_owner_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity
    ADD CONSTRAINT entity_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES meta.user_account(user_id);


--
-- Name: entity_projection entity_projection_context_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_projection
    ADD CONSTRAINT entity_projection_context_id_fkey FOREIGN KEY (context_id) REFERENCES meta.context(context_id);


--
-- Name: entity_projection entity_projection_entity_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_projection
    ADD CONSTRAINT entity_projection_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES meta.entity(entity_id) ON DELETE CASCADE;


--
-- Name: entity_projection entity_projection_model_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_projection
    ADD CONSTRAINT entity_projection_model_id_fkey FOREIGN KEY (model_id) REFERENCES meta.ontology_model(model_id);


--
-- Name: entity_projection entity_projection_template_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_projection
    ADD CONSTRAINT entity_projection_template_id_fkey FOREIGN KEY (template_id) REFERENCES meta.ontology_template(template_id);


--
-- Name: entity entity_source_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity
    ADD CONSTRAINT entity_source_id_fkey FOREIGN KEY (source_id) REFERENCES meta.source_system(source_id);


--
-- Name: entity_template_assignment entity_template_assignment_entity_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_template_assignment
    ADD CONSTRAINT entity_template_assignment_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES meta.entity(entity_id) ON DELETE CASCADE;


--
-- Name: entity_template_assignment entity_template_assignment_template_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.entity_template_assignment
    ADD CONSTRAINT entity_template_assignment_template_id_fkey FOREIGN KEY (template_id) REFERENCES meta.ontology_template(template_id);


--
-- Name: event_log event_log_asset_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.event_log
    ADD CONSTRAINT event_log_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES meta.media_asset(asset_id);


--
-- Name: event_log event_log_entity_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.event_log
    ADD CONSTRAINT event_log_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES meta.entity(entity_id);


--
-- Name: event_log event_log_projection_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.event_log
    ADD CONSTRAINT event_log_projection_id_fkey FOREIGN KEY (projection_id) REFERENCES meta.entity_projection(projection_id);


--
-- Name: event_log event_log_relation_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.event_log
    ADD CONSTRAINT event_log_relation_id_fkey FOREIGN KEY (relation_id) REFERENCES meta.semantic_relation(relation_id);


--
-- Name: field_registry_label field_registry_label_field_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.field_registry_label
    ADD CONSTRAINT field_registry_label_field_id_fkey FOREIGN KEY (field_id) REFERENCES meta.field_registry(field_id) ON DELETE CASCADE;


--
-- Name: import_batch import_batch_source_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.import_batch
    ADD CONSTRAINT import_batch_source_id_fkey FOREIGN KEY (source_id) REFERENCES meta.source_system(source_id);


--
-- Name: media_asset media_asset_entity_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.media_asset
    ADD CONSTRAINT media_asset_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES meta.entity(entity_id);


--
-- Name: menu_item menu_item_parent_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.menu_item
    ADD CONSTRAINT menu_item_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES meta.menu_item(menu_id) ON DELETE CASCADE;


--
-- Name: ontology_template ontology_template_kind_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.ontology_template
    ADD CONSTRAINT ontology_template_kind_id_fkey FOREIGN KEY (kind_id) REFERENCES meta.entity_kind(kind_id);


--
-- Name: ontology_template ontology_template_model_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.ontology_template
    ADD CONSTRAINT ontology_template_model_id_fkey FOREIGN KEY (model_id) REFERENCES meta.ontology_model(model_id);


--
-- Name: page_registry page_registry_created_by_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.page_registry
    ADD CONSTRAINT page_registry_created_by_fkey FOREIGN KEY (created_by) REFERENCES meta.user_account(user_id);


--
-- Name: projection_state projection_state_projection_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.projection_state
    ADD CONSTRAINT projection_state_projection_id_fkey FOREIGN KEY (projection_id) REFERENCES meta.entity_projection(projection_id) ON DELETE CASCADE;


--
-- Name: relation_type relation_type_from_kind_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.relation_type
    ADD CONSTRAINT relation_type_from_kind_id_fkey FOREIGN KEY (from_kind_id) REFERENCES meta.entity_kind(kind_id);


--
-- Name: relation_type relation_type_inverse_type_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.relation_type
    ADD CONSTRAINT relation_type_inverse_type_id_fkey FOREIGN KEY (inverse_type_id) REFERENCES meta.relation_type(relation_type_id);


--
-- Name: relation_type relation_type_to_kind_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.relation_type
    ADD CONSTRAINT relation_type_to_kind_id_fkey FOREIGN KEY (to_kind_id) REFERENCES meta.entity_kind(kind_id);


--
-- Name: role_permission role_permission_permission_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.role_permission
    ADD CONSTRAINT role_permission_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES meta.permission(permission_id) ON DELETE CASCADE;


--
-- Name: role_permission role_permission_role_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.role_permission
    ADD CONSTRAINT role_permission_role_id_fkey FOREIGN KEY (role_id) REFERENCES meta.role(role_id) ON DELETE CASCADE;


--
-- Name: semantic_relation semantic_relation_context_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.semantic_relation
    ADD CONSTRAINT semantic_relation_context_id_fkey FOREIGN KEY (context_id) REFERENCES meta.context(context_id);


--
-- Name: semantic_relation semantic_relation_relation_type_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.semantic_relation
    ADD CONSTRAINT semantic_relation_relation_type_id_fkey FOREIGN KEY (relation_type_id) REFERENCES meta.relation_type(relation_type_id);


--
-- Name: semantic_relation semantic_relation_source_projection_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.semantic_relation
    ADD CONSTRAINT semantic_relation_source_projection_id_fkey FOREIGN KEY (source_projection_id) REFERENCES meta.entity_projection(projection_id) ON DELETE CASCADE;


--
-- Name: semantic_relation semantic_relation_target_projection_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.semantic_relation
    ADD CONSTRAINT semantic_relation_target_projection_id_fkey FOREIGN KEY (target_projection_id) REFERENCES meta.entity_projection(projection_id) ON DELETE CASCADE;


--
-- Name: user_role user_role_role_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.user_role
    ADD CONSTRAINT user_role_role_id_fkey FOREIGN KEY (role_id) REFERENCES meta.role(role_id) ON DELETE CASCADE;


--
-- Name: user_role user_role_user_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.user_role
    ADD CONSTRAINT user_role_user_id_fkey FOREIGN KEY (user_id) REFERENCES meta.user_account(user_id) ON DELETE CASCADE;


--
-- Name: user_theme user_theme_user_id_fkey; Type: FK CONSTRAINT; Schema: meta; Owner: dwmb
--

ALTER TABLE ONLY meta.user_theme
    ADD CONSTRAINT user_theme_user_id_fkey FOREIGN KEY (user_id) REFERENCES meta.user_account(user_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict bBKrEejqTvzRkpaJsbPmAa5U69uNHrshic3MAxjf0df6OOHb1ZNbXiW7S1pjrUW

