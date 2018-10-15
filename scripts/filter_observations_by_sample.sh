#!/usr/bin/env bash
#
#  filter_observations_by_sample.sh - Filter an OTU table ona per-sample basis
#
#  Version 1.2 (July 27, 2016)
#
#  Copyright (c) 2014-- Lela Andrews
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
if [[ -f $tempfile2 ]]; then
	rm $tempfile2
fi
if [[ -f $tempfile3 ]]; then
	rm $tempfile3
fi
if [[ -f $tempfile4 ]]; then
	rm $tempfile4
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
	tempfile2="$tempdir/$randcode.tempfile2.temp"
	tempfile3="$tempdir/$randcode.tempfile3.temp"
	tempfile4="$tempdir/$randcode.tempfile4.temp"

	mode="$1"
	biom="$2"
	filter="$3"
	share="$4"

	biompath="${biom%.*}"
	biomname="${biompath##*/}"
	biomextension="${biom##*.}"
	biomdir=$(dirname $biom)

	date0=$(date)

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

## Check whether user had supplied -h or --help. If yes display help 
	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
	less $repodir/docs/filter_observations_by_sample.help
		exit 0	
	fi

## If other than SOMENUMBEROF arguments supplied, display usage
	if [[ "$#" -ne 4 ]]; then 
	cat $repodir/docs/filter_observations_by_sample.usage
	exit 1
	fi

## Check if mode is set correctly, else exit with usage and info
	if [[ "$mode" != "n" ]] && [[ "$mode" != "f" ]]; then
	echo "
Mode incorrectly set. Must be \"n\" or \"f\"."
	cat $repodir/docs/filter_observations_by_sample.usage
	exit 1
	fi

## Check if input OTU table is a biom file
	if [[ "$biomextension" != "biom" ]]; then
	echo "
Input OTU table does not have .biom extension. Check input and try again."
	cat $repodir/docs/filter_observations_by_sample.usage
	exit 1
	fi
	if [[ ! -f "$biom" ]]; then
	echo "
Input OTU table does not appear to be a valid file. Check input and try again."
	cat $repodir/docs/filter_observations_by_sample.usage
	exit 1
	fi

## Check if input OTU table is json or hdf5 format
	hdf5test=$(file $biom | grep "Hierarchical Data Format")
	if [[ ! -z "$hdf5test" ]]; then
	format="hdf5"
	else
	format="json"
	fi

## Check for valid <filter> value
	if [[ "$mode" == "n" ]]; then
	mode0="by count"
		if ! [[ "$filter" =~ ^[0-9]+$ ]]; then
		echo "
You supplied mode \"n\", but supplied value for <filter> is not an integer.
Check input and try again."
		cat $repodir/docs/filter_observations_by_sample.usage
		exit 1
		fi
	fi
	if [[ "$mode" == "f" ]]; then
	mode0="by fraction"
		if ! [[ "$filter" =~ ^[0]+(\.[0-9]+)$ ]]; then
		echo "
You supplied mode \"f\", but supplied value for <filter> is not a decimal less
than 1. Check input and try again."
		cat $repodir/docs/filter_observations_by_sample.usage
		exit 1
		fi
	fi

## Check for valid <share> value
	if ! [[ "$share" =~ ^[0-9]+$ ]]; then
	echo "
Supplied value for <share> is not an integer. Check input and try again."
	cat $repodir/docs/filter_observations_by_sample.usage
	exit 1
	fi

## Set output based on input
	outfile="${biomname}_${mode}${filter}_s${share}.${biomextension}"
	output="$biomdir/$outfile"
	rm $output

## Report script start if all checks pass
echo "
Filtering OTUs by sample. This will take a moment.
Input table: ${bold}${biom}${normal}
Output directory: ${bold}${biomdir}${normal}
Output table: ${bold}${outfile}${normal}
Filter mode: ${bold}${mode0} (${mode})${normal}
Filter value: ${bold}${filter}${normal}
Share value: ${bold}${share}${normal}
"

## If format is hdf5, convert to json for processing, else copy to temp directory
	if [[ "$format" == "hdf5" ]]; then
	biom convert -i $biom -o $tempfile1 --to-json --table-type="OTU table"
	else
	cp $biom $tempfile1
	fi

## Execute filtering for mode "n"
	if [[ "$mode" == "n" ]]; then
	filter_observations_by_sample.py -i $tempfile1 -o $tempfile2 -n $filter
	filter_otus_from_otu_table.py -i $tempfile2 -o $tempfile3 -n 1 -s $share
	fi

## Execute filtering for mode "f"
	if [[ "$mode" == "f" ]]; then
	filter_observations_by_sample.py -f -i $tempfile1 -o $tempfile2 -n $filter
	filter_otus_from_otu_table.py -i $tempfile2 -o $tempfile3 -n 1 -s $share
	fi

## If format is hdf5, convert from json, else copy temp output to outdir
	if [[ "$format" == "hdf5" ]]; then
	biom convert -i $tempfile3 -o $tempfile4 --to-hdf5 --table-type="OTU table"
	cp $tempfile4 $output
	else
	biom convert -i $tempfile3 -o $tempfile4 --to-json --table-type="OTU table"
	cp $tempfile4 $output
	fi

exit 0
