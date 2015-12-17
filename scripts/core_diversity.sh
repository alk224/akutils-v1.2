#!/usr/bin/env bash
#
#  core_diversity.sh - Core diversity analysis through QIIME for OTU table analysis
#
#  Version 2.0 (December 16, 2015)
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
## Trap function on exit.
function finish {
if [[ -f $cdivtemp ]]; then
	rm $cdivtemp
fi
if [[ -f $tablelist ]]; then
	rm $tablelist
fi
if [[ -f $catlist ]]; then
	rm $catlist
fi
if [[ -f $insamples ]]; then
	rm $insamples
fi
if [[ -f $raresamples ]]; then
	rm $raresamples
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
	input="$5"
	mapfile="$6"
	cats="$7"
	cores="$8"
	threads=$(($cores+1))

	date0=$(date +%Y%m%d_%I%M%p)
	res0=$(date +%s.%N)

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

## Define temp files
	cdivtemp="$tempdir/${randcode}_cdiv.temp"
	tablelist="$tempdir/${randcode}_cdiv_tablelist.temp"
	catlist="$tempdir/${randcode}_cdiv_categories.temp"

## If incorrect number of arguments supplied, display usage 
	if [[ "$#" -ne 8 ]]; then 
	cat $repodir/docs/core_diversity.usage
		exit 1
	fi

## Read in variables from config file
	tree=(`grep "Tree" $config | grep -v "#" | cut -f 2`)
	cores=(`grep "CPU_cores" $config | grep -v "#" | cut -f 2`)
	adepth=(`grep "Rarefaction_depth" $config | grep -v "#" | cut -f 2`)
	threads=$(($cores-1))

## Find log file or set new one. ## NEED TO EDIT SO A LOG GOES TO EACH ANALYSIS DIRECTORY
	rm log_core_diversity*~ 2>/dev/null
	logcount=$(ls log_core_diversity* 2>/dev/null | head -1 | wc -l)
	if [[ "$logcount" -eq 1 ]]; then
		log=`ls log_core_diversity*.txt | head -1`
	elif [[ "$logcount" -eq 0 ]]; then
		log="$workdir/log_core_diversity_$date0.txt"
	fi
	echo "
${bold}akutils core_diversity workflow beginning.${normal}
	"
	echo "
akutils core_diversity workflow beginning." >> $log
	date >> $log

## Set workflow mode (table, directory, prefix, ALL) and send list of tables to temp file
	if [[ -f "$input" && "$input" == *.biom ]]; then
	mode="table"
	echo "$input" > $tablelist
	fi
	if [[ "$input" == "ALL" ]]; then
	mode="ALL"
	find . -mindepth 3 -maxdepth 3 -name "*.biom" 2>/dev/null | grep -v "_CSS.biom" | grep -v "_DESeq2.biom" > $tablelist
	fi
	prefixtest=$(find . -mindepth 3 -maxdepth 3 -name "$input.biom" 2>/dev/null | grep -v "_CSS.biom" | grep -v "_DESeq2.biom" | wc -l)
	if [[ "$prefixtest" -ge 1 ]]; then
	mode="prefix"
	find . -mindepth 3 -maxdepth 3 -name "$input.biom" 2>/dev/null | grep -v "_CSS.biom" | grep -v "_DESeq2.biom" > $tablelist
	fi
	if [[ -d "$input" ]]; then
	mode="directory"
	find $input -name "*.biom" 2>/dev/null | grep -v "_CSS.biom" | grep -v "_DESeq2.biom" > $tablelist
	fi

	## Exit if above tests failed to add any files to tablelist
	if [[ ! -f $tablelist ]]; then
	echo "Failed to locate any tables to process with supplied input.
You supplied: $input

Exiting.
	"
	exit 1
	fi

	res0=$(date +%s.%N)

echo "
$mode
"

## Make categories temp file
	echo "Parsing input categories.
	"
	bash $scriptdir/parse_cats.sh $stdout $stderr $log $mapfile $cats $catlist $randcode $tempdir

## Make normalized tables if necessary

#	echo "Normalizing tables if necessary.
#	"
#	bash $scriptdir/norm_tables.sh $stdout $stderr $log $tablelist $threads

################################################################################
## Start of for loop to process each table in the master list sequentially
################################################################################

for table in `cat $tablelist`; do

		## Define table-specific variables, make output directory if necessary
		## and move table there for normalizing, rarefaction, and filtering
		inputdir=$(dirname $table)
		inputbase=$(basename $table .biom)
		outdir="$inputdir/core_diversity/$inputbase"
		tabledir="$outdir/OTU_tables"
		if [[ ! -d $outdir ]]; then
			mkdir -p $outdir
		fi
		if [[ ! -d $tabledir ]]; then
			mkdir -p $tabledir
		fi
		if [[ ! -f $tabledir/$inputbase.biom ]]; then
			cp $table $tabledir
		fi
		intable="$tabledir/$inputbase.biom"
		insummary="$tabledir/$inputbase.summary"

		## Find log file or set new one. ## NEED TO EDIT SO A LOG GOES TO EACH ANALYSIS DIRECTORY
		rm log_core_diversity*~ 2>/dev/null
		logcount=$(ls $outdir/log_core_diversity* 2>/dev/null | head -1 | wc -l)
		if [[ "$logcount" -eq 1 ]]; then
		log=`ls $outdir/log_core_diversity*.txt | head -1`
		elif [[ "$logcount" -eq 0 ]]; then
		log="$outdir/log_core_diversity_$date0.txt"
		fi
		echo "
${bold}akutils core_diversity workflow beginning.${normal}"
		echo "
akutils core_diversity workflow beginning." >> $log
		date >> $log

		## Summarize input table
		biom-summarize_folder.sh $tabledir &>/dev/null

		## Determine rarefaction depth
		if [[ $adepth =~ ^[0-9]+$ ]]; then
		depth=($adepth)
		else
		depth=`awk '/Counts\/sample detail:/ {for(i=1; i<=1; i++) {getline; print $NF}}' $tabledir/$inputbase.summary | awk -F. '{print $1}'`
		fi

		## Rarefy input table according to established depth
		raretable="$tabledir/table_even$depth.biom"
		raresummary="$tabledir/table_even$depth.summary"
		if [[ ! -f $raretable ]]; then
		echo "
Input table: $table
Rarefying input table according to config file.
Depth: $depth"

		echo "
Input table: $table
Rarefying input table according to config file.
Depth: $depth" >> $log

		echo "
Single rarefaction command:
	single_rarefaction.py -i $intable -o $raretable -d $depth" >> $log
		single_rarefaction.py -i $intable -o $raretable -d $depth 1> $stdout 2> $stderr
		bash $scriptdir/log_slave.sh $stdout $stderr $log
		fi

		biom-summarize_folder.sh $tabledir &>/dev/null
		rarebase=$(basename $raretable .biom)

		## Filter any samples removed by rarefying from the original input table
		inlines0=$(cat $insummary | wc -l)
		inlines=$(($inlines0-14))
		rarelines0=$(cat $raresummary | wc -l)
		rarelines=$(($rarelines0-14))

		insamples="$tempdir/${randcode}_insamples.temp"
		raresamples="$tempdir/${randcode}_raresamples.temp"
		cat $insummary | tail -$inlines | cut -d":" -f1 > $insamples
		cat $raresummary | tail -$rarelines | cut -d":" -f1 > $raresamples
		insamplecount=$(cat $insamples | wc -l)
		raresamplecount=$(cat $raresamples | wc -l)
		diffcount=$(($insamplecount-$raresamplecount))

		echo "
Filtering any samples removed during rarefaction."
		echo "
Filtering any samples removed during rarefaction." >> $log
		filtertable="$tabledir/sample_filtered_table.biom"
		filter_samples_from_otu_table.py -i $intable -o $filtertable --sample_id_fp $raresamples
		echo "filter_samples_from_otu_table.py -i $intable -o $filtertable --sample_id_fp $raresamples" >> $log
		echo "
Removed $diffcount samples from the analysis:"
		echo "
Removed $diffcount samples from the analysis:" >> $log
		grep -vFf $raresamples $insamples
		grep -vFf $raresamples $insamples >> $log

		## Normalize filtered table with CSS and DESeq2 transformations
		CSStable="$tabledir/CSS_table.biom"
		DESeq2table="$tabledir/DESeq2_table.biom"
		if [[ ! -f $CSStable ]]; then
		echo "
Normalizing sample-filtered table with CSS transformation."
		echo "
Normalizing sample-filtered table with CSS transformation.
normalize_table.py -i $filtertable -o $CSStable -a CSS" >> $log
			if [[ ! -f $CSStable ]]; then
			 normalize_table.py -i $filtertable -o $CSStable -a CSS 2>/dev/null
			fi
#			if [[ ! -f $DESeq2table ]]; then
#			( normalize_table.py -i $filtertable -o $DESeq2table -a DESeq2 2>/dev/null ) &
#			fi
		wait
		fi
	
		## Summarize tables one last time and initiate html output
		biom-summarize_folder.sh $tabledir &>/dev/null
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist

		## Sort OTU tables
		CSSsort="$outdir/OTU_tables/CSS_table_sorted.biom"
		if [[ ! -f $CSSsort ]]; then
		sort_otu_table.py -i $CSStable -o $CSSsort
		fi
		raresort="$outdir/OTU_tables/table_even${depth}_sorted.biom"
		if [[ ! -f $raresort ]]; then
		sort_otu_table.py -i $raretable -o $raresort
		fi

		## Find phylogenetic tree or set mode nonphylogenetic

exit 0
done
## If function to control mode and for loop for batch processing start here

	if [[ $mode == "table" ]]; then

	## Check for valid input (file has .biom extension)

	biombase_fields=`echo $biombase | grep -o "_" | wc -l`
	outbase=`basename "$1" | cut -d. -f1 | cut -d"_" -f1-$biombase_fields`
	biomextension="${1##*.}"
	biomname="${1%.*}"
	biomdir=$(dirname $1)

	if [[ $biomextension != "biom" ]]; then
	echo "
	Input file is not a biom file.  Check your input and try again.
	Exiting.
	"
	exit 1
	else
	table=$1

	## Check for associated phylogenetic tree and set analysis mode
	OTUdir=$(dirname $biomdir)
	if [[ -f "$OTUdir/pynast_alignment/fasttree_phylogeny.tre" ]]; then
	analysis="Phylogenetic"
	metrics="bray_curtis,chord,hellinger,kulczynski,unweighted_unifrac,weighted_unifrac"
	tree="$OTUdir/pynast_alignment/fasttree_phylogeny.tre"
	elif [[ -f "$OTUdir/mafft_alignment/fasttree_phylogeny.tre" ]]; then
	analysis="Phylogenetic"
	metrics="bray_curtis,chord,hellinger,kulczynski,unweighted_unifrac,weighted_unifrac"
	tree="$OTUdir/mafft_alignment/fasttree_phylogeny.tre"
	else
	analysis="Nonhylogenetic"
	metrics="bray_curtis,chord,hellinger,kulczynski"
	fi

	## Summarize input table(s) if necessary and extract rarefaction depth from shallowest sample
	if [[ ! -f $biomdir/$biombase.summary ]]; then
	biom-summarize_folder.sh $biomdir &>/dev/null
	fi
	depth=`grep -A 1 "Counts/sample detail" $biomdir/$biombase.summary | sed '/Counts/d' | cut -d" " -f3 | cut -d. -f1`

	## Set output directory
	outdir=$biomdir/core_diversity/$outbase
	outdir1=$biomdir/core_diversity
	mkdir -p $outdir

	## Check for normalized table
	normbase=`echo $biombase | sed 's/hdf5/CSS/'`
	normcount=`ls $biomdir/$normbase.biom 2>/dev/null | wc -l`
	if [[ $normcount == "0" ]]; then
	normtable="None supplied"
	else
	normtable="$biomdir/$normbase.biom"
	fi

	echo "Normalized table: $normtable
Output: $outdir
Rarefaction depth: $depth
Analysis: $analysis
	"
	echo "Normalized table: $normtable
Output: $outdir
Rarefaction depth: $depth
Analysis: $analysis
	" >> $log

	if [[ $normcount == "1" ]]; then
	echo "Calling normalized_table_beta_diversity.sh function.
"
	echo "Calling normalized_table_beta_diversity.sh function.
Command:
bash $scriptdir/normalized_table_beta_diversity.sh <normalized_table> <output_dir> <mapping_file> <cores> <optional_tree>
bash $scriptdir/normalized_table_beta_diversity.sh $normtable $outdir $mapfile $cores $tree
" >> $log
	bash $scriptdir/normalized_table_beta_diversity.sh $normtable $outdir $mapfile $cores $tree
	fi

	echo "Calling nonnormalized_table_diversity_analyses.sh function.
"
	echo "Calling nonnormalized_table_diversity_analyses.sh function.
Command:
bash $scriptdir/nonnormalized_table_diversity_analyses.sh <OTU_table> <output_dir> <mapping_file> <cores> <rarefaction_depth> <optional_tree>
bash $scriptdir/nonnormalized_table_diversity_analyses.sh $table $outdir $mapfile $cores $depth $tree
" >> $log
	bash $scriptdir/nonnormalized_table_diversity_analyses.sh $table $outdir $mapfile $cats $cores $depth $tree
	fi

	elif [[ $mode == "batch" ]]; then
	ls | grep "_otus_" > $tempdir/otupickdirs.temp
	echo > $tempdir/batch_tablecount.temp
	for line in `cat $tempdir/otupickdirs.temp`; do
	for otutabledir in `ls $line 2>/dev/null | grep "OTU_tables"`; do
	eachtablecount=`ls $line/$otutabledir/${input}_table_hdf5.biom 2>/dev/null | wc -l`
	if [[ $eachtablecount == 1 ]]; then
	echo $eachtablecount >> $tempdir/batch_tablecount.temp
	fi
	done
	done
	sed -i '/^\s*$/d' $tempdir/batch_tablecount.temp
	alltablescount=`cat $tempdir/batch_tablecount.temp | wc -l`
	if [[ $alltablescount == 0 ]]; then
	echo "
No OTU tables found matching the supplied prefix.  To perform batch
processing, execute cdiv_graphs_and_stats_workflow.sh from the same
directory you processed the rest of your data.  If you want to target
the tables matching \"03_table_hdf5.biom\" and the associated normalized
table, you would enter \"03\" as the prefix.

You supplied: $input

Exiting.
	"
	else
	echo "Processing core diversity analyses for $alltablescount OTU tables.
	"

	# Build list of tables to process
	echo > $tempdir/batch_tablelist.temp
	for line in `cat $tempdir/otupickdirs.temp`; do
	for otutabledir in `ls $line 2>/dev/null | grep "OTU_tables"`; do
	if [[ -f $line/$otutabledir/${input}_table_hdf5.biom ]]; then
	echo $line/$otutabledir/${input}_table_hdf5.biom >> $tempdir/batch_tablelist.temp
	fi
	done
	done

	# Process tables loop
	for table in `cat $tempdir/batch_tablelist.temp`; do
	## Check for valid input (file has .biom extension)
	biombase=`basename "$table" | cut -d. -f1`
	outbase=`basename "$table" | cut -d. -f1 | cut -d"_" -f1-2`
	biomextension="${table##*.}"
	biomname="${table%.*}"
	biomdir=$(dirname $table)
	## Check for associated phylogenetic tree and set analysis mode for each table
	OTUdir=$(dirname $biomdir)
	if [[ -f "$OTUdir/pynast_alignment/fasttree_phylogeny.tre" ]]; then
	analysis="Phylogenetic"
	metrics="bray_curtis,chord,hellinger,kulczynski,unweighted_unifrac,weighted_unifrac"
	tree="$OTUdir/pynast_alignment/fasttree_phylogeny.tre"
	elif [[ -f "$OTUdir/mafft_alignment/fasttree_phylogeny.tre" ]]; then
	analysis="Phylogenetic"
	metrics="bray_curtis,chord,hellinger,kulczynski,unweighted_unifrac,weighted_unifrac"
	tree="$OTUdir/mafft_alignment/fasttree_phylogeny.tre"
	else
	analysis="Nonhylogenetic"
	metrics="bray_curtis,chord,hellinger,kulczynski"
	fi	
	## Summarize input table(s) if necessary and extract rarefaction depth from shallowest sample
	if [[ ! -f $biomdir/$biombase.summary ]]; then
	biom-summarize_folder.sh $biomdir &>/dev/null
	fi
	depth=`grep -A 1 "Counts/sample detail" $biomdir/$biombase.summary | sed '/Counts/d' | cut -d" " -f3 | cut -d. -f1`

	## Check for normalized table
	normbase=`echo $biombase | sed 's/hdf5/CSS/'`
	normcount=`ls $biomdir/$normbase.biom 2>/dev/null | wc -l`
	if [[ $normcount == "0" ]]; then
	normtable="None supplied"
	else
	normtable="$biomdir/$normbase.biom"
	fi

	## Set output directory
	outdir=$biomdir/core_diversity/$outbase
	outdir1=$biomdir/core_diversity
	mkdir -p $outdir

	echo "Input table: $table
Normalized table: $normtable
Output: $outdir
Rarefaction depth: $depth
Analysis: $analysis
	"
	echo "Input table: $table
Normalized table: $normtable
Output: $outdir
Rarefaction depth: $depth
Analysis: $analysis
	" >> $log
	echo "Calling normalized_table_beta_diversity.sh function.
"
	echo "Calling normalized_table_beta_diversity.sh function.
Command:
bash $scriptdir/normalized_table_beta_diversity.sh <normalized_table> <output_dir> <mapping_file> <cores> <optional_tree>
bash $scriptdir/normalized_table_beta_diversity.sh $normtable $outdir $mapfile $cores $tree
" >> $log
	bash $scriptdir/normalized_table_beta_diversity.sh $normtable $outdir $mapfile $cores $tree

	echo "Calling nonnormalized_table_diversity_analyses.sh function.
"
	echo "Calling nonnormalized_table_diversity_analyses.sh function.
Command:
bash $scriptdir/nonnormalized_table_diversity_analyses.sh <OTU_table> <output_dir> <mapping_file> <cores> <rarefaction_depth> <optional_tree>
bash $scriptdir/nonnormalized_table_diversity_analyses.sh $table $outdir $mapfile $cores $depth $tree
" >> $log
	bash $scriptdir/nonnormalized_table_diversity_analyses.sh $table $outdir $mapfile $cats $cores $depth $tree
	done
	fi
	fi

## Tidy up
#	if [[ -d cdiv_temp ]]; then
#	rm -r cdiv_temp
#	fi

## Log end of workflow and exit

res1=$(date +%s.%N)
dt=$(echo "$res1 - $res0" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)

runtime=`printf "Total runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`

if [[ $mode == "table" ]]; then
	alltablescount="1"
fi

echo "All cdiv_graphs_and_stats_workflow.sh steps completed.  Hooray!
Processed $alltablescount OTU tables.
$runtime
"
echo "All cdiv_graphs_and_stats_workflow.sh steps completed.  Hooray!
Processed $alltablescount OTU tables.
$runtime
" >> $log

exit 0

