library(DBI)
library(RPostgreSQL)
library(RSQLite)
library(proto)
library(gsubfn)
library(sqldf)
library(dplyr)
library(dbplyr)
library(Matrix)
library(slam)
library(foreach)

#this function is needed when using integer ids as character strings
lstrip <- function(data) {  
  data = sub("^\\s+", "", data)
  return (data)
}

# https://stackoverflow.com/questions/16309750/match-does-not-work
match.numeric <- function(x, table) {
  are.equal <- function(x, y) isTRUE(all.equal(x, y))
  match.one <- function(x, table)
    match(TRUE, vapply(table, are.equal, logical(1L), x = x))
  vapply(x, match.one, integer(1L), table)
}

get_connection <- function(dbname, host = "", port = 5432, user = "", password = "") {
  return (src_postgres(dbname = dbname, host = host, port = port, user = user, password = password))
}

get_variations_of_names <- function(conn, variations) {  
  if (length(variations) == 0) {
    return (NULL)
  } else if (length(variations) == 1) {
    return (collect(filter(tbl(conn, "variation"), name == variations)))
  } else {
    return (collect(filter(tbl(conn, "variation"), name %in% variations)))
  }  
}

get_variations_of_ids <- function(conn, ids) {
  if (length(ids) == 0) {
    return (NULL)
  } else if (length(ids) == 1) {
    return (collect(filter(tbl(conn, "variation"), id == ids)))
  } else {    
    return (collect(filter(tbl(conn, "variation"), id %in% ids)))
  }
}

get_variations_of_names_of_back_set <- function(conn, variations, back_set) {
  if (length(variations) == 0 || length(back_set) != 1) {
    return (NULL)
  } else if (back_set == 1L) {
    if (length(variations) == 1) {
      return (collect(arrange(filter(tbl(conn, "variation"), name == variations), chr, position)))
    } else {
      return (collect(arrange(filter(tbl(conn, "variation"), name %in% variations), chr, position)))
    }  
  } else if (length(variations) == 1) {
    return (collect(arrange(semi_join(
      filter(tbl(conn, "variation"), name == variations), 
      filter(tbl(conn, "var2back_set"), back_set_id == back_set), 
      by = c("id" = "var_id")), chr, position)))
  } else {
    return (collect(arrange(semi_join(
      filter(tbl(conn, "variation"), name %in% variations), 
      filter(tbl(conn, "var2back_set"), back_set_id == back_set), 
      by = c("id" = "var_id")), chr, position)))
  }
}

filter_variations <- function(vars, window_length) {
  #allocate vector of filtered ids
  filtered_var_ids = integer(nrow(vars))
  filtered_var_ids = vars$id[1]
  #number of filtered vars
  filtered = 1
  #current length of window
  current_window_length = 0  
  if (nrow(vars) > 1)
  {
    for (i in 2:nrow(vars)) {
      #add to current window length vars positions difference 
      current_window_length = current_window_length + (vars$position[i] - vars$position[i - 1])    
      if (vars$chr[i - 1] != vars$chr[i] || current_window_length > window_length) {
        #vars are on another chromosome or window was too large. Reset window size
        current_window_length = 0
        #var is outside of window, filter current one
        filtered = filtered + 1
        filtered_var_ids[filtered] = vars$id[i]
      }
    }
  }
  return (filter(vars, id %in% filtered_var_ids))
}

get_annotations_of_labels <- function(conn, ann_desc_id, annotations) {
  if (length(ann_desc_id) == 0 || length(annotations) == 0) {
    return (NULL)
  } else if (length(ann_desc_id) == 1 && length(annotations) == 1) {
    return (collect(filter(tbl(conn, "annotation"), annotation_description_id == ann_desc_id & label == annotations)))
  } else if (length(ann_desc_id) == 1) {
    return (collect(filter(tbl(conn, "annotation"), annotation_description_id == ann_desc_id & label %in% annotations)))  
  } else if (length(annotations) == 1) {
    return (collect(filter(tbl(conn, "annotation"), annotation_description_id %in% ann_desc_id & label == annotations)))   
  } else {
    return (collect(filter(tbl(conn, "annotation"), annotation_description_id %in% ann_desc_id & label %in% annotations)))
  }
}

get_annotations_of_ids <- function(conn, ids) {
  if (length(ids) == 0) {
    return (NULL)
  } else if (length(ids) == 1) {
    return (collect(filter(tbl(conn, "annotation"), id == ids)))
  } else {
    return (collect(filter(tbl(conn, "annotation"), id %in% ids)))
  }
}

get_annotations_of_desc_id <- function(conn, description_ids = NULL) {
  if (length(description_ids) == 0) {
    return (collect(tbl(conn, "annotation")))
  } else if (length(description_ids) == 1) {
    return (collect(filter(tbl(conn, "annotation"), annotation_description_id == description_ids)))
  } else {
    return (collect(filter(tbl(conn, "annotation"), annotation_description_id %in% description_ids)))
  }  
}

get_annotations_of_desc_id_of_back_set <- function(conn, back_set, description_ids) {
  if (length(back_set) != 1) {
    return (NULL)
  }
  if (back_set == 1L) {
    if (length(description_ids) == 1) {
      return (collect(inner_join(filter(tbl(conn, "annotation"), annotation_description_id == description_ids),
                                 filter(tbl(conn, "ann2back_set"), back_set_id == back_set),
                                 by = c('id' = 'ann_id'))))
    } else {
      return (collect(inner_join(filter(tbl(conn, "annotation"), annotation_description_id %in% description_ids),
                                 filter(tbl(conn, "ann2back_set"), back_set_id == back_set),
                                 by = c('id' = 'ann_id'))))
    }
  } else {
    if (length(description_ids) == 1) {
      return (collect(inner_join(filter(tbl(conn, "annotation"), annotation_description_id == description_ids),
                                 filter(tbl(conn, "ann2back_set"), back_set_id == back_set, count > 0),
                                 by = c('id' = 'ann_id'))))
    } else {
      return (collect(inner_join(filter(tbl(conn, "annotation"), annotation_description_id %in% description_ids),
                                 filter(tbl(conn, "ann2back_set"), back_set_id == back_set, count > 0),
                                 by = c('id' = 'ann_id'))))
    }
  }
}

get_ann_desc <- function(conn) {
  return (collect(tbl(conn, "annotation_description")))
}

get_var_ann_desc <- function(ann_desc) {  
  return (filter(ann_desc, type == "var"))
}

get_gene_ann_desc <- function(ann_desc) {
  return (filter(ann_desc, type == "gene"))
}

get_back_set <- function(conn) {
  return (collect(tbl(conn, "background_sets")))
}

get_total_count_of_annotations_in_back_sets <- function(conn) {
  return (table(collect(select(inner_join(tbl(conn,'annotation'), filter(tbl(conn,'ann2back_set'), count > 0), 
                                          by = c("id" = "ann_id")), back_set_id, annotation_description_id), n=Inf)))
}

get_association_pairs <- function(conn, variations_ids, annotations_ids) {
  if (length(variations_ids) == 0 || length(annotations_ids) == 0) {
    return (NULL)
  }  
  
  #get associations pairs
  if (length(variations_ids) == 1 && length(annotations_ids) == 1) {
    id_pairs = collect(filter(tbl(conn,"var2ann"), var_id == variations_ids & ann_id == annotations_ids))
  }
  else if (length(variations_ids) == 1) {
    id_pairs = collect(filter(tbl(conn,"var2ann"), var_id == variations_ids & ann_id %in% annotations_ids))
  }
  else if (length(annotations_ids) == 1) {
    id_pairs = collect(filter(tbl(conn,"var2ann"), var_id %in% variations_ids & ann_id == annotations_ids))
  }
  else {
    id_pairs = collect(filter(tbl(conn,"var2ann"), var_id %in% variations_ids & ann_id %in% annotations_ids))
  }  
  
  if (nrow(id_pairs) == 0) {
    return (NULL)
  } else {
    return (id_pairs)
  }
}

get_sparse_matrix <- function(variations_ids, annotations_ids, id_pairs) {
  if (is.null(id_pairs)) {
    return (NULL)
  }
  #create dictionary pk->index_in_binary_matrix for variations    
  variations_map_pk2index = integer()
  variations_map_pk2index[variations_ids] = 1:length(variations_ids)
  #create dictionary pk->index_in_binary_matrix for annotations  
  annotations_map_pk2index = integer()
  annotations_map_pk2index[annotations_ids] = 1:length(annotations_ids)    
  #Map primary keys in id_pairs to indices in binary matrix by created dictionaries    
  variations_indices = variations_map_pk2index[id_pairs$var_id]
  annotations_indices = annotations_map_pk2index[id_pairs$ann_id]
  #create and return binary sparse matrix  
  return (sparseMatrix(variations_indices, annotations_indices,
                       #each item has value 1
                       x=1,
                       #dimensions of matrix are number of queried variations and number of queried annotations
                       dims=c(length(variations_ids), length(annotations_ids)), 
                       #apply dimension names lists
                       dimnames=list(variations_ids, annotations_ids)))
}

get_odds_ratio <- function(annotations, sparse_matrix, variations_sample, variations_total) {
  
  # DEBUG
  #print(sparse_matrix)
  
  if (is.null(sparse_matrix)) {
    annotations$observed <- rep(0, nrow(annotations))
    # DEBUG
    # print("Sparse matrix is null")
  } else {
    names2sums = numeric() #because col_sums returns sums as doubles, not integers
    names2sums[dimnames(sparse_matrix)[[2]]] = col_sums(sparse_matrix)
    annotations$observed <- names2sums[as.character(annotations$id)]
    
    # DEBUG
    # print(names2sums[as.character(annotations$id)])
    # print("names2sums:")
    # print(str(names2sums))
    # print(class(names2sums))
    # print(typeof(names2sums))
    # print(names(names2sums))
    # print(names2sums)
    # print("test: names2sums[24320]:")
    # print(names2sums[24320])
    # print('test: names2sums["24320"]:')
    # print(names2sums["24320"])
    # print("annotation ids:")
    # print(annotations$id)
    # print("names2sums 2:")
    # print(names2sums[as.integer(annotations$id)])
    # print(names2sums[annotations$id])
  }
  prop = variations_sample / variations_total  
  annotations$expected <- annotations$count * prop    
  annotations$odds_ratio <- (annotations$observed / (variations_sample - annotations$observed)) /
    (annotations$count / (variations_total - annotations$count))
  
  # DEBUG
  # print(prop)
  # print(annotations$count * prop)
  # print(annotations$observed)
  # print((annotations$observed / (variations_sample - annotations$observed)) /
  #         (annotations$count / (variations_total - annotations$count)))  
  # print(variations_sample)
  # print(variations_total)
  # print(annotations)
  
  return (annotations)
}

get_overrepresentation_significance <- function(annotations, variations_sample, variations_total) {  
  annotations$pvalue_over <- phyper(annotations$observed - 1, annotations$count, 
                                   variations_total - annotations$count, variations_sample, lower.tail = FALSE)  
  annotations$pvalue_over_fdr <- p.adjust(annotations$pvalue_over, method="BH")  
  return (select(annotations, id, pvalue_over, pvalue_over_fdr))
}

get_underrepresentation_significance <- function(annotations, variations_sample, variations_total) {  
  annotations$pvalue_under <- phyper(annotations$observed, annotations$count, 
                                     variations_total - annotations$count, variations_sample, lower.tail = TRUE)  
  annotations$pvalue_under_fdr <- p.adjust(annotations$pvalue_under, method="BH")  
  return (select(annotations, id, pvalue_under, pvalue_under_fdr))
}

get_variation_binary_data <- function(variations, annotations, annotations_desc, sparse, sep, annotation.n=NULL) {    
 
  
  if (!is.null(annotations)) {
    ann_desc2name = character()
    ann_desc2name[annotations_desc$id] = annotations_desc$description
    rows = 1
    #for each annotation add new column to variations data frame with zeros or ones from sparse matrix
    if(!is.null(annotation.n)) {
      max.annotations <- min(nrow(annotations), annotation.n)
    } else {
      max.annotations <- nrow(annotations)
    }
    
    for (i in 1:max.annotations) {
      variations[[paste(ann_desc2name[as.integer(annotations[i,]$annotation_description_id)], annotations[i,]$label, sep = sep)]] <-
        sparse[lstrip(variations$id), lstrip(annotations[i,]$id)]
    }    
  }

  print(head(variations))
  
#  foreach(i=1:nrow(annotations), .combine=cbind) %do% {
#    tmp <- sparse[lstrip(variations$id), lstrip(annotations[i,]$id)]
#    colnames(tmp)[i] <- [paste(ann_desc2name[as.integer(annotations[i,]$annotation_description_id)], annotations[i,]$label, sep = sep)]

#      }
  
    
  return (variations)
}

get_contingency_table <- function(variations, annotations, annotations_desc, id_pairs) {
  ann_desc2name = character()
  ann_desc2name[annotations_desc$id] = annotations_desc$description
  if (is.null(id_pairs)) {
    return (NULL)
  }
  #create dictionary pk->name for variations    
  variations_map_pk2name = character()
  variations_map_pk2name[variations$id] = variations$name
  #create dictionary pk->label for annotations  
  annotations_map_pk2label = character()
  annotations_map_pk2label[annotations$id] = 
    paste(ann_desc2name[annotations$annotation_description_id], annotations$label, sep = ": ")
  #Map primary keys in id_pairs to names
  label_pairs = data.frame(var_name = character(nrow(id_pairs)), ann_label = character(nrow(id_pairs)))  
  label_pairs$var_name = variations_map_pk2name[id_pairs$var_id]
  label_pairs$ann_label = annotations_map_pk2label[id_pairs$ann_id]
  #create contingency table
  return (table(label_pairs))  
}

get_example_data <- function() {
  return (paste(readLines("data/example_snps.txt"), collapse="\n"))
}

processTextInput <- function(text) {
  #print(file)
  #values <- suppressWarnings(as.numeric(unlist(strsplit(text, split=",| |\n|\r|\t|\v"))))
  #if (is.null(file)) {
  #values <- suppressWarnings(as.numeric(unlist(strsplit(text, split="[, \n\r\t\v]+"))))
  #values <- values[which(!is.na(values))]
  #} else {
  values <- NULL
  
  values <- suppressWarnings(as.character(unlist(strsplit(text, split=',| |\r|\t|\v'))))
  values[values==""] <- NA
  values <- values[!is.na(values)]
  values
}
