#!/usr/bin/env Rscript
retrieve_ensembl_genes <- function(genesfile,output,start=1) {
  library(biomaRt)
  # Used for trimming whitespace, sigh
  library(limma)
  library(RCurl)
    
  genemart <- useMart("ENSEMBL_MART_ENSEMBL", host="www.ensembl.org")  
  genemart <-useDataset("hsapiens_gene_ensembl",genemart)
  
  genes <- scan(genesfile, what="characters", sep=",", quote="\"", skip=0)
  gc()
  head(genes)
  
  totalgenes <- length(genes)
  chunksize <- 1000#100000
  
  append <- TRUE
  start=strtoi(start)
  if (start == 1){
    append <- FALSE
  }
  
  curlHandle <- getCurlHandle()
  startTime <- Sys.time()
  
  for (j in seq(from=start, to=totalgenes, by=chunksize)) {
    loopStartTime <- Sys.time()
    print(paste(j, totalgenes, sep="/"))
    geneschunk <- genes[j:(j+chunksize-1)]
    repeat {
      success = TRUE
      print("Query started...")
      tryCatch(geneslist <- getBM(attributes=c("ensembl_gene_id", "go_id", "name_1006", "definition_1006",
                                               "hgnc_symbol","gene_biotype","phenotype_description"),
                                  filters=c("ensembl_gene_id"),values=geneschunk, mart=genemart, uniqueRows=TRUE, curl=curlHandle),#, "mim_morbid_description
               error = function(e) success = FALSE)            
      if (success & exists("geneslist")) {        
        print("Query completed.")
        break
      }
      print("Query failed. Retrying...")
    }
    
    write.table(geneslist, file=output, sep = "\t", col.names=FALSE, row.names=FALSE, quote=FALSE, na="", append=append) 
    append = TRUE
    rm(geneslist)
    rm(geneschunk)
    gc()
    
    print("Loop: ")
    print( Sys.time() - loopStartTime)
    print("Per gene: ")
    print( (Sys.time() - loopStartTime) / chunksize)
    print("Total: ")
    print( Sys.time() - startTime)
  }
  print(paste0("Processing file ", genesfile, " finished."))
}


args=(commandArgs(TRUE))
retrieve_ensembl_genes(args[1],args[2],args[3])
