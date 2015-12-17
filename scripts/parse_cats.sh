#!/usr/bin env

## parse_cats.sh to make temp categories file


## Define variables
	stdout="$1"
	stderr="$2"
	log="$3"
	mapfile="$4"
	cats="$5"
	catlist="$6"

## Parse categories and create temp file
	IN=$cats
	OIFS=$IFS
	IFS=','
	arr=$IN

	echo > $catlist
	for x in $arr; do
		echo $x >> $catlist
	done
	IFS=$OIFS
	sed -i '/^\s*$/d' $catlist

exit 0
