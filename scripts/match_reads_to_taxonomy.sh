#!/usr/bin/env bash
#
#  match_reads_to_taxonomy.sh - Count the number of OTUs per species-level taxon and inspect sequencing reads
#
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
#set -e
scriptdir="$( cd "$( dirname "$0" )" && pwd )"
table1="$1"
tablename=$(basename $table1 .biom)
fullpath=`readlink -f $table1`
OTUdir=$(dirname $fullpath)
outdir=$(dirname "$OTUdir")
threads="$2"
rep_set="$3"

## convert rarefied OTU table to .txt
if [[ ! -f $outdir/OTU_tables/$tablename.txt ]]; then
	biomtotxt.sh $1 &>/dev/null
fi
table=$outdir/OTU_tables/$tablename.txt

## get column from OTU table that contains the taxonomy string
taxa_column=`awk -v outdir="$outdir" -v table="$table" '{ for(i=1;i<=NF;i++){if ($i ~ /taxonomy/) {print i}}}' $table`
alt_taxa_column=`expr $taxa_column - 1`

## sort OTU table by taxonomy
if [[ ! -f $outdir/OTU_tables/${tablename}_sorted_by_taxonomy.txt ]]; then
	head -2 $outdir/OTU_tables/$tablename.txt | tail -1 > $outdir/OTU_tables/${tablename}_sorted_by_taxonomy.txt
	tail -n +3 $outdir/OTU_tables/$tablename.txt | sort -k$taxa_column >> $outdir/OTU_tables/${tablename}_sorted_by_taxonomy.txt
fi

## make list of OTUs from sorted table
if [[ ! -f $outdir/OTU_tables/${tablename}_sorted_by_taxonomy_otu_list.txt ]]; then
	grep -v "#" $outdir/OTU_tables/${tablename}_sorted_by_taxonomy.txt | cut -f1 > $outdir/OTU_tables/${tablename}_sorted_by_taxonomy_otu_list.txt
fi

## Build sequence file, adding taxonomy string to fasta header
for otuid in `cat $outdir/OTU_tables/${tablename}_sorted_by_taxonomy_otu_list.txt`; do 
	grep -A 1 -e ">$otuid\s" $rep_set >> $outdir/Representative_sequences/${tablename}_rep_sequences.fasta
	sed -i "/^>$otuid\s/ s/$otuid\s/$otuid\t/" $outdir/Representative_sequences/${tablename}_rep_sequences.fasta
	otuid_tax_string0=`grep -e "$otuid\s" $outdir/OTU_tables/${tablename}_sorted_by_taxonomy.txt | cut -f$alt_taxa_column`
	otuid_tax_string1=`echo $otuid_tax_string0 | sed "s/; /__/g"`
	otuid_tax_string=`echo $otuid_tax_string1 | sed "s/ /_/g"`
	sed -i "/^>$otuid\t/ s/$/\t$otuid_tax_string/" $outdir/Representative_sequences/${tablename}_rep_sequences.fasta
done

## strip out characters that are stupidly used in greengenes strings
sed -i -e "s/\[//g" -e "s/\]//g" -e "s/'//g" $outdir/Representative_sequences/${tablename}_rep_sequences.fasta

## Build taxonomy list from L7 table and L7 table with matching taxonomy strings
cp $outdir/Rarefied_output/beta_diversity/summarized_tables/rarefied_table_sorted_L7.txt $outdir/Representative_sequences/L7_table0.txt
grep "#OTU ID" $outdir/Representative_sequences/L7_table0.txt > $outdir/Representative_sequences/L7_table.txt
grep -v "#" $outdir/Representative_sequences/L7_table0.txt | sed "s/;/__/g" | sed "s/ /_/g" >> $outdir/Representative_sequences/L7_table.txt
rm $outdir/Representative_sequences/L7_table0.txt
grep -v "#" $outdir/Representative_sequences/L7_table.txt | cut -f1 | sed "s/;/__/g" | sed "s/ /_/g" > $outdir/Representative_sequences/L7_taxa_list.txt

## strip out annoying characters found in greengenes tax strings
sed -i -e "s/\[//g" -e "s/\]//g" -e "s/'//g" $outdir/Representative_sequences/L7_taxa_list.txt

## remove "__Other" string from less confident tax assignments in taxa list for searching purposes
sed -i "s/__Other.*//" $outdir/Representative_sequences/L7_taxa_list.txt

## Add number of OTUs to second column of taxa list
for taxid in `cat $outdir/Representative_sequences/L7_taxa_list.txt`; do
	num_otus=`grep -Fwc "$taxid" $outdir/Representative_sequences/${tablename}_rep_sequences.fasta`
	#echo $num_otus
	sed -i "/${taxid}$/ s/$/\t${num_otus}/" $outdir/Representative_sequences/L7_taxa_list.txt
done

## Build taxon-specific multi-fasta files
mkdir -p $outdir/Representative_sequences/L7_sequences_by_taxon
for taxid in `cat $outdir/Representative_sequences/L7_taxa_list.txt | cut -f1`; do

	grep -A 1 -w "$taxid" $outdir/Representative_sequences/${tablename}_rep_sequences.fasta > $outdir/Representative_sequences/L7_sequences_by_taxon/$taxid.fasta
done

## Mafft alignments for taxa with multiple reads per OTU -- copy single representative reads
mkdir -p $outdir/Representative_sequences/L7_sequences_by_taxon_alignments
for taxid in `cat $outdir/Representative_sequences/L7_taxa_list.txt | cut -f1`; do
	otu_count=`grep -w "$taxid" $outdir/Representative_sequences/L7_taxa_list.txt | cut -f2`
	if [[ $otu_count -le 1 ]]; then
	mkdir $outdir/Representative_sequences/L7_sequences_by_taxon_alignments/$taxid
	cp $outdir/Representative_sequences/L7_sequences_by_taxon/$taxid.fasta $outdir/Representative_sequences/L7_sequences_by_taxon_alignments/$taxid/${taxid}_aligned.fasta
	echo "
Single representative sequence for this taxon.  Skipping alignment.
	" > $outdir/Representative_sequences/L7_sequences_by_taxon_alignments/$taxid/${taxid}_log.txt
	elif [[ $otu_count -ge 2 ]]; then
	mkdir $outdir/Representative_sequences/L7_sequences_by_taxon_alignments/$taxid
	mafft --localpair --maxiterate 1000 --quiet --nuc --reorder --treeout --clustalout --thread $threads $outdir/Representative_sequences/L7_sequences_by_taxon/$taxid.fasta > $outdir/Representative_sequences/L7_sequences_by_taxon_alignments/$taxid/${taxid}_aligned.aln
	fi
done

## Generate summary stats
	if [[ ! -f $outdir/Representative_sequences/otus_per_taxon_summary.txt ]]; then
		workdir=$(pwd)
		cd $outdir/Representative_sequences/
		Rscript $scriptdir/otu_summary_stats.r $outdir/Representative_sequences/L7_taxa_list.txt
		cd $workdir
	fi

exit 0
