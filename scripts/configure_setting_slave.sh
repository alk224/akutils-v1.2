#!/usr/bin/env bash
#
#  configure_setting_slave.sh - Configure individual akutils settings.
#
#  Version 1.0.0 (February, 01, 2015)
#
#  Copyright (c) 2015-- Lela Andrews
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

## Find scripts location and set variables
	scriptdir="$( cd "$( dirname "$0" )" && pwd )"
	repodir=`dirname $scriptdir`
	workdir=$(pwd)
	stdout="$1"
	stderr="$2"
	randcode="$3"
	variable="$4"
	setting="$5"

	bold=$(tput bold)
	normal=$(tput sgr0)
	underline=$(tput smul)

## Get config file
	config=$(bash $scriptdir/config_id.sh)
	configdir=$(dirname $config)

## Check if global or local
	if [[ "$configdir" == "." ]]; then
	globallocal="local"
	else
	globallocal="global"
	fi

## Check if supplied variable is valid or exit
	variabletest=$(grep -v "#" $config | grep $variable)
	if [[ -z "$variabletest" ]]; then
	echo "
Invalid configurable variable supplied. You supplied $variable.
Exiting.
	"
	exit 1
	fi

## Get existing variable setting and description
	currentsetting=$(grep -v "#" $config | grep $variable | cut -f2)
	description=$(grep "#" $config | grep $variable | cut -f3)

## Offer to exit before changing setting
	echo "
Change akutils variable setting in your ${bold}${globallocal}${normal} config file.
Config file: ${config}
Variable: ${bold}${variable}${normal}
Description: $description
Current setting: ${bold}${currentsetting}${normal}
New setting: ${bold}${setting}${normal}

Type enter to change the setting, or \"n\" to cancel.
Change setting?"
	read change

	if [[ "$change" == "n" ]]; then
	echo "
Cancelling.  Variable setting not changed.
	"
	exit 0
	fi

## Change variable setting

	sed -i -e "s@^$variable\t$currentsetting@$variable\t$setting@" $config

	echo "Variable setting ${bold}${variable}${normal} changed.
	"

exit 0
