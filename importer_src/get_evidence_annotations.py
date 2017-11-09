# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

__author__="tiborf"
__date__ ="$Jan 30, 2015 4:39:33 PM$"

import csv

class GetEvidenceDbImport:

    def __init__(self, get_evidence_data):
        self.get_evidence_data = {}
        with open(get_evidence_data) as input_file:
            reader = csv.reader(input_file, delimiter='\t')        
            headers=["impact", "qualified_impact", "inheritance"]   
            for row in reader:
                #check if dbsnp is assigned
                if len(row[7]) != 0:
                    dbsnp = row[7]
                    if not dbsnp in self.get_evidence_data:
                        self.get_evidence_data[dbsnp] = set()
                    for i in range(3):
                        if len(row[i + 3]) != 0:                            
                            self.get_evidence_data[dbsnp].add((headers[i], row[i + 3], '','var'))                

    def get_get_evidence_annotations(self, dbsnp):        
        if dbsnp in self.get_evidence_data:
            for i in self.get_evidence_data[dbsnp]:
                yield i
                        

if __name__ == "__main__":
    print("evidences_data module")
