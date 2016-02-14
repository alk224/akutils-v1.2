#!/usr/bin/env bash
#
#  align_tree_workflow.sh - sequence alignment and tree building workflow
#
#  Version 1.0.0 (November, 14, 2015)
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

## Trap function on exit.

## Find scripts location and set variables.
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=`dirname $scriptdir`
	workdir=$(pwd)
	stdout="$1"
	stderr="$2"
	randcode="$3"
	mode="$4"
	target="$5"
	date0=`date +%Y%m%d_%I%M%p`
	res0=$(date +%s.%N)

## ID config file.
	config=$(bash $scriptdir/config_id.sh)

## Check for valid mode setting.  Display usage if error.
	if [[ "$mode" != "other" ]] && [[ "$mode" != "16S" ]]; then
	echo "
Invalid mode entered. Valid modes are 16S or other."
	cat $repodir/docs/align_and_tree.usage
	exit 1
	fi

## Check that valid target was supplied.  Display usage if error.
	if [[ "$5" == "ALL" ]]; then
	target="ALL"
	elif [[ -d "$5" ]]; then
	target="$5"
	else
	echo "
Invalid target supplied. Must be otu picking directory or \"ALL.\""
	cat $repodir/docs/align_and_tree.usage
	exit 1
	fi

## Find log file or set new one.
	logcount=`ls log_align_and_tree_*.txt 2>/dev/null | head -1 | wc -l`
	if [[ "$logcount" == "1" ]]; then
		log=`ls log_align_and_tree_*.txt | head -1`
	elif [[ "$logcount" == "0" ]]; then
		log=($workdir/log_align_and_tree_$date0.txt)
	fi

## Import variables from config file or send useful feedback if there is a problem.
	template=(`grep "Alignment_template" $config | grep -v "#" | cut -f 2`)
	lanemask=(`grep "Alignment_lanemask" $config | grep -v "#" | cut -f 2`)
	threads=(`grep "CPU_cores" $config | grep -v "#" | cut -f 2`)

	if [[ "$mode" == "16S" ]]; then
	if [[ "$template" == "undefined" ]] && [[ ! -z "$template" ]]; then
	echo "
Alignment template has not been defined.  Define it in your akutils
config file.  To update definitions, run:

akutils configure

If you just updated akutils be sure to select \"rebuild\" on your global
config file to update the available variables.  Exiting.
	"
	exit 1
	fi
	if [[ "$lanemask" == "undefined" ]] && [[ ! -z "$lanemask" ]]; then
	echo "
Alignment lanemask has not been defined.  Define it in your akutils
config file.  To update definitions, run:

akutils configure

If you just updated akutils be sure to select \"rebuild\" on your global
config file to update the available variables.  Exiting.
	"
	exit 1
	fi
	fi

	if [[ "$threads" == "undefined" ]] && [[ ! -z "$threads" ]]; then
	echo "
Threads to use during alignment has not been defined.  Define it in your
akutils config file.  To update definitions, run:

akutils configure

If you just updated akutils be sure to select \"rebuild\" on your global
config file to update the available variables.

Defaulting to 1 thread.
	"
	threads="1"
	fi

## Workflow for single target directory
if [[ -d "$target" ]]; then
	echo "Beginning align and tree workflow on supplied directory in \"$mode\" mode.
Indir: $target"
	date "+%a %b %d %I:%M %p %Z %Y"
	echo ""
	echo "Beginning align and tree workflow on supplied directory in \"$mode\" mode.
Indir: $target" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	echo "" >> $log

	## Check for rep_set file and assign variable if OK, exit if not.
	repsetcount=`ls $target/*rep_set.fna 2>/dev/null | wc -l`
	if [[ "$repsetcount" -eq "0" ]]; then
	echo "No representative sequences file found.  Make sure there is a file
present in the target directory titled *rep_set.fna where \"*\" is any
preceding character(s).  Exiting.
	"
	echo "No representative sequences file found.  Make sure there is a file
present in the target directory titled *rep_set.fna where \"*\" is any
preceding character(s).  Exiting.
	" >> $log
	exit 1
	fi

	## For loop to process all rep sets in target directory
	for  repsetfile in `ls $target/*rep_set.fna 2>/dev/null`; do
	repsetbase=`basename $repsetfile .fna`
	seqcount0=`cat $repsetfile | wc -l`
	seqcount=`expr $seqcount0 / 2`

	## 16S mode:
	if [[ $mode == "16S" ]]; then

	## Align sequences command and check that output is not an empty file
	res1=$(date +%s.%N)
	if [[ ! -f $target/pynast_alignment/${repsetbase}_aligned.fasta ]]; then
	echo "Infile: $repsetfile
Outdir: $target/pynast_alignment/
Aligning $seqcount sequences with PyNAST on $threads threads.
	"
	echo "Infile: $repsetfile
Outdir: $target/pynast_alignment/
Aligning $seqcount sequences with PyNAST on $threads threads.

Align sequences command:
	parallel_align_seqs_pynast.py -i $repsetfile -o $target/pynast_alignment -t $template -O $threads
" >> $log
	parallel_align_seqs_pynast.py -i $repsetfile -o $target/pynast_alignment -t $template -O $threads 1>$stdout 2>$stderr || true
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	else
	echo "Previous alignment output detected.
File: $target/pynast_alignment/${repsetbase}_aligned.fasta
	"
	fi

	if [[ ! -s $target/pynast_alignment/${repsetbase}_aligned.fasta ]]; then
	echo "No valid alignment produced.  Check your inputs and try again.  Exiting.
	"
	exit 1
	fi

	## Log alignment runtime.
	res2=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)
	runtime=`printf "Alignment runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "$runtime
	" >> $log

	## Filter alignment command
	res1=$(date +%s.%N)
	if [[ ! -f $target/pynast_alignment/${repsetbase}_aligned_pfiltered.fasta ]]; then
	echo "Filtering alignment against supplied lanemask file.
	"
	echo "Filter alignment command:
	filter_alignment.py -i $target/pynast_alignment/${repsetbase}_aligned.fasta -m $lanemask -o $target/pynast_alignment/
" >> $log
	filter_alignment.py -i $target/pynast_alignment/${repsetbase}_aligned.fasta -m $lanemask -o $target/pynast_alignment/ 1>$stdout 2>$stderr || true
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	else
	echo "Alignment previously filtered.
	"
	fi

	## Log filtering runtime.
	res2=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)
	runtime=`printf "Filter alignment runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "$runtime
	" >> $log

	## Make phylogeny command.
	res1=$(date +%s.%N)
	if [[ ! -f $target/pynast_alignment/fasttree_phylogeny.tre ]]; then
	echo "Building phylogenetic tree with fasttree.
	"
	echo "Make phylogeny command:
	make_phylogeny.py -i $target/pynast_alignment/${repsetbase}_aligned_pfiltered.fasta -t fasttree -o $target/pynast_alignment/fasttree_phylogeny.tre
" >> $log
	make_phylogeny.py -i $target/pynast_alignment/${repsetbase}_aligned_pfiltered.fasta -t fasttree -o $target/pynast_alignment/fasttree_phylogeny.tre 1>$stdout 2>$stderr || true
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	else
	echo "Phylogeny previously completed.
file: $target/pynast_alignment/fasttree_phylogeny.tre
	"
	fi

	## Log phylogeny runtime.
	res2=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)
	runtime=`printf "Make phylogeny runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "$runtime
	" >> $log

	## "other" mode:
	elif [[ $mode == "other" ]]; then

	## Align sequences command and check that output is not an empty file
	res1=$(date +%s.%N)
	if [[ ! -f $target/mafft_alignment/${repsetbase}_aligned.fasta ]]; then
	echo "Infile: $repsetfile
Outdir: $target/mafft_alignment/
Aligning $seqcount sequences with MAFFT on $threads threads.
	"
	echo "Infile: $repsetfile
Outdir: $target/mafft_alignment/
Aligning $seqcount sequences with MAFFT on $threads threads.

Align sequences command (MAFFT command):
	mafft --thread $threads --parttree --retree 2 --partsize 1000 --alga $repsetfile > $target/mafft_alignment/${repsetbase}_aligned.fasta 2>$target/mafft_alignment/alignment_log_${repsetbase}.txt
" >> $log
	mkdir -p $target/mafft_alignment
	echo "See $target/mafft_alignment/alignment_log_${repsetbase}.txt for any errors.">$stderr
	mafft --thread $threads --parttree --retree 2 --partsize 1000 --alga $repsetfile > $target/mafft_alignment/${repsetbase}_aligned.fasta 2>$target/mafft_alignment/alignment_log_${repsetbase}.txt || true
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	else
	echo "Previous alignment output detected.
File: $target/mafft_alignment/${repsetbase}_aligned.fasta
	"
	fi

	if [[ ! -s $target/mafft_alignment/${repsetbase}_aligned.fasta ]]; then
	echo "No valid alignment produced.  Check your inputs and try again.  Exiting.
	"
	exit 1
	fi

	## Log alignment runtime.
	res2=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)

	runtime=`printf "Alignment runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "$runtime
	" >> $log

	## Filter alignment command
	res1=$(date +%s.%N)
	if [[ ! -f $target/mafft_alignment/${repsetbase}_aligned_pfiltered.fasta ]]; then
	echo "Filtering top 10% entropic sites from alignment.
	"
	echo "Filter alignment command:
	filter_alignment.py -i $target/mafft_alignment/${repsetbase}_aligned.fasta -e 0.1 -o $target/mafft_alignment/
" >> $log
	filter_alignment.py -i $target/mafft_alignment/${repsetbase}_aligned.fasta -e 0.1 -o $target/mafft_alignment/ 1>$stdout 2>$stderr || true
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	else
	echo "Alignment previously filtered.
	"
	fi

	## Log filtering time.
	res3=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)
	runtime=`printf "Filter alignment runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "$runtime
	" >> $log

	## Make phylogeny command
	res1=$(date +%s.%N)
	if [[ ! -f $target/mafft_alignment/fasttree_phylogeny.tre ]]; then
	echo "Building phylogenetic tree with fasttree.
	"
	echo "Make phylogeny command:
	make_phylogeny.py -i $target/mafft_alignment/${repsetbase}_aligned_pfiltered.fasta -t fasttree -o $target/mafft_alignment/fasttree_phylogeny.tre
" >> $log
	make_phylogeny.py -i $target/mafft_alignment/${repsetbase}_aligned_pfiltered.fasta -t fasttree -o $target/mafft_alignment/fasttree_phylogeny.tre 1>$stdout 2>$stderr || true
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	else
	echo "Phylogeny previously completed.
file: $target/mafft_alignment/fasttree_phylogeny.tre
	"
	fi

	## Log phylogeny runtime.
	res2=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)
	runtime=`printf "Make phylogeny runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "$runtime
	" >> $log
	fi

	## End of for loop for target directory
	done

## Workflow for ALL otu picking subdirectories

	elif [[ $target == "ALL" ]]; then
	echo "Beginning align and tree workflow on all subdirectories in \"$mode\" mode.
Indir: ALL subdirectories containing \"*_otus_*\""
	date "+%a %b %d %I:%M %p %Z %Y"
	echo ""
	echo "Beginning align and tree workflow on all subdirectories in \"$mode\" mode.
Indir: ALL subdirectories containing \"*_otus_*\"" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	echo "" >> $log

for otudir in `ls | grep "_otus_"`; do

	if [[ -d $otudir ]]; then
	for  repsetfile in `ls $otudir/*rep_set.fna 2>/dev/null`; do
	repsetbase=`basename $repsetfile .fna`
	seqcount0=`cat $repsetfile | wc -l`
	seqcount=`expr $seqcount0 / 2`

	## 16S mode:
	if [[ $mode == "16S" ]]; then

	## Align sequences command and check that output is not an empty file
	res1=$(date +%s.%N)
	if [[ ! -f $otudir/pynast_alignment/${repsetbase}_aligned.fasta ]]; then
	echo "Infile: $repsetfile
Outdir: $otudir/pynast_alignment/
Aligning $seqcount sequences with PyNAST on $threads threads.
	"
	echo "Infile: $repsetfile
Outdir: $otudir/pynast_alignment/
Aligning $seqcount sequences with PyNAST on $threads threads.

Align sequences command:
	parallel_align_seqs_pynast.py -i $repsetfile -o $otudir/pynast_alignment -t $template -O $threads
" >> $log
	parallel_align_seqs_pynast.py -i $repsetfile -o $otudir/pynast_alignment -t $template -O $threads 1>$stdout 2>$stderr || true
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	else
	echo "Previous alignment output detected.
File: $otudir/pynast_alignment/${repsetbase}_aligned.fasta
	"
	fi

	if [[ ! -s $otudir/pynast_alignment/${repsetbase}_aligned.fasta ]]; then
	echo "No valid alignment produced.  Check your inputs and try again.  Exiting.
	"
	exit 1
	fi

	## Log alignment runtime.
	res2=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)
	runtime=`printf "Alignment runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "$runtime
	" >> $log

	## Filter alignment command
	res1=$(date +%s.%N)
	if [[ ! -f $otudir/pynast_alignment/${repsetbase}_aligned_pfiltered.fasta ]]; then
	echo "Filtering alignment against supplied lanemask file.
	"
	echo "Filter alignment command:
	filter_alignment.py -i $otudir/pynast_alignment/${repsetbase}_aligned.fasta -m $lanemask -o $otudir/pynast_alignment/
" >> $log
	filter_alignment.py -i $otudir/pynast_alignment/${repsetbase}_aligned.fasta -m $lanemask -o $otudir/pynast_alignment/ 1>$stdout 2>$stderr || true
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	else
	echo "Alignment previously filtered.
	"
	fi

	## Log filtering runtime.
	res2=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)
	runtime=`printf "Filter alignment runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "$runtime
	" >> $log

	## Make phylogeny command
	res1=$(date +%s.%N)
	if [[ ! -f $otudir/pynast_alignment/fasttree_phylogeny.tre ]]; then
	echo "Building phylogenetic tree with fasttree.
	"
	echo "Make phylogeny command:
	make_phylogeny.py -i $otudir/pynast_alignment/${repsetbase}_aligned_pfiltered.fasta -t fasttree -o $otudir/pynast_alignment/fasttree_phylogeny.tre
" >> $log
	make_phylogeny.py -i $otudir/pynast_alignment/${repsetbase}_aligned_pfiltered.fasta -t fasttree -o $otudir/pynast_alignment/fasttree_phylogeny.tre 1>$stdout 2>$stderr || true
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	else
	echo "Phylogeny previously completed.
file: $otudir/pynast_alignment/fasttree_phylogeny.tre
	"
	fi

	## Log phylogeny runtime.
	res2=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)
	runtime=`printf "Make phylogeny runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "$runtime
	" >> $log

	## "other" mode:
	elif [[ $mode == "other" ]]; then

	## Align sequences command and check that output is not an empty file
	res1=$(date +%s.%N)
	if [[ ! -f $otudir/mafft_alignment/${repsetbase}_aligned.fasta ]]; then
	echo "Infile: $repsetfile
Outdir: $otudir/mafft_alignment/
Aligning $seqcount sequences with MAFFT on $threads threads.
	"
	echo "Infile: $repsetfile
Outdir: $otudir/mafft_alignment/
Aligning $seqcount sequences with MAFFT on $threads threads.

Align sequences command (MAFFT command):
	mafft --thread $threads --parttree --retree 2 --partsize 1000 --alga $repsetfile > $otudir/mafft_alignment/${repsetbase}_aligned.fasta
" >> $log
	mkdir -p $otudir/mafft_alignment
	mafft --thread $threads --parttree --retree 2 --partsize 1000 --alga $repsetfile > $otudir/mafft_alignment/${repsetbase}_aligned.fasta 1>$stdout 2>$otudir/mafft_alignment/alignment_log_${repsetbase}.txt || true
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	else
	echo "Previous alignment output detected.
File: $otudir/mafft_alignment/${repsetbase}_aligned.fasta
	"
	fi

	if [[ ! -s $otudir/mafft_alignment/${repsetbase}_aligned.fasta ]]; then
	echo "No valid alignment produced.  Check your inputs and try again.  Exiting.
	"
	exit 1
	fi

	## Log alignment runtime.
	res2=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)
	runtime=`printf "Alignment runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "$runtime
	" >> $log

	## Filter alignment command
	res1=$(date +%s.%N)
	if [[ ! -f $otudir/mafft_alignment/${repsetbase}_aligned_pfiltered.fasta ]]; then
	echo "Filtering top 10% entropic sites from alignment.
	"
	echo "Filter alignment command:
	filter_alignment.py -i $otudir/mafft_alignment/${repsetbase}_aligned.fasta -e 0.1 -o $otudir/mafft_alignment/
" >> $log
	filter_alignment.py -i $otudir/mafft_alignment/${repsetbase}_aligned.fasta -e 0.1 -o $otudir/mafft_alignment/ 1>$stdout 2>$stderr || true
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	else
	echo "Alignment previously filtered.
	"
	fi

	## Log filtering runtime.
	res1=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)
	runtime=`printf "Filter alignment runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "$runtime
	" >> $log

	## Make phylogeny command
	res1=$(date +%s.%N)
	if [[ ! -f $otudir/mafft_alignment/fasttree_phylogeny.tre ]]; then
	echo "Building phylogenetic tree with fasttree.
	"
	echo "Make phylogeny command:
	make_phylogeny.py -i $otudir/mafft_alignment/${repsetbase}_aligned_pfiltered.fasta -t fasttree -o $otudir/mafft_alignment/fasttree_phylogeny.tre
" >> $log
	make_phylogeny.py -i $otudir/mafft_alignment/${repsetbase}_aligned_pfiltered.fasta -t fasttree -o $otudir/mafft_alignment/fasttree_phylogeny.tre 1>$stdout 2>$stderr || true
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	else
	echo "Phylogeny previously completed.
file: $otudir/mafft_alignment/fasttree_phylogeny.tre
	"
	fi

	## Log phylogeny runtime.
	res2=$(date +%s.%N)
	dt=$(echo "$res2 - $res1" | bc)
	dd=$(echo "$dt/86400" | bc)
	dt2=$(echo "$dt-86400*$dd" | bc)
	dh=$(echo "$dt2/3600" | bc)
	dt3=$(echo "$dt2-3600*$dh" | bc)
	dm=$(echo "$dt3/60" | bc)
	ds=$(echo "$dt3-60*$dm" | bc)
	runtime=`printf "Make phylogeny runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "$runtime
	" >> $log
	fi

	## End of for loop for target directory.
	done
fi
done
fi

## Log end of workflow and total runtime.
res2=$(date +%s.%N)
dt=$(echo "$res2 - $res0" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)
runtime=`printf "Total runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`

echo "All workflow steps completed.  Hooray!

$runtime
"
echo "---

All workflow steps completed.  Hooray!" >> $log
date "+%a %b %d %I:%M %p %Z %Y" >> $log
echo "
$runtime 
" >> $log

exit 0
