'''
Created on Mar 20, 2015

@author: tiborf
'''

import csv

class BackgroundSets(object):
    '''
    classdocs
    '''


    def __init__(self, back_set_not_counted_file, back_sets_folder):
        '''
        Constructor
        '''                
        self.variations_sets = {}
        self.new_back_sets_desc = []            
        with open(back_set_not_counted_file, 'r') as back_sets_input:        
            reader = csv.reader(back_sets_input, delimiter='\t')        
            for row in reader:
                self.new_back_sets_desc.append([row[0], row[1], row[2]])
                #count variations in variation set files and create python sets of variations in all variation set files
                if row[0] != '1': #skip line for all variations background set
                    self.variations_sets[row[0]] = set()
                    counter = 0
                    with open(back_sets_folder + row[1] + ".txt", 'r') as back_set_vars:
                        for var in back_set_vars:
                            if var[0] == '#' or var == 'unknown':
                                continue
                            counter += 1                            
                            self.variations_sets[row[0]].add(var.strip())                        
                    self.new_back_sets_desc[-1].append(counter)
        self.back_sets_ids = [str(i) for i in range(1, len(self.new_back_sets_desc) + 1)]
                    
    def get_back_sets_ids(self):
        return self.back_sets_ids
    
    def process_variant(self, variant, variant_id, var2back_set_csv):
        '''
        Write new rows to var2back_set table and fill out in_back_set
        '''
        in_back_set = []
        for i in self.get_back_sets_ids():
            if i == '1':
                in_back_set.append(i)
            elif variant in self.variations_sets[i]:
                var2back_set_csv.writerow([i, variant_id])
                in_back_set.append(i)
        return in_back_set
    
    def write_table_back_sets_file(self, all_variants_count, table_back_set_file):
        with open(table_back_set_file,'w') as new_back_sets_output:               
            writer = csv.writer(new_back_sets_output, delimiter='\t')
            self.new_back_sets_desc[0].append(all_variants_count)
            for row in self.new_back_sets_desc:            
                writer.writerow([row[0], row[1], row[2], row[3]])
            