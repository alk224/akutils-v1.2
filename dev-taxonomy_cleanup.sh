#!/bin/bash
set -e

echo "Enter your taxonomy file name:"
read -e taxfile

echo "Enter the file containing a list of sequence IDs to retain (columnar format):"
read -e retain

wc -l < $taxfile > wc_taxfile.temp
wc -l < $retain > wc_retain.temp

read taxlines < wc_taxfile.temp
read retainlines < wc_retain.temp

difference=$(expr $taxlines - $retainlines)

echo ""
echo "********************************************************************"
echo ""
echo "Retaining all lines containing sequence IDs found in $taxfile"
echo ""
echo "Filtered file will be called $taxfile.taxfiltered.txt"
echo ""
echo "********************************************************************"
echo ""
sleep 1
echo "Filtering out $difference lines from $taxfile ($taxlines lines)"
echo ""
echo "Filtered file will contain $retainlines sequence identifiers"
echo ""
echo "********************************************************************"

for line in `cat $retain` ; do
     grep $line $taxfile >> $taxfile.taxfiltered.txt
done

wc -l < $taxfile.taxfiltered.txt > wc_filtered.temp
read filteredlines < wc_filtered.temp

rm wc_taxfile.temp
rm wc_retain.temp

echo ""
echo "Filtering completed"
echo ""
echo "Filtered file contains $filteredlines sequence identifiers"
echo ""
echo "********************************************************************"
echo ""
rm wc_filtered.temp

