-- Table: northgate.parks_lens

-- DROP TABLE IF EXISTS northgate.parks_lens;

CREATE TABLE IF NOT EXISTS northgate.parks_lens
(
    id integer NOT NULL DEFAULT nextval('parks_lens_id_seq'::regclass),
    name character varying COLLATE pg_catalog."default" NOT NULL,
    miny double precision NOT NULL,
    minx double precision NOT NULL,
    maxy double precision NOT NULL,
    maxx double precision NOT NULL,
    geometry geometry,
    geo_lens character varying COLLATE pg_catalog."default",
    CONSTRAINT parks_lens_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS northgate.parks_lens
    OWNER to olgapshen;

GRANT ALL ON TABLE northgate.parks_lens TO lvapl WITH GRANT OPTION;

GRANT ALL ON TABLE northgate.parks_lens TO malaxov16 WITH GRANT OPTION;

GRANT ALL ON TABLE northgate.parks_lens TO marwin887 WITH GRANT OPTION;

GRANT ALL ON TABLE northgate.parks_lens TO olgapshen;

GRANT ALL ON TABLE northgate.parks_lens TO sshiae WITH GRANT OPTION;
