#!/usr/bin env

## norm_tables.sh to produce normalized tables in parallel from a list of inputs

## Define variables
	stdout="$1"
	stderr="$2"
	log="$3"
	tablelist="$4"
	threads="$5"


	for table in `cat $tablelist`; do
	while [ $( pgrep -P $$ | wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
		tabledir=$(dirname $table)
		tablebase=$(basename $table .biom)
		if [[ ! -f $tabledir/${tablebase}_CSS.biom ]]; then
		echo "Normalizing $tablebase by CSS transformation."
		( normalize_table.py -i $table -o $tabledir/${tablebase}_CSS.biom -a CSS ) &
		fi		
	done

	for table in `cat $tablelist`; do
	while [ $( pgrep -P $$ | wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
		tabledir=$(dirname $table)
		tablebase=$(basename $table .biom)
		if [[ ! -f $tabledir/${tablebase}_DESeq2.biom ]]; then
		echo "Normalizing $tablebase by DESeq2 transformation."
		( normalize_table.py -i $table -o $tabledir/${tablebase}_DESeq2.biom -a DESeq2 ) &
		fi
		
	done

exit 0
