
# Install R-packages
packages_list <- c(
  "plotly",
  "reshape2",
  "gplots",
  "stringr",
  "ggdendro",
  "gridBase",
  "RColorBrewer",
  "rvg",
  "ggplot2",
  "dbplyr",
  "dplyr",
  "proto",
  "gsubfn",
  "sqldf",
  "slam",
  "RPostgreSQL",
  "foreach",
  "shinyjs",
  "shinyBS"
)

install.packages(packages_list, repos='https://ftp.acc.umu.se/mirror/CRAN/')

# Install Bioconductor and BioC packages
#########################################

# LEGACY
#source("http://bioconductor.org/biocLite.R")
#biocLite()
#biocLite("ggbio")
#biocLite("GenomicRanges")
#biocLite("TxDb.Hsapiens.UCSC.hg38.knownGene")
#biocLite("chromPlot")
##biocLite("karyoploteR")

# Alternative,R < 3.5.0
#source("https://bioconductor.org/biocLite.R")
#BiocInstaller::biocLite(c("ggbio", "GenomicFeatures", "TxDb.Hsapiens.UCSC.hg38.knownGene","chromPlot"))

# Beyond R version 3.6.0
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install()
BiocManager::install(c("ggbio", "GenomicFeatures", "TxDb.Hsapiens.UCSC.hg38.knownGene","chromPlot"))
