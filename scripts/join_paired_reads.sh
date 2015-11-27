#!/usr/bin/env bash
#
#  Single_indexed_fqjoin_workflow.sh - Fastq-join workflow for single-indexed MiSeq data
#
#  Version 1.1.0 (June 16, 2015)
#
#  Copyright (c) 2014-2015 Andrew Krohn
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
	config="$4"
	res1=$(date +%s.%N)

	if [[ "$8" =~ ^-?[0-9]+$ ]]; then
	mode="single"
	index1="$5"
	read1="$6"
	read2="$7"
	length="$8"
	options="${@:9:9}"

	elif [[ "$9" =~ ^-?[0-9]+$ ]]; then
	mode="dual"
	index1="$5"
	index2="$6"
	read1="$7"
	read2="$8"
	length="$9"
	options="${@:10:9}"
	index2extension="${index2##*.}"
	index2base=`basename "$index2" .$index2extension`
	index2name="${index2%.*}"
	fi

	index1extension="${index1##*.}"
	read1extension="${read1##*.}"
	read2extension="${read2##*.}"
	index1base=`basename "$index1" .$index1extension`
	read1base=`basename "$read1" .$read1extension`
	read2base=`basename "$read2" .$read2extension`
	index1name="${index1%.*}"
	read1name="${read1%.*}"
	read2name="${read2%.*}"

## Display usage if incorrect number of arguments supplied
	if [[ "$#" -le "7" ]]; then
		cat $repodir/docs/join_paired_reads.usage
		exit 0
	fi

## Define output directory and check to see it already exists
	outdir="$workdir/join_paired_reads_out"
	if [[ -d "$outdir" ]]; then
		echo "
Output directory already exists ($outdir).  
Aborting workflow.
		"
		exit 1
	else
		mkdir $outdir
	fi

## Log start of workflow
	date0=`date +%Y%m%d_%I%M%p`
	log="$outdir/log_join_paired_reads_$date0.txt"
	echo "
akutils join_paired_reads workflow starting in $mode mode."

	echo "
akutils join_paired_reads workflow starting in $mode mode." >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log

## Set start of read data for fastx_trimmer steps
	readno=$(($length+1))

## Single-indexed mode start here
if [[ "$mode" == "single" ]]; then

## Concatenate index1 in front of read1
	echo "
Concatenating index and first read."
	echo "
Concatenation:" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	bash $scriptdir/concatenate_fastqs.sh $index1 $read1
	mv ${index1base}_${read1base}.${index1extension} $outdir/i1r1.fq
	wait

## Fastq-join command
	echo "
Joining reads."
	echo "
Joining command:" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	echo "	fastq-join $options $outdir/i1r1.fq $read2 -o $outdir/temp.%.fq" >> $log
	echo "
Fastq-join results:" >> $log
	fastq-join $options $outdir/i1r1.fq $read2 -o $outdir/temp.%.fq >> $log
	wait

## Split index and read data from successfully joined reads
	echo "
Splitting read and index data from successfully joined data."
	echo "
Split index and read commands:" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	echo "	fastx_trimmer -l $length -i $outdir/temp.join.fq -o $outdir/idx.fq -Q 33" >> $log
	echo "	fastx_trimmer -f $readno -i $outdir/temp.join.fq -o $outdir/rd.fq -Q 33" >> $log
	( fastx_trimmer -l $length -i $outdir/temp.join.fq -o $outdir/idx.fq -Q 33 ) &
	( fastx_trimmer -f $readno -i $outdir/temp.join.fq -o $outdir/rd.fq -Q 33 ) &
	wait

## Remove temp files
	echo "
Removing temporary files."
	echo "
Removing temporary files (raw join data, unjoined reads, concatenated indexes)." >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	rm $outdir/temp.*.fq
	rm $outdir/i1r1*.fq

## Dual-indexed mode start here
elif [[ "$mode" == "dual" ]]; then

## Concatenate index1 in front of index2
	echo "
Concatenating indices and first read."
	echo "
First concatenation:" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	bash $scriptdir/concatenate_fastqs.sh $index1 $index2
	mv ${index1base}_${index2base}.${index1extension} $outdir/i1i2.fq
	wait

## Concatenate indexes in front of read1
	echo "
Second concatenation:" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	bash $scriptdir/concatenate_fastqs.sh $outdir/i1i2.fq $read1
	mv $outdir/i1i2_${read1base}.fq $outdir/i1i2r1.fq
	wait

## Fastq-join command
	echo "
Joining reads."
	echo "
Joining command:" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	echo "	fastq-join $options $outdir/i1i2r1.fq $read2 -o $outdir/temp.%.fq" >> $log
	echo "
Fastq-join results:" >> $log
	fastq-join $options $outdir/i1i2r1.fq $read2 -o $outdir/temp.%.fq >> $log
	wait

## Split index and read data from successfully joined reads
	echo "
Splitting read and index data from successfully joined data."
	echo "
Split index and read commands:" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	echo "	fastx_trimmer -l $length -i $outdir/temp.join.fq -o $outdir/idx.fq -Q 33" >> $log
	echo "	fastx_trimmer -f $readno -i $outdir/temp.join.fq -o $outdir/rd.fq -Q 33" >> $log
	( fastx_trimmer -l $length -i $outdir/temp.join.fq -o $outdir/idx.fq -Q 33 ) &
	( fastx_trimmer -f $readno -i $outdir/temp.join.fq -o $outdir/rd.fq -Q 33 ) &
	wait

## Remove temp files
	echo "
Removing temporary files."
	echo "
Removing temporary files (raw join data, unjoined reads, concatenated indexes)." >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	rm $outdir/temp.*.fq
	rm $outdir/i1i2*.fq
fi

## Log end of workflow
res2=$(date +%s.%N)
dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)
runtime=`printf "Total runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
echo "
Joining workflow steps completed.  Hooray!
$runtime
"
echo "
---

All workflow steps completed.  Hooray!" >> $log
date "+%a %b %d %I:%M %p %Z %Y" >> $log
echo "
$runtime 
" >> $log

exit 0
