#!/usr/bin/env bash
##
## get_otus_from_ghost_tree.sh - bash wrapper for using the get_otus_from_ghost_tree.py script
## 
#  Version 1.1.0 (June 16, 2015)
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
##
## Usage:
##	get_otus_from_ghost_tree.sh 
##
## Trap function on exit.
function finish {
if [[ -f $tipfile ]]; then
	rm $tipfile
fi
if [[ -f $OTUidstemp1 ]]; then
	rm $OTUidstemp1
fi
if [[ -f $OTUidstemp2 ]]; then
	rm $OTUidstemp2
fi
if [[ -f $tempdir/${randcode}_tree.temp ]]; then
	rm $tempdir/${randcode}_tree.temp
fi
if [[ -f $stderr ]]; then
	rm $stderr
fi
if [[ -f $stdout ]]; then
	rm $stdout
fi
}
trap finish EXIT

## Define variables
	workdir=$(pwd)
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=`dirname $scriptdir`
	tempdir="$repodir/temp/"
	stderr=($repodir/temp/$randcode\_stderr)
	stdout=($repodir/temp/$randcode\_stdout)
	randcode=`cat /dev/urandom |tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1` 2>/dev/null
	biom="$1"
	tree="$2"
	taxfile="$3"
	tipfile="${tempdir}/${randcode}_ghost_tree_tips.txt"
	OTUidstemp1="$tempdir/${randcode}_otuids1.temp"
	OTUidstemp2="$tempdir/${randcode}_otuids2.temp"

## Usage and help
	usage="$repodir/docs/preprocess_otus_for_ghost-tree.usage"
	help="$repodir/docs/preprocess_otus_for_ghost-tree.help"

## Check whether user supplied help, -h or --help. If yes display help.
	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "help" ]]; then
	less $help
		exit 0	
	fi

## If other than one argument supplied, display usage
	if [[ "$#" -ne "2" && "$#" -ne "3" ]]; then
	cat $usage
	exit 1
	fi

## Establish additional variables
	biombase=$(basename $biom .biom)
	treebase=$(basename $tree)
	otudir=$(dirname $biom)
	outdir0=$(dirname $otudir)
	outdir="${outdir0}/ghost-tree_output_${biombase}"
	validtaxa="$outdir/tax_assignments_filtered_against_input_ghost-tree.txt"
	otukey="$outdir/otu_list.txt"
	modtree="${outdir}/${biombase}_${treebase}"
	log="$outdir/preprocess_otus_for_ghost-tree.log"

## Make and clear output directory if necessary, establish log
	mkdir -p $outdir &>/dev/null
	rm -r $outdir/* &>/dev/null
	echo "
Processing data for use with ghost-tree file.

Input OTU table: $biom
Input tree file: $tree" > $log
	if [[ ! -z $taxfile ]]; then
	echo "Input taxonomy file: $taxfile" >> $log
	fi
	echo "" >> $log

## Export variables to be read in via python
	export tempdir
	export outdir
	export randcode
	export tree

## Filter input OTUs against supplied tree
	echo "
Filtering input OTU table against input tree"
	python $scriptdir/get_otus_from_ghost_tree.py 1>$stdout 2>$stderr
		bash $scriptdir/log_slave.sh $stdout $stderr $log

## Report mode and proceed as necessary
####################################
## building new tree with renamed tips if tax file supplied
	if [[ ! -z $taxfile ]]; then
	echo "
Taxonomy file supplied.  Will rename tree tips according to OTU names and provide
a modified tree file."

## Replace underscores in tree tips file, copy ghost-tree tree to output for processing
	echo "
Processing input tree to match OTU ID strings"
	sed -i 's/\s/_/g' $tipfile
	cp $tree $tempdir/${randcode}_tree.temp

## Make list of valid OTUs
	grep -Ff $tipfile $taxfile > $validtaxa
	cat $validtaxa | cut -f1 > $OTUidstemp1
	cat $validtaxa | cut -f4 > $OTUidstemp2
	paste $OTUidstemp1 $OTUidstemp2 > $otukey
	wait

## For loop with sed to replace taxID strings with OTUID strings
	for otuid in `cat $otukey | cut -f1`; do
		taxid=$(grep -w "$otuid" $otukey | cut -f2)
		#echo "taxid = $taxid, otuid = $otuid" ## uncomment for debugging
		sed -i "s/$taxid/$otuid/" $tempdir/${randcode}_tree.temp
	done
	wait

## Filter resulting tree to include only useful tips
	echo "
Filtering tree to include only useful tips"
	filter_tree.py -i $tempdir/${randcode}_tree.temp -o $modtree -t $otukey 1>$stdout 2>$stderr
		bash $scriptdir/log_slave.sh $stdout $stderr $log

## Filter otus from table against tip file
	echo "
Filtering OTU table for available tree tips"
	filter_otus_from_otu_table.py -i $biom -o $otudir/${biombase}_ghost-tree_filtered.biom -e $otukey --negate_ids_to_exclude 1>$stdout 2>$stderr
		bash $scriptdir/log_slave.sh $stdout $stderr $log

## Report completion
	if [[ -f $otudir/${biombase}_ghost-tree_filtered.biom && -f $modtree ]]; then
	echo "
Table filtered against ghost-tree file for use in downstream analysis.

Output OTU table: $otudir/${biombase}_ghost-tree_filtered.biom
Output tree file: $modtree
	"
	exit 0
	else
	echo "
There seems to have been a problem. Sorry I couldn't make your files. Check the
log file for obvious errors: $log
"
	exit 1
	fi

####################################
## normal workflow (no tax file supplied)
	else

## Filter otus from table against tip file
	echo "
Filtering OTU table for available tree tips"
	filter_otus_from_otu_table.py -i $biom -o $otudir/${biombase}_ghost-tree_filtered.biom -e $tipfile --negate_ids_to_exclude 1>$stdout 2>$stderr
		bash $scriptdir/log_slave.sh $stdout $stderr $log

## Report completion
	if [[ -f $otudir/${biombase}_ghost-tree_filtered.biom && -f $outdir/$modtree ]]; then
	echo "
Table filtered against ghost-tree file for use in downstream analysis.

Output OTU table: $otudir/${biombase}_ghost-tree_filtered.biom
	"
	exit 0
	else
	echo "
There seems to have been a problem. Sorry I couldn't make your file. Try supplying
a taxonomy file (output from assign_taxonomy.py) in case your OTU IDs do not match
those associated with your supplied tree from ghost-tree. Check the log file for
obvious errors: $log
"
	exit 1
	fi
	fi

exit 0
