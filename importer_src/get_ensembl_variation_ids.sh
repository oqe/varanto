# Retrieves and saves list of Ensembl variation identifiers. Remember to check/update to latest database version before running.
if [[ $3 == 0 ]]; then
	mysql -u anonymous -h ensembldb.ensembl.org -e "SELECT DISTINCT name FROM $1" > $2
else
	mysql -u anonymous -h ensembldb.ensembl.org -e "SELECT DISTINCT name FROM $1 LIMIT $3" > $2
fi
