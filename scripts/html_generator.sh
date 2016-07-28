#!/usr/bin/env bash
#
## html_generator.sh - HTML generator for akutils core diversity workflow
#
#  Version 1.2 (July, 27, 2016)
#
#  Copyright (c) 2015-2016 Andrew Krohn
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
if [[ -f $anchor20temp ]]; then
	rm $anchor20temp
fi
if [[ -f $anchor21temp ]]; then
	rm $anchor21temp
fi
if [[ -f $anchor0004temp ]]; then
	rm $anchor0004temp
fi
if [[ -f $anchor0006temp ]]; then
	rm $anchor0006temp
fi
if [[ -f $anchor0007temp ]]; then
	rm $anchor0007temp
fi
if [[ -f $anchor0008temp ]]; then
	rm $anchor0008temp
fi
if [[ -f $anchor0009temp ]]; then
	rm $anchor0009temp
fi
if [[ -f $anchor0010temp ]]; then
	rm $anchor0010temp
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
treebase="$9"

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
anchor20temp="${tempdir}/${randcode}_anchor20.temp"
anchor21temp="${tempdir}/${randcode}_anchor21.temp"
anchor0004temp="${tempdir}/${randcode}_anchor0004.temp"
anchor0006temp="${tempdir}/${randcode}_anchor0006.temp"
anchor0007temp="${tempdir}/${randcode}_anchor0007.temp"
anchor0008temp="${tempdir}/${randcode}_anchor0008.temp"
anchor0009temp="${tempdir}/${randcode}_anchor0009.temp"
anchor0010temp="${tempdir}/${randcode}_anchor0010.temp"

## Copy blank outputs:
	cp $repodir/akutils_resources/html_template/index.html $outdir
	cp -r $repodir/akutils_resources/html_template/.html $outdir
#	if [[ -d $outdir/Representative_sequences ]]; then
#		cp -r $repodir/akutils_resources/html_template/sequences_by_taxonomy.html $outdir/Representative_sequences/
#		cp -r $repodir/akutils_resources/html_template/.html $outdir/Representative_sequences/
#	fi

####################################
## Main html output start here:

## Define log file
log=`ls $outdir/log_core_diversity* 2>/dev/null`
logfile=$(basename $log)

## Set table name
	## Find anchor in template and send table name and rarefaction depth
	sed -i "s/<!--anchor001-->/${inputbase}.biom/" $outdir/index.html 2>/dev/null
	sed -i "s/<!--anchor001a-->/${depth}/" $outdir/index.html 2>/dev/null

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
if [[ -f $outdir/OTU_tables/DESeq2_table.summary ]]; then
echo "<tr><td> DESeq2-normalized OTU table statistics </td><td> <a href=\"./OTU_tables/DESeq2_table.summary\" target=\"_blank\"> DESeq2_table.summary </a></td></tr>" >> $anchor01temp
fi
echo "</table>" >> $anchor01temp

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor01/=" $outdir/index.html)
	sed -i "${linenum}r $anchor01temp" $outdir/index.html

## Build anchor02temp (OTU table links)
	## OTU tables
## Tables used in analysis (biom and .txt versions)
echo "<table class=\"center\" border=1>" > $anchor02temp
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Metadata (input mapping file) </td></tr>" >> $anchor02temp
if [[ -f $outdir/OTU_tables/input_mapping_file.txt ]]; then
echo "<tr><td> Input metadata mapping file </td><td> <a href=\"./OTU_tables/input_mapping_file.txt\" target=\"_blank\"> input_mapping_file.txt </a></td></tr>" >> $anchor02temp
fi
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Input OTU table </td></tr>" >> $anchor02temp
if [[ -f $outdir/OTU_tables/${inputbase}.biom ]]; then
echo "<tr><td> Input OTU table (BIOM format, zero count OTUs removed) </td><td> <a href=\"./OTU_tables/${inputbase}.biom\" target=\"_blank\"> ${inputbase}.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/${inputbase}.txt ]]; then
echo "<tr><td> Input OTU table (tab-delimited format, zero count OTUs removed) </td><td> <a href=\"./OTU_tables/${inputbase}.txt\" target=\"_blank\"> ${inputbase}.txt </a></td></tr>" >> $anchor02temp
fi
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Rarefied OTU tables (depth = ${depth}) </td></tr>" >> $anchor02temp
if [[ -f $outdir/OTU_tables/rarefied_table_sorted.biom ]]; then
echo "<tr><td> Rarefied OTU table (BIOM format) </td><td> <a href=\"./OTU_tables/rarefied_table_sorted.biom\" target=\"_blank\"> rarefied_table_sorted.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/rarefied_table_sorted_with_metadata.biom ]]; then
echo "<tr><td> Rarefied OTU table with metadata (BIOM format) </td><td> <a href=\"./OTU_tables/rarefied_table_sorted_with_metadata.biom\" target=\"_blank\"> rarefied_table_sorted_with_metadata.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/rarefied_table_sorted.txt ]]; then
echo "<tr><td> Rarefied OTU table (tab-delimited format) </td><td> <a href=\"./OTU_tables/rarefied_table_sorted.txt\" target=\"_blank\"> rarefied_table_sorted.txt </a></td></tr>" >> $anchor02temp
fi
#if [[ -f $outdir/OTU_tables/rarefied_table_sorted_with_metadata.txt ]]; then
#echo "<tr><td> Rarefied OTU table with metadata (tab-delimited format) </td><td> <a href=\"./OTU_tables/rarefied_table_sorted_with_metadata.txt\" target=\"_blank\"> rarefied_table_sorted_with_metadata.txt </a></td></tr>" >> $anchor02temp
#fi
if [[ -f $outdir/OTU_tables/rarefied_table_sorted_relativized.biom ]]; then
echo "<tr><td> Rarefied OTU table, relativized (BIOM format) </td><td> <a href=\"./OTU_tables/rarefied_table_sorted_relativized.biom\" target=\"_blank\"> rarefied_table_sorted_relativized.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/rarefied_table_sorted_relativized_with_metadata.biom ]]; then
echo "<tr><td> Rarefied OTU table, relativized with metadata (BIOM format) </td><td> <a href=\"./OTU_tables/rarefied_table_sorted_relativized_with_metadata.biom\" target=\"_blank\"> rarefied_table_sorted_relativized_with_metadata.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/rarefied_table_sorted_relativized.txt ]]; then
echo "<tr><td> Rarefied OTU table, relativized (tab-delimited format) </td><td> <a href=\"./OTU_tables/rarefied_table_sorted_relativized.txt\" target=\"_blank\"> rarefied_table_sorted_relativized.txt </a></td></tr>" >> $anchor02temp
fi
#if [[ -f $outdir/OTU_tables/rarefied_table_sorted_relativized_with_metadata.txt ]]; then
#echo "<tr><td> Rarefied OTU table, relativized with metadata (tab-delimited format) </td><td> <a href=\"./OTU_tables/rarefied_table_sorted_relativized_with_metadata.txt\" target=\"_blank\"> rarefied_table_sorted_relativized_with_metadata.txt </a></td></tr>" >> $anchor02temp
#fi
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Sample-filtered OTU tables (input OTU table filtered for samples removed during rarefaction) </td></tr>" >> $anchor02temp
if [[ -f $outdir/OTU_tables/sample_filtered_table.biom ]]; then
echo "<tr><td> Sample-filtered table (input for normalization, BIOM format) </td><td> <a href=\"./OTU_tables/sample_filtered_table.biom\" target=\"_blank\"> sample_filtered_table.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/sample_filtered_table.txt ]]; then
echo "<tr><td> Sample-filtered table (input for normalization, tab-delimited format) </td><td> <a href=\"./OTU_tables/sample_filtered_table.txt\" target=\"_blank\"> sample_filtered_table.txt </a></td></tr>" >> $anchor02temp
fi
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> CSS-normalized OTU tables (CSS transformation of sample-filtered table) </td></tr>" >> $anchor02temp
if [[ -f $outdir/OTU_tables/CSS_table_sorted.biom ]]; then
echo "<tr><td> CSS-normalized OTU table (BIOM format) </td><td> <a href=\"./OTU_tables/CSS_table_sorted.biom\" target=\"_blank\"> CSS_table_sorted.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/CSS_table_sorted_with_metadata.biom ]]; then
echo "<tr><td> CSS-normalized OTU table with metadata (BIOM format) </td><td> <a href=\"./OTU_tables/CSS_table_sorted_with_metadata.biom\" target=\"_blank\"> CSS_table_sorted_with_metadata.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/CSS_table_sorted.txt ]]; then
echo "<tr><td> CSS-normalized OTU table (tab-delimited format) </td><td> <a href=\"./OTU_tables/CSS_table_sorted.txt\" target=\"_blank\"> CSS_table_sorted.txt </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/CSS_table_sorted_relativized.biom ]]; then
echo "<tr><td> CSS-normalized OTU table, relativized (BIOM format) </td><td> <a href=\"./OTU_tables/CSS_table_sorted_relativized.biom\" target=\"_blank\"> CSS_table_sorted_relativized.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/CSS_table_sorted_relativized_with_metadata.biom ]]; then
echo "<tr><td> CSS-normalized OTU table, relativized with metadata (BIOM format) </td><td> <a href=\"./OTU_tables/CSS_table_sorted_relativized_with_metadata.biom\" target=\"_blank\"> CSS_table_sorted_relativized_with_metadata.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/CSS_table_sorted_relativized.txt ]]; then
echo "<tr><td> CSS-normalized OTU table, relativized (tab-delimited format) </td><td> <a href=\"./OTU_tables/CSS_table_sorted_relativized.txt\" target=\"_blank\"> CSS_table_sorted_relativized.txt </a></td></tr>" >> $anchor02temp
fi
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> DESeq2-normalized OTU tables (DESeq2 transformation of sample-filtered table) </td></tr>" >> $anchor02temp
if [[ -f $outdir/OTU_tables/DESeq2_table_sorted.biom ]]; then
echo "<tr><td> DESeq2-normalized OTU table (BIOM format) </td><td> <a href=\"./OTU_tables/DESeq2_table_sorted.biom\" target=\"_blank\"> DESeq2_table_sorted.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/DESeq2_table_sorted_with_metadata.biom ]]; then
echo "<tr><td> DESeq2-normalized OTU table with metadata (BIOM format) </td><td> <a href=\"./OTU_tables/DESeq2_table_sorted_with_metadata.biom\" target=\"_blank\"> DESeq2_table_sorted_with_metadata.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/DESeq2_table_sorted.txt ]]; then
echo "<tr><td> DESeq2-normalized OTU table (tab-delimited format) </td><td> <a href=\"./OTU_tables/DESeq2_table_sorted.txt\" target=\"_blank\"> DESeq2_table_sorted.txt </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/DESeq2_table_sorted_relativized.biom ]]; then
echo "<tr><td> DESeq2-normalized OTU table, relativized (BIOM format) </td><td> <a href=\"./OTU_tables/DESeq2_table_sorted_relativized.biom\" target=\"_blank\"> DESeq2_table_sorted_relativized.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/DESeq2_table_sorted_relativized_with_metadata.biom ]]; then
echo "<tr><td> DESeq2-normalized OTU table, relativized with metadata (BIOM format) </td><td> <a href=\"./OTU_tables/DESeq2_table_sorted_relativized_with_metadata.biom\" target=\"_blank\"> DESeq2_table_sorted_relativized_with_metadata.biom </a></td></tr>" >> $anchor02temp
fi
if [[ -f $outdir/OTU_tables/DESeq2_table_sorted_relativized.txt ]]; then
echo "<tr><td> DESeq2-normalized OTU table, relativized (tab-delimited format) </td><td> <a href=\"./OTU_tables/DESeq2_table_sorted_relativized.txt\" target=\"_blank\"> DESeq2_table_sorted_relativized.txt </a></td></tr>" >> $anchor02temp
fi

echo "</table>" >> $anchor02temp

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor02/=" $outdir/index.html)
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
</table>" > $anchor03temp
#<tr><td> Aligned and unaligned sequences </td><td> <a href=\"./Representative_sequences/sequences_by_taxonomy.html\" target=\"_blank\"> sequences_by_taxonomy.html </a></td></tr>
#</table>" > $anchor03temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor03/=" $outdir/index.html)
	sed -i "${linenum}r $anchor03temp" $outdir/index.html

## Build anchor20temp (phylogenetic tree data)
	if [[ -d $outdir/Phyloseq_output/Trees ]]; then
echo "<table class=\"center\" border=1>" > $anchor20temp
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Phylogenetic tree colored by Phylum <br><br> Bootstrap values at sample nodes, OTU names at tips </td></tr>" >> $anchor20temp
echo "<tr><td> Phylogenetic tree (colored by phylum) </td><td> <a href=\"./Phyloseq_output/Trees/Phylum_tree.pdf\" target=\"_blank\"> Phylum_tree.pdf </a></td></tr>" >> $anchor20temp
echo "<tr><td> Input tree (Newick format) </td><td> <a href=\"./Phyloseq_output/Trees/${treebase}\" target=\"_blank\"> ${treebase} </a></td></tr>" >> $anchor20temp
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Phylogenetic trees colored by category, size by abundance (normalized counts) <br><br> Bootstrap values at sample nodes, species names at tips </td></tr>" >> $anchor20temp
	for line in `cat $catlist`; do
echo "<tr><td> Phylogenetic tree (colored by ${line}) </td><td> <a href=\"./Phyloseq_output/Trees/${line}_detail_tree.pdf\" target=\"_blank\"> ${line}_detail_tree.pdf </a></td></tr>" >> $anchor20temp
	done
echo "</table>" >> $anchor20temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor20/=" $outdir/index.html)
	sed -i "${linenum}r $anchor20temp" $outdir/index.html

## Build anchor21temp (network plots)
	if [[ -d $outdir/Phyloseq_output/Networks ]]; then
echo "<table class=\"center\" border=1>" > $anchor21temp
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Network plots by category <br><br> Networks based on Bray-Curtis dissimilarity with 90% maximum distance </td></tr>" >> $anchor21temp
	for line in `cat $catlist`; do
echo "<tr><td> Network plot (colored by ${line}) </td><td> <a href=\"./Phyloseq_output/Networks/${line}_network.pdf\" target=\"_blank\"> ${line}_network.pdf </a></td></tr>" >> $anchor21temp
	done
echo "</table>" >> $anchor21temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor21/=" $outdir/index.html)
	sed -i "${linenum}r $anchor21temp" $outdir/index.html

## Build anchor04temp (CSS normalized taxa plots)
## Taxa plots by sample
	if [[ -d $outdir/CSS_normalized_output/taxa_plots ]]; then
echo "<table class=\"center\" border=1>" > $anchor04temp
echo "<tr><td> Taxa summary bar plots (by sample) </td><td> <a href=\"./CSS_normalized_output/taxa_plots/taxa_summary_plots/bar_charts.html\" target=\"_blank\"> bar_charts.html </a></td></tr>" >> $anchor04temp

## Taxa plots by category
	for line in `cat $catlist`; do
	if [[ -d $outdir/CSS_normalized_output/taxa_plots_${line} ]]; then
echo "<tr><td> Taxa summary bar plots (${line}) </td><td> <a href=\"./CSS_normalized_output/taxa_plots_${line}/taxa_summary_plots/bar_charts.html\" target=\"_blank\"> bar_charts.html </a></td></tr>
<tr><td> Taxa summary pie plots (${line}) </td><td> <a href=\"./CSS_normalized_output/taxa_plots_$line/taxa_summary_plots/pie_charts.html\" target=\"_blank\"> pie_charts.html </a></td></tr>" >> $anchor04temp
	fi
	done
echo "</table>" >> $anchor04temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor04/=" $outdir/index.html)
	sed -i "${linenum}r $anchor04temp" $outdir/index.html

## Build anchor06temp (CSS normalized beta diversity)
## CSS normalized beta diversity results
	if [[ -d $outdir/CSS_normalized_output/beta_diversity ]]; then
echo "<table class=\"center\" border=1>" > $anchor06temp
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Beta diversity comparisons (CSS normalized) </td></tr>
<tr><td> Anosim results (CSS normalized) </td><td> <a href=\"./CSS_normalized_output/beta_diversity/anosim_results_collated.txt\" target=\"_blank\"> anosim_results_collated.txt -- CSS NORMALIZED DATA </a></td></tr>
<tr><td> Adonis results (CSS normalized) </td><td> <a href=\"./CSS_normalized_output/beta_diversity/adonis_results_collated.txt\" target=\"_blank\"> adonis_results_collated.txt -- CSS NORMALIZED DATA </a></td></tr>
<tr><td> DB-RDA results (CSS normalized) </td><td> <a href=\"./CSS_normalized_output/beta_diversity/dbrda_results_collated.txt\" target=\"_blank\"> dbrda_results_collated.txt -- CSS NORMALIZED DATA </a></td></tr>
<tr><td> Permanova results (CSS normalized) </td><td> <a href=\"./CSS_normalized_output/beta_diversity/permanova_results_collated.txt\" target=\"_blank\"> permanova_results_collated.txt -- CSS NORMALIZED DATA </a></td></tr>
<tr><td> Permdisp results (CSS normalized) </td><td> <a href=\"./CSS_normalized_output/beta_diversity/permdisp_results_collated.txt\" target=\"_blank\"> permdisp_results_collated.txt -- CSS NORMALIZED DATA </a></td></tr>" >> $anchor06temp
	for dm in $outdir/CSS_normalized_output/beta_diversity/*_dm.txt; do
	dmbase=`basename $dm _dm.txt`
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> ${dmbase} </td></tr>" >> $anchor06temp
	for line in `cat $catlist`; do
echo "<tr><td> Distance boxplots (${line}, ${dmbase}) </td><td> <a href=\"./CSS_normalized_output/beta_diversity/${dmbase}_boxplots/${line}_Distances.pdf\" target=\"_blank\"> ${line}_Distances.pdf </a></td></tr>
<tr><td> Distance boxplots statistics (${line}, ${dmbase}) </td><td> <a href=\"./CSS_normalized_output/beta_diversity/${dmbase}_boxplots/${line}_Stats.txt\" target=\"_blank\"> ${line}_Stats.txt </a></td></tr>" >> $anchor06temp

	done
	nmsstress=`grep -e "^stress\s" $outdir/CSS_normalized_output/beta_diversity/${dmbase}_nmds.txt 2>/dev/null || true | cut -f2`
echo "<tr><td> 3D PCoA plot (${dmbase}) </td><td> <a href=\"./CSS_normalized_output/beta_diversity/${dmbase}_emperor_pcoa_plot/index.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> 2D PCoA plot (${dmbase}) </td><td> <a href=\"./CSS_normalized_output/beta_diversity/2D_PCoA_bdiv_plots/${dmbase}_pc_2D_PCoA_plots.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> 3D NMDS plot (${dmbase}, $nmsstress) </td><td> <a href=\"./CSS_normalized_output/beta_diversity/${dmbase}_emperor_nmds_plot/index.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> DB-RDA plot (${dmbase}) </td><td> <a href=\"./CSS_normalized_output/beta_diversity/dbrda_out/\" target=\"_blank\"> dbrda_plot_directory </a></td></tr>" >> $anchor06temp
echo "<tr><td> Distance matrix (${dmbase}) </td><td> <a href=\"./CSS_normalized_output/beta_diversity/${dmbase}_dm.txt\" target=\"_blank\"> ${dmbase}_dm.txt </a></td></tr>
<tr><td> Principal coordinate matrix (${dmbase}) </td><td> <a href=\"./CSS_normalized_output/beta_diversity/${dmbase}_pc.txt\" target=\"_blank\"> ${dmbase}_pc.txt </a></td></tr>
<tr><td> NMDS coordinates (${dmbase}) </td><td> <a href=\"./CSS_normalized_output/beta_diversity/${dmbase}_nmds.txt\" target=\"_blank\"> ${dmbase}_nmds.txt </a></td></tr>" >> $anchor06temp
	done
	fi
echo "</table>" >> $anchor06temp

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor06/=" $outdir/index.html)
	sed -i "${linenum}r $anchor06temp" $outdir/index.html

## Build anchor07temp (CSS normalized group significance)
## Kruskal-Wallis results
	if [[ -d $outdir/CSS_normalized_output/KruskalWallis ]]; then
echo "<table class=\"center\" border=1>" > $anchor07temp
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Group Significance Results (Kruskal-Wallis - nonparametric ANOVA) <br><br> All mean values are percent of total counts by sample (relative OTU abundances) </td></tr>" >> $anchor07temp
	for line in `cat $catlist`; do
	if [[ -f $outdir/CSS_normalized_output/KruskalWallis/kruskalwallis_${line}_OTU.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - OTU level </td><td> <a href=\"./CSS_normalized_output/KruskalWallis/kruskalwallis_${line}_OTU.txt\" target=\"_blank\"> kruskalwallis_${line}_OTU.txt </a></td></tr>" >> $anchor07temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/CSS_normalized_output/KruskalWallis/kruskalwallis_${line}_L7.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - species level (L7) </td><td> <a href=\"./CSS_normalized_output/KruskalWallis/kruskalwallis_${line}_L7.txt\" target=\"_blank\"> kruskalwallis_${line}_L7.txt </a></td></tr>" >> $anchor07temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/CSS_normalized_output/KruskalWallis/kruskalwallis_${line}_L6.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - genus level (L6) </td><td> <a href=\"./CSS_normalized_output/KruskalWallis/kruskalwallis_${line}_L6.txt\" target=\"_blank\"> kruskalwallis_${line}_L6.txt </a></td></tr>" >> $anchor07temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/CSS_normalized_output/KruskalWallis/kruskalwallis_${line}_L5.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - family level (L5) </td><td> <a href=\"./CSS_normalized_output/KruskalWallis/kruskalwallis_${line}_L5.txt\" target=\"_blank\"> kruskalwallis_${line}_L5.txt </a></td></tr>" >> $anchor07temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/CSS_normalized_output/KruskalWallis/kruskalwallis_${line}_L4.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - order level (L4) </td><td> <a href=\"./CSS_normalized_output/KruskalWallis/kruskalwallis_${line}_L4.txt\" target=\"_blank\"> kruskalwallis_${line}_L4.txt </a></td></tr>" >> $anchor07temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/CSS_normalized_output/KruskalWallis/kruskalwallis_${line}_L3.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - class level (L3) </td><td> <a href=\"./CSS_normalized_output/KruskalWallis/kruskalwallis_${line}_L3.txt\" target=\"_blank\"> kruskalwallis_${line}_L3.txt </a></td></tr>" >> $anchor07temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/Normalized_output/KruskalWallis/kruskalwallis_${line}_L2.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - phylum level (L2) </td><td> <a href=\"./Normalized_output/KruskalWallis/kruskalwallis_${line}_L2.txt\" target=\"_blank\"> kruskalwallis_${line}_L2.txt </a></td></tr>" >> $anchor07temp
	fi
	done
echo "</table>" >> $anchor07temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor07/=" $outdir/index.html)
	sed -i "${linenum}r $anchor07temp" $outdir/index.html

## Build anchor08temp (CSS normalized rank abundance)
	if [[ -d $outdir/CSS_normalized_output/RankAbundance ]]; then
echo "<table class=\"center\" border=1>" > $anchor08temp
echo "
<tr><td> Rank abundance (xlog-ylog) </td><td> <a href=\"./CSS_normalized_output/RankAbundance/rankabund_xlog-ylog.pdf\" target=\"_blank\"> rankabund_xlog-ylog.pdf </a></td></tr>
<tr><td> Rank abundance (xlinear-ylog) </td><td> <a href=\"./CSS_normalized_output/RankAbundance/rankabund_xlinear-ylog.pdf\" target=\"_blank\"> rankabund_xlinear-ylog.pdf </a></td></tr>
<tr><td> Rank abundance (xlog-ylinear) </td><td> <a href=\"./CSS_normalized_output/RankAbundance/rankabund_xlog-ylinear.pdf\" target=\"_blank\"> rankabund_xlog-ylinear.pdf </a></td></tr>
<tr><td> Rank abundance (xlinear-ylinear) </td><td> <a href=\"./CSS_normalized_output/RankAbundance/rankabund_xlinear-ylinear.pdf\" target=\"_blank\"> rankabund_xlinear-ylinear.pdf </a></td></tr>
</table>" >> $anchor08temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor08/=" $outdir/index.html)
	sed -i "${linenum}r $anchor08temp" $outdir/index.html

## Build anchor09temp (CSS normalized supervised learning)
## Supervised learning (CSS normalized)
	if [[ -d $outdir/CSS_normalized_output/SupervisedLearning ]]; then
echo "<table class=\"center\" border=1>
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Supervised learning results <br><br> Out-of-bag analysis (oob) </td></tr>" > $anchor09temp
	for category in `cat $catlist`; do
echo "<tr><td> Summary (${category}) </td><td> <a href=\"./CSS_normalized_output/SupervisedLearning/${category}/summary.txt\" target=\"_blank\"> summary.txt </a></td></tr>
<tr><td> Mislabeling (${category}) </td><td> <a href=\"./CSS_normalized_output/SupervisedLearning/${category}/mislabeling.txt\" target=\"_blank\"> mislabeling.txt </a></td></tr>
<tr><td> Confusion Matrix (${category}) </td><td> <a href=\"./CSS_normalized_output/SupervisedLearning/${category}/confusion_matrix.txt\" target=\"_blank\"> confusion_matrix.txt </a></td></tr>
<tr><td> CV Probabilities (${category}) </td><td> <a href=\"./CSS_normalized_output/SupervisedLearning/${category}/cv_probabilities.txt\" target=\"_blank\"> cv_probabilities.txt </a></td></tr>
<tr><td> Feature Importance Scores (${category}) </td><td> <a href=\"./CSS_normalized_output/SupervisedLearning/${category}/feature_importance_scores.txt\" target=\"_blank\"> feature_importance_scores.txt </a></td></tr>" >> $anchor09temp
	done
echo "</table>" >> $anchor09temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor09/=" $outdir/index.html)
	sed -i "${linenum}r $anchor09temp" $outdir/index.html

## Build anchor10temp (CSS normalized biplots)
## Biplots (CSS normalized)
	if [[ -d $outdir/CSS_normalized_output/beta_diversity/biplots ]]; then
echo "<table class=\"center\" border=1>
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Biplots -- CSS NORMALIZED DATA </td></tr>" > $anchor10temp

	for dm in $outdir/CSS_normalized_output/beta_diversity/*_dm.txt; do
	dmbase=`basename $dm _dm.txt`
	for level in $outdir/CSS_normalized_output/beta_diversity/biplots/${dmbase}/CSS_table_sorted_*/; do
	lev=`basename $level`
	Lev=`echo $lev | sed 's/CSS_table_sorted_//'`
	Level=`echo $Lev | sed 's/L/Level /'`

echo "<tr><td> PCoA biplot, ${Level} (${dmbase}) </td><td> <a href=\"./CSS_normalized_output/beta_diversity/biplots/${dmbase}/${lev}/index.html\" target=\"_blank\"> index.html </a></td></tr>" >> $anchor10temp

	done
	done
echo "</table>" >> $anchor10temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor10/=" $outdir/index.html)
	sed -i "${linenum}r $anchor10temp" $outdir/index.html

## Build anchor04temp (DESeq2 normalized taxa plots)
## Taxa plots by sample
	if [[ -d $outdir/DESeq2_normalized_output/taxa_plots ]]; then
echo "<table class=\"center\" border=1>" > $anchor0004temp
echo "<tr><td> Taxa summary bar plots (by sample) </td><td> <a href=\"./DESeq2_normalized_output/taxa_plots/taxa_summary_plots/bar_charts.html\" target=\"_blank\"> bar_charts.html </a></td></tr>" >> $anchor0004temp

## Taxa plots by category
	for line in `cat $catlist`; do
	if [[ -d $outdir/DESeq2_normalized_output/taxa_plots_${line} ]]; then
echo "<tr><td> Taxa summary bar plots (${line}) </td><td> <a href=\"./DESeq2_normalized_output/taxa_plots_${line}/taxa_summary_plots/bar_charts.html\" target=\"_blank\"> bar_charts.html </a></td></tr>
<tr><td> Taxa summary pie plots (${line}) </td><td> <a href=\"./DESeq2_normalized_output/taxa_plots_$line/taxa_summary_plots/pie_charts.html\" target=\"_blank\"> pie_charts.html </a></td></tr>" >> $anchor0004temp
	fi
	done
echo "</table>" >> $anchor0004temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor0004/=" $outdir/index.html)
	sed -i "${linenum}r $anchor0004temp" $outdir/index.html

## Build anchor06temp (DESeq2 normalized beta diversity)
## DESeq2 normalized beta diversity results
	if [[ -d $outdir/DESeq2_normalized_output/beta_diversity ]]; then
echo "<table class=\"center\" border=1>" > $anchor0006temp
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Beta diversity comparisons (DESeq2 normalized) </td></tr>
<tr><td> Anosim results (DESeq2 normalized) </td><td> <a href=\"./DESeq2_normalized_output/beta_diversity/anosim_results_collated.txt\" target=\"_blank\"> anosim_results_collated.txt -- DESeq2 NORMALIZED DATA </a></td></tr>
<tr><td> Adonis results (DESeq2 normalized) </td><td> <a href=\"./DESeq2_normalized_output/beta_diversity/adonis_results_collated.txt\" target=\"_blank\"> adonis_results_collated.txt -- DESeq2 NORMALIZED DATA </a></td></tr>
<tr><td> DB-RDA results (DESeq2 normalized) </td><td> <a href=\"./DESeq2_normalized_output/beta_diversity/dbrda_results_collated.txt\" target=\"_blank\"> dbrda_results_collated.txt -- DESeq2 NORMALIZED DATA </a></td></tr>
<tr><td> Permanova results (DESeq2 normalized) </td><td> <a href=\"./DESeq2_normalized_output/beta_diversity/permanova_results_collated.txt\" target=\"_blank\"> permanova_results_collated.txt -- DESeq2 NORMALIZED DATA </a></td></tr>
<tr><td> Permdisp results (DESeq2 normalized) </td><td> <a href=\"./DESeq2_normalized_output/beta_diversity/permdisp_results_collated.txt\" target=\"_blank\"> permdisp_results_collated.txt -- DESeq2 NORMALIZED DATA </a></td></tr>" >> $anchor0006temp
	for dm in $outdir/DESeq2_normalized_output/beta_diversity/*_dm.txt; do
	dmbase=`basename $dm _dm.txt`
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> ${dmbase} </td></tr>" >> $anchor0006temp
	for line in `cat $catlist`; do
echo "<tr><td> Distance boxplots (${line}, ${dmbase}) </td><td> <a href=\"./DESeq2_normalized_output/beta_diversity/${dmbase}_boxplots/${line}_Distances.pdf\" target=\"_blank\"> ${line}_Distances.pdf </a></td></tr>
<tr><td> Distance boxplots statistics (${line}, ${dmbase}) </td><td> <a href=\"./DESeq2_normalized_output/beta_diversity/${dmbase}_boxplots/${line}_Stats.txt\" target=\"_blank\"> ${line}_Stats.txt </a></td></tr>" >> $anchor0006temp

	done
	nmsstress=`grep -e "^stress\s" $outdir/DESeq2_normalized_output/beta_diversity/${dmbase}_nmds.txt 2>/dev/null || true | cut -f2`
echo "<tr><td> 3D PCoA plot (${dmbase}) </td><td> <a href=\"./DESeq2_normalized_output/beta_diversity/${dmbase}_emperor_pcoa_plot/index.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> 2D PCoA plot (${dmbase}) </td><td> <a href=\"./DESeq2_normalized_output/beta_diversity/2D_PCoA_bdiv_plots/${dmbase}_pc_2D_PCoA_plots.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> 3D NMDS plot (${dmbase}, $nmsstress) </td><td> <a href=\"./DESeq2_normalized_output/beta_diversity/${dmbase}_emperor_nmds_plot/index.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> DB-RDA plot (${dmbase}) </td><td> <a href=\"./DESeq2_normalized_output/beta_diversity/dbrda_out/\" target=\"_blank\"> dbrda_plot_directory </a></td></tr>" >> $anchor0006temp
echo "<tr><td> Distance matrix (${dmbase}) </td><td> <a href=\"./DESeq2_normalized_output/beta_diversity/${dmbase}_dm.txt\" target=\"_blank\"> ${dmbase}_dm.txt </a></td></tr>
<tr><td> Principal coordinate matrix (${dmbase}) </td><td> <a href=\"./DESeq2_normalized_output/beta_diversity/${dmbase}_pc.txt\" target=\"_blank\"> ${dmbase}_pc.txt </a></td></tr>
<tr><td> NMDS coordinates (${dmbase}) </td><td> <a href=\"./DESeq2_normalized_output/beta_diversity/${dmbase}_nmds.txt\" target=\"_blank\"> ${dmbase}_nmds.txt </a></td></tr>" >> $anchor0006temp
	done
	fi
echo "</table>" >> $anchor0006temp

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor0006/=" $outdir/index.html)
	sed -i "${linenum}r $anchor0006temp" $outdir/index.html

## Build anchor07temp (DESeq2 normalized group significance)
## Kruskal-Wallis results
	if [[ -d $outdir/DESeq2_normalized_output/KruskalWallis ]]; then
echo "<table class=\"center\" border=1>" > $anchor0007temp
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Group Significance Results (Kruskal-Wallis - nonparametric ANOVA) <br><br> All mean values are percent of total counts by sample (relative OTU abundances) </td></tr>" >> $anchor0007temp
	for line in `cat $catlist`; do
	if [[ -f $outdir/DESeq2_normalized_output/KruskalWallis/kruskalwallis_${line}_OTU.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - OTU level </td><td> <a href=\"./DESeq2_normalized_output/KruskalWallis/kruskalwallis_${line}_OTU.txt\" target=\"_blank\"> kruskalwallis_${line}_OTU.txt </a></td></tr>" >> $anchor0007temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/DESeq2_normalized_output/KruskalWallis/kruskalwallis_${line}_L7.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - species level (L7) </td><td> <a href=\"./DESeq2_normalized_output/KruskalWallis/kruskalwallis_${line}_L7.txt\" target=\"_blank\"> kruskalwallis_${line}_L7.txt </a></td></tr>" >> $anchor0007temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/DESeq2_normalized_output/KruskalWallis/kruskalwallis_${line}_L6.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - genus level (L6) </td><td> <a href=\"./DESeq2_normalized_output/KruskalWallis/kruskalwallis_${line}_L6.txt\" target=\"_blank\"> kruskalwallis_${line}_L6.txt </a></td></tr>" >> $anchor0007temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/DESeq2_normalized_output/KruskalWallis/kruskalwallis_${line}_L5.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - family level (L5) </td><td> <a href=\"./DESeq2_normalized_output/KruskalWallis/kruskalwallis_${line}_L5.txt\" target=\"_blank\"> kruskalwallis_${line}_L5.txt </a></td></tr>" >> $anchor0007temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/DESeq2_normalized_output/KruskalWallis/kruskalwallis_${line}_L4.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - order level (L4) </td><td> <a href=\"./DESeq2_normalized_output/KruskalWallis/kruskalwallis_${line}_L4.txt\" target=\"_blank\"> kruskalwallis_${line}_L4.txt </a></td></tr>" >> $anchor0007temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/DESeq2_normalized_output/KruskalWallis/kruskalwallis_${line}_L3.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - class level (L3) </td><td> <a href=\"./DESeq2_normalized_output/KruskalWallis/kruskalwallis_${line}_L3.txt\" target=\"_blank\"> kruskalwallis_${line}_L3.txt </a></td></tr>" >> $anchor0007temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/Normalized_output/KruskalWallis/kruskalwallis_${line}_L2.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - phylum level (L2) </td><td> <a href=\"./Normalized_output/KruskalWallis/kruskalwallis_${line}_L2.txt\" target=\"_blank\"> kruskalwallis_${line}_L2.txt </a></td></tr>" >> $anchor0007temp
	fi
	done
echo "</table>" >> $anchor0007temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor0007/=" $outdir/index.html)
	sed -i "${linenum}r $anchor0007temp" $outdir/index.html

## Build anchor08temp (DESeq2 normalized rank abundance)
	if [[ -d $outdir/DESeq2_normalized_output/RankAbundance ]]; then
echo "<table class=\"center\" border=1>" > $anchor0008temp
echo "
<tr><td> Rank abundance (xlog-ylog) </td><td> <a href=\"./DESeq2_normalized_output/RankAbundance/rankabund_xlog-ylog.pdf\" target=\"_blank\"> rankabund_xlog-ylog.pdf </a></td></tr>
<tr><td> Rank abundance (xlinear-ylog) </td><td> <a href=\"./DESeq2_normalized_output/RankAbundance/rankabund_xlinear-ylog.pdf\" target=\"_blank\"> rankabund_xlinear-ylog.pdf </a></td></tr>
<tr><td> Rank abundance (xlog-ylinear) </td><td> <a href=\"./DESeq2_normalized_output/RankAbundance/rankabund_xlog-ylinear.pdf\" target=\"_blank\"> rankabund_xlog-ylinear.pdf </a></td></tr>
<tr><td> Rank abundance (xlinear-ylinear) </td><td> <a href=\"./DESeq2_normalized_output/RankAbundance/rankabund_xlinear-ylinear.pdf\" target=\"_blank\"> rankabund_xlinear-ylinear.pdf </a></td></tr>
</table>" >> $anchor0008temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor0008/=" $outdir/index.html)
	sed -i "${linenum}r $anchor0008temp" $outdir/index.html

## Build anchor09temp (DESeq2 normalized supervised learning)
## Supervised learning (DESeq2 normalized)
	if [[ -d $outdir/DESeq2_normalized_output/SupervisedLearning ]]; then
echo "<table class=\"center\" border=1>
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Supervised learning results <br><br> Out-of-bag analysis (oob) </td></tr>" > $anchor0009temp
	for category in `cat $catlist`; do
echo "<tr><td> Summary (${category}) </td><td> <a href=\"./DESeq2_normalized_output/SupervisedLearning/${category}/summary.txt\" target=\"_blank\"> summary.txt </a></td></tr>
<tr><td> Mislabeling (${category}) </td><td> <a href=\"./DESeq2_normalized_output/SupervisedLearning/${category}/mislabeling.txt\" target=\"_blank\"> mislabeling.txt </a></td></tr>
<tr><td> Confusion Matrix (${category}) </td><td> <a href=\"./DESeq2_normalized_output/SupervisedLearning/${category}/confusion_matrix.txt\" target=\"_blank\"> confusion_matrix.txt </a></td></tr>
<tr><td> CV Probabilities (${category}) </td><td> <a href=\"./DESeq2_normalized_output/SupervisedLearning/${category}/cv_probabilities.txt\" target=\"_blank\"> cv_probabilities.txt </a></td></tr>
<tr><td> Feature Importance Scores (${category}) </td><td> <a href=\"./DESeq2_normalized_output/SupervisedLearning/${category}/feature_importance_scores.txt\" target=\"_blank\"> feature_importance_scores.txt </a></td></tr>" >> $anchor0009temp
	done
echo "</table>" >> $anchor0009temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor0009/=" $outdir/index.html)
	sed -i "${linenum}r $anchor0009temp" $outdir/index.html

## Build anchor10temp (DESeq2 normalized biplots)
## Biplots (DESeq2 normalized)
	if [[ -d $outdir/DESeq2_normalized_output/beta_diversity/biplots ]]; then
echo "<table class=\"center\" border=1>
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Biplots -- DESeq2 NORMALIZED DATA </td></tr>" > $anchor0010temp

	for dm in $outdir/DESeq2_normalized_output/beta_diversity/*_dm.txt; do
	dmbase=`basename $dm _dm.txt`
	for level in $outdir/DESeq2_normalized_output/beta_diversity/biplots/${dmbase}/DESeq2_table_sorted_*/; do
	lev=`basename $level`
	Lev=`echo $lev | sed 's/DESeq2_table_sorted_//'`
	Level=`echo $Lev | sed 's/L/Level /'`

echo "<tr><td> PCoA biplot, ${Level} (${dmbase}) </td><td> <a href=\"./DESeq2_normalized_output/beta_diversity/biplots/${dmbase}/${lev}/index.html\" target=\"_blank\"> index.html </a></td></tr>" >> $anchor0010temp

	done
	done
echo "</table>" >> $anchor0010temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor0010/=" $outdir/index.html)
	sed -i "${linenum}r $anchor0010temp" $outdir/index.html

## Build anchor11temp (rarefied taxa plots)
## Taxa plots by sample
	if [[ -d $outdir/Rarefied_output/taxa_plots ]]; then
echo "<table class=\"center\" border=1>" > $anchor11temp
echo "<tr><td> Taxa summary bar plots (by sample) </td><td> <a href=\"./Rarefied_output/taxa_plots/taxa_summary_plots/bar_charts.html\" target=\"_blank\"> bar_charts.html </a></td></tr>" >> $anchor11temp

## Taxa plots by category
	for line in `cat $catlist`; do
	if [[ -d $outdir/Rarefied_output/taxa_plots_${line} ]]; then
echo "<tr><td> Taxa summary bar plots (${line}) </td><td> <a href=\"./Rarefied_output/taxa_plots_${line}/taxa_summary_plots/bar_charts.html\" target=\"_blank\"> bar_charts.html </a></td></tr>
<tr><td> Taxa summary pie plots (${line}) </td><td> <a href=\"./Rarefied_output/taxa_plots_$line/taxa_summary_plots/pie_charts.html\" target=\"_blank\"> pie_charts.html </a></td></tr>" >> $anchor11temp
	fi
	done
echo "</table>" >> $anchor11temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor11/=" $outdir/index.html)
	sed -i "${linenum}r $anchor11temp" $outdir/index.html

## Build anchor12temp (rarefied alpha diversity)
## Alpha diversity results
	if [[ -d $outdir/Alpha_diversity_max${depth} ]]; then
echo "<table class=\"center\" border=1>" > $anchor12temp
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Alpha diversity results <br><br> Rarefaction depth: ${depth} </td></tr>
<tr><td> Alpha rarefaction plots </td><td> <a href=\"./Alpha_diversity_max$depth/alpha_rarefaction_plots/rarefaction_plots.html\" target=\"_blank\"> rarefaction_plots.html </a></td></tr>" >> $anchor12temp

	for category in `cat $catlist`; do
	for metric in `cat $alphatemp`; do
echo "<tr><td> Alpha diversity statistics ($category, $metric, parametric) </td><td> <a href=\"./Alpha_diversity_max$depth/compare_${metric}_parametric/${category}_stats.txt\" target=\"_blank\"> ${category}_stats.txt </a></td></tr>
<tr><td> Alpha diversity boxplots ($category, $metric, parametric) </td><td> <a href=\"./Alpha_diversity_max$depth/compare_${metric}_parametric/${category}_boxplots.pdf\" target=\"_blank\"> ${category}_boxplots.pdf </a></td></tr>
<tr><td> Alpha diversity statistics ($category, $metric, nonparametric) </td><td> <a href=\"./Alpha_diversity_max$depth/compare_${metric}_nonparametric/${category}_stats.txt\" target=\"_blank\"> ${category}_stats.txt </a></td></tr>
<tr><td> Alpha diversity boxplots ($category, $metric, nonparametric) </td><td> <a href=\"./Alpha_diversity_max$depth/compare_${metric}_nonparametric/${category}_boxplots.pdf\" target=\"_blank\"> ${category}_boxplots.pdf </a></td></tr>" >> $anchor12temp
	done
	done
echo "</table>" >> $anchor12temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor12/=" $outdir/index.html)
	sed -i "${linenum}r $anchor12temp" $outdir/index.html

## Build anchor13temp (rarefied beta diversity)
## Rarefied beta diversity results
	if [[ -d $outdir/Rarefied_output/beta_diversity ]]; then
echo "<table class=\"center\" border=1>" > $anchor13temp
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Beta diversity comparisons (rarefied) </td></tr>
<tr><td> Anosim results (rarefied) </td><td> <a href=\"./Rarefied_output/beta_diversity/anosim_results_collated.txt\" target=\"_blank\"> anosim_results_collated.txt -- RAREFIED DATA </a></td></tr>
<tr><td> Adonis results (rarefied) </td><td> <a href=\"./Rarefied_output/beta_diversity/adonis_results_collated.txt\" target=\"_blank\"> adonis_results_collated.txt -- RAREFIED DATA </a></td></tr>
<tr><td> DB-RDA results (rarefied) </td><td> <a href=\"./Rarefied_output/beta_diversity/dbrda_results_collated.txt\" target=\"_blank\"> dbrda_results_collated.txt -- RAREFIED DATA </a></td></tr>
<tr><td> Permanova results (rarefied) </td><td> <a href=\"./Rarefied_output/beta_diversity/permanova_results_collated.txt\" target=\"_blank\"> permanova_results_collated.txt -- RAREFIED DATA </a></td></tr>
<tr><td> Permdisp results (rarefied) </td><td> <a href=\"./Rarefied_output/beta_diversity/permdisp_results_collated.txt\" target=\"_blank\"> permdisp_results_collated.txt -- RAREFIED DATA </a></td></tr>" >> $anchor13temp
	for dm in $outdir/Rarefied_output/beta_diversity/*_dm.txt; do
	dmbase=`basename $dm _dm.txt`
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> ${dmbase} </td></tr>" >> $anchor13temp
	for line in `cat $catlist`; do
echo "<tr><td> Distance boxplots (${dmbase}) </td><td> <a href=\"./Rarefied_output/beta_diversity/${dmbase}_boxplots/${line}_Distances.pdf\" target=\"_blank\"> ${line}_Distances.pdf </a></td></tr>
<tr><td> Distance boxplots statistics (${dmbase}) </td><td> <a href=\"./Rarefied_output/beta_diversity/${dmbase}_boxplots/${line}_Stats.txt\" target=\"_blank\"> ${line}_Stats.txt </a></td></tr>" >> $anchor13temp
	done
	nmsstress=`grep -e "^stress\s" $outdir/Rarefied_output/beta_diversity/${dmbase}_nmds.txt 2>/dev/null | cut -f2` || true
echo "<tr><td> 3D PCoA plot (${dmbase}) </td><td> <a href=\"./Rarefied_output/beta_diversity/${dmbase}_emperor_pcoa_plot/index.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> 2D PCoA plot (${dmbase}) </td><td> <a href=\"./Rarefied_output/beta_diversity/2D_PCoA_bdiv_plots/${dmbase}_pc_2D_PCoA_plots.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> 3D NMDS plot (${dmbase}, $nmsstress) </td><td> <a href=\"./Rarefied_output/beta_diversity/${dmbase}_emperor_nmds_plot/index.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> DB-RDA plot (${dmbase}) </td><td> <a href=\"./Rarefied_output/beta_diversity/dbrda_out/\" target=\"_blank\"> dbrda_plot.pdf </a></td></tr>" >> $anchor13temp
echo "<tr><td> Distance matrix (${dmbase}) </td><td> <a href=\"./Rarefied_output/beta_diversity/${dmbase}_dm.txt\" target=\"_blank\"> ${dmbase}_dm.txt </a></td></tr>
<tr><td> Principal coordinate matrix (${dmbase}) </td><td> <a href=\"./Rarefied_output/beta_diversity/${dmbase}_pc.txt\" target=\"_blank\"> ${dmbase}_pc.txt </a></td></tr>
<tr><td> NMDS coordinates (${dmbase}) </td><td> <a href=\"./Rarefied_output/beta_diversity/${dmbase}_nmds.txt\" target=\"_blank\"> ${dmbase}_nmds.txt </a></td></tr>" >> $anchor13temp
	done
echo "</table>" >> $anchor13temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor13/=" $outdir/index.html)
	sed -i "${linenum}r $anchor13temp" $outdir/index.html

## Build anchor14temp (rarefied group significance)
## Kruskal-Wallis results
	if [[ -d $outdir/Rarefied_output/KruskalWallis ]]; then
echo "<table class=\"center\" border=1>" > $anchor14temp
echo "<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Group Significance Results (Kruskal-Wallis - nonparametric ANOVA) <br><br> All mean values are percent of total counts by sample (relative OTU abundances) </td></tr>" >> $anchor14temp
	for line in `cat $catlist`; do
	if [[ -f $outdir/Rarefied_output/KruskalWallis/kruskalwallis_${line}_OTU.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - OTU level </td><td> <a href=\"./Rarefied_output/KruskalWallis/kruskalwallis_${line}_OTU.txt\" target=\"_blank\"> kruskalwallis_${line}_OTU.txt </a></td></tr>" >> $anchor14temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/Rarefied_output/KruskalWallis/kruskalwallis_${line}_L7.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - species level (L7) </td><td> <a href=\"./Rarefied_output/KruskalWallis/kruskalwallis_${line}_L7.txt\" target=\"_blank\"> kruskalwallis_${line}_L7.txt </a></td></tr>" >> $anchor14temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/Rarefied_output/KruskalWallis/kruskalwallis_${line}_L6.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - genus level (L6) </td><td> <a href=\"./Rarefied_output/KruskalWallis/kruskalwallis_${line}_L6.txt\" target=\"_blank\"> kruskalwallis_${line}_L6.txt </a></td></tr>" >> $anchor14temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/Rarefied_output/KruskalWallis/kruskalwallis_${line}_L5.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - family level (L5) </td><td> <a href=\"./Rarefied_output/KruskalWallis/kruskalwallis_${line}_L5.txt\" target=\"_blank\"> kruskalwallis_${line}_L5.txt </a></td></tr>" >> $anchor14temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/Rarefied_output/KruskalWallis/kruskalwallis_${line}_L4.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - order level (L4) </td><td> <a href=\"./Rarefied_output/KruskalWallis/kruskalwallis_${line}_L4.txt\" target=\"_blank\"> kruskalwallis_${line}_L4.txt </a></td></tr>" >> $anchor14temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/Rarefied_output/KruskalWallis/kruskalwallis_${line}_L3.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - class level (L3) </td><td> <a href=\"./Rarefied_output/KruskalWallis/kruskalwallis_${line}_L3.txt\" target=\"_blank\"> kruskalwallis_${line}_L3.txt </a></td></tr>" >> $anchor14temp
	fi
	done
	for line in `cat $catlist`; do
	if [[ -f $outdir/Rarefied_output/KruskalWallis/kruskalwallis_${line}_L2.txt ]]; then
echo "<tr><td> Kruskal-Wallis results - ${line} - phylum level (L2) </td><td> <a href=\"./Rarefied_output/KruskalWallis/kruskalwallis_${line}_L2.txt\" target=\"_blank\"> kruskalwallis_${line}_L2.txt </a></td></tr>" >> $anchor14temp
	fi
	done
echo "</table>" >> $anchor14temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor14/=" $outdir/index.html)
	sed -i "${linenum}r $anchor14temp" $outdir/index.html

## Build anchor15temp (rarefied rank abundance)
## Rank abundance plots (rarefied)
	if [[ -d $outdir/Rarefied_output/RankAbundance ]]; then
echo "<table class=\"center\" border=1>" > $anchor15temp
echo "<tr><td> Rank abundance (xlog-ylog) </td><td> <a href=\"./Rarefied_output/RankAbundance/rankabund_xlog-ylog.pdf\" target=\"_blank\"> rankabund_xlog-ylog.pdf </a></td></tr>
<tr><td> Rank abundance (xlinear-ylog) </td><td> <a href=\"./Rarefied_output/RankAbundance/rankabund_xlinear-ylog.pdf\" target=\"_blank\"> rankabund_xlinear-ylog.pdf </a></td></tr>
<tr><td> Rank abundance (xlog-ylinear) </td><td> <a href=\"./Rarefied_output/RankAbundance/rankabund_xlog-ylinear.pdf\" target=\"_blank\"> rankabund_xlog-ylinear.pdf </a></td></tr>
<tr><td> Rank abundance (xlinear-ylinear) </td><td> <a href=\"./Rarefied_output/RankAbundance/rankabund_xlinear-ylinear.pdf\" target=\"_blank\"> rankabund_xlinear-ylinear.pdf </a></td></tr>
</table>" >> $anchor15temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor15/=" $outdir/index.html)
	sed -i "${linenum}r $anchor15temp" $outdir/index.html

## Build anchor16temp (rarefied supervised learning)
## Supervised learning (rarefied)
	if [[ -d $outdir/Rarefied_output/SupervisedLearning ]]; then
echo "<table class=\"center\" border=1>
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Supervised learning results <br><br> Out-of-bag analysis (oob) </td></tr>" > $anchor16temp
	for category in `cat $catlist`; do
echo "<tr><td> Summary (${category}) </td><td> <a href=\"./Rarefied_output/SupervisedLearning/${category}/summary.txt\" target=\"_blank\"> summary.txt </a></td></tr>
<tr><td> Mislabeling (${category}) </td><td> <a href=\"./Rarefied_output/SupervisedLearning/${category}/mislabeling.txt\" target=\"_blank\"> mislabeling.txt </a></td></tr>
<tr><td> Confusion Matrix (${category}) </td><td> <a href=\"./Rarefied_output/SupervisedLearning/${category}/confusion_matrix.txt\" target=\"_blank\"> confusion_matrix.txt </a></td></tr>
<tr><td> CV Probabilities (${category}) </td><td> <a href=\"./Rarefied_output/SupervisedLearning/${category}/cv_probabilities.txt\" target=\"_blank\"> cv_probabilities.txt </a></td></tr>
<tr><td> Feature Importance Scores (${category}) </td><td> <a href=\"./Rarefied_output/SupervisedLearning/${category}/feature_importance_scores.txt\" target=\"_blank\"> feature_importance_scores.txt </a></td></tr>" >> $anchor16temp
	done
echo "</table>" >> $anchor16temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor16/=" $outdir/index.html)
	sed -i "${linenum}r $anchor16temp" $outdir/index.html

## Build anchor17temp (rarefied biplots)
## Biplots (rarefied)
	if [[ -d $outdir/Rarefied_output/beta_diversity/biplots ]]; then
echo "<table class=\"center\" border=1>
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Biplots -- RAREFIED DATA </td></tr>" >> $anchor17temp

	for dm in $outdir/Rarefied_output/beta_diversity/*_dm.txt; do
	dmbase=`basename $dm _dm.txt`
	for level in $outdir/Rarefied_output/beta_diversity/biplots/$dmbase/rarefied_table_sorted_*/; do
	lev=`basename $level`
	Lev=`echo $lev | sed 's/rarefied_table_sorted_//'`
	Level=`echo $Lev | sed 's/L/Level /'`

echo "<tr><td> PCoA biplot, ${Level} (${dmbase}) </td><td> <a href=\"./Rarefied_output/beta_diversity/biplots/${dmbase}/rarefied_table_sorted_${Lev}/index.html\" target=\"_blank\"> index.html </a></td></tr>" >> $anchor17temp

	done
	done
echo "</table>" >> $anchor17temp
	fi

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor17/=" $outdir/index.html)
	sed -i "${linenum}r $anchor17temp" $outdir/index.html


	if [[ -d $outdir/Representative_sequences ]]; then
## Build anchor18temp (unaligned sequences)
echo "<table class=\"center\" border=1>" > $anchor18temp

	for taxonid in `cat $outdir/Representative_sequences/L7_taxa_list.txt 2>/dev/null | cut -f1`; do
	otu_count=`grep -Fw "$taxonid" $outdir/Representative_sequences/L7_taxa_list.txt 2>/dev/null | cut -f2`

	if [[ -f $outdir/Representative_sequences/L7_sequences_by_taxon/${taxonid}.fasta ]]; then
echo "<tr><td><font size="1"><a href=\"./Representative_sequences/L7_sequences_by_taxon/${taxonid}.fasta\" target=\"_blank\"> ${taxonid} </a></font></td><td> $otu_count OTUs </td></tr>" >> $anchor18temp
	fi
	done

echo "</table>" >> $anchor18temp

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor18/=" $outdir/index.html)
	sed -i "${linenum}r $anchor18temp" $outdir/index.html

## Build anchor19temp (aligned sequences)
echo "<table class=\"center\" border=1>" > $anchor19temp

	for taxonid in `cat $outdir/Representative_sequences/L7_taxa_list.txt 2>/dev/null | cut -f1`; do
	otu_count=`grep -Fw "$taxonid" $outdir/Representative_sequences/L7_taxa_list.txt 2>/dev/null | cut -f2`

	if [[ -f $outdir/Representative_sequences/L7_sequences_by_taxon_alignments/${taxonid}/${taxonid}_aligned.aln ]]; then
echo "<tr><td><font size="1"><a href=\"./Representative_sequences/L7_sequences_by_taxon_alignments/${taxonid}/${taxonid}_aligned.aln\" target=\"_blank\"> ${taxonid} </a></font></td><td> $otu_count OTUs </td></tr>" >> $anchor19temp
	fi
	done

echo "</table>" >> $anchor19temp

	## Find anchor in template and send data
	linenum=$(sed -n "/anchor19/=" $outdir/index.html)
	sed -i "${linenum}r $anchor19temp" $outdir/index.html

	fi

exit 0

###########################
## Unused code below here

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

exit 0
