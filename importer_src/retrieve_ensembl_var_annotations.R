#!/usr/bin/env Rscript
retrieve_ensembl_variations <- function(snpfile,snp_annotations_file,start_from=1) {  
  library(biomaRt)
  # Used for trimming whitespace, sigh
  library(limma) 
  library(RCurl)
  
  snpmart <- useMart("ENSEMBL_MART_SNP",host="www.ensembl.org")  
  snpmart <-useDataset("hsapiens_snp", snpmart)
  
  snps <- scan(snpfile, what="characters", sep=",", quote="\"", skip=0)
  gc()
  head(snps)
  
  totalsnps <- length(snps)
  chunksize <- 100000
  
  append <- FALSE  
  start_from <- strtoi(start_from) #argument from commandline is in string type
  
  if (start_from != 1) {
    append <- TRUE    
  }
  
  curlHandle <- getCurlHandle()
  startTime <- Sys.time()  
  
  for (j in seq(from=start_from, to=totalsnps, by=chunksize)) {
    loopStartTime <- Sys.time()  
    print(paste(j, totalsnps, sep="/"))
    snpchunk <- snps[j:(j+chunksize-1)]    
    repeat {
      exceptionOccured = FALSE
      print("Query started...")
      tryCatch(snplist <- getBM(attributes=c("refsnp_id", "allele", "chr_name", "chrom_start", "chrom_strand", "phenotype_description", 
                                             "study_external_ref", "study_description", "consequence_type_tv", "ensembl_gene_stable_id", 
                                             "associated_gene", "polyphen_prediction", "sift_prediction"),
                                filters=c("snp_filter"), values=snpchunk, mart=snpmart, uniqueRows=TRUE, curl=curlHandle),
               error = function(e) exceptionOccured = TRUE)      
      if (!exceptionOccured & exists("snplist")) {
        print("Query completed.")
        break        
      }
      print("Query failed. Retrying...")
    }
    
    write.table(snplist, file=snp_annotations_file, sep = "\t", col.names=FALSE, row.names=FALSE, quote=FALSE, na="", append=append)
    append <- TRUE    
    rm(snpchunk)    
    rm(snplist)    
    gc()
    
    print("Loop: ")
    print( Sys.time() - loopStartTime)
    print("Per SNP: ")
    print( (Sys.time() - loopStartTime) / chunksize)
    print("Total: ")
    print( Sys.time() - startTime)      
  }
}

args=(commandArgs(TRUE))
retrieve_ensembl_variations(args[1],args[2],args[3])