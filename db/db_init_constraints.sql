ALTER TABLE public.background_sets ADD CONSTRAINT background_sets_pk PRIMARY KEY (id) WITH (fillfactor = 100);
CLUSTER background_sets_pk ON background_sets;
ALTER SEQUENCE public.background_sets_id_seq INCREMENT BY :back_set_cnt;

ALTER TABLE public.annotation_description ADD CONSTRAINT id PRIMARY KEY (id) WITH (fillfactor = 100);
CLUSTER id ON annotation_description;
ALTER SEQUENCE public.annotation_description_id_seq INCREMENT BY :ann_desc_cnt;

ALTER TABLE public.annotation ADD CONSTRAINT annotation_id_idx PRIMARY KEY (id) WITH (fillfactor = 100);
ALTER SEQUENCE public.annotation_id_seq INCREMENT BY :ann_cnt;
CREATE UNIQUE INDEX annotation_description_id_idx
 ON public.Annotation
 ( Annotation_description_id, Label ) WITH (fillfactor = 100);
CLUSTER annotation_description_id_idx ON Annotation;

ALTER TABLE public.ann2back_set ADD CONSTRAINT ann2back_set_pk PRIMARY KEY(back_set_id, ann_id) WITH (fillfactor = 100);
CREATE INDEX ann2back_set_idx
 ON public.Ann2Back_set
 ( Count ASC, Back_set_id ) WITH (fillfactor = 100);
CLUSTER ann2back_set_idx ON Ann2Back_set;

ALTER TABLE public.variation ADD CONSTRAINT variation_id_idx PRIMARY KEY (id) WITH (fillfactor = 100);
ALTER SEQUENCE public.variation_id_seq INCREMENT BY :var_cnt;
CREATE UNIQUE INDEX variation_name_idx
 ON public.Variation
 ( Name ) WITH (fillfactor = 100);
CLUSTER variation_name_idx ON Variation ;
CREATE INDEX variation_loci_idx
 ON public.Variation
 ( Chr, Position ASC ) WITH (fillfactor = 100);

ALTER TABLE public.var2back_set ADD CONSTRAINT var2back_set_pk PRIMARY KEY(back_set_id, var_id) WITH (fillfactor = 100);

ALTER TABLE public.var2ann ADD CONSTRAINT var_id_ann_id PRIMARY KEY (var_id, ann_id) WITH (fillfactor = 100);

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

