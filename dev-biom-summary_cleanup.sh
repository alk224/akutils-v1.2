#!/bin/bash

#Loop to rename bio summaries that have dual extension for some reason (eg .biom.summary)

echo ""
echo "********************************************************"
echo ""
echo "Enter subdirectory containing biom summaries with dual extensions:"
read -e biomdir

echo ""
echo "Processing..."
echo ""

for file in $biomdir/*.biom.*; do
   mv "${file}" "${file/.biom.*/.summary}";
done

echo ""
echo "Done"
echo ""

