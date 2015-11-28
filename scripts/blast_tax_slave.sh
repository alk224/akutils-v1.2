#!/usr/bin/env bash
#
#  blast_tax_slave.sh - assign taxonomy with BLAST in QIIME
#
#  Version 1.0.0 (November, 27, 2015)
#
#  Copyright (c) 2015 Andrew Krohn
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
set -e

## Set variables
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=`dirname $scriptdir`
	workdir=$(pwd)
	stdout="$1"
	stderr="$2"
	log="$3"
	cores="$4"
	taxmethod="$5"
	taxdir="$6"
	otupickdir="$7"
	refs="$8"

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)
	res1=$(date +%s.%N)

## Log and run command
	echo "Assigning taxonomy.
Input sequences: ${bold}$repsetcount${normal}
Method: ${bold}$taxmethod${normal} on ${bold}$cores${normal} cores.
	"
	echo "Assigning taxonomy ($taxmethod):
Input sequences: $repsetcount" >> $log
	date "+%a %b %d %I:%M %p %Z %Y" >> $log
	echo "
	parallel_assign_taxonomy_blast.py -i $otupickdir/merged_rep_set.fna -o $taxdir -r $refs -t $tax -O $cores
	" >> $log
	parallel_assign_taxonomy_blast.py -i $otupickdir/merged_rep_set.fna -o $taxdir -r $refs -t $tax -O $cores 1>$stdout 2>$stderr
	bash $scriptdir/log_slave.sh $stdout $stderr $log
	wait






exit 0
