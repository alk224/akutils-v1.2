#!/usr/bin/env bash
#
#  cdhit_slave.sh - pick otus with CD-HIT in QIIME
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

## Set variables
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=`dirname $scriptdir`
	workdir=$(pwd)
	stdout="$1"
	stderr="$2"
	log="$3"
	config="$4"
	resfile="$5"
	derepseqs="$6"
	seqs="$7"
	numseqs="$8"
	presufdir="$9"
	seqname="${10}"
	blasttax="${11}"
	rdptax="${12}"
	uclusttax="${13}"
	alltax="${14}"

	similaritycount=`cat $resfile | wc -l`
	cores=(`grep "CPU_cores" $config | grep -v "#" | cut -f 2`)
	refs=(`grep "Reference" $config | grep -v "#" | cut -f 2`)
	tax=(`grep "Taxonomy" $config | grep -v "#" | cut -f 2`)
	taxassigner=(`grep "Tax_assigner" $config | grep -v "#" | cut -f 2`)
	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)
	res1=$(date +%s.%N)

## Log and run commands

	echo "Beginning OTU picking (CD-HIT) at ${bold}$similaritycount${normal} similarity values.
	"
	echo "Beginning OTU picking (CD-HIT) at $similaritycount similarity values." >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log

for similarity in `cat $resfile`; do
	otupickdir="cdhit_otus_${similarity}"

	if [[ ! -f $otupickdir/derep_rep_set_otus.txt ]]; then
		res2=$(date +%s.%N)

		## Pick OTUs
		echo "Picking OTUs against collapsed rep set.
Input sequences: ${bold}$numseqs${normal}
Method: ${bold}CD-HIT (de novo)${normal}"
		echo "Picking OTUs against collapsed rep set." >> $log
		date "+%a %b %d %I:%M %p %Z %Y" >> $log
		echo "Input sequences: $numseqs" >> $log
		echo "Method: CD-HIT (de novo)" >> $log
		echo "Percent similarity: $similarity" >> $log
		echo "Percent similarity: ${bold}$similarity${normal}
		"
		echo "
	pick_otus.py -m cdhit -M 6000 -i $derepseqs -o $otupickdir -s $similarity
		" >> $log
		pick_otus.py -m cdhit -M 6000 -i $derepseqs -o $otupickdir -s $similarity 1>$stdout 2>$stderr
		bash $scriptdir/log_slave.sh $stdout $stderr $log

	#add "denovo" prefix to all OTU ids
	sed -i "s/^/denovo/" $otupickdir/derep_rep_set_otus.txt

		res3=$(date +%s.%N)
		dt=$(echo "$res3 - $res2" | bc)
		dd=$(echo "$dt/86400" | bc)
		dt2=$(echo "$dt-86400*$dd" | bc)
		dh=$(echo "$dt2/3600" | bc)
		dt3=$(echo "$dt2-3600*$dh" | bc)
		dm=$(echo "$dt3/60" | bc)
		ds=$(echo "$dt3-60*$dm" | bc)
		otu_runtime=`printf "CD-HIT OTU picking runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`	
		echo "$otu_runtime

		" >> $log
		else
		echo "CD-HIT OTU picking already completed ($similarity).
		"
	fi

	## Merge OTU maps
	if [[ ! -f $otupickdir/merged_otu_map.txt ]]; then
		echo "Merging OTU maps.
		"
		echo "Merging OTU maps:" >> $log
		date "+%a %b %d %I:%M %p %Z %Y" >> $log
		echo "
	merge_otu_maps.py -i ${presufdir}/${seqname}_otus.txt,${otupickdir}/derep_rep_set_otus.txt -o ${otupickdir}/merged_otu_map.txt
		" >> $log
		merge_otu_maps.py -i ${presufdir}/${seqname}_otus.txt,${otupickdir}/derep_rep_set_otus.txt -o ${otupickdir}/merged_otu_map.txt 1>$stdout 2>$stderr
		bash $scriptdir/log_slave.sh $stdout $stderr $log
		else
		echo "OTU maps already merged.
		"
	fi

	## Pick rep set
	if [[ ! -f $otupickdir/merged_rep_set.fna ]]; then
		echo "Picking rep set against merged OTU map.
		"
		echo "Picking rep set against merged OTU map:" >> $log
		date "+%a %b %d %I:%M %p %Z %Y" >> $log
		echo "
	pick_rep_set.py -i $otupickdir/merged_otu_map.txt -f $seqs -o $otupickdir/merged_rep_set.fna
		" >> $log
		pick_rep_set.py -i $otupickdir/merged_otu_map.txt -f $seqs -o $otupickdir/merged_rep_set.fna 1>$stdout 2>$stderr
		bash $scriptdir/log_slave.sh $stdout $stderr $log
		else
		echo "Merged rep set already completed.
		"
	fi
	repsetcount=`grep -e "^>" $otupickdir/merged_rep_set.fna | wc -l`
	echo "Identified ${bold}$repsetcount${normal} OTUs from ${bold}$numseqs${normal} input sequences.
	"
	echo "Identified $repsetcount OTUs from $numseqs input sequences.
	" >> $log

## Assign taxonomy

	## BLAST
	if [[ $blasttax == "blast" ]] || [[ $alltax == "ALL" ]]; then
		taxmethod="BLAST"
		taxdir="$otupickdir/blast_taxonomy_assignment"
		if [[ ! -f $taxdir/merged_rep_set_tax_assignments.txt ]]; then
			bash $scriptdir/blast_tax_slave.sh $stdout $stderr $log $cores $taxmethod $taxdir $otupickdir $refs $tax $repsetcount
		fi
	fi

	## RDP
	if [[ $rdptax == "rdp" ]] || [[ $alltax == "ALL" ]]; then
		taxmethod="RDP"
		taxdir="$otupickdir/rdp_taxonomy_assignment"
		if [[ ! -f $taxdir/merged_rep_set_tax_assignments.txt ]]; then
			bash $scriptdir/rdp_tax_slave.sh $stdout $stderr $log $cores $taxmethod $taxdir $otupickdir $refs $tax $repsetcount
		fi
	fi

	## UCLUST
	if [[ $uclusttax == "uclust" ]] || [[ $alltax == "ALL" ]]; then
		taxmethod="UCLUST"
		taxdir="$otupickdir/uclust_taxonomy_assignment"
		if [[ ! -f $taxdir/merged_rep_set_tax_assignments.txt ]]; then
			bash $scriptdir/uclust_tax_slave.sh $stdout $stderr $log $cores $taxmethod $taxdir $otupickdir $refs $tax $repsetcount
		fi
	fi
done

	res4=$(date +%s.%N)
	dt=$(echo "$res4 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)
	runtime=`printf "Total runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`

echo "Sequential OTU picking steps completed (CD-HIT).

$runtime
"
echo "---

Sequential OTU picking completed (CD-HIT)." >> $log
date "+%a %b %d %I:%M %p %Z %Y" >> $log
echo "
$runtime 
" >> $log

exit 0
