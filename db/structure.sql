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
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: ltree; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;


--
-- Name: EXTENSION ltree; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION ltree IS 'data type for hierarchical tree-like structures';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: access_token_context; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.access_token_context AS ENUM (
    'member_invitation'
);


--
-- Name: candidate_contact_created_via; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.candidate_contact_created_via AS ENUM (
    'api',
    'applied',
    'manual'
);


--
-- Name: candidate_contact_source; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.candidate_contact_source AS ENUM (
    'bitbucket',
    'devto',
    'djinni',
    'github',
    'habr',
    'headhunter',
    'hunter',
    'indeed',
    'kendo',
    'linkedin',
    'nymeria',
    'salesql',
    'genderize',
    'other'
);


--
-- Name: candidate_contact_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.candidate_contact_status AS ENUM (
    'current',
    'outdated',
    'invalid'
);


--
-- Name: candidate_contact_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.candidate_contact_type AS ENUM (
    'personal',
    'work'
);


--
-- Name: email_message_field; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.email_message_field AS ENUM (
    'from',
    'to',
    'cc',
    'bcc'
);


--
-- Name: email_message_sent_via; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.email_message_sent_via AS ENUM (
    'gmail',
    'internal_compose',
    'internal_reply'
);


--
-- Name: event_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.event_type AS ENUM (
    'active_storage_attachment_added',
    'active_storage_attachment_removed',
    'candidate_added',
    'candidate_changed',
    'candidate_merged',
    'candidate_recruiter_assigned',
    'candidate_recruiter_unassigned',
    'email_received',
    'email_sent',
    'note_added',
    'note_removed',
    'placement_added',
    'placement_changed',
    'placement_removed',
    'position_added',
    'position_changed',
    'position_collaborator_assigned',
    'position_collaborator_unassigned',
    'position_hiring_manager_assigned',
    'position_hiring_manager_unassigned',
    'position_interviewer_assigned',
    'position_interviewer_unassigned',
    'position_recruiter_assigned',
    'position_recruiter_unassigned',
    'position_stage_added',
    'position_stage_changed',
    'position_stage_removed',
    'scorecard_added',
    'scorecard_changed',
    'scorecard_removed',
    'scorecard_template_added',
    'scorecard_template_changed',
    'scorecard_template_removed',
    'task_added',
    'task_changed',
    'task_status_changed',
    'task_watcher_added',
    'task_watcher_removed'
);


--
-- Name: location_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.location_type AS ENUM (
    'city',
    'admin_region2',
    'admin_region1',
    'country',
    'set'
);


--
-- Name: member_access_level; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.member_access_level AS ENUM (
    'inactive',
    'member',
    'admin'
);


--
-- Name: placement_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.placement_status AS ENUM (
    'qualified',
    'reserved',
    'disqualified'
);


--
-- Name: position_change_status_reason; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.position_change_status_reason AS ENUM (
    'other',
    'new_position',
    'deprioritized',
    'filled',
    'no_longer_relevant',
    'cancelled'
);


--
-- Name: position_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.position_status AS ENUM (
    'draft',
    'open',
    'on_hold',
    'closed'
);


--
-- Name: repeat_interval_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.repeat_interval_type AS ENUM (
    'never',
    'daily',
    'weekly',
    'monthly',
    'yearly'
);


--
-- Name: scorecard_score; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.scorecard_score AS ENUM (
    'irrelevant',
    'relevant',
    'good',
    'perfect'
);


--
-- Name: task_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.task_status AS ENUM (
    'open',
    'closed'
);


--
-- Name: array_deduplicate(anyarray); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.array_deduplicate(input_array anyarray) RETURNS anyarray
    LANGUAGE plpgsql
    AS $$
  BEGIN
    RETURN ARRAY(SELECT DISTINCT unnest(input_array));
  END
$$;


--
-- Name: f_unaccent(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.f_unaccent(text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
      SELECT public.unaccent('public.unaccent', $1)
  $_$;


--
-- Name: location_expand_sets(bigint[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_expand_sets(location_ids bigint[]) RETURNS bigint[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
  DECLARE
    sets bigint[];
  BEGIN
    sets := (SELECT array_agg(id) FROM locations WHERE id = ANY(location_ids) AND type = 'set');

    IF sets IS NULL THEN
      RETURN location_ids;
    END iF;

    RETURN (
      WITH result_ids AS (
        WITH RECURSIVE lh(location_id) AS (
          SELECT location_id
          FROM location_hierarchies
          WHERE parent_location_id = ANY(sets)
          UNION
          SELECT location_hierarchies.location_id
          FROM location_hierarchies, lh
          JOIN locations l ON l.id = lh.location_id
          WHERE parent_location_id = lh.location_id
          AND l.type = 'set'
        )
        SELECT lh.location_id FROM lh
      )
      SELECT array_agg(id)
      FROM locations
      WHERE id IN (SELECT location_id FROM result_ids)
      AND type != 'set'
    );
  END;
$$;


--
-- Name: location_name_to_label(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_name_to_label(location_name text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
  BEGIN
    RETURN regexp_replace(f_unaccent(location_name), '[^A-Za-z0-9_]', '_', 'g');
  END;
$$;


--
-- Name: location_parents(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.location_parents(loc_id bigint) RETURNS bigint[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
  BEGIN
    RETURN (
      WITH location_path AS (
          SELECT array_agg(path) as paths
          FROM location_hierarchies
          WHERE location_id = loc_id
      )
      SELECT array_deduplicate(array_agg(location_id))
      FROM location_hierarchies
      WHERE path @> ANY(SELECT paths from location_path)
      AND location_id != loc_id
    );
  END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.access_tokens (
    id bigint NOT NULL,
    hashed_token bytea NOT NULL,
    sent_to public.citext NOT NULL,
    sent_at timestamp(6) without time zone,
    context public.access_token_context NOT NULL,
    tenant_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.access_tokens_id_seq OWNED BY public.access_tokens.id;


--
-- Name: account_password_reset_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_password_reset_keys (
    id bigint NOT NULL,
    key character varying NOT NULL,
    deadline timestamp(6) without time zone NOT NULL,
    email_last_sent timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: account_password_reset_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_password_reset_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_password_reset_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_password_reset_keys_id_seq OWNED BY public.account_password_reset_keys.id;


--
-- Name: account_remember_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_remember_keys (
    id bigint NOT NULL,
    key character varying NOT NULL,
    deadline timestamp(6) without time zone NOT NULL
);


--
-- Name: account_remember_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_remember_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_remember_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_remember_keys_id_seq OWNED BY public.account_remember_keys.id;


--
-- Name: account_verification_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_verification_keys (
    id bigint NOT NULL,
    key character varying NOT NULL,
    requested_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    email_last_sent timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: account_verification_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_verification_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_verification_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_verification_keys_id_seq OWNED BY public.account_verification_keys.id;


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id bigint NOT NULL,
    email public.citext NOT NULL,
    name character varying NOT NULL,
    linkedin_url character varying DEFAULT ''::character varying NOT NULL,
    calendar_url character varying DEFAULT ''::character varying NOT NULL,
    female boolean DEFAULT false NOT NULL,
    tenant_id bigint NOT NULL,
    external_source_id bigint,
    password_hash character varying,
    status integer DEFAULT 1 NOT NULL
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;


--
-- Name: action_text_rich_texts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.action_text_rich_texts (
    id bigint NOT NULL,
    name character varying NOT NULL,
    body text,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: action_text_rich_texts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.action_text_rich_texts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: action_text_rich_texts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.action_text_rich_texts_id_seq OWNED BY public.action_text_rich_texts.id;


--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: attachment_informations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attachment_informations (
    id bigint NOT NULL,
    is_cv boolean,
    active_storage_attachment_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: attachment_informations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attachment_informations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachment_informations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attachment_informations_id_seq OWNED BY public.attachment_informations.id;


--
-- Name: blazer_audits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blazer_audits (
    id bigint NOT NULL,
    user_id bigint,
    query_id bigint,
    statement text,
    data_source character varying,
    created_at timestamp(6) without time zone
);


--
-- Name: blazer_audits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blazer_audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blazer_audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blazer_audits_id_seq OWNED BY public.blazer_audits.id;


--
-- Name: blazer_checks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blazer_checks (
    id bigint NOT NULL,
    creator_id bigint,
    query_id bigint,
    state character varying,
    schedule character varying,
    emails text,
    slack_channels text,
    check_type character varying,
    message text,
    last_run_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: blazer_checks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blazer_checks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blazer_checks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blazer_checks_id_seq OWNED BY public.blazer_checks.id;


--
-- Name: blazer_dashboard_queries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blazer_dashboard_queries (
    id bigint NOT NULL,
    dashboard_id bigint,
    query_id bigint,
    "position" integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: blazer_dashboard_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blazer_dashboard_queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blazer_dashboard_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blazer_dashboard_queries_id_seq OWNED BY public.blazer_dashboard_queries.id;


--
-- Name: blazer_dashboards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blazer_dashboards (
    id bigint NOT NULL,
    creator_id bigint,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: blazer_dashboards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blazer_dashboards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blazer_dashboards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blazer_dashboards_id_seq OWNED BY public.blazer_dashboards.id;


--
-- Name: blazer_queries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blazer_queries (
    id bigint NOT NULL,
    creator_id bigint,
    name character varying,
    description text,
    statement text,
    data_source character varying,
    status character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: blazer_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blazer_queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blazer_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blazer_queries_id_seq OWNED BY public.blazer_queries.id;


--
-- Name: candidate_alternative_names; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.candidate_alternative_names (
    id bigint NOT NULL,
    candidate_id bigint NOT NULL,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tenant_id bigint NOT NULL
);


--
-- Name: candidate_alternative_names_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.candidate_alternative_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: candidate_alternative_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.candidate_alternative_names_id_seq OWNED BY public.candidate_alternative_names.id;


--
-- Name: candidate_email_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.candidate_email_addresses (
    id bigint NOT NULL,
    candidate_id bigint NOT NULL,
    address public.citext NOT NULL,
    list_index integer NOT NULL,
    type public.candidate_contact_type NOT NULL,
    source public.candidate_contact_source DEFAULT 'other'::public.candidate_contact_source NOT NULL,
    status public.candidate_contact_status DEFAULT 'current'::public.candidate_contact_status NOT NULL,
    url character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    added_at timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_via public.candidate_contact_created_via DEFAULT 'manual'::public.candidate_contact_created_via NOT NULL,
    created_by_id bigint,
    tenant_id bigint NOT NULL
);


--
-- Name: candidate_email_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.candidate_email_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: candidate_email_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.candidate_email_addresses_id_seq OWNED BY public.candidate_email_addresses.id;


--
-- Name: candidate_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.candidate_links (
    id bigint NOT NULL,
    candidate_id bigint NOT NULL,
    url character varying NOT NULL,
    status public.candidate_contact_status DEFAULT 'current'::public.candidate_contact_status NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    added_at timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_via public.candidate_contact_created_via DEFAULT 'manual'::public.candidate_contact_created_via NOT NULL,
    created_by_id bigint,
    tenant_id bigint NOT NULL
);


--
-- Name: candidate_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.candidate_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: candidate_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.candidate_links_id_seq OWNED BY public.candidate_links.id;


--
-- Name: candidate_phones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.candidate_phones (
    id bigint NOT NULL,
    candidate_id bigint NOT NULL,
    phone character varying NOT NULL,
    list_index integer NOT NULL,
    type public.candidate_contact_type NOT NULL,
    source public.candidate_contact_source DEFAULT 'other'::public.candidate_contact_source NOT NULL,
    status public.candidate_contact_status DEFAULT 'current'::public.candidate_contact_status NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    added_at timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_via public.candidate_contact_created_via DEFAULT 'manual'::public.candidate_contact_created_via NOT NULL,
    created_by_id bigint,
    tenant_id bigint NOT NULL
);


--
-- Name: candidate_phones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.candidate_phones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: candidate_phones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.candidate_phones_id_seq OWNED BY public.candidate_phones.id;


--
-- Name: candidate_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.candidate_sources (
    id bigint NOT NULL,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tenant_id bigint NOT NULL
);


--
-- Name: candidate_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.candidate_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: candidate_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.candidate_sources_id_seq OWNED BY public.candidate_sources.id;


--
-- Name: candidates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.candidates (
    id bigint NOT NULL,
    recruiter_id bigint,
    location_id bigint,
    full_name character varying NOT NULL,
    company character varying DEFAULT ''::character varying NOT NULL,
    merged_to integer,
    last_activity_at timestamp without time zone DEFAULT clock_timestamp() NOT NULL,
    blacklisted boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    headline character varying DEFAULT ''::character varying NOT NULL,
    telegram character varying DEFAULT ''::character varying NOT NULL,
    skype character varying DEFAULT ''::character varying NOT NULL,
    candidate_source_id bigint,
    tenant_id bigint NOT NULL,
    external_source_id bigint
);


--
-- Name: candidates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.candidates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: candidates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.candidates_id_seq OWNED BY public.candidates.id;


--
-- Name: disqualify_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disqualify_reasons (
    id bigint NOT NULL,
    title character varying NOT NULL,
    description character varying DEFAULT ''::character varying NOT NULL,
    tenant_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: disqualify_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.disqualify_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: disqualify_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.disqualify_reasons_id_seq OWNED BY public.disqualify_reasons.id;


--
-- Name: email_message_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_message_addresses (
    id bigint NOT NULL,
    email_message_id bigint,
    address public.citext NOT NULL,
    field public.email_message_field NOT NULL,
    "position" integer NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tenant_id bigint NOT NULL
);


--
-- Name: email_message_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_message_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_message_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_message_addresses_id_seq OWNED BY public.email_message_addresses.id;


--
-- Name: email_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_messages (
    id bigint NOT NULL,
    email_thread_id bigint NOT NULL,
    message_id character varying DEFAULT ''::character varying NOT NULL,
    in_reply_to character varying DEFAULT ''::character varying NOT NULL,
    autoreply_headers jsonb DEFAULT '{}'::jsonb NOT NULL,
    "timestamp" integer NOT NULL,
    subject character varying DEFAULT ''::character varying NOT NULL,
    plain_body text DEFAULT ''::text NOT NULL,
    html_body text DEFAULT ''::text NOT NULL,
    plain_mime_type character varying DEFAULT ''::character varying NOT NULL,
    sent_via public.email_message_sent_via,
    "references" character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tenant_id bigint NOT NULL
);


--
-- Name: email_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_messages_id_seq OWNED BY public.email_messages.id;


--
-- Name: email_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_templates (
    id bigint NOT NULL,
    name character varying NOT NULL,
    subject character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tenant_id bigint NOT NULL
);


--
-- Name: email_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_templates_id_seq OWNED BY public.email_templates.id;


--
-- Name: email_threads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_threads (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tenant_id bigint NOT NULL,
    external_source_id bigint
);


--
-- Name: email_threads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_threads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_threads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_threads_id_seq OWNED BY public.email_threads.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id bigint NOT NULL,
    type public.event_type NOT NULL,
    performed_at timestamp without time zone DEFAULT clock_timestamp() NOT NULL,
    actor_account_id bigint,
    eventable_type character varying NOT NULL,
    eventable_id integer NOT NULL,
    changed_field character varying,
    changed_from jsonb,
    changed_to jsonb,
    properties jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tenant_id bigint NOT NULL
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: friendly_id_slugs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.friendly_id_slugs (
    id bigint NOT NULL,
    slug character varying NOT NULL,
    sluggable_id integer NOT NULL,
    sluggable_type character varying(50),
    scope character varying,
    created_at timestamp(6) without time zone
);


--
-- Name: friendly_id_slugs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.friendly_id_slugs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: friendly_id_slugs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.friendly_id_slugs_id_seq OWNED BY public.friendly_id_slugs.id;


--
-- Name: location_aliases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.location_aliases (
    id bigint NOT NULL,
    location_id bigint NOT NULL,
    alias character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: location_aliases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.location_aliases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: location_aliases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.location_aliases_id_seq OWNED BY public.location_aliases.id;


--
-- Name: location_hierarchies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.location_hierarchies (
    id bigint NOT NULL,
    parent_location_id bigint,
    location_id bigint NOT NULL,
    path public.ltree NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: location_hierarchies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.location_hierarchies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: location_hierarchies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.location_hierarchies_id_seq OWNED BY public.location_hierarchies.id;


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locations (
    id bigint NOT NULL,
    geoname_id integer,
    type public.location_type NOT NULL,
    name character varying NOT NULL,
    ascii_name character varying NOT NULL,
    slug character varying,
    country_code character varying NOT NULL,
    country_name character varying DEFAULT ''::character varying NOT NULL,
    latitude numeric(10,7),
    longitude numeric(10,7),
    population integer DEFAULT 0 NOT NULL,
    time_zone character varying DEFAULT ''::character varying NOT NULL,
    linkedin_geourn integer,
    geoname_feature_code character varying DEFAULT ''::character varying NOT NULL,
    geoname_admin1_code character varying DEFAULT ''::character varying NOT NULL,
    geoname_admin2_code character varying DEFAULT ''::character varying NOT NULL,
    geoname_admin3_code character varying DEFAULT ''::character varying NOT NULL,
    geoname_admin4_code character varying DEFAULT ''::character varying NOT NULL,
    geoname_modification_date date,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.locations_id_seq OWNED BY public.locations.id;


--
-- Name: members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.members (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tenant_id bigint NOT NULL,
    refresh_token character varying DEFAULT ''::character varying NOT NULL,
    token character varying DEFAULT ''::character varying NOT NULL,
    last_email_synchronization_uid integer,
    access_level public.member_access_level
);


--
-- Name: members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.members_id_seq OWNED BY public.members.id;


--
-- Name: members_note_threads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.members_note_threads (
    note_thread_id bigint NOT NULL,
    member_id bigint NOT NULL
);


--
-- Name: note_reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.note_reactions (
    member_id bigint NOT NULL,
    note_id bigint NOT NULL
);


--
-- Name: note_threads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.note_threads (
    id bigint NOT NULL,
    notable_type character varying NOT NULL,
    notable_id bigint NOT NULL,
    hidden boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tenant_id bigint NOT NULL
);


--
-- Name: note_threads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.note_threads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: note_threads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.note_threads_id_seq OWNED BY public.note_threads.id;


--
-- Name: notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notes (
    id bigint NOT NULL,
    text text DEFAULT ''::text NOT NULL,
    note_thread_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    member_id bigint NOT NULL,
    tenant_id bigint NOT NULL
);


--
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notes_id_seq OWNED BY public.notes.id;


--
-- Name: placements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.placements (
    id bigint NOT NULL,
    position_id bigint NOT NULL,
    position_stage_id bigint NOT NULL,
    candidate_id bigint NOT NULL,
    status public.placement_status DEFAULT 'qualified'::public.placement_status NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tenant_id bigint NOT NULL,
    external_source_id bigint,
    disqualify_reason_id bigint
);


--
-- Name: placements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.placements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: placements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.placements_id_seq OWNED BY public.placements.id;


--
-- Name: position_stages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.position_stages (
    id bigint NOT NULL,
    position_id bigint NOT NULL,
    name character varying NOT NULL,
    list_index integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tenant_id bigint NOT NULL,
    external_source_id bigint,
    deleted boolean DEFAULT false NOT NULL
);


--
-- Name: position_stages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.position_stages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: position_stages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.position_stages_id_seq OWNED BY public.position_stages.id;


--
-- Name: positions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.positions (
    id bigint NOT NULL,
    name character varying NOT NULL,
    change_status_reason public.position_change_status_reason DEFAULT 'new_position'::public.position_change_status_reason NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    recruiter_id bigint,
    tenant_id bigint NOT NULL,
    external_source_id bigint,
    location_id bigint,
    status public.position_status DEFAULT 'draft'::public.position_status NOT NULL,
    slug character varying
);


--
-- Name: positions_collaborators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.positions_collaborators (
    position_id bigint NOT NULL,
    collaborator_id bigint NOT NULL
);


--
-- Name: positions_hiring_managers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.positions_hiring_managers (
    position_id bigint NOT NULL,
    hiring_manager_id bigint NOT NULL
);


--
-- Name: positions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.positions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: positions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.positions_id_seq OWNED BY public.positions.id;


--
-- Name: positions_interviewers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.positions_interviewers (
    position_id bigint NOT NULL,
    interviewer_id bigint NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: scorecard_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scorecard_questions (
    id bigint NOT NULL,
    scorecard_id bigint NOT NULL,
    question character varying NOT NULL,
    list_index integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tenant_id bigint NOT NULL
);


--
-- Name: scorecard_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scorecard_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scorecard_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scorecard_questions_id_seq OWNED BY public.scorecard_questions.id;


--
-- Name: scorecard_template_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scorecard_template_questions (
    id bigint NOT NULL,
    scorecard_template_id bigint NOT NULL,
    question character varying NOT NULL,
    list_index integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tenant_id bigint NOT NULL
);


--
-- Name: scorecard_template_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scorecard_template_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scorecard_template_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scorecard_template_questions_id_seq OWNED BY public.scorecard_template_questions.id;


--
-- Name: scorecard_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scorecard_templates (
    id bigint NOT NULL,
    position_stage_id bigint NOT NULL,
    title character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tenant_id bigint NOT NULL
);


--
-- Name: scorecard_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scorecard_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scorecard_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scorecard_templates_id_seq OWNED BY public.scorecard_templates.id;


--
-- Name: scorecards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scorecards (
    id bigint NOT NULL,
    position_stage_id bigint NOT NULL,
    placement_id bigint NOT NULL,
    title character varying NOT NULL,
    score public.scorecard_score NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    interviewer_id bigint NOT NULL,
    tenant_id bigint NOT NULL
);


--
-- Name: scorecards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scorecards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scorecards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scorecards_id_seq OWNED BY public.scorecards.id;


--
-- Name: solid_queue_blocked_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_blocked_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    concurrency_key character varying NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_blocked_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_blocked_executions_id_seq OWNED BY public.solid_queue_blocked_executions.id;


--
-- Name: solid_queue_claimed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_claimed_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    process_id bigint,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_claimed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_claimed_executions_id_seq OWNED BY public.solid_queue_claimed_executions.id;


--
-- Name: solid_queue_failed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_failed_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    error text,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_failed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_failed_executions_id_seq OWNED BY public.solid_queue_failed_executions.id;


--
-- Name: solid_queue_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_jobs (
    id bigint NOT NULL,
    queue_name character varying NOT NULL,
    class_name character varying NOT NULL,
    arguments text,
    priority integer DEFAULT 0 NOT NULL,
    active_job_id character varying,
    scheduled_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    concurrency_key character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_jobs_id_seq OWNED BY public.solid_queue_jobs.id;


--
-- Name: solid_queue_pauses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_pauses (
    id bigint NOT NULL,
    queue_name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_pauses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_pauses_id_seq OWNED BY public.solid_queue_pauses.id;


--
-- Name: solid_queue_processes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_processes (
    id bigint NOT NULL,
    kind character varying NOT NULL,
    last_heartbeat_at timestamp(6) without time zone NOT NULL,
    supervisor_id bigint,
    pid integer NOT NULL,
    hostname character varying,
    metadata text,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL
);


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_processes_id_seq OWNED BY public.solid_queue_processes.id;


--
-- Name: solid_queue_ready_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_ready_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_ready_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_ready_executions_id_seq OWNED BY public.solid_queue_ready_executions.id;


--
-- Name: solid_queue_recurring_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    task_key character varying NOT NULL,
    run_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_executions_id_seq OWNED BY public.solid_queue_recurring_executions.id;


--
-- Name: solid_queue_recurring_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_tasks (
    id bigint NOT NULL,
    key character varying NOT NULL,
    schedule character varying NOT NULL,
    command character varying(2048),
    class_name character varying,
    arguments text,
    queue_name character varying,
    priority integer DEFAULT 0,
    static boolean DEFAULT true NOT NULL,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_tasks_id_seq OWNED BY public.solid_queue_recurring_tasks.id;


--
-- Name: solid_queue_scheduled_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_scheduled_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    scheduled_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_scheduled_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_scheduled_executions_id_seq OWNED BY public.solid_queue_scheduled_executions.id;


--
-- Name: solid_queue_semaphores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_semaphores (
    id bigint NOT NULL,
    key character varying NOT NULL,
    value integer DEFAULT 1 NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_semaphores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_semaphores_id_seq OWNED BY public.solid_queue_semaphores.id;


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tasks (
    id bigint NOT NULL,
    name character varying NOT NULL,
    status public.task_status DEFAULT 'open'::public.task_status NOT NULL,
    repeat_interval public.repeat_interval_type DEFAULT 'never'::public.repeat_interval_type NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    taskable_type character varying,
    taskable_id bigint,
    assignee_id bigint,
    due_date date NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tenant_id bigint NOT NULL
);


--
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tasks_id_seq OWNED BY public.tasks.id;


--
-- Name: tasks_watchers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tasks_watchers (
    task_id bigint NOT NULL,
    watcher_id bigint NOT NULL
);


--
-- Name: tenants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenants (
    id bigint NOT NULL,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    career_site_enabled boolean DEFAULT false NOT NULL,
    public_styles text DEFAULT ''::text NOT NULL,
    slug character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: tenants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenants_id_seq OWNED BY public.tenants.id;


--
-- Name: access_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_tokens ALTER COLUMN id SET DEFAULT nextval('public.access_tokens_id_seq'::regclass);


--
-- Name: account_password_reset_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_password_reset_keys ALTER COLUMN id SET DEFAULT nextval('public.account_password_reset_keys_id_seq'::regclass);


--
-- Name: account_remember_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_remember_keys ALTER COLUMN id SET DEFAULT nextval('public.account_remember_keys_id_seq'::regclass);


--
-- Name: account_verification_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_verification_keys ALTER COLUMN id SET DEFAULT nextval('public.account_verification_keys_id_seq'::regclass);


--
-- Name: accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);


--
-- Name: action_text_rich_texts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_text_rich_texts ALTER COLUMN id SET DEFAULT nextval('public.action_text_rich_texts_id_seq'::regclass);


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: attachment_informations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachment_informations ALTER COLUMN id SET DEFAULT nextval('public.attachment_informations_id_seq'::regclass);


--
-- Name: blazer_audits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_audits ALTER COLUMN id SET DEFAULT nextval('public.blazer_audits_id_seq'::regclass);


--
-- Name: blazer_checks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_checks ALTER COLUMN id SET DEFAULT nextval('public.blazer_checks_id_seq'::regclass);


--
-- Name: blazer_dashboard_queries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_dashboard_queries ALTER COLUMN id SET DEFAULT nextval('public.blazer_dashboard_queries_id_seq'::regclass);


--
-- Name: blazer_dashboards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_dashboards ALTER COLUMN id SET DEFAULT nextval('public.blazer_dashboards_id_seq'::regclass);


--
-- Name: blazer_queries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_queries ALTER COLUMN id SET DEFAULT nextval('public.blazer_queries_id_seq'::regclass);


--
-- Name: candidate_alternative_names id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_alternative_names ALTER COLUMN id SET DEFAULT nextval('public.candidate_alternative_names_id_seq'::regclass);


--
-- Name: candidate_email_addresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_email_addresses ALTER COLUMN id SET DEFAULT nextval('public.candidate_email_addresses_id_seq'::regclass);


--
-- Name: candidate_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_links ALTER COLUMN id SET DEFAULT nextval('public.candidate_links_id_seq'::regclass);


--
-- Name: candidate_phones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_phones ALTER COLUMN id SET DEFAULT nextval('public.candidate_phones_id_seq'::regclass);


--
-- Name: candidate_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_sources ALTER COLUMN id SET DEFAULT nextval('public.candidate_sources_id_seq'::regclass);


--
-- Name: candidates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidates ALTER COLUMN id SET DEFAULT nextval('public.candidates_id_seq'::regclass);


--
-- Name: disqualify_reasons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disqualify_reasons ALTER COLUMN id SET DEFAULT nextval('public.disqualify_reasons_id_seq'::regclass);


--
-- Name: email_message_addresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_message_addresses ALTER COLUMN id SET DEFAULT nextval('public.email_message_addresses_id_seq'::regclass);


--
-- Name: email_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_messages ALTER COLUMN id SET DEFAULT nextval('public.email_messages_id_seq'::regclass);


--
-- Name: email_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_templates ALTER COLUMN id SET DEFAULT nextval('public.email_templates_id_seq'::regclass);


--
-- Name: email_threads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_threads ALTER COLUMN id SET DEFAULT nextval('public.email_threads_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: friendly_id_slugs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friendly_id_slugs ALTER COLUMN id SET DEFAULT nextval('public.friendly_id_slugs_id_seq'::regclass);


--
-- Name: location_aliases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_aliases ALTER COLUMN id SET DEFAULT nextval('public.location_aliases_id_seq'::regclass);


--
-- Name: location_hierarchies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_hierarchies ALTER COLUMN id SET DEFAULT nextval('public.location_hierarchies_id_seq'::regclass);


--
-- Name: locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations ALTER COLUMN id SET DEFAULT nextval('public.locations_id_seq'::regclass);


--
-- Name: members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members ALTER COLUMN id SET DEFAULT nextval('public.members_id_seq'::regclass);


--
-- Name: note_threads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note_threads ALTER COLUMN id SET DEFAULT nextval('public.note_threads_id_seq'::regclass);


--
-- Name: notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes ALTER COLUMN id SET DEFAULT nextval('public.notes_id_seq'::regclass);


--
-- Name: placements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.placements ALTER COLUMN id SET DEFAULT nextval('public.placements_id_seq'::regclass);


--
-- Name: position_stages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.position_stages ALTER COLUMN id SET DEFAULT nextval('public.position_stages_id_seq'::regclass);


--
-- Name: positions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions ALTER COLUMN id SET DEFAULT nextval('public.positions_id_seq'::regclass);


--
-- Name: scorecard_questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scorecard_questions ALTER COLUMN id SET DEFAULT nextval('public.scorecard_questions_id_seq'::regclass);


--
-- Name: scorecard_template_questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scorecard_template_questions ALTER COLUMN id SET DEFAULT nextval('public.scorecard_template_questions_id_seq'::regclass);


--
-- Name: scorecard_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scorecard_templates ALTER COLUMN id SET DEFAULT nextval('public.scorecard_templates_id_seq'::regclass);


--
-- Name: scorecards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scorecards ALTER COLUMN id SET DEFAULT nextval('public.scorecards_id_seq'::regclass);


--
-- Name: solid_queue_blocked_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_blocked_executions_id_seq'::regclass);


--
-- Name: solid_queue_claimed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_claimed_executions_id_seq'::regclass);


--
-- Name: solid_queue_failed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_failed_executions_id_seq'::regclass);


--
-- Name: solid_queue_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_jobs_id_seq'::regclass);


--
-- Name: solid_queue_pauses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_pauses_id_seq'::regclass);


--
-- Name: solid_queue_processes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_processes_id_seq'::regclass);


--
-- Name: solid_queue_ready_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_ready_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_tasks_id_seq'::regclass);


--
-- Name: solid_queue_scheduled_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_scheduled_executions_id_seq'::regclass);


--
-- Name: solid_queue_semaphores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_semaphores_id_seq'::regclass);


--
-- Name: tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks ALTER COLUMN id SET DEFAULT nextval('public.tasks_id_seq'::regclass);


--
-- Name: tenants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants ALTER COLUMN id SET DEFAULT nextval('public.tenants_id_seq'::regclass);


--
-- Name: access_tokens access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_tokens
    ADD CONSTRAINT access_tokens_pkey PRIMARY KEY (id);


--
-- Name: account_password_reset_keys account_password_reset_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_password_reset_keys
    ADD CONSTRAINT account_password_reset_keys_pkey PRIMARY KEY (id);


--
-- Name: account_remember_keys account_remember_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_remember_keys
    ADD CONSTRAINT account_remember_keys_pkey PRIMARY KEY (id);


--
-- Name: account_verification_keys account_verification_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_verification_keys
    ADD CONSTRAINT account_verification_keys_pkey PRIMARY KEY (id);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: action_text_rich_texts action_text_rich_texts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_text_rich_texts
    ADD CONSTRAINT action_text_rich_texts_pkey PRIMARY KEY (id);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: attachment_informations attachment_informations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachment_informations
    ADD CONSTRAINT attachment_informations_pkey PRIMARY KEY (id);


--
-- Name: blazer_audits blazer_audits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_audits
    ADD CONSTRAINT blazer_audits_pkey PRIMARY KEY (id);


--
-- Name: blazer_checks blazer_checks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_checks
    ADD CONSTRAINT blazer_checks_pkey PRIMARY KEY (id);


--
-- Name: blazer_dashboard_queries blazer_dashboard_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_dashboard_queries
    ADD CONSTRAINT blazer_dashboard_queries_pkey PRIMARY KEY (id);


--
-- Name: blazer_dashboards blazer_dashboards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_dashboards
    ADD CONSTRAINT blazer_dashboards_pkey PRIMARY KEY (id);


--
-- Name: blazer_queries blazer_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_queries
    ADD CONSTRAINT blazer_queries_pkey PRIMARY KEY (id);


--
-- Name: candidate_alternative_names candidate_alternative_names_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_alternative_names
    ADD CONSTRAINT candidate_alternative_names_pkey PRIMARY KEY (id);


--
-- Name: candidate_email_addresses candidate_email_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_email_addresses
    ADD CONSTRAINT candidate_email_addresses_pkey PRIMARY KEY (id);


--
-- Name: candidate_links candidate_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_links
    ADD CONSTRAINT candidate_links_pkey PRIMARY KEY (id);


--
-- Name: candidate_phones candidate_phones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_phones
    ADD CONSTRAINT candidate_phones_pkey PRIMARY KEY (id);


--
-- Name: candidate_sources candidate_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_sources
    ADD CONSTRAINT candidate_sources_pkey PRIMARY KEY (id);


--
-- Name: candidates candidates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidates
    ADD CONSTRAINT candidates_pkey PRIMARY KEY (id);


--
-- Name: disqualify_reasons disqualify_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disqualify_reasons
    ADD CONSTRAINT disqualify_reasons_pkey PRIMARY KEY (id);


--
-- Name: email_message_addresses email_message_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_message_addresses
    ADD CONSTRAINT email_message_addresses_pkey PRIMARY KEY (id);


--
-- Name: email_messages email_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_messages
    ADD CONSTRAINT email_messages_pkey PRIMARY KEY (id);


--
-- Name: email_templates email_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT email_templates_pkey PRIMARY KEY (id);


--
-- Name: email_threads email_threads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_threads
    ADD CONSTRAINT email_threads_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: friendly_id_slugs friendly_id_slugs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friendly_id_slugs
    ADD CONSTRAINT friendly_id_slugs_pkey PRIMARY KEY (id);


--
-- Name: location_aliases location_aliases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_aliases
    ADD CONSTRAINT location_aliases_pkey PRIMARY KEY (id);


--
-- Name: location_hierarchies location_hierarchies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_hierarchies
    ADD CONSTRAINT location_hierarchies_pkey PRIMARY KEY (id);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: members members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_pkey PRIMARY KEY (id);


--
-- Name: note_threads note_threads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note_threads
    ADD CONSTRAINT note_threads_pkey PRIMARY KEY (id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: placements placements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.placements
    ADD CONSTRAINT placements_pkey PRIMARY KEY (id);


--
-- Name: position_stages position_stages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.position_stages
    ADD CONSTRAINT position_stages_pkey PRIMARY KEY (id);


--
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: scorecard_questions scorecard_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scorecard_questions
    ADD CONSTRAINT scorecard_questions_pkey PRIMARY KEY (id);


--
-- Name: scorecard_template_questions scorecard_template_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scorecard_template_questions
    ADD CONSTRAINT scorecard_template_questions_pkey PRIMARY KEY (id);


--
-- Name: scorecard_templates scorecard_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scorecard_templates
    ADD CONSTRAINT scorecard_templates_pkey PRIMARY KEY (id);


--
-- Name: scorecards scorecards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scorecards
    ADD CONSTRAINT scorecards_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_blocked_executions solid_queue_blocked_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT solid_queue_blocked_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_claimed_executions solid_queue_claimed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT solid_queue_claimed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_failed_executions solid_queue_failed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT solid_queue_failed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_jobs solid_queue_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs
    ADD CONSTRAINT solid_queue_jobs_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_pauses solid_queue_pauses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses
    ADD CONSTRAINT solid_queue_pauses_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_processes solid_queue_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes
    ADD CONSTRAINT solid_queue_processes_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_ready_executions solid_queue_ready_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT solid_queue_ready_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_executions solid_queue_recurring_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT solid_queue_recurring_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_tasks solid_queue_recurring_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks
    ADD CONSTRAINT solid_queue_recurring_tasks_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_scheduled_executions solid_queue_scheduled_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT solid_queue_scheduled_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_semaphores solid_queue_semaphores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores
    ADD CONSTRAINT solid_queue_semaphores_pkey PRIMARY KEY (id);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);


--
-- Name: idx_on_collaborator_id_position_id_d61c6081fc; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_collaborator_id_position_id_d61c6081fc ON public.positions_collaborators USING btree (collaborator_id, position_id);


--
-- Name: idx_on_position_id_hiring_manager_id_39a4bc0c27; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_position_id_hiring_manager_id_39a4bc0c27 ON public.positions_hiring_managers USING btree (position_id, hiring_manager_id);


--
-- Name: idx_on_scorecard_template_id_list_index_625d06ef82; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_scorecard_template_id_list_index_625d06ef82 ON public.scorecard_template_questions USING btree (scorecard_template_id, list_index);


--
-- Name: index_access_tokens_on_hashed_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_tokens_on_hashed_token ON public.access_tokens USING hash (hashed_token);


--
-- Name: index_access_tokens_on_sent_to; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_tokens_on_sent_to ON public.access_tokens USING btree (sent_to);


--
-- Name: index_access_tokens_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_tokens_on_tenant_id ON public.access_tokens USING btree (tenant_id);


--
-- Name: index_accounts_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_email ON public.accounts USING btree (email);


--
-- Name: index_accounts_on_external_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_external_source_id ON public.accounts USING btree (external_source_id);


--
-- Name: index_accounts_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_tenant_id ON public.accounts USING btree (tenant_id);


--
-- Name: index_action_text_rich_texts_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_action_text_rich_texts_uniqueness ON public.action_text_rich_texts USING btree (record_type, record_id, name);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_attachment_informations_on_active_storage_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachment_informations_on_active_storage_attachment_id ON public.attachment_informations USING btree (active_storage_attachment_id);


--
-- Name: index_blazer_audits_on_query_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_audits_on_query_id ON public.blazer_audits USING btree (query_id);


--
-- Name: index_blazer_audits_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_audits_on_user_id ON public.blazer_audits USING btree (user_id);


--
-- Name: index_blazer_checks_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_checks_on_creator_id ON public.blazer_checks USING btree (creator_id);


--
-- Name: index_blazer_checks_on_query_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_checks_on_query_id ON public.blazer_checks USING btree (query_id);


--
-- Name: index_blazer_dashboard_queries_on_dashboard_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_dashboard_queries_on_dashboard_id ON public.blazer_dashboard_queries USING btree (dashboard_id);


--
-- Name: index_blazer_dashboard_queries_on_query_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_dashboard_queries_on_query_id ON public.blazer_dashboard_queries USING btree (query_id);


--
-- Name: index_blazer_dashboards_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_dashboards_on_creator_id ON public.blazer_dashboards USING btree (creator_id);


--
-- Name: index_blazer_queries_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_queries_on_creator_id ON public.blazer_queries USING btree (creator_id);


--
-- Name: index_candidate_alternative_names_on_candidate_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_candidate_alternative_names_on_candidate_id_and_name ON public.candidate_alternative_names USING btree (candidate_id, name);


--
-- Name: index_candidate_alternative_names_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidate_alternative_names_on_tenant_id ON public.candidate_alternative_names USING btree (tenant_id);


--
-- Name: index_candidate_email_addresses_on_candidate_id_and_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_candidate_email_addresses_on_candidate_id_and_address ON public.candidate_email_addresses USING btree (candidate_id, address);


--
-- Name: index_candidate_email_addresses_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidate_email_addresses_on_created_by_id ON public.candidate_email_addresses USING btree (created_by_id);


--
-- Name: index_candidate_email_addresses_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidate_email_addresses_on_tenant_id ON public.candidate_email_addresses USING btree (tenant_id);


--
-- Name: index_candidate_links_on_candidate_id_and_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_candidate_links_on_candidate_id_and_url ON public.candidate_links USING btree (candidate_id, url);


--
-- Name: index_candidate_links_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidate_links_on_created_by_id ON public.candidate_links USING btree (created_by_id);


--
-- Name: index_candidate_links_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidate_links_on_tenant_id ON public.candidate_links USING btree (tenant_id);


--
-- Name: index_candidate_phones_on_candidate_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidate_phones_on_candidate_id ON public.candidate_phones USING btree (candidate_id);


--
-- Name: index_candidate_phones_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidate_phones_on_created_by_id ON public.candidate_phones USING btree (created_by_id);


--
-- Name: index_candidate_phones_on_phone_and_candidate_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_candidate_phones_on_phone_and_candidate_id ON public.candidate_phones USING btree (phone, candidate_id);


--
-- Name: index_candidate_phones_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidate_phones_on_tenant_id ON public.candidate_phones USING btree (tenant_id);


--
-- Name: index_candidate_sources_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidate_sources_on_tenant_id ON public.candidate_sources USING btree (tenant_id);


--
-- Name: index_candidate_sources_on_tenant_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_candidate_sources_on_tenant_id_and_name ON public.candidate_sources USING btree (tenant_id, name);


--
-- Name: index_candidates_on_candidate_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidates_on_candidate_source_id ON public.candidates USING btree (candidate_source_id);


--
-- Name: index_candidates_on_external_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_candidates_on_external_source_id ON public.candidates USING btree (external_source_id);


--
-- Name: index_candidates_on_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidates_on_location_id ON public.candidates USING btree (location_id);


--
-- Name: index_candidates_on_recruiter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidates_on_recruiter_id ON public.candidates USING btree (recruiter_id);


--
-- Name: index_candidates_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidates_on_tenant_id ON public.candidates USING btree (tenant_id);


--
-- Name: index_disqualify_reasons_on_tenant_id_and_title; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_disqualify_reasons_on_tenant_id_and_title ON public.disqualify_reasons USING btree (tenant_id, title);


--
-- Name: index_email_message_addresses_on_address; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_message_addresses_on_address ON public.email_message_addresses USING btree (address);


--
-- Name: index_email_message_addresses_on_email_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_message_addresses_on_email_message_id ON public.email_message_addresses USING btree (email_message_id);


--
-- Name: index_email_message_addresses_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_message_addresses_on_tenant_id ON public.email_message_addresses USING btree (tenant_id);


--
-- Name: index_email_messages_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_messages_on_created_at ON public.email_messages USING btree (created_at);


--
-- Name: index_email_messages_on_email_thread_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_messages_on_email_thread_id ON public.email_messages USING btree (email_thread_id);


--
-- Name: index_email_messages_on_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_messages_on_message_id ON public.email_messages USING btree (message_id);


--
-- Name: index_email_messages_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_messages_on_tenant_id ON public.email_messages USING btree (tenant_id);


--
-- Name: index_email_templates_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_email_templates_on_name ON public.email_templates USING btree (name);


--
-- Name: index_email_templates_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_templates_on_tenant_id ON public.email_templates USING btree (tenant_id);


--
-- Name: index_email_threads_on_external_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_email_threads_on_external_source_id ON public.email_threads USING btree (external_source_id);


--
-- Name: index_email_threads_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_threads_on_tenant_id ON public.email_threads USING btree (tenant_id);


--
-- Name: index_events_on_actor_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_actor_account_id ON public.events USING btree (actor_account_id);


--
-- Name: index_events_on_changed_field; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_changed_field ON public.events USING btree (changed_field) WHERE (changed_field IS NOT NULL);


--
-- Name: index_events_on_changed_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_changed_from ON public.events USING gin (changed_from);


--
-- Name: index_events_on_changed_to; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_changed_to ON public.events USING gin (changed_to);


--
-- Name: index_events_on_eventable_id_and_eventable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_eventable_id_and_eventable_type ON public.events USING btree (eventable_id, eventable_type);


--
-- Name: index_events_on_properties; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_properties ON public.events USING gin (properties);


--
-- Name: index_events_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_tenant_id ON public.events USING btree (tenant_id);


--
-- Name: index_events_on_type_and_performed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_type_and_performed_at ON public.events USING btree (type, performed_at DESC);


--
-- Name: index_friendly_id_slugs_on_slug_and_sluggable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_friendly_id_slugs_on_slug_and_sluggable_type ON public.friendly_id_slugs USING btree (slug, sluggable_type);


--
-- Name: index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope ON public.friendly_id_slugs USING btree (slug, sluggable_type, scope);


--
-- Name: index_friendly_id_slugs_on_sluggable_type_and_sluggable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_friendly_id_slugs_on_sluggable_type_and_sluggable_id ON public.friendly_id_slugs USING btree (sluggable_type, sluggable_id);


--
-- Name: index_location_aliases_on_alias; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_location_aliases_on_alias ON public.location_aliases USING btree (alias);


--
-- Name: index_location_aliases_on_alias_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_location_aliases_on_alias_trgm ON public.location_aliases USING gin (lower(public.f_unaccent((alias)::text)) public.gin_trgm_ops);


--
-- Name: index_location_aliases_on_location_id_and_alias; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_location_aliases_on_location_id_and_alias ON public.location_aliases USING btree (location_id, alias);


--
-- Name: index_location_hierarchies_on_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_location_hierarchies_on_location_id ON public.location_hierarchies USING btree (location_id);


--
-- Name: index_location_hierarchies_on_parent_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_location_hierarchies_on_parent_location_id ON public.location_hierarchies USING btree (parent_location_id);


--
-- Name: index_location_hierarchies_on_path; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_location_hierarchies_on_path ON public.location_hierarchies USING btree (path);


--
-- Name: index_location_hierarchies_on_path_using_gist_16; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_location_hierarchies_on_path_using_gist_16 ON public.location_hierarchies USING gist (path public.gist_ltree_ops (siglen='16'));


--
-- Name: index_locations_on_country_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_country_code ON public.locations USING btree (country_code);


--
-- Name: index_locations_on_country_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_country_name ON public.locations USING btree (country_name);


--
-- Name: index_locations_on_geoname_admin1_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_geoname_admin1_code ON public.locations USING btree (geoname_admin1_code);


--
-- Name: index_locations_on_geoname_admin2_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_geoname_admin2_code ON public.locations USING btree (geoname_admin2_code);


--
-- Name: index_locations_on_geoname_admin3_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_geoname_admin3_code ON public.locations USING btree (geoname_admin3_code);


--
-- Name: index_locations_on_geoname_admin4_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_geoname_admin4_code ON public.locations USING btree (geoname_admin4_code);


--
-- Name: index_locations_on_geoname_feature_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_geoname_feature_code ON public.locations USING btree (geoname_feature_code);


--
-- Name: index_locations_on_geoname_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_locations_on_geoname_id ON public.locations USING btree (geoname_id);


--
-- Name: index_locations_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_name ON public.locations USING btree (name);


--
-- Name: index_locations_on_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_name_trgm ON public.locations USING gin (lower(public.f_unaccent((name)::text)) public.gin_trgm_ops);


--
-- Name: index_locations_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_locations_on_slug ON public.locations USING btree (slug);


--
-- Name: index_locations_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_type ON public.locations USING btree (type);


--
-- Name: index_members_note_threads_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_note_threads_on_member_id ON public.members_note_threads USING btree (member_id);


--
-- Name: index_members_note_threads_on_note_thread_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_note_threads_on_note_thread_id ON public.members_note_threads USING btree (note_thread_id);


--
-- Name: index_members_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_account_id ON public.members USING btree (account_id);


--
-- Name: index_members_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_tenant_id ON public.members USING btree (tenant_id);


--
-- Name: index_note_reactions_on_note_id_and_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_note_reactions_on_note_id_and_member_id ON public.note_reactions USING btree (note_id, member_id);


--
-- Name: index_note_threads_on_notable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_note_threads_on_notable ON public.note_threads USING btree (notable_type, notable_id);


--
-- Name: index_note_threads_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_note_threads_on_tenant_id ON public.note_threads USING btree (tenant_id);


--
-- Name: index_notes_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_member_id ON public.notes USING btree (member_id);


--
-- Name: index_notes_on_note_thread_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_note_thread_id ON public.notes USING btree (note_thread_id);


--
-- Name: index_notes_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_tenant_id ON public.notes USING btree (tenant_id);


--
-- Name: index_placements_on_candidate_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_placements_on_candidate_id ON public.placements USING btree (candidate_id);


--
-- Name: index_placements_on_disqualify_reason_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_placements_on_disqualify_reason_id ON public.placements USING btree (disqualify_reason_id);


--
-- Name: index_placements_on_external_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_placements_on_external_source_id ON public.placements USING btree (external_source_id);


--
-- Name: index_placements_on_position_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_placements_on_position_id ON public.placements USING btree (position_id);


--
-- Name: index_placements_on_position_stage_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_placements_on_position_stage_id ON public.placements USING btree (position_stage_id);


--
-- Name: index_placements_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_placements_on_tenant_id ON public.placements USING btree (tenant_id);


--
-- Name: index_position_stages_on_external_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_position_stages_on_external_source_id ON public.position_stages USING btree (external_source_id);


--
-- Name: index_position_stages_on_position_id_and_list_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_position_stages_on_position_id_and_list_index ON public.position_stages USING btree (position_id, list_index) WHERE (deleted = false);


--
-- Name: index_position_stages_on_position_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_position_stages_on_position_id_and_name ON public.position_stages USING btree (position_id, name) WHERE (deleted = false);


--
-- Name: index_position_stages_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_position_stages_on_tenant_id ON public.position_stages USING btree (tenant_id);


--
-- Name: index_positions_interviewers_on_position_id_and_interviewer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_positions_interviewers_on_position_id_and_interviewer_id ON public.positions_interviewers USING btree (position_id, interviewer_id);


--
-- Name: index_positions_on_external_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_positions_on_external_source_id ON public.positions USING btree (external_source_id);


--
-- Name: index_positions_on_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_positions_on_location_id ON public.positions USING btree (location_id);


--
-- Name: index_positions_on_recruiter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_positions_on_recruiter_id ON public.positions USING btree (recruiter_id);


--
-- Name: index_positions_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_positions_on_slug ON public.positions USING btree (slug);


--
-- Name: index_positions_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_positions_on_tenant_id ON public.positions USING btree (tenant_id);


--
-- Name: index_scorecard_questions_on_scorecard_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scorecard_questions_on_scorecard_id ON public.scorecard_questions USING btree (scorecard_id);


--
-- Name: index_scorecard_questions_on_scorecard_id_and_list_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_scorecard_questions_on_scorecard_id_and_list_index ON public.scorecard_questions USING btree (scorecard_id, list_index);


--
-- Name: index_scorecard_questions_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scorecard_questions_on_tenant_id ON public.scorecard_questions USING btree (tenant_id);


--
-- Name: index_scorecard_template_questions_on_scorecard_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scorecard_template_questions_on_scorecard_template_id ON public.scorecard_template_questions USING btree (scorecard_template_id);


--
-- Name: index_scorecard_template_questions_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scorecard_template_questions_on_tenant_id ON public.scorecard_template_questions USING btree (tenant_id);


--
-- Name: index_scorecard_templates_on_position_stage_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_scorecard_templates_on_position_stage_id ON public.scorecard_templates USING btree (position_stage_id);


--
-- Name: index_scorecard_templates_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scorecard_templates_on_tenant_id ON public.scorecard_templates USING btree (tenant_id);


--
-- Name: index_scorecards_on_placement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scorecards_on_placement_id ON public.scorecards USING btree (placement_id);


--
-- Name: index_scorecards_on_position_stage_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scorecards_on_position_stage_id ON public.scorecards USING btree (position_stage_id);


--
-- Name: index_scorecards_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scorecards_on_tenant_id ON public.scorecards USING btree (tenant_id);


--
-- Name: index_solid_queue_blocked_executions_for_maintenance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_maintenance ON public.solid_queue_blocked_executions USING btree (expires_at, concurrency_key);


--
-- Name: index_solid_queue_blocked_executions_for_release; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_release ON public.solid_queue_blocked_executions USING btree (concurrency_key, priority, job_id);


--
-- Name: index_solid_queue_blocked_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_blocked_executions_on_job_id ON public.solid_queue_blocked_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_claimed_executions_on_job_id ON public.solid_queue_claimed_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_process_id_and_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_claimed_executions_on_process_id_and_job_id ON public.solid_queue_claimed_executions USING btree (process_id, job_id);


--
-- Name: index_solid_queue_dispatch_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_dispatch_all ON public.solid_queue_scheduled_executions USING btree (scheduled_at, priority, job_id);


--
-- Name: index_solid_queue_failed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_failed_executions_on_job_id ON public.solid_queue_failed_executions USING btree (job_id);


--
-- Name: index_solid_queue_jobs_for_alerting; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_alerting ON public.solid_queue_jobs USING btree (scheduled_at, finished_at);


--
-- Name: index_solid_queue_jobs_for_filtering; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_filtering ON public.solid_queue_jobs USING btree (queue_name, finished_at);


--
-- Name: index_solid_queue_jobs_on_active_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_active_job_id ON public.solid_queue_jobs USING btree (active_job_id);


--
-- Name: index_solid_queue_jobs_on_class_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_class_name ON public.solid_queue_jobs USING btree (class_name);


--
-- Name: index_solid_queue_jobs_on_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_finished_at ON public.solid_queue_jobs USING btree (finished_at);


--
-- Name: index_solid_queue_pauses_on_queue_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_pauses_on_queue_name ON public.solid_queue_pauses USING btree (queue_name);


--
-- Name: index_solid_queue_poll_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_all ON public.solid_queue_ready_executions USING btree (priority, job_id);


--
-- Name: index_solid_queue_poll_by_queue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_by_queue ON public.solid_queue_ready_executions USING btree (queue_name, priority, job_id);


--
-- Name: index_solid_queue_processes_on_last_heartbeat_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_last_heartbeat_at ON public.solid_queue_processes USING btree (last_heartbeat_at);


--
-- Name: index_solid_queue_processes_on_name_and_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_processes_on_name_and_supervisor_id ON public.solid_queue_processes USING btree (name, supervisor_id);


--
-- Name: index_solid_queue_processes_on_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_supervisor_id ON public.solid_queue_processes USING btree (supervisor_id);


--
-- Name: index_solid_queue_ready_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_ready_executions_on_job_id ON public.solid_queue_ready_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_job_id ON public.solid_queue_recurring_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_task_key_and_run_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_task_key_and_run_at ON public.solid_queue_recurring_executions USING btree (task_key, run_at);


--
-- Name: index_solid_queue_recurring_tasks_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_tasks_on_key ON public.solid_queue_recurring_tasks USING btree (key);


--
-- Name: index_solid_queue_recurring_tasks_on_static; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_recurring_tasks_on_static ON public.solid_queue_recurring_tasks USING btree (static);


--
-- Name: index_solid_queue_scheduled_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_scheduled_executions_on_job_id ON public.solid_queue_scheduled_executions USING btree (job_id);


--
-- Name: index_solid_queue_semaphores_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_expires_at ON public.solid_queue_semaphores USING btree (expires_at);


--
-- Name: index_solid_queue_semaphores_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_semaphores_on_key ON public.solid_queue_semaphores USING btree (key);


--
-- Name: index_solid_queue_semaphores_on_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_key_and_value ON public.solid_queue_semaphores USING btree (key, value);


--
-- Name: index_tasks_on_assignee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_assignee_id ON public.tasks USING btree (assignee_id);


--
-- Name: index_tasks_on_assignee_id_and_due_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_assignee_id_and_due_date ON public.tasks USING btree (assignee_id, due_date);


--
-- Name: index_tasks_on_taskable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_taskable ON public.tasks USING btree (taskable_type, taskable_id);


--
-- Name: index_tasks_on_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_tenant_id ON public.tasks USING btree (tenant_id);


--
-- Name: index_tasks_watchers_on_task_id_and_watcher_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tasks_watchers_on_task_id_and_watcher_id ON public.tasks_watchers USING btree (task_id, watcher_id);


--
-- Name: index_tenants_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tenants_on_slug ON public.tenants USING btree (slug) WHERE ((slug)::text <> ''::text);


--
-- Name: tasks fk_rails_0016c50613; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT fk_rails_0016c50613 FOREIGN KEY (assignee_id) REFERENCES public.members(id);


--
-- Name: scorecards fk_rails_0668b92833; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scorecards
    ADD CONSTRAINT fk_rails_0668b92833 FOREIGN KEY (placement_id) REFERENCES public.placements(id);


--
-- Name: members fk_rails_0ef6c30e45; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT fk_rails_0ef6c30e45 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: location_aliases fk_rails_1d9daa974b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_aliases
    ADD CONSTRAINT fk_rails_1d9daa974b FOREIGN KEY (location_id) REFERENCES public.locations(id);


--
-- Name: candidates fk_rails_21931277a5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidates
    ADD CONSTRAINT fk_rails_21931277a5 FOREIGN KEY (candidate_source_id) REFERENCES public.candidate_sources(id);


--
-- Name: candidates fk_rails_2223471537; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidates
    ADD CONSTRAINT fk_rails_2223471537 FOREIGN KEY (location_id) REFERENCES public.locations(id);


--
-- Name: candidate_phones fk_rails_247c2f1f8c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_phones
    ADD CONSTRAINT fk_rails_247c2f1f8c FOREIGN KEY (created_by_id) REFERENCES public.members(id);


--
-- Name: positions_hiring_managers fk_rails_28b240935e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions_hiring_managers
    ADD CONSTRAINT fk_rails_28b240935e FOREIGN KEY (position_id) REFERENCES public.positions(id);


--
-- Name: positions fk_rails_2a3f3cea27; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT fk_rails_2a3f3cea27 FOREIGN KEY (recruiter_id) REFERENCES public.members(id);


--
-- Name: account_verification_keys fk_rails_2e3b612008; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_verification_keys
    ADD CONSTRAINT fk_rails_2e3b612008 FOREIGN KEY (id) REFERENCES public.accounts(id);


--
-- Name: solid_queue_recurring_executions fk_rails_318a5533ed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT fk_rails_318a5533ed FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: candidate_email_addresses fk_rails_3561be77a4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_email_addresses
    ADD CONSTRAINT fk_rails_3561be77a4 FOREIGN KEY (candidate_id) REFERENCES public.candidates(id);


--
-- Name: scorecards fk_rails_38df9f3585; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scorecards
    ADD CONSTRAINT fk_rails_38df9f3585 FOREIGN KEY (interviewer_id) REFERENCES public.members(id);


--
-- Name: solid_queue_failed_executions fk_rails_39bbc7a631; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT fk_rails_39bbc7a631 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: positions_interviewers fk_rails_4094d59edc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions_interviewers
    ADD CONSTRAINT fk_rails_4094d59edc FOREIGN KEY (position_id) REFERENCES public.positions(id);


--
-- Name: notes fk_rails_4a1d11a9b2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT fk_rails_4a1d11a9b2 FOREIGN KEY (note_thread_id) REFERENCES public.note_threads(id);


--
-- Name: solid_queue_blocked_executions fk_rails_4cd34e2228; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT fk_rails_4cd34e2228 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: notes fk_rails_556b0a09d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT fk_rails_556b0a09d2 FOREIGN KEY (member_id) REFERENCES public.members(id);


--
-- Name: positions_interviewers fk_rails_6879654d6e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions_interviewers
    ADD CONSTRAINT fk_rails_6879654d6e FOREIGN KEY (interviewer_id) REFERENCES public.members(id);


--
-- Name: placements fk_rails_7be786382b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.placements
    ADD CONSTRAINT fk_rails_7be786382b FOREIGN KEY (position_stage_id) REFERENCES public.position_stages(id);


--
-- Name: positions fk_rails_7c4f309ff7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT fk_rails_7c4f309ff7 FOREIGN KEY (location_id) REFERENCES public.locations(id);


--
-- Name: positions_collaborators fk_rails_7ef0cdb0c5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions_collaborators
    ADD CONSTRAINT fk_rails_7ef0cdb0c5 FOREIGN KEY (position_id) REFERENCES public.positions(id);


--
-- Name: access_tokens fk_rails_7f7e5b27bd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_tokens
    ADD CONSTRAINT fk_rails_7f7e5b27bd FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: positions_hiring_managers fk_rails_800fb5ba44; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions_hiring_managers
    ADD CONSTRAINT fk_rails_800fb5ba44 FOREIGN KEY (hiring_manager_id) REFERENCES public.members(id);


--
-- Name: scorecard_questions fk_rails_81cd2756c8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scorecard_questions
    ADD CONSTRAINT fk_rails_81cd2756c8 FOREIGN KEY (scorecard_id) REFERENCES public.scorecards(id);


--
-- Name: solid_queue_ready_executions fk_rails_81fcbd66af; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT fk_rails_81fcbd66af FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: tasks_watchers fk_rails_83d4da4da8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks_watchers
    ADD CONSTRAINT fk_rails_83d4da4da8 FOREIGN KEY (watcher_id) REFERENCES public.members(id);


--
-- Name: positions_collaborators fk_rails_8588910131; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions_collaborators
    ADD CONSTRAINT fk_rails_8588910131 FOREIGN KEY (collaborator_id) REFERENCES public.members(id);


--
-- Name: attachment_informations fk_rails_89a7cd7423; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachment_informations
    ADD CONSTRAINT fk_rails_89a7cd7423 FOREIGN KEY (active_storage_attachment_id) REFERENCES public.active_storage_attachments(id);


--
-- Name: candidate_alternative_names fk_rails_8aef3d4c1f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_alternative_names
    ADD CONSTRAINT fk_rails_8aef3d4c1f FOREIGN KEY (candidate_id) REFERENCES public.candidates(id);


--
-- Name: scorecard_templates fk_rails_8bda10f867; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scorecard_templates
    ADD CONSTRAINT fk_rails_8bda10f867 FOREIGN KEY (position_stage_id) REFERENCES public.position_stages(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: account_remember_keys fk_rails_9b2f6d8501; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_remember_keys
    ADD CONSTRAINT fk_rails_9b2f6d8501 FOREIGN KEY (id) REFERENCES public.accounts(id);


--
-- Name: solid_queue_claimed_executions fk_rails_9cfe4d4944; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT fk_rails_9cfe4d4944 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: tasks_watchers fk_rails_a5a37f1835; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks_watchers
    ADD CONSTRAINT fk_rails_a5a37f1835 FOREIGN KEY (task_id) REFERENCES public.tasks(id);


--
-- Name: candidate_links fk_rails_a5ebb9a55f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_links
    ADD CONSTRAINT fk_rails_a5ebb9a55f FOREIGN KEY (created_by_id) REFERENCES public.members(id);


--
-- Name: placements fk_rails_b301cc4475; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.placements
    ADD CONSTRAINT fk_rails_b301cc4475 FOREIGN KEY (position_id) REFERENCES public.positions(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: solid_queue_scheduled_executions fk_rails_c4316f352d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT fk_rails_c4316f352d FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: email_messages fk_rails_c79e1f5f48; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_messages
    ADD CONSTRAINT fk_rails_c79e1f5f48 FOREIGN KEY (email_thread_id) REFERENCES public.email_threads(id);


--
-- Name: placements fk_rails_caa177de79; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.placements
    ADD CONSTRAINT fk_rails_caa177de79 FOREIGN KEY (candidate_id) REFERENCES public.candidates(id);


--
-- Name: account_password_reset_keys fk_rails_ccaeb37cea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_password_reset_keys
    ADD CONSTRAINT fk_rails_ccaeb37cea FOREIGN KEY (id) REFERENCES public.accounts(id);


--
-- Name: placements fk_rails_cdf26a9eb3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.placements
    ADD CONSTRAINT fk_rails_cdf26a9eb3 FOREIGN KEY (disqualify_reason_id) REFERENCES public.disqualify_reasons(id);


--
-- Name: candidate_phones fk_rails_cfcc7aa34d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_phones
    ADD CONSTRAINT fk_rails_cfcc7aa34d FOREIGN KEY (candidate_id) REFERENCES public.candidates(id);


--
-- Name: location_hierarchies fk_rails_d680d5b704; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_hierarchies
    ADD CONSTRAINT fk_rails_d680d5b704 FOREIGN KEY (location_id) REFERENCES public.locations(id);


--
-- Name: scorecard_template_questions fk_rails_e373b6a964; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scorecard_template_questions
    ADD CONSTRAINT fk_rails_e373b6a964 FOREIGN KEY (scorecard_template_id) REFERENCES public.scorecard_templates(id);


--
-- Name: events fk_rails_ea3c6e6353; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT fk_rails_ea3c6e6353 FOREIGN KEY (actor_account_id) REFERENCES public.accounts(id);


--
-- Name: location_hierarchies fk_rails_eb4e848cce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_hierarchies
    ADD CONSTRAINT fk_rails_eb4e848cce FOREIGN KEY (parent_location_id) REFERENCES public.locations(id);


--
-- Name: position_stages fk_rails_f5fbacf194; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.position_stages
    ADD CONSTRAINT fk_rails_f5fbacf194 FOREIGN KEY (position_id) REFERENCES public.positions(id);


--
-- Name: candidate_email_addresses fk_rails_fd26989a5d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_email_addresses
    ADD CONSTRAINT fk_rails_fd26989a5d FOREIGN KEY (created_by_id) REFERENCES public.members(id);


--
-- Name: candidate_links fk_rails_ff2d75d07e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_links
    ADD CONSTRAINT fk_rails_ff2d75d07e FOREIGN KEY (candidate_id) REFERENCES public.candidates(id);


--
-- Name: scorecards fk_rails_ffb1a0c157; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scorecards
    ADD CONSTRAINT fk_rails_ffb1a0c157 FOREIGN KEY (position_stage_id) REFERENCES public.position_stages(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20241203142925'),
('20241202095447'),
('20241129084054'),
('20241107081744'),
('20241105130512'),
('20241102110106'),
('20241028124325'),
('20241024082345'),
('20241024082312'),
('20241018104859'),
('20241018092829'),
('20241018063719'),
('20241017110924'),
('20241017101832'),
('20241015130853'),
('20241015130852'),
('20241015130851'),
('20241015130608'),
('20241015125238'),
('20241015101251'),
('20241015101237'),
('20241014103851'),
('20241011094049'),
('20241010123414'),
('20241008103850'),
('20241001104238'),
('20240930100900'),
('20240926063106'),
('20240926040800'),
('20240924153311'),
('20240924153030'),
('20240923151001'),
('20240920135234'),
('20240919035839'),
('20240918105348'),
('20240917131723'),
('20240916132738'),
('20240913152510'),
('20240912084504'),
('20240911061747'),
('20240911051822'),
('20240909141257'),
('20240909131121'),
('20240904072749'),
('20240904065325'),
('20240904061514'),
('20240902071234'),
('20240902064755'),
('20240902063330'),
('20240902055934'),
('20240602141417'),
('20240602141416'),
('20240602141415'),
('20240506091416'),
('20240504075807'),
('20240502094848'),
('20240501080828'),
('20240501075335'),
('20240426071136'),
('20240425094431'),
('20240425091511'),
('20240423033545'),
('20240423022713'),
('20240422114747'),
('20240419091633'),
('20240418121526'),
('20240418070256'),
('20240417151916'),
('20240416104851'),
('20240416053719'),
('20240415091326'),
('20240415070643'),
('20240411061423'),
('20240410042127'),
('20240409052033'),
('20240405103259'),
('20240404155739'),
('20240404153834'),
('20240404145104'),
('20240404084025'),
('20240403070728'),
('20240328064406'),
('20240327132812'),
('20240327104934'),
('20240327062244'),
('20240327060244'),
('20240326102218'),
('20240326084615'),
('20240326081427'),
('20240325141539'),
('20240325063100'),
('20240322085731'),
('20240322055152'),
('20240322040604'),
('20240321160130'),
('20240321153228'),
('20240321153227'),
('20240321063622'),
('20240319154220'),
('20240318112738'),
('20240318083527'),
('20240318051606'),
('20240318045509'),
('20240318034734'),
('20240318030310'),
('20240315150905'),
('20240315094556'),
('20240314143743'),
('20240314085122'),
('20240314080741'),
('20240313143106'),
('20240313122316'),
('20240312134726'),
('20240312105257'),
('20240307081926'),
('20240307081337'),
('20240306075855'),
('20240306075854'),
('20240306073844');

