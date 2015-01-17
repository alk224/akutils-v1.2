#!/bin/bash

## check whether user had supplied -h or --help. If yes display help 

	if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
		echo "
		This script will recursively change the date last modified
		of every file and folder from within the directory that
		you execute it.  

		This might be useful if your computing resource automatically
		deletes files of a certain age.  However, try not to use
		this script for evil...

		Usage:
		recursive_touch.sh
		"
		exit 0
	fi 

## if more than zero arguments supplied, display usage 

	if [  "$#" -ge 0 ] ;
	then 
		echo "
		Usage:
		recursive_touch.sh
		"
		exit 1
	fi

	echo "
	Touching all files within and below the current directory.
	
	Date last modified will be changed to today.
	"

	find . -exec touch {} \;
