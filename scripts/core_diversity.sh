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
if [[ -f $alphatemp ]]; then
	rm $alphatemp
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
	alphatemp="$tempdir/${randcode}_alphametrics.temp"

## If incorrect number of arguments supplied, display usage 
	if [[ "$#" -ne 8 ]]; then 
	cat $repodir/docs/core_diversity.usage
		exit 1
	fi

## Read in variables from config file
	tree=(`grep "Tree" $config | grep -v "#" | cut -f 2`)
	adepth=(`grep "Rarefaction_depth" $config | grep -v "#" | cut -f 2`)
	threads=$(($cores+1))

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
	tablecount=$(cat $tablelist | wc -l)

## Make categories temp file
	echo "
Parsing input categories."
	bash $scriptdir/parse_cats.sh $stdout $stderr $log $mapfile $cats $catlist $randcode $tempdir

## Make normalized tables if necessary

#	echo "Normalizing tables if necessary.
#	"
#	bash $scriptdir/norm_tables.sh $stdout $stderr $log $tablelist $threads

################################################################################
## Start of for loop to process each table in the master list sequentially
################################################################################

for table in `cat $tablelist`; do

		## Define initial variables
		workdir=$(pwd)
		inputdir=$(dirname $table)
		inputdirup1=$(dirname $inputdir)
		inputbase=$(basename $table .biom)

		## Summarize any tables in input directory
		biom-summarize_folder.sh $inputdir &>/dev/null
		wait

		## Determine rarefaction depth
		if [[ $adepth =~ ^[0-9]+$ ]]; then
		depth=($adepth)
		else
		depth=`awk '/Counts\/sample detail:/ {for(i=1; i<=1; i++) {getline; print $NF}}' $inputdir/$inputbase.summary | awk -F. '{print $1}'`
		fi

		## Define remaining variables, make output directory if necessary
		## and move table there for normalizing, rarefaction, and filtering
		outdir="$inputdir/core_diversity/${inputbase}_depth${depth}"
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

		## Find log file or set new one. 
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

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

akutils core_diversity workflow beginning." >> $log
		date >> $log
echo "
********************************************************************************

INITIAL TABLE PROCESSING STARTS HERE

********************************************************************************
" >> $log

		## Find phylogenetic tree or set mode nonphylogenetic
		if [[ -f $inputdirup1/pynast_alignment/fasttree_phylogeny.tre ]]; then
		tree="$inputdirup1/pynast_alignment/fasttree_phylogeny.tre"
		phylogenetic="YES"
		metrics="bray_curtis,chord,hellinger,kulczynski,unweighted_unifrac,weighted_unifrac"
		alphametrics="PD_whole_tree,chao1,observed_species,shannon"
		fi
		if [[ -f $inputdirup1/mafft_alignment/fasttree_phylogeny.tre ]]; then
		tree="$inputdirup1/mafft_alignment/fasttree_phylogeny.tre"
		phylogenetic="YES"
		metrics="bray_curtis,chord,hellinger,kulczynski,unweighted_unifrac,weighted_unifrac"
		alphametrics="PD_whole_tree,chao1,observed_species,shannon"
		fi
		if [[ -z $phylogenetic ]]; then
		phylogenetic="NO"
		metrics="bray_curtis,chord,hellinger,kulczynski"
		alphametrics="chao1,observed_species,shannon"
		fi

		## Make alpha metrics temp file
		echo > $alphatemp
		IN=$alphametrics
		OIFS=$IFS
		IFS=','
		arr=$IN
		for x in $arr; do
			echo $x >> $alphatemp
		done
		IFS=$OIFS
		sed -i '/^\s*$/d' $alphatemp

		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

		## Summarize input table
		biom-summarize_folder.sh $tabledir &>/dev/null

		## Refresh html output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

		## Rarefy input table according to established depth
		raretable="$tabledir/rarefied_table.biom"
		raresummary="$tabledir/rarefied_table.summary"
		if [[ ! -f $raretable ]]; then
		echo "
Input table: $table
Rarefying input table according to config file ($adepth).
${bold}Rarefaction depth: $depth${normal}"

		echo "
Input table: $table
Rarefying input table according to config file ($adepth).
Rarefaction depth: $depth" >> $log

		echo "
Single rarefaction command:
	single_rarefaction.py -i $intable -o $raretable -d $depth" >> $log
		single_rarefaction.py -i $intable -o $raretable -d $depth 1> $stdout 2> $stderr
		wait
		bash $scriptdir/log_slave.sh $stdout $stderr $log
		fi

		biom-summarize_folder.sh $tabledir &>/dev/null
		rarebase=$(basename $raretable .biom)

		## Refresh html output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

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

		filtertable="$tabledir/sample_filtered_table.biom"
		if [[ ! -f $filtertable ]]; then
		echo "
Filtering any samples removed during rarefaction."
		echo "
Filtering any samples removed during rarefaction:
	filter_samples_from_otu_table.py -i $intable -o $filtertable --sample_id_fp $raresamples" >> $log
		filter_samples_from_otu_table.py -i $intable -o $filtertable --sample_id_fp $raresamples 1> $stdout 2> $stderr
		bash $scriptdir/log_slave.sh $stdout $stderr $log
		else
		echo "
Sample-filtered table already present." >> $log
		fi

		## Log any sample removals
		echo "
${bold}Removed $diffcount samples${normal} from the analysis:"
		echo "
Removed $diffcount samples from the analysis following rarefaction:" >> $log
		grep -vFf $raresamples $insamples
		grep -vFf $raresamples $insamples >> $log

		## Normalize filtered table with CSS and DESeq2 transformations
		CSStable="$tabledir/CSS_table.biom"
		DESeq2table="$tabledir/DESeq2_table.biom"
		if [[ ! -f $CSStable ]]; then
		echo "
Normalizing sample-filtered table with CSS transformation."
		echo "
Normalizing sample-filtered table with CSS transformation:
	normalize_table.py -i $filtertable -o $CSStable -a CSS" >> $log
			if [[ ! -f $CSStable ]]; then
			normalize_table.py -i $filtertable -o $CSStable -a CSS 1> $stdout 2> $stderr || true
			bash $scriptdir/log_slave.sh $stdout $stderr $log
			fi

#			## This is the script/syntax for normalizing a folder of tables in parallel
#			if [[ ! -f $DESeq2table ]]; then
#			( normalize_table.py -i $filtertable -o $DESeq2table -a DESeq2 2>/dev/null ) &
#			fi
		wait
		fi
	
		## Summarize tables one last time and refresh html output
		biom-summarize_folder.sh $tabledir &>/dev/null
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

		## Sort OTU tables
		CSSsort="$outdir/OTU_tables/CSS_table_sorted.biom"
		raresort="$outdir/OTU_tables/rarefied_table_sorted.biom"
		if [[ ! -f $CSSsort ]]; then
		sort_otu_table.py -i $CSStable -o $CSSsort
		echo "
		sort_otu_table.py -i $CSStable -o $CSSsort" >> $log
		fi
		if [[ ! -f $raresort ]]; then
		sort_otu_table.py -i $raretable -o $raresort
		echo "
		sort_otu_table.py -i $raretable -o $raresort" >> $log
		fi

		## Relativize rarefied and CSS tables
		raresortrel="$outdir/OTU_tables/rarefied_table_sorted_relativized.biom"
		CSSsortrel="$outdir/OTU_tables/CSS_table_sorted_relativized.biom"
		if [[ ! -f $raresortrel ]]; then
		relativize_otu_table.py -i $raresort >/dev/null 2>&1 || true
		echo "
		relativize_otu_table.py -i $raresort" >> $log
		fi
		if [[ ! -f $CSSsortrel ]]; then
		relativize_otu_table.py -i $CSSsort >/dev/null 2>&1 || true
		echo "
		relativize_otu_table.py -i $CSSsort" >> $log
		fi

		if [[ "$phylogenetic" == "YES" ]]; then
		echo "
Analysis will be ${bold}phylogenetic${normal}.
${bold}Alpha diversity metrics:${normal} $alphametrics
${bold}Beta diversity metrics:${normal} $metrics
${bold}Tree file:${normal} $tree"
		echo "
Analysis will be phylogenetic.
Alpha diversity metrics: $alphametrics
Beta diversity metrics: $metrics
Tree file: $tree" >> $log
		elif [[ "$phylogenetic" == "NO" ]]; then
		echo "
Analysis will be nonphylogenetic.
${bold}Alpha diversity metrics:${normal} $alphametrics
${bold}Beta diversity metrics:${normal} $metrics
${bold}Tree file:${normal} None found"
		echo "
Analysis will be nonphylogenetic.
Alpha diversity metrics: $alphametrics
Beta diversity metrics: $metrics
Tree file: None found" >> $log
		fi

		## Make .txt versions of analysis tables
		CCSsorttxt="$outdir/OTU_tables/CSS_table_sorted.txt"
		raresorttxt="$outdir/OTU_tables/rarefied_table_sorted.txt"
		intabletxt="$outdir/OTU_tables/$inputbase.txt"
		filtertabletxt="$outdir/OTU_tables/sample_filtered_table.txt"
		raresortreltxt="$outdir/OTU_tables/rarefied_table_sorted_relativized.txt"
		CSSsortreltxt="$outdir/OTU_tables/CSS_table_sorted_relativized.txt"
		if [[ ! -f $CSSsorttxt ]]; then
		biomtotxt.sh $CSSsort &>/dev/null
		sed -i '/# Constructed from biom file/d' $CSSsorttxt 2>/dev/null || true
		fi
		if [[ ! -f $raresorttxt ]]; then
		biomtotxt.sh $raresort &>/dev/null
		sed -i '/# Constructed from biom file/d' $raresorttxt 2>/dev/null || true
		fi
		if [[ ! -f $intabletxt ]]; then
		biomtotxt.sh $intable &>/dev/null
		sed -i '/# Constructed from biom file/d' $intabletxt 2>/dev/null || true
		fi
		if [[ ! -f $filtertabletxt ]]; then
		biomtotxt.sh $filtertable &>/dev/null
		sed -i '/# Constructed from biom file/d' $filtertabletxt 2>/dev/null || true
		fi
		if [[ ! -f $raresortreltxt ]]; then
		biomtotxt.sh $raresortrel &>/dev/null
		sed -i '/# Constructed from biom file/d' $raresortreltxt 2>/dev/null || true
		fi
		if [[ ! -f $CSSsortreltxt ]]; then
		biomtotxt.sh $CSSsortrel &>/dev/null
		sed -i '/# Constructed from biom file/d' $CSSsortreltxt 2>/dev/null || true
		fi

################################################################################
## START OF NORMALIZED ANALYSIS HERE

echo "
********************************************************************************

NORMALIZED TABLE PROCESSING STARTS HERE

********************************************************************************
" >> $log

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
	
	else
	echo "
Relative abundance tables already present." >> $log
	fi
	wait

## Beta diversity
	if [[ "$phylogenetic" == "YES" ]]; then
	if [[ ! -f $outdir/bdiv_normalized/bray_curtis_dm.txt && ! -f $outdir/bdiv_normalized/chord_dm.txt && ! -f $outdir/bdiv_normalized/hellinger_dm.txt && ! -f $outdir/bdiv_normalized/kulczynski_dm.txt && ! -f $outdir/bdiv_normalized/unweighted_unifrac_dm.txt && ! -f $outdir/bdiv_normalized/weighted_unifrac_dm.txt ]]; then
	echo "
Parallel beta diversity command:
	parallel_beta_diversity.py -i $CSSsort -o $outdir/bdiv_normalized/ --metrics $metrics -T  -t $tree --jobs_to_start $cores" >> $log
	echo "
Calculating beta diversity distance matrices."
	parallel_beta_diversity.py -i $CSSsort -o $outdir/bdiv_normalized/ --metrics $metrics -T  -t $tree --jobs_to_start $cores 1> $stdout 2> $stderr
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi
	elif [[ "$phylogenetic" == "NO" ]]; then
	if [[ ! -f $outdir/bdiv_normalized/bray_curtis_dm.txt && ! -f $outdir/bdiv_normalized/chord_dm.txt && ! -f $outdir/bdiv_normalized/hellinger_dm.txt && ! -f $outdir/bdiv_normalized/kulczynski_dm.txt ]]; then
	echo "
Parallel beta diversity command:
	parallel_beta_diversity.py -i $CSSsort -o $outdir/bdiv_normalized/ --metrics $metrics -T --jobs_to_start $cores" >> $log
	echo "
Calculating beta diversity distance matrices."
	parallel_beta_diversity.py -i $CSSsort -o $outdir/bdiv_normalized/ --metrics $metrics -T --jobs_to_start $cores 1> $stdout 2> $stderr
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi
	else
	echo "
Beta diversity matrices already present." >> $log
	fi
	wait

## Rename output files
	if [[ ! -f $outdir/bdiv_normalized/bray_curtis_dm.txt ]]; then
	bcdm=$(ls $outdir/bdiv_normalized/bray_curtis_*.txt)
	mv $bcdm $outdir/bdiv_normalized/bray_curtis_dm.txt 2>/dev/null
	fi
	wait
	if [[ ! -f $outdir/bdiv_normalized/chord_dm.txt ]]; then
	cdm=$(ls $outdir/bdiv_normalized/chord_*.txt)
	mv $cdm $outdir/bdiv_normalized/chord_dm.txt 2>/dev/null
	fi
	wait
	if [[ ! -f $outdir/bdiv_normalized/hellinger_dm.txt ]]; then
	hdm=$(ls $outdir/bdiv_normalized/hellinger_*.txt)
	mv $hdm $outdir/bdiv_normalized/hellinger_dm.txt 2>/dev/null
	fi
	wait
	if [[ ! -f $outdir/bdiv_normalized/kulczynski_dm.txt ]]; then
	kdm=$(ls $outdir/bdiv_normalized/kulczynski_*.txt)
	mv $kdm $outdir/bdiv_normalized/kulczynski_dm.txt 2>/dev/null
	fi
	wait
	if [[ "$phylogenetic" == "YES" ]]; then
	if [[ ! -f $outdir/bdiv_normalized/unweighted_unifrac_dm.txt ]]; then
	uudm=$(ls $outdir/bdiv_normalized/unweighted_unifrac_*.txt)
	mv $uudm $outdir/bdiv_normalized/unweighted_unifrac_dm.txt 2>/dev/null
	fi
	wait
	if [[ ! -f $outdir/bdiv_normalized/weighted_unifrac_dm.txt ]]; then
	wudm=$(ls $outdir/bdiv_normalized/weighted_unifrac_*.txt)
	mv $wudm $outdir/bdiv_normalized/weighted_unifrac_dm.txt 2>/dev/null
	fi
	wait
	fi
	wait

## Principal coordinates and NMDS commands
	pcoacoordscount=`ls $outdir/bdiv_normalized/*_pc.txt 2>/dev/null | wc -l`
	nmdscoordscount=`ls $outdir/bdiv_normalized/*_nmds.txt 2>/dev/null | wc -l`
	nmdsconvertcoordscount=`ls $outdir/bdiv_normalized/*_nmds_converted.txt 2>/dev/null | wc -l`
	if [[ $pcoacoordscount == 0 && $nmdscoordscount == 0 && $nmdsconvertcoordscount == 0 ]]; then
	echo "
Principal coordinates and NMDS commands." >> $log
	echo "
Constructing PCoA and NMDS coordinate files."
	echo "Principal coordinates:" >> $log
	for dm in $outdir/bdiv_normalized/*_dm.txt; do
	dmbase=$(basename $dm _dm.txt)
	echo "	principal_coordinates.py -i $dm -o $outdir/bdiv_normalized/${dmbase}_pc.txt" >> $log
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	( principal_coordinates.py -i $dm -o $outdir/bdiv_normalized/${dmbase}_pc.txt >/dev/null 2>&1 || true ) &
	done
	wait
	echo "" >> $log

	echo "NMDS coordinates:" >> $log
	for dm in $outdir/bdiv_normalized/*_dm.txt; do
	dmbase=$(basename $dm _dm.txt)
	echo "	nmds.py -i $dm -o $outdir/bdiv_normalized/${dmbase}_nmds.txt" >> $log
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	( nmds.py -i $dm -o $outdir/bdiv_normalized/${dmbase}_nmds.txt >/dev/null 2>&1 || true ) &
	done
	wait
	echo "" >> $log

	echo "Convert NMDS coordinates:" >> $log
	for dm in $outdir/bdiv_normalized/*_dm.txt; do
	dmbase=$(basename $dm _dm.txt)
	echo "	python $scriptdir/convert_nmds_coords.py -i $outdir/bdiv_normalized/${dmbase}_nmds.txt -o $outdir/bdiv_normalized/${dmbase}_nmds_converted.txt" >> $log
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	( python $scriptdir/convert_nmds_coords.py -i $outdir/bdiv_normalized/${dmbase}_nmds.txt -o $outdir/bdiv_normalized/${dmbase}_nmds_converted.txt >/dev/null 2>&1 || true ) &
	done
	wait
	echo "" >> $log
	else
	echo "
PCoA and NMDS coordinate files already present." >> $log
	fi

## Make 3D emperor plots (PCoA)
	pcoaplotscount=`ls $outdir/bdiv_normalized/*_pcoa_plot 2>/dev/null | wc -l`
	if [[ $pcoaplotscount == 0 ]]; then
	echo "
Make emperor commands:" >> $log
	echo "
Generating 3D PCoA plots."
	echo "PCoA plots:" >> $log
	for pc in $outdir/bdiv_normalized/*_pc.txt; do
	pcbase=$(basename $pc _pc.txt)
		if [[ -d $outdir/bdiv_normalized/${pcbase}_emperor_pcoa_plot/ ]]; then
		rm -r $outdir/bdiv_normalized/${pcbase}_emperor_pcoa_plot/
		fi
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	echo "	make_emperor.py -i $pc -o $outdir/bdiv_normalized/${pcbase}_emperor_pcoa_plot/ -m $mapfile --add_unique_columns --ignore_missing_samples" >> $log
	( make_emperor.py -i $pc -o $outdir/bdiv_normalized/${pcbase}_emperor_pcoa_plot/ -m $mapfile --add_unique_columns --ignore_missing_samples >/dev/null 2>&1 || true ) &
	done
	wait
	echo "" >> $log
	else
	echo "
3D PCoA plots already present." >> $log
	fi

## Make 3D emperor plots (NMDS)
	nmdsplotscount=`ls $outdir/bdiv_normalized/*_nmds_plot 2>/dev/null | wc -l`
	if [[ $nmdsplotscount == 0 ]]; then
	echo "
Generating 3D NMDS plots."
	echo "NMDS plots:" >> $log
	for nmds in $outdir/bdiv_normalized/*_nmds_converted.txt; do
	nmdsbase=$(basename $nmds _nmds_converted.txt)
		if [[ -d $outdir/bdiv_normalized/${nmdsbase}_emperor_nmds_plot/ ]]; then
		rm -r $outdir/bdiv_normalized/${nmdsbase}_emperor_nmds_plot/
		fi
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	echo "	make_emperor.py -i $nmds -o $outdir/bdiv_normalized/${nmdsbase}_emperor_nmds_plot/ -m $mapfile --add_unique_columns --ignore_missing_samples" >> $log
	( make_emperor.py -i $nmds -o $outdir/bdiv_normalized/${nmdsbase}_emperor_nmds_plot/ -m $mapfile --add_unique_columns --ignore_missing_samples >/dev/null 2>&1 || true ) &
	done
	wait
	echo "" >> $log
	else
	echo "
3D NMDS plots already present." >> $log
	fi

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

## Make 2D plots
	if [[ ! -d $outdir/bdiv_normalized/2D_PCoA_bdiv_plots ]]; then
	echo "
Make 2D PCoA plots commands:" >> $log
	echo "
Generating 2D PCoA plots."
	for pc in $outdir/bdiv_normalized/*_pc.txt; do
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	echo "	make_2d_plots.py -i $pc -m $mapfile -o $outdir/bdiv_normalized/2D_PCoA_bdiv_plots" >> $log
	( make_2d_plots.py -i $pc -m $mapfile -o $outdir/bdiv_normalized/2D_PCoA_bdiv_plots >/dev/null 2>&1 || true ) &
	done
	wait
	echo "" >> $log
	else
	echo "
2D plots already present." >> $log
	fi

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

## Comparing categories statistics
if [[ ! -f $outdir/bdiv_normalized/permanova_results_collated.txt && ! -f $outdir/bdiv_normalized/permdisp_results_collated.txt && ! -f $outdir/bdiv_normalized/anosim_results_collated.txt && ! -f $outdir/bdiv_normalized/dbrda_results_collated.txt && ! -f $outdir/bdiv_normalized/adonis_results_collated.txt ]]; then
echo "
Compare categories commands:" >> $log
	echo "
Calculating one-way statsitics from distance matrices."
	if [[ ! -f $outdir/bdiv_normalized/permanova_results_collated.txt ]]; then
echo "Running PERMANOVA tests."
echo "PERMANOVA:" >> $log
	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_normalized/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		echo "	compare_categories.py --method permanova -i $dm -m $mapfile -c $line -o $outdir/bdiv_normalized/permanova_out/$line/$method/" >> $log
		( compare_categories.py --method permanova -i $dm -m $mapfile -c $line -o $outdir/bdiv_normalized/permanova_out/$line/$method/ >/dev/null 2>&1 || true ) &
		done
	done
	wait
	echo "" >> $log

	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_normalized/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		echo "Category: $line" >> $outdir/bdiv_normalized/permanova_results_collated.txt
		echo "Method: $method" >> $outdir/bdiv_normalized/permanova_results_collated.txt
		cat $outdir/bdiv_normalized/permanova_out/$line/$method/permanova_results.txt >> $outdir/bdiv_normalized/permanova_results_collated.txt 2>/dev/null || true
		echo "" >> $outdir/bdiv_normalized/permanova_results_collated.txt
		done
	done
	wait
	fi

	if [[ ! -f $outdir/bdiv_normalized/permdisp_results_collated.txt ]]; then
echo "Running PERMDISP tests."
echo "PERMDISP:" >> $log
	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_normalized/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		echo "	compare_categories.py --method permdisp -i $dm -m $mapfile -c $line -o $outdir/bdiv_normalized/permdisp_out/$line/$method/" >> $log
		( compare_categories.py --method permdisp -i $dm -m $mapfile -c $line -o $outdir/bdiv_normalized/permdisp_out/$line/$method/ >/dev/null 2>&1 || true ) &
		done
	done
	wait
	echo "" >> $log

	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_normalized/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		echo "Category: $line" >> $outdir/bdiv_normalized/permdisp_results_collated.txt
		echo "Method: $method" >> $outdir/bdiv_normalized/permdisp_results_collated.txt
		cat $outdir/bdiv_normalized/permdisp_out/$line/$method/permdisp_results.txt >> $outdir/bdiv_normalized/permdisp_results_collated.txt 2>/dev/null || true
		echo "" >> $outdir/bdiv_normalized/permdisp_results_collated.txt
		done
	done
	wait
	fi

	if [[ ! -f $outdir/bdiv_normalized/anosim_results_collated.txt ]]; then
echo "Running ANOSIM tests."
echo "ANOSIM:" >> $log
	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_normalized/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		echo "	compare_categories.py --method anosim -i $dm -m $mapfile -c $line -o $outdir/bdiv_normalized/anosim_out/$line/$method/" >> $log
		( compare_categories.py --method anosim -i $dm -m $mapfile -c $line -o $outdir/bdiv_normalized/anosim_out/$line/$method/ 2>/dev/null 2>&1 || true ) &
		done
	done
	wait
	echo "" >> $log

	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_normalized/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		echo "Category: $line" >> $outdir/bdiv_normalized/anosim_results_collated.txt
		echo "Method: $method" >> $outdir/bdiv_normalized/anosim_results_collated.txt
		cat $outdir/bdiv_normalized/anosim_out/$line/$method/anosim_results.txt >> $outdir/bdiv_normalized/anosim_results_collated.txt 2>/dev/null || true
		echo "" >> $outdir/bdiv_normalized/anosim_results_collated.txt
		done
	done
	wait
	fi

	if [[ ! -f $outdir/bdiv_normalized/dbrda_results_collated.txt ]]; then
echo "Running DB-RDA tests."
echo "DB-RDA:" >> $log
	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_normalized/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		echo "	compare_categories.py --method dbrda -i $dm -m $mapfile -c $line -o $outdir/bdiv_normalized/dbrda_out/$line/$method/" >> $log
		( compare_categories.py --method dbrda -i $dm -m $mapfile -c $line -o $outdir/bdiv_normalized/dbrda_out/$line/$method/ 2>/dev/null 2>&1 || true ) &
		done
	done
	wait
	echo "" >> $log

	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_normalized/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		echo "Category: $line" >> $outdir/bdiv_normalized/dbrda_results_collated.txt
		echo "Method: $method" >> $outdir/bdiv_normalized/dbrda_results_collated.txt
		cat $outdir/bdiv_normalized/dbrda_out/$line/$method/dbrda_results.txt >> $outdir/bdiv_normalized/dbrda_results_collated.txt 2>/dev/null || true
		echo "" >> $outdir/bdiv_normalized/dbrda_results_collated.txt
		done
	done
	wait
	fi

	if [[ ! -f $outdir/bdiv_normalized/adonis_results_collated.txt ]]; then
echo "Running Adonis tests."
echo "Adonis:" >> $log
	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_normalized/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		echo "	compare_categories.py --method adonis -i $dm -m $mapfile -c $line -o $outdir/bdiv_normalized/adonis_out/$line/$method/" >> $log
		( compare_categories.py --method adonis -i $dm -m $mapfile -c $line -o $outdir/bdiv_normalized/adonis_out/$line/$method/ 2>/dev/null 2>&1 || true ) &
		done
	done
	wait
	echo "" >> $log

	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_normalized/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		echo "Category: $line" >> $outdir/bdiv_normalized/adonis_results_collated.txt
		echo "Method: $method" >> $outdir/bdiv_normalized/adonis_results_collated.txt
		cat $outdir/bdiv_normalized/adonis_out/$line/$method/adonis_results.txt >> $outdir/bdiv_normalized/adonis_results_collated.txt 2>/dev/null || true
		echo "" >> $outdir/bdiv_normalized/adonis_results_collated.txt
		done
	done
	wait
	fi
else
echo "
Categorical comparisons already present." >> $log
fi
	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

## Distance boxplots for each category
	boxplotscount=`ls $outdir/bdiv_normalized/*_boxplots 2>/dev/null | wc -l`
	if [[ $boxplotscount == 0 ]]; then
	echo "
Make distance boxplots commands:" >> $log
	echo "
Generating distance boxplots."
	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_normalized/*_dm.txt; do
		dmbase=$(basename $dm _dm.txt)
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		echo "	make_distance_boxplots.py -d $outdir/bdiv_normalized/${dmbase}_dm.txt -f $line -o $outdir/bdiv_normalized/${dmbase}_boxplots/ -m $mapfile -n 999" >> $log
		( make_distance_boxplots.py -d $outdir/bdiv_normalized/${dmbase}_dm.txt -f $line -o $outdir/bdiv_normalized/${dmbase}_boxplots/ -m $mapfile -n 999 >/dev/null 2>&1 || true ) &
		done
	done
	wait
	echo "" >> $log
	else
	echo "
Boxplots already present." >> $log
	fi

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

## Make biplots
	if [[ ! -d $outdir/bdiv_normalized/biplots ]]; then
	echo "
Make biplots commands:" >> $log
	echo "
Generating PCoA biplots:"
	mkdir $outdir/bdiv_normalized/biplots
	for pc in $outdir/bdiv_normalized/*_pc.txt; do
	pcmethod=$(basename $pc _pc.txt)
	mkdir $outdir/bdiv_normalized/biplots/$pcmethod
	done
	wait

	for pc in $outdir/bdiv_normalized/*_pc.txt; do
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	pcmethod=$(basename $pc _pc.txt)
		for level in $outdir/bdiv_normalized/summarized_tables/CSS_table_sorted_*.txt; do
		L=$(basename $level .txt)
		echo "	make_emperor.py -i $pc -m $mapfile -o $outdir/bdiv_normalized/biplots/$pcmethod/$L -t $level --add_unique_columns --ignore_missing_samples" >> $log
		( make_emperor.py -i $pc -m $mapfile -o $outdir/bdiv_normalized/biplots/$pcmethod/$L -t $level --add_unique_columns --ignore_missing_samples >/dev/null 2>&1 || true ) &
		done
	done
	wait
	echo "" >> $log
	else
	echo "
Biplots already present." >> $log
	fi

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

## Run supervised learning on data using supplied categories
	if [[ ! -d $outdir/bdiv_normalized/SupervisedLearning ]]; then
	mkdir $outdir/bdiv_normalized/SupervisedLearning
	echo "
Supervised learning commands:" >> $log
	echo "
Running supervised learning analysis."
	for category in `cat $catlist`; do
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		echo "	supervised_learning.py -i $CSSsort -m $mapfile -c $category -o $outdir/bdiv_normalized/SupervisedLearning/$category --ntree 1000" >> $log
		( supervised_learning.py -i $CSSsort -m $mapfile -c $category -o $outdir/bdiv_normalized/SupervisedLearning/$category --ntree 1000 &>/dev/null 2>&1 || true ) &
	done
	else
	echo "
Supervised Learning already present." >> $log
	fi

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

## Make rank abundance plots (normalized)
	if [[ ! -d $outdir/bdiv_normalized/RankAbundance ]]; then
	mkdir $outdir/bdiv_normalized/RankAbundance
	echo "
Rank abundance plot commands:" >> $log
	echo "
Generating rank abundance plots."
	echo "	plot_rank_abundance_graph.py -i $CSSsort -o $outdir/bdiv_normalized/RankAbundance/rankabund_xlog-ylog.pdf -s "*" -n
	plot_rank_abundance_graph.py -i $CSSsort -o $outdir/bdiv_normalized/RankAbundance/rankabund_xlinear-ylog.pdf -s "*" -n -x
	plot_rank_abundance_graph.py -i $CSSsort -o $outdir/bdiv_normalized/RankAbundance/rankabund_xlog-ylinear.pdf -s "*" -n -y
	plot_rank_abundance_graph.py -i $CSSsort -o $outdir/bdiv_normalized/RankAbundance/rankabund_xlinear-ylinear.pdf -s "*" -n -x -y
	" >> $log
	( plot_rank_abundance_graph.py -i $CSSsort -o $outdir/bdiv_normalized/RankAbundance/rankabund_xlog-ylog.pdf -s "*" -n ) &
	( plot_rank_abundance_graph.py -i $CSSsort -o $outdir/bdiv_normalized/RankAbundance/rankabund_xlinear-ylog.pdf -s "*" -n -x ) &
	( plot_rank_abundance_graph.py -i $CSSsort -o $outdir/bdiv_normalized/RankAbundance/rankabund_xlog-ylinear.pdf -s "*" -n -y ) &
	( plot_rank_abundance_graph.py -i $CSSsort -o $outdir/bdiv_normalized/RankAbundance/rankabund_xlinear-ylinear.pdf -s "*" -n -x -y ) &
	fi
wait

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

echo "
********************************************************************************

END OF NORMALIZED TABLE PROCESSING STEPS

********************************************************************************
" >> $log

################################################################################
## START OF RAREFIED ANALYSIS HERE

echo "
********************************************************************************

RAREFIED TABLE PROCESSING STARTS HERE

********************************************************************************
" >> $log

	echo "
Processing rarefied table."
	echo "
Processing rarefied table." >> $log

## Summarize taxa (yields relative abundance tables)
	if [[ ! -d $outdir/bdiv_rarefied/summarized_tables ]]; then
	echo "
Summarize taxa command:
	summarize_taxa.py -i $raresort -o $outdir/bdiv_rarefied/summarized_tables -L 2,3,4,5,6,7" >> $log
	echo "
Summarizing taxonomy by sample and building plots."
	summarize_taxa.py -i $raresort -o $outdir/bdiv_rarefied/summarized_tables -L 2,3,4,5,6,7 1> $stdout 2> $stderr
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	
	else
	echo "
Relative abundance tables already present." >> $log
	fi
	wait

## Beta diversity
	if [[ "$phylogenetic" == "YES" ]]; then
	if [[ ! -f $outdir/bdiv_rarefied/bray_curtis_dm.txt && ! -f $outdir/bdiv_rarefied/chord_dm.txt && ! -f $outdir/bdiv_rarefied/hellinger_dm.txt && ! -f $outdir/bdiv_rarefied/kulczynski_dm.txt && ! -f $outdir/bdiv_rarefied/unweighted_unifrac_dm.txt && ! -f $outdir/bdiv_rarefied/weighted_unifrac_dm.txt ]]; then
	echo "
Parallel beta diversity command:
	parallel_beta_diversity.py -i $raresort -o $outdir/bdiv_rarefied/ --metrics $metrics -T  -t $tree --jobs_to_start $cores" >> $log
	echo "
Calculating beta diversity distance matrices."
	parallel_beta_diversity.py -i $raresort -o $outdir/bdiv_rarefied/ --metrics $metrics -T  -t $tree --jobs_to_start $cores 1> $stdout 2> $stderr
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi
	elif [[ "$phylogenetic" == "NO" ]]; then
	if [[ ! -f $outdir/bdiv_rarefied/bray_curtis_dm.txt && ! -f $outdir/bdiv_rarefied/chord_dm.txt && ! -f $outdir/bdiv_rarefied/hellinger_dm.txt && ! -f $outdir/bdiv_rarefied/kulczynski_dm.txt ]]; then
	echo "
Parallel beta diversity command:
	parallel_beta_diversity.py -i $raresort -o $outdir/bdiv_rarefied/ --metrics $metrics -T --jobs_to_start $cores" >> $log
	echo "
Calculating beta diversity distance matrices."
	parallel_beta_diversity.py -i $raresort -o $outdir/bdiv_rarefied/ --metrics $metrics -T --jobs_to_start $cores 1> $stdout 2> $stderr
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi
	else
	echo "
Beta diversity matrices already present." >> $log
	fi
	wait

## Rename output files
	if [[ ! -f $outdir/bdiv_rarefied/bray_curtis_dm.txt ]]; then
	bcdm=$(ls $outdir/bdiv_rarefied/bray_curtis_rarefied_table_sorted.txt)
	mv $bcdm $outdir/bdiv_rarefied/bray_curtis_dm.txt 2>/dev/null
	fi
	wait
	if [[ ! -f $outdir/bdiv_rarefied/chord_dm.txt ]]; then
	cdm=$(ls $outdir/bdiv_rarefied/chord_rarefied_table_sorted.txt)
	mv $cdm $outdir/bdiv_rarefied/chord_dm.txt 2>/dev/null
	fi
	wait
	if [[ ! -f $outdir/bdiv_rarefied/hellinger_dm.txt ]]; then
	hdm=$(ls $outdir/bdiv_rarefied/hellinger_rarefied_table_sorted.txt)
	mv $hdm $outdir/bdiv_rarefied/hellinger_dm.txt 2>/dev/null
	fi
	wait
	if [[ ! -f $outdir/bdiv_rarefied/kulczynski_dm.txt ]]; then
	kdm=$(ls $outdir/bdiv_rarefied/kulczynski_rarefied_table_sorted.txt)
	mv $kdm $outdir/bdiv_rarefied/kulczynski_dm.txt 2>/dev/null
	fi
	wait
	if [[ "$phylogenetic" == "YES" ]]; then
	if [[ ! -f $outdir/bdiv_rarefied/unweighted_unifrac_dm.txt ]]; then
	uudm=$(ls $outdir/bdiv_rarefied/unweighted_unifrac_rarefied_table_sorted.txt)
	mv $uudm $outdir/bdiv_rarefied/unweighted_unifrac_dm.txt 2>/dev/null
	fi
	wait
	if [[ ! -f $outdir/bdiv_rarefied/weighted_unifrac_dm.txt ]]; then
	wudm=$(ls $outdir/bdiv_rarefied/weighted_unifrac_rarefied_table_sorted.txt)
	mv $wudm $outdir/bdiv_rarefied/weighted_unifrac_dm.txt 2>/dev/null
	fi
	wait
	fi
	wait

## Principal coordinates and NMDS commands
	pcoacoordscount=`ls $outdir/bdiv_rarefied/*_pc.txt 2>/dev/null | wc -l`
	nmdscoordscount=`ls $outdir/bdiv_rarefied/*_nmds.txt 2>/dev/null | wc -l`
	nmdsconvertcoordscount=`ls $outdir/bdiv_rarefied/*_nmds_converted.txt 2>/dev/null | wc -l`
	if [[ $pcoacoordscount == 0 && $nmdscoordscount == 0 && $nmdsconvertcoordscount == 0 ]]; then
	echo "
Principal coordinates and NMDS commands." >> $log
	echo "
Constructing PCoA and NMDS coordinate files."
	echo "Principal coordinates:" >> $log
	for dm in $outdir/bdiv_rarefied/*_dm.txt; do
	dmbase=$(basename $dm _dm.txt)
	echo "	principal_coordinates.py -i $dm -o $outdir/bdiv_rarefied/${dmbase}_pc.txt" >> $log
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	( principal_coordinates.py -i $dm -o $outdir/bdiv_rarefied/${dmbase}_pc.txt >/dev/null 2>&1 || true ) &
	done
	wait
	echo "" >> $log

	echo "NMDS coordinates:" >> $log
	for dm in $outdir/bdiv_rarefied/*_dm.txt; do
	dmbase=$(basename $dm _dm.txt)
	echo "	nmds.py -i $dm -o $outdir/bdiv_rarefied/${dmbase}_nmds.txt" >> $log
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	( nmds.py -i $dm -o $outdir/bdiv_rarefied/${dmbase}_nmds.txt >/dev/null 2>&1 || true ) &
	done
	wait
	echo "" >> $log

	echo "Convert NMDS coordinates:" >> $log
	for dm in $outdir/bdiv_rarefied/*_dm.txt; do
	dmbase=$(basename $dm _dm.txt)
	echo "	python $scriptdir/convert_nmds_coords.py -i $outdir/bdiv_rarefied/${dmbase}_nmds.txt -o $outdir/bdiv_rarefied/${dmbase}_nmds_converted.txt" >> $log
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	( python $scriptdir/convert_nmds_coords.py -i $outdir/bdiv_rarefied/${dmbase}_nmds.txt -o $outdir/bdiv_rarefied/${dmbase}_nmds_converted.txt >/dev/null 2>&1 || true ) &
	done
	wait
	echo "" >> $log
	else
	echo "
PCoA and NMDS coordinate files already present." >> $log
	fi

## Make 3D emperor plots (PCoA)
	pcoaplotscount=`ls $outdir/bdiv_rarefied/*_pcoa_plot 2>/dev/null | wc -l`
	if [[ $pcoaplotscount == 0 ]]; then
	echo "
Make emperor commands:" >> $log
	echo "
Generating 3D PCoA plots."
	echo "PCoA plots:" >> $log
	for pc in $outdir/bdiv_rarefied/*_pc.txt; do
	pcbase=$(basename $pc _pc.txt)
		if [[ -d $outdir/bdiv_rarefied/${pcbase}_emperor_pcoa_plot/ ]]; then
		rm -r $outdir/bdiv_rarefied/${pcbase}_emperor_pcoa_plot/
		fi
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	echo "	make_emperor.py -i $pc -o $outdir/bdiv_rarefied/${pcbase}_emperor_pcoa_plot/ -m $mapfile --add_unique_columns --ignore_missing_samples" >> $log
	( make_emperor.py -i $pc -o $outdir/bdiv_rarefied/${pcbase}_emperor_pcoa_plot/ -m $mapfile --add_unique_columns --ignore_missing_samples >/dev/null 2>&1 || true ) &
	done
	wait
	echo "" >> $log
	else
	echo "
3D PCoA plots already present." >> $log
	fi

## Make 3D emperor plots (NMDS)
	nmdsplotscount=`ls $outdir/bdiv_rarefied/*_nmds_plot 2>/dev/null | wc -l`
	if [[ $nmdsplotscount == 0 ]]; then
	echo "
Generating 3D NMDS plots."
	echo "NMDS plots:" >> $log
	for nmds in $outdir/bdiv_rarefied/*_nmds_converted.txt; do
	nmdsbase=$(basename $nmds _nmds_converted.txt)
		if [[ -d $outdir/bdiv_rarefied/${nmdsbase}_emperor_nmds_plot/ ]]; then
		rm -r $outdir/bdiv_rarefied/${nmdsbase}_emperor_nmds_plot/
		fi
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	echo "	make_emperor.py -i $nmds -o $outdir/bdiv_rarefied/${nmdsbase}_emperor_nmds_plot/ -m $mapfile --add_unique_columns --ignore_missing_samples" >> $log
	( make_emperor.py -i $nmds -o $outdir/bdiv_rarefied/${nmdsbase}_emperor_nmds_plot/ -m $mapfile --add_unique_columns --ignore_missing_samples >/dev/null 2>&1 || true ) &
	done
	wait
	echo "" >> $log
	else
	echo "
3D NMDS plots already present." >> $log
	fi

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

## Make 2D plots
	if [[ ! -d $outdir/bdiv_rarefied/2D_PCoA_bdiv_plots ]]; then
	echo "
Make 2D PCoA plots commands:" >> $log
	echo "
Generating 2D PCoA plots."
	for pc in $outdir/bdiv_rarefied/*_pc.txt; do
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	echo "	make_2d_plots.py -i $pc -m $mapfile -o $outdir/bdiv_rarefied/2D_PCoA_bdiv_plots" >> $log
	( make_2d_plots.py -i $pc -m $mapfile -o $outdir/bdiv_rarefied/2D_PCoA_bdiv_plots >/dev/null 2>&1 || true ) &
	done
	wait
	echo "" >> $log
	else
	echo "
2D plots already present." >> $log
	fi

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

## Comparing categories statistics
if [[ ! -f $outdir/bdiv_rarefied/permanova_results_collated.txt && ! -f $outdir/bdiv_rarefied/permdisp_results_collated.txt && ! -f $outdir/bdiv_rarefied/anosim_results_collated.txt && ! -f $outdir/bdiv_rarefied/dbrda_results_collated.txt && ! -f $outdir/bdiv_rarefied/adonis_results_collated.txt ]]; then
echo "
Compare categories commands:" >> $log
	echo "
Calculating one-way statsitics from distance matrices."
	if [[ ! -f $outdir/bdiv_rarefied/permanova_results_collated.txt ]]; then
echo > $outdir/bdiv_rarefied/permanova_results_collated.txt
echo "Running PERMANOVA tests."
echo "PERMANOVA:" >> $log
	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_rarefied/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		echo "	compare_categories.py --method permanova -i $dm -m $mapfile -c $line -o $outdir/bdiv_rarefied/permanova_out/$line/$method/" >> $log
		( compare_categories.py --method permanova -i $dm -m $mapfile -c $line -o $outdir/bdiv_rarefied/permanova_out/$line/$method/ >/dev/null 2>&1 || true ) &
		done
	done
	wait
	echo "" >> $log

	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_rarefied/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		echo "Category: $line" >> $outdir/bdiv_rarefied/permanova_results_collated.txt
		echo "Method: $method" >> $outdir/bdiv_rarefied/permanova_results_collated.txt
		cat $outdir/bdiv_rarefied/permanova_out/$line/$method/permanova_results.txt >> $outdir/bdiv_rarefied/permanova_results_collated.txt 2>/dev/null || true
		echo "" >> $outdir/bdiv_rarefied/permanova_results_collated.txt
		done
	done
	wait
	fi

	if [[ ! -f $outdir/bdiv_rarefied/permdisp_results_collated.txt ]]; then
echo > $outdir/bdiv_rarefied/permdisp_results_collated.txt
echo "Running PERMDISP tests."
echo "PERMDISP:" >> $log
	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_rarefied/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		echo "	compare_categories.py --method permdisp -i $dm -m $mapfile -c $line -o $outdir/bdiv_rarefied/permdisp_out/$line/$method/" >> $log
		( compare_categories.py --method permdisp -i $dm -m $mapfile -c $line -o $outdir/bdiv_rarefied/permdisp_out/$line/$method/ >/dev/null 2>&1 || true ) &
		done
	done
	wait
	echo "" >> $log

	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_rarefied/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		echo "Category: $line" >> $outdir/bdiv_rarefied/permdisp_results_collated.txt
		echo "Method: $method" >> $outdir/bdiv_rarefied/permdisp_results_collated.txt
		cat $outdir/bdiv_rarefied/permdisp_out/$line/$method/permdisp_results.txt >> $outdir/bdiv_rarefied/permdisp_results_collated.txt 2>/dev/null || true
		echo "" >> $outdir/bdiv_rarefied/permdisp_results_collated.txt
		done
	done
	wait
	fi

	if [[ ! -f $outdir/bdiv_rarefied/anosim_results_collated.txt ]]; then
echo > $outdir/bdiv_rarefied/anosim_results_collated.txt
echo "Running ANOSIM tests."
echo "ANOSIM:" >> $log
	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_rarefied/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		echo "	compare_categories.py --method anosim -i $dm -m $mapfile -c $line -o $outdir/bdiv_rarefied/anosim_out/$line/$method/" >> $log
		( compare_categories.py --method anosim -i $dm -m $mapfile -c $line -o $outdir/bdiv_rarefied/anosim_out/$line/$method/ 2>/dev/null 2>&1 || true ) &
		done
	done
	wait
	echo "" >> $log

	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_rarefied/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		echo "Category: $line" >> $outdir/bdiv_rarefied/anosim_results_collated.txt
		echo "Method: $method" >> $outdir/bdiv_rarefied/anosim_results_collated.txt
		cat $outdir/bdiv_rarefied/anosim_out/$line/$method/anosim_results.txt >> $outdir/bdiv_rarefied/anosim_results_collated.txt 2>/dev/null || true
		echo "" >> $outdir/bdiv_rarefied/anosim_results_collated.txt
		done
	done
	wait
	fi

	if [[ ! -f $outdir/bdiv_rarefied/dbrda_results_collated.txt ]]; then
echo > $outdir/bdiv_rarefied/dbrda_results_collated.txt
echo "Running DB-RDA tests."
echo "DB-RDA:" >> $log
	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_rarefied/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		echo "	compare_categories.py --method dbrda -i $dm -m $mapfile -c $line -o $outdir/bdiv_rarefied/dbrda_out/$line/$method/" >> $log
		( compare_categories.py --method dbrda -i $dm -m $mapfile -c $line -o $outdir/bdiv_rarefied/dbrda_out/$line/$method/ 2>/dev/null 2>&1 || true ) &
		done
	done
	wait
	echo "" >> $log

	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_rarefied/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		echo "Category: $line" >> $outdir/bdiv_rarefied/dbrda_results_collated.txt
		echo "Method: $method" >> $outdir/bdiv_rarefied/dbrda_results_collated.txt
		cat $outdir/bdiv_rarefied/dbrda_out/$line/$method/dbrda_results.txt >> $outdir/bdiv_rarefied/dbrda_results_collated.txt 2>/dev/null || true
		echo "" >> $outdir/bdiv_rarefied/dbrda_results_collated.txt
		done
	done
	wait
	fi

	if [[ ! -f $outdir/bdiv_rarefied/adonis_results_collated.txt ]]; then
echo > $outdir/bdiv_rarefied/adonis_results_collated.txt
echo "Running Adonis tests."
echo "Adonis:" >> $log
	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_rarefied/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		echo "	compare_categories.py --method adonis -i $dm -m $mapfile -c $line -o $outdir/bdiv_rarefied/adonis_out/$line/$method/" >> $log
		( compare_categories.py --method adonis -i $dm -m $mapfile -c $line -o $outdir/bdiv_rarefied/adonis_out/$line/$method/ 2>/dev/null 2>&1 || true ) &
		done
	done
	wait
	echo "" >> $log

	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_rarefied/*_dm.txt; do
		method=$(basename $dm _dm.txt)
		echo "Category: $line" >> $outdir/bdiv_rarefied/adonis_results_collated.txt
		echo "Method: $method" >> $outdir/bdiv_rarefied/adonis_results_collated.txt
		cat $outdir/bdiv_rarefied/adonis_out/$line/$method/adonis_results.txt >> $outdir/bdiv_rarefied/adonis_results_collated.txt 2>/dev/null || true
		echo "" >> $outdir/bdiv_rarefied/adonis_results_collated.txt
		done
	done
	wait
	fi
else
echo "
Categorical comparisons already present." >> $log
fi
	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

## Distance boxplots for each category
	boxplotscount=`ls $outdir/bdiv_rarefied/*_boxplots 2>/dev/null | wc -l`
	if [[ $boxplotscount == 0 ]]; then
	echo "
Make distance boxplots commands:" >> $log
	echo "
Generating distance boxplots."
	for line in `cat $catlist`; do
		for dm in $outdir/bdiv_rarefied/*_dm.txt; do
		dmbase=$(basename $dm _dm.txt)
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		echo "	make_distance_boxplots.py -d $outdir/bdiv_rarefied/${dmbase}_dm.txt -f $line -o $outdir/bdiv_rarefied/${dmbase}_boxplots/ -m $mapfile -n 999" >> $log
		( make_distance_boxplots.py -d $outdir/bdiv_rarefied/${dmbase}_dm.txt -f $line -o $outdir/bdiv_rarefied/${dmbase}_boxplots/ -m $mapfile -n 999 >/dev/null 2>&1 || true ) &
		done
	done
	wait
	echo "" >> $log
	else
	echo "
Boxplots already present." >> $log
	fi

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

## Make biplots
	if [[ ! -d $outdir/bdiv_rarefied/biplots ]]; then
	echo "
Make biplots commands:" >> $log
	echo "
Generating PCoA biplots:"
	mkdir $outdir/bdiv_rarefied/biplots
	for pc in $outdir/bdiv_rarefied/*_pc.txt; do
	pcmethod=$(basename $pc _pc.txt)
	mkdir $outdir/bdiv_rarefied/biplots/$pcmethod
	done
	wait

	for pc in $outdir/bdiv_rarefied/*_pc.txt; do
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	pcmethod=$(basename $pc _pc.txt)
		for level in $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_*.txt; do
		L=$(basename $level .txt)
		echo "	make_emperor.py -i $pc -m $mapfile -o $outdir/bdiv_rarefied/biplots/$pcmethod/$L -t $level --add_unique_columns --ignore_missing_samples" >> $log
		( make_emperor.py -i $pc -m $mapfile -o $outdir/bdiv_rarefied/biplots/$pcmethod/$L -t $level --add_unique_columns --ignore_missing_samples >/dev/null 2>&1 || true ) &
		done
	done
	wait
	echo "" >> $log
	else
	echo "
Biplots already present." >> $log
	fi

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

## Run supervised learning on data using supplied categories
	if [[ ! -d $outdir/bdiv_rarefied/SupervisedLearning ]]; then
	mkdir $outdir/bdiv_rarefied/SupervisedLearning
	echo "
Supervised learning commands:" >> $log
	echo "
Running supervised learning analysis."
	for category in `cat $catlist`; do
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		echo "	supervised_learning.py -i $raresort -m $mapfile -c $category -o $outdir/bdiv_rarefied/SupervisedLearning/$category --ntree 1000" >> $log
		( supervised_learning.py -i $raresort -m $mapfile -c $category -o $outdir/bdiv_rarefied/SupervisedLearning/$category --ntree 1000 &>/dev/null 2>&1 || true ) &
	done
	else
	echo "
Supervised Learning already present." >> $log
	fi

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

## Make rank abundance plots (rarefied)
	if [[ ! -d $outdir/bdiv_rarefied/RankAbundance ]]; then
	mkdir $outdir/bdiv_rarefied/RankAbundance
	echo "
Rank abundance plot commands:" >> $log
	echo "
Generating rank abundance plots."
	echo "	plot_rank_abundance_graph.py -i $raresort -o $outdir/bdiv_rarefied/RankAbundance/rankabund_xlog-ylog.pdf -s "*" -n
	plot_rank_abundance_graph.py -i $raresort -o $outdir/bdiv_rarefied/RankAbundance/rankabund_xlinear-ylog.pdf -s "*" -n -x
	plot_rank_abundance_graph.py -i $raresort -o $outdir/bdiv_rarefied/RankAbundance/rankabund_xlog-ylinear.pdf -s "*" -n -y
	plot_rank_abundance_graph.py -i $raresort -o $outdir/bdiv_rarefied/RankAbundance/rankabund_xlinear-ylinear.pdf -s "*" -n -x -y
	" >> $log
	( plot_rank_abundance_graph.py -i $raresort -o $outdir/bdiv_rarefied/RankAbundance/rankabund_xlog-ylog.pdf -s "*" -n ) &
	( plot_rank_abundance_graph.py -i $raresort -o $outdir/bdiv_rarefied/RankAbundance/rankabund_xlinear-ylog.pdf -s "*" -n -x ) &
	( plot_rank_abundance_graph.py -i $raresort -o $outdir/bdiv_rarefied/RankAbundance/rankabund_xlog-ylinear.pdf -s "*" -n -y ) &
	( plot_rank_abundance_graph.py -i $raresort -o $outdir/bdiv_rarefied/RankAbundance/rankabund_xlinear-ylinear.pdf -s "*" -n -x -y ) &
	fi
wait

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

	## Remove pointless log.txt file output by supervised learning
	sllogtest=$(grep "confusion.matrix" ./log.txt 2>/dev/null)
	if [[ ! -z "$sllogtest" ]]; then
		rm log.txt
	fi

###################################
## Start of alpha diversity steps

## Multiple rarefactions
	alphastepsize=$(($depth/10))

	if [[ ! -d $outdir/arare_max$depth ]]; then
	echo "
Multiple rarefaction command:
	parallel_multiple_rarefactions.py -T -i $raresort -m 10 -x $depth -s $alphastepsize -o $outdir/arare_max$depth/rarefaction/ -O $cores" >> $log
	echo "
Performing mutiple rarefactions for alpha diversity analysis."
	parallel_multiple_rarefactions.py -T -i $raresort -m 10 -x $depth -s $alphastepsize -o $outdir/arare_max$depth/rarefaction/ -O $cores 1> $stdout 2> $stderr
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log

## Alpha diversity
	if [[ "$phylogenetic" == "YES" ]]; then
	echo "
Alpha diversity command:
	parallel_alpha_diversity.py -T -i $outdir/arare_max$depth/rarefaction/ -o $outdir/arare_max$depth/alpha_div/ -t $tree -O $cores -m $alphametrics" >> $log
	echo "
Calculating alpha diversity."
	parallel_alpha_diversity.py -T -i $outdir/arare_max$depth/rarefaction/ -o $outdir/arare_max$depth/alpha_div/ -t $tree -O $cores -m $alphametrics
        elif [[ "$phylogenetic" == "NO" ]]; then
	echo "
Alpha diversity command:
        parallel_alpha_diversity.py -T -i $outdir/arare_max$depth/rarefaction/ -o $outdir/arare_max$depth/alpha_div/ -O $cores -m $alphametrics" >> $log
	echo "
Calculating alpha diversity."
        parallel_alpha_diversity.py -T -i $outdir/arare_max$depth/rarefaction/ -o $outdir/arare_max$depth/alpha_div/ -O $cores -m $alphametrics
	fi

## Collate alpha
	if [[ ! -d $outdir/arare_max$depth/alpha_div_collated/ ]]; then
	echo "
Collate alpha command:
	collate_alpha.py -i $outdir/arare_max$depth/alpha_div/ -o $outdir/arare_max$depth/alpha_div_collated/" >> $log
	collate_alpha.py -i $outdir/arare_max$depth/alpha_div/ -o $outdir/arare_max$depth/alpha_div_collated/ 1> $stdout 2> $stderr
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	rm -r $outdir/arare_max$depth/rarefaction/ $outdir/arare_max$depth/alpha_div/

## Make rarefaction plots
	echo "
Make rarefaction plots command:
	make_rarefaction_plots.py -i $outdir/arare_max$depth/alpha_div_collated/ -m $mapfile -o $outdir/arare_max$depth/alpha_rarefaction_plots/ -d 300 -e stderr" >> $log
	echo "
Generating alpha rarefaction plots."
	make_rarefaction_plots.py -i $outdir/arare_max$depth/alpha_div_collated/ -m $mapfile -o $outdir/arare_max$depth/alpha_rarefaction_plots/ -d 300 -e stderr 1> $stdout 2> $stderr || true
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log

## Alpha diversity stats
	echo "
Compare alpha diversity commands:" >> $log
	echo "
Calculating alpha diversity statistics."
	for file in $outdir/arare_max$depth/alpha_div_collated/*.txt; do
	filebase=$(basename $file .txt)
		while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
		sleep 1
		done
		echo "compare_alpha_diversity.py -i $file -m $mapfile -c $cats -o $outdir/arare_max$depth/alpha_compare_parametric -t parametric -p fdr" >> $log
		( compare_alpha_diversity.py -i $file -m $mapfile -c $cats -o $outdir/arare_max$depth/compare_$filebase\_parametric -t parametric -p fdr >/dev/null 2>&1 || true ) &
		echo "compare_alpha_diversity.py -i $file -m $mapfile -c $cats -o $outdir/arare_max$depth/alpha_compare_nonparametric -t nonparametric -p fdr" >> $log
		( compare_alpha_diversity.py -i $file -m $mapfile -c $cats -o $outdir/arare_max$depth/compare_$filebase\_nonparametric -t nonparametric -p fdr >/dev/null 2>&1 || true ) &
	done
	fi
	wait
	else
	echo "
Alpha diversity analysis already completed." >> $log
	fi

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

#######################################
## Start of taxonomy plotting steps

## Plot taxa summaries
		if [[ ! -d $outdir/taxa_plots ]]; then
	echo "
Plotting taxonomy by sample."
	echo "
Plot taxa summaries command:
	plot_taxa_summary.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L2.txt,$outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L3.txt,$outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L4.txt,$outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L5.txt,$outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L6.txt,$outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L7.txt -o $outdir/taxa_plots/taxa_summary_plots/ -c bar" >> $log
	plot_taxa_summary.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L2.txt,$outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L3.txt,$outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L4.txt,$outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L5.txt,$outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L6.txt,$outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L7.txt -o $outdir/taxa_plots/taxa_summary_plots/ -c bar 1> $stdout 2> $stderr || true
	wait
		bash $scriptdir/log_slave.sh $stdout $stderr $log
		fi

## Taxa summaries for each category
	for line in `cat $catlist`; do
		if [[ ! -d $outdir/taxa_plots_$line ]]; then
	echo "
Building taxonomy plots for category: $line."
	echo "
Summarize taxa commands by category \"$line\":
	collapse_samples.py -m ${mapfile} -b ${raresort} --output_biom_fp ${outdir}/taxa_plots_${line}/${line}_otu_table.biom --output_mapping_fp ${outdir}/taxa_plots_${line}/${line}_map.txt --collapse_fields $line
	sort_otu_table.py -i ${outdir}/taxa_plots_${line}/${line}_otu_table.biom -o ${outdir}/taxa_plots_${line}/${line}_otu_table_sorted.biom
	summarize_taxa.py -i ${outdir}/taxa_plots_${line}/${line}_otu_table_sorted.biom -o ${outdir}/taxa_plots_${line}/  -L 2,3,4,5,6,7 -a
	plot_taxa_summary.py -i ${outdir}/taxa_plots_${line}/${line}_otu_table_sorted_L2.txt,${outdir}/taxa_plots_${line}/${line}_otu_table_sorted_L3.txt,${outdir}/taxa_plots_${line}/${line}_otu_table_sorted_L4.txt,${outdir}/taxa_plots_${line}/${line}_otu_table_sorted_L5.txt,${outdir}/taxa_plots_${line}/${line}_otu_table_sorted_L6.txt,${outdir}/taxa_plots_${line}/${line}_otu_table_sorted_L7.txt -o ${outdir}/taxa_plots_${line}/taxa_summary_plots/ -c bar,pie" >> $log

		mkdir $outdir/taxa_plots_$line

	collapse_samples.py -m ${mapfile} -b ${raresort} --output_biom_fp ${outdir}/taxa_plots_${line}/${line}_otu_table.biom --output_mapping_fp ${outdir}/taxa_plots_${line}/${line}_map.txt --collapse_fields $line 1> $stdout 2> $stderr || true
	wait
		bash $scriptdir/log_slave.sh $stdout $stderr $log
		wait
	sort_otu_table.py -i ${outdir}/taxa_plots_${line}/${line}_otu_table.biom -o ${outdir}/taxa_plots_${line}/${line}_otu_table_sorted.biom 1> $stdout 2> $stderr || true
	wait
		bash $scriptdir/log_slave.sh $stdout $stderr $log
		wait
	summarize_taxa.py -i ${outdir}/taxa_plots_${line}/${line}_otu_table_sorted.biom -o ${outdir}/taxa_plots_${line}/  -L 2,3,4,5,6,7 -a 1> $stdout 2> $stderr || true
	wait
		bash $scriptdir/log_slave.sh $stdout $stderr $log
		wait
	plot_taxa_summary.py -i ${outdir}/taxa_plots_${line}/${line}_otu_table_sorted_L2.txt,${outdir}/taxa_plots_${line}/${line}_otu_table_sorted_L3.txt,${outdir}/taxa_plots_${line}/${line}_otu_table_sorted_L4.txt,${outdir}/taxa_plots_${line}/${line}_otu_table_sorted_L5.txt,${outdir}/taxa_plots_${line}/${line}_otu_table_sorted_L6.txt,${outdir}/taxa_plots_${line}/${line}_otu_table_sorted_L7.txt -o ${outdir}/taxa_plots_${line}/taxa_summary_plots/ -c bar,pie 1> $stdout 2> $stderr || true
	wait
		bash $scriptdir/log_slave.sh $stdout $stderr $log
		wait
		fi
	done

	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

## Run supervised learning on data using supplied categories
	if [[ ! -d $outdir/bdiv_rarefied/SupervisedLearning ]]; then
	mkdir -p $outdir/bdiv_rarefied/SupervisedLearning
	echo "Running supervised learning analysis.
	"
	for category in `cat $catlist`; do
	supervised_learning.py -i $raresort-m $mapfile -c $category -o $outdir/bdiv_rarefied/SupervisedLearning/$category --ntree 1000 >/dev/null 2>&1 || true
	done
	fi

############################
## Group comparison steps

## Group significance for each category (Kruskal-Wallis and nonparametric Ttest)

	## Kruskal-Wallis
	kwtestcount=$(ls $outdir/KruskalWallis/kruskalwallis_* 2> /dev/null | wc -l)
	if [[ $kwtestcount == 0 ]]; then
	echo "
Group significance commands:" >> $log
	if [[ ! -d $outdir/KruskalWallis ]]; then
	mkdir $outdir/KruskalWallis
	fi
	raresortrel="$outdir/OTU_tables/rarefied_table_sorted_relativized.biom"
	if [[ ! -f $raresortrel ]]; then
	echo "
Relativizing OTU table:
	relativize_otu_table.py -i $raresort" >> $log
	relativize_otu_table.py -i $raresort >/dev/null 2>&1 || true
	fi
		raresortreltxt="$outdir/OTU_tables/rarefied_table_sorted_relativized.txt"
		if [[ ! -f $raresortreltxt ]]; then
		biomtotxt.sh $raresortrel &>/dev/null
		sed -i '/# Constructed from biom file/d' $raresortreltxt 2>/dev/null || true
		fi
	echo "
Calculating Kruskal-Wallis test statistics when possible."
for line in `cat $catlist`; do
	if [[ ! -f $outdir/KruskalWallis/kruskalwallis_${line}_OTU.txt ]]; then
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	echo "	group_significance.py -i $raresortrel -m $mapfile -c $line -o $outdir/KruskalWallis/kruskalwallis_${line}_OTU.txt -s kruskal_wallis" >> $log
	( group_significance.py -i $raresortrel -m $mapfile -c $line -o $outdir/KruskalWallis/kruskalwallis_${line}_OTU.txt -s kruskal_wallis ) >/dev/null 2>&1 || true &
	fi
done
wait
for line in `cat $catlist`; do
	if [[ ! -f $outdir/KruskalWallis/kruskalwallis_$line\_L2.txt ]]; then
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	echo "	group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L2.biom -m $mapfile -c $line -o $outdir/KruskalWallis/kruskalwallis_${line}_L2.txt -s kruskal_wallis" >> $log
	( group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L2.biom -m $mapfile -c $line -o $outdir/KruskalWallis/kruskalwallis_${line}_L2.txt -s kruskal_wallis ) >/dev/null 2>&1 || true &
	fi
done
wait
for line in `cat $catlist`; do
	if [[ ! -f $outdir/KruskalWallis/kruskalwallis_$line\_L3.txt ]]; then
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	echo "	group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L3.biom -m $mapfile -c $line -o $outdir/KruskalWallis/kruskalwallis_${line}_L3.txt -s kruskal_wallis" >> $log
	( group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L3.biom -m $mapfile -c $line -o $outdir/KruskalWallis/kruskalwallis_${line}_L3.txt -s kruskal_wallis ) >/dev/null 2>&1 || true &
	fi
done
wait
for line in `cat $catlist`; do
	if [[ ! -f $outdir/KruskalWallis/kruskalwallis_$line\_L4.txt ]]; then
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	echo "	group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L4.biom -m $mapfile -c $line -o $outdir/KruskalWallis/kruskalwallis_${line}_L4.txt -s kruskal_wallis" >> $log
	( group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L4.biom -m $mapfile -c $line -o $outdir/KruskalWallis/kruskalwallis_${line}_L4.txt -s kruskal_wallis ) >/dev/null 2>&1 || true &
	fi
done
wait
for line in `cat $catlist`; do
	if [[ ! -f $outdir/KruskalWallis/kruskalwallis_$line\_L5.txt ]]; then
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	echo "	group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L5.biom -m $mapfile -c $line -o $outdir/KruskalWallis/kruskalwallis_${line}_L5.txt -s kruskal_wallis" >> $log
	( group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L5.biom -m $mapfile -c $line -o $outdir/KruskalWallis/kruskalwallis_${line}_L5.txt -s kruskal_wallis ) >/dev/null 2>&1 || true &
	fi
done
wait
for line in `cat $catlist`; do
	if [[ ! -f $outdir/KruskalWallis/kruskalwallis_$line\_L6.txt ]]; then
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	echo "	group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L6.biom -m $mapfile -c $line -o $outdir/KruskalWallis/kruskalwallis_${line}_L6.txt -s kruskal_wallis" >> $log
	( group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L6.biom -m $mapfile -c $line -o $outdir/KruskalWallis/kruskalwallis_${line}_L6.txt -s kruskal_wallis ) >/dev/null 2>&1 || true &
	fi
done
wait
for line in `cat $catlist`; do
	if [[ ! -f $outdir/KruskalWallis/kruskalwallis_$line\_L7.txt ]]; then
	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
	echo "	group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L7.biom -m $mapfile -c $line -o $outdir/KruskalWallis/kruskalwallis_${line}_L7.txt -s kruskal_wallis" >> $log
	( group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L7.biom -m $mapfile -c $line -o $outdir/KruskalWallis/kruskalwallis_${line}_L7.txt -s kruskal_wallis ) >/dev/null 2>&1 || true &
	fi
done
fi
wait
	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

#	## Nonparametric T-test
#	if [[ ! -d $outdir/Nonparametric_ttest ]]; then
#	mkdir $outdir/Nonparametric_ttest
#	raresortrel="$outdir/OTU_tables/rarefied_table_sorted_relativized.biom"
#	if [[ ! -f $raresortrel ]]; then
#	echo "
#Relativizing OTU table:
#	relativize_otu_table.py -i $raresort" >> $log
#	relativize_otu_table.py -i $raresort >/dev/null 2>&1 || true
#	fi
#	echo "
#Calculating nonparametric T-test statistics when possible."
#for line in `cat $catlist`; do
#	if [[ ! -f $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_OTU.txt ]]; then
#	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
#	sleep 1
#	done
#	echo "	group_significance.py -i $raresortrel -m $mapfile -c $line -o $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_OTU.txt -s nonparametric_t_test" >> $log
#	( group_significance.py -i $raresortrel -m $mapfile -c $line -o $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_OTU.txt -s nonparametric_t_test ) >/dev/null 2>&1 || true &
#	fi
#done
#wait
#for line in `cat $catlist`; do
#	if [[ ! -f $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L2.txt ]]; then
#	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
#	sleep 1
#	done
#	echo "	group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L2.biom -m $mapfile -c $line -o $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L2.txt -s nonparametric_t_test" >> $log
#	( group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L2.biom -m $mapfile -c $line -o $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L2.txt -s nonparametric_t_test ) >/dev/null 2>&1 || true &
#	fi
#done
#wait
#for line in `cat $catlist`; do
#	if [[ ! -f $outdir/Nonparametric_ttest/nonparametric_ttest_$line\_L3.txt ]]; then
#	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
#	sleep 1
#	done
#	echo "	group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L3.biom -m $mapfile -c $line -o $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L3.txt -s nonparametric_t_test" >> $log
#	( group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L3.biom -m $mapfile -c $line -o $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L3.txt -s nonparametric_t_test ) >/dev/null 2>&1 || true &
#	fi
#done
#wait
#for line in `cat $catlist`; do
#	if [[ ! -f $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L4.txt ]]; then
#	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
#	sleep 1
#	done
#	echo "	group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L4.biom -m $mapfile -c $line -o $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L4.txt -s nonparametric_t_test" >> $log
#	( group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L4.biom -m $mapfile -c $line -o $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L4.txt -s nonparametric_t_test ) >/dev/null 2>&1 || true &
#	fi
#done
#wait
#for line in `cat $catlist`; do
#	if [[ ! -f $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L5.txt ]]; then
#	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
#	sleep 1
#	done
#	echo "	group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L5.biom -m $mapfile -c $line -o $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L5.txt -s nonparametric_t_test" >> $log
#	( group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L5.biom -m $mapfile -c $line -o $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L5.txt -s nonparametric_t_test ) >/dev/null 2>&1 || true &
#	fi
#done
#wait
#for line in `cat $catlist`; do
#	if [[ ! -f $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L6.txt ]]; then
#	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
#	sleep 1
#	done
#	echo "	group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L6.biom -m $mapfile -c $line -o $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L6.txt -s nonparametric_t_test" >> $log
#	( group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L6.biom -m $mapfile -c $line -o $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L6.txt -s nonparametric_t_test ) >/dev/null 2>&1 || true &
#	fi
#done
#wait
#for line in `cat $catlist`; do
#	if [[ ! -f $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L7.txt ]]; then
#	while [ $( pgrep -P $$ |wc -w ) -ge ${threads} ]; do 
#	sleep 1
#	done
#	echo "	group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L7.biom -m $mapfile -c $line -o $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L7.txt -s nonparametric_t_test" >> $log
#	( group_significance.py -i $outdir/bdiv_rarefied/summarized_tables/rarefied_table_sorted_L7.biom -m $mapfile -c $line -o $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L7.txt -s nonparametric_t_test ) >/dev/null 2>&1 || true &
#	fi
#done
#fi
#wait
	## Update HTML output
#		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

## Run match_reads_to_taxonomy if rep set present
## Automatically find merged_rep_set.fna file from existing akutils workflows
if [[ ! -d $outdir/Representative_sequences ]]; then
	rep_set="$inputdirup1/merged_rep_set.fna"
	mkdir -p $outdir/Representative_sequences/
	cp $rep_set $outdir/Representative_sequences/

	if [[ -f $outdir/Representative_sequences/merged_rep_set.fna ]]; then
	repseqs="$outdir/Representative_sequences/merged_rep_set.fna"
	echo "
Extracting sequencing data for each taxon and performing mafft alignments.
	"
echo "
Extracting sequences command:
	bash $scriptdir/match_reads_to_taxonomy.sh $intable $threads $repseqs" >> $log
	bash $scriptdir/match_reads_to_taxonomy.sh $intable $threads $repseqs 1> $stdout 2> $stderr || true
	wait
		bash $scriptdir/log_slave.sh $stdout $stderr $log

	fi

fi
	## Update HTML output
		bash $scriptdir/html_generator.sh $inputbase $outdir $depth $catlist $alphatemp $randcode $tempdir $repodir

done
################################################################################
## End of for loop for multiple tables processing

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

echo "
akutils core_diversity steps completed.  Hooray!
Processed $tablecount OTU tables.
$runtime
"
echo "
********************************************************************************

akutils core_diversity steps completed.  Hooray!
Processed $tablecount OTU tables.
$runtime

********************************************************************************
" >> $log

exit 0
