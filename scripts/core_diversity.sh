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
		inputdirup1=$(dirname $inputdir)
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
			normalize_table.py -i $filtertable -o $CSStable -a CSS 1> $stdout 2> $stderr || true
			bash $scriptdir/log_slave.sh $stdout $stderr $log
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
		if [[ -f $inputdirup1/pynast_alignment/fasttree_phylogeny.tre ]]; then
		tree="$inputdirup1/pynast_alignment/fasttree_phylogeny.tre"
		phylogenetic="YES"
		fi
		if [[ -f $inputdirup1/mafft_alignment/fasttree_phylogeny.tre ]]; then
		tree="$inputdirup1/mafft_alignment/fasttree_phylogeny.tre"
		phylogenetic="YES"
		fi
		if [[ -z $phylogenetic ]]; then
		phylogenetic="NO"
		fi

		if [[ "$phylogenetic" == "YES" ]]; then
		metrics="bray_curtis,chord,hellinger,kulczynski,unweighted_unifrac,weighted_unifrac"
		echo "
Analysis will be phylogenetic."
		echo "
Analysis will be phylogenetic." >> $log
		elif [[ "$phylogenetic" == "NO" ]]; then
		metrics="bray_curtis,chord,hellinger,kulczynski"
		echo "
Analysis will be nonphylogenetic."
		echo "
Analysis will be nonphylogenetic." >> $log
		fi

################################################################################
## START OF NORMALIZED ANALYSIS HERE

	echo "
Processing normalized table."
	echo "
Processing normalized table." >> $log

## Summarize taxa (yields relative abundance tables)
	if [[ ! -d $outdir/bdiv_normalized/summarized_tables ]]; then
	echo "
Summarize taxa command:
	summarize_taxa.py -i $CSSsort -o $outdir/bdiv_normalized/summarized_tables -L 2,3,4,5,6,7" >> $log
	echo "
Summarizing taxonomy by sample and building plots."
	summarize_taxa.py -i $CSSsort -o $outdir/bdiv_normalized/summarized_tables -L 2,3,4,5,6,7 1> $stdout 2> $stderr
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi

## Beta diversity
	if [[ "$phylogenetic" == "YES" ]]; then
	echo "
Parallel beta diversity command:
	parallel_beta_diversity.py -i $table -o $outdir/bdiv_normalized/ --metrics $metrics -T  -t $tree --jobs_to_start $cores" >> $log
	echo "
Calculating beta diversity distance matrices."
	parallel_beta_diversity.py -i $table -o $outdir/bdiv_normalized/ --metrics $metrics -T  -t $tree --jobs_to_start $cores 1> $stdout 2> $stderr
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	elif [[ "$phylogenetic" == "NO" ]]; then
	echo "
Parallel beta diversity command:
	parallel_beta_diversity.py -i $table -o $outdir/bdiv_normalized/ --metrics $metrics -T --jobs_to_start $cores" >> $log
	echo "
Calculating beta diversity distance matrices."
	parallel_beta_diversity.py -i $table -o $outdir/bdiv_normalized/ --metrics $metrics -T --jobs_to_start $cores 1> $stdout 2> $stderr
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi

## Rename output files
	for dm in $outdir/bdiv_normalized/*_table.txt; do
	dmbase=$(basename $dm _table.txt)
	mv $dm $outdir/bdiv_normalized/$dmbase\_dm.txt
	done

## Principal coordinates and NMDS commands
	echo "
Principal coordinates and NMDS commands:" >> $log
	echo "
Constructing PCoA and NMDS coordinate files."
	for dm in $outdir/bdiv_normalized/*_dm.txt; do
	dmbase=$(basename $dm _dm.txt)
	echo "	principal_coordinates.py -i $dm -o $outdir/bdiv_normalized/$dmbase\_pc.txt
	nmds.py -i $dm -o $outdir/bdiv_normalized/$dmbase\_nmds.txt" >> $log
	principal_coordinates.py -i $dm -o $outdir/bdiv_normalized/$dmbase\_pc.txt >/dev/null 2>&1 || true
	nmds.py -i $dm -o $outdir/bdiv_normalized/$dmbase\_nmds.txt >/dev/null 2>&1 || true
	python $scriptdir/convert_nmds_coords.py -i $outdir/bdiv_normalized/$dmbase\_nmds.txt -o $outdir/bdiv_normalized/$dmbase\_nmds_converted.txt
	done

## Make 3D emperor plots (PCoA)
	echo "
Make emperor commands:" >> $log
	echo "
Generating 3D PCoA plots."
	for pc in $outdir/bdiv_normalized/*_pc.txt; do
	pcbase=$( basename $pc _pc.txt )
		if [[ -d $outdir/bdiv_normalized/$pcbase\_emperor_pcoa_plot/ ]]; then
		rm -r $outdir/bdiv_normalized/$pcbase\_emperor_pcoa_plot/
		fi
	echo "	make_emperor.py -i $pc -o $outdir/bdiv_normalized/$pcbase\_emperor_pcoa_plot/ -m $mapfile --add_unique_columns --ignore_missing_samples" >> $log
	make_emperor.py -i $pc -o $outdir/bdiv_normalized/$pcbase\_emperor_pcoa_plot/ -m $mapfile --add_unique_columns --ignore_missing_samples >/dev/null 2>&1 || true
	done

## Make 3D emperor plots (NMDS)
	echo "
Make emperor commands:" >> $log
	echo "
Generating 3D NMDS plots."
	for nmds in $outdir/bdiv_normalized/*_nmds_converted.txt; do
	nmdsbase=$( basename $nmds _nmds_converted.txt )
		if [[ -d $outdir/bdiv_normalized/$nmdsbase\_emperor_nmds_plot/ ]]; then
		rm -r $outdir/bdiv_normalized/$nmdsbase\_emperor_nmds_plot/
		fi
	echo "	make_emperor.py -i $nmds -o $outdir/bdiv_normalized/$nmdsbase\_emperor_nmds_plot/ -m $mapfile --add_unique_columns --ignore_missing_samples" >> $log
	make_emperor.py -i $nmds -o $outdir/bdiv_normalized/$nmdsbase\_emperor_nmds_plot/ -m $mapfile --add_unique_columns --ignore_missing_samples >/dev/null 2>&1 || true
	done

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist

## Make 2D plots
	if [[ ! -d $outdir/bdiv_normalized/2D_PCoA_bdiv_plots ]]; then
	echo "
Make 2D plots commands:" >> $log
	echo "
Generating 2D PCoA plots."
	for pc in $outdir/bdiv_normalized/*_pc.txt; do
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	echo "	make_2d_plots.py -i $pc -m $mapfile -o $outdir/bdiv_normalized/2D_PCoA_bdiv_plots" >> $log
	( make_2d_plots.py -i $pc -m $mapfile -o $outdir/bdiv_normalized/2D_PCoA_bdiv_plots >/dev/null 2>&1 || true ) &
	done
	fi
wait

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist

## Anosim and permanova stats
	if [[ ! -f $outdir/bdiv_normalized/permanova_results_collated.txt ]]; then
echo > $outdir/bdiv_normalized/permanova_results_collated.txt
echo > $outdir/bdiv_normalized/anosim_results_collated.txt
echo "
Compare categories commands:" >> $log
	echo "
Calculating one-way statsitics from distance matrices."
echo "Running PERMANOVA tests."
	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_normalized/*_dm.txt; do
		method=$( basename $dm _dm.txt )
		echo "	compare_categories.py --method permanova -i $dm -m $mapfile -c $line -o $outdir/bdiv_normalized/permanova_temp/$line/$method/" >> $log
		compare_categories.py --method permanova -i $dm -m $mapfile -c $line -o $outdir/bdiv_normalized/permanova_temp/$line/$method/ >/dev/null 2>&1 || true
		echo "Category: $line" >> $outdir/bdiv_normalized/permanova_results_collated.txt
		echo "Method: $method" >> $outdir/bdiv_normalized/permanova_results_collated.txt
		cat $outdir/bdiv_normalized/permanova_temp/$line/$method/permanova_results.txt >> $outdir/bdiv_normalized/permanova_results_collated.txt  2>/dev/null || true
		echo "" >> $outdir/bdiv_normalized/permanova_results_collated.txt
		done
	done

echo "Running ANOSIM tests."
	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_normalized/*_dm.txt; do
		method=$( basename $dm _dm.txt )

		echo "	compare_categories.py --method anosim -i $dm -m $mapfile -c $line -o $outdir/bdiv_normalized/anosim_temp/$line/$method/" >> $log
		compare_categories.py --method anosim -i $dm -m $mapfile -c $line -o $outdir/bdiv_normalized/anosim_temp/$line/$method/ 2>/dev/null 2>&1 || true
		echo "Category: $line" >> $outdir/bdiv_normalized/anosim_results_collated.txt
		echo "Method: $method" >> $outdir/bdiv_normalized/anosim_results_collated.txt
		cat $outdir/bdiv_normalized/anosim_temp/$line/$method/anosim_results.txt >> $outdir/bdiv_normalized/anosim_results_collated.txt  2>/dev/null || true
		echo "" >> $outdir/bdiv_normalized/anosim_results_collated.txt
		done
	done
	fi

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist

done
exit 0


## Log end of workflow and exit

#res1=$(date +%s.%N)
#dt=$(echo "$res1 - $res0" | bc)
#dd=$(echo "$dt/86400" | bc)
#dt2=$(echo "$dt-86400*$dd" | bc)
#dh=$(echo "$dt2/3600" | bc)
#dt3=$(echo "$dt2-3600*$dh" | bc)
#dm=$(echo "$dt3/60" | bc)
#ds=$(echo "$dt3-60*$dm" | bc)
#
#runtime=`printf "Total runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
#
#if [[ $mode == "table" ]]; then
#	alltablescount="1"
#fi
#
#echo "All cdiv_graphs_and_stats_workflow.sh steps completed.  Hooray!
#Processed $alltablescount OTU tables.
#$runtime
#"
#echo "All cdiv_graphs_and_stats_workflow.sh steps completed.  Hooray!
#Processed $alltablescount OTU tables.
#$runtime
#" >> $log

#exit 0
