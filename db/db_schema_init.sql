
CREATE SEQUENCE public.background_sets_id_seq;

CREATE TABLE public.Background_sets (
                Id INTEGER NOT NULL DEFAULT nextval('public.background_sets_id_seq'),
                Label VARCHAR NOT NULL,
                Description VARCHAR NOT NULL,
                Count INTEGER NOT NULL,
                CONSTRAINT background_sets_pk PRIMARY KEY (Id)
);


ALTER SEQUENCE public.background_sets_id_seq OWNED BY public.Background_sets.Id;

CREATE SEQUENCE public.annotation_description_id_seq;

CREATE TABLE public.Annotation_description (
                Id INTEGER NOT NULL DEFAULT nextval('public.annotation_description_id_seq'),
                Label VARCHAR NOT NULL,
                Description VARCHAR,
                Type VARCHAR NOT NULL,
                CONSTRAINT id PRIMARY KEY (Id)
);


ALTER SEQUENCE public.annotation_description_id_seq OWNED BY public.Annotation_description.Id;

CREATE SEQUENCE public.annotation_id_seq;

CREATE TABLE public.Annotation (
                Id INTEGER NOT NULL DEFAULT nextval('public.annotation_id_seq'),
                Label VARCHAR NOT NULL,
                Description VARCHAR,
                Annotation_description_id INTEGER NOT NULL,
                CONSTRAINT annotation_id_idx PRIMARY KEY (Id)
);


ALTER SEQUENCE public.annotation_id_seq OWNED BY public.Annotation.Id;

CREATE UNIQUE INDEX annotation_description_id_idx
 ON public.Annotation
 ( Annotation_description_id, Label );

CLUSTER annotation_description_id_idx ON Annotation;

CREATE TABLE public.Ann2Back_set (
                Back_set_id INTEGER NOT NULL,
                Ann_id INTEGER NOT NULL,
                Count INTEGER NOT NULL,
                CONSTRAINT ann2back_set_pk PRIMARY KEY (Back_set_id, Ann_id)
);


CREATE INDEX ann2back_set_idx
 ON public.Ann2Back_set
 ( Count ASC, Back_set_id );

CLUSTER ann2back_set_idx ON Ann2Back_set;

CREATE SEQUENCE public.variation_id_seq;

CREATE TABLE public.Variation (
                Id INTEGER NOT NULL DEFAULT nextval('public.variation_id_seq'),
                Name VARCHAR NOT NULL,
                Strand VARCHAR NOT NULL,
                Position INTEGER NOT NULL,
                Allele VARCHAR NOT NULL,
                Chr VARCHAR NOT NULL,
                CONSTRAINT variation_id_idx PRIMARY KEY (Id)
);


ALTER SEQUENCE public.variation_id_seq OWNED BY public.Variation.Id;

CREATE UNIQUE INDEX variation_name_idx
 ON public.Variation
 ( Name );

CLUSTER variation_name_idx ON Variation ;

CREATE INDEX variation_loci_idx
 ON public.Variation
 ( Chr, Position ASC );

CREATE TABLE public.Var2Back_set (
                Back_set_id INTEGER NOT NULL,
                Var_id INTEGER NOT NULL,
                CONSTRAINT var2back_set_pk PRIMARY KEY (Back_set_id, Var_id)
);


CREATE TABLE public.Var2Ann (
                Var_id INTEGER NOT NULL,
                Ann_id INTEGER NOT NULL,
                CONSTRAINT var_id_ann_id PRIMARY KEY (Var_id, Ann_id)
);


ALTER TABLE public.Ann2Back_set ADD CONSTRAINT background_sets_ann2back_set_fk
FOREIGN KEY (Back_set_id)
REFERENCES public.Background_sets (Id)
ON DELETE CASCADE
ON UPDATE CASCADE
NOT DEFERRABLE;

ALTER TABLE public.Var2Back_set ADD CONSTRAINT background_sets_var2back_set_fk
FOREIGN KEY (Back_set_id)
REFERENCES public.Background_sets (Id)
ON DELETE CASCADE
ON UPDATE CASCADE
NOT DEFERRABLE;

ALTER TABLE public.Annotation ADD CONSTRAINT annotation_description_annotation_fk
FOREIGN KEY (Annotation_description_id)
REFERENCES public.Annotation_description (Id)
ON DELETE CASCADE
ON UPDATE CASCADE
NOT DEFERRABLE;

ALTER TABLE public.Var2Ann ADD CONSTRAINT annotation_var2ann_fk
FOREIGN KEY (Ann_id)
REFERENCES public.Annotation (Id)
ON DELETE CASCADE
ON UPDATE CASCADE
NOT DEFERRABLE;

ALTER TABLE public.Ann2Back_set ADD CONSTRAINT annotation_ann2back_set_fk
FOREIGN KEY (Ann_id)
REFERENCES public.Annotation (Id)
ON DELETE CASCADE
ON UPDATE CASCADE
NOT DEFERRABLE;

ALTER TABLE public.Var2Ann ADD CONSTRAINT variation_var2ann_fk
FOREIGN KEY (Var_id)
REFERENCES public.Variation (Id)
ON DELETE CASCADE
ON UPDATE CASCADE
NOT DEFERRABLE;

ALTER TABLE public.Var2Back_set ADD CONSTRAINT variation_var2back_set_fk
FOREIGN KEY (Var_id)
REFERENCES public.Variation (Id)
ON DELETE CASCADE
ON UPDATE CASCADE
NOT DEFERRABLE;
