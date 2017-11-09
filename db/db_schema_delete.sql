ALTER TABLE public.Var2Ann DROP CONSTRAINT variation_var2ann_fk;
ALTER TABLE public.Var2Ann DROP CONSTRAINT annotation_var2ann_fk;
ALTER TABLE public.Annotation DROP CONSTRAINT annotation_description_annotation_fk;
ALTER TABLE public.Ann2Back_set DROP CONSTRAINT annotation_ann2back_set_fk;
ALTER TABLE public.Ann2Back_set DROP CONSTRAINT background_sets_ann2back_set_fk;
ALTER TABLE public.Var2Back_set DROP CONSTRAINT background_sets_var2back_set_fk;
ALTER TABLE public.Var2Back_set DROP CONSTRAINT variation_var2back_set_fk;
DROP TABLE public.Var2Ann;
DROP INDEX variation_name_idx;
DROP INDEX variation_loci_idx;
DROP TABLE public.Variation;
DROP INDEX ann2back_set_idx;
DROP TABLE public.Ann2Back_set;
DROP TABLE public.Background_sets;
DROP INDEX annotation_description_id_idx;
DROP TABLE public.Annotation;
DROP TABLE public.Annotation_description;
DROP TABLE public.Var2Back_set








