# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

__author__="tiborf"
__date__ ="$Jan 30, 2015 11:51:07 PM$"

import csv

class AnnDescriptions:
    
    def __init__(self, ann_descriptions):
        self.annotation_label_to_id = {}
        with open(ann_descriptions) as desc_input:            
            reader = csv.reader(desc_input, delimiter='\t')                    
            for row in reader:                
                self.annotation_label_to_id[row[1] + "_" + row[3]] = row[0]

    def get_annotation_description(self, label, var_gene):        
        return self.annotation_label_to_id[label + "_" + var_gene]
    
    def id_count(self):
        return len(self.annotation_label_to_id)

if __name__ == "__main__":
    print("annotations_descriptions module")
