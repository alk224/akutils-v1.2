#!/bin/bash
set -e

## Check whether user had supplied -h or --help. If yes display help 

	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
		echo "
		This script will process a normalized OTU table in
		a statistically admissible way (without rarefying).
		Output will be the same as with the core diversity
		analysis in qiime, but also including biplots, 2d
		PCoA plots, and collated statistical outputs for
		input categories for permanova and anosim.

		Usage (order is important!!):
		cdiv_for_normalized_tables.sh <otu_table> <output_dir> <mapping_file> <comma_separated_categories> <rarefaction_depth> <processors_to_use> <tree_file>

		<tree_file> is optional.  Analysis will be nonphylogenetic 
		if no tree file is supplied.
		
		Example:
		cdiv_for_normalized_tables.sh CSS_table.biom core_div map.txt Site,Date 1000 12 phylogeny.tre

		Will process the table, CSS_table.biom using the mapping
		file, map.txt, and categories Site and Date through the
		workflow on 12 cores with phylogenetic and nonphylogenetic
		metrics against the tree, phylogeny.tre.  Alpha diversity
		will be assessed at a depth of 1000 reads.  Output will be
		in a subdirectory called core_div.

		Phylogenetic metrics: unweighted_unifrac, weighted_unifrac
		Nonphylogenetic metrics: abund_jaccard, binary_jaccard, bray_curtis, binary_chord, chord, hellinger, kulczynski, manhattan, gower

		It is important that your input table be properly
		filtered before running this workflow, or your output
		may be of questionable quality.  Minimal filtering
		might include removal of low-count samples, singleton
		OTUs, and abundance-based OTU filtering at some level
		(e.g. 0.005%).
		"
		exit 0
	fi 

## If less than five or more than 6 arguments supplied, display usage 

	if [[ "$#" -le 5 ]] || [[ "$#" -ge 8 ]]; then 
		echo "
		Usage (order is important!!):
		cdiv_for_normalized_tables.sh <otu_table> <output_dir> <mapping_file> <comma_separated_categories> <rarefaction_depth> <processors_to_use> <tree_file>

		<tree_file> is optional.  Analysis will be nonphylogenetic 
		if no tree file is supplied.

		"
		exit 1
	fi

## Define variables

intable=($1)
out=($2)
mapfile=($3)
cats=($4)
depth=($5)
cores=($6)
tree=($7)
otuname=$(basename $intable .biom)
outdir=$out/$otuname/
date0=`date +%Y%m%d_%I%M%p`
log=$outdir/log_$date0.txt

## Make output directory or exit if it already exists

	if [[ ! -d $outdir ]]; then
	mkdir -p $outdir
	else
	echo "
		Output directory already exists.  Exiting.
	"
	exit 1
	fi

## Set workflow mode (phylogenetic or nonphylogenetic) and log start

	if [[ -z $tree ]]; then
	mode=nonphylogenetic
	metrics=abund_jaccard,binary_jaccard,bray_curtis,binary_chord,chord,hellinger,kulczynski,manhattan,gower
	else
	mode=phylogenetic
	metrics=abund_jaccard,binary_jaccard,bray_curtis,binary_chord,chord,hellinger,kulczynski,manhattan,gower,unweighted_unifrac,weighted_unifrac
	fi

	echo "
		Core diversity workflow started in $mode mode
	"
		date1=`date "+%a %b %I:%M %p %Z %Y"`
	res0=$(date +%s.%N)

echo "Core diversity workflow started in $mode mode" > $log
echo $date1 >> $log

## Make categories temp file

	IN=$cats
	OIFS=$IFS
	IFS=','
	arr=$IN
	for x in $arr; do
		echo $x > $outdir/categories.tempfile
	done
	IFS=$OIFS

## Summarize input table

	cp $intable $outdir/table.biom
	table=$outdir/table.biom

	echo "
Summarize table command:
	biom summarize-table -i $table -o $outdir/biom_table_summary.txt" >> $log

	biom summarize-table -i $table -o $outdir/biom_table_summary.txt

	if [[ ! -s $outdir/biom_table_summary.txt ]]; then
	echo "
		Biom table summary is size zero.  Exiting
	"
	exit 1
	fi

## Beta diversity

	if [[ "$mode" == phylogenetic ]]; then
	echo "
Parallel beta diversity command:
	parallel_beta_diversity.py -i $table -o $outdir/bdiv/ --metrics $metrics -T  -t $tree --jobs_to_start $cores" >> $log
	parallel_beta_diversity.py -i $table -o $outdir/bdiv/ --metrics $metrics -T  -t $tree --jobs_to_start $cores

	elif [[ "$mode" == nonphylogenetic ]]; then
	echo "
Parallel beta diversity command:
	parallel_beta_diversity.py -i $table -o $outdir/bdiv/ --metrics $metrics -T --jobs_to_start $cores" >> $log
	parallel_beta_diversity.py -i $table -o $outdir/bdiv/ --metrics $metrics -T --jobs_to_start $cores

	fi

## Rename output files

	for dm in $outdir/bdiv/*_table.txt; do
	dmbase=$( basename $dm _table.txt )
	mv $dm $outdir/bdiv/$dmbase\_dm.txt
	done

## Principal coordinates
	echo "
Principal coordinates commands:" >> $log

	for dm in $outdir/bdiv/*_dm.txt; do
	dmbase=$( basename $dm _dm.txt )
	echo "	principal_coordinates.py -i $dm -o $outdir/bdiv/$dmbase\_pc.txt" >> $log
	principal_coordinates.py -i $dm -o $outdir/bdiv/$dmbase\_pc.txt 
	done

## Make emperor
	echo "
Make emperor commands:" >> $log

	for pc in $outdir/bdiv/*_pc.txt; do
	pcbase=$( basename $pc _pc.txt )
	echo "	make_emperor.py -i $pc -o $outdir/bdiv/$pcbase\_emperor_pcoa_plot/ -m $mapfile" >> $log
	make_emperor.py -i $pc -o $outdir/bdiv/$pcbase\_emperor_pcoa_plot/ -m $mapfile
	done

## Anosim and permanova stats

echo > $outdir/permanova_results_collated.txt
echo > $outdir/anosim_results_collated.txt
echo "
Compare categories commands:" >> $log

	for line in `cat $outdir/categories.tempfile`; do
		for dm in $outdir/bdiv/*_dm.txt; do
		method=$( basename $dm .txt )
		echo "	compare_categories.py --method permanova -i $dm -m $mapfile -c $line -o $outdir/permanova_temp/$line/$method/" >> $log
		compare_categories.py --method permanova -i $dm -m $mapfile -c $line -o $outdir/permanova_temp/$line/$method/
		echo "Category: $line" >> $outdir/permanova_results_collated.txt
		echo "Method: $method" >> $outdir/permanova_results_collated.txt
		cat $outdir/permanova_temp/$line/$method/permanova_results.txt >> $outdir/permanova_results_collated.txt
		echo "" >> $outdir/permanova_results_collated.txt

		echo "	compare_categories.py --method anosim -i $dm -m $mapfile -c $line -o $outdir/anosim_temp/$line/$method/" >> $log
		compare_categories.py --method anosim -i $dm -m $mapfile -c $line -o $outdir/anosim_temp/$line/$method/
		echo "Category: $line" >> $outdir/anosim_results_collated.txt
		echo "Method: $method" >> $outdir/anosim_results_collated.txt
		cat $outdir/anosim_temp/$line/$method/anosim_results.txt >> $outdir/anosim_results_collated.txt
		echo "" >> $outdir/anosim_results_collated.txt
		done
done


## Multiple rarefactions
	echo "
Multiple rarefaction command:
	parallel_multiple_rarefactions.py -T -i $table -m 10 -x $depth -s 99 -o $outdir/arare_max$depth/rarefaction/ -O $cores" >> $log
	parallel_multiple_rarefactions.py -T -i $table -m 10 -x $depth -s 99 -o $outdir/arare_max$depth/rarefaction/ -O $cores

## Alpha diversity
        if [[ "$mode" == phylogenetic ]]; then
	echo "
Alpha diversity command:
	parallel_alpha_diversity.py -T -i $outdir/arare_max$depth/rarefaction/ -o $outdir/arare_max$depth/alpha_div/ -t $tree -O $cores -m PD_whole_tree,chao1,observed_species,shannon" >> $log
	parallel_alpha_diversity.py -T -i $outdir/arare_max$depth/rarefaction/ -o $outdir/arare_max$depth/alpha_div/ -t $tree -O $cores -m PD_whole_tree,chao1,observed_species,shannon

        elif [[ "$mode" == nonphylogenetic ]]; then
	echo "
Alpha diversity command:
        parallel_alpha_diversity.py -T -i $outdir/arare_max$depth/rarefaction/ -o $outdir/arare_max$depth/alpha_div/ -O $cores -m chao1,observed_species,shannon" >> $log
        parallel_alpha_diversity.py -T -i $outdir/arare_max$depth/rarefaction/ -o $outdir/arare_max$depth/alpha_div/ -O $cores -m chao1,observed_species,shannon
	fi

## Make 2D plots in background
	echo "
Make 2D plots commands:" >> $log
	for pc in $outdir/bdiv/*_pc.txt; do
	echo "	make_2d_plots.py -i $pc -m $mapfile -o $outdir/2D_bdiv_plots" >> $log
	( make_2d_plots.py -i $pc -m $mapfile -o $outdir/2D_bdiv_plots ) &
	done

## Collate alpha
	echo "
Collate alpha command:
	collate_alpha.py -i $outdir/arare_max$depth/alpha_div/ -o $outdir/arare_max$depth/alpha_div_collated/" >> $log
	collate_alpha.py -i $outdir/arare_max$depth/alpha_div/ -o $outdir/arare_max$depth/alpha_div_collated/

	rm -r $outdir/arare_max$depth/rarefaction/ $outdir/arare_max$depth/alpha_div/

## Make rarefaction plots
	echo "
Make rarefaction plots command:
	make_rarefaction_plots.py -i $outdir/arare_max$depth/alpha_div_collated/ -m $mapfile -o $outdir/arare_max$depth/alpha_rarefaction_plots/" >> $log
	make_rarefaction_plots.py -i $outdir/arare_max$depth/alpha_div_collated/ -m $mapfile -o $outdir/arare_max$depth/alpha_rarefaction_plots/

## Sort OTU table
	echo "
Sort OTU table command:
	sort_otu_table.py -i $table -o $outdir/taxa_plots/table_sorted.biom" >> $log
	mkdir $outdir/taxa_plots
	sort_otu_table.py -i $table -o $outdir/taxa_plots/table_sorted.biom
	sortedtable=($outdir/taxa_plots/table_sorted.biom)

## Summarize taxa
	echo "
Summarize taxa command:
	summarize_taxa.py -i $sortedtable -o $outdir/taxa_plots/ -L 2,3,4,5,6,7" >> $log
	summarize_taxa.py -i $sortedtable -o $outdir/taxa_plots/ -L 2,3,4,5,6,7

## Plot taxa summaries
	echo "
Plot taxa summaries command:
	plot_taxa_summary.py -i $outdir/taxa_plots/table_sorted_L2.txt,$outdir/taxa_plots/table_sorted_L3.txt,$outdir/taxa_plots/table_sorted_L4.txt,$outdir/taxa_plots/table_sorted_L5.txt,$outdir/taxa_plots/table_sorted_L6.txt,$outdir/taxa_plots/table_sorted_L7.txt -o $outdir/taxa_plots/taxa_summary_plots/ -c bar" >> $log
	plot_taxa_summary.py -i $outdir/taxa_plots/table_sorted_L2.txt,$outdir/taxa_plots/table_sorted_L3.txt,$outdir/taxa_plots/table_sorted_L4.txt,$outdir/taxa_plots/table_sorted_L5.txt,$outdir/taxa_plots/table_sorted_L6.txt,$outdir/taxa_plots/table_sorted_L7.txt -o $outdir/taxa_plots/taxa_summary_plots/ -c bar

## Taxa summaries for each category

	for line in `cat $outdir/categories.tempfile`; do
	echo "
Summarize taxa commands by category $line:
	collapse_samples.py -m $mapfile -b $table --output_biom_fp $outdir/taxa_plots_$line/$line\_otu_table.biom --output_mapping_fp $outdir/taxa_plots_$line/$line_map.txt --collapse_fields $line
	sort_otu_table.py -i $outdir/taxa_plots_$line/$line\_otu_table.biom -o $outdir/taxa_plots_$line/$line\_otu_table_sorted.biom
	summarize_taxa.py -i $outdir/taxa_plots_$line/$line\_otu_table_sorted.biom -o $outdir/taxa_plots_$line/
	plot_taxa_summary.py -i $outdir/taxa_plots_$line/$line\_otu_table_sorted_L2.txt,$outdir/taxa_plots_$line/$line\_otu_table_sorted_L3.txt,$outdir/taxa_plots_$line/$line\_otu_table_sorted_L4.txt,$outdir/taxa_plots_$line/$line\_otu_table_sorted_L5.txt,$outdir/taxa_plots_$line/$line\_otu_table_sorted_L6.txt,$outdir/taxa_plots_$line/$line\_otu_table_sorted_L7.txt -o $outdir/taxa_plots_$line/taxa_summary_plots/ -c bar,pie" >> $log

	mkdir $outdir/taxa_plots_$line

	collapse_samples.py -m $mapfile -b $table --output_biom_fp $outdir/taxa_plots_$line/$line\_otu_table.biom --output_mapping_fp $outdir/taxa_plots_$line/$line_map.txt --collapse_fields $line
	
	sort_otu_table.py -i $outdir/taxa_plots_$line/$line\_otu_table.biom -o $outdir/taxa_plots_$line/$line\_otu_table_sorted.biom

	summarize_taxa.py -i $outdir/taxa_plots_$line/$line\_otu_table_sorted.biom -o $outdir/taxa_plots_$line/ -L 2,3,4,5,6,7

	plot_taxa_summary.py -i $outdir/taxa_plots_$line/$line\_otu_table_sorted_L2.txt,$outdir/taxa_plots_$line/$line\_otu_table_sorted_L3.txt,$outdir/taxa_plots_$line/$line\_otu_table_sorted_L4.txt,$outdir/taxa_plots_$line/$line\_otu_table_sorted_L5.txt,$outdir/taxa_plots_$line/$line\_otu_table_sorted_L6.txt,$outdir/taxa_plots_$line/$line\_otu_table_sorted_L7.txt -o $outdir/taxa_plots_$line/taxa_summary_plots/ -c bar,pie

	done

## Distance boxplots for each category
	echo "
Make distance boxplots commands:" >> $log

	for line in `cat $outdir/categories.tempfile`; do

		for dm in $outdir/bdiv/*dm.txt; do
		dmbase=$( basename $dm _dm.txt )
		echo "	make_distance_boxplots.py -d $outdir/bdiv/$dmbase\_dm.txt -f $line -o $outdir/bdiv/$dmbase\_boxplots/ -m $mapfile -n 999" >> $log
		( make_distance_boxplots.py -d $outdir/bdiv/$dmbase\_dm.txt -f $line -o $outdir/bdiv/$dmbase\_boxplots/ -m $mapfile -n 999 ) &
		done

	done

## Group significance for each category
	echo "
Group significance commands:" >> $log

	for line in `cat $outdir/categories.tempfile`; do
	echo "	group_significance.py -i $table -m $mapfile -c $line -o $outdir/group_significance_$line.txt" >> $log
	( group_significance.py -i $table -m $mapfile -c $line -o $outdir/group_significance_$line.txt ) &
	done

## Make biplots
	echo "
Make biplots commands:" >> $log

	mkdir $outdir/biplots
	for pc in $outdir/bdiv/*_pc.txt; do
	pcmethod=$( basename $pc _pc.txt )
	mkdir $outdir/biplots/$pcmethod

		for level in $outdir/taxa_plots/table_sorted_*.txt; do
		L=$( basename $level .txt )
		echo "	make_emperor.py -i $pc -m $mapfile -o $outdir/biplots/$pcmethod/$L -t $level" >> $log
		make_emperor.py -i $pc -m $mapfile -o $outdir/biplots/$pcmethod/$L -t $level
		done
	done

## Make html file

logpath=`ls $outdir/log_*`
logfile=`basename $logpath`

echo "<html>
<head><title>QIIME results</title></head>
<body>
<a href=\"http://www.qiime.org\" target=\"_blank\"><img src=\"http://qiime.org/_static/wordpressheader.png\" alt=\"www.qiime.org\"\"/></a><p>
<table border=1>
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center>Run summary data</td></tr>
<tr><td>Master run log</td><td> <a href=\"$logfile\" target=\"_blank\">$logfile</a></td></tr>
<tr><td>BIOM table statistics</td><td> <a href=\"./biom_table_summary.txt\" target=\"_blank\">biom_table_summary.txt</a></td></tr>" > $outdir/index.html



## Tidy up

	rm $outdir/categories.tempfile
	rm -r $outdir/anosim_temp
	rm -r $outdir/permanova_temp

## Log workflow end

	res1=$( date +%s.%N )
	dt=$( echo $res1 - $res0 | bc )
	dd=$( echo $dt/86400 | bc )
	dt2=$( echo $dt-86400*$dd | bc )
	dh=$( echo $dt2/3600 | bc )
	dt3=$( echo $dt2-3600*$dh | bc )
	dm=$( echo $dt3/60 | bc )
	ds=$( echo $dt3-60*$dm | bc )

	runtime=`printf "Total runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`

echo "
		Core diversity workflow completed!
		$runtime
"
echo "
		Core diversity workflow completed!
		$runtime
" >> $log


