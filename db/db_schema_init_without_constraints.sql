
CREATE SEQUENCE public.background_sets_id_seq;

CREATE TABLE public.Background_sets (
                Id INTEGER NOT NULL DEFAULT nextval('public.background_sets_id_seq'),
                Label VARCHAR NOT NULL,
                Description VARCHAR NOT NULL,
                Count INTEGER NOT NULL                
);


ALTER SEQUENCE public.background_sets_id_seq OWNED BY public.Background_sets.Id;

CREATE SEQUENCE public.annotation_description_id_seq;

CREATE TABLE public.Annotation_description (
                Id INTEGER NOT NULL DEFAULT nextval('public.annotation_description_id_seq'),
                Label VARCHAR NOT NULL,
                Description VARCHAR,
                Type VARCHAR NOT NULL                
);


ALTER SEQUENCE public.annotation_description_id_seq OWNED BY public.Annotation_description.Id;

CREATE SEQUENCE public.annotation_id_seq;

CREATE TABLE public.Annotation (
                Id INTEGER NOT NULL DEFAULT nextval('public.annotation_id_seq'),
                Label VARCHAR NOT NULL,
                Description VARCHAR,
                Annotation_description_id INTEGER NOT NULL                
);


ALTER SEQUENCE public.annotation_id_seq OWNED BY public.Annotation.Id;

CREATE TABLE public.Ann2Back_set (
                Back_set_id INTEGER NOT NULL,
                Ann_id INTEGER NOT NULL,
                Count INTEGER NOT NULL
);

CREATE SEQUENCE public.variation_id_seq;

CREATE TABLE public.Variation (
                Id INTEGER NOT NULL DEFAULT nextval('public.variation_id_seq'),
                Name VARCHAR NOT NULL,
                Strand VARCHAR NOT NULL,
                Position INTEGER NOT NULL,
                Allele VARCHAR NOT NULL,
                Chr VARCHAR NOT NULL                
);


ALTER SEQUENCE public.variation_id_seq OWNED BY public.Variation.Id;

CREATE TABLE public.Var2Back_set (
                Back_set_id INTEGER NOT NULL,
                Var_id INTEGER NOT NULL
);


CREATE TABLE public.Var2Ann (
                Var_id INTEGER NOT NULL,
                Ann_id INTEGER NOT NULL
);


