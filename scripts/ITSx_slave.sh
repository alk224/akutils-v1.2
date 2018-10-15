#!/usr/bin/env bash
#
#  ITSx_slave.sh - ITSx searches amid QIIME workflow
#
#  Version 1.0.0 (November, 27, 2015)
#
#  Copyright (c) 2015-- Lela Andrews
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
	cores="$4"
	seqs="$5"
	numseqs="$6"
	config="$7"
	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)
	res1=$(date +%s.%N)
	itsx_options=`grep "ITSx_options" $config | grep -v "#" | cut -f 2-`

## Log and run command
	echo "Screening sequences for ITS HMMer profiles with ITSx on ${bold}$cores${normal} cores.
Input sequences: ${bold}$numseqs${normal}
	"
	echo "
ITSx command:" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	echo "
	ITSx_parallel.sh $seqs $cores $itsx_options
	" >> $log
	ITSx_parallel.sh $seqs $cores $itsx_options 1>$stdout 2>$outdir/ITSx_log.txt
	bash $scriptdir/log_slave.sh $stdout $stderr $log

	seqs="split_libraries/seqs_chimera_filtered_ITSx_filtered.fna"
	ITSseqs=`grep -e "^>" $seqs | wc -l`

	if [[ ! -s $seqs ]]; then
	echo "ITSx step failed to identify any ITS profiles.  Check your data and try
again.  Exiting.
	"
	echo "ITSx step failed to identify any ITS profiles.  Check your data and try
again.  Exiting.
	" >> $log
	exit 1	
	fi

	echo "Identified ${bold}$ITSseqs${normal} ITS-containing sequences from ${bold}$numseqs${normal} input reads.
	"
	echo "Identified $ITSseqs ITS-containing sequences from $numseqs input reads.
	" >> $log

	res2=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)

	itsx_runtime=`printf "ITSx runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`	
	echo "$itsx_runtime

	" >> $log

exit 0
