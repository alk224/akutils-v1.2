#!/usr/bin/env bash
#
#  akutils - akutils master script
#
#  Version 0.0.1 (Novermber, 13, 2015)
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
## Trap function on exit.
function finish {
if [[ -f $tfilelist ]]; then
	for line in `cat $tfilelist`; do
		rm $line
	done
	wait
	rm $tfilelist
fi
if [[ -f $seqlist ]]; then
	rm $seqlist
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
	config="$4"
	fastq="$5"
	indexes="$6"
	mismatch="$7"
	cores="$8"
	threads=$(($cores+1))

	date0=$(date +%Y%m%d_%I%M%p)
	res0=$(date +%s.%N)

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

## If incorrect number of arguments supplied, display usage 
	if [[ "$#" -ne 8 ]]; then 
	cat $repodir/docs/index_groomer.usage
		exit 1
	fi

## Extract fastq basename, extension, and directory for output naming and file direction
	fqext="${fastq##*.}"
	fqname=$(basename $fastq .$fqext)
	fqdir=$(dirname $fastq)

## If input fastq extension is not .fq or .fastq, exit
	if [[ "$fqext" != "fq" && "$fqext" != "fastq" ]]; then
	echo "
Input fastq does not have valid extension (.fq or .fastq). Check you input and
try again. Exiting.
	"
	exit 1
	fi

## Extract approximate sequences with fq grep and build temp files
	echo "
Extracting sequences with $mismatch mismatches on $cores CPU cores.
	"
	tfilelist="${tempdir}/${randcode}_tfile_master.temp"
	for sequence in `grep -v "#" $indexes | cut -f1`; do
	tfile="${tempdir}/${randcode}_${sequence}_list.temp"
	echo $tfile >> $tfilelist
		while [ $( pgrep -P $$ | wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		( fqgrep -m $mismatch -f -p $sequence $fastq | grep -v -e "^>" | sort | uniq | grep -v "$sequence" > $tfile ) &
	done
wait
	for sequence in `grep -v "#" $indexes | cut -f1`; do
	seqlist="${tempdir}/${randcode}_seqlist.temp"
	tfile="${tempdir}/${randcode}_${sequence}_list.temp"
	cat $tfile >> $seqlist
	done
wait
seqcount=$(cat $seqlist | wc -l)

## Copy input file for grooming
	fastqgroom="$fqdir/$fqname.groomed.${mismatch}mismatch.$fqext"
	cp $fastq $fastqgroom

## Use perl to groom index sequences
	count=1
	for sequence in `grep -v "#" $indexes | cut -f1`; do
	 	tfile="${tempdir}/${randcode}_${sequence}_list.temp"
		for line in `cat $tfile`; do
		## Can't seem to make multithreading work here with perl or sed
		#while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		#sleep 1
		#done
		echo -ne "Replacing $count/$seqcount sequences\r"
		perl -i -pe"s/^$line$/$sequence/g" $fastqgroom
		#sed -i "s/^$line$/$sequence/g" $fastqgroom
		((count++))
		done
	done
wait

## Report end
	echo "
Index grooming complete. 
	"

exit 0
