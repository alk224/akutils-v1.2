#!/usr/bin/env bash
#
#  split_libraries_slave.sh - split libraries in QIIME
#
#  Version 1.0.0 (November, 15, 2015)
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
set -e

## Set variables
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=`dirname $scriptdir`
	workdir=$(pwd)
	outdir="$workdir/split_libraries"
	stdout="$1"
	stderr="$2"
	log="$3"
	qvalue="$4"
	minpercent="$5"
	maxbad="$6"
	barcodetype="$7"
	map="$8"
	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)
	res1=$(date +%s.%N)

## Log and run command
	echo "Performing split_libraries_fastq.py command.
Minimum q-score: ${bold}$qvalue${normal}
Minimum read percent: ${bold}$minpercent${normal}
Maximum bad reads: ${bold}$maxbad${normal}
Autodetect index length: ${bold}$barcodetype${normal}"

	echo "Split libraries command:" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	echo "Minimum q-score: $qvalue
Minimum read percent: $minpercent
Maximum bad reads: $maxbad
Autodetect index length: $barcodetype
	split_libraries_fastq.py -i rd.fq -b idx.fq -m $map -o $outdir -q $qvalue --barcode_type $barcodetype -p $minpercent -r $maxbad
	" >> $log

	split_libraries_fastq.py -i rd.fq -b idx.fq -m $map -o $outdir -q $qvalue --barcode_type $barcodetype -p $minpercent -r $maxbad 1>$stdout 2>$stderr || true
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	seqs="$outdir/seqs.fna"
	numseqs=`grep -e "^>" $seqs | wc -l`

	res2=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)
	sl_runtime=`printf "Split libraries runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "$sl_runtime
	" >> $log

	echo "Split libraries demultiplexed ${bold}$numseqs${normal} reads from your data.
	"
	echo "Split libraries demultiplexed $numseqs reads from your data.
	" >> $log

## Check for success
	if [[ ! -s $outdir/seqs.fna ]]; then
		echo "
Split libraries step seems to not have identified any samples based on
the indexing data you supplied.  You should check your list of indexes
and try again.  Do they need to be reverse-complemented?
		"
		echo "
Split libraries step seems to not have identified any samples based on
the indexing data you supplied.  You should check your list of indexes
and try again.  Do they need to be reverse-complemented?
		" >> $log
		exit 1
	fi

exit 0
