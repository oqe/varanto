# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

__author__="tiborf"
__date__ ="$Dec 4, 2014 11:16:51 AM$"

import csv

class GenesDbImport:    
    
    def __init__(self, annotated_genes, msigdb_files, msigdb_not_found_hgnc):
        self.genes = {}
        #process data from ensembl and create dictionary hgnc_symbol->ensembl_gene_id
        hgnc2ensembl = {}
        with open(annotated_genes) as input_file:
            reader = csv.reader(input_file, delimiter='\t')            
            headers=["ensembl_gene_id", "go_id", "name_1006", "definition_1006", "hgnc_symbol", "gene_biotype", 
                "phenotype_description"]#, "mim_morbid_description"]            
            for row in reader:                
                current_gene = row[0]
                if not current_gene in self.genes:
                    self.genes[current_gene] = set()
                for j in range(1, len(headers)):
                    #skip empty cells and descriptions columns for go_id
                    if len(row[j]) == 0 or j == 2 or j == 3:
                        continue
                    if j == 1:                        
                        #include description to go_id
                        self.genes[current_gene].add((headers[j], row[j], row[j+1] + "_" + row[j+2], 'gene'))
                    else:                        
                        self.genes[current_gene].add((headers[j], row[j],'','gene'))
                    if (j == 4):
                        #insert record to hgnc->ensembl dictionary
                        if not row[4] in hgnc2ensembl:
                            hgnc2ensembl[row[4]] = set()
                        hgnc2ensembl[row[4]].add(current_gene)                            
        
        #process data from MSigDB Collections
        not_found_hgnc = {}        
        with open(msigdb_files, 'r') as files_and_headers:
            #open list of files and header of collections
            reader = csv.reader(files_and_headers, delimiter='\t')
            for row in reader:
                #open collection file                            
                with open(row[0], 'r') as ann_file:
                    reader_ann = csv.reader(ann_file, delimiter='\t')
                    for row_ann in reader_ann:
                        #add annotation to genes
                        for i in range(2, len(row_ann)):
                            hgnc_symbol = row_ann[i]
                            if not hgnc_symbol in hgnc2ensembl:
                                #print("Warning: HGNC symbol without paired Ensembl ID found. Ignoring this gene. (" + hgnc_symbol + ")")
                                if not hgnc_symbol in not_found_hgnc:
                                    not_found_hgnc[hgnc_symbol] = 0
                                not_found_hgnc[hgnc_symbol] += 1                                    
                                continue
                            for ensembl_id in hgnc2ensembl[hgnc_symbol]:
                                if ensembl_id in self.genes:                                    
                                    self.genes[ensembl_id].add((row[1], row_ann[0], 
                                                                '<a target="_blank" href="' + row_ann[1] + '">' + row_ann[1] + '</a>', 'gene'))
                                else:
                                    print("Error: HGNC symbol with incorrect Ensembl Gene ID. Ignoring this gene. (" + hgnc_symbol + ", " + ensembl_id + ")")
        
        with open(msigdb_not_found_hgnc, 'w') as not_found_hgnc_file:
            for i in not_found_hgnc:
                print(i + " (" + str(not_found_hgnc[i]) + ")", file = not_found_hgnc_file)
        

    def get_gene_annotations(self, ensembl_gene_id):
        if ensembl_gene_id != 'ENSG00000204217': #error ensembl id because of error go identifier        
            if ensembl_gene_id in self.genes:            
                for i in self.genes[ensembl_gene_id]:
                    yield i        

if __name__ == "__main__":
    print("genes_data module")
