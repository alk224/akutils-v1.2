#!/usr/bin/env bash
#
#  OTU_table_slave.sh - build OTU tables in QIIME
#
#  Version 1.0.0 (November, 27, 2015)
#
#  Copyright (c) 2015 Andrew Krohn
#
#  This software is provided 'as-is', without any express or implied
#  warranty. In no event will the authors be held liable for any damages
#  arising from the use of this software.
#
#  Permission is granted to anyone to use this software for any purpose,
#  including commercial applications, and to alter it and redistribute it
#  freely, subject to the following restrictions:
#
#  1. The origin of this software must not be misrepresented; you must not
#     claim that you wrote the original software. If you use this software
#     in a product, an acknowledgment in the product documentation would be
#     appreciated but is not required.
#  2. Altered source versions must be plainly marked as such, and must not be
#     misrepresented as being the original software.
#  3. This notice may not be removed or altered from any source distribution.
#
#set -e
## Trap function on exit.
function finish {
if [[ -f $rawtables ]]; then
	rm $rawtables
fi
if [[ -f $initialtables ]]; then
	rm $initialtables
fi
if [[ -f $min100tables ]]; then
	rm $min100tables
fi
}
trap finish EXIT

## Define variables.
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=$(dirname $scriptdir)
	workdir=$(pwd)
	tempdir="$repodir/temp"
	stdout="$1"
	stderr="$2"
	log="$3"
	randcode="$4"
	taxfiles="$5"
	threads="$6"
	mode="$7"

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

## Temp files
	rawtables="$tempdir/${randcode}_rawtables.temp"
	initialtables="$tempdir/${randcode}_initialtables.temp"
	min100tables="$tempdir/${randcode}_min100tables.temp"

## Build OTU tables in parallel

	echo "Building OTU tables in parallel.
	"
	echo "Building OTU tables in parallel:" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log

	## Make initial otu table
	for line in `cat $taxfiles`; do
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		otudir=`dirname $(dirname $line)`
		taxtype=`echo $line | cut -d"/" -f2 | cut -d"_" -f1`
		tabledir="$otudir/OTU_tables_${taxtype}_taxonomy"
		logtemp="$tabledir/${randcode}_logtemp.txt"
		stdouttemp="$tabledir/${randcode}_stdout.txt"
		stderrtemp="$tabledir/${randcode}_stderr.txt"
		if [[ ! -d $tabledir ]]; then
			mkdir -p $tabledir
		fi

		if [[ ! -f $tabledir/raw_otu_table.biom ]]; then
		echo "make_otu_table.py -i $otudir/merged_otu_map.txt -t $line -o $tabledir/initial_otu_table.biom" >> $logtemp
		( make_otu_table.py -i $otudir/merged_otu_map.txt -t $line -o $tabledir/initial_otu_table.biom 1>$stderrtemp 2>$stdouttemp || true ) &
		cat $logtemp >> $log
		bash $scriptdir/log_slave.sh $stdouttemp $stderrtemp $log
		rm $stdouttemp $stderrtemp $logtemp 2>/dev/null
		fi
	done
	wait

## Make list of initial OTU tables
	find ./ -maxdepth 3 -mindepth 3 | grep "initial_otu_table.biom" > $initialtables

	## Ensure initial table is hdf5, change name to raw table
	for line in `cat $initialtables`; do
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		tabledir=$(dirname $line)
		logtemp="$tabledir/${randcode}_logtemp.txt"
		stdouttemp="$tabledir/${randcode}_stdout.txt"
		stderrtemp="$tabledir/${randcode}_stderr.txt"

		if [[ ! -f $tabledir/raw_otu_table.biom ]]; then
		echo "biom convert -i $line -o $tabledir/raw_otu_table.biom --table-type=\"OTU table\" --to-hdf5" >> $logtemp
		( biom convert -i $line -o $tabledir/raw_otu_table.biom --table-type="OTU table" --to-hdf5 1>$stderrtemp 2>$stdouttemp || true ) &
		cat $logtemp >> $log
		bash $scriptdir/log_slave.sh $stdouttemp $stderrtemp $log
		rm $stdouttemp $stderrtemp $logtemp 2>/dev/null
		fi
	done
	wait

## Make list of raw OTU tables
	find ./ -maxdepth 3 -mindepth 3 | grep "raw_otu_table.biom" > $rawtables

## Filter non-target taxa (ITS and 16S mode only)

	if [[ $mode == "16S" ]]; then
		echo "Filtering away non-prokaryotic sequences.
		"
		echo "Filtering away non-prokaryotic sequences:" >> $log
	for line in `cat $rawtables`; do
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		tabledir=$(dirname $line)
		logtemp="$tabledir/${randcode}_logtemp.txt"
		stdouttemp="$tabledir/${randcode}_stdout.txt"
		stderrtemp="$tabledir/${randcode}_stderr.txt"

		if [[ ! -f $tabledir/raw_otu_table_bacteria_only.biom ]]; then
		echo "filter_taxa_from_otu_table.py -i $tabledir/raw_otu_table.biom -o $tabledir/raw_otu_table_bacteria_only.biom -p k__Bacteria,k__Archaea" >> $logtemp
		( filter_taxa_from_otu_table.py -i $tabledir/raw_otu_table.biom -o $tabledir/raw_otu_table_bacteria_only.biom -p k__Bacteria,k__Archaea 1>$stderrtemp 2>$stdouttemp || true ) &
		cat $logtemp >> $log
		bash $scriptdir/log_slave.sh $stdouttemp $stderrtemp $log
		rm $stdouttemp $stderrtemp $logtemp 2>/dev/null
		fi
	done
	wait

	## Update list of raw tables to reflect 16S taxa filtering
	find ./ -maxdepth 3 -mindepth 3 | grep "raw_otu_table_bacteria_only.biom" > $rawtables
	fi

	if [[ $mode == "ITS" ]]; then
		echo "Filtering away non-fungal sequences.
		"
		echo "Filtering away non-fungal sequences:" >> $log
	for line in `cat $rawtables`; do
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		tabledir=$(dirname $line)
		logtemp="$tabledir/${randcode}_logtemp.txt"
		stdouttemp="$tabledir/${randcode}_stdout.txt"
		stderrtemp="$tabledir/${randcode}_stderr.txt"

		if [[ ! -f $tabledir/raw_otu_table_fungi_only.biom ]]; then
		echo "filter_taxa_from_otu_table.py -i $tabledir/raw_otu_table.biom -o $tabledir/raw_otu_table_fungi_only.biom -p k__Fungi" >> $logtemp
		( filter_taxa_from_otu_table.py -i $tabledir/raw_otu_table.biom -o $tabledir/raw_otu_table_fungi_only.biom -p k__Fungi 1>$stderrtemp 2>$stdouttemp || true ) &
		cat $logtemp >> $log
		bash $scriptdir/log_slave.sh $stdouttemp $stderrtemp $log
		rm $stdouttemp $stderrtemp $logtemp 2>/dev/null
		fi
	done
	wait

	## Update list of raw tables to reflect ITS taxa filtering
	find ./ -maxdepth 3 -mindepth 3 | grep "raw_otu_table_fungi_only.biom" > $rawtables
	fi

## Filter low count samples

	echo "Filtering away low count samples (<100 reads).
	"
	echo "Filtering away low count samples (<100 reads):" >> $log 
	for line in `cat $rawtables`; do
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		tabledir=$(dirname $line)
		logtemp="$tabledir/${randcode}_logtemp.txt"
		stdouttemp="$tabledir/${randcode}_stdout.txt"
		stderrtemp="$tabledir/${randcode}_stderr.txt"

		if [[ ! -f $tabledir/min100_table.biom ]]; then
		echo "filter_samples_from_otu_table.py -i $line -o $tabledir/min100_table.biom -n 100" >> $logtemp
		( filter_samples_from_otu_table.py -i $line -o $tabledir/min100_table.biom -n 100 1>$stderrtemp 2>$stdouttemp || true ) &
		cat $logtemp >> $log
		bash $scriptdir/log_slave.sh $stdouttemp $stderrtemp $log
		rm $stdouttemp $stderrtemp $logtemp 2>/dev/null
		fi
	done
	wait

	## Update list of raw tables to reflect ITS taxa filtering
	find ./ -maxdepth 3 -mindepth 3 | grep "min100_table.biom" > $min100tables

## Final filtering and normalizing steps
	echo "Final filtering and normalizing steps.
	"
	echo "Final filtering and normalizing steps:" >> $log

	for line in `cat $min100tables`; do
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		tabledir=$(dirname $line)
		if [[ ! -f $tabledir/n2_table_hdf5.biom ]]; then
		## filter singletons by sample
		( filter_observations_by_sample.py -i $tabledir/min100_table.biom -o $tabledir/n2_table0.biom -n 1 ;
		filter_otus_from_otu_table.py -i $tabledir/n2_table0.biom -o $tabledir/n2_table.biom -n 1 -s 2 ;
		biom convert -i $tabledir/n2_table.biom -o $tabledir/n2_table_hdf5.biom --table-type="OTU table" --to-hdf5 ; rm $tabledir/n2_table0.biom $tabledir/n2_table.biom 2>/dev/null ) &
		fi
	done
	wait

	for line in `cat $min100tables`; do
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		tabledir=$(dirname $line)
		if [[ ! -f $tabledir/n2_table_CSS.biom ]]; then
		## normalize singleton by sample-filtered tables
		( normalize_table.py -i $tabledir/n2_table_hdf5.biom -o $tabledir/n2_table_CSS.biom -a CSS >/dev/null 2>&1 || true ) &
		fi
	done
	wait

	for line in `cat $min100tables`; do
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		tabledir=$(dirname $line)
		if [[ ! -f $tabledir/mc2_table_hdf5.biom ]]; then
		## filter singletons by table
		( filter_otus_from_otu_table.py -i $tabledir/min100_table.biom -o $tabledir/mc2_table_hdf5.biom -n 2 -s 2 >/dev/null 2>&1 || true ) &
		fi
	done
	wait

	for line in `cat $min100tables`; do
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		tabledir=$(dirname $line)
		if [[ ! -f $tabledir/mc2_table_CSS.biom ]]; then
		## normalize singleton by table-filtered tables
		( normalize_table.py -i $tabledir/mc2_table_hdf5.biom -o $tabledir/mc2_table_CSS.biom -a CSS >/dev/null 2>&1 || true ) &
		fi
	done
	wait

	for line in `cat $min100tables`; do
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		tabledir=$(dirname $line)
		if [[ ! -f $tabledir/mc2_table_hdf5.biom ]]; then
		## filter tables by 0.005 percent
		( filter_otus_from_otu_table.py -i $tabledir/min100_table.biom -o $tabledir/005_table_hdf5.biom --min_count_fraction 0.00005 -s 2 >/dev/null 2>&1 || true ) &
		fi
	done
	wait

	for line in `cat $min100tables`; do
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		tabledir=$(dirname $line)
		if [[ ! -f $tabledir/mc2_table_CSS.biom ]]; then
		## normalize 0.005 percent-filtered tables
		( normalize_table.py -i $tabledir/005_table_hdf5.biom -o $tabledir/005_table_CSS.biom -a CSS >/dev/null 2>&1 || true ) &
		fi
	done
	wait

	for line in `cat $min100tables`; do
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		tabledir=$(dirname $line)
		if [[ ! -f $tabledir/n2_table_hdf5.biom ]]; then
		## filter at 0.3 percent by sample
		( filter_observations_by_sample.py -i $tabledir/min100_table.biom -o $tabledir/03_table0.biom -f -n 0.003 ;
		filter_otus_from_otu_table.py -i $tabledir/03_table0.biom -o $tabledir/03_table.biom -n 1 -s 2 ;
		biom convert -i $tabledir/03_table.biom -o $tabledir/03_table_hdf5.biom --table-type="OTU table" --to-hdf5 ; rm $tabledir/03_table0.biom $tabledir/03_table.biom 2>/dev/null ) &
		fi
	done
	wait

	for line in `cat $min100tables`; do
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		tabledir=$(dirname $line)
		if [[ ! -f $tabledir/n2_table_CSS.biom ]]; then
		## normalize 0.3 percent by sample-filtered tables
		( normalize_table.py -i $tabledir/03_table_hdf5.biom -o $tabledir/03_table_CSS.biom -a CSS >/dev/null 2>&1 || true ) &
		fi
	done
	wait

## Summarize raw otu tables

	for line in `cat $min100tables`; do
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		tabledir=$(dirname $line)
		biom-summarize_folder.sh $tabledir &>/dev/null
	done
	wait

echo "Table filtering complete.
"
echo "Table filtering complete.
" >> $log

exit 0
