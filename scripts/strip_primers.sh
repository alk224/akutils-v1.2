#!/usr/bin/env bash
#
#  akutils strip_primers - Remove primers and subsequent seqeunce from MiSeq data
#
#  Version 1.2.0 (June 29, 2016)
#
#  Copyright (c) 2014-2015 Andrew Krohn
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
## Trap function on exit.
function finish {
if [[ -f $fqtest ]]; then
	rm $fqtest
fi
if [[ -f $fqtemp ]]; then
	rm $fqtemp
fi
if [[ -f $filterlist ]]; then
	rm $filterlist
fi
if [[ -f $indexlist ]]; then
	rm $indexlist
fi
if [[ -f $empty1 ]]; then
	rm $empty1
fi
if [[ -f $empty2 ]]; then
	rm $empty2
fi
if [[ -f $empty3 ]]; then
	rm $empty3
fi
if [[ -f $empty4 ]]; then
	rm $empty4
fi
}
trap finish EXIT

## Define variables.
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=`dirname $scriptdir`
	workdir=$(pwd)
	tempdir="$repodir/temp"
	stdout="$1"
	stderr="$2"
	randcode="$3"
	config="$4"
	mode0="$5"
	fastq1="$6"
	fastq2="$7"
	fastq3="$8"
	fastq4="$9"

	fastqext="${fastq1##*.}"
	fastqbase=$(basename $fastq1 .$fastqext)

	mode1=${mode0:0:1}
	mode2=${mode0:1:2}

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

	date0=$(date +%Y%m%d_%I%M%p)
	res1=$(date +%s.%N)

## Read in variables from config file
	errors=(`grep "Cutadapt_errors" $config | grep -v "#" | cut -f 2`)

## Check for cutadapt install.
	progtest=$(command -v cutadapt 2>/dev/null | wc -l)
	if [[ "$progtest" == "0" ]]; then
	echo "
Cutadapt does not seem to be present on your system. You may need to install it
or simply call the correct module. Exiting.
	"
	exit 1
	fi

		## Parse trimming mode (3, 5, or B)
		if [[ "$mode2" == "3" ]]; then
		trim="3prime"
		elif [[ "$mode2" == "5" ]]; then
		trim="5prime-anchored"
		elif [[ "$mode2" == "B" ]]; then
		trim="both-ends"
		fi

## Check for presence of primer file. Exit if not present and suggest primer_file command.
	if [[ ! -f "primer_file.txt" ]]; then
	echo "
No valid primer file is present in this directory.

Running akutils primer_file utility to generate one for you."
	sleep 1
	akutils primer_file
	exit 0
	else
	primers="primer_file.txt"
	primercount=$(cat $primers | wc -l)
		if [[ "$primercount" -ge "3" ]]; then
		primercount="2"
		fi
		if [[ "$primercount" -eq "0" ]]; then
		echo "
No valid primers in primer file. Exiting.
		"
		exit 1
		fi
		if [[ "$primercount" -eq "1" ]]; then
		primer1=$(head -1 $primers | cut -f2)
		primer1name=$(head -1 $primers | cut -f1)

		## Set output directory with primer names and trimming mode
		outdir="$workdir/strip_primers_out_${primer1name}_${trim}"
		elif [[ "$primercount" -eq "2" ]]; then
		primer1=$(head -1 $primers | cut -f2)
		primer1name=$(head -1 $primers | cut -f1)
		primer2=$(head -2 $primers | tail -1 | cut -f2)
		primer2name=$(head -2 $primers | tail -1 | cut -f1)

		## Set output directory with primer names
		outdir="$workdir/strip_primers_out_${primer1name}-${primer2name}_${trim}"
		fi
	fi

## Check for valid mode1 or else exit.
	if [[ "$mode0" == "03" ]] || [[ "$mode0" == "05" ]] || [[ "$mode0" == "0B" ]] || [[ "$mode0" == "13" ]] || [[ "$mode0" == "15" ]] || [[ "$mode0" == "1B" ]] || [[ "$mode0" == "23" ]] || [[ "$mode0" == "25" ]] || [[ "$mode0" == "2B" ]]; then
	echo "
${bold}akutils strip_primers command${normal}

Selected mode: ${bold}${mode0}${normal}
Index files supplied: ${bold}${mode1}${normal}"
		if [[ "$mode2" == "3" ]]; then
		echo "Trimming mode: ${bold}3-prime${normal} (should be using reverse/complemented primer sequences)"
		elif [[ "$mode2" == "5" ]]; then
		echo "Trimming mode: ${bold}5-prime anchored${normal} (forward primer should begin the read)"
		elif [[ "$mode2" == "B" ]]; then
		echo "Trimming mode: ${bold}Bidirectional${normal}"
		fi

	else
	echo "
Invalid mode set. Must be ${bold}03, 05, 0B, 13, 15, 1B, 23, 25, or 2B${normal}.
Exiting.
	"
	cat $repodir/docs/strip_primers.usage
	exit 1
	fi

## Check for valid input or else exit.
	fqtest="$tempdir/${randcode}_fqtest"
	for infile in $fastq1 $fastq2 $fastq3 $fastq4; do
	if [[ ! -z $infile ]]; then
	fastqext="${infile##*.}"
	if [[ "$fastqext" != "fastq" ]] && [[ "$fastqext" != "fq" ]]; then
	echo "$infile" >> $fqtest
	fi
	fi
	done

	if [[ -f $fqtest ]]; then
	echo "
Invalid fastq file(s) supplied. Must have ${bold}.fq${normal} or ${bold}.fastq${normal} extension.

Check these files and try again:"
	cat $fqtest
	exit 1
	fi

## Count number of input files.
	fqtemp="$tempdir/${randcode}_fqtemp"
	for infile in $fastq1 $fastq2 $fastq3 $fastq4; do
	echo $infile >> $fqtemp
	done
	incount=$(cat $fqtemp | wc -l)

## Count number of files to filter and make list
	fcount=$(($incount-$mode1))
	if [[ "$fcount" -ge "3" ]]; then
	filtercount="2"
	else
	filtercount="$fcount"
		if [[ "$filtercount" == "0" ]]; then
		echo "
No files identified for primer removal. Exiting.
		"
		exit 1
		fi
	fi

	filterlist="$tempdir/${randcode}_filterlist"
	head -${filtercount} $fqtemp >> $filterlist
	indexlist="$tempdir/${randcode}_indexlist"
	tail -${mode1} $fqtemp >> $indexlist
	if [[ "$mode1" == "1" ]]; then
	idx1=$(head -1 $indexlist)
	idx1ext="${idx1##*.}"
	idx1base=$(basename $idx1 .$idx1ext)
	fi
	if [[ "$mode1" == "2" ]]; then
	idx1=$(head -1 $indexlist)
	idx1ext="${idx1##*.}"
	idx1base=$(basename $idx1 .$idx1ext)
	idx2=$(head -2 $indexlist | tail -1)
	idx2ext="${idx2##*.}"
	idx2base=$(basename $idx2 .$idx2ext)
	fi

	if [[ "$filtercount" == "1" ]]; then
	file1=$(head -1 $filterlist)
	file1ext="${file1##*.}"
	file1base=$(basename $file1 .$file1ext)
	out1="$outdir/$file1base.noprimers.$file1ext"
	elif [[ "$filtercount" == "2" ]]; then
	file1=$(head -1 $filterlist)
	file2=$(head -2 $filterlist | tail -1)
	file1ext="${file1##*.}"
	file2ext="${file2##*.}"
	file1base=$(basename $file1 .$file1ext)
	file2base=$(basename $file2 .$file2ext)
	out1="$outdir/$file1base.noprimers.$file1ext"
	out2="$outdir/$file2base.noprimers.$file2ext"
	fi

## Set log file.
	logtest=$(ls $outdir/log_strip_primers* 2>/dev/null | wc -l)
	if [[ "$logtest" -ge "1" ]]; then
	log=$(ls $outdir/log_strip_primers* | head -1)
	else
	log=($outdir/log_strip_primers_$date0.txt)
	fi


## Set output variable.

	output="$outdir/$fastqbase.${primer}-removed.${mode1}prime.$fastqext"

## Check for output directory.
	if [[ -d $outdir ]]; then
	echo "
Output directory exists. Rename or delete before rerunning this command.
Exiting.
	"
	exit 1
	else
		mkdir -p $outdir
	fi

## Report start of script to log file.
	date1=$(date "+%a %b %I:%M %p %Z %Y")
	echo "
********************************************************************************
$date1

akutils strip_primers command issued.
Input file(s):" >> $log
	cat $fqtemp >> $log
	echo "
Read file(s) to filter primers against:" >> $log
	cat $filterlist >> $log
	echo "
Mode: $mode1 index file(s)" >> $log
	echo "Index file(s) to be filtered against read files after primer trimming:" >> $log
	cat $indexlist >> $log
	echo "
Primers to filter from reads:" >> $log
	cat $primers >> $log
	echo "" >> $log

## Copy primer file into output directory
	cp $primers $outdir/

	echo ""

## Cutadapt command

## 3' trimming (mode2 = 3)
if [[ "$mode2" == "3" ]]; then
	echo "Issuing cutadapt command. This can take a while, so please be patient.

${bold}Command:${normal}"

	if [[ "$filtercount" == "1" ]] && [[ "$primercount" == "1" ]]; then
		echo "
Cutadapt command:
	cutadapt -e $errors -a $primer1 -o $out1 $file1
" >> $log
		echo "
	cutadapt -e $errors -a $primer1 -o $out1 $file1"
	cutadapt -e $errors -a $primer1 -o $out1 $file1 1>$stdout 2>$stderr
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi
	if [[ "$filtercount" == "1" ]] && [[ "$primercount" == "2" ]]; then
		echo "
Cutadapt command:
	cutadapt -e $errors -a $primer1 -a $primer2 -o $out1 $file1
" >> $log
		echo "
	cutadapt -e $errors -a $primer1 -a $primer2 -o $out1 $file1"
	cutadapt -e $errors -a $primer1 -a $primer2 -o $out1 $file1 1>$stdout 2>$stderr
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi
	if [[ "$filtercount" == "2" ]] && [[ "$primercount" == "1" ]]; then
		echo "
Cutadapt command:
	cutadapt -e $errors -a $primer1 -A $primer1 -o $out1 -p $out2 $file1 $file2
" >> $log
		echo "
	cutadapt -e $errors -a $primer1 -A $primer1 -o $out1 -p $out2 $file1 $file2"
	cutadapt -e $errors -a $primer1 -A $primer1 -o $out1 -p $out2 $file1 $file2 1>$stdout 2>$stderr
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi
	if [[ "$filtercount" == "2" ]] && [[ "$primercount" == "2" ]]; then
		echo "
Cutadapt command:
	cutadapt -e $errors -a $primer2 -A $primer1 -o $out1 -p $out2 $file1 $file2
" >> $log
		echo "
	cutadapt -e $errors -a $primer2 -A $primer1 -o $out1 -p $out2 $file1 $file2"
	cutadapt -e $errors -a $primer2 -A $primer1 -o $out1 -p $out2 $file1 $file2 1>$stdout 2>$stderr
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi
fi

## 5' trimming (mode2 = 5)
if [[ "$mode2" == "5" ]]; then
	echo "Issuing cutadapt command. This can take a while, so please be patient.

${bold}Command:${normal}"

	if [[ "$filtercount" == "1" ]] && [[ "$primercount" == "1" ]]; then
		echo "
Cutadapt command:
	cutadapt -e $errors -g ^${primer1} -o $out1 $file1
" >> $log
		echo "
	cutadapt -e $errors -g ^${primer1} -o $out1 $file1"
	cutadapt -e $errors -g ^${primer1} -o $out1 $file1 1>$stdout 2>$stderr
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi
	if [[ "$filtercount" == "1" ]] && [[ "$primercount" == "2" ]]; then
		echo "
Cutadapt command:
	cutadapt -e $errors -g ^${primer1} -g ^${primer2} -o $out1 $file1
" >> $log
		echo "
	cutadapt -e $errors -g ^${primer1} -g ^${primer2} -o $out1 $file1"
	cutadapt -e $errors -g ^${primer1} -g ^${primer2} -o $out1 $file1 1>$stdout 2>$stderr
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi
	if [[ "$filtercount" == "2" ]] && [[ "$primercount" == "1" ]]; then
		echo "
Cutadapt command:
	cutadapt -e $errors -g ^${primer1} -G ^${primer1} -o $out1 -p $out2 $file1 $file2
" >> $log
		echo "
	cutadapt -e $errors -g ^${primer1} -G ^${primer1} -o $out1 -p $out2 $file1 $file2"
	cutadapt -e $errors -g ^${primer1} -G ^${primer1} -o $out1 -p $out2 $file1 $file2 1>$stdout 2>$stderr
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi
	if [[ "$filtercount" == "2" ]] && [[ "$primercount" == "2" ]]; then
		echo "
Cutadapt command:
	cutadapt -e $errors -g ^${primer1} -G ^${primer2} -o $out1 -p $out2 $file1 $file2
" >> $log
		echo "
	cutadapt -e $errors -g ^${primer1} -G ^${primer2} -o $out1 -p $out2 $file1 $file2"
	cutadapt -e $errors -g ^${primer1} -G ^${primer2} -o $out1 -p $out2 $file1 $file2 1>$stdout 2>$stderr
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi
fi

## Trimming from both ends (mode2 = B)
if [[ "$mode2" == "B" ]]; then
	echo "Issuing cutadapt command. This can take a while, so please be patient.

${bold}Command:${normal}"

	if [[ "$filtercount" == "1" ]] && [[ "$primercount" == "1" ]]; then
		echo "
Cutadapt command:
	cutadapt -e $errors -b $primer1 -o $out1 $file1
" >> $log
		echo "
	cutadapt -e $errors -b $primer1 -o $out1 $file1"
	cutadapt -e $errors -b $primer1 -o $out1 $file1 1>$stdout 2>$stderr
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi
	if [[ "$filtercount" == "1" ]] && [[ "$primercount" == "2" ]]; then
		echo "
Cutadapt command:
	cutadapt -e $errors -b $primer1 -b $primer2 -o $out1 $file1
" >> $log
		echo "
	cutadapt -e $errors -b $primer1 -b $primer2 -o $out1 $file1"
	cutadapt -e $errors -b $primer1 -b $primer2 -o $out1 $file1 1>$stdout 2>$stderr
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi
	if [[ "$filtercount" == "2" ]] && [[ "$primercount" == "1" ]]; then
		echo "
Cutadapt command:
	cutadapt -e $errors -b $primer1 -B $primer1 -o $out1 -p $out2 $file1 $file2
" >> $log
		echo "
	cutadapt -e $errors -b $primer1 -B $primer1 -o $out1 -p $out2 $file1 $file2"
	cutadapt -e $errors -b $primer1 -B $primer1 -o $out1 -p $out2 $file1 $file2 1>$stdout 2>$stderr
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi
	if [[ "$filtercount" == "2" ]] && [[ "$primercount" == "2" ]]; then
		echo "
Cutadapt command:
	cutadapt -e $errors -b $primer1 -b $primer2 -B $primer1 -B $primer2 -o $out1 -p $out2 $file1 $file2
" >> $log
		echo "
	cutadapt -e $errors -b $primer1 -b $primer2 -B $primer1 -B $primer2 -o $out1 -p $out2 $file1 $file2"
	cutadapt -e $errors -b $primer1 -b $primer2 -B $primer1 -B $primer2 -o $out1 -p $out2 $file1 $file2 1>$stdout 2>$stderr
	wait
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	fi
fi

## Count empty fastq records from output and filter if necessary
	echo "
Checking for empty fastq records in filtered output."
	empty1="$tempdir/${randcode}_empty1"
	empty2="$tempdir/${randcode}_empty2"
	empty3="$tempdir/${randcode}_empty3"
	empty4="$tempdir/${randcode}_empty4"
	if [[ "$filtercount" == "1" ]]; then
	grep -B 1 -e "^$" $out1 | grep -v -e "^$" | grep -v -e "^+$" | sed "/^--$/d" | cut -d" " -f1 > $empty1
	cat $empty1 > $empty3
	fi

	if [[ "$filtercount" == "2" ]]; then
	grep -B 1 -e "^$" $out1 | grep -v -e "^$" | grep -v -e "^+$" | sed "/^--$/d" | cut -d" " -f1 > $empty1
	grep -B 1 -e "^$" $out2 | grep -v -e "^$" | grep -v -e "^+$" | sed "/^--$/d" | cut -d" " -f1 > $empty2
	cat $empty1 $empty1 > $empty3
	fi

	if [[ -s $empty3 ]]; then
	sort $empty3 | uniq > $empty4
	sed -i "s/^@//g" $empty4
	emptycount=$(cat $empty4 | wc -l)
	echo "
${bold}$emptycount empty fastq records found.${normal} Filtering from read pairs and indexes."
	echo "
$emptycount empty fastq records found. Filtering from read pairs and indexes." >> $log

		if [[ "$mode1" == "0" ]] && [[ "$filtercount" == "1" ]]; then
		mv $out1 $outdir/$file1base.temp.fastq
		filter_fasta.py -f $outdir/$file1base.temp.fastq -o $outdir/$file1base.noprimers.fastq -n --sample_id_fp $empty4
		wait
		mv $outdir/$file1base.noprimers.fastq $out1
		rm $outdir/$file1base.temp.fastq
		fi

		if [[ "$mode1" == "0" ]] && [[ "$filtercount" == "2" ]]; then
		mv $out1 $outdir/$file1base.temp.fastq
		mv $out2 $outdir/$file2base.temp.fastq
		( filter_fasta.py -f $outdir/$file1base.temp.fastq -o $outdir/$file1base.noprimers.fastq -n --sample_id_fp $empty4 ) &
		( filter_fasta.py -f $outdir/$file2base.temp.fastq -o $outdir/$file2base.noprimers.fastq -n --sample_id_fp $empty4 ) &
		wait
		mv $outdir/$file1base.noprimers.fastq $out1
		mv $outdir/$file2base.noprimers.fastq $out2
		rm $outdir/$file1base.temp.fastq
		rm $outdir/$file2base.temp.fastq
		fi

		if [[ "$mode1" == "1" ]] && [[ "$filtercount" == "1" ]]; then
		mv $out1 $outdir/$file1base.temp.fastq
		cp $idx1 $outdir/$idx1base.temp.fastq
		( filter_fasta.py -f $outdir/$file1base.temp.fastq -o $outdir/$file1base.noprimers.fastq -n --sample_id_fp $empty4 ) &
		( filter_fasta.py -f $outdir/$idx1base.temp.fastq -o $outdir/$idx1base.noprimers.fastq -n --sample_id_fp $empty4 ) &
		wait
		mv $outdir/$file1base.noprimers.fastq $out1
		mv $outdir/$idx1base.noprimers.fastq $outdir/$idx1base.noprimers.$idx1ext
		rm $outdir/$file1base.temp.fastq
		rm $outdir/$idx1base.temp.fastq
		fi

		if [[ "$mode1" == "1" ]] && [[ "$filtercount" == "2" ]]; then
		mv $out1 $outdir/$file1base.temp.fastq
		mv $out2 $outdir/$file2base.temp.fastq
		cp $idx1 $outdir/$idx1base.temp.fastq
		( filter_fasta.py -f $outdir/$file1base.temp.fastq -o $outdir/$file1base.noprimers.fastq -n --sample_id_fp $empty4 ) &
		( filter_fasta.py -f $outdir/$file2base.temp.fastq -o $outdir/$file2base.noprimers.fastq -n --sample_id_fp $empty4 ) &
		( filter_fasta.py -f $outdir/$idx1base.temp.fastq -o $outdir/$idx1base.noprimers.fastq -n --sample_id_fp $empty4 ) &
		wait
		mv $outdir/$file1base.noprimers.fastq $out1
		mv $outdir/$file2base.noprimers.fastq $out2
		mv $outdir/$idx1base.noprimers.fastq $outdir/$idx1base.noprimers.$idx1ext
		rm $outdir/$file1base.temp.fastq
		rm $outdir/$file2base.temp.fastq
		rm $outdir/$idx1base.temp.fastq
		fi

		if [[ "$mode1" == "2" ]] && [[ "$filtercount" == "1" ]]; then
		mv $out1 $outdir/$file1base.temp.fastq
		cp $idx1 $outdir/$idx1base.temp.fastq
		cp $idx2 $outdir/$idx2base.temp.fastq
		( filter_fasta.py -f $outdir/$file1base.temp.fastq -o $outdir/$file1base.noprimers.fastq -n --sample_id_fp $empty4 ) &
		( filter_fasta.py -f $outdir/$idx1base.temp.fastq -o $outdir/$idx1base.noprimers.fastq -n --sample_id_fp $empty4 ) &
		( filter_fasta.py -f $outdir/$idx2base.temp.fastq -o $outdir/$idx2base.noprimers.fastq -n --sample_id_fp $empty4 ) &
		wait
		mv $outdir/$file1base.noprimers.fastq $out1
		mv $outdir/$idx1base.noprimers.fastq $outdir/$idx1base.noprimers.$idx1ext
		mv $outdir/$idx2base.noprimers.fastq $outdir/$idx2base.noprimers.$idx2ext
		rm $outdir/$file1base.temp.fastq
		rm $outdir/$idx1base.temp.fastq
		rm $outdir/$idx2base.temp.fastq
		fi

		if [[ "$mode1" == "2" ]] && [[ "$filtercount" == "2" ]]; then
		mv $out1 $outdir/$file1base.temp.fastq
		mv $out2 $outdir/$file2base.temp.fastq
		cp $idx1 $outdir/$idx1base.temp.fastq
		cp $idx2 $outdir/$idx2base.temp.fastq
		( filter_fasta.py -f $outdir/$file1base.temp.fastq -o $outdir/$file1base.noprimers.fastq -n --sample_id_fp $empty4 ) &
		( filter_fasta.py -f $outdir/$file2base.temp.fastq -o $outdir/$file2base.noprimers.fastq -n --sample_id_fp $empty4 ) &
		( filter_fasta.py -f $outdir/$idx1base.temp.fastq -o $outdir/$idx1base.noprimers.fastq -n --sample_id_fp $empty4 ) &
		( filter_fasta.py -f $outdir/$idx2base.temp.fastq -o $outdir/$idx2base.noprimers.fastq -n --sample_id_fp $empty4 ) &
		wait
		mv $outdir/$file1base.noprimers.fastq $out1
		mv $outdir/$file2base.noprimers.fastq $out2
		mv $outdir/$idx1base.noprimers.fastq $outdir/$idx1base.noprimers.$idx1ext
		mv $outdir/$idx2base.noprimers.fastq $outdir/$idx2base.noprimers.$idx2ext
		rm $outdir/$file1base.temp.fastq
		rm $outdir/$file2base.temp.fastq
		rm $outdir/$idx1base.temp.fastq
		rm $outdir/$idx2base.temp.fastq
		fi

	else
	echo "
${bold}Zero empty fastq records found.${normal} Copying index files to output.
No filter required."
	echo "
No empty fastq records found. Copying index files to output.
No filter required." >> $log

		if [[ "$mode1" == "1" ]]; then
		cp $idx1 $outdir/$idx1base.noprimers.$idx1ext
		fi
		if [[ "$mode1" == "2" ]]; then
		cp $idx1 $outdir/$idx1base.noprimers.$idx1ext
		cp $idx2 $outdir/$idx2base.noprimers.$idx2ext
		fi
	fi

## Log end of workflow
res2=$(date +%s.%N)
dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)

runtime=`printf "Total runtime: %d days %02d hours %02d minutes %02.1f seconds\n" $dd $dh $dm $ds`

echo "
${bold}Strip primers workflow steps completed.  Hooray!${normal}
$runtime
"
echo "
---

All workflow steps completed.  Hooray!" >> $log
date "+%a %b %I:%M %p %Z %Y" >> $log
echo "
$runtime 
" >> $log

exit 0
