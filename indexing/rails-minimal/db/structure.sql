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
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET default_tablespace = '';

SET default_table_access_method = heap;

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
-- Name: companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.companies (
    id bigint NOT NULL,
    name character varying,
    symbol character varying,
    exchange character varying,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    searchable tsvector GENERATED ALWAYS AS ((setweight(to_tsvector('english'::regconfig, (COALESCE(name, ''::character varying))::text), 'A'::"char") || setweight(to_tsvector('english'::regconfig, COALESCE(description, ''::text)), 'B'::"char"))) STORED
);


--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.companies_id_seq OWNED BY public.companies.id;


--
-- Name: gin_indexed_companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gin_indexed_companies (
    id bigint NOT NULL,
    exchange character varying NOT NULL,
    symbol character varying NOT NULL,
    name character varying NOT NULL,
    description text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: gin_indexed_companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gin_indexed_companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gin_indexed_companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gin_indexed_companies_id_seq OWNED BY public.gin_indexed_companies.id;


--
-- Name: indexed_companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.indexed_companies (
    id bigint NOT NULL,
    exchange character varying NOT NULL,
    symbol character varying NOT NULL,
    name character varying NOT NULL,
    description text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: indexed_companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.indexed_companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: indexed_companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.indexed_companies_id_seq OWNED BY public.indexed_companies.id;


--
-- Name: partial_indexed_companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.partial_indexed_companies (
    id bigint NOT NULL,
    exchange character varying NOT NULL,
    symbol character varying NOT NULL,
    name character varying NOT NULL,
    description text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: partial_indexed_companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.partial_indexed_companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: partial_indexed_companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.partial_indexed_companies_id_seq OWNED BY public.partial_indexed_companies.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: unindexed_companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.unindexed_companies (
    id bigint NOT NULL,
    exchange character varying NOT NULL,
    symbol character varying NOT NULL,
    name character varying NOT NULL,
    description text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: unindexed_companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.unindexed_companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: unindexed_companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.unindexed_companies_id_seq OWNED BY public.unindexed_companies.id;


--
-- Name: companies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies ALTER COLUMN id SET DEFAULT nextval('public.companies_id_seq'::regclass);


--
-- Name: gin_indexed_companies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gin_indexed_companies ALTER COLUMN id SET DEFAULT nextval('public.gin_indexed_companies_id_seq'::regclass);


--
-- Name: indexed_companies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indexed_companies ALTER COLUMN id SET DEFAULT nextval('public.indexed_companies_id_seq'::regclass);


--
-- Name: partial_indexed_companies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partial_indexed_companies ALTER COLUMN id SET DEFAULT nextval('public.partial_indexed_companies_id_seq'::regclass);


--
-- Name: unindexed_companies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unindexed_companies ALTER COLUMN id SET DEFAULT nextval('public.unindexed_companies_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: gin_indexed_companies gin_indexed_companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gin_indexed_companies
    ADD CONSTRAINT gin_indexed_companies_pkey PRIMARY KEY (id);


--
-- Name: indexed_companies indexed_companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indexed_companies
    ADD CONSTRAINT indexed_companies_pkey PRIMARY KEY (id);


--
-- Name: partial_indexed_companies partial_indexed_companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partial_indexed_companies
    ADD CONSTRAINT partial_indexed_companies_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: unindexed_companies unindexed_companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unindexed_companies
    ADD CONSTRAINT unindexed_companies_pkey PRIMARY KEY (id);


--
-- Name: index_indexed_companies_on_exchange_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_indexed_companies_on_exchange_symbol ON public.indexed_companies USING btree (exchange, symbol);


--
-- Name: index_indexed_companies_on_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_indexed_companies_on_symbol ON public.indexed_companies USING btree (symbol);


--
-- Name: index_on_exchange_and_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_on_exchange_and_symbol ON public.partial_indexed_companies USING btree (exchange, symbol) WHERE ((symbol)::text <= 'E'::text);


--
-- Name: index_on_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_on_name_trgm ON public.gin_indexed_companies USING gin (name public.gin_trgm_ops);


--
-- Name: index_on_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_on_symbol ON public.partial_indexed_companies USING btree (symbol) WHERE ((symbol)::text <= 'E'::text);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20240504074651'),
('20240504050321');

