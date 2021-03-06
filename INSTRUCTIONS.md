
# Local install/deployment instructions

Local installation and deployment instructions for Varanto. 

## Table of Contents

Deploying Varanto locally - instructions  
1. Requirements  
    1.1. Install required software  
    1.2. Setup your PostgreSQL database  
2. Downloading and preparing data sources (MSigDB, background sets) and Varanto git repository  
    2.1. Varanto git repository  
    2.2. Preparing additional data sources manually  
        2.2.1. Download MSigDB_Collection  
        2.2.2. Prepare MSigDB_Collection  
        2.2.3. Download background sets  
        2.2.4. Prepare background sets  
    2.3. Main data source version check  
3. Download and prepare main data sources and import to database  
    3.1. Edit and apply changes to configuration file (varanto_import.conf)  
    3.2. Setting up passwordless database import (optional, but recommended)  
    3.3. Import script - Download main data sources  
    3.4. Import script - Prepare and import data resources to database  
4. Shiny  
    4.1. Input your database information for R Shiny  
    4.2. Startup Shiny  


## Deploying Varanto locally - instructions

These instructions detail how to deploy Varanto (locally) with same (data) resources as the hosted webservice at http://bioinformatics.uef.fi/varanto.

**Notice that obtaining the same resources and deploying them may take several days depending on computational and network resources at your disposal.**

Replace /varanto/ in the code blocks with the actual path to your git downloaded varanto directory.

### 1. Requirements

Setup has only been tested on CentOS 7, but should work on UNIX-like systems.

* <strong>OS</strong>: UNIX-like
    * Python 3.4 or above
    * R, RStudio
        * BiomaRt, dplyr, Shiny, plotly, ggplot2 and other packages (check About from http://bioinformatics.uef.fi/varanto/)  
    * PostgreSQL

*Approximate disk space requirements:*
* Overall recommended space for deployment: ~ 3 TB
* SNP-arrays/Background sets ~ 400 MB
* MSigDB (.gmt) ~ 28 MB
* Ensembl and GET-E ~ 712 GB
* operational PostgreSQL database ~ 1.5 TB

#### 1.1 Install required software

Install required software:
* Python 3.4 or up
* RStudio
* PostgreSQL

#### 1.3 Setup your PostgreSQL database

Create and configure your PostgreSQL database. No further instructions on that are provided here.

Initiation of the schema is automated and handled by the import-script. If there is already an existing one with similar schema it will be deleted.

### 2. Downloading and preparing data sources (MSigDB, background sets) and Varanto git repository

MSigDB and background sets data sources need to be manually downloaded and prepared. These data will be later imported to the database.

#### 2.1 Varanto git repository, install R-packages

Download git repo

    git init
    git remote add origin https://github.com/oqe/varanto
    git pull origin master

For MSigDB and SNP-arrays (or your custom background sets) you need to some manual downloading and setting up before import. Ensembl and GET-E downloading and preparation is automated in the main import script. Configuration of varanto_import.conf is still required.

Check *varanto_import.conf* file for settings and paths for files. There is a more comprehensive follow up on this .conf file in section 3.1.

Data sources in these examples will be downloaded and stored to /varanto/downloaded_data. Alternatively they can be downloaded to any given directory, be sure to reflected that in place of /varanto/downloaded_data.

**Install R-packages*:**
* After installing RStudio open and run varanto/www/install_R_packages.R to install the required packages

#### 2.2 Preparing additional data sources manually

In the webservice we use MSigDB for gene annotations and various SNP-arrays as background sets for filtering (to select variants in the selected array).

These resources need to be downloaded and prepared manually before the import.

##### 2.2.1 Download MSigDB_Collection

Download/update the MSigDB Collections (http://software.broadinstitute.org/gsea/msigdb/collections.jsp)[http://software.broadinstitute.org/gsea/msigdb/collections.jsp] by downloading the files to */varanto/downloaded_content/MSigDB_Collections_<version number>/. Also check the release notes for the downloads.

<strong>You only need to download the gene symbols files.</strong> File extensions for these are .gmt.

##### 2.2.2 Prepare MSigDB_Collection

Update/create a tab-delimited listing of the previous step's downloaded MSigDB files' paths, listing one path per line and give each path a "name" separated by tab (on the same line). Save this text file to */varanto/data/MSigDB_Collections_<version number>.txt*. For example:

    /varanto/downloaded_data/MSigDB_Collections_v6.0/h.all.v6.0.symbols.gmt H_hallmark
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c1.all.v6.0.symbols.gmt    C1_positional
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c2.all.v6.0.symbols.gmt    C2_curated
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c2.cgp.v6.0.symbols.gmt    CGP_chemical_and_genetic_perturbations
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c2.cp.v6.0.symbols.gmt CP_Canonical_pathways
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c2.cp.biocarta.v6.0.symbols.gmt    CP_BIOCARTA_BioCarta
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c2.cp.kegg.v6.0.symbols.gmt    CP_KEGG_KEGG
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c2.cp.reactome.v6.0.symbols.gmt    CP_REACTOME_Reactome
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c3.all.v6.0.symbols.gmt    C3_motif
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c3.mir.v6.0.symbols.gmt    MIR_microRNA_targets
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c3.tft.v6.0.symbols.gmt    TFT_transcription_factor_targets
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c4.all.v6.0.symbols.gmt    C4_computational
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c4.cgn.v6.0.symbols.gmt    CGN_cancer_gene_neighborhoods
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c4.cm.v6.0.symbols.gmt CM_cancer_modules
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c5.all.v6.0.symbols.gmt    C5_GO
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c5.bp.v6.0.symbols.gmt BP_GO_biological_process
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c5.cc.v6.0.symbols.gmt CC_GO_cellular_component
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c5.mf.v6.0.symbols.gmt MF_GO_molecular_function
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c6.all.v6.0.symbols.gmt    C6_oncogenic_signatures
    /varanto/downloaded_data/MSigDB_Collections_v6.0/c7.all.v6.0.symbols.gmt    C7_immunologic_signatures

Modify your *varanto_import.conf* file's line MSIGDB_CONF= value to previous step's file  

##### 2.2.3 Download background sets

In the hosted Varanto background sets are comprised of different single-nucleotide polymorphism (SNP) -arrays. Anything with SNP identifiers can be used as a background set, so you may prepare your own custom background sets.

Basically we extract the SNP-identifiers from the downloaded SNP-arrays and prepare the files accordingly.

Download snpArray* files from UCSC: http://hgdownload.cse.ucsc.edu/goldenPath/hg19/database/

##### 2.2.4 Prepare background sets

Extract downloaded snpArray-files

    gunzip *.txt.gz

Extract wanted column with snp identifiers.  
Check from file which column you want to extract, for example in terminal:

    head snpArrayAffy5.txt

Extract wanted column (by it's column number) and save to a new file, for example:

    awk '{print $9}' snpArrayAffy5.txt > /varanto/donwloaded_data/background_sets/Affy5.txt

Do the previous to all files. Remember to check each file first for the right column. In "snpArrayAffy"-files it usually seems to be the ninth column and for "snpArrayIllumina" it's the fift column.

Edit snpArray filenames to your preference. And and find out the actual names for the labels (tab separated). Here we remove *snpArray* from the filenames. So the actual file names (without extensions) are on the second column and the actual real names (labels) are on the third column, running number is on the first column.

So you should end up with the following or equivalent text to *background_sets.txt* file in your (git)project folder (eg. /varanto/data/background_sets.txt)

    1   all All variations
    2   Affy5   Affymetrix Genome-Wide Human SNP Array 5.0
    3   Affy6   Affymetrix Genome-Wide Human SNP Array 6.0
    4   Affy6SV Affymetrix Genome-Wide Human SNP Array 6.0 Structural Variation
    5   Affy250Nsp  Affymetrix GeneChip Human Mapping 250K Nsp
    6   Affy250Sty  Affymetrix GeneChip Human Mapping 250K Sty
    7   Illumina1M  Illumina Human1M-Duo
    8   Illumina300 Illumina HumanHap300
    9   Illumina550 Illumina HumanHap550
    10  Illumina650 Illumina HumanHap650Y
    11  IlluminaHuman660W_Quad  Illumina Human660W-Quad
    12  IlluminaHumanCytoSNP_12 Illumina HumanCytoSNP-12
    13  IlluminaHumanOmni1_Quad Illumina HumanOmni1-Quad

Actual names of the arrays https://cgwb.nci.nih.gov/cgi-bin/hgTrackUi?g=snpArray

Copy the newly formated array files with only identifier to folder that is defined in "varanto_import.conf" as *"BACKGROUND_SETS_FOLDER="*, for example "/varanto/downloaded_data/background_sets".

#### 2.2. Main data source version check

Check the current version of ensembl database. Current and previous version and their dates of database versions can be checked from the (Table of Assemblies)[http://www.ensembl.org/info/website/archives/assembly.html]  
  
If you have previously used Varanto to import some version of Ensembl, you can check your previous download folder for the ensembl data  /varanto/downloaded_data and note the version and path. That is if you wish to revert to that version.

### 3. Download and prepare main data sources and import to database

In this section we will download the main data sources with help of the import_script and also use this script to prepare and import data to database.

#### 3.1 Edit and apply changes to configuration file (varanto_import.conf)

Edit /varanto/conf/varanto_import.conf

*USER DEFINED* - Input your PostgreSQL database host address, database- and usernames.
    
    DB_HOST=<your host address>
    DB_NAME=<your database name>
    DB_USER=<your database username>

Like the name implies references sql-commands which are used to initiate and create database - DO NOT CHANGE

    DB_INIT_AND_CREATE=../db/db_init_and_insert_data.sql

**USER DEFINED** - Ensembl Homo Sapiens variation table version. Usually follows the naming scheme of *homo_sapiens_variation_<ensembl assembly version>_<genome version GRch38, so 38>.variation*. For example:

    ENSEMBL_VAR_TABLE=homo_sapiens_variation_89_38.variation

File to which to download variation ids 

    ENSEMBL_VAR_IDS=/varanto/downloaded_data/v89/ensembl_variations_ids.txt

File to which to download variation annotations

    ENSEMBL_VAR_ANNOTATIONS=/varanto/downloaded_data/v89/annotated_ensembl_snps.txt


    ENSEMBL_VAR_ANNOTATIONS_START_FROM=(1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1) #101 times

Progress/log information file

    ENSEMBL_VAR_ANNOTATIONS_PROGRESS=/varanto/downloaded_data/v89/retrieve_ensembl_variations.out

Associated gene id download file

    ASSOCIATED_GENES_IDS=/varanto/downloaded_data/v89/associated_genes_ids.txt

Associated genes download file

    ASSOCIATED_GENES_ANNOTATIONS=/varanto/downloaded_data/v89/annotated_associated_genes.txt


    ENSEMBL_GENES_ANNOTATIONS_START_FROM=(1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1) #101 times


    ENSEMBL_GENES_ANNOTATIONS_PROGRESS=/varanto/downloaded_data/v89/retrieve_ensembl_genes.out

Default GET-E URL - DO NOT CHANGE

    GET_EVIDENCE_VAR_URL=evidence.pgp-hms.org/download/latest/flat/latest-flat.tsv

File to which download GET-E

    GET_EVIDENCE_VAR_INFO=/varanto/downloaded_data/v89/get_evidence_var_info.tsv

**USER DEFINED** - See section 2.2.4 of this document

    BACKGROUND_SETS_DESCRIPTIONS=../data/background_sets.txt


    BACKGROUND_SETS_FOLDER=/varanto/downloaded_data/background_sets/

**USER DEFINED** - Import outcome files ready for processing steps before database import. You only need to edit path to which you want the import processed files to be saved:

    TABLE_VAR=/varanto/downloaded_data/v89/variations.csv
    TABLE_ANN=/varanto/downloaded_data/v89/annotations.csv
    TABLE_VAR2ANN=/varanto/downloaded_data/v89/var2ann.csv

Database import ready file that defines the annotation descriptions:

    TABLE_ANNDESC=/varanto/data/annotations_descriptions.txt

**USER DEFINED** - Processed files ready for database import. You only need to edit path to which you want the import processed files to be saved:

    TABLE_BACKSET=/varanto/downloaded_data/v89/back_set.csv
    TABLE_ANN2BACK=/varanto/downloaded_data/v89/ann2back.csv
    TABLE_VAR2BACK=/varanto/downloaded_data/v89/var2back.csv
    TABLES_COUNTS=/varanto/downloaded_data/v89/tables_counts.csv

Amount of top allelles:

    TOP_ALLELES=2000

**USER DEFINED** - See section 2.2.2:

    MSIGDB_CONF=varanto/data/MSigDB_Collections_v6.0_files.txt

**USER DEFINED** - "Log" file for msigdb identfiers that are not found. You only need to edit path to which you want the import processed files to be saved:

    MSIGDB_HGNC_NOT_FOUND=/varanto/downloaded_data/v89/msigdb_hgnc_not_found.txt

#### 3.2 Setting up passwordless database import (optional, but recommended)

During the import the script asks for database password multiple times. The import won't proceed any further until the password has been given. This can be negated by setting up *.pgpass file.

Passwordless database import can be done in postgresql by creating *.pgpass* file.  
So you do not waste time by watching over the database import and write your password everytime the import scripts asks for it.  

Create *.pgpass* -file to your home directory (cd ~):

	nano .pgpass

And write to file...

	hostname:port:database:username:password

So <password> is your actual password. After that you need to save changes you made to the file and set permissions.

	chmod 600 .pgpass

After that you need to check every command in your database creating scripts that have *psql* and add *-w* handle to them.

See the following: 
https://www.postgresql.org/docs/current/static/libpq-pgpass.html 
https://linuxandryan.wordpress.com/2013/03/07/creating-and-using-a-pgpass-file/

#### 3.3 Import script - Download main data sources

Main download may take several days! For example one attempt took 4 days and 9 hours.

Script is run **varanto_import.script sh** from the following git folder of your varanto project: /varanto/importer_src

You can perform wanted steps by defining what steps to execute.
    
    #STEP 1: Obtain variation ids
    #STEP 2: Obtain variation annotations
    #STEP 3: Obtain associated genes ids
    #STEP 4: Obtaining associated genes annotations
    #STEP 5: Downloading GET Evidence evidence.pgp-hms.org/download/latest/flat/latest-flat.tsv
    #STEP 6: Preparing data for insertion to database
    #STEP 7: Dropping existing database schema
    #STEP 8: Creating database schema and inserting data

    "USAGE: varanto_import.sh [-c config_file] [-f from_step] [-t to_step] [-s single_step] [-m binary-step-mask(01000111)]"

Here we presume you defined your configuration file appropriately (eg. **varanto_import.conf**)!

For example if we want to only do the downloading of the required files before going doing anything database related we will perform step 1-5. (pwd: /home/users/username/pathtovaranto/varanto/importer_src):

    sh varanto_import.sh -c /varanto/conf/varanto_import.conf -f 1 -t 5

#### 3.4 Import script - Prepare and import data resources to database

Process imported data and and import to PostgreSQL database

    sh varanto_import.sh -c /varanto/conf/varanto_import.conf -f 6 -t 8

### 4. Shiny

After completing the import steps succesfully we need to run Varanto locally we also need to apply appropriate changes to connect to our postgresql database. After that you can launch Varanto from RStudio.

Also to install required R-packages run **install_packages.R** from **www**-folder unless already done in section 2.1.

#### 4.1 Input your database information for R Shiny

**global.R.DEFAULT**

Update with your database and user login information and rename to global.R

Fill in information:
- db
- host
- port
- password

#### 4.2 Startup shiny

To start up the Varanto web app locally start your RStudio and load ui.R.  
Then start up the Shiny app under the ui.R source code tab by clicking "Run App" with green triangle.
