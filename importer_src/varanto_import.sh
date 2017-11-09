#! /bin/bash

set -e #check for failed commands
set -u #check for unbound variables

chmod +x get_ensembl_variation_ids.sh
chmod +x retrieve_associated_genes_ids.sh
chmod +x prepare_table_files.py
chmod +x db_init_schema_and_insert_data.sh
chmod +x retrieve_ensembl_genes_annotations.R
chmod +x retrieve_ensembl_var_annotations.R

step=(true true true true true true true true); #which steps to perform
steps=8 #number of steps
config_file="varanto_import.conf"

#process arguments
while getopts "c:f:t:s:m:h" opt; do
	case $opt in
		c)
			config_file=$OPTARG
			;;
		f)
			for (( i=0; i<$OPTARG-1; i++ ))
			do
				step[$i]=false
			done
			;;
		t)
			for (( i=$OPTARG; i<$steps; i++ ))
			do
				step[$i]=false
			done
			;;
		s)
			for (( i=0; i<$steps; i++ ))
			do
				if [[ ! $i -eq $OPTARG-1 ]]; then
					step[$i]=false
				fi					
			done
			;;
		m)
			for (( i=0; i<$steps; i++ ))
			do
				if [[ ${OPTARG:$i:1} -eq "0" ]]; then
					step[$i]=false
				fi
			done
			;;
		h)
			echo "USAGE: varanto_import.sh [-c config_file] [-f from_step] [-t to_step] [-s single_step] [-m binary-step-mask(01000111)]"
			exit
			;;
		\?)
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			exit 1
			;;
	esac
done
#load variables from config file
source $config_file
#function for echo of time difference
function time_diff {
	days="$(($1 / 86400))d"
	hours="$(($1 / 3600 % 24))"
	minutes="$(($1 / 60 % 60))"
	seconds="$(($1 % 60))"
	echo "$days $(($hours / 10))$(($hours % 10)):$(($minutes / 10))$(($minutes % 10)):$(($seconds / 10))$(($seconds % 10))"
}
date0=$(date +"%s")

#STEP 1: Obtain variation ids
if [[ ${step[0]} == true ]]; then
	echo "STEP 1 - Obtaining ensembl variation ids started..." 
	date_start=$(date +"%s")
	./get_ensembl_variation_ids.sh $ENSEMBL_VAR_TABLE $ENSEMBL_VAR_IDS $LIMIT
	date_end=$(date +"%s")
	diff=$(($date_end-$date_start))
	diff_total=$(($date_end-$date0))
	echo "STEP 1 - Obtaining ensembl variation ids completed. Time: `time_diff $diff`. Total time: `time_diff $diff_total`."
fi

#STEP 2: Obtain variation annotations
if [[ ${step[1]} == true ]]; then
	echo "STEP 2 - Obtaining ensembl variation annotations started..."
	date_start=$(date +"%s")
	(( lines = `wc -l $ENSEMBL_VAR_IDS | cut -f 1 -d " "` / $THREADS ))
	rm -f ${ENSEMBL_VAR_IDS}_*
	split -l $lines $ENSEMBL_VAR_IDS "${ENSEMBL_VAR_IDS}_"
	i=0
	for ii in ${ENSEMBL_VAR_IDS}_*
	do
		./retrieve_ensembl_var_annotations.R $ii "${ENSEMBL_VAR_ANNOTATIONS}_$i" ${ENSEMBL_VAR_ANNOTATIONS_START_FROM[$i]} > "${ENSEMBL_VAR_ANNOTATIONS_PROGRESS}_$i" &
		((i = i + 1))
	done
	wait
	to_join_ann=""
	for ((ii=0;ii<$i;ii++))
	do
		to_join_ann="${to_join_ann}${ENSEMBL_VAR_ANNOTATIONS}_$ii "		
	done
	cat $to_join_ann > $ENSEMBL_VAR_ANNOTATIONS
	date_end=$(date +"%s")
	diff=$(($date_end-$date_start))
	diff_total=$(($date_end-$date0))
	echo "STEP 2 - Obtaining ensembl variation annotations completed. Time: `time_diff $diff`. Total time: `time_diff $diff_total`."
fi

#STEP 3: Obtain associated genes ids
if [[ ${step[2]} == true ]]; then
	echo "STEP 3 - Obtaining associated genes ids started..."
	date_start=$(date +"%s")
	./retrieve_associated_genes_ids.sh $ENSEMBL_VAR_ANNOTATIONS $ASSOCIATED_GENES_IDS
	date_end=$(date +"%s")
	diff=$(($date_end-$date_start))
	diff_total=$(($date_end-$date0))
	echo "STEP 3 - Obtaining associated genes ids completed. Time: `time_diff $diff`. Total time: `time_diff $diff_total`."
fi

#STEP 4: Obtaining associated genes annotations
if [[ ${step[3]} == true ]]; then
	echo "STEP 4 - Obtaining associated genes annotations started..."
	date_start=$(date +"%s")
	(( lines = `wc -l $ASSOCIATED_GENES_IDS | cut -f 1 -d " "` / $THREADS ))
	rm -f ${ASSOCIATED_GENES_IDS}_*
	split -l $lines $ASSOCIATED_GENES_IDS "${ASSOCIATED_GENES_IDS}_"
	i=0
	for ii in ${ASSOCIATED_GENES_IDS}_*
	do
		./retrieve_ensembl_genes_annotations.R $ii "${ASSOCIATED_GENES_ANNOTATIONS}_$i" ${ENSEMBL_GENES_ANNOTATIONS_START_FROM[$i]} > "${ENSEMBL_GENES_ANNOTATIONS_PROGRESS}_$i" &
		((i = i + 1))
	done
	wait
	to_join_gene_ann=""
	for ((ii=0;ii<$i;ii++))
	do
		to_join_gene_ann="${to_join_gene_ann}${ASSOCIATED_GENES_ANNOTATIONS}_$ii "
	done	
	cat $to_join_gene_ann > $ASSOCIATED_GENES_ANNOTATIONS
	date_end=$(date +"%s")
	diff=$(($date_end-$date_start))
	diff_total=$(($date_end-$date0))
	echo "STEP 4 - Obtaining associated genes annotations completed. Time: `time_diff $diff`. Total time: `time_diff $diff_total`."
fi

#STEP 5: Downloading GET Evidence evidence.pgp-hms.org/download/latest/flat/latest-flat.tsv
if [[ ${step[4]} == true ]]; then
	echo "STEP 5 - Obtaining GET-evidence variant information started..."
	date_start=$(date +"%s")
	curl $GET_EVIDENCE_VAR_URL > $GET_EVIDENCE_VAR_INFO
	date_end=$(date +"%s")
	diff=$(($date_end-$date_start))
	diff_total=$(($date_end-$date0))
	echo "STEP 5 - Obtaining GET-evidence variant information completed. Time: `time_diff $diff`. Total time: `time_diff $diff_total`."
fi

#STEP 6: Preparing data for insertion to database
if [[ ${step[5]} == true ]]; then
	echo "STEP 6 - Preparing data for insertion to database..."
	date_start=$(date +"%s")
	./prepare_table_files.py $TABLE_VAR $TABLE_ANN $TABLE_VAR2ANN $TABLE_ANNDESC $TABLE_BACKSET $TABLE_ANN2BACK $TABLE_VAR2BACK $TABLES_COUNTS $ENSEMBL_VAR_ANNOTATIONS $ASSOCIATED_GENES_ANNOTATIONS $GET_EVIDENCE_VAR_INFO $BACKGROUND_SETS_DESCRIPTIONS $BACKGROUND_SETS_FOLDER  $TOP_ALLELES $MSIGDB_CONF $MSIGDB_HGNC_NOT_FOUND
	date_end=$(date +"%s")
	diff=$(($date_end-$date_start))
	diff_total=$(($date_end-$date0))
	echo "STEP 6 - Preparing data for insertion to database. Time: `time_diff $diff`. Total time: `time_diff $diff_total`."
fi

#STEP 7: Dropping existing database schema
if [[ ${step[6]} == true ]]; then
	echo "STEP 7 - Dropping existing database schema started..." 
	date_start=$(date +"%s")
	psql -w -h $DB_HOST -d $DB_NAME -U $DB_USER -f $DB_CLEAN
	date_end=$(date +"%s")
	diff=$(($date_end-$date_start))
	diff_total=$(($date_end-$date0))
	echo "STEP 7 - Dropping existing database schema completed. Time: `time_diff $diff`. Total time: `time_diff $diff_total`."
fi

#STEP 8: Creating database schema and inserting data
if [[ ${step[7]} == true ]]; then	
	echo "STEP 8 - Creating database schema and inserting data started..." 
	date_start=$(date +"%s")
	./db_init_schema_and_insert_data.sh $DB_HOST $DB_NAME $DB_USER $DB_INIT_AND_CREATE $TABLE_VAR $TABLE_ANN $TABLE_VAR2ANN $TABLE_ANNDESC $TABLE_BACKSET $TABLE_ANN2BACK $TABLE_VAR2BACK $TABLES_COUNTS
	date_end=$(date +"%s")
	diff=$(($date_end-$date_start))
	diff_total=$(($date_end-$date0))
	echo "STEP 8 - Creating database schema and inserting data completed. Time: `time_diff $diff`. Total time: `time_diff $diff_total`."
fi

