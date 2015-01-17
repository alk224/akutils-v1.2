#!/bin/bash

## Interactive tool to generate a slurm file for use on monsoon

set -e

## check whether user had supplied -h or --help. If yes display help 

	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
		echo "
		slurm_builder.sh

		This script helps a user to build a slurm file appropriate
		for their job.  It will be appropriate for use on the
		monsoon cluster at NAU.

		Usage:
		slurm_builder.sh
		"
		exit 0	
	fi

## If other than two arguments supplied, display usage 

	if [  "$#" -ne 0 ]; then 

		echo "
		Usage:
		slurm_builder.sh
		"
		exit 1
	fi
echo skipped
