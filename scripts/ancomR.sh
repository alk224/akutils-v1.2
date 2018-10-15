#!/usr/bin/env bash
#
#  ancomR.sh - Test a biom-formatted OTU table in the R package ANCOM according to a QIIME-formatted mapping file and supplied factor
#
#  Version 1.0.0 (February, 17, 2016)
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
#set -e

## Trap function on exit.
function finish {
if [[ -f $tempfile0 ]]; then
	rm $tempfile0
fi
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
if [[ -f $tempfile5 ]]; then
	rm $tempfile5
fi
if [[ -f $tempfile6 ]]; then
	rm $tempfile6
fi
if [[ -f $biomtemp ]]; then
	rm $biomtemp
fi
if [[ -f $biomtemp0 ]]; then
	rm $biomtemp0
fi
if [[ -f $stdout ]]; then
	rm $stdout
fi
if [[ -f $stderr ]]; then
	rm $stderr
fi
}
trap finish EXIT

## Set variables
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=$(dirname $scriptdir)
	akutilsresdir="$repodir/akutils_resources/"
	workdir=$(pwd)
	tempdir="$repodir/temp"
	randcode=`cat /dev/urandom |tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1` 2>/dev/null
	biomtemp0="$tempdir/$randcode.biomtemp0.biom"
	tempfile0="$tempdir/$randcode.convert0.temp"
	tempfile1="$tempdir/$randcode.convert1.temp"
	tempfile2="$tempdir/$randcode.convert2.temp"
	tempfile3="$tempdir/$randcode.map.temp"
	tempfile4="$tempdir/$randcode.convert4.temp"
	tempfile5="$tempdir/$randcode.convert5.temp"
	tempfile6="$tempdir/$randcode.convert6.temp"
	biomtemp="$tempdir/$randcode.biom.temp"
	stdout="$tempdir/$randcode.stdout.temp"
	stderr="$tempdir/$randcode.stderr.temp"
	input="$1"
	map="$2"
	factor="$3"
	alpha="$4"
	cores="$5"

	date0=$(date +%Y%m%d_%I%M%p)

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

## Check whether user had supplied -h or --help. If yes display help 
	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
	less $repodir/docs/ancomR.help
		exit 0
	fi

## If incorrect number of arguments supplied, display usage 
	if [[ "$#" -ne 5 ]]; then 
	cat $repodir/docs/ancomR.usage
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

## Test for presence of ancom.R
	ancomrtest=$(Rscript $scriptdir/ancom_test.r | wc -l)
	if [[ "$ancomrtest" -ge "1" ]]; then
	echo "
This script requires the ancom.R library to be available in order to run. Ensure
it is properly installed (or loaded) before running this script again.
You can obtain ancom.R here: https://www.niehs.nih.gov/research/resources/software/biostatistics/ancom/index.cfm
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

## Parse input file
	inbase=$(basename $input .biom)
	inext="${1##*.}"
	inpath="${1%.*}"
	inname="${inpath##*/}"
	indir=$(dirname $1)
	outdir="$workdir/ANCOM_${inbase}_${factor}/"

	mkdir -p $outdir

## Test for valid input
	if [[ ! -f $input ]]; then
		echo "
Input file not found. Check your spelling and re-enter command.
Exiting.
		"
		exit 1
	fi
	if [[ "$inext" != "biom" ]]; then
		echo "
Input file does not have valid extension. Input must have biom extension.
Exiting.
		"
		exit 1
	fi
		if [[ ! -f $map ]]; then
		echo "
Mapping file not found. Check your spelling and re-enter command.
Exiting.
		"
		exit 1
	fi

## Check if supplied factor is valid according to mapping file or exit
	factortest=$(head -1 $map | grep -w $factor | wc -l)
	if [[ "$factortest" -ne "1" ]]; then
		echo "
Supplied factor not found in mapping file. Check your spelling and re-enter
command. Exiting.
		"
		exit 1
	fi
## Check if supplied alpha is a decimal or exit
	if ! [[ "$alpha" =~ ^[0]+(\.[0-9]+)$ ]]; then
		echo "
Supplied alpha level is not a decimal between 0 and 1. You supplied ${bold}${alpha}${normal}.
Exiting.
		"
		exit 1
	fi

## Convert biom file to txt and copy to tempdir for processing
	cp $input $biomtemp0
	wait
	biomtemp0base=$(basename $biomtemp0 .biom)
	biomtotxt.sh $biomtemp0 &>/dev/null
	wait
	mv $tempdir/$biomtemp0base.txt $tempfile0
	wait

## Test for initial header in some converted OTU tables and remove as necessary
	headtest=$(grep "Constructed from biom file" $tempfile0 2>/dev/null | wc -l)
	if [[ "$headtest" -ge "1" ]]; then
		sed -i '/# Constructed from biom file/d' $tempfile0
	fi
	wait

## Change OTU ID to Group
	sed -i 's/#OTU ID/Group/' $tempfile0
	wait

## Get column from OTU table that contains the taxonomy string
	column0=`awk -v table="$tempfile0" '{ for(i=1;i<=NF;i++){if ($i ~ /taxonomy/) {print i}}}' $tempfile0`
	column1=`expr $column0 - 2`

## Get factor column from map file and make tempfile to relate sample ID to factor
	fact=`awk -v factor="$factor" -v map="$map" '{ for(i=1;i<=NF;i++){if ($i == factor) {print i}}}' $map`

	grep -v "#" $map | cut -f1,${fact} > $tempfile3
	wait

## Remove taxonomy field
	cat $tempfile0 | cut -f1-${column1} > $tempfile1
	wait

## If this is a summarized table, remove all but the deepest taxonomic identifier (using semicolon as delimiter)
	sctest=$(cat $tempfile1 | cut -f1 | grep ";" | wc -l)
	if [[ "$sctest" -ge "1" ]]; then
		sed -i "s/^.\+;//g" $tempfile1
	fi
	wait

## Transpose table
	datamash transpose < $tempfile1 > $tempfile2
	wait

## Replace sample IDs with factor according to mapping file
	for line in `cat $tempfile3 | cut -f1`; do
		linetest=$(grep -w $line $tempfile2 | wc -l)
		if [[ $linetest -ge 1 ]]; then
		new=`grep -w $line $tempfile3 | cut -f2`
		sed -i "s/^$line\s/$new\t/" $tempfile2
		fi
	done
	wait

## Move first column to end, writing to output
	numcols=`awk '{print NF}' $tempfile2 | tail -n1`
	cat $tempfile2 | cut -f1 > $tempfile4
	cat $tempfile2 | cut -f2-${numcols} > $tempfile5
	wait
	paste $tempfile5 $tempfile4 > $tempfile6
	wait

echo "Ancom-friendly conversion complete.
Beginning statistical comparisons. Please be patient.
User-defined significance level: ${bold}${alpha}${normal}
"

## Copy transformed OTU file and instructions into output directory
	manfile0="otufile_for_ancom.txt"
	manfile="$outdir/otufile_for_ancom.txt"
	cp $tempfile6 $manfile
	cp $repodir/akutils_resources/R-instructions_ancom.r $outdir
	wait

## Copy transformed files to output (debugging only)
#	cp $tempfile0 $outdir/tempfile0.txt
#	cp $tempfile1 $outdir/tempfile1.txt
#	cp $tempfile2 $outdir/tempfile2.txt
#	cp $tempfile3 $outdir/tempfile3.txt
#	cp $tempfile4 $outdir/tempfile4.txt
#	cp $tempfile5 $outdir/tempfile5.txt
#	cp $tempfile6 $outdir/tempfile6.txt

## Run ancom.R
	Rscript $scriptdir/ancomR.r $tempfile6 $factor $outdir $alpha $akutilsresdir $cores 1> $stdout 2> $stderr
	wait

## Collate Detections and statistical summary
	uncorout="$outdir/ANCOM_detections_${factor}_uncorrected.txt"
	fdr1="$outdir/ANCOM_detections_${factor}_FDRstrict.txt"
	fdr2="$outdir/ANCOM_detections_${factor}_FDRrelaxed.txt"
	uncorpdf="ANCOM_${factor}_1.pdf"
	fdrpdf1="ANCOM_${factor}_2.pdf"
	fdrpdf2="ANCOM_${factor}_3.pdf"

	echo "
ANCOM citation:
Mandal S., Van Treuren W., White RA., Eggesbø M., Knight R., Peddada SD. 2015.
Analysis of composition of microbiomes: a novel method for studying microbial
composition. Microbial ecology in health and disease 26:27663." > $outdir/Statistical_summary.txt
	echo "
User-defined significance level = $alpha" >> $outdir/Statistical_summary.txt
	echo "
Corrected detections (strict FDR):" >> $outdir/Statistical_summary.txt
	cat $fdr1 >> $outdir/Statistical_summary.txt 2>/dev/null
	echo "
Corrected detections (relaxed FDR):" >> $outdir/Statistical_summary.txt
	cat $fdr2 >> $outdir/Statistical_summary.txt 2>/dev/null
	echo "
Uncorrected detections:" >> $outdir/Statistical_summary.txt
	cat $uncorout >> $outdir/Statistical_summary.txt 2>/dev/null
	echo "" >> $outdir/Statistical_summary.txt
	cat $outdir/Rstats.txt >> $outdir/Statistical_summary.txt 2>/dev/null
	echo "
********************************************************************************
R script logging below here.

stdout:" >> $outdir/Statistical_summary.txt
	cat $stdout >> $outdir/Statistical_summary.txt 2>/dev/null
	echo "
stderr:" >> $outdir/Statistical_summary.txt
	cat $stderr >> $outdir/Statistical_summary.txt 2>/dev/null
	echo "" >> $outdir/Statistical_summary.txt

## Test for output, print completion and outputs, remove unwanted files
	uncortest=$(grep "No significant OTUs detected" $uncorout 2>/dev/null | wc -l)
	fdrtest1=$(grep "No significant OTUs detected" $fdr1 2>/dev/null | wc -l)
	fdrtest2=$(grep "No significant OTUs detected" $fdr2 2>/dev/null | wc -l)
	rm $outdir/Rstats.txt 2>/dev/null
	if [[ -f "Rplots.pdf" ]]; then
		rm Rplots.pdf 2>/dev/null
	fi
	rm $uncorout $fdr1 $fdr2 2>/dev/null

echo "Comparisons complete.
Output directory: ${bold}${outdir}${normal}
Statistics (W) and detections: ${bold}Statistical_summary.txt${normal}
Detection plots: ${bold}Detection_plots.pdf${normal}
OTU file for manual use: ${bold}${manfile0}${normal}
R instructions (ancomR): ${bold}R-instructions_ancom.r${normal}
"
wait

exit 0
