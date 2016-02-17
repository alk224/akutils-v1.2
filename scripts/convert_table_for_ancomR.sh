#!/usr/bin/env bash
#
#  convert_table_for_ancomR.sh - prepare a tab-delimited OTU table for analysis in the R package ANCOM
#
#  Version 1.0.0 (February, 17, 2016)
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
}
trap finish EXIT

## Set variables
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=$(dirname $scriptdir)
	workdir=$(pwd)
	tempdir="$repodir/temp"
	randcode=`cat /dev/urandom |tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1` 2>/dev/null
	tempfile0="$randcode.convert0.temp"
	tempfile1="$randcode.convert1.temp"
	tempfile2="$randcode.convert2.temp"
	tempfile3="$randcode.map.temp"
	tempfile4="$randcode.convert4.temp"
	tempfile5="$randcode.convert5.temp"
	input="$1"
	map="$2"
	factor="$3"

	date0=$(date +%Y%m%d_%I%M%p)

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

## Check whether user had supplied -h or --help. If yes display help 
	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	less $scriptdir/docs/convert_table_for_ancomR.help
		exit 0
	fi

## If incorrect number of arguments supplied, display usage 
	if [[ "$#" -ne 3 ]]; then 
	cat $repodir/docs/convert_table_for_ancomR.usage
		exit 1
	fi 

## Parse input file
	inbase=$(basename $1 .txt)
	inext="${1##*.}"
	inpath="${1%.*}"
	inname="${inpath##*/}"
	indir=$(dirname $1)

## Define output file
	output="${indir}/${inbase}_ancomR_${factor}.txt"
	if [[ -f $output ]]; then
		rm $output
	fi

## Test for valid input
	if [[ ! -f $input ]]; then
		echo "
Input file not found. Check your spelling and re-enter command.
Exiting.
		"
		exit 1
	fi
	if [[ "$inext" != "txt" ]]; then
		echo "
Input file does not have valid extension. Input must have txt extension.
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

## Copy input to tempdir for processing
	cp $input $tempfile0

## Test for initial header in some converted OTU tables and remove as necessary
	headtest=$(grep "Constructed from biom file" $tempfile0 2>/dev/null | wc -l)
	if [[ "$headtest" -ge "1" ]]; then
		sed -i '/# Constructed from biom file/d' $tempfile0
	fi

## Change OTU ID to Group
	sed -i 's/#OTU ID/Group/' $tempfile0

## Get column from OTU table that contains the taxonomy string
	column0=`awk -v table="$tempfile0" '{ for(i=1;i<=NF;i++){if ($i ~ /taxonomy/) {print i}}}' $tempfile0`
	column1=`expr $column0 - 2`

## Get factor column from map file and make tempfile to relate sample ID to factor
	fact=`awk -v factor="$factor" -v map="$map" '{ for(i=1;i<=NF;i++){if ($i ~ factor) {print i}}}' $map`
	grep -v "#" $map | cut -f1,${fact} > $tempfile3

## Remove taxonomy field
	cat $tempfile0 | cut -d$'\t' -f1-${column1} > $tempfile1

## Transpose table
	awk '
{ 
    for (i=1; i<=NF; i++)  {
        a[NR,i] = $i
    }
}
NF>p { p = NF }
END {    
    for(j=1; j<=p; j++) {
        str=a[1,j]
        for(i=2; i<=NR; i++){
            str=str" "a[i,j];
        }
        print str
    }
}' $tempfile1 > $tempfile2

## Replace spaces in transposed table with tabs (would like to correct awk string to do this instead)
	sed -i 's/\s/\t/g' $tempfile2

## Replace sample IDs with factor according to mapping file
	for line in `cat $tempfile3 | cut -f1`; do
		new=`grep -w $line $tempfile3 | cut -f2`
		sed -i "s/^$line\s/$new\t/" $tempfile2
	done

## Move first column to end, writing to output
	numcols=`awk '{print NF}' $tempfile2 | tail -n1`
	cat $tempfile2 | cut -f1 > $tempfile4
	cat $tempfile2 | cut -f2-${numcols} > $tempfile5
	paste $tempfile5 $tempfile4 > $output

echo "
Conversion complete.
Output: $output
"
exit 0
