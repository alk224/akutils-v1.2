#!/usr/bin/env bash
#
#  SCRIPT NAME - SHORT DESCRIPTION
#
#  Version 1.0.0 (MONTH, 99, 2015)
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
## Trap function on exit.
function finish {

if [[ -f $tempfile1 ]]; then
	rm $tempfile1
fi
}
trap finish EXIT

## Set variables
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=$(dirname $scriptdir)
	workdir=$(pwd)
	tempdir="$repodir/temp"
	randcode=`cat /dev/urandom |tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1` 2>/dev/null

	tempfile1="$tempdir/$randcode.tempfile1.temp"

	arg1="$1"
	arg2="$2"

	date0=$(date)

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

## Check whether user had supplied -h or --help. If yes display help 
	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
	less $repodir/docs/template.help
		exit 0	
	fi

## If other than SOMENUMBEROF arguments supplied, display usage
	if [[ "$#" -ne 2 ]]; then 
	cat $repodir/docs/template.usage
	fi

exit 0
