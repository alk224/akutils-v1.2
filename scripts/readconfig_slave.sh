#!/usr/bin/env bash
#
#  readconfig_slave.sh - Print akutils configured variables to screen
#
#  Version 1.0.0 (November, 13, 2015)
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
## Find scripts location
scriptdir="$( cd "$( dirname "$0" )" && pwd )"
repodir=`dirname $scriptdir`
workdir=$(pwd)
configfile="$1"
globallocal="$2"
stdout="$3"
stderr="$4"
randcode="$5"

## Check config file against blank config file to determine if any new variables are available
	grep -v "#" $configfile | sed '/^$/d' > $repodir/temp/$randcode_config
	grep -v "#" $repodir/akutils_resources/blank_config.config | sed '/^$/d' > $repodir/temp/$randcode_template

## Read config file variables and print to screen
	echo "
Reading akutils configurable fields from $globallocal config file.
$configfile
	"
	echo ""
	grep -v "#" $configfile | sed '/^$/d'
	echo ""

exit 0
