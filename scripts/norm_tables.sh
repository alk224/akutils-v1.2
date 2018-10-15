#!/usr/bin env
#
# norm_tables.sh - produce normalized tables in parallel from a list of inputs
#  Version 1.1.0 (June 16, 2015)
#
#  Copyright (c) 2014-- Lela Andrews
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
## Define variables
	stdout="$1"
	stderr="$2"
	log="$3"
	tablelist="$4"
	threads="$5"


	for table in `cat $tablelist`; do
	while [ $( pgrep -P $$ | wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
		tabledir=$(dirname $table)
		tablebase=$(basename $table .biom)
		if [[ ! -f $tabledir/${tablebase}_CSS.biom ]]; then
		echo "Normalizing $tablebase by CSS transformation."
		( normalize_table.py -i $table -o $tabledir/${tablebase}_CSS.biom -a CSS ) &
		fi		
	done

	for table in `cat $tablelist`; do
	while [ $( pgrep -P $$ | wc -w ) -ge ${threads} ]; do 
	sleep 1
	done
		tabledir=$(dirname $table)
		tablebase=$(basename $table .biom)
		if [[ ! -f $tabledir/${tablebase}_DESeq2.biom ]]; then
		echo "Normalizing $tablebase by DESeq2 transformation."
		( normalize_table.py -i $table -o $tabledir/${tablebase}_DESeq2.biom -a DESeq2 ) &
		fi
		
	done

exit 0
