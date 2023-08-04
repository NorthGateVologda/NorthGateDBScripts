-- Table: northgate.polygons_lens

-- DROP TABLE IF EXISTS northgate.polygons_lens;

CREATE TABLE IF NOT EXISTS northgate.polygons_lens
(
    id integer NOT NULL DEFAULT nextval('polygons_lens_id_seq'::regclass),
    geometry_lens character varying COLLATE pg_catalog."default" NOT NULL,
    geometry geometry(Polygon,4326),
    CONSTRAINT polygons_lens_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS northgate.polygons_lens
    OWNER to olgapshen;

GRANT ALL ON TABLE northgate.polygons_lens TO lvapl WITH GRANT OPTION;

GRANT ALL ON TABLE northgate.polygons_lens TO malaxov16 WITH GRANT OPTION;

GRANT ALL ON TABLE northgate.polygons_lens TO marwin887 WITH GRANT OPTION;

GRANT ALL ON TABLE northgate.polygons_lens TO olgapshen;

GRANT ALL ON TABLE northgate.polygons_lens TO sshiae WITH GRANT OPTION;
