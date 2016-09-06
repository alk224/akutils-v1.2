#!/usr/bin/env bash
#
#  akutils update - akutils updating script
#
#  Version 0.0.1 (June 27, 2016)
#
#  Copyright (c) 2015-2016 Andrew Krohn
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

## Define variables.
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=$(dirname $scriptdir)
	workdir=$(pwd)
	tempdir="$repodir/temp"
	homedir=`echo $HOME`

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

## Move to akutils repo directory and perform git pull
	cd $repodir
		if [[ -f "akutils_resources/primer_sequences.bak" ]]; then
		primerbak="yes"
		rm akutils_resources/primer_sequences.txt
		fi
	echo "
${bold}Performing fresh git pull of akutils repository.${normal}
	"
	git pull
		if [[ "$primerbak" == "yes" ]]; then
		cp akutils_resources/primer_sequences.bak akutils_resources/primer_sequences.txt
		fi
	wait

## If present, update QIIME_test_data_16S repo
	if [[ -d "$homedir/QIIME_test_data_16S" ]]; then
	cd $homedir/QIIME_test_data_16S
	echo "
${bold}Performing fresh git pull of QIIME_test_data_16S repository.${normal}
	"
	git pull
	wait
	fi

## If present, update akutils_ubuntu_installer repo
	if [[ -d "$homedir/akutils_ubuntu_installer" ]]; then
	cd $homedir/akutils_ubuntu_installer
	echo "
${bold}Performing fresh git pull of akutils_ubuntu_installer repository.${normal}
	"
	git pull
	wait
	fi

## If present, update akutils_RADseq_utility repo
	if [[ -d "$homedir/akutils_RADseq_utility" ]]; then
	cd $homedir/akutils_RADseq_utility
	echo "
${bold}Performing fresh git pull of akutils_RADseq_utility.${normal}
	"
	git pull
	wait
	fi

## Replace user-defined sequences from backed up primer database if necessary
	if [[ -f "$repodir/akutils_resources/primer_sequences.bak" ]]; then
	sort $repodir/akutils_resources/primer_sequences.txt $repodir/akutils_resources/primer_sequences.bak | uniq -u >> $repodir/akutils_resources/primer_sequences.txt
	fi

	echo "
${bold}git pull command(s) complete.${normal}
If new functions were added, you may need to either open a new terminal window,
or issue the following command:

${underline}source ~/.bashrc${normal}
	"

exit 0
