#!/usr/bin/env bash
#
#  SCRIPT NAME - SHORT DESCRIPTION
#
#  Version 1.0.0 (MONTH, 99, 2015)
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
## Trap function on exit.
function finish {

if [[ -f $tempfile1 ]]; then
	rm $tempfile1
fi
}
trap finish EXIT

## Set variables
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=$(dirname $scriptdir)
	workdir=$(pwd)
	tempdir="$repodir/temp"
	randcode=`cat /dev/urandom |tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1` 2>/dev/null

	tempfile1="$tempdir/$randcode.tempfile1.temp"

	fastq="$1"
	fastqextension="${1##*.}"
	outfile="fastq_data_results-$fastq.pdf"

	date0=$(date)

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

## Check whether user had supplied -h or --help. If yes display help 
	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
	less $repodir/docs/fastq_data.help
		exit 0	
	fi

## If other than 1 arguments supplied, display usage
	if [[ "$#" -ne 1 ]]; then 
	cat $repodir/docs/fastq_data.usage
		exit 0
	fi

## If supplied file is neither .fastq or .fq, display usage
	if [[ "$fastqextension" != "fq" ]] && [[ "$fastqextension" != "fastq" ]]; then
		echo "
Input file must have .fastq or .fq extension.  Are you sure you have
supplied a valid fastq file?
		"
		exit 1
	fi

## Call fastq_data.r script
	echo "Analysis commencing. Please be patient...
	"
	Rscript $scriptdir/fastq_data.r $fastq $outfile &>/dev/null
	wait

## Report end of script
	echo "Analysis complete.

Output:		${bold}${outfile}${normal}
	"

exit 0
