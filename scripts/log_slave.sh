#!/usr/bin/env bash
## Logging slave script
## Author: Lela Andrews
## Date: 2015-10-29
## License: MIT
## Version 0.0.1
#

## Define variables from inputs
	stdout="$1"
	stderr="$2"
	log="$3"

## Logging function
	echo "***** stdout:" >> $log
	if [[ ! -s $stdout ]]; then
	echo "No output to log from stdout.
	" >> $log
	else
	cat $stdout >> $log
	echo "" >> $log
	fi

	echo "***** stderr:" >> $log
	if [[ ! -s $stderr ]]; then
	echo "No output to log from stderr.
	" >> $log
	else
	cat $stderr >> $log
	echo "" >> $log
	fi
	echo > $stdout
	echo > $stderr

exit 0
