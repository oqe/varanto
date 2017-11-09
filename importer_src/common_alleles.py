'''
Created on Mar 30, 2015

@author: tiborf
'''

import operator

class CommonAlleles(object):
    '''
    classdocs
    '''


    def __init__(self):
        '''
        Constructor
        '''        
        self.vars = []
        self.alleles_count = {}
        
    def insert_variation(self, var_id, var_allele, var_in_back_sets):
        self.vars.append((var_allele, var_in_back_sets))
        if not var_allele in self.alleles_count:
            self.alleles_count[var_allele] = 0
        self.alleles_count[var_allele] += 1
    
    def get_common_alleles(self, top_alleles_count):
        ordered_alleles = sorted(self.alleles_count.items(), key=operator.itemgetter(1), reverse=True)
        top_alleles = set([ordered_alleles[i][0] for i in range(min(top_alleles_count, len(ordered_alleles)))])
        for i in range(len(self.vars)):
            var = self.vars[i]
            if var[0] in top_alleles:
                yield (i + 1, ('common_allele', var[0], '', 'var'), var[1])
            else:
                yield (i + 1, ('common_allele', 'uncommon', '', 'var'), var[1])
            
            
        
        