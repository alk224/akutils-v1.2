#!/usr/bin/env bash
#
#  pick_otus.sh - take raw fastq data to an otu table
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
#set -e
## Trap function on exit.
function finish {
if [[ -f $otupicklist ]]; then
	rm $otupicklist
fi
if [[ -f $taxassignlist ]]; then
	rm $taxassignlist
fi
if [[ -f $swarmtemp ]]; then
	rm $swarmtemp
fi
if [[ -f $percenttemp ]]; then
	rm $percenttemp
fi
if [[ -f $otupickdirs ]]; then
	rm $otupickdirs
fi
if [[ -f $taxfiles ]]; then
	rm $taxfiles
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
	randcode="$3"
	mode="$4"
	date0=$(date +%Y%m%d_%I%M%p)
	res0=$(date +%s.%N)

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

## Define temp files
	otupicklist="$tempdir/${randcode}_otupickers.temp"
	taxassignlist="$tempdir/${randcode}_taxassigners.temp"
	swarmtemp="$tempdir/${randcode}_swarm_resolutions.temp"
	percenttemp="$tempdir/${randcode}_percent_identities.temp"
	otupickdirs="$tempdir/${randcode}_otupicking_directories.temp"
	taxfiles="$tempdir/${randcode}_taxassign_directories.temp"
	touch $stdout
	touch $stderr

## ID config file.
	config=$(bash $scriptdir/config_id.sh)

## Check for valid mode setting.  Display usage if error.
	if [[ "$mode" != "other" ]] && [[ "$mode" != "16S" ]] && [[ "$mode" != "ITS" ]]; then
	echo "
Invalid mode entered. Valid modes are 16S, ITS or other."
	cat $repodir/docs/pick_otus.usage
	exit 1
	fi

## Find log file or set new one.
	rm log_pick_otus*~ 2>/dev/null
	logcount=$(ls log_pick_otus* 2>/dev/null | head -1 | wc -l)
	if [[ "$logcount" -eq 1 ]]; then
		log=`ls log_pick_otus*.txt | head -1`
	elif [[ "$logcount" -eq 0 ]]; then
		log="$workdir/log_pick_otus_$date0.txt"
	fi
	echo "
${bold}akutils pick_otus workflow beginning.${normal}
	"
	echo "
akutils pick_otus workflow beginning." >> $log
	date >> $log

## Read in variables from config file
	refs=(`grep "Reference" $config | grep -v "#" | cut -f 2`)
	tax=(`grep "Taxonomy" $config | grep -v "#" | cut -f 2`)
	tree=(`grep "Tree" $config | grep -v "#" | cut -f 2`)
	chimera_refs=(`grep "Chimeras" $config | grep -v "#" | cut -f 2`)
#	seqs=($outdir/split_libraries/seqs_chimera_filtered.fna)
	alignment_template=(`grep "Alignment_template" $config | grep -v "#" | cut -f 2`)
	alignment_lanemask=(`grep "Alignment_lanemask" $config | grep -v "#" | cut -f 2`)
	revcomp=(`grep "RC_seqs" $config | grep -v "#" | cut -f 2`)
	seqs=($outdir/split_libraries/seqs.fna)
	CPU_cores=(`grep "CPU_cores" $config | grep -v "#" | cut -f 2`)
	itsx_threads=($CPU_cores)
	itsx_options=`grep "ITSx_options" $config | grep -v "#" | cut -f 2-`
	slqual=(`grep "Split_libraries_qvalue" $config | grep -v "#" | cut -f 2`)
	slminpercent=(`grep "Split_libraries_minpercent" $config | grep -v "#" | cut -f 2`)
	slmaxbad=(`grep "Split_libraries_maxbad" $config | grep -v "#" | cut -f 2`)
	min_overlap=(`grep "Min_overlap" $config | grep -v "#" | cut -f 2`)
	max_mismatch=(`grep "Max_mismatch" $config | grep -v "#" | cut -f 2`)
	mcf_threads=($CPU_cores)
	phix_index=(`grep "PhiX_index" $config | grep -v "#" | cut -f 2`)
	smalt_threads=($CPU_cores)
	multx_errors=(`grep "Multx_errors" $config | grep -v "#" | cut -f 2`)
	rdp_confidence=(`grep "RDP_confidence" $config | grep -v "#" | cut -f 2`)
	rdp_max_memory=(`grep "RDP_max_memory" $config | grep -v "#" | cut -f 2`)
	prefix_len=(`grep "Prefix_length" $config | grep -v "#" | cut -f 2`)
	suffix_len=(`grep "Suffix_length" $config | grep -v "#" | cut -f 2`)
	otupicker=(`grep "OTU_picker" $config | grep -v "#" | cut -f 2`)
	taxassigner=(`grep "Tax_assigner" $config | grep -v "#" | cut -f 2`)
	cores="$CPU_cores"
	threads=$(($cores-1))

## Make OTU picker and taxonomy assigner temp files
	OIFS=$IFS
	IFS=','
		for x in $otupicker; do
		echo $x >> $otupicklist
		done

		for x in $taxassigner; do
		echo $x >> $taxassignlist
		done
	IFS=$OIFS
	
## Set OTU picker and tax assigner variables
	swarmpick=`grep "swarm" $otupicklist`
	if [[ -z $swarmpick ]]; then
	swarmpick="0"
	fi
	blastpick=`grep "blast" $otupicklist`
	if [[ -z $blastpick ]]; then
	blastpick="0"
	fi
	cdhitpick=`grep "cdhit" $otupicklist`
	if [[ -z $cdhitpick ]]; then
	cdhitpick="0"
	fi
	openrefpick=`grep "openref" $otupicklist`
	if [[ -z $openrefpick ]]; then
	openrefpick="0"
	fi
	custopenrefpick=`grep "custom_openref" $otupicklist`
	if [[ -z $custopenrefpick ]]; then
	custopenrefpick="0"
	fi
	allpick=`grep "ALL" $otupicklist`
	if [[ -z $allpick ]]; then
	allpick="0"
	fi

	blasttax=`grep "blast" $taxassignlist`
	if [[ -z $blasttax ]]; then
	blasttax="0"
	fi
	rdptax=`grep "rdp" $taxassignlist`
	if [[ -z $rdptax ]]; then
	rdptax="0"
	fi
	uclusttax=`grep "uclust" $taxassignlist`
	if [[ -z $uclusttax ]]; then
	uclusttax="0"
	fi
	alltax=`grep "ALL" $taxassignlist`
	if [[ -z $alltax ]]; then
	alltax="0"
	fi

## Check that no more than one parameter file is present
	parameter_count=(`ls $outdir/parameter* 2>/dev/null | wc -w`)
	if [[ $parameter_count -ge 2 ]]; then
	echo "
No more than one parameter file can reside in your working
directory.  Presently, there are $parameter_count such files.  
Move or rename all but one of these files and restart the
workflow.  A parameter file is any file in your working
directory that starts with \"parameter\".  See --help for
more details.

Exiting.
	"
		exit 1
	elif [[ $parameter_count == 1 ]]; then
		param_file=(`ls $outdir/parameter*`)
	echo "
Found parameters file.
$param_file
	"
	echo "Using custom parameters file.
$outdir/$param_file

Parameters file contents:" >> $log
	cat $param_file >> $log
	elif [[ $parameter_count == 0 ]]; then
	echo "
No parameters file found.  Running with default settings.
	"
	echo "No parameter file found.  Using default settings.
	" >> $log
	fi

## Check that no more than one mapping file is present
	map_count=(`ls $workdir/map* | wc -w`)
	if [[ $map_count -ge 2 || $map_count == 0 ]]; then
	echo "
This workflow requires a mapping file.  No more than one mapping file 
can reside in your working directory.  Presently, there are $map_count such
files.  Move or rename all but one of these files and restart the 
workflow.  A mapping file is any file in your working directory that starts
with \"map\".  It should be properly formatted for QIIME processing.

Exiting.
	"	
		exit 1
	else
		map=(`ls $workdir/map*`)
		echo "Mapping file: $map" >> $log	
	fi
	echo "" >> $log

## Check for split_libraries outputs and inputs
	if [[ -f split_libraries/seqs.fna ]]; then
	seqs="split_libraries/seqs.fna"
	numseqs=`grep -e "^>" $seqs | wc -l`
	echo "Split libraries output detected ($numseqs sequences).
	"
	echo "Split libraries output detected ($numseqs sequences).
	" >> $log
	else
	echo "Split libraries needs to be completed.
Checking for fastq files.
	"
		if [[ ! -f idx.fq ]]; then
		echo "Index file not present (./idx.fq). Correct this error by renaming your
index file as idx.fq and ensuring it resides within this directory.
		"
		exit 1
		fi

		if [[ ! -f rd.fq ]]; then
		echo "
Sequence read file not present (./rd.fq).  Correct this error by
renaming your read file as rd.fq and ensuring it resides within this
directory.
		"
		exit 1
		fi
	fi

## Call split libraries function and set variables as necessary
	if [[ ! -f split_libraries/seqs.fna ]]; then
		if [[ $slqual == "" ]]; then 
		qual="19"
		else
		qual="$slqual"
		fi
		if [[ $slminpercent == "" ]]; then
		minpercent="0.95"
		else
		minpercent="$slminpercent"
		fi
		if [[ $slmaxbad == "" ]]; then 
		maxbad="0"
		else
		maxbad="$slmaxbad"
		fi
		barcodetype=$((`sed '2q;d' idx.fq | egrep "\w+" | wc -m`-1))
		qvalue=$((qual+1))

	bash $scriptdir/split_libraries_slave.sh $stdout $stderr $log $qvalue $minpercent $maxbad $barcodetype $map
	fi
	seqs="split_libraries/seqs.fna"
	numseqs=`grep -e "^>" $seqs | wc -l`

## Call chimera filtering function and set variables as necessary
	if [[ $chimera_refs != "undefined" ]] || [[ -z $chimera_refs ]]; then
	if [[ ! -f split_libraries/seqs_chimera_filtered.fna ]]; then
	bash $scriptdir/filter_chimeras_slave.sh $stdout $stderr $log $CPU_cores $chimera_refs $numseqs
		else
		if [[ -s split_libraries/seqs_chimera_filtered.fna ]]; then
		seqs="split_libraries/seqs_chimera_filtered.fna"
		numseqs=`grep -e "^>" $seqs | wc -l`
		fi
		echo "Chimera-filtered sequences detected ($numseqs sequences).
	"
		echo "Chimera-filtered sequences detected ($numseqs sequences).
	" >> $log
	fi
		else echo "No chimera reference collection supplied.
Skipping chimera checking step.
	"
	fi

## ITSx filtering (mode ITS only)
	if [[ $mode == "ITS" ]]; then
	seqbase=`basename $seqs .fna`
	if [[ -f split_libraries/${seqbase}_ITSx_filtered.fna ]]; then
		if [[ -s split_libraries/seqs_chimera_filtered_ITSx_filtered.fna ]]; then
		seqs="split_libraries/seqs_chimera_filtered_ITSx_filtered.fna"
		numseqs=`grep -e "^>" $seqs | wc -l`
		echo "ITSx filtered sequences detected. ($numseqs sequences).
		"
		echo "ITSx filtered sequences detected. ($numseqs sequences).
		" >> $log
		fi
	else
	bash $scriptdir/ITSx_slave.sh $stdout $stderr $log $CPU_cores $seqs $numseqs $config

	seqs="split_libraries/seqs_chimera_filtered_ITSx_filtered.fna"
	ITSseqs=`grep -e "^>" $seqs | wc -l`
	fi
	seqs="split_libraries/seqs_chimera_filtered_ITSx_filtered.fna"
	if [[ ! -s $seqs ]]; then
	exit 1
	fi
	fi

## Dereplicate sequences with prefix/suffix collapser
	presufdir="prefix${prefix_len}_suffix${suffix_len}"
	seqpath="${seqs%.*}"
	seqname=`basename $seqpath`

	if [[ ! -f ${presufdir}/${seqname}_otus.txt ]]; then
	bash $scriptdir/prefix_suffix_slave.sh $stdout $stderr $log $prefix_len $suffix_len $presufdir $seqs $numseqs
	otus="${presufdir}/${seqname}_otus.txt"
	else
	echo "Dereplication with prefix/suffix picker previously completed.
	"
	echo "Dereplication with prefix/suffix picker previously completed.
	" >> $log
	otus="${presufdir}/${seqname}_otus.txt"
	fi

## Pick rep set against dereplicated OTU file
	derepseqs="$presufdir/derep_rep_set.fasta"
	if [[ ! -f $derepseqs ]]; then
	bash $scriptdir/pick_rep_set_slave.sh $stdout $stderr $log $otus $seqs $derepseqs $numseqs

	else
	echo "Dereplicated rep set already present.
	"
	echo "Dereplicated rep set already present.
	" >> $log
	fi
	numseqs=`grep -e "^>" $derepseqs | wc -l`

################################
## SWARM OTU Steps BEGIN HERE ##
################################

## Define otu picking parameters ahead of outdir naming

if [[ $swarmpick == "swarm" || $allpick == "ALL" ]]; then
	otumethod="Swarm"

	if [[ $parameter_count == 1 ]]; then
		grep "swarm_resolution" $param_file | cut -d " " -f2 | sed '/^$/d' > $swarmtemp
	else
		echo 1 > $swarmtemp
	fi

	resolutioncount=`cat $swarmtemp | wc -l`
	if [[ $resolutioncount == 0 ]]; then
		echo 1 > $swarmtemp
	fi

	bash $scriptdir/swarm_slave.sh $stdout $stderr $log $config $swarmtemp $derepseqs $seqs $numseqs $presufdir $seqname $blasttax $rdptax $uclusttax $alltax
fi

################################
## BLAST OTU Steps BEGIN HERE ##
################################

## Define otu picking parameters ahead of outdir naming

if [[ $blastpick == "blast" || $allpick == "ALL" ]]; then
	otumethod="BLAST"

	if [[ $parameter_count == 1 ]]; then
		grep "similarity" $param_file | cut -d " " -f2 | sed '/^$/d' > $percenttemp
	else
		echo "0.97" > $percenttemp
	fi

	similaritycount=`cat $percenttemp | wc -l`
	if [[ $similaritycount == 0 ]]; then
		echo "0.97" > $percenttemp
	fi

	bash $scriptdir/blast_slave.sh $stdout $stderr $log $config $percenttemp $derepseqs $seqs $numseqs $presufdir $seqname $blasttax $rdptax $uclusttax $alltax
fi

################################
## CDHIT OTU Steps BEGIN HERE ##
################################

## Define otu picking parameters ahead of outdir naming

if [[ $cdhitpick == "cdhit" || $allpick == "ALL" ]]; then
	otumethod="CD-HIT"

	if [[ $parameter_count == 1 ]]; then
		grep "similarity" $param_file | cut -d " " -f2 | sed '/^$/d' > $percenttemp
	else
		echo "0.97" > $percenttemp
	fi

	similaritycount=`cat $percenttemp | wc -l`
	if [[ $similaritycount == 0 ]]; then
		echo "0.97" > $percenttemp
	fi

	bash $scriptdir/cdhit_slave.sh $stdout $stderr $log $config $percenttemp $derepseqs $seqs $numseqs $presufdir $seqname $blasttax $rdptax $uclusttax $alltax
fi

##################################
## Openref OTU Steps BEGIN HERE ##
##################################

## Define otu picking parameters ahead of outdir naming

if [[ $openrefpick == "openref" || $allpick == "ALL" ]]; then
	otumethod="OpenRef"
echo yes
	if [[ $parameter_count == 1 ]]; then
		grep "similarity" $param_file | cut -d " " -f2 | sed '/^$/d' > $percenttemp
	else
		echo "0.97" > $percenttemp
	fi

	similaritycount=`cat $percenttemp | wc -l`
	if [[ $similaritycount == 0 ]]; then
		echo "0.97" > $percenttemp
	fi

	bash $scriptdir/openref_slave.sh $stdout $stderr $log $config $percenttemp $derepseqs $seqs $numseqs $presufdir $seqname $blasttax $rdptax $uclusttax $alltax $parameter_count $param_file $randcode
fi

#########################################
## Custom openref OTU Steps BEGIN HERE ##
#########################################

## Define otu picking parameters ahead of outdir naming

if [[ $openrefpick == "custom_openref" || $allpick == "ALL" ]]; then
	otumethod=CustomOpenRef

	if [[ $parameter_count == 1 ]]; then
		grep "similarity" $param_file | cut -d " " -f2 | sed '/^$/d' > $percenttemp
	else
		echo "0.97" > $percenttemp
	fi

	similaritycount=`cat $percenttemp | wc -l`
	if [[ $similaritycount == 0 ]]; then
		echo "0.97" > $percenttemp
	fi

	bash $scriptdir/custom_openref_slave.sh $stdout $stderr $log $config $percenttemp $derepseqs $seqs $numseqs $presufdir $seqname $blasttax $rdptax $uclusttax $alltax $parameter_count $param_file $randcode
fi

## Build OTU tables in parallel

	ls -d *_otus_*/*taxonomy_assignment/merged_rep_set_tax_assignments.txt > $taxfiles

	bash $scriptdir/OTU_table_slave.sh $stdout $stderr $log $randcode $taxfiles $threads $mode




## Log end of script

	res1=$(date +%s.%N)
	dt=$(echo "$res1 - $res0" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)
	runtime=`printf "Total runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`

echo "${bold}OTU picking workflow steps complete.${normal}

$runtime
"
echo "---

OTU picking workflow steps complete." >> $log
date "+%a %b %d %I:%M %p %Z %Y" >> $log
echo "
$runtime 
" >> $log

exit 0
