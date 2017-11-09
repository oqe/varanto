'''
Created on Mar 20, 2015

@author: tiborf
'''

import csv
import genes_annotations_to_db;
import get_evidence_annotations;
from annotation import Annotation
from annotations_descriptions import AnnDescriptions
from common_alleles import CommonAlleles

class Labels(object):
    '''
    classdocs
    '''


    def __init__(self, headers, back_sets_ids, ann_desc_file, genes_annotations_file, get_evidence_file, top_alleles_count, msigdb_files,
                 msigdb_not_found_hgnc):
        '''
        Constructor
        '''
        #current annotation id
        self.annotation_id_cnt = 0
        #dictionary annotation->id
        self.map_ann2id = {}
        #initialize annnotations description file
        self.ann_descriptions = AnnDescriptions(ann_desc_file)
        #initialize gene annotations
        self.genes_ann = genes_annotations_to_db.GenesDbImport(genes_annotations_file, msigdb_files, msigdb_not_found_hgnc)        
        #initialize variation get-evidence annotations   
        self.get_evidence = get_evidence_annotations.GetEvidenceDbImport(get_evidence_file)
        #initialize counts of annotations in each background set
        self.id2counts = {}
        #store back sets ids
        self.back_sets_ids = back_sets_ids
        #current variant id
        self.current_variant_id = None
        #headers in variation annotation file
        self.headers = headers
        #initialize top alleles count
        self.top_alleles_count = top_alleles_count
        #initialize common_allese
        self.common_alleles = CommonAlleles()    
            
    
    def process_variation_row(self, variant_id, var_is_in_back_sets, row, annotations_csv, var2ann_csv):
        #check if it is another variation or if it is same like in the previous call
        if self.current_variant_id != variant_id:
            self.current_variant_id = variant_id
            #initialize set of annotation ids already found for this variation        
            self.variation_annotations_ids = set()
            #initialize set of processed genes
            self.processed_genes = set()
            #process get-evidence annotations for variation
            for i in self.get_evidence.get_get_evidence_annotations(row[0]):
                self.process_annotation_of_current_variant(i, var_is_in_back_sets, annotations_csv, var2ann_csv)
            #insert allele to common_alleles
            self.common_alleles.insert_variation(self.current_variant_id, row[1], var_is_in_back_sets)
        
        #process row
        for j in [1] + [j for j in range(5,len(self.headers))]:
            #only non-empty columns
            if len(row[j]) == 0:
                continue
            self.process_annotation_of_current_variant((self.headers[j], row[j], '', 'var'), var_is_in_back_sets, annotations_csv, var2ann_csv)
            if (j == 9):
                #process associated gene annotations if it is not already done
                if not row[9] in self.processed_genes:
                    self.processed_genes.add(row[9])                 
                    for i in self.genes_ann.get_gene_annotations(row[9]):
                        self.process_annotation_of_current_variant(i, var_is_in_back_sets, annotations_csv, var2ann_csv)
                            
        
    def process_annotation_of_current_variant(self, ann, var_is_in_back_sets, annotations_csv, var2ann_csv):        
        #write annotation
        current_annotation_id = self.write_annotation(ann, annotations_csv)        
        #check if this association is not already written (some annotations can be recorded in 
        #more lines of same snp)
        if not current_annotation_id in self.variation_annotations_ids:
            self.variation_annotations_ids.add(current_annotation_id)
            self.write_var2ann_row(self.current_variant_id, current_annotation_id, var_is_in_back_sets, var2ann_csv)
    
    def process_annotation(self, current_variant_id, ann, var_is_in_back_sets, annotations_csv, var2ann_csv):
        #write annotation
        current_annotation_id = self.write_annotation(ann, annotations_csv)
        #write var2ann row
        self.write_var2ann_row(current_variant_id, current_annotation_id, var_is_in_back_sets, var2ann_csv)            
    
    def write_annotation(self, ann, annotations_csv):
        unique_tuple = (ann[0], ann[1], ann[3]) #description have not to be there        
        #check if annotation is already in dictionary
        if unique_tuple in self.map_ann2id:                        
            #assign current annotation id and increment count of this label
            return self.map_ann2id[unique_tuple]                        
        else:
            ann_info = Annotation(ann[0],ann[1],ann[2],ann[3])                                          
            #add new annotation to dictionary and write row with annotation            
            self.annotation_id_cnt += 1
            current_annotation_id = self.annotation_id_cnt
            self.map_ann2id[unique_tuple] = current_annotation_id                    
            self.id2counts[current_annotation_id] = {}
            for i in self.back_sets_ids:
                self.id2counts[current_annotation_id][i] = 0
            ann_desc_id = self.ann_descriptions.get_annotation_description(ann_info.attribute, ann_info.var_gene)
            annotations_csv.writerow([current_annotation_id, ann_info.label, ann_info.description.replace('\\','\\\\'), ann_desc_id])
            return current_annotation_id
    
    def write_var2ann_row(self, current_variant_id, current_annotation_id, var_is_in_back_sets, var2ann_csv):
        #write relationship to output file
        var2ann_csv.writerow([current_variant_id, current_annotation_id])
        #increment counts for this annotation in background sets
        for i in var_is_in_back_sets:
            #increment for background set with label of new_back_sets_desc[i][2]
            self.id2counts[current_annotation_id][i] += 1    
        
    
    #process annotations dependent on the data gained by processing of all variation rows (top alleles)
    def process_additional_annotation(self, annotations_csv, var2ann_csv):
        #sort counts of alleles, choose common alleles and process them as separate attribute with limited number of alleles
        for i in self.common_alleles.get_common_alleles(self.top_alleles_count):
            self.process_annotation(i[0], i[1], i[2], annotations_csv, var2ann_csv)        
    
    def write_annotation_counts(self, table_ann2back_set_file):
        with open(table_ann2back_set_file,'w') as ann2back:
            writer = csv.writer(ann2back, delimiter='\t')
            for i in self.id2counts:
                for j in self.id2counts[i]:
                    writer.writerow([j, i, self.id2counts[i][j]])
        
        