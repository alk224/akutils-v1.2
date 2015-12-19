#!/usr/bin/env bash
#
## html_generator.sh - HTML generator for akutils core diversity workflow

inputbase="$1"
outdir="$2"
depth="$3"
catlist="$4"
alphatemp="$5"

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

################################################################################
## Master HTML output below here

## Page header and log file
log=`ls $outdir/log_core_diversity*`
logfile=$(basename $log)

echo "<html>
<head><title>QIIME results</title></head>
<body>
<a href=\"http://www.qiime.org\" target=\"_blank\"><img src=\"http://qiime.org/_static/wordpressheader.png\" alt=\"www.qiime.org\"\"/></a><p>
<h1> akutils core diversity workflow </h1><p>
<a href=\"https://github.com/alk224/akutils\" target=\_blank\"><h2> https://github.com/alk224/akutils </h2></a><p>
<table border=1>
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Run Summary Data </td></tr>
<tr><td> Master run log </td><td> <a href=\" ./$logfile \" target=\"_blank\"> $logfile </a></td></tr>" > $outdir/index.html

## Biom summary files
if [[ -f $outdir/OTU_tables/${inputbase}.summary ]]; then
echo "<tr><td> Input BIOM table statistics </td><td> <a href=\"./OTU_tables/${inputbase}.summary\" target=\"_blank\"> ${inputbase}.summary </a></td></tr>" >> $outdir/index.html
fi
if [[ -f $outdir/OTU_tables/table_even${depth}.summary ]]; then
echo "<tr><td> Rarefied BIOM table statistics (depth = $depth) </td><td> <a href=\"./OTU_tables/table_even${depth}.summary\" target=\"_blank\"> table_even${depth}.summary </a></td></tr>" >> $outdir/index.html
fi
if [[ -f $outdir/OTU_tables/sample_filtered_table.summary ]]; then
echo "<tr><td> Sample-filtered BIOM table statistics </td><td> <a href=\"./OTU_tables/sample_filtered_table.summary\" target=\"_blank\"> sample_filtered_table.summary </a></td></tr>" >> $outdir/index.html
fi
if [[ -f $outdir/OTU_tables/CSS_table.summary ]]; then
echo "<tr><td> CSS-normalized BIOM table statistics </td><td> <a href=\"./OTU_tables/CSS_table.summary\" target=\"_blank\"> CSS_table.summary </a></td></tr>" >> $outdir/index.html
fi

## Representative sequences summary and link
	if [[ -f $outdir/Representative_sequences/L7_taxa_list.txt ]] && [[ -f $outdir/Representative_sequences/otus_per_taxon_summary.txt ]]; then
#	tablename=`basename $table .biom`
	Total_OTUs=`cat $outdir/OTU_tables/$inputbase.txt | grep -v "#" | wc -l`
	Total_taxa=`cat $outdir/Representative_sequences/L7_taxa_list.txt | wc -l`
	Mean_OTUs=`grep mean $outdir/Representative_sequences/otus_per_taxon_summary.txt | cut -f2`
	Median_OTUs=`grep median $outdir/Representative_sequences/otus_per_taxon_summary.txt | cut -f2`
	Max_OTUs=`grep max $outdir/Representative_sequences/otus_per_taxon_summary.txt | cut -f2`
	Min_OTUs=`grep min $outdir/Representative_sequences/otus_per_taxon_summary.txt | cut -f2`
echo "
<tr colspan=2 align=center bgcolor=#e8e8e8><td colspan=2 align=center> Sequencing data by L7 taxon </td></tr>
<tr><td> Total OTU count </td><td align=center> $Total_OTUs </td></tr>
<tr><td> Total L7 taxa count </td><td align=center> $Total_taxa </td></tr>
<tr><td> Mean OTUs per L7 taxon </td><td align=center> $Mean_OTUs </td></tr>
<tr><td> Median OTUs per L7 taxon </td><td align=center> $Median_OTUs </td></tr>
<tr><td> Maximum OTUs per L7 taxon </td><td align=center> $Max_OTUs </td></tr>
<tr><td> Minimum OTUs per L7 taxon </td><td align=center> $Min_OTUs </td></tr>
<tr><td> Aligned and unaligned sequences </td><td> <a href=\"./Representative_sequences/sequences_by_taxonomy.html\" target=\"_blank\"> sequences_by_taxonomy.html </a></td></tr>" >> $outdir/index.html
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

echo "<tr><td> Distance boxplots (${dmbase}) </td><td> <a href=\"./bdiv_normalized/${dmbase}_boxplots/${line}_Distances.pdf\" target=\"_blank\"> ${line}_Distances.pdf </a></td></tr>
<tr><td> Distance boxplots statistics (${dmbase}) </td><td> <a href=\"./bdiv_normalized/${dmbase}_boxplots/${line}_Stats.txt\" target=\"_blank\"> ${line}_Stats.txt </a></td></tr>" >> $outdir/index.html

	done

	nmsstress=`grep -e "^stress\s" $outdir/bdiv_normalized/${dmbase}_nmds.txt 2>/dev/null || true | cut -f2`

echo "<tr><td> 3D PCoA plot (${dmbase}) </td><td> <a href=\"./bdiv_normalized/${dmbase}_emperor_pcoa_plot/index.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> 2D PCoA plot (${dmbase}) </td><td> <a href=\"./bdiv_normalized/2D_bdiv_plots/${dmbase}_pc_2D_PCoA_plots.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> 3D NMDS plot (${dmbase}, $nmsstress) </td><td> <a href=\"./bdiv_normalized/${dmbase}_emperor_nmds_plot/index.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> DB-RDA plot (${dmbase}) </td><td> <a href=\"./bdiv_normalized/dbrda_out/${line}/${dmbase}/dbrda_plot.pdf\" target=\"_blank\"> dbrda_plot.pdf </a></td></tr>" >> $outdir/index.html
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

	nmsstress=`grep -e "^stress\s" $outdir/bdiv_rarefied/${dmbase}_nmds.txt | cut -f2` 2>/dev/null || true

echo "<tr><td> 3D PCoA plot (${dmbase}) </td><td> <a href=\"./bdiv_rarefied/${dmbase}_emperor_pcoa_plot/index.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> 2D PCoA plot (${dmbase}) </td><td> <a href=\"./bdiv_rarefied/2D_PCoA_bdiv_plots/${dmbase}_pc_2D_PCoA_plots.html\" target=\"_blank\"> index.html </a></td></tr>
<tr><td> 3D NMDS plot (${dmbase}, $nmsstress) </td><td> <a href=\"./bdiv_rarefied/${dmbase}_emperor_nmds_plot/index.html\" target=\"_blank\"> index.html </a></td></tr>" >> $outdir/index.html
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
