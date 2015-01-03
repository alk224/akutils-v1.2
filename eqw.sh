#!/bin/bash
set -e

## check whether user had supplied -h or --help. If yes display help 

	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
		echo "
		eqw.sh (EnGGen QIIME WORKFLOW)

		This script takes an input directory and attempts to process
		contents through a qiime workflow.  More stuff to add here...			

		Output will be 2 files, an index file (idx.fq) and a read
		file (rd.fq).

		Usage (order is important!!):
		Qiime_workflow.sh <input folder> <mode>

		Example:
		Qiime_workflow.sh ./ 16S

		This example will attempt to process data residing in the
		current directory through a complete qiime workflow.  If
		certain conventions are met, the workflow will skip all
		steps that have already been processed.  It will try to
		guess why some step failed and give you feedback if/when
		it crashes.

		Order of processing attempts:
		1) Checks for <input folder>/split_libraries/seqs.fna.  
		If present, moves forward to chimera filter or OTU picking.
		If absent, checks for joined fastq files (as idx.fq and 
		rd.fq).  Requires a mapping file be present (map*).
		2) If joined fastqs absent, looks for raw fastq files
		(as index1*fastq, index2*fastq, read1*fastq, read2*fastq).
		Requires a mapping file to be present (map*) and a primers
		file to be present (primers*).

		Config file:
		To get this script to work you need a valid config file.
		You can generate a config file and set up the necessary
		fields by running the egw config utility:

		eqw.sh config

		Mapping file:
		Mapping files are formatted for QIIME.  Index sequences
		contained therein must be in the CORRECT orientation.

		Primers file:
		Primers file must be in fasta format.  Degenerate primers
		must be expressed as individual sequences as degenerate
		code is not correctly parsed.  All primer sequences must 
		be REVERSE COMPLEMENTED.

		Parameters file:
		Parameters for the steps starting at OTU picking can be
		modified by placing a qiime-formatted parameters file in
		your working directory.  The parameters file must begin
		with \"parameters\".  More than one such file in your
		working directory will cause the workflow to exit.

		Example parameters file contents (parameters_fast.txt):
		pick_otus:max_accepts	1
		pick_otus:max_rejects	8

		Requires the following dependencies to run all steps:
		1) QIIME 1.8.0 or later (qiime.org)
		2) ea-utils (https://code.google.com/p/ea-utils/)
		3) Fastx toolkit (http://hannonlab.cshl.edu/fastx_toolkit/)
		4) NGSutils (http://ngsutils.org/)
		5) Fasta-splitter.pl (http://kirill-kryukov.com/study/tools/fasta-splitter/)
		6) ITSx (http://microbiology.se/software/itsx/)
		7) Smalt (https://www.sanger.ac.uk/resources/software/smalt/)
		8) HMMer v3+ (http://hmmer.janelia.org/)
		
		Citations: 
QIIME: 
Caporaso, J., Kuczynski, J., & Stombaugh, J. (2010). QIIME allows analysis of high-throughput community sequencing data. Nature Methods, 7(5), 335–336.

ea-utils:
etc etc for now...
		"
		exit 0	
	fi

## If config supplied, run config utility instead

	if [[ "$1" == "config" ]]; then
## Will need to change this with a more proper installation setup
		eqw_config_utility.sh
		exit 0
	fi

## If less than two arguments supplied, display usage 

	if [  "$#" -le 1 ]; then 

		echo "
		Usage (order is important!!):
		Qiime_workflow.sh <input folder> <mode>
		"
		exit 1
	fi

## Check that valid mode was entered

	if [[ $2 != ITS && $2 != 16S ]]; then
		echo "
		Invalid mode entered (you entered $2).
		Valid modes are 16S or ITS.

		Usage (order is important!!):
		Qiime_workflow.sh <input folder> <mode>
		"
		exit 1
	fi

	mode=($2)

## Check that no more than one parameter file is present

	parameter_count=(`ls $1/parameter* | wc -w`)

	if [[ $parameter_count -ge 2 ]]; then

		echo "
		No more than one parameter file can reside in your working
		directory.  Presently, there are $parameter_count such files.  
		Move or rename all but one of these files and restart the
		workflow.  A parameter file is any file in your working
		directory that starts with \"parameter\".  See --help for
		more details.
		
		Exiting...
		"
		
		exit 1
	else
	param_file=(`ls $1/parameter*`)
	fi

## Check that no more than one mapping file is present

	map_count=(`ls $1/map* | wc -w`)

	if [[ $map_count -ge 2 && $map_count -ne 0 ]]; then

		echo "
		This workflow requires a mapping file.  No more than one 
		mapping file can reside in your working directory.  Presently,
		there are $map_count such files.  Move or rename all but one 
		of these files and restart the workflow.  A mapping file is 
		any file in your working directory that starts with \"map\".
		It should be properly formatted for QIIME processing.
		
		Exiting...
		"
		
		exit 1
	else
	map=(`ls $1/map*`)	
	fi

## Check for required dependencies:

	scriptdir="$( cd "$( dirname "$0" )" && pwd )"

echo "
		Checking for required dependencies...
"

scriptdir="$( cd "$( dirname "$0" )" && pwd )"


for line in `cat $scriptdir/eqw_resources/dependencies.list`; do
	dependcount=`command -v $line 2>/dev/null | wc -w`
	if [[ $dependcount == 0 ]]; then
	echo "
		$line is not in your path.  Dependencies not satisfied.
		Exiting.
	"
	exit 1
	else
	if [[ $dependcount -ge 1 ]]; then
	echo "		$line is in your path..."
	fi
	fi
done
echo "
		All dependencies satisfied.  Proceeding...
"

## Define working directory and log file
	workdir=$(pwd)
	outdir=($1)

##Read in variables from config file

	local_config_count=(`ls $1/eqw*.config 2>/dev/null | wc -w`)
	if [[ $local_config_count -ge 1 ]]; then

	config=`ls $1/eqw*.config`

	echo "		Using custom eqw config file.
		($1/$config)
	"
	else
		global_config_count=(`ls $scriptdir/eqw_resources/eqw*.config 2>/dev/null | wc -w`)
		if [[ $global_config_count -ge 1 ]]; then

		config=`ls $scriptdir/eqw_resources/eqw*.config`

		echo "		Using global eqw config file.
		($scriptdir/eqw_resources/eqw*.config)
		"
		fi
	fi

	if [[ $mode == "16S" ]]; then
	refs=(`grep "16S_reference" $config | grep -v "#" | cut -f 2`)
	tax=(`grep "16S_taxonomy" $config | grep -v "#" | cut -f 2`)
	tree=(`grep "16S_tree" $config | grep -v "#" | cut -f 2`)
	chimera_refs=(`grep "16S_chimeras" $config | grep -v "#" | cut -f 2`)
	seqs=($outdir/split_libraries/seqs_chimera_filtered.fna)
	alignment_template=(`grep "16S_alignment_template" $config | grep -v "#" | cut -f 2`)
	alignment_lanemask=(`grep "16S_alignment_lanemask" $config | grep -v "#" | cut -f 2`)
	revcomp=(`grep "16S_RC_seqs" $config | grep -v "#" | cut -f 2`)

	elif [[ $mode == "ITS" ]]; then
	refs=(`grep "ITS_reference" $config | grep -v "#" | cut -f 2`)
	tax=(`grep "ITS_taxonomy" $config | grep -v "#" | cut -f 2`)
	chimera_refs=(`grep "ITS_chimeras" $config | grep -v "#" | cut -f 2`)
	seqs=($outdir/split_libraries/seqs.fna)
	itsx_threads=(`grep "Threads_ITSx" $config | grep -v "#" | cut -f 2`)
	revcomp=(`grep "ITS_RC_seqs" $config | grep -v "#" | cut -f 2`)
	itsx_options=(`grep "ITSx_options" $config | grep -v "#" | cut -f 2`)

	fi

	slqual=(`grep "Split_libraries_qvalue" $config | grep -v "#" | cut -f 2`)
	chimera_threads=(`grep "Threads_chimera_filter" $config | grep -v "#" | cut -f 2`)
	otupicking_threads=(`grep "Threads_pick_otus" $config | grep -v "#" | cut -f 2`)
	taxassignment_threads=(`grep "Threads_assign_taxonomy" $config | grep -v "#" | cut -f 2`)
	alignseqs_threads=(`grep "Threads_align_seqs" $config | grep -v "#" | cut -f 2`)
	min_overlap=(`grep "Min_overlap" $config | grep -v "#" | cut -f 2`)
	max_mismatch=(`grep "Max_mismatch" $config | grep -v "#" | cut -f 2`)
	mcf_threads=(`grep "Threads_mcf" $config | grep -v "#" | cut -f 2`)
	phix_index=(`grep "PhiX_index" $config | grep -v "#" | cut -f 2`)
	smalt_threads=(`grep "Threads_smalt" $config | grep -v "#" | cut -f 2`)
	multx_errors=(`grep "Multx_errors" $config | grep -v "#" | cut -f 2`)
	rdp_confidence=(`grep "RDP_confidence" $config | grep -v "#" | cut -f 2`)
	rdp_max_memory=(`grep "RDP_max_memory" $config | grep -v "#" | cut -f 2`)
	

## Check if output directory already exists

	if [[ -d $outdir ]]; then
		echo "		Output directory already exists ($outdir).

		Checking for prior workflow progress...
		"
		if [[ -f $outdir/eqw_workflow.log ]]; then
			log=($outdir/eqw_workflow.log)
			echo "
---

qiime_workflow_script restarting in $mode mode" >> $log
			date >> $log
			echo "
---
			" >> $log
		fi
	else
		echo "		Beginning qiime_workflow_script in $mode mode
		"
		mkdir $outdir
		touch $outdir/eqw_workflow.log
		log=($outdir/eqw_workflow.log)
		echo "qiime_workflow_script beginning in $mode mode" >> $log
		date >> $log
		echo "
---
		" >> $log
	fi

## Check for split_libraries outputs and inputs

	if [[ -f $outdir/split_libraries/seqs.fna ]]; then
	echo "		Split libraries output detected. 
		($outdir/split_libraries/seqs.fna)
		Skipping split_libraries_fastq.py step,
	"
	else

	echo "		Split libraries needs to be completed.
		Checking for fastq files.
	"

		if [[ ! -f idx.fq || ! -f rd.fq ]]; then
		echo "		Joined fastqs not present or not all present.
		(Looked for idx.fq and rd.fq).

		Checking for raw fastq files instead.
		"

		fastq_count=(`ls $outdir/*fastq | wc -w`)

		if [[ $fastq_count -ge 3 ]]; then
		index_count=(`ls $outdir/index*fastq | wc -w`)
		read_count=(`ls $outdir/read*fastq | wc -w`)
		fi

		if [[ $read_count != 2 ]]; then
		echo "		More or less than 2 read files (raw fastq) are
		present.  Check your input files and try again.

		Exiting workflow.
		"
		exit 1
		fi
		

		if [[ $index_count -eq 1 ]]; then
		index1=(`ls $outdir/index1*fastq`)
		index1length=$((`sed '2q;d' $index1 | egrep "\w+" | wc -m`-1))

		elif [[ $index_count -eq 2 ]]; then
		index1=(`ls $outdir/index1*fastq`)
		index2=(`ls $outdir/index2*fastq`)
		index1length=$((`sed '2q;d' $index1 | egrep "\w+" | wc -m`-1))
		index2length=$((`sed '2q;d' $index2 | egrep "\w+" | wc -m`-1))
		indexlength=$(($index1+$index2))

		fi

		read1=(`ls $outdir/read1*fastq`)
		read2=(`ls $outdir/read2*fastq`)
		primers_count=(`ls $outdir/primers* 2>/dev/null | wc -w`)

		if [[ $primers_count -ne 1 ]]; then
		echo " 		Either your primers file is missing or you have
		too many files in your working directory that
		start with primers*.  See --help for more details.
		"
		exit 1
		else primers=(`ls $outdir/primers*`)
		fi

		if [[ $index_count -eq 2 ]]; then
		echo "		Starting dual indexed joining workflow with
		PhiX screen.
		"
		joinmode=dual
		echo "		Stripping out any primer sequences with fastq-mcf."
		


		if [[ $min_overlap -eq 0 && $max_mismatch -eq 0 ]]; then
		`Dual_indexed_fqjoin_workflow.sh $index1 $index2 $read1 $read2 $indexlength`
		fi
		if [[ $min_overlap -eq 0 && $max_mismatch -ne 0 ]]; then
		`Dual_indexed_fqjoin_workflow.sh $index1 $index2 $read1 $read2 $indexlength -m $min_overlap`
		fi
		if [[ $min_overlap -ne 0 && $max_mismatch -eq 0 ]]; then
		`Dual_indexed_fqjoin_workflow.sh $index1 $index2 $read1 $read2 $indexlength -p $max_mismatch`
		fi
		if [[ $min_overlap -ne 0 && $max_mismatch -ne 0 ]]; then
		`Dual_indexed_fqjoin_workflow.sh $index1 $index2 $read1 $read2 $indexlength -m $min_overlap -p $max_mismatch`
		fi		

		elif [[ $index_count -eq 1 ]]; then
		echo "		Starting single indexed joining workflow with
		PhiX screen.
		"
		joinmode=single
		echo "		Stripping out any primer sequences with fastq-mcf."

		strip_primers_parallel.sh $read1 $read2 $primers $mcf_threads

		if [[ ! -f barcodes.multx.fil ]]; then
		cat $map | cut -f 1-2 | grep -v "#" > barcodes.multx.fil
		fi
		barcodes=barcodes.multx.fil

		PhiX_filtering_single_index_CL.sh fastq-mcf_out/read1.mcf.fq fastq-mcf_out/read2.mcf.fq $index1 $index1length $barcodes $multx_errors $phix_index $smalt_threads $min_overlap $max_mismatch

		wait
		fi		
		cp PhiX_screen/idx.filtered.join.fq ./
		mv idx.filtered.join.fq idx.fq
		cp PhiX_screen/rd.filtered.join.fq ./
		mv rd.filtered.join.fq rd.fq

		fi

		if [[ ! -f idx.fq ]]; then
		echo "		Index file not present (./idx.fq).
		Correct this error by renaming your index file as idx.fq
		and ensuring it resides within this directory
		"
		exit 1
		fi

		if [[ ! -f rd.fq ]]; then
		echo "		Sequence read file not present (./rd.fq).
		Correct this error by renaming your read file as rd.fq
		and ensuring it resides within this directory
		"
		exit 1
		fi

	fi

## split_libraries_fastq.py command

		log=($outdir/eqw_workflow.log)
	
	if [[ $slqual == "" ]]; then 
	qual=(19)
	else
	qual=($slqual)
	fi
	if [[ `sed '2q;d' idx.fq | egrep "\w+" | wc -m` == 13  ]]; then
	barcodetype=(golay_12)
	else
	barcodetype=$((`sed '2q;d' idx.fq | egrep "\w+" | wc -m`-1))
	fi
	qvalue=$((qual+1))
	echo "		Performing split_libraries.py command (q$qvalue)"
	if [[ $barcodetype == "golay_12" ]]; then
	echo " 		12 base Golay index codes detected...
	"
	else
	echo "$barcodetype base indexes detected...
	"
	fi

	echo "Calling split_libraries_fastq.py:
split_libraries_fastq.py -i rd.fq -b idx.fq -m $map -o $outdir/split_libraries -q $qual --barcode_type $barcodetype" >> $log
	date >> $log

	`split_libraries_fastq.py -i rd.fq -b idx.fq -m $map -o $outdir/split_libraries -q $qual --barcode_type $barcodetype`	
	
	echo "		Split libraries command completed.
	"

	echo "
Split libraries command completed." >> $log
	date >> $log	

	wait

## Check for split libraries success

	if [[ ! -s $outdir/split_libraries/seqs.fna ]]; then
		echo "
		Split libraries step seems to not have identified any samples
		based on the indexing data you supplied.  You should check
		your list of indexes and try again (do they need to be reverse-
		complemented?
		"
		exit 1
	fi

## Chimera filtering step (for 16S mode only)

	if [[ $mode == "16S" ]]; then

	if [[ ! -f $outdir/split_libraries/seqs_chimera_filtered.fna ]]; then

	echo "		Beginning chimera filtering.
		(Method: usearch61)
		(Reference: $chimera_refs)
"
	echo "Beginning chimera filtering step
		(Method: usearch61)
		(Reference: $chimera_refs)" >> $log
	date >> $log

	echo "
Chimera filtering steps as issued:

identify_chimeric_seqs.py -m usearch61 -i $outdir/split_libraries/seqs.fna -r $chimera_refs -o $outdir/usearch61_chimera_checking

filter_fasta.py -f $outdir/split_libraries/seqs.fna -o $outdir/split_libraries/seqs_chimera_filtered.fna -s $outdir/usearch61_chimera_checking/chimeras.txt -n
" >> $log

	`identify_chimeric_seqs.py -m usearch61 -i $outdir/split_libraries/seqs.fna -r $chimera_refs -o $outdir/usearch61_chimera_checking`
	wait
	`filter_fasta.py -f $outdir/split_libraries/seqs.fna -o $outdir/split_libraries/seqs_chimera_filtered.fna -s $outdir/usearch61_chimera_checking/chimeras.txt -n`
	wait
	echo ""
	else

	echo "		Chimera filtered sequences detected.
		($seqs)
		Skipping chimera checking step.
	"

	fi
	fi

## Check for parameter file in working directory

	if [[ `ls $outdir/parameter* | wc -w` == 1 ]]; then
		param_file=$(ls $outdir/parameter*)
	fi

## Reverse complement demultiplexed sequences if necessary

	if [[ $revcomp == "True" ]]; then

	if [[ ! -f $outdir/split_libraries/seqs_rc.fna ]]; then

	`adjust_seq_orientation.py -i $seqs -r -o $outdir/split_libraries/seqs_rc.fna`
	wait
	echo "		Demultiplexed sequences were reverse complemented.
	"
	else
	echo "		Sequences already in proper orientation.
	"
	fi
	seqs=$outdir/split_libraries/seqs_rc.fna
	fi

## ITSx filtering (ITS mode only)

	if [[ $mode == "ITS" ]]; then

#	ITSx_parallel.sh $seqs $itsx_threads $itsx_options

	wait
	seqs=$outdir/split_libraries/seqs_rc_ITSx_output/seqs_rc_ITSx_filtered.fna	
	
	fi

## Check for OTU picking output

## OTU picking command

	if [[ ! -f $outdir/uclust_otu_picking/final_otu_map.txt ]]; then

	if [[ `ls $param_file | wc -w` == 1 ]]; then

	echo "		Picking open reference OTUs.  Passing in parameters file
		($param_file) to modify default settings
	"
	cat $param_file
	echo "
---

OTU picking command as issued:
pick_open_reference_otus.py -i $seqs -r $refs -o $outdir/uclust_otu_picking --prefilter_percent_id 0.0 -aO $otupicking_threads --suppress_align_and_tree --suppress_taxonomy_assignment -p $param_file
	" >> $log

	`pick_open_reference_otus.py -i $seqs -r $refs -o $outdir/uclust_otu_picking --prefilter_percent_id 0.0 -aO $otupicking_threads --suppress_align_and_tree --suppress_taxonomy_assignment -p $param_file`
	wait
	else

	echo "
---

OTU picking command as issued:
pick_open_reference_otus.py -i $seqs -r $refs -o $outdir/uclust_otu_picking --prefilter_percent_id 0.0 -aO $otupicking_threads --suppress_align_and_tree --suppress_taxonomy_assignment
	" >> $log
`pick_open_reference_otus.py -i $seqs -r $refs -o $outdir/uclust_otu_picking --prefilter_percent_id 0.0 -aO $otupicking_threads --suppress_align_and_tree --suppress_taxonomy_assignment`
	wait
	fi

	else

	echo "		OTU map detected.
		($outdir/uclust_otu_picking/final_otu_map.txt)
		Skipping OTU picking step.
"
	fi

## Pick rep set against raw OTU map

	if [[ ! -f $outdir/uclust_otu_picking/final_rep_set.fna ]]; then

	echo "Pick representative sequences command as issued:
pick_rep_set.py	-i $outdir/uclust_otu_picking/final_otu_map.txt -f $seqs -o $outdir/uclust_otu_picking/final_rep_set.fna
	" >> $log

`pick_rep_set.py -i $outdir/uclust_otu_picking/final_otu_map.txt -f $seqs -o $outdir/uclust_otu_picking/final_rep_set.fna`

	fi

## Check for open reference output directory

	if [[ ! -d $outdir/open_reference_output ]]; then
	mkdir $outdir/open_reference_output
	fi

## Check for rep set and raw OTU map files

	if [[ ! -f $outdir/open_reference_output/final_rep_set.fna ]]; then
	cp $outdir/uclust_otu_picking/final_rep_set.fna $outdir/open_reference_output/
	else
	echo "		Final rep set file already present.  Not copying.
	"
	fi

	if [[ ! -f $outdir/open_reference_output/final_otu_map.txt ]]; then
	cp $outdir/uclust_otu_picking/final_otu_map.txt $outdir/open_reference_output
	else
	echo "		Final OTU map already present.  Not copying.
	"
	fi

## Align sequences (16S mode)

	if [[ $mode == "16S" ]]; then

	if [[ ! -f $outdir/open_reference_output/pynast_aligned_seqs/final_rep_set_aligned.fasta ]]; then

	echo "		Aligning sequences.
		(Method: Pynast on $alignseqs_threads cores)
		(Template: $alignment_template)
	"
	`parallel_align_seqs_pynast.py -i $outdir/open_reference_output/final_rep_set.fna -o $outdir/open_reference_output/pynast_aligned_seqs -t $alignment_template -O $alignseqs_threads`
	wait

	else	
	echo "		Alignment file detected.
		($outdir/open_reference_output/pynast_aligned_seqs/final_rep_set_aligned.fasta)
		Skipping sequence alignment step.
	"
	fi
	fi

## Align sequences (ITS mode)

	if [[ $mode == "ITS" ]]; then

	if [[ ! -f $outdir/open_reference_output/mafft_aligned_seqs/final_rep_set_aligned.fasta ]]; then

	echo "		Aligning sequences.
		(Method: Mafft on $alignseqs_threads cores)
		(Template: none)
	"
	`align_seqs.py -i $outdir/open_reference_output/final_rep_set.fna -o $outdir/open_reference_output/mafft_aligned_seqs -m mafft`
	wait

	else	
	echo "		Alignment file detected.
		($outdir/open_reference_output/mafft_aligned_seqs/final_rep_set_aligned.fasta)
		Skipping sequence alignment step.
	"
	fi
	fi

## Filtering alignment (16S mode)

	if [[ $mode == "16S" ]]; then

	if [[  ! -f $outdir/open_reference_output/pynast_aligned_seqs/final_rep_set_aligned_pfiltered.fasta ]]; then
	
	echo "		Filtering sequence alignment.
		Lanemask file: $alignment_lanemask.
	"
	`filter_alignment.py -i $outdir/open_reference_output/pynast_aligned_seqs/final_rep_set_aligned.fasta -o $outdir/open_reference_output/pynast_aligned_seqs/ -m $alignment_lanemask`
	wait

	else
	echo "		Filtered alignment detected.
		($outdir/open_reference_output/pynast_aligned_seqs/final_rep_set_aligned_pfiltered.fasta)
		Skipping alignment filtering step.
	"
	fi
	fi

## Filtering alignment (ITS mode)

	if [[ $mode == "ITS" ]]; then

	if [[  ! -f $outdir/open_reference_output/mafft_aligned_seqs/final_rep_set_aligned_pfiltered.fasta ]]; then
	
	echo "		Filtering sequence alignment.
		Entropy threshold: 0.1
	"
	`filter_alignment.py -i $outdir/open_reference_output/mafft_aligned_seqs/final_rep_set_aligned.fasta -o $outdir/open_reference_output/mafft_aligned_seqs/ -e 0.1`
	wait

	else
	echo "		Filtered alignment detected.
		($outdir/open_reference_output/mafft_aligned_seqs/final_rep_set_aligned_pfiltered.fasta)
		Skipping alignment filtering step.
	"
	fi
	fi

## Make phylogeny in background (16S mode)

	if [[ $mode == "16S" ]]; then

	if [[ ! -f $outdir/open_reference_output/pynast_aligned_seqs/fasttree_phylogeny.tre ]]; then

	echo "		Constructing phylogeny based on sample sequences.
		Method: Fasttree
	"
	( `make_phylogeny.py -i $outdir/open_reference_output/pynast_aligned_seqs/final_rep_set_aligned_pfiltered.fasta -o $outdir/open_reference_output/pynast_aligned_seqs/fasttree_phylogeny.tre` ) &

	else
	echo "		Phylogenetic tree detected.
		($outdir/open_reference_output/pynast_aligned_seqs/fasttree_phylogeny.tre)
		Skipping make phylogeny step.
	"
	fi
	fi

## Make phylogeny in background (ITS mode)

	if [[ $mode == "ITS" ]]; then

	if [[ ! -f $outdir/open_reference_output/mafft_aligned_seqs/fasttree_phylogeny.tre ]]; then

	echo "		Constructing phylogeny based on sample sequences.
		Method: Fasttree
	"
	( `make_phylogeny.py -i $outdir/open_reference_output/mafft_aligned_seqs/final_rep_set_aligned_pfiltered.fasta -o $outdir/open_reference_output/mafft_aligned_seqs/fasttree_phylogeny.tre` ) &

	else
	echo "		Phylogenetic tree detected.
		($outdir/open_reference_output/mafft_aligned_seqs/fasttree_phylogeny.tre)
		Skipping make phylogeny step.
	"
	fi
	fi


## Assign taxonomy (RDP)

	if [[ ! -f $outdir/open_reference_output/rdp_taxonomy_assignment/final_rep_set_tax_assignments.txt ]]; then

	echo "		Assigning taxonomy.
		(Method: RDP Classifier on $taxassignment_threads cores)
	"
	`parallel_assign_taxonomy_rdp.py -i $outdir/open_reference_output/final_rep_set.fna -o $outdir/open_reference_output/rdp_taxonomy_assignment -c $rdp_confidence -r $refs -t $tax --rdp_max_memory $rdp_max_memory -O $taxassignment_threads`
	wait

	else
	echo "		Taxonomy assignments detected.
		($outdir/open_reference_output/rdp_taxonomy_assignment/final_rep_set_tax_assignments.txt)
		Skipping taxonomy assignment step.
	"
	fi


## Make raw otu table

	if [[ ! -f $outdir/open_reference_output/raw_otu_table.biom ]]; then
	
	echo "		Making raw OTU table.
	"
	`make_otu_table.py -i $outdir/open_reference_output/final_otu_map.txt -t $outdir/open_reference_output/rdp_taxonomy_assignment/final_rep_set_tax_assignments.txt -o $outdir/open_reference_output/raw_otu_table.biom`

	else
	echo "		Raw OTU table detected.
		($outdir/open_reference_output/raw_otu_table.biom)
		Moving to final filtering steps.
	"
	fi

## Summarize raw otu table in background

	if [[ ! -f $outdir/open_reference_output/raw_otu_table.summary ]]; then
	( `biom summarize-table -i $outdir/open_reference_output/raw_otu_table.biom -o $outdir/open_reference_output/raw_otu_table.summary` ) &
	fi

## Final filtering steps for OTU tables

## Remove singletons and doubletons

	if [[ ! -f $outdir/open_reference_output/raw_otu_table_no_singletons_no_doubletons.biom ]]; then
	
	`filter_otus_from_otu_table.py -i $outdir/open_reference_output/raw_otu_table.biom -o $outdir/open_reference_output/raw_otu_table_no_singletons_no_doubletons.biom -n 3`
	fi

	if [[ ! -f $outdir/open_reference_output/raw_otu_table_no_singletons_no_doubletons.summary ]]; then
	( `biom summarize-table -i $outdir/open_reference_output/raw_otu_table_no_singletons_no_doubletons.biom -o $outdir/open_reference_output/raw_otu_table_no_singletons_no_doubletons.summary` ) &
	fi
wait

echo "		Workflow steps completed.
"



