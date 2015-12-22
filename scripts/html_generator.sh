#!/usr/bin/env bash
#
## html_generator.sh - HTML generator for akutils core diversity workflow

## Trap function on exit.
function finish {
if [[ -f $anchor01temp ]]; then
	rm $anchor01temp
fi
if [[ -f $anchor02temp ]]; then
	rm $anchor02temp
fi
if [[ -f $anchor03temp ]]; then
	rm $anchor03temp
fi
if [[ -f $anchor04temp ]]; then
	rm $anchor04temp
fi
if [[ -f $anchor05temp ]]; then
	rm $anchor05temp
fi
if [[ -f $anchor06temp ]]; then
	rm $anchor06temp
fi
if [[ -f $anchor07temp ]]; then
	rm $anchor07temp
fi
if [[ -f $anchor08temp ]]; then
	rm $anchor08temp
fi
if [[ -f $anchor09temp ]]; then
	rm $anchor09temp
fi
if [[ -f $anchor10temp ]]; then
	rm $anchor10temp
fi
if [[ -f $anchor11temp ]]; then
	rm $anchor11temp
fi
if [[ -f $anchor12temp ]]; then
	rm $anchor12temp
fi
if [[ -f $anchor13temp ]]; then
	rm $anchor13temp
fi
if [[ -f $anchor14temp ]]; then
	rm $anchor14temp
fi
if [[ -f $anchor15temp ]]; then
	rm $anchor15temp
fi
if [[ -f $anchor16temp ]]; then
	rm $anchor16temp
fi
if [[ -f $anchor17temp ]]; then
	rm $anchor17temp
fi
if [[ -f $anchor18temp ]]; then
	rm $anchor18temp
fi
if [[ -f $anchor19temp ]]; then
	rm $anchor19temp
fi
}
trap finish EXIT

## Input variables
inputbase="$1"
outdir="$2"
depth="$3"
catlist="$4"
alphatemp="$5"
randcode="$6"
tempdir="$7"
repodir="$8"

## Temp file definitions
anchor01temp="${tempdir}/${randcode}_anchor01.temp"
anchor02temp="${tempdir}/${randcode}_anchor02.temp"
anchor03temp="${tempdir}/${randcode}_anchor03.temp"
anchor04temp="${tempdir}/${randcode}_anchor04.temp"
anchor05temp="${tempdir}/${randcode}_anchor05.temp"
anchor06temp="${tempdir}/${randcode}_anchor06.temp"
anchor07temp="${tempdir}/${randcode}_anchor07.temp"
anchor08temp="${tempdir}/${randcode}_anchor08.temp"
anchor09temp="${tempdir}/${randcode}_anchor09.temp"
anchor10temp="${tempdir}/${randcode}_anchor10.temp"
anchor11temp="${tempdir}/${randcode}_anchor11.temp"
anchor12temp="${tempdir}/${randcode}_anchor12.temp"
anchor13temp="${tempdir}/${randcode}_anchor13.temp"
anchor14temp="${tempdir}/${randcode}_anchor14.temp"
anchor15temp="${tempdir}/${randcode}_anchor15.temp"
anchor16temp="${tempdir}/${randcode}_anchor16.temp"
anchor17temp="${tempdir}/${randcode}_anchor17.temp"
anchor18temp="${tempdir}/${randcode}_anchor18.temp"
anchor19temp="${tempdir}/${randcode}_anchor19.temp"

## Copy blank outputs:
	cp $repodir/akutils_resources/html_template/index.html $outdir
	cp -r $repodir/akutils_resources/html_template/.html $outdir
	if [[ -d $outdir/Representative_sequences ]]; then
		cp -r $repodir/akutils_resources/html_template/sequences_by_taxonomy.html $outdir/Representative_sequences/
	fi

####################################
## Main html output start here:

## Define log file
log=`ls $outdir/log_core_diversity* 2>/dev/null`
logfile=$(basename $log)

## Build anchor01temp (Run summary data)
	## Master log file
echo "<table class=\"center\" border=1>
<tr><td> Master run log </td><td> <a href=\"./$logfile\" target=\"_blank\"> $logfile </a></td></tr>" > $anchor01temp

	## Biom summary files
if [[ -f $outdir/OTU_tables/${inputbase}.summary ]]; then
echo "<tr><td> Input OTU table statistics </td><td> <a href=\"./OTU_tables/${inputbase}.summary\" target=\"_blank\"> ${inputbase}.summary </a></td></tr>" >> $anchor01temp
fi
if [[ -f $outdir/OTU_tables/rarefied_table.summary ]]; then
echo "<tr><td> Rarefied OTU table statistics (depth = $depth) </td><td> <a href=\"./OTU_tables/rarefied_table.summary\" target=\"_blank\"> rarefied_table.summary </a></td></tr>" >> $anchor01temp
fi
if [[ -f $outdir/OTU_tables/sample_filtered_table.summary ]]; then
echo "<tr><td> Sample-filtered OTU table statistics </td><td> <a href=\"./OTU_tables/sample_filtered_table.summary\" target=\"_blank\"> sample_filtered_table.summary </a></td></tr>" >> $anchor01temp
fi
if [[ -f $outdir/OTU_tables/CSS_table.summary ]]; then
echo "<tr><td> CSS-normalized OTU table statistics </td><td> <a href=\"./OTU_tables/CSS_table.summary\" target=\"_blank\"> CSS_table.summary </a></td></tr>" >> $anchor01temp
fi
echo "</table>" >> $anchor01temp

	## Find anchor in template and send data
	linenum=`sed -n "/anchor01/=" $outdir/index.html`
	sed -i "${linenum}r $anchor01temp" $outdir/index.html

## Build anchor02temp (OTU table links)
	## OTU tables
## Tables used in analysis (biom and .txt versions)
echo "<table class=\"center\" border=1>" > $anchor02temp
if [[ -f $outdir/OTU_tables/${inputbase}.biom ]]; then
echo "<tr><td> Input OTU table (BIOM format) </td><td> <a href=\"./OTU_tables/${inputbase}.biom\" target=\"_blank\"> ${inputbase}.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/${inputbase}.txt ]]; then
echo "<tr><td> Input OTU table (tab-delimited format) </td><td> <a href=\"./OTU_tables/${inputbase}.txt\" target=\"_blank\"> ${inputbase}.txt </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/rarefied_table_sorted.biom ]]; then
echo "<tr><td> Rarefied OTU table (BIOM format) </td><td> <a href=\"./OTU_tables/rarefied_table_sorted.biom\" target=\"_blank\"> rarefied_table_sorted.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/rarefied_table_sorted.txt ]]; then
echo "<tr><td> Rarefied OTU table (tab-delimited format) </td><td> <a href=\"./OTU_tables/rarefied_table_sorted.txt\" target=\"_blank\"> rarefied_table_sorted.txt </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/rarefied_table_sorted_relativized.biom ]]; then
echo "<tr><td> Rarefied OTU table, relativized (BIOM format) </td><td> <a href=\"./OTU_tables/rarefied_table_sorted_relativized.biom\" target=\"_blank\"> rarefied_table_sorted_relativized.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/rarefied_table_sorted_relativized.txt ]]; then
echo "<tr><td> Rarefied OTU table, relativized (tab-delimited format) </td><td> <a href=\"./OTU_tables/rarefied_table_sorted_relativized.txt\" target=\"_blank\"> rarefied_table_sorted_relativized.txt </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/sample_filtered_table.biom ]]; then
echo "<tr><td> Sample-filtered table (input for normzliation, BIOM format) </td><td> <a href=\"./OTU_tables/sample_filtered_table.biom\" target=\"_blank\"> sample_filtered_table.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/sample_filtered_table.txt ]]; then
echo "<tr><td> Sample-filtered table (input for normzliation, tab-delimited format) </td><td> <a href=\"./OTU_tables/sample_filtered_table.txt\" target=\"_blank\"> sample_filtered_table.txt </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/CSS_table_sorted.biom ]]; then
echo "<tr><td> Normalized OTU table (BIOM format) </td><td> <a href=\"./OTU_tables/CSS_table_sorted.biom\" target=\"_blank\"> CSS_table_sorted.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/CSS_table_sorted.txt ]]; then
echo "<tr><td> Normalized OTU table (tab-delimited format) </td><td> <a href=\"./OTU_tables/CSS_table_sorted.txt\" target=\"_blank\"> CSS_table_sorted.txt </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/CSS_table_sorted_relativized.biom ]]; then
echo "<tr><td> Normalized OTU table, relativized (BIOM format) </td><td> <a href=\"./OTU_tables/CSS_table_sorted_relativized.biom\" target=\"_blank\"> CSS_table_sorted_relativized.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/CSS_table_sorted_relativized.txt ]]; then
echo "<tr><td> Normalized OTU table, relativized (tab-delimited format) </td><td> <a href=\"./OTU_tables/CSS_table_sorted_relativized.txt\" target=\"_blank\"> CSS_table_sorted_relativized.txt </a></td></tr>" >> $anchor02temp
fi
echo "</table>" >> $anchor02temp

	## Find anchor in template and send data
	linenum=`sed -n "/anchor02/=" $outdir/index.html`
	sed -i "${linenum}r $anchor02temp" $outdir/index.html

## Build anchor03temp (L7 summary data)
	## Representative sequences summary and link
	if [[ -f $outdir/Representative_sequences/L7_taxa_list.txt ]] && [[ -f $outdir/Representative_sequences/otus_per_taxon_summary.txt ]]; then
#	tablename=`basename $table .biom`
	Total_OTUs=`cat $outdir/OTU_tables/$inputbase.txt 2>/dev/null | grep -v "#" 2>/dev/null | wc -l`
	Total_taxa=`cat $outdir/Representative_sequences/L7_taxa_list.txt 2>/dev/null | wc -l`
	Mean_OTUs=`grep mean $outdir/Representative_sequences/otus_per_taxon_summary.txt 2>/dev/null | cut -f2`
	Median_OTUs=`grep median $outdir/Representative_sequences/otus_per_taxon_summary.txt 2>/dev/null | cut -f2`
	Max_OTUs=`grep max $outdir/Representative_sequences/otus_per_taxon_summary.txt 2>/dev/null | cut -f2`
	Min_OTUs=`grep min $outdir/Representative_sequences/otus_per_taxon_summary.txt 2>/dev/null | cut -f2`
echo "<table class=\"center\" border=1>
<tr><td> Total OTU count </td><td align=center> $Total_OTUs </td></tr>
<tr><td> Total L7 taxa count </td><td align=center> $Total_taxa </td></tr>
<tr><td> Mean OTUs per L7 taxon </td><td align=center> $Mean_OTUs </td></tr>
<tr><td> Median OTUs per L7 taxon </td><td align=center> $Median_OTUs </td></tr>
<tr><td> Maximum OTUs per L7 taxon </td><td align=center> $Max_OTUs </td></tr>
<tr><td> Minimum OTUs per L7 taxon </td><td align=center> $Min_OTUs </td></tr>
<tr><td> Aligned and unaligned sequences </td><td> <a href=\"./Representative_sequences/sequences_by_taxonomy.html\" target=\"_blank\"> sequences_by_taxonomy.html </a></td></tr>
</table>" > $anchor03temp
	fi

	## Find anchor in template and send data
	linenum=`sed -n "/anchor03/=" $outdir/index.html`
	sed -i "${linenum}r $anchor03temp" $outdir/index.html

## Build anchor04temp (normalized taxa plots)


## Build anchor06temp (normalized beta diversity)
## Normalized beta diversity results
	if [[ -d $outdir/Normalized_output/beta_diversity ]]; then
echo "<table class=\"center\" border=1>" > $anchor06temp
echo "<tr><td> Anosim results (normalized) </td><td> <a href=\"./Normalized_output/beta_diversity/anosim_results_collated.txt\" target=\"_blank\"> anosim_results_collated.txt -- NORMALIZED DATA </a></td></tr>
<tr><td> Adonis results (normalized) </td><td> <a href=\"./Normalized_output/beta_diversity/adonis_results_collated.txt\" target=\"_blank\"> adonis_results_collated.txt -- NORMALIZED DATA </a></td></tr>
<tr><td> DB-RDA results (normalized) </td><td> <a href=\"./Normalized_output/beta_diversity/dbrda_results_collated.txt\" target=\"_blank\"> dbrda_results_collated.txt -- NORMALIZED DATA </a></td></tr>
<tr><td> Permanova results (normalized) </td><td> <a href=\"./Normalized_output/beta_diversity/permanova_results_collated.txt\" target=\"_blank\"> permanova_results_collated.txt -- NORMALIZED DATA </a></td></tr>
<tr><td> Permdisp results (normalized) </td><td> <a href=\"./Normalized_output/beta_diversity/permdisp_results_collated.txt\" target=\"_blank\"> permdisp_results_collated.txt -- NORMALIZED DATA </a></td></tr>" >> $anchor06temp
	for dm in $outdir/Normalized_output/beta_diversity/*_dm.txt; do
	dmbase=`basename $dm _dm.txt`
	for line in `cat $catlist`; do
echo "<tr><td> Distance boxplots (${line}, ${dmbase}) </td><td> <a href=\"./Normalized_output/beta_diversity/${dmbase}_boxplots/${line}_Distances.pdf\" target=\"_blank\"> ${line}_Distances.pdf </a></td></tr>
<tr><td> Distance boxplots statistics (${line}, ${dmbase}) </td><td> <a href=\"./Normalized_output/beta_diversity/${dmbase}_boxplots/${line}_Stats.txt\" target=\"_blank\"> ${line}_Stats.txt </a></td></tr>" >> $anchor06temp

	done
	nmsstress=`grep -e "^stress\s" $outdir/Normalized_output/beta_diversity/${dmbase}_nmds.txt 2>/dev/null || true | cut -f2`
echo "<tr><td> 3D PCoA plot (${dmbase}) </td><td> <a href=\"./Normalized_output/beta_diversity/${dmbase}_emperor_pcoa_plot/index.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> 2D PCoA plot (${dmbase}) </td><td> <a href=\"./Normalized_output/beta_diversity/2D_bdiv_plots/${dmbase}_pc_2D_PCoA_plots.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> 3D NMDS plot (${dmbase}, $nmsstress) </td><td> <a href=\"./Normalized_output/beta_diversity/${dmbase}_emperor_nmds_plot/index.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> DB-RDA plot (${dmbase}) </td><td> <a href=\"./Normalized_output/beta_diversity/dbrda_out/\" target=\"_blank\"> dbrda_plot_directory </a></td></tr>" >> $anchor06temp
echo "<tr><td> Distance matrix (${dmbase}) </td><td> <a href=\"./Normalized_output/beta_diversity/${dmbase}_dm.txt\" target=\"_blank\"> ${dmbase}_dm.txt </a></td></tr>
<tr><td> Principal coordinate matrix (${dmbase}) </td><td> <a href=\"./Normalized_output/beta_diversity/${dmbase}_pc.txt\" target=\"_blank\"> ${dmbase}_pc.txt </a></td></tr>
<tr><td> NMDS coordinates (${dmbase}) </td><td> <a href=\"./Normalized_output/beta_diversity/${dmbase}_nmds.txt\" target=\"_blank\"> ${dmbase}_nmds.txt </a></td></tr>" >> $anchor06temp
	done
	fi
echo "</table>" >> $anchor06temp

	## Find anchor in template and send data
	linenum=`sed -n "/anchor06/=" $outdir/index.html`
	sed -i "${linenum}r $anchor06temp" $outdir/index.html


## Build anchor07temp (normalized group significance)


## Build anchor08temp (normalized rank abundance)


## Build anchor09temp (normalized supervised learning)


## Build anchor10temp (normalized biplots)


## Build anchor11temp (rarefied taxa plots)


## Build anchor12temp (rarefied alpha diversity)


## Build anchor13temp (rarefied beta diversity)


## Build anchor14temp (rarefied group significance)


## Build anchor15temp (rarefied rank abundance)


## Build anchor16temp (rarefied supervised learning)


## Build anchor17temp (rarefied biplots)


## Build anchor18temp (unaligned sequences)


## Build anchor19temp (aligned sequences)



exit 0

## Make html files
	##sequences and alignments html

	if [[ -d $outdir/Representative_sequences ]]; then
echo "<html>
<head><title>QIIME results - sequences</title></head>
<body>
<p><h2> akutils core diversity workflow for normalized and non-normalized OTU tables </h2><p>
<a href=\"https://github.com/alk224/akutils\" target=\_blank\"><h2> https://github.com/alk224/akutils </h2></a><p>
<table border=1>
<p><h3> Sequences by taxonomy </h3><p>
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Unaligned sequences </td></tr>" > $outdir/Representative_sequences/sequences_by_taxonomy.html

	for taxonid in `cat $outdir/Representative_sequences/L7_taxa_list.txt 2>/dev/null | cut -f1`; do
	otu_count=`grep -Fw "$taxonid" $outdir/Representative_sequences/L7_taxa_list.txt 2>/dev/null | cut -f2`

	if [[ -f $outdir/Representative_sequences/L7_sequences_by_taxon/${taxonid}.fasta ]]; then
echo "<tr><td><font size="1"><a href=\"./L7_sequences_by_taxon/${taxonid}.fasta\" target=\"_blank\"> ${taxonid} </a></font></td><td> $otu_count OTUs </td></tr>" >> $outdir/Representative_sequences/sequences_by_taxonomy.html
	fi
	done

echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Aligned sequences (MAFFT L-INS-i) </td></tr>" >> $outdir/Representative_sequences/sequences_by_taxonomy.html

	for taxonid in `cat $outdir/Representative_sequences/L7_taxa_list.txt 2>/dev/null | cut -f1`; do
	otu_count=`grep -Fw "$taxonid" $outdir/Representative_sequences/L7_taxa_list.txt 2>/dev/null | cut -f2`

	if [[ -f $outdir/Representative_sequences/L7_sequences_by_taxon_alignments/${taxonid}/${taxonid}_aligned.aln ]]; then
echo "<tr><td><font size="1"><a href=\"./L7_sequences_by_taxon_alignments/${taxonid}/${taxonid}_aligned.aln\" target=\"_blank\"> ${taxonid} </a></font></td><td> $otu_count OTUs </td></tr>" >> $outdir/Representative_sequences/sequences_by_taxonomy.html
	fi
	done

	fi



## Taxa plots by sample
	if [[ -d $outdir/taxa_plots ]]; then
echo "
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Taxonomic Summary Results (by sample) </td></tr>
<tr><td> Taxa summary bar plots </td><td> <a href=\"./taxa_plots/taxa_summary_plots/bar_charts.html\" target=\"_blank\"> bar_charts.html </a></td></tr>" >> $outdir/index.html
	fi

## Taxa plots by category
	for line in `cat $catlist`; do
	if [[ -d $outdir/taxa_plots_${line} ]]; then
echo "
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Taxonomic summary results (by $line) </td></tr>
<tr><td> Taxa summary bar plots </td><td> <a href=\"./taxa_plots_$line/taxa_summary_plots/bar_charts.html\" target=\"_blank\"> bar_charts.html </a></td></tr>
<tr><td> Taxa summary pie plots </td><td> <a href=\"./taxa_plots_$line/taxa_summary_plots/pie_charts.html\" target=\"_blank\"> pie_charts.html </a></td></tr>" >> $outdir/index.html
	fi
	done

## Kruskal-Wallis results
	if [[ -d $outdir/KruskalWallis ]]; then
echo "
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Group Significance Results (Kruskal-Wallis - nonparametric ANOVA) <br><br> All mean values are percent of total counts by sample (relative OTU abundances) </td></tr>" >> $outdir/index.html

	for line in `cat $catlist`; do
	if [[ -f $outdir/KruskalWallis/kruskalwallis_${line}_OTU.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - OTU level </td><td> <a href=\"./KruskalWallis/kruskalwallis_${line}_OTU.txt\" target=\"_blank\"> kruskalwallis_${line}_OTU.txt </a></td></tr>" >> $outdir/index.html
	fi
	done

	for line in `cat $catlist`; do
	if [[ -f $outdir/KruskalWallis/kruskalwallis_${line}_L7.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - species level (L7) </td><td> <a href=\"./KruskalWallis/kruskalwallis_${line}_L7.txt\" target=\"_blank\"> kruskalwallis_${line}_L7.txt </a></td></tr>" >> $outdir/index.html
	fi
	done

	for line in `cat $catlist`; do
	if [[ -f $outdir/KruskalWallis/kruskalwallis_${line}_L6.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - genus level (L6) </td><td> <a href=\"./KruskalWallis/kruskalwallis_${line}_L6.txt\" target=\"_blank\"> kruskalwallis_${line}_L6.txt </a></td></tr>" >> $outdir/index.html
	fi
	done

	for line in `cat $catlist`; do
	if [[ -f $outdir/KruskalWallis/kruskalwallis_${line}_L5.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - family level (L5) </td><td> <a href=\"./KruskalWallis/kruskalwallis_${line}_L5.txt\" target=\"_blank\"> kruskalwallis_${line}_L5.txt </a></td></tr>" >> $outdir/index.html
	fi
	done

	for line in `cat $catlist`; do
	if [[ -f $outdir/KruskalWallis/kruskalwallis_${line}_L4.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - order level (L4) </td><td> <a href=\"./KruskalWallis/kruskalwallis_${line}_L4.txt\" target=\"_blank\"> kruskalwallis_${line}_L4.txt </a></td></tr>" >> $outdir/index.html
	fi
	done

	for line in `cat $catlist`; do
	if [[ -f $outdir/KruskalWallis/kruskalwallis_${line}_L3.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - class level (L3) </td><td> <a href=\"./KruskalWallis/kruskalwallis_${line}_L3.txt\" target=\"_blank\"> kruskalwallis_${line}_L3.txt </a></td></tr>" >> $outdir/index.html
	fi
	done

	for line in `cat $catlist`; do
	if [[ -f $outdir/KruskalWallis/kruskalwallis_${line}_L2.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - phylum level (L2) </td><td> <a href=\"./KruskalWallis/kruskalwallis_${line}_L2.txt\" target=\"_blank\"> kruskalwallis_${line}_L2.txt </a></td></tr>" >> $outdir/index.html
	fi
	done
	fi

## Nonparametric T-test results
	if [[ -d $outdir/Nonparametric_ttest ]]; then
echo "
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Group Significance Results (Nonparametric T-test, 1000 permutations) <br><br> Results only generated when comparing two groups <br><br> All mean values are percent of total counts by sample (relative OTU abundances) </td></tr>" >> $outdir/index.html

	for line in `cat $catlist`; do
	if [[ -f $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_OTU.txt ]]; then
echo "<tr><td> Nonparametric T-test results - ${line} - OTU level </td><td> <a href=\"./Nonparametric_ttest/nonparametric_ttest_${line}_OTU.txt\" target=\"_blank\"> nonparametric_ttest_${line}_OTU.txt </a></td></tr>" >> $outdir/index.html
	fi
	done

	for line in `cat $catlist`; do
	if [[ -f $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L7.txt ]]; then
echo "<tr><td> Nonparametric T-test results - ${line} - species level (L7) </td><td> <a href=\"./Nonparametric_ttest/nonparametric_ttest_${line}_L7.txt\" target=\"_blank\"> nonparametric_ttest_${line}_L7.txt </a></td></tr>" >> $outdir/index.html
	fi
	done

	for line in `cat $catlist`; do
	if [[ -f $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L6.txt ]]; then
echo "<tr><td> Nonparametric T-test results - ${line} - genus level (L6) </td><td> <a href=\"./Nonparametric_ttest/nonparametric_ttest_${line}_L6.txt\" target=\"_blank\"> nonparametric_ttest_${line}_L6.txt </a></td></tr>" >> $outdir/index.html
	fi
	done

	for line in `cat $catlist`; do
	if [[ -f $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L5.txt ]]; then
echo "<tr><td> Nonparametric T-test results - ${line} - family level (L5) </td><td> <a href=\"./Nonparametric_ttest/nonparametric_ttest_${line}_L5.txt\" target=\"_blank\"> nonparametric_ttest_${line}_L5.txt </a></td></tr>" >> $outdir/index.html
	fi
	done

	for line in `cat $catlist`; do
	if [[ -f $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L4.txt ]]; then
echo "<tr><td> Nonparametric T-test results - ${line} - order level (L4) </td><td> <a href=\"./Nonparametric_ttest/nonparametric_ttest_${line}_L4.txt\" target=\"_blank\"> nonparametric_ttest_${line}_L4.txt </a></td></tr>" >> $outdir/index.html
	fi
	done

	for line in `cat $catlist`; do
	if [[ -f $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L3.txt ]]; then
echo "<tr><td> Nonparametric T-test results - ${line} - class level (L3) </td><td> <a href=\"./Nonparametric_ttest/nonparametric_ttest_${line}_L3.txt\" target=\"_blank\"> nonparametric_ttest_${line}_L3.txt </a></td></tr>" >> $outdir/index.html
	fi
	done

	for line in `cat $catlist`; do
	if [[ -f $outdir/Nonparametric_ttest/nonparametric_ttest_${line}_L2.txt ]]; then
echo "<tr><td> Nonparametric T-test results - ${line} - phylum level (L2) </td><td> <a href=\"./Nonparametric_ttest/nonparametric_ttest_${line}_L2.txt\" target=\"_blank\"> nonparametric_ttest_${line}_L2.txt </a></td></tr>" >> $outdir/index.html
	fi
	done
	fi

## Alpha diversity results
	if [[ -d $outdir/arare_max${depth} ]]; then
echo "
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Alpha Diversity Results </td></tr>
<tr><td> Alpha rarefaction plots </td><td> <a href=\"./arare_max$depth/alpha_rarefaction_plots/rarefaction_plots.html\" target=\"_blank\"> rarefaction_plots.html </a></td></tr>" >> $outdir/index.html

	for category in `cat $catlist`; do
	for metric in `cat $alphatemp`; do
echo "<tr><td> Alpha diversity statistics ($category, $metric, parametric) </td><td> <a href=\"./arare_max$depth/compare_${metric}_parametric/${category}_stats.txt\" target=\"_blank\"> ${category}_stats.txt </a></td></tr>
<tr><td> Alpha diversity boxplots ($category, $metric, parametric) </td><td> <a href=\"./arare_max$depth/compare_${metric}_parametric/${category}_boxplots.pdf\" target=\"_blank\"> ${category}_boxplots.pdf </a></td></tr>
<tr><td> Alpha diversity statistics ($category, $metric, nonparametric) </td><td> <a href=\"./arare_max$depth/compare_${metric}_nonparametric/${category}_stats.txt\" target=\"_blank\"> ${category}_stats.txt </a></td></tr>
<tr><td> Alpha diversity boxplots ($category, $metric, nonparametric) </td><td> <a href=\"./arare_max$depth/compare_${metric}_nonparametric/${category}_boxplots.pdf\" target=\"_blank\"> ${category}_boxplots.pdf </a></td></tr>" >> $outdir/index.html
	done
	done
	fi

## Normalized beta diversity results
	if [[ -d $outdir/bdiv_normalized ]]; then
echo "
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Beta Diversity Results -- NORMALIZED DATA </td></tr>
<tr><td> Anosim results (normalized) </td><td> <a href=\"./bdiv_normalized/anosim_results_collated.txt\" target=\"_blank\"> anosim_results_collated.txt -- NORMALIZED DATA </a></td></tr>
<tr><td> Adonis results (normalized) </td><td> <a href=\"./bdiv_normalized/adonis_results_collated.txt\" target=\"_blank\"> adonis_results_collated.txt -- NORMALIZED DATA </a></td></tr>
<tr><td> DB-RDA results (normalized) </td><td> <a href=\"./bdiv_normalized/dbrda_results_collated.txt\" target=\"_blank\"> dbrda_results_collated.txt -- NORMALIZED DATA </a></td></tr>
<tr><td> Permanova results (normalized) </td><td> <a href=\"./bdiv_normalized/permanova_results_collated.txt\" target=\"_blank\"> permanova_results_collated.txt -- NORMALIZED DATA </a></td></tr>
<tr><td> Permdisp results (normalized) </td><td> <a href=\"./bdiv_normalized/permdisp_results_collated.txt\" target=\"_blank\"> permdisp_results_collated.txt -- NORMALIZED DATA </a></td></tr>" >> $outdir/index.html

	for dm in $outdir/bdiv_normalized/*_dm.txt; do
	dmbase=`basename $dm _dm.txt`
	for line in `cat $catlist`; do

echo "<tr><td> Distance boxplots (${line}, ${dmbase}) </td><td> <a href=\"./bdiv_normalized/${dmbase}_boxplots/${line}_Distances.pdf\" target=\"_blank\"> ${line}_Distances.pdf </a></td></tr>
<tr><td> Distance boxplots statistics (${line}, ${dmbase}) </td><td> <a href=\"./bdiv_normalized/${dmbase}_boxplots/${line}_Stats.txt\" target=\"_blank\"> ${line}_Stats.txt </a></td></tr>" >> $outdir/index.html

	done

	nmsstress=`grep -e "^stress\s" $outdir/bdiv_normalized/${dmbase}_nmds.txt 2>/dev/null || true | cut -f2`

echo "<tr><td> 3D PCoA plot (${dmbase}) </td><td> <a href=\"./bdiv_normalized/${dmbase}_emperor_pcoa_plot/index.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> 2D PCoA plot (${dmbase}) </td><td> <a href=\"./bdiv_normalized/2D_bdiv_plots/${dmbase}_pc_2D_PCoA_plots.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> 3D NMDS plot (${dmbase}, $nmsstress) </td><td> <a href=\"./bdiv_normalized/${dmbase}_emperor_nmds_plot/index.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> DB-RDA plot (${dmbase}) </td><td> <a href=\"./bdiv_normalized/dbrda_out/\" target=\"_blank\"> dbrda_plot.pdf </a></td></tr>" >> $outdir/index.html
echo "<tr><td> Distance matrix (${dmbase}) </td><td> <a href=\"./bdiv_normalized/${dmbase}_dm.txt\" target=\"_blank\"> ${dmbase}_dm.txt </a></td></tr>
<tr><td> Principal coordinate matrix (${dmbase}) </td><td> <a href=\"./bdiv_normalized/${dmbase}_pc.txt\" target=\"_blank\"> ${dmbase}_pc.txt </a></td></tr>
<tr><td> NMDS coordinates (${dmbase}) </td><td> <a href=\"./bdiv_normalized/${dmbase}_nmds.txt\" target=\"_blank\"> ${dmbase}_nmds.txt </a></td></tr>" >> $outdir/index.html

	done

	fi

## Rarefied beta diversity results
	if [[ -d $outdir/bdiv_rarefied ]]; then
echo "
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Beta Diversity Results -- RAREFIED DATA </td></tr>
<tr><td> Anosim results (rarefied) </td><td> <a href=\"./bdiv_rarefied/anosim_results_collated.txt\" target=\"_blank\"> anosim_results_collated.txt -- RAREFIED DATA </a></td></tr>
<tr><td> Adonis results (rarefied) </td><td> <a href=\"./bdiv_rarefied/adonis_results_collated.txt\" target=\"_blank\"> adonis_results_collated.txt -- RAREFIED DATA </a></td></tr>
<tr><td> DB-RDA results (rarefied) </td><td> <a href=\"./bdiv_rarefied/dbrda_results_collated.txt\" target=\"_blank\"> dbrda_results_collated.txt -- RAREFIED DATA </a></td></tr>
<tr><td> Permanova results (rarefied) </td><td> <a href=\"./bdiv_rarefied/permanova_results_collated.txt\" target=\"_blank\"> permanova_results_collated.txt -- RAREFIED DATA </a></td></tr>
<tr><td> Permdisp results (rarefied) </td><td> <a href=\"./bdiv_rarefied/permdisp_results_collated.txt\" target=\"_blank\"> permdisp_results_collated.txt -- RAREFIED DATA </a></td></tr>" >> $outdir/index.html

	for dm in $outdir/bdiv_rarefied/*_dm.txt; do
	dmbase=`basename $dm _dm.txt`
	for line in `cat $catlist`; do

echo "<tr><td> Distance boxplots (${dmbase}) </td><td> <a href=\"./bdiv_rarefied/${dmbase}_boxplots/${line}_Distances.pdf\" target=\"_blank\"> ${line}_Distances.pdf </a></td></tr>
<tr><td> Distance boxplots statistics (${dmbase}) </td><td> <a href=\"./bdiv_rarefied/${dmbase}_boxplots/${line}_Stats.txt\" target=\"_blank\"> ${line}_Stats.txt </a></td></tr>" >> $outdir/index.html

	done

	nmsstress=`grep -e "^stress\s" $outdir/bdiv_rarefied/${dmbase}_nmds.txt 2>/dev/null | cut -f2` || true

echo "<tr><td> 3D PCoA plot (${dmbase}) </td><td> <a href=\"./bdiv_rarefied/${dmbase}_emperor_pcoa_plot/index.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> 2D PCoA plot (${dmbase}) </td><td> <a href=\"./bdiv_rarefied/2D_PCoA_bdiv_plots/${dmbase}_pc_2D_PCoA_plots.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> 3D NMDS plot (${dmbase}, $nmsstress) </td><td> <a href=\"./bdiv_rarefied/${dmbase}_emperor_nmds_plot/index.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> DB-RDA plot (${dmbase}) </td><td> <a href=\"./bdiv_rarefied/dbrda_out/\" target=\"_blank\"> dbrda_plot.pdf </a></td></tr>" >> $outdir/index.html
echo "<tr><td> Distance matrix (${dmbase}) </td><td> <a href=\"./bdiv_rarefied/${dmbase}_dm.txt\" target=\"_blank\"> ${dmbase}_dm.txt </a></td></tr>
<tr><td> Principal coordinate matrix (${dmbase}) </td><td> <a href=\"./bdiv_rarefied/${dmbase}_pc.txt\" target=\"_blank\"> ${dmbase}_pc.txt </a></td></tr>
<tr><td> NMDS coordinates (${dmbase}) </td><td> <a href=\"./bdiv_rarefied/${dmbase}_nmds.txt\" target=\"_blank\"> ${dmbase}_nmds.txt </a></td></tr>" >> $outdir/index.html

	done
	fi

## Rank abundance plots (normalized)
	if [[ -d $outdir/bdiv_normalized/RankAbundance ]]; then
echo "
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Rank Abundance Plots (relative abundances) -- NORMALIZED DATA </td></tr> 
<tr><td> Rank abundance (xlog-ylog) </td><td> <a href=\"./bdiv_normalized/RankAbundance/rankabund_xlog-ylog.pdf\" target=\"_blank\"> rankabund_xlog-ylog.pdf </a></td></tr>
<tr><td> Rank abundance (xlinear-ylog) </td><td> <a href=\"./bdiv_normalized/RankAbundance/rankabund_xlinear-ylog.pdf\" target=\"_blank\"> rankabund_xlinear-ylog.pdf </a></td></tr>
<tr><td> Rank abundance (xlog-ylinear) </td><td> <a href=\"./bdiv_normalized/RankAbundance/rankabund_xlog-ylinear.pdf\" target=\"_blank\"> rankabund_xlog-ylinear.pdf </a></td></tr>
<tr><td> Rank abundance (xlinear-ylinear) </td><td> <a href=\"./bdiv_normalized/RankAbundance/rankabund_xlinear-ylinear.pdf\" target=\"_blank\"> rankabund_xlinear-ylinear.pdf </a></td></tr>" >> $outdir/index.html
	fi

## Rank abundance plots (rarefied)
	if [[ -d $outdir/bdiv_rarefied/RankAbundance ]]; then
echo "
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Rank Abundance Plots (relative abundances) -- RAREFIED DATA </td></tr> 
<tr><td> Rank abundance (xlog-ylog) </td><td> <a href=\"./bdiv_rarefied/RankAbundance/rankabund_xlog-ylog.pdf\" target=\"_blank\"> rankabund_xlog-ylog.pdf </a></td></tr>
<tr><td> Rank abundance (xlinear-ylog) </td><td> <a href=\"./bdiv_rarefied/RankAbundance/rankabund_xlinear-ylog.pdf\" target=\"_blank\"> rankabund_xlinear-ylog.pdf </a></td></tr>
<tr><td> Rank abundance (xlog-ylinear) </td><td> <a href=\"./bdiv_rarefied/RankAbundance/rankabund_xlog-ylinear.pdf\" target=\"_blank\"> rankabund_xlog-ylinear.pdf </a></td></tr>
<tr><td> Rank abundance (xlinear-ylinear) </td><td> <a href=\"./bdiv_rarefied/RankAbundance/rankabund_xlinear-ylinear.pdf\" target=\"_blank\"> rankabund_xlinear-ylinear.pdf </a></td></tr>" >> $outdir/index.html
	fi

## Supervised learning (normalized)
	if [[ -d $outdir/bdiv_normalized/SupervisedLearning ]]; then
echo "
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Supervised Learning (out of bag) -- NORMALIZED DATA </td></tr>" >> $outdir/index.html
	for category in `cat $catlist`; do
echo "<tr><td> Summary (${category}) </td><td> <a href=\"./bdiv_normalized/SupervisedLearning/${category}/summary.txt\" target=\"_blank\"> summary.txt </a></td></tr>
<tr><td> Mislabeling (${category}) </td><td> <a href=\"./bdiv_normalized/SupervisedLearning/${category}/mislabeling.txt\" target=\"_blank\"> mislabeling.txt </a></td></tr>
<tr><td> Confusion Matrix (${category}) </td><td> <a href=\"./bdiv_normalized/SupervisedLearning/${category}/confusion_matrix.txt\" target=\"_blank\"> confusion_matrix.txt </a></td></tr>
<tr><td> CV Probabilities (${category}) </td><td> <a href=\"./bdiv_normalized/SupervisedLearning/${category}/cv_probabilities.txt\" target=\"_blank\"> cv_probabilities.txt </a></td></tr>
<tr><td> Feature Importance Scores (${category}) </td><td> <a href=\"./bdiv_normalized/SupervisedLearning/${category}/feature_importance_scores.txt\" target=\"_blank\"> feature_importance_scores.txt </a></td></tr>" >> $outdir/index.html
	done
	fi

## Supervised learning (rarefied)
	if [[ -d $outdir/bdiv_rarefied/SupervisedLearning ]]; then
echo "
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Supervised Learning (out of bag) -- RAREFIED DATA </td></tr>" >> $outdir/index.html
	for category in `cat $catlist`; do
echo "<tr><td> Summary (${category}) </td><td> <a href=\"./bdiv_rarefied/SupervisedLearning/${category}/summary.txt\" target=\"_blank\"> summary.txt </a></td></tr>
<tr><td> Mislabeling (${category}) </td><td> <a href=\"./bdiv_rarefied/SupervisedLearning/${category}/mislabeling.txt\" target=\"_blank\"> mislabeling.txt </a></td></tr>
<tr><td> Confusion Matrix (${category}) </td><td> <a href=\"./bdiv_rarefied/SupervisedLearning/${category}/confusion_matrix.txt\" target=\"_blank\"> confusion_matrix.txt </a></td></tr>
<tr><td> CV Probabilities (${category}) </td><td> <a href=\"./bdiv_rarefied/SupervisedLearning/${category}/cv_probabilities.txt\" target=\"_blank\"> cv_probabilities.txt </a></td></tr>
<tr><td> Feature Importance Scores (${category}) </td><td> <a href=\"./bdiv_rarefied/SupervisedLearning/${category}/feature_importance_scores.txt\" target=\"_blank\"> feature_importance_scores.txt </a></td></tr>" >> $outdir/index.html
	done
	fi

## Biplots (normalized)
	if [[ -d $outdir/bdiv_normalized/biplots ]]; then
echo "
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Biplots -- NORMALIZED DATA </td></tr>" >> $outdir/index.html

	for dm in $outdir/bdiv_normalized/*_dm.txt; do
	dmbase=`basename $dm _dm.txt`
	for level in $outdir/bdiv_normalized/biplots/${dmbase}/CSS_table_sorted_*/; do
	lev=`basename $level`
	Lev=`echo $lev | sed 's/CSS_table_sorted_//'`
	Level=`echo $Lev | sed 's/L/Level /'`

echo "<tr><td> PCoA biplot, ${Level} (${dmbase}) </td><td> <a href=\"./bdiv_normalized/biplots/${dmbase}/${lev}/index.html\" target=\"_blank\"> index.html </a></td></tr>" >> $outdir/index.html

	done
	done
	fi

## Biplots (rarefied)
	if [[ -d $outdir/bdiv_rarefied/biplots ]]; then
echo "
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Biplots -- RAREFIED DATA </td></tr>" >> $outdir/index.html

	for dm in $outdir/bdiv_rarefied/*_dm.txt; do
	dmbase=`basename $dm _dm.txt`
	for level in $outdir/bdiv_rarefied/biplots/$dmbase/rarefied_table_sorted_*/; do
	lev=`basename $level`
	Lev=`echo $lev | sed 's/rarefied_table_sorted_//'`
	Level=`echo $Lev | sed 's/L/Level /'`

echo "<tr><td> PCoA biplot, ${Level} (${dmbase}) </td><td> <a href=\"./bdiv_rarefied/biplots/${dmbase}/rarefied_table_sorted_${Lev}/index.html\" target=\"_blank\"> index.html </a></td></tr>" >> $outdir/index.html

	done
	done
	fi

exit 0
