#!/usr/bin/env bash
#
#  akutils primer_file - Generate a file of primer sequences for use with strip_primers command
#
#  Version 1.0.0 (June 29, 2016)
#
#  Copyright (c) 2014-2016 Andrew Krohn
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

## Define variables.
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=`dirname $scriptdir`
	workdir=$(pwd)
	stdout="$1"
	stderr="$2"
	randcode="$3"
	config="$4"
	list="$5"

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

	outdir=$workdir/strip_primers_out
	date0=$(date +%Y%m%d_%I%M%p)
	res1=$(date +%s.%N)

## If "list" supplied, display contents of primer_file.txt if present.
	if [[ "$list" == "list" ]]; then
		if [[ -f "primer_list.txt" ]]; then
		echo "
Contents of local primer file (primer_file.txt):"
		cat primer_file.txt
		echo ""
		else
		echo "
No local primer file is present. Run the akutils primer_file command with no
argument to generate a new one. Exiting.
		"
		fi
	fi

## Locate local primer file or not.
	if [[ -f "primer_file.txt" ]]; then
	mode="yes"
	else
	mode="no"
	fi

## Enter interactive mode
	echo "
Starting primer_file interactive mode to produce or edit a primer file."
	if [[ "$mode" == "yes" ]]; then
	echo "
Primer file present. Editing existing file.
Contents:"
	cat primer_file.txt
	echo ""
	elif [[ "$mode" == "no" ]]; then
	echo "
No primer file is present. Building new file.
	"
	fi

## Editing mode.
#	if [[ "$mode" == "yes" ]]; then
	echo "Would you like to add or remove a sequence?"
	read addremove

	if [[ "$addremove" == "add" || "$addremove" == "remove" ]]; then
	if [[ "$addremove" == "add" ]]; then
	echo "OK. Here is a list of primers that I know about:
	"
	cat $repodir/akutils_resources/primer_sequences.txt
	echo "
You can enter one of the above primers by name (must be exactly right) or enter
a different primer name if yours isn't listed. I will prompt you to enter the
sequence next."
	read primername
		nametest=$(grep -w "$primername" $repodir/akutils_resources/primer_sequences.txt 2>/dev/null | wc -l)
		if [[ "$nametest" == "1" ]]; then
		primer1=$(grep -w "$primername" $repodir/akutils_resources/primer_sequences.txt | cut -f1)
		primer2=$(grep -w "$primername" $repodir/akutils_resources/primer_sequences.txt | cut -f2)
		printf "\n${primer1}\t${primer2}\n" >> primer_file.txt
		sed -i "/^$/d" primer_file.txt
		echo "
Primer $primername has been added to your primer file. This file now contains:"
		cat primer_file.txt
		echo ""
		exit 0

		elif  [[ "$nametest" == "0" ]]; then
		echo "
You entered: $primername

I don't know this primer. Please enter the sequence exactly and I will add it to
your file and to my database so you can easily enter it next time. It is OK to
use IUPAC degenerate code."
		read primerseq
		if [[ -z "$primerseq" ]]; then
		echo "
No sequence entered. No changes made. Exiting.
		"
		sed -i "/^$/d" primer_file.txt
		exit 0
		fi
		printf "\n${primername}\t${primerseq}\n" >> primer_file.txt
		sed -i "/^$/d" primer_file.txt
		printf "\n${primername}\t${primerseq}\n" >> $repodir/akutils_resources/primer_sequences.txt
		sed -i "/^$/d" $repodir/akutils_resources/primer_sequences.txt
		cp $repodir/akutils_resources/primer_sequences.txt $repodir/akutils_resources/primer_sequences.bak
		echo "
Primer $primername has been added to your primer file. This file now contains:"
		cat primer_file.txt
		echo ""
		exit 0
		fi

	elif [[ "$addremove" == "remove" ]]; then

	echo "
Remove sequence from file (file) or database (db)?"
		read filedb

	if [[ "$filedb" == "file" ]]; then
	echo "OK. Enter the name of the primer you would like to remove exactly as it appears
in your primer file:
	"
	read primername
	sed -i "/$primername/d" primer_file.txt
	sed -i "/^$/d" primer_file.txt
	echo "
Primer $primername has been removed from your primer file. This file now contains:"
	cat primer_file.txt
	echo ""
	exit 0

	elif [[ "$filedb" == "db" ]]; then
	echo "OK. Here is the current list of primers in the database:
	"
	cat $repodir/akutils_resources/primer_sequences.txt
	echo ""
	echo "Enter the name of the primer you would like to remove exactly as it appears
in your primer database:
	"
	read primername
	sed -i "/$primername/d" $repodir/akutils_resources/primer_sequences.txt
	cp $repodir/akutils_resources/primer_sequences.txt $repodir/akutils_resources/primer_sequences.bak
	echo "
Primer $primername has been removed from your primer database. This file now contains:"
	cat $repodir/akutils_resources/primer_sequences.txt
	echo ""
	exit 0

	else
	echo "
Invalid option. Exiting.
	"
	exit 1
	fi

	elif [[ "$addremove" == "exit" ]]; then
	echo "OK. Requested to exit.
	"
	exit 0
	fi

	else	
	echo "
Invalid option. Exiting.
	"
	exit 1
	fi

exit 0
