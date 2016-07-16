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

if [[ -f $biomtemp0 ]]; then
	rm $biomtemp0
fi
if [[ -f $biomtemp1 ]]; then
	rm $biomtemp1
fi
if [[ -f $biomtemp0t ]]; then
	rm $biomtemp0t
fi
if [[ -f $biomtemp2 ]]; then
	rm $biomtemp2
fi
if [[ -f $fcheck ]]; then
	rm $fcheck
fi
if [[ -f $biomtemp3 ]]; then
	rm $biomtemp3
fi
if [[ -f $maptemp0 ]]; then
	rm $maptemp0
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

	biomtemp0="$tempdir/$randcode.biom0.biom"
	biomtemp0t="$tempdir/$randcode.biom0.txt"
	biomtemp1="$tempdir/$randcode.biom1.temp"
	biomtemp2="$tempdir/$randcode.biom2.temp"
	biomtemp3="$tempdir/$randcode.biom3.temp"

	maptemp0="$tempdir/$randcode.map0.temp"
	maptemp1="$tempdir/$randcode.map1.temp"

	fcheck="$tempdir/$randcode.factorcheck.temp"
	dmtemp0="$tempdir/$randcode.dm0.temp"

	f1temp="$tempdir/$randcode.f1.temp"
	f2temp="$tempdir/$randcode.f2.temp"

	map="$1"
	biom="$2"
	factor="$3"

	biompath="${biom%.*}"
	biomname="${biompath##*/}"

	date0=$(date)

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

## Check whether user had supplied -h or --help. If yes display help 
	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
	less $repodir/docs/indicator_species.help
		exit 0
	fi

## If incorrect number of arguments supplied, display usage 
	if [[ "$#" -ne 3 ]]; then 
	cat $repodir/docs/indicator_species.usage
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
	ftest=$(head -1 $map | grep -w $factor | wc -l)
	if [[ "$ftest" -eq "0" ]]; then
	echo $factor >> $fcheck
	fi
	if [[ -s $fcheck ]]; then
	echo "
Your supplied factor was not found in your mapping file:"
	cat $fcheck
	echo ""
	exit 1
	fi

## Report start of script
	echo "
akutils indicator species analysis script

Supplied OTU table:	${bold}${biom}${normal}
Input factor:		${bold}${factor}${normal}

This will take a few moments.
	"

####################
## Start of data file transforms

## Copy input biom table to temp and convert to .txt
	cp $biom $biomtemp0
	biomtotxt.sh $biomtemp0 &>/dev/null
	wait

## Get column from OTU table that contains the taxonomy string and remove if present
	column0=`awk -v table="$biomtemp0t" '{ for(i=1;i<=NF;i++){if ($i ~ /taxonomy/) {print i}}}' $biomtemp0t`
	column1=`expr $column0 - 2`
	taxcol=`expr $column0 - 1`
	if [[ ! -z "$taxcol" ]]; then 
	cat $biomtemp0t | cut -f1-${column1} > $biomtemp1
	else
	cp $biomtemp0t $biomtemp1
	fi

## If this is a summarized table, remove all but the deepest taxonomic identifier (using semicolon as delimiter)
	sctest=$(cat $biomtemp1 | cut -f1 | grep ";" | wc -l)
	if [[ "$sctest" -ge "1" ]]; then
		sed -i "s/^.\+;//g" $biomtemp1
	fi

## Transpose table
	datamash transpose < $biomtemp1 > $biomtemp2
	wait

## Reorder input map to match transformed OTU table
	head -1 $map > $maptemp0
	for line in `cat $biomtemp2 | cut -f1`; do
	grep -w "^$line" $map >> $maptemp0
	done

## Remove sample ID column from OTU table
	cat $biomtemp2 | cut -f2- > $biomtemp3

## Get factor column from map file
	fcol=`awk -v factor="$factor" -v map="$maptemp0" '{ for(i=1;i<=NF;i++){if ($i == factor) {print i}}}' $map`

## Set output directory and call indicator_species.r script
	outdir="Indicspecies_${factor}_${biomname}"
	outfile="$outdir/Statistical_summary.txt"
	outfile0="Statistical_summary.txt"
	rm -r $outdir 2>/dev/null
	mkdir $outdir
	echo "
akutils indicator species analysis script.
$date0
Supplied OTU table:	$biom
Input factor: 		$factor" > $outfile
	Rscript $scriptdir/indicator_species.r $maptemp0 $biomtemp3 $factor $outdir 1>>$outfile 2>/dev/null
	wait

## Copy transformed files and R instructions into output directory
	cp $maptemp0 $outdir/map.indicspecies.txt
	cp $biomtemp3 $outdir/otutable.indicspecies.txt
	cp $repodir/akutils_resources/R-instructions_indicspecies.txt $outdir/

## Report end of script
	echo "Analysis complete.

Output directory: ${bold}${outdir}${normal}
Statistics:	${bold}${outfile0}${normal}
Map file (R):	${bold}map.indicspecies.txt${normal}
Dis matrix (R):	${bold}otutable.indicspecies.txt${normal}
R instructions:	${bold}R-instructions_indicspecies.txt${normal}
	"

exit 0
