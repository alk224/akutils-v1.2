#!/usr/bin/env bash
## Trap function to replace temporary global config file on exit status 1
function finish {
if [[ ! -z $backfile ]]; then
mv $backfile $homedir/akutils/akutils_resources/akutils.global.config
fi
}
trap finish EXIT

## workflow of tests to examine system installation completeness
set -e
homedir=`echo $HOME`
scriptdir="$( cd "$( dirname "$0" )" && pwd )"
repodir=`dirname $scriptdir`
workdir=$(pwd)

## Echo test start
echo "
Beginning tests of QIIME installation.
All tests take ~20 minutes on a system
with 24 cores.
"

## Check for test data
testtest=`ls $homedir/QIIME_test_data_16S 2>/dev/null | wc -l`
	if [[ $testtest == 0 ]]; then
	cd $homedir
	git clone https://github.com/alk224/QIIME_test_data_16S.git
	else
	echo "Test data in place.
	"
	fi
testdir=($homedir/QIIME_test_data_16S)
cd $testdir

## Set log file
logcount=`ls $testdir/log_workflow_testing* 2>/dev/null | wc -l`	
if [[ $logcount > 0 ]]; then
	rm $testdir/log_workflow_testing*
fi
	echo "Workflow tests beginning."
	date1=`date "+%a %b %d %I:%M %p %Z %Y"`
	echo "$date1"
	date0=`date +%Y%m%d_%I%M%p`
	log=($testdir/log_workflow_testing_$date0.txt)
	echo "
Workflow tests beginning." > $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	res0=$(date +%s.%N)
	echo "
---
		" >> $log

## Unpack data if necessary
	for gzfile in `ls raw_data/*.gz 2>/dev/null`; do
	gunzip $gzfile
	done
	for gzfile in `ls gg_database/*.gz 2>/dev/null`; do
	gunzip $gzfile
	done

## Setup akutils global config file
if [[ -f $testdir/resources/akutils.global.config.master ]]; then
rm $testdir/resources/akutils.global.config.master
fi
cp $testdir/resources/config.template $testdir/resources/akutils.global.config.master
masterconfig=($testdir/resources/akutils.global.config.master)
cpus=`grep -c ^processor /proc/cpuinfo`

for field in `grep -v "#" $masterconfig | cut -f 1`; do
	if [[ $field == "Reference" ]]; then
	setting=`grep $field $masterconfig | grep -v "#" | cut -f 2`
	newsetting=($testdir/db_format_out/515f_806r_composite.fasta)
	sed -i -e "s@^$field\t$setting@$field\t$newsetting@" $masterconfig
	fi
	if [[ $field == "Taxonomy" ]]; then
	setting=`grep $field $masterconfig | grep -v "#" | cut -f 2`
	newsetting=($testdir/db_format_out/515f_806r_composite_taxonomy.txt)
	sed -i -e "s@^$field\t$setting@$field\t$newsetting@" $masterconfig
	fi
	if [[ $field == "Chimeras" ]]; then
	setting=`grep $field $masterconfig | grep -v "#" | cut -f 2`
	newsetting=($testdir/gg_database/gold.fa)
	sed -i -e "s@^$field\t$setting@$field\t$newsetting@" $masterconfig
	fi
	if [[ $field == "OTU_picker" ]]; then
	setting=`grep $field $masterconfig | grep -v "#" | cut -f 2`
	newsetting="ALL"
	sed -i -e "s@^$field\t$setting@$field\t$newsetting@" $masterconfig
	fi
	if [[ $field == "Tax_assigner" ]]; then
	setting=`grep $field $masterconfig | grep -v "#" | cut -f 2`
	newsetting="ALL"
	sed -i -e "s@^$field\t$setting@$field\t$newsetting@" $masterconfig
	fi
	if [[ $field == "Alignment_template" ]]; then
	setting=`grep $field $masterconfig | grep -v "#" | cut -f 2`
	newsetting=($testdir/gg_database/core_set_aligned.fasta.imputed)
	sed -i -e "s@^$field\t$setting@$field\t$newsetting@" $masterconfig
	fi
	if [[ $field == "Alignment_lanemask" ]]; then
	setting=`grep $field $masterconfig | grep -v "#" | cut -f 2`
	newsetting=($testdir/gg_database/lanemask_in_1s_and_0s)
	sed -i -e "s@^$field\t$setting@$field\t$newsetting@" $masterconfig
	fi
	if [[ $field == "Rarefaction_depth" ]]; then
	setting=`grep $field $masterconfig | grep -v "#" | cut -f 2`
	newsetting="AUTO"
	sed -i -e "s@^$field\t$setting@$field\t$newsetting@" $masterconfig
	fi
	if [[ $field == "CPU_cores" ]]; then
	setting=`grep $field $masterconfig | grep -v "#" | cut -f 2`
	newsetting=($cpus)
	sed -i -e "s@^$field\t$setting@$field\t$newsetting@" $masterconfig
	fi
done


## If no global akutils config file, set global config
configtest=`ls $homedir/akutils/akutils_resources/akutils.global.config 2>/dev/null | wc -l`
	if [[ $configtest == 0 ]]; then
	cp $masterconfig $homedir/akutils/akutils_resources/akutils.global.config
	echo "Set akutils global config file.
	"
	echo "
Set akutils global config file." >> $log
	fi

## If global config exists, backup and temporarily replace
	if [[ $configtest == 1 ]]; then
	DATE=`date +%Y%m%d-%I%M%p`
	backfile=($homedir/akutils/akutils_resources/akutils.global.config.backup.$DATE)
	cp $homedir/akutils/akutils_resources/akutils.global.config $backfile
	cp $masterconfig $homedir/akutils/akutils_resources/akutils.global.config
	echo "Set temporary akutils global config file.
	"
	echo "
Set temporary akutils global config file." >> $log
	fi

## Test of db_format.sh command
	res1=$(date +%s.%N)
	echo "Test of db_format.sh command.
	"
	echo "
***** Test of db_format.sh command.
***** Command:
db_format $testdir/gg_database/97_rep_set_1000.fasta $testdir/gg_database/97_taxonomy_1000.txt $testdir/resources/primers_515F-806R.txt 150 $testdir/db_format_out" >> $log
	if [[ -d $testdir/db_format_out ]]; then
	rm -r $testdir/db_format_out
	else
	mkdir -p $testdir/db_format_out
	fi
bash $scriptdir/db_format.sh $testdir/gg_database/97_rep_set_1000.fasta $testdir/gg_database/97_taxonomy_1000.txt $testdir/resources/primers_515F-806R.txt 250 $testdir/db_format_out 1>$testdir/std_out 2>$testdir/std_err || true
wait
echo "
***** dbformat.sh std_out:
" >> $log
cat $testdir/std_out >> $log
echo "
***** dbformat.sh std_err:
" >> $log
	if [[ -s $testdir/std_err ]]; then
	echo "!!!!! ERRORS REPORTED DURING TEST !!!!!
	" >> $log
	fi
cat $testdir/std_err >> $log
	if [[ ! -s $testdir/std_err ]]; then
	echo "db_format.sh successful (no error message).
	"
	echo "db_format.sh successful (no error message)." >> $log
echo "" >> $log
	else
	echo "Errors reported during db_format.sh test.
See log file: $log
	"
	fi

res2=$(date +%s.%N)
dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)

runtime=`printf "Runtime for db_format.sh test:
%d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
echo "
$runtime
" >> $log
echo "$runtime
"

## Test of strip_primers.sh command
	res1=$(date +%s.%N)
	echo "Test of strip_primers.sh command.
	"
	echo "
***** Test of strip_primers.sh command.
***** Command:
strip_primers.sh $homedir/akutils/primers.16S.ITS.fa $testdir/read1.fq $testdir/read2.fq $testdir/index1.fq" >> $log
	if [[ ! -f $testdir/index1.fq ]]; then
	cp $testdir/raw_data/idx.trim.fastq $testdir/index1.fq
	fi
	if [[ ! -f $testdir/read1.fq ]]; then
	cp $testdir/raw_data/r1.trim.fastq $testdir/read1.fq
	fi
	if [[ ! -f $testdir/read2.fq ]]; then
	cp $testdir/raw_data/r2.trim.fastq $testdir/read2.fq
	fi
	if [[ -d $testdir/strip_primers_out ]]; then
	rm -r $testdir/strip_primers_out
	fi
bash $scriptdir/strip_primers.sh $homedir/akutils/primers.16S.ITS.fa $testdir/read1.fq $testdir/read2.fq $testdir/index1.fq 1>$testdir/std_out 2>$testdir/std_err || true
wait
	if [[ ! -f $testdir/strip_primers_out/index1.noprimers.fastq ]] && [[ -f $testdir/strip_primers_out/index1.fastq ]]; then
	mv $testdir/strip_primers_out/index1.fastq $testdir/strip_primers_out/index1.noprimers.fastq
	fi
echo "
***** strip_primers.sh std_out:
" >> $log
cat $testdir/std_out >> $log
echo "
***** strip_primers.sh std_err:
" >> $log
	if [[ -s $testdir/std_err ]]; then
	echo "!!!!! ERRORS REPORTED DURING TEST !!!!!
	" >> $log
	fi
cat $testdir/std_err >> $log
	if [[ ! -s $testdir/std_err ]]; then
	echo "strip_primers.sh successful (no error message).
	"
	echo "strip_primers.sh successful (no error message)." >> $log
echo "" >> $log
	else
	echo "Errors reported during strip_primers.sh test.
See log file: $log
	"
	fi

res2=$(date +%s.%N)
dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)

runtime=`printf "Runtime for strip_primers.sh test:
%d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
echo "
$runtime
" >> $log
echo "$runtime
"

## Test of PhiX_filtering_workflow.sh command
	res1=$(date +%s.%N)
	echo "Test of PhiX_filtering_workflow.sh command.
	"
	echo "
***** Test of PhiX_filtering_workflow.sh command.
***** Command:
PhiX_filtering_workflow.sh $testdir/PhiX_filtering_out $testdir/map.test.txt $testdir/strip_primers_out/index1.noprimers.fastq $testdir/strip_primers_out/read1.noprimers.fastq $testdir/strip_primers_out/read2.noprimers.fastq" >> $log
	if [[ -d $testdir/PhiX_filtering_out ]]; then
	rm -r $testdir/PhiX_filtering_out
	fi
	if [[ ! -f $testdir/map.test.txt ]]; then
	cp $testdir/raw_data/map.mock.16S.nodils.txt $testdir/map.test.txt
	fi
bash $scriptdir/PhiX_filtering_workflow.sh $testdir/PhiX_filtering_out $testdir/map.test.txt $testdir/strip_primers_out/index1.noprimers.fastq $testdir/strip_primers_out/read1.noprimers.fastq $testdir/strip_primers_out/read2.noprimers.fastq 1>$testdir/std_out 2>$testdir/std_err 2>&1 || true
wait
echo "
***** PhiX_filtering_workflow.sh std_out:
" >> $log
cat $testdir/std_out >> $log
echo "
***** PhiX_filtering_workflow.sh std_err:
" >> $log
	if [[ -s $testdir/std_err ]]; then
	echo "!!!!! ERRORS REPORTED DURING TEST !!!!!
	" >> $log
	fi
cat $testdir/std_err >> $log
	if [[ ! -s $testdir/std_err ]]; then
	echo "PhiX_filtering_workflow.sh successful (no error message).
	"
	echo "PhiX_filtering_workflow.sh successful (no error message)." >> $log
echo "" >> $log
	else
	echo "Errors reported during PhiX_filtering_workflow.sh test.
See log file: $log
	"
	fi

res2=$(date +%s.%N)
dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)

runtime=`printf "Runtime for PhiX_filtering_workflow.sh test:
%d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
echo "
$runtime
" >> $log
echo "$runtime
"

## Test of Single_indexed_fqjoin_workflow.sh command
	res1=$(date +%s.%N)
	echo "Test of Single_indexed_fqjoin_workflow.sh command.
	"
	echo "
***** Test of Single_indexed_fqjoin_workflow.sh command.
***** Command:
Single_indexed_fqjoin_workflow.sh $testdir/PhiX_filtering_out/index.phixfiltered.fastq $testdir/PhiX_filtering_out/read1.phixfiltered.fastq $testdir/PhiX_filtering_out/read2.phixfiltered.fastq 12 -m 30 -p 30" >> $log
	if [[ -d $testdir/fastq-join_output ]]; then
	rm -r $testdir/fastq-join_output
	fi
bash $scriptdir/Single_indexed_fqjoin_workflow.sh $testdir/PhiX_filtering_out/index.phixfiltered.fastq $testdir/PhiX_filtering_out/read1.phixfiltered.fastq $testdir/PhiX_filtering_out/read2.phixfiltered.fastq 12 -m 30 -p 30 1>$testdir/std_out 2>$testdir/std_err || true
wait
echo "
***** Single_indexed_fqjoin_workflow.sh std_out:
" >> $log
cat $testdir/std_out >> $log
grep -A 5 "Fastq-join results:" $testdir/fastq-join_output/fastq-join_workflow*.log >> $log
echo "
***** Single_indexed_fqjoin_workflow.sh std_err:
" >> $log
	if [[ -s $testdir/std_err ]]; then
	echo "!!!!! ERRORS REPORTED DURING TEST !!!!!
	" >> $log
	fi
cat $testdir/std_err >> $log
	if [[ ! -s $testdir/std_err ]]; then
	echo "Single_indexed_fqjoin_workflow.sh successful (no error message).
	"
	echo "Single_indexed_fqjoin_workflow.sh successful (no error message)." >> $log
echo "" >> $log
	else
	echo "Errors reported during Single_indexed_fqjoin_workflow.sh test.
See log file: $log
	"
	fi

res2=$(date +%s.%N)
dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)

runtime=`printf "Runtime for Single_indexed_fqjoin_workflow.sh test:
%d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
echo "
$runtime
" >> $log
echo "$runtime
"

## Test of otu_picking_workflow.sh command
	res1=$(date +%s.%N)
	echo "Test of otu_picking_workflow.sh command.
This test takes a while.  Please be patient
(~13 minutes needed on a system with 24 cores).
	"
	echo "
***** Test of otu_picking_workflow.sh command.
***** Command:
otu_picking_workflow.sh $testdir/otu_picking_workflow_out 16S" >> $log
	if [[ -d $testdir/otu_picking_workflow_out ]]; then
	rm -r $testdir/otu_picking_workflow_out
	fi
	mkdir $testdir/otu_picking_workflow_out
	cp $testdir/map.test.txt $testdir/otu_picking_workflow_out
	cp $testdir/fastq-join_output/idx.fq $testdir/otu_picking_workflow_out
	cp $testdir/fastq-join_output/rd.fq $testdir/otu_picking_workflow_out
cd $testdir/otu_picking_workflow_out
bash $scriptdir/otu_picking_workflow.sh ./ 16S 1>$testdir/std_out 2>$testdir/std_err || true
wait
cd $homedir
echo "
***** otu_picking_workflow.sh std_out:
" >> $log
cat $testdir/std_out >> $log
echo "
***** otu_picking_workflow.sh std_err:
" >> $log
	if [[ -s $testdir/std_err ]]; then
	echo "!!!!! ERRORS REPORTED DURING TEST !!!!!
	" >> $log
	fi
cat $testdir/std_err >> $log
	if [[ ! -s $testdir/std_err ]]; then
	echo "otu_picking_workflow.sh successful (no error message).
	"
	echo "otu_picking_workflow.sh successful (no error message)." >> $log
echo "" >> $log
	else
	echo "Errors reported during otu_picking_workflow.sh test.
See log file: $log
	"
	fi

res2=$(date +%s.%N)
dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)

runtime=`printf "Runtime for otu_picking_workflow.sh test:
%d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
echo "
$runtime
" >> $log
echo "$runtime
"

## Test of align_and_tree_workflow.sh command
	res1=$(date +%s.%N)
	echo "Test of align_and_tree_workflow.sh command.
	"
	echo "
***** Test of align_and_tree_workflow.sh command.
***** Command:
align_and_tree_workflow.sh swarm_otus_d1/ 16S" >> $log
cd $testdir/otu_picking_workflow_out
bash $scriptdir/align_tree_workflow.sh swarm_otus_d1/ 16S 1>$testdir/std_out 2>$testdir/std_err || true
wait
cd $homedir
echo "
***** align_and_tree_workflow.sh std_out:
" >> $log
cat $testdir/std_out >> $log
echo "
***** align_and_tree_workflow.sh std_err:
" >> $log
	if [[ -s $testdir/std_err ]]; then
	echo "!!!!! ERRORS REPORTED DURING TEST !!!!!
	" >> $log
	fi
cat $testdir/std_err >> $log
	if [[ ! -s $testdir/std_err ]]; then
	echo "align_and_tree_workflow.sh successful (no error message).
	"
	echo "align_and_tree_workflow.sh successful (no error message)." >> $log
echo "" >> $log
	else
	echo "Errors reported during align_and_tree_workflow.sh test.
See log file: $log
	"
	fi

res2=$(date +%s.%N)
dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)

runtime=`printf "Runtime for align_and_tree_workflow.sh test:
%d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
echo "
$runtime
" >> $log
echo "$runtime
"

## Test of cdiv_graphs_and_stats_workflow.sh command
	res1=$(date +%s.%N)
	echo "Test of cdiv_graphs_and_stats_workflow.sh command.
This test takes a while.  Please be patient
(~7 minutes needed on a system with 24 cores).
	"
	echo "
***** Test of cdiv_graphs_and_stats_workflow.sh command.
***** Command:
cdiv_graphs_and_stats_workflow.sh swarm_otus_d1/OTU_tables_blast_tax/03_table_hdf5.biom map.test.txt Community $cpus" >> $log
cd $testdir/otu_picking_workflow_out
bash $scriptdir/cdiv_stats_workflow.sh swarm_otus_d1/OTU_tables_blast_tax/03_table_hdf5.biom map.test.txt Community $cpus 1>$testdir/std_out 2>$testdir/std_err || true
wait
cd $homedir
echo "
***** cdiv_graphs_and_stats_workflow.sh std_out:
" >> $log
cat $testdir/std_out >> $log
echo "
***** cdiv_graphs_and_stats_workflow.sh std_err:
" >> $log
	if [[ -s $testdir/std_err ]]; then
	echo "!!!!! ERRORS REPORTED DURING TEST !!!!!
	" >> $log
	fi
cat $testdir/std_err >> $log
	if [[ ! -s $testdir/std_err ]]; then
	echo "cdiv_graphs_and_stats_workflow.sh successful (no error message).
	"
	echo "cdiv_graphs_and_stats_workflow.sh successful (no error message)." >> $log
echo "" >> $log
	else
	echo "Errors reported during cdiv_graphs_and_stats_workflow.sh test.
See log file: $log
	"
	fi

res2=$(date +%s.%N)
dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)

runtime=`printf "Runtime for cdiv_graphs_and_stats_workflow.sh test:
%d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
echo "
$runtime
" >> $log
echo "$runtime
"

## Count successes and failures
testcount=`grep "***** Test of" $log | wc -l`
errorcount=`grep "!!!!! ERRORS REPORTED DURING TEST" $log | wc -l`
echo "Ran $testcount tests.
"
echo "Ran $testcount tests.
" >> $log
	if [[ $errorcount == 0 ]]; then
	echo "All tests successful ($testcount/$testcount).
	"
	echo "All tests successful ($testcount/$testcount).
	" >> $ log
	else
	echo "Errors observed in $errorcount/$testcount tests.
See log file for details:
$log
	"
	echo "Errors observed in $errorcount/$testcount tests.
	" >> $log
	fi

res2=$(date +%s.%N)
dt=$(echo "$res2 - $res0" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)

runtime=`printf "Runtime for all workflow tests:
%d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
echo "
$runtime
" >> $log
echo "$runtime
"

exit 0
