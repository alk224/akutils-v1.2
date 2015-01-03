#!/bin/bash

#script to process split libraries step in parallel

#Define variables based on user input
echo "Enter your raw sequence read file (fastq only):"
read -e seqs

echo "Enter your index sequences file (fastq only):"
read -e index

echo "Enter your mapping file:"
read -e map

echo "Enter desired quality threshold (for q20 and better enter 19):"
read quality

echo "Enter any additional modifications to the command here as you would normally enter during split_libraries_fastq.py (eg, barcode_type 12 --rev_comp_mapping_barcodes):"
read modifications

echo "Enter the desired number of cores (number must allow even splitting of fastq or this script will break!!):"
read cores

mkdir split_libraries
echo "---" > split_libraries/parallel_split_libraries_log.txt
echo "parallel processing began at" >> split_libraries/parallel_split_libraries_log.txt
date >> split_libraries/parallel_split_libraries_log.txt
echo "---" >> split_libraries/parallel_split_libraries_log.txt
echo "Starting parallel processing of split_libraries_fastq.py command.  This could take a while...."

outdir=parallel_split_libraries_fastq_tempdir
mkdir $outdir

lines=$(cat $index | wc -l)
splitlines=$(expr $lines / $cores)
split $seqs -l $splitlines
mv xa* ./parallel_split_libraries_fastq_tempdir/

for xread in ./parallel_split_libraries_fastq_tempdir/xa*
do
     mv $xread $xread.rd.fq
done

split $index -l $splitlines

for xind in xa*
do
     mv $xind $xind.idx.fq
     mv $xind.idx.fq ./parallel_split_libraries_fastq_tempdir/
done

for splitseq in ./parallel_split_libraries_fastq_tempdir/*.rd.fq; do
     base=$(basename $splitseq .rd.fq)


( split_libraries_fastq.py -i ./parallel_split_libraries_fastq_tempdir/$base.rd.fq -o ./parallel_split_libraries_fastq_tempdir/$base\_slout -m $map -b ./parallel_split_libraries_fastq_tempdir/$base.idx.fq -q $quality $modifications ) &
done
wait

#mkdir split_libraries

for dir in ./parallel_split_libraries_fastq_tempdir/*_slout; do
cat $dir/seqs.fna >> split_libraries/seqs.fna

done

rm -r parallel_split_libraries_fastq_tempdir/
echo "---" >> split_libraries/parallel_split_libraries_log.txt
echo "parallel processing completed at" >> split_libraries/parallel_split_libraries_log.txt
date >> split_libraries/parallel_split_libraries_log.txt
echo "---" >>split_libraries/parallel_split_libraries_log.txt
