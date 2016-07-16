#!/usr/bin/env bash
#
#  two-way_permanova.sh - two-way permanova analysis for QIIME data
#
#  Version 0.0.1 (July, 15, 2016)
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

if [[ -f $maptemp0 ]]; then
	rm $maptemp0
fi
if [[ -f $fcheck ]]; then
	rm $fcheck
fi
if [[ -f $dmtemp0 ]]; then
	rm $dmtemp0
fi
if [[ -f $f1temp ]]; then
	rm $f1temp
fi
if [[ -f $f2temp ]]; then
	rm $f2temp
fi
if [[ -f $tempfile5 ]]; then
	rm $tempfile5
fi
if [[ -f $tempfile6 ]]; then
	rm $tempfile6
fi
if [[ -f $biomtemp ]]; then
	rm $biomtemp
fi
}
trap finish EXIT

## Set variables
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=$(dirname $scriptdir)
	workdir=$(pwd)
	tempdir="$repodir/temp"
	randcode=`cat /dev/urandom |tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1` 2>/dev/null

	maptemp0="$tempdir/$randcode.map0.temp"
	maptemp1="$tempdir/$randcode.map1.temp"

	fcheck="$tempdir/$randcode.factorcheck.temp"
	dmtemp0="$tempdir/$randcode.dm0.temp"

	f1temp="$tempdir/$randcode.f1.temp"
	f2temp="$tempdir/$randcode.f2.temp"

	map="$1"
	dm="$2"
	factor1="$3"
	factor2="$4"

	biompath="${biom%.*}"
	biomname="${biompath##*/}"

	date0=$(date)

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

## Check whether user had supplied -h or --help. If yes display help 
	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
	less $repodir/docs/two-way_permanova.help
		exit 0
	fi

## If incorrect number of arguments supplied, display usage 
	if [[ "$#" -ne 4 ]]; then 
	cat $repodir/docs/two-way_permanova.usage
		exit 1
	fi 

## Test for presence of datamash
	dmtest=$(command -v datamash | wc -l)
	if [[ "$dmtest" == "0" ]]; then
	echo "
This script requires the datamash utility to run. Ensure the command is in your
PATH before running this script again.
You can obtain datamash here: https://www.gnu.org/software/datamash/download/
Or run (or rerun) the akutils_ubuntu_installer: https://github.com/alk224/akutils_ubuntu_installer
Exiting.
	"
	exit 1
	fi

## Test for presence of biom
	biomtest=$(command -v biom | wc -l)
	if [[ "$biomtest" == "0" ]]; then
	echo "
This script requires the biom package to be available in order to run. Ensure
it is properly installed (or loaded) before running this script again.
Exiting.
	"
	exit 1
	fi

## Check input categories against mapping file
	f1test=$(head -1 $map | grep -w $factor1 | wc -l)
	f2test=$(head -1 $map | grep -w $factor2 | wc -l)
	if [[ "$f1test" -eq "0" ]]; then
	echo $factor1 >> $fcheck
	fi
	if [[ "$f2test" -eq "0" ]]; then
	echo $factor2 >> $fcheck
	fi
	if [[ -s $fcheck ]]; then
	echo "
You supplied the following as input factors:
$factor1
$factor2

The following factors were not found in your mapping file:"
	cat $fcheck
	echo ""
	exit 1
	fi

## Report start of script
	echo "
akutils two-way permanova script

Supplied distance matrix:	${bold}${dm}${normal}
Input factor 1: 		${bold}${factor1}${normal}
Input factor 2: 		${bold}${factor2}${normal}

This will take a few moments.
	"

####################
## Start of data file transforms

## Reorder input map to match input distance matrix
	head -1 $map > $maptemp0
	for line in `cat $dm | cut -f1`; do
	grep -w "^$line" $map >> $maptemp0
	done

## Make temporary dm file without first column (sample IDs)
	cat $dm | cut -f2- > $dmtemp0

## Get factor columns from map file
	f1col=`awk -v factor="$factor1" -v map="$maptemp0" '{ for(i=1;i<=NF;i++){if ($i == factor) {print i}}}' $map`
	f2col=`awk -v factor="$factor2" -v map="$maptemp0" '{ for(i=1;i<=NF;i++){if ($i == factor) {print i}}}' $map`
	cat $maptemp0 | cut -f${f1col} > $f1temp
	cat $maptemp0 | cut -f${f2col} > $f2temp

## Run adonis function in R (PerMANOVA test)
	outdir="2way_permanova_${factor1}_by_${factor2}"
	rm -r $outdir 2>/dev/null
	mkdir $outdir
	outfile="$outdir/Statistical_summary.txt"
	outfile0="Statistical_summary.txt"
	echo "
akutils two-way PERMANOVA script.
$date0
dm: $dm
f1: $factor1
f2: $factor2

********************************
PERMANOVA results:" > $outfile
	Rscript $scriptdir/adonis.r $maptemp0 $dmtemp0 $factor1 $factor2 $f1temp $f2temp $outdir 1>>$outfile 2>/dev/null
	wait

## Run betadisper function in R (PERMDISP2 test)
	echo "
********************************
PERMDISP results:" >> $outfile
	Rscript $scriptdir/betadisper.r $maptemp0 $dmtemp0 $factor1 $factor2 $dm $f2temp $outdir 1>>$outfile 2>/dev/null
	wait
	echo "" >> $outfile

## Copy transformed files and R instructions into output directory
	cp $maptemp0 $outdir/map.vegan.txt
	cp $dmtemp0 $outdir/dm.vegan.txt
	cp $repodir/akutils_resources/R-instructions_vegan.txt $outdir/

## Report end of script
	echo "Analysis complete.

Output directory: ${bold}${outdir}${normal}
Statistics:	${bold}${outfile0}${normal}
Plots:		${bold}Permdisp_plots.pdf${normal}
Map file (R):	${bold}map.vegan.txt${normal}
Dis matrix (R):	${bold}dm.vegan.txt${normal}
R instructions:	${bold}R-instructions_vegan.txt${normal}
	"

exit 0
