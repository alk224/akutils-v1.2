#!/usr/bin/env bash
#
#  synthetic_index.sh - generate synthetic indexes for demultiplexed fastqs
#
#  Version 0.0.1 (May, 16, 2016)
#
#  Copyright (c) 2016 Andrew Krohn
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
if [[ -f $stdout ]]; then
	rm $stdout
fi
if [[ -f $stderr ]]; then
	rm $stderr
fi
if [[ -f $indlist ]]; then
	rm $indlist
fi
if [[ -f $samplist ]]; then
	rm $samplist
fi
if [[ -f $r1list ]]; then
	rm $r1list
fi
if [[ -f $r2list ]]; then
	rm $r2list
fi
rm $fastqdir/*INDEX_temp.fastq 2>/dev/null
#rm $fastqdir/sed* 2>/dev/null
}
trap finish EXIT

## Find scripts and repository location.
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=`dirname $scriptdir`
	tempdir="$repodir/temp/"

## Set working directory and other important variables
	workdir=$(pwd)
	randcode=`cat /dev/urandom |tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1` 2>/dev/null
	stderr=($repodir/temp/$randcode\_stderr)
	stdout=($repodir/temp/$randcode\_stdout)

## Usage and help
	usage="$repodir/docs/synthetic_index.usage"
	help="$repodir/docs/synthetic_index.help"

## Check whether user supplied help, -h or --help. If yes display help.
	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "help" ]]; then
	less $help
		exit 0	
	fi

## If incorrect number of arguments supplied, display usage 
	if [[ "$#" -ne 2 ]]; then 
	cat $repodir/docs/synthetic_index.usage
		exit 1
	fi

## Print script start to screen
	echo "
Beginning synthetic index file construction. Please be patient.
	"

## Read input variables
	mapfile="$1"
	fastqdir="$2"

	bold=$(tput bold)
	normal=$(tput sgr0)

## Set config file
	config=$(bash $scriptdir/config_id.sh)
	cores=(`grep "CPU_cores" $config | grep -v "#" | cut -f 2`)
	threads=$(($cores-1))

## Make temp files from which to read indexes based on map file entries
	samplist="${tempdir}/${randcode}_sample.list"
	indlist="${tempdir}/${randcode}_index.list"
	grep -v "#" $mapfile | cut -f1-2 > $indlist
	grep -v "#" $mapfile | cut -f1 > $samplist

## Detect index length
	indlength=$((`head -1 $indlist | cut -f2 | wc -m`-1))
	qual=$(eval "printf 'A'%.0s {1..$indlength}")

## Compare input list to available files in target directory
	sed -i "/^$/d" $samplist
	sampcount=$(cat $samplist | wc -l)
	r1list="${tempdir}/${randcode}_r1.list"
	r2list="${tempdir}/${randcode}_r2.list"
	for sample in `cat $samplist`; do
		r1file=$(ls $fastqdir/$sample.R1.fastq 2>/dev/null)
		r2file=$(ls $fastqdir/$sample.R2.fastq 2>/dev/null)
		echo ${r1file##*/} >> $r1list
		echo ${r2file##*/} >> $r2list
	done
	sed -i "/^$/d" $r1list
	sed -i "/^$/d" $r2list
	r1count=$(cat $r1list | wc -l)
	r2count=$(cat $r2list | wc -l)

	echo "Mapping file contains ${bold}${sampcount} sample IDs${normal}.
Corresponding first read files (count): ${bold}${r1count}${normal}
Corresponding second read files (count): ${bold}${r2count}${normal}

Probably these should be equal values. If there is a problem, you should check
that your sampleID names match exactly those found in your mapping file. For
more details, use synthetic_index.sh help.
	"

## For loop to build each index file
	for sample in `cat $samplist`; do
		index=$(grep -e "$sample\s" $indlist | cut -f2)
		indfile="$fastqdir/${sample}.INDEX_temp.fastq"
		cp $fastqdir/$sample.R1.fastq $indfile
		header=$(head -1 $indfile 2>/dev/null | cut -d":" -f1-3)
		## sed command to replace the sequence line with synthetic index
		## sequences by searching for the header line
		sed -i "/$header/!b;n;c$index" $indfile
		wait
		## sed command to replace the qual score line with A (q32)
		## scores by searching for the "+" lines
		sed -i "/^\+$/!b;n;c$qual" $indfile
		wait
	done

## Combine read and index files into new directory as multiplexed data
	mkdir -p ./synthetic_index_out 2>/dev/null
	rm -r ./synthetic_index_out/* 2>/dev/null
	cat $fastqdir/*.R1.fastq > ./synthetic_index_out/read1.fastq 2>/dev/null
	cat $fastqdir/*.R2.fastq > ./synthetic_index_out/read2.fastq 2>/dev/null
	cat $fastqdir/*.INDEX_temp.fastq > ./synthetic_index_out/index.fastq 2>/dev/null

## Remove temp index files
	rm $fastqdir/*.INDEX_temp.fastq

## Test for outputs
	if [[ -s ./synthetic_index_out/read1.fastq ]]; then
	read1="./synthetic_index_out/read1.fastq"
	read1count=$(cat ./synthetic_index_out/read1.fastq | wc -l)
	else
	rm ./synthetic_index_out/read1.fastq 2>/dev/null
	read1="no output"
	fi
	if [[ -s ./synthetic_index_out/read2.fastq ]]; then
	read2="./synthetic_index_out/read2.fastq"
	read2count=$(cat ./synthetic_index_out/read2.fastq | wc -l)
	else
	rm ./synthetic_index_out/read2.fastq 2>/dev/null
	read2="no output"
	fi
	if [[ -s ./synthetic_index_out/index.fastq ]]; then
	index="./synthetic_index_out/index.fastq"
	indexcount=$(cat ./synthetic_index_out/index.fastq | wc -l)
	else
	rm ./synthetic_index_out/index.fastq 2>/dev/null
	index="no output"
	fi

## Print end of script to screen
	echo "Synthetic index construction complete. Check that files have equal number of
lines below as an indication that everything is in phase.
	Output directory: ./synthetic_index_out
	Output read 1 file: $read1 (${bold}${read1count} lines${normal})
	Output read 2 file: $read2 (${bold}${read2count} lines${normal})
	Output index file: $index (${bold}${indexcount} lines${normal})
	"

exit 0
