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

## Define variables.
	homedir=`echo $HOME`
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=`dirname $scriptdir`
	workdir=$(pwd)
	cpus=`grep -c ^processor /proc/cpuinfo`
	ram=`grep MemTotal /proc/meminfo | cut -d":" -f2 | sed 's/\s//g'`
	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

## Echo test start
echo "
Beginning tests of akutils functions.
All tests take ~20 minutes on a system
with 24 cores or ~60 minutes on a
system with 2 cores.

Your system has ${bold}$cpus${normal} cores
and ${bold}$ram${normal} available RAM.
"

## Check for test data
	testtest=`ls $homedir/QIIME_test_data_16S 2>/dev/null | wc -l`
	if [[ $testtest == 0 ]]; then
	cd $homedir
	echo "Retrieving test data from github."
	git clone https://github.com/alk224/QIIME_test_data_16S.git
	else
	echo "Test data is in place."
	fi
	testdir=($homedir/QIIME_test_data_16S)
	cd $testdir

## Set log file
	logcount=`ls $testdir/log_workflow_testing* 2>/dev/null | wc -l`	
	if [[ $logcount > 0 ]]; then
	rm $testdir/log_workflow_testing*
	fi
	echo "${bold}Workflow tests beginning.${normal}"
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

## Test of format_database.sh command
	res1=$(date +%s.%N)
	echo "${bold}Test of format_database command.${normal}
	"
	echo "
***** Test of format_database command.
***** Command:
akutils format_database $testdir/gg_database/97_rep_set_1000.fasta $testdir/gg_database/97_taxonomy_1000.txt $testdir/resources/primers_515F-806R.txt 150 $testdir/db_format_out" >> $log
	if [[ -d $testdir/format_database_out ]]; then
	rm -r $testdir/format_database_out
	else
	mkdir -p $testdir/format_database_out
	fi
	akutils format_database $testdir/gg_database/97_rep_set_1000.fasta $testdir/gg_database/97_taxonomy_1000.txt $testdir/resources/primers_515F-806R.txt 250 $testdir/format_database_out 1>$testdir/std_out 2>$testdir/std_err || true
	wait
	echo "
***** format_database std_out:
	" >> $log
	cat $testdir/std_out >> $log
	echo "
***** format_database std_err:
	" >> $log
	if [[ -s $testdir/std_err ]]; then
	echo "!!!!! ERRORS REPORTED DURING TEST !!!!!
	" >> $log
	fi
	cat $testdir/std_err >> $log
	if [[ ! -s $testdir/std_err ]]; then
	echo "format_database successful (no error message).
	"
	echo "format_database successful (no error message)." >> $log
	echo "" >> $log
	else
	echo "Errors reported during format_database test.
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
	runtime=`printf "Runtime for format_database test:
%d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "
$runtime
	" >> $log
	echo "$runtime
	"

## Test of strip_primers.sh command
	res1=$(date +%s.%N)
	echo "${bold}Test of strip_primers command.${normal}
	"
	echo "
***** Test of strip_primers command.
***** Command:
akutils strip_primers $homedir/akutils/primers.16S.ITS.fa $testdir/read1.fq $testdir/read2.fq $testdir/index1.fq" >> $log
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

	akutils strip_primers $homedir/akutils/primers.16S.ITS.fa $testdir/read1.fq $testdir/read2.fq $testdir/index1.fq 1>$testdir/std_out 2>$testdir/std_err || true
	wait
	if [[ ! -f $testdir/strip_primers_out/index1.noprimers.fastq ]] && [[ -f $testdir/strip_primers_out/index1.fastq ]]; then
	mv $testdir/strip_primers_out/index1.fastq $testdir/strip_primers_out/index1.noprimers.fastq
	fi
	echo "
***** strip_primers std_out:
	" >> $log
	cat $testdir/std_out >> $log
	echo "
***** strip_primers std_err:
	" >> $log
	if [[ -s $testdir/std_err ]]; then
	echo "!!!!! ERRORS REPORTED DURING TEST !!!!!
	" >> $log
	fi
	cat $testdir/std_err >> $log
	if [[ ! -s $testdir/std_err ]]; then
	echo "strip_primers successful (no error message).
	"
	echo "strip_primers successful (no error message)." >> $log
	echo "" >> $log
	else
	echo "Errors reported during strip_primers test.
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
	runtime=`printf "Runtime for strip_primers test:
%d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "
$runtime
	" >> $log
	echo "$runtime
	"

## Test of phix_filtering command
	res1=$(date +%s.%N)
	echo "${bold}Test of phix_filtering command.${normal}
	"
	echo "
***** Test of phix_filtering command.
***** Command:
akutils phix_filtering $testdir/phix_filtering_out $testdir/map.test.txt $testdir/strip_primers_out/index1.noprimers.fastq $testdir/strip_primers_out/read1.noprimers.fastq $testdir/strip_primers_out/read2.noprimers.fastq" >> $log
	if [[ -d $testdir/phix_filtering_out ]]; then
	rm -r $testdir/phix_filtering_out
	fi
	if [[ ! -f $testdir/map.test.txt ]]; then
	cp $testdir/raw_data/map.mock.16S.nodils.txt $testdir/map.test.txt
	fi
	akutils phix_filtering $testdir/phix_filtering_out $testdir/map.test.txt $testdir/strip_primers_out/index1.noprimers.fastq $testdir/strip_primers_out/read1.noprimers.fastq $testdir/strip_primers_out/read2.noprimers.fastq 1>$testdir/std_out 2>$testdir/std_err 2>&1 || true
	wait
	echo "
***** phix_filtering std_out:
	" >> $log
	cat $testdir/std_out >> $log
	echo "
***** phix_filtering std_err:
	" >> $log
	if [[ -s $testdir/std_err ]]; then
	echo "!!!!! ERRORS REPORTED DURING TEST !!!!!
	" >> $log
	fi
	cat $testdir/std_err >> $log
	if [[ ! -s $testdir/std_err ]]; then
	echo "phix_filtering successful (no error message).
	"
	echo "phiX_filtering successful (no error message)." >> $log
	echo "" >> $log
	else
	echo "Errors reported during phix_filtering test.
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
	runtime=`printf "Runtime for phix_filtering test:
%d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "
	$runtime
	" >> $log
	echo "$runtime
	"

## Test of join_paired_reads.sh command
	res1=$(date +%s.%N)
	echo "${bold}Test of join_paired_reads command.${normal}
	"
	echo "
***** Test of join_paired_reads command.
***** Command:
akutils join_paired_reads $testdir/phix_filtering_out/index.phixfiltered.fastq $testdir/phix_filtering_out/read1.phixfiltered.fastq $testdir/phix_filtering_out/read2.phixfiltered.fastq 12 -m 30 -p 30" >> $log
	if [[ -d $testdir/join_paired_reads_out ]]; then
	rm -r $testdir/join_paired_reads_out
	fi
	cd $testdir
	akutils join_paired_reads $testdir/phix_filtering_out/index.phixfiltered.fastq $testdir/phix_filtering_out/read1.phixfiltered.fastq $testdir/phix_filtering_out/read2.phixfiltered.fastq 12 -m 30 -p 30 1>$testdir/std_out 2>$testdir/std_err || true
	wait
	cd $workdir
	echo "
***** join_paired_reads std_out:
	" >> $log
	cat $testdir/std_out >> $log
	grep -A 5 "Fastq-join results:" $testdir/join_paired_reads_out/log_join_paired_reads*.txt >> $log
	echo "
***** join_paired_reads std_err:
	" >> $log
	if [[ -s $testdir/std_err ]]; then
	echo "!!!!! ERRORS REPORTED DURING TEST !!!!!
	" >> $log
	fi
	cat $testdir/std_err >> $log
	if [[ ! -s $testdir/std_err ]]; then
	echo "join_paired_reads successful (no error message).
	"
	echo "join_paired_reads successful (no error message)." >> $log
	echo "" >> $log
	else
	echo "Errors reported during join_paired_reads test.
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

## Test of pick_otus.sh command
	res1=$(date +%s.%N)
	echo "${bold}Test of pick_otus command.${normal}
This test takes a while.  Please be patient
(~13 minutes needed on a system with 24 cores).
	"
	echo "
***** Test of pick_otus command.
***** Command:
akutils pick_otus 16S" >> $log
	if [[ -d $testdir/pick_otus_out ]]; then
	rm -r $testdir/pick_otus_out
	fi
	mkdir $testdir/pick_otus_out
	cp $testdir/map.test.txt $testdir/pick_otus_out
	cp $testdir/join_paired_reads_out/idx.fq $testdir/pick_otus_out
	cp $testdir/join_paired_reads_out/rd.fq $testdir/pick_otus_out
	cd $testdir/pick_otus_out
	akutils pick_otus.sh 16S 1>$testdir/std_out 2>$testdir/std_err || true
	wait
	cd $workdir
	echo "
***** pick_otus std_out:
	" >> $log
	cat $testdir/std_out >> $log
	echo "
***** pick_otus std_err:
	" >> $log
	if [[ -s $testdir/std_err ]]; then
	echo "!!!!! ERRORS REPORTED DURING TEST !!!!!
	" >> $log
	fi
	cat $testdir/std_err >> $log
	if [[ ! -s $testdir/std_err ]]; then
	echo "pick_otus successful (no error message).
	"
	echo "pick_otus successful (no error message)." >> $log
	echo "" >> $log
	else
	echo "Errors reported during pick_otus test.
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
	runtime=`printf "Runtime for pick_otus test:
%d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "
$runtime
	" >> $log
	echo "$runtime
	"
exit 0
## Test of align_and_tree command
	res1=$(date +%s.%N)
	echo "Test of align_and_tree command.
	"
	echo "
***** Test of align_and_tree command.
***** Command:
akutils align_and_tree swarm_otus_d1/ 16S" >> $log
	cd $testdir/pick_otus_out
	bash $scriptdir/align_tree.sh swarm_otus_d1/ 16S 1>$testdir/std_out 2>$testdir/std_err || true
	wait
	cd $workdir
	echo "
***** align_and_tree std_out:
	" >> $log
	cat $testdir/std_out >> $log
	echo "
***** align_and_tree std_err:
	" >> $log
	if [[ -s $testdir/std_err ]]; then
	echo "!!!!! ERRORS REPORTED DURING TEST !!!!!
	" >> $log
	fi
	cat $testdir/std_err >> $log
	if [[ ! -s $testdir/std_err ]]; then
	echo "align_and_tree successful (no error message).
	"
	echo "align_and_tree successful (no error message)." >> $log
	echo "" >> $log
	else
	echo "Errors reported during align_and_tree test.
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
	runtime=`printf "Runtime for align_and_tree test:
%d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`
	echo "
	$runtime
	" >> $log
	echo "$runtime
	"

## Test of core_diversity command
	res1=$(date +%s.%N)
	echo "Test of core_diversity command.
This test takes a while.  Please be patient
(~7 minutes needed on a system with 24 cores).
	"
	echo "
***** Test of core_diversity command.
***** Command:
akutils core_diversity.sh swarm_otus_d1/OTU_tables_blast_tax/03_table_hdf5.biom map.test.txt Community $cpus" >> $log
	cd $testdir/pick_otus_out
	bash $scriptdir/core_diversity.sh swarm_otus_d1/OTU_tables_blast_tax/03_table_hdf5.biom map.test.txt Community $cpus 1>$testdir/std_out 2>$testdir/std_err || true
	wait
	cd $workdir
	echo "
***** core_diversity std_out:
	" >> $log
	cat $testdir/std_out >> $log
	echo "
***** core_diversity std_err:
	" >> $log
	if [[ -s $testdir/std_err ]]; then
	echo "!!!!! ERRORS REPORTED DURING TEST !!!!!
	" >> $log
	fi
	cat $testdir/std_err >> $log
	if [[ ! -s $testdir/std_err ]]; then
	echo "core_diversity successful (no error message).
	"
	echo "core_diversity successful (no error message)." >> $log
	echo "" >> $log
	else
	echo "Errors reported during core_diversity test.
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
	runtime=`printf "Runtime for core_diversity test:
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
	" >> $log
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
