#!/bin/bash
set -e

#Define input and outputs based on user responses

echo "Enter the name of your first read file (must end with .fastq):"
read -e read1
echo ""

echo "Enter the name of your second read file (must end with .fastq):"
read -e read2
echo ""

echo "Enter the name of your indexing read file (must end with .fastq):"
read -e index1
echo ""

echo "Enter the length of your index read:"
read indexlength
echo ""

echo "Enter your desired output folder (Directory must already exist.  Use ./ for this directory):"
read -e outdir
echo ""

echo "Enter your desired minimum overlap:
(default is 6, I like 30, but this might depend on your data)"
read overlap
echo ""

echo "Enter your desired allowable percent mismatch:
(default is 10 percent, I like 30 percent.  Enter as integer value)"
read mismatch
echo ""

echo "
single indexed read joining workflow beginning" > $outdir/fastq-join_stdout.txt
date >> $outdir/fastq-join_stdout.txt
echo "---" >> $outdir/fastq-join_stdout.txt

readno=$(expr $indexlength + 1)

#make output directory
mkdir $outdir/fastq-join_output

#map Phix reads in order to filter out and assess contamination levels
smalt map -n 20 -o $outdir/fastq-join_output/read1.phix.mapped.sam ~/PhiX/phix-k11-s1 $read1
#smalt map -n 20 -o $outdir/fastq-join_output/read2.phix.mapped.sam ~/PhiX/phix-k11-s1 $read2

#use grep to identify reads that are non-phix
egrep "\w+:\w+:\w+-\w+:\w+:\w+:\w+:\w+\s4" $outdir/fastq-join_output/read1.phix.mapped.sam > $outdir/fastq-join_output/phix.unmapped.sam
#egrep "\w+:\w+:\w+-\w+:\w+:\w+:\w+:\w+\s4" $outdir/fastq-join_output/read2.phix.mapped.sam >> $outdir/fastq-join_output/phix.unmapped.sam

#filter contaminating sequences out prior to joining
( filter_fasta.py -f $index1 -o $outdir/fastq-join_output/index.phixfiltered.fq -s $outdir/fastq-join_output/phix.unmapped.sam ) &
( filter_fasta.py -f $read1 -o $outdir/fastq-join_output/read1.phixfiltered.fq -s $outdir/fastq-join_output/phix.unmapped.sam ) &
( filter_fasta.py -f $read2 -o $outdir/fastq-join_output/read2.phixfiltered.fq -s $outdir/fastq-join_output/phix.unmapped.sam ) &
wait

totalseqs1=$(cat $outdir/fastq-join_output/read1.phix.mapped.sam | wc -l)
nonphixseqs1=$(cat $outdir/fastq-join_output/index.phixfiltered.fq | wc -l)
totalseqs=$(($totalseqs1-3))
nonphixseqs=$(($nonphixseqs1/4))
phixseqs=$(($totalseqs-$nonphixseqs))
nonphix100seqs=$(($nonphixseqs*100))
datapercent=$(expr $nonphix100seqs / $totalseqs)
contampercent=$(expr 100 - $datapercent)
read1unmap=$(egrep "\w+:\w+:\w+-\w+:\w+:\w+:\w+:\w+\s4" $outdir/fastq-join_output/read1.phix.mapped.sam | wc -l)
#read2unmap=$(egrep "\w+:\w+:\w+-\w+:\w+:\w+:\w+:\w+\s4" $outdir/fastq-join_output/read2.phix.mapped.sam | wc -l)
read1map=$(($totalseqs-$read1unmap))
#read2map=$(($totalseqs-$read2unmap))

echo "
PhiX filtering completed
" >> $outdir/fastq-join_stdout.txt

echo "Identified $read1map PhiX reads in your first read file" >> $outdir/fastq-join_stdout.txt
#echo "Identified $read2map PhiX reads in your first read file" >> $outdir/fastq-join_stdout.txt

echo "Your demultiplexed data contains sample data at this percentage: $datapercent ($nonphixseqs out of $totalseqs total reads)" >> $outdir/fastq-join_stdout.txt
echo "Your demultiplexed data contains PhiX contamination at this percentage: $contampercent ($phixseqs PhiX174 reads)
" >> $outdir/fastq-join_stdout.txt
echo "---
" >> $outdir/fastq-join_stdout.txt

#concatenate index1 in front of read1
paste -d '' <(echo; sed -n '1,${n;p;}' $outdir/fastq-join_output/index.phixfiltered.fq | sed G) $outdir/fastq-join_output/read1.phixfiltered.fq | sed '/^$/d' > $outdir/fastq-join_output/i1r1.phixfiltered.fq
wait

echo "concatenation completed
" >> $outdir/fastq-join_stdout.txt
date >> $outdir/fastq-join_stdout.txt
echo "---" >> $outdir/fastq-join_stdout.txt
echo "" >> $outdir/fastq-join_stdout.txt

#fastq-join command

echo "Joining command as issued: fastq-join -p $mismatch -m $overlap -r $outdir/fastq-join.report.log $outdir/fastq-join_output/i1r1.fq $read2 -o $outdir/fastq-join_output/joined.%.fastq" >> $outdir/fastq-join_stdout.txt
echo "" >> $outdir/fastq-join_stdout.txt
echo "Fastq-join results:" >> $outdir/fastq-join_stdout.txt
fastq-join -p $mismatch -m $overlap -r $outdir/fastq-join.report.log $outdir/fastq-join_output/i1r1.phixfiltered.fq $outdir/fastq-join_output/read2.phixfiltered.fq -o $outdir/fastq-join_output/phixfiltered.%.fastq >> $outdir/fastq-join_stdout.txt

wait

joinedlines=$(cat $outdir/fastq-join_output/phixfiltered.join.fastq | wc -l)
joinedseqs=$(($joinedlines/4))
joined100seqs=$(($joinedseqs*100))
joinedpercent=$(($joined100seqs/$totalseqs))

echo "
Read joining success was achieved at $joinedpercent percent" >> $outdir/fastq-join_stdout.txt

echo "" >> $outdir/fastq-join_stdout.txt
echo "fastq-join step completed" >> $outdir/fastq-join_stdout.txt
date >> $outdir/fastq-join_stdout.txt
echo "
---" >> $outdir/fastq-join_stdout.txt

#move fastq-join report to output directory
mv $outdir/fastq-join.report.log $outdir/fastq-join_output/

#filter input fastq of phix contamination with filter_fasta.py
#filter_fasta.py -f $outdir/fastq-join_output/joined.join.fastq -o $outdir/fastq-join_output/joined.PhixFiltered.fastq -s $outdir/fastq-join_output/phix.unmapped.sam

#log fastx_trimmer commands
echo "
Index trimming command as issued: fastx_trimmer -l $indexlength -i $outdir/fastq-join_output/joined.PhixFiltered.fastq -o $outdir/idx.join.fq -Q 33" >> $outdir/fastq-join_stdout.txt
echo "
Read trimming command as issued: fastx_trimmer -f $readno -i $outdir/fastq-join_output/joined.PhixFiltered.fastq -o $outdir/rd.join.fq -Q 33" >> $outdir/fastq-join_stdout.txt

#split index from successfully joined reads
( fastx_trimmer -l $indexlength -i $outdir/fastq-join_output/phixfiltered.join.fastq -o $outdir/idx.join.fq -Q 33 ) &

#split read data from successfully joined reads
( fastx_trimmer -f $readno -i $outdir/fastq-join_output/phixfiltered.join.fastq -o $outdir/rd.join.fq -Q 33 ) &

#rerun concatenation and joining commands and delete resulting files so as to determine the effect of phix filtering on join success
paste -d '' <(echo; sed -n '1,${n;p;}' $index1 | sed G) $read1 | sed '/^$/d' > $outdir/fastq-join_output/i1r1.nonfiltered.fq
echo "
Fastq-join results (no PhiX filtering):" >> $outdir/fastq-join_stdout.txt
fastq-join -p $mismatch -m $overlap $outdir/fastq-join_output/i1r1.nonfiltered.fq $read2 -o $outdir/fastq-join_output/nonfiltered.%.fastq >> $outdir/fastq-join_stdout.txt
wait

joinednonlines=$(cat $outdir/fastq-join_output/nonfiltered.join.fastq | wc -l)
joinednonseqs=$(($joinednonlines/4))
joined100nonseqs=$(($joinednonseqs*100))
joinednonpercent=$(($joined100nonseqs/$totalseqs))
phixinflation=$(($joinednonseqs-$joinedseqs))
phix100inflation=$(($phixinflation*100))
inflationpercent=$(($phix100inflation/$joinedseqs))

echo "
Unfiltered read joining success was achieved at $joinednonpercent percent.
PhiX would have contributed $phixinflation reads to your dataset had you joined reads without filtering (an inflation of $inflationpercent percent).

---" >> $outdir/fastq-join_stdout.txt
rm $outdir/fastq-join_output/nonfiltered.join.fastq
rm $outdir/fastq-join_output/nonfiltered.un1.fastq
rm $outdir/fastq-join_output/nonfiltered.un2.fastq
rm $outdir/fastq-join_output/i1r1.nonfiltered.fq
wait

echo "
Removing excess large files...
"
rm $outdir/fastq-join_output/i1r1.phixfiltered.fq
rm $outdir/fastq-join_output/index.phixfiltered.fq
rm $outdir/fastq-join_output/phix.unmapped.sam
rm $outdir/fastq-join_output/phixfiltered.join.fastq
rm $outdir/fastq-join_output/phixfiltered.un1.fastq
rm $outdir/fastq-join_output/phixfiltered.un2.fastq
#rm $outdir/fastq-join_output/read1.phix.mapped.sam
rm $outdir/fastq-join_output/read1.phixfiltered.fq
rm $outdir/fastq-join_output/read2.phixfiltered.fq

echo "joining workflow is completed!" >> $outdir/fastq-join_stdout.txt
date >> $outdir/fastq-join_stdout.txt
echo "---
" >> $outdir/fastq-join_stdout.txt

echo "Joining workflow is completed.
See output file, $outdir/fastq-join_stdout.txt for joining details.

"

