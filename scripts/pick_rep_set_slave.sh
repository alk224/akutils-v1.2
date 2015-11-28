#!/usr/bin/env bash
#
#  pick_rep_set_slave.sh - pick representative sequences in QIIME
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
set -e

## Set variables
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=`dirname $scriptdir`
	workdir=$(pwd)
	stdout="$1"
	stderr="$2"
	log="$3"
	otus="$4"
	seqs="$5"
	outseqs="$6"
	numseqs="$7"
	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)
	res1=$(date +%s.%N)

## Log and run command
	echo "Picking rep set with prefix/suffix-collapsed OTU map.
	"
	echo "Picking rep set with prefix/suffix-collapsed OTU map:" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	echo "
	pick_rep_set.py -i $otus -f $seqs -o $outseqs
	" >> $log
	pick_rep_set.py -i $otus -f $seqs -o $outseqs 1>$stdout 2>$stderr
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	numseqs1=`grep -e "^>" $outseqs | wc -l`
	echo "Dereplicated from ${bold}$numseqs${normal} to ${bold}$numseqs1${normal} sequences.
	"

	res2=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)
	repset_runtime=`printf "Pick rep set runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`	
	echo "$repset_runtime

	" >> $log

exit 0
