#! /usr/local/bin/python3
__author__="tiborf"
__date__ ="$Nov 21, 2014 10:27:36 AM$"

from datetime import datetime
import csv
import sys
from params import Params;
from background_sets import BackgroundSets
from labels import Labels

def main():
    if len(sys.argv) != 17:        
        print("USAGE: ./prepare_table_files.py table_var_file table_ann_file table_var2ann_file table_ann_desc_file table_back_set_file " +
              "table_ann2back_set_file table_var2back_set_file tables_row_counts_file MSigDB_files MSigDB_not_found_HGNC_file" +
              "var_annotations_file genes_annotations_file get_evidence_file back_set_not_counted_file back_sets_folder top_alleles")
        print("Use varanto_import.sh and varanto_import.conf for easier setting of parameters.")
        sys.exit(-1)
    
    params = Params(sys.argv)
        
    print("Generating input data files...")
    start = datetime.now()
    
    #initialize counters of annotations in background lists and load background set description file
    print("* Loading and counting variations from background sets files...")    
    back_sets = BackgroundSets(params.back_set_not_counted_file, params.back_sets_folder)                
    print("* Loading and counting variations from background sets files completed at " + str(datetime.now() - start))
    
    headers=["refsnp_id", "allele", "chr_name", "chrom_start", "chrom_strand", "phenotype_description", 
            "study_external_ref", "study_description", "consequence_type_tv", "ensembl_gene_stable_id", 
            "associated_gene", "polyphen_prediction", "sift_prediction"]    
    
    #initialize labels
    print("* Loading data for annotation processing...")
    labels = Labels(headers, back_sets.get_back_sets_ids(), params.table_ann_desc_file, 
                    params.genes_annotations_file, params.get_evidence_file, params.top_alleles, params.msigdb_files,
                    params.msigdb_not_found_hgnc)
    print("* Loading data for annotation processing completed at " + str(datetime.now() - start))
        
    #open annotated snps file
    with open(params.var_annotations_file,'r', encoding='latin-1') as input_var, open(
        params.table_var_file, 'w') as variations_output, open(
        params.table_ann_file, 'w') as annotations_output, open(
        params.table_var2ann_file,'w') as var2ann_output, open(
        params.table_var2back_set_file,'w') as var2back_set_output:    
                       
        #initialize csv reader and writers
        reader = csv.reader(input_var, delimiter='\t')
        variations_csv = csv.writer(variations_output, delimiter='\t')
        annotations_csv = csv.writer(annotations_output, delimiter='\t', quoting=csv.QUOTE_NONE, escapechar='\\')
        var2ann_csv = csv.writer(var2ann_output, delimiter='\t')
        var2back_set_csv = csv.writer(var2back_set_output, delimiter='\t')
                
        #current name of variant and status of change
        current_variant = None        
        #current id of variant
        variation_id_cnt = 0        
        #for outputting progress
        last_time = datetime.now()
        rows_processed = 0                    
        #process each file
        for row in reader:
            #check if it is another snp than snp in the previous line
            if row[0] != current_variant:
                #check if it is variant in standard track (according to chromosome name)
                if not row[2] in ["1","2","3","4","5","6","7","8","9","10","11","12","13",
                    "14","15","16","17","18","19","20","21","22","MT","X","Y"]:
                    continue
                #add row in variations csv
                current_variant = row[0]
                variation_id_cnt += 1
                #write variation
                variations_csv.writerow([variation_id_cnt,row[0],row[4],row[3],row[1],row[2]])
                #list of background sets ids which contain variation
                var_is_in_back_sets = back_sets.process_variant(current_variant, variation_id_cnt, var2back_set_csv)                
                                    
            labels.process_variation_row(variation_id_cnt, var_is_in_back_sets, row, annotations_csv, var2ann_csv)
            
            rows_processed += 1
            
            if rows_processed % 10000 == 0:
                sys.stdout.write("\rLines processed: %d, time of processing last 10000 rows: " % rows_processed)                
                sys.stdout.write(str(datetime.now() - last_time))                
                sys.stdout.flush()            
                last_time = datetime.now()
        
        #process annotations dependent on the data gained by processing of all variation rows (top alleles)
        labels.process_additional_annotation(annotations_csv, var2ann_csv)

        sys.stdout.write("\n")
    
    #write to file descriptions of background sets with counted variations
    back_sets.write_table_back_sets_file(variation_id_cnt, params.table_back_set_file)
    
    #write associations between annotations and their counts in all background sets
    labels.write_annotation_counts(params.table_ann2back_set_file)
    
    #write counts of rows for db tables with primary keys sequences to increment them.
    with open(params.tables_row_counts_file, 'w') as out:
        writer = csv.writer(out, delimiter='\t')
        writer.writerow([variation_id_cnt, labels.annotation_id_cnt, 
              labels.ann_descriptions.id_count(), len(back_sets.get_back_sets_ids())])            
    
    print("Generating input files completed in " + str(datetime.now() - start))        
            
if __name__ == "__main__":
    main()
