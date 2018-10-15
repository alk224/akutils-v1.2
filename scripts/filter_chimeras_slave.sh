#!/usr/bin/env bash
#
#  filter_chimeras_slave.sh - filter chimeras in QIIME
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
	chimera_refs="$5"
	numseqs="$6"
	chimbase=$(basename $chimera_refs)
	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)
	res1=$(date +%s.%N)

## Determine filtering mode
	if [[ "$chimbase" == "denovo" ]]; then
	uchime_mode="denovo"
	elif [[ ! -z "$chimbase" ]]; then
	uchime_mode="ref"
	fi

## Log and run command (ref)
if [[ "$uchime_mode" == "ref" ]]; then
	echo "Filtering chimeras.
Method: ${bold}vsearch${normal} (uchime_ref)
Reference: ${bold}$chimbase${normal}
Threads: ${bold}$cores${normal}
Input sequences: ${bold}$numseqs${normal}
"
	echo "
Chimera filtering commands:" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	echo "Method: vsearch (uchime_ref)
Reference: $chimera_refs
Threads: $cores
Input sequences: $numseqs
	" >> $log

	echo "	vsearch --uchime_ref $outdir/seqs.fna --db $chimera_refs --threads $cores --nonchimeras $outdir/vsearch_nonchimeras.fna
" >> $log

	`vsearch --uchime_ref $outdir/seqs.fna --db $chimera_refs --threads $cores --nonchimeras $outdir/vsearch_nonchimeras.fna 1>$stdout 2>$outdir/vsearch_log.txt`
	bash $scriptdir/log_slave.sh $stdout $stderr $log

	#unwrap output
	unwrap_fasta.sh $outdir/vsearch_nonchimeras.fna $outdir/seqs_chimera_filtered.fna
fi

## Log and run command (denovo)
if [[ "$uchime_mode" == "denovo" ]]; then
	echo "Filtering chimeras.
Method: ${bold}vsearch${normal} (uchime_denovo)
Reference: ${bold}$chimbase${normal}
Threads: ${bold}$cores${normal}
Input sequences: ${bold}$numseqs${normal}
"
	echo "
Chimera filtering commands:" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	echo "Method: vsearch (uchime_denovo)
Reference: $chimera_refs
Threads: $cores
Input sequences: $numseqs
	" >> $log

	echo "	vsearch --uchime_denovo $outdir/seqs.fna --threads $cores --nonchimeras $outdir/vsearch_nonchimeras.fna
" >> $log

	`vsearch --uchime_denovo $outdir/seqs.fna --threads $cores --nonchimeras $outdir/vsearch_nonchimeras.fna 1>$stdout 2>$outdir/vsearch_log.txt`
	bash $scriptdir/log_slave.sh $stdout $stderr $log

	#unwrap output
	unwrap_fasta.sh $outdir/vsearch_nonchimeras.fna $outdir/seqs_chimera_filtered.fna
fi

## Count results
	chimeracount1=$(cat $outdir/seqs_chimera_filtered.fna | wc -l)
	chimeracount2=$(echo "$chimeracount1 / 2" | bc)
	seqcount1=$(cat $outdir/seqs.fna | wc -l)
	seqcount=$(echo "$seqcount1 / 2" | bc)
	chimeracount=$(echo "$seqcount - $chimeracount2" | bc)

	echo "Identified ${bold}$chimeracount${normal} chimeric sequences from ${bold}$seqcount${normal} input reads.
	"
	echo "Identified $chimeracount chimeric sequences from $seqcount
input reads.
	" >> $log

	wait
	rm $outdir/vsearch_nonchimeras.fna

	res2=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)

	chim_runtime=`printf "Chimera filtering runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`	
	echo "$chim_runtime
	" >> $log

exit 0
