#! /bin/bash

set -e #check for failed commands
set -u #check for unbound variables

DB_HOST=$1
DB_NAME=$2
DB_USER=$3
DB_INIT_AND_CREATE=$4
TABLE_VAR=$5
TABLE_ANN=$6
TABLE_VAR2ANN=$7
TABLE_ANNDESC=$8
TABLE_BACKSET=$9
TABLE_ANN2BACK=${10}
TABLE_VAR2BACK=${11}
TABLES_COUNTS=${12}

##function for echo of time difference
function time_diff {
	days="$(($1 / 86400))d"
	hours="$(($1 / 3600 % 24))"
	minutes="$(($1 / 60 % 60))"
	seconds="$(($1 % 60))"
	echo "$days $(($hours / 10))$(($hours % 10)):$(($minutes / 10))$(($minutes % 10)):$(($seconds / 10))$(($seconds % 10))"
}
date0=$(date +"%s")

psql -w -h $DB_HOST -d $DB_NAME -U $DB_USER -f ../db/db_schema_init_without_constraints.sql

echo "COPY VARIATIONS"
date_start=$(date +"%s")
cat $TABLE_VAR | psql -h $DB_HOST -d $DB_NAME -U $DB_USER -c "COPY variation FROM STDIN WITH ENCODING 'LATIN1'" -w
date_end=$(date +"%s")
diff=$(($date_end-$date_start))
diff_total=$(($date_end-$date0))
SIZE=$(du -sh $TABLE_VAR | cut -f1)
echo "Inserting data - COPY VARIATIONS ($SIZE) completed. Time: `time_diff $diff`. Total time: `time_diff $diff_total`."

echo "COPY ANNOTATIONS"
date_start=$(date +"%s")
cat $TABLE_ANN | psql -h $DB_HOST -d $DB_NAME -U $DB_USER -c "COPY annotation FROM STDIN WITH ENCODING 'LATIN1'" -w
date_end=$(date +"%s")
diff=$(($date_end-$date_start))
diff_total=$(($date_end-$date0))
SIZE=$(du -sh $TABLE_ANN | cut -f1)
echo "Inserting data - COPY ANNOTATIONS ($SIZE) completed. Time: `time_diff $diff`. Total time: `time_diff $diff_total`."

echo "COPY VAR2ANN"
date_start=$(date +"%s")
cat $TABLE_VAR2ANN | psql -h $DB_HOST -d $DB_NAME -U $DB_USER -c "COPY var2ann FROM STDIN WITH ENCODING 'LATIN1'" -w
date_end=$(date +"%s")
diff=$(($date_end-$date_start))
diff_total=$(($date_end-$date0))
SIZE=$(du -sh $TABLE_VAR2ANN | cut -f1)
echo "Inserting data - COPY VAR2ANN ($SIZE) completed. Time: `time_diff $diff`. Total time: `time_diff $diff_total`."

echo "COPY ANNOTATION_DESCRIPTION"
date_start=$(date +"%s")
cat $TABLE_ANNDESC | psql -h $DB_HOST -d $DB_NAME -U $DB_USER -c "COPY annotation_description FROM STDIN WITH ENCODING 'UTF-8'" -w
date_end=$(date +"%s")
diff=$(($date_end-$date_start))
diff_total=$(($date_end-$date0))
SIZE=$(du -sh $TABLE_ANNDESC | cut -f1)
echo "Inserting data - COPY ANNOTATION_DESCRIPTION ($SIZE) completed. Time: `time_diff $diff`. Total time: `time_diff $diff_total`."

echo "COPY BACKGROUND_SETS"
cat $TABLE_BACKSET | psql -h $DB_HOST -d $DB_NAME -U $DB_USER -c "COPY background_sets FROM STDIN WITH ENCODING 'LATIN1'" -w
date_end=$(date +"%s")
diff=$(($date_end-$date_start))
diff_total=$(($date_end-$date0))
SIZE=$(du -sh $TABLE_BACKSET | cut -f1)
echo "Inserting data - COPY BACKGROUND_SETS ($SIZE) completed. Time: `time_diff $diff`. Total time: `time_diff $diff_total`."

echo "COPY ANN2BACK_SET"
date_start=$(date +"%s")
cat $TABLE_ANN2BACK | psql -h $DB_HOST -d $DB_NAME -U $DB_USER -c "COPY ann2back_set FROM STDIN WITH ENCODING 'LATIN1'" -w
date_end=$(date +"%s")
diff=$(($date_end-$date_start))
diff_total=$(($date_end-$date0))
SIZE=$(du -sh $TABLE_ANN2BACK | cut -f1)
echo "Inserting data - COPY ANN2BACK_SET ($SIZE) completed. Time: `time_diff $diff`. Total time: `time_diff $diff_total`."

echo "COPY VAR2BACK_SET"
date_start=$(date +"%s")
cat $TABLE_VAR2BACK | psql -h $DB_HOST -d $DB_NAME -U $DB_USER -c "COPY var2back_set FROM STDIN WITH ENCODING 'LATIN1'" -w
date_end=$(date +"%s")
diff=$(($date_end-$date_start))
diff_total=$(($date_end-$date0))
SIZE=$(du -sh $TABLE_VAR2BACK | cut -f1)
echo "Inserting data - COPY VAR2BACK_SET ($SIZE) completed. Time: `time_diff $diff`. Total time: `time_diff $diff_total`."

echo "SETTING PRIMARY AND FOREIGN KEYS AND GENERATING INDEXES"
date_start=$(date +"%s")
psql -w -h $DB_HOST -d $DB_NAME -U $DB_USER -f ../db/db_init_constraints.sql -v var_cnt=`awk '{print $1}' $TABLES_COUNTS` -v ann_cnt=`awk '{print $2}' $TABLES_COUNTS` -v ann_desc_cnt=`awk '{print $3}' $TABLES_COUNTS` -v back_set_cnt=`awk '{print $4}' $TABLES_COUNTS`
date_end=$(date +"%s")
diff=$(($date_end-$date_start))
diff_total=$(($date_end-$date0))
echo "Setting primary and foreign keys and generating indexes completed. Time: `time_diff $diff`. Total time: `time_diff $diff_total`."

