#!/bin/bash

set -e

#collect input from user

echo "******************************************************************"
echo ""
echo "This will help you summarize a raw otu table and filter the output"
echo ""
echo "******************************************************************"
echo ""

echo "Enter your otu table to be summarized:"
read -e rawtable
echo ""

echo "Enter your desired path and name for the summarized otu table:"
read -e sumtable
echo ""

echo "Enter your mapping file containing a category to sumamrize by:"
read -e mapfile
echo ""

echo "Enter the category to summarize by:"
read -e sumcategory
echo ""

echo "Enter the desired path and name for 0.005% otu table output:"
read -e fivetable
echo ""

echo "Enter the desired path and name for 1% otu table output:"
read -e onetable
echo ""

echo "******************************************************************"
echo ""
echo "Summarizing $rawtable by $sumcategory.  New OTU table will be called $sumtable.  Filtering $sumtable at 1% and 0.005% and summarizing the results."
echo ""
echo "******************************************************************"
echo ""

#issue summarize by category command
summarize_otu_by_cat.py -i $rawtable -o $sumtable -m $mapfile -c $sumcategory
sleep 1
echo "Summarizing complete.  Filtering tables now..."

#filter summed otu table
echo ""
echo "0.005% filter..."
filter_otus_from_otu_table.py -i $sumtable -o $fivetable --min_count_fraction 0.00005
echo ""
echo "1% filter..."
filter_otus_from_otu_table.py -i $sumtable -o $onetable --min_count_fraction 0.01
echo ""
echo "Filtering complete.  Summarizing output now..."

biom summarize-table -i $fivetable -o $fivetable.summary
biom summarize-table -i $onetable -o $onetable.summary

echo ""
echo "******************************************************************"
echo ""
echo "Processing completed successfully!!"
echo ""
echo "******************************************************************"
echo ""
