source('varanto_functions.R')

db = ''
host = ''
port = ''
user = ''
password = ''
global_conn = get_connection(db, host=host, port=port, user=user, password=password)

ann_desc = get_ann_desc(global_conn)
var_ann_desc = get_var_ann_desc(ann_desc)
gene_ann_desc = get_gene_ann_desc(ann_desc)

back_set = get_back_set(global_conn)
