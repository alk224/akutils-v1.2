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
set -e

## Define variables.
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=`dirname $scriptdir`
	workdir=$(pwd)
	stdout="$1"
	stderr="$2"
	randcode="$3"
	mode="$4"
	date0=`date +%Y%m%d_%I%M%p`
	res0=$(date +%s.%N)
	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

## Trap function on exit.
#function finish {
#if [[ -f $stdout ]]; then
#	rm $stdout
#fi
#if [[ -f $stderr ]]; then
#	rm $stderr
#fi
#}
#trap finish EXIT

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
	logcount=`ls log_pick_otus_* 2>/dev/null | head -1 | wc -l`
	if [[ "$logcount" == "1" ]]; then
		log=`ls log_pick_otus*.txt | head -1`
	elif [[ "$logcount" == "0" ]]; then
		log=($workdir/log_pick_otus_$date0.txt)
	fi
	echo "
${bold}akutils pick_otus workflow beginning.${normal}
	"

## Read in variables from config file
	refs=(`grep "Reference" $config | grep -v "#" | cut -f 2`)
	tax=(`grep "Taxonomy" $config | grep -v "#" | cut -f 2`)
	tree=(`grep "Tree" $config | grep -v "#" | cut -f 2`)
	chimera_refs=(`grep "Chimeras" $config | grep -v "#" | cut -f 2`)
	seqs=($outdir/split_libraries/seqs_chimera_filtered.fna)
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
	chimera_threads=($CPU_cores)
	otupicking_threads=($CPU_cores)
	taxassignment_threads=($CPU_cores)
	alignseqs_threads=($CPU_cores)
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

## Check for valid OTU picking and tax assignment modes
	if [[ "$otupicker" != "blast" && "$otupicker" != "cdhit" && "$otupicker" != "swarm" && "$otupicker" != "openref" && "$otupicker" != "custom_openref" && "$otupicker" != "ALL" ]]; then
	echo "Invalid OTU picking method chosen.
Your current setting: ${bold}$otupicker${normal}

Valid choices are blast, cdhit, swarm, openref, custom_openref, or ALL.
Rerun akutils configure and change the current OTU picker setting.
Exiting.
	"
		exit 1
	else echo "OTU picking method(s): ${bold}$otupicker${normal}
	"
	fi

	if [[ "$taxassigner" != "blast" && "$taxassigner" != "rdp" && "$taxassigner" != "uclust" && "$taxassigner" != "ALL" ]]; then
	echo "Invalid taxonomy assignment method chosen.
Your current setting: ${bold}$taxassigner${normal}

Valid choices are blast, rdp, uclust, or ALL. Rerun akutils configure
and change the current taxonomy assigner setting.
Exiting.
	"
		exit 1
	else echo "Taxonomy assignment method(s): ${bold}$taxassigner${normal}
	"
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
	fi

## Check for split_libraries outputs and inputs
	if [[ -f $outdir/split_libraries/seqs.fna ]]; then
	echo "Split libraries output detected.
	"
	seqs=$outdir/split_libraries/seqs.fna
	numseqs=`grep -e "^>" $seqs | wc -l`
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
	if [[ ! -f $outdir/split_libraries/seqs.fna ]]; then
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

	bash $scriptdir/split_libraries_slave.sh $stdout $stderr $log $qvalue $minpercent $maxbad $barcodetype $map #1>$stdout 2>$stderr
	fi
	seqs=$outdir/split_libraries/seqs.fna

## Call chimera filtering function and set variables as necessary












exit 0
