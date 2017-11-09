'''
Created on Mar 20, 2015

@author: tiborf
'''

class Annotation(object):
    '''
    classdocs
    '''


    def __init__(self, attribute, label, description, var_gene):
        '''
        Constructor
        '''
        self.attribute = attribute
        self.label = label
        self.description = description
        self.var_gene = var_gene
