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

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

## Move to repo directory and perform git pull
	cd $repodir
	echo "
${bold}Performing fresh git pull of akutils repository.${normal}
	"
	git pull
	wait

	echo "
${bold}git pull command complete.${normal}
If new functions were added, you may need to either open a new terminal window,
or issue the following command:

${underline}source ~/.bashrc${normal}
	"

exit 0
