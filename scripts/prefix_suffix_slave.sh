#!/usr/bin/env bash
#
#  prefix_suffix_slave.sh - dereplicate sequences in QIIME
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
	prefix_len="$4"
	suffix_len="$5"
	presufdir="$6"
	seqs="$7"
	numseqs="$8"
	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)
	res1=$(date +%s.%N)

## Log and run command

	echo "Dereplicating $numseqs sequences with prefix/suffix picker.
Input sequences: ${bold}$numseqs${normal}
Prefix length: ${bold}$prefix_len${normal}
Suffix length: ${bold}$suffix_len${normal}
	"
	echo "Dereplicating $numseqs sequences with prefix/suffix picker." >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	echo "Input sequences: $numseqs
Prefix length: $prefix_len
Suffix length: $suffix_len" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	echo "
	pick_otus.py -m prefix_suffix -p $prefix_len -u $suffix_len -i $seqs -o $presufdir	
	" >> $log
	pick_otus.py -m prefix_suffix -p $prefix_len -u $suffix_len -i $seqs -o $presufdir 1>$stdout 2>$stderr
	bash $scriptdir/log_slave.sh $stdout $stderr $log

	res2=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)
	pref_runtime=`printf "Prefix/suffix dereplication runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`	
	echo "$pref_runtime

	" >> $log

exit 0
