'''
Created on Mar 20, 2015

@author: tiborf
'''

class Params(object):
    '''
    classdocs
    '''
    

    def __init__(self, params):
        '''
        Constructor
        '''
        self.table_var_file = params[1]
        self.table_ann_file = params[2]
        self.table_var2ann_file = params[3]
        self.table_ann_desc_file = params[4]
        self.table_back_set_file = params[5]
        self.table_ann2back_set_file = params[6]
        self.table_var2back_set_file = params[7]
        self.tables_row_counts_file = params[8]
        self.var_annotations_file = params[9]
        self.genes_annotations_file = params[10]
        self.get_evidence_file = params[11]
        self.back_set_not_counted_file = params[12]
        self.back_sets_folder = params[13]
        self.top_alleles = int(params[14])
        self.msigdb_files = params[15]
        self.msigdb_not_found_hgnc = params[16]
        