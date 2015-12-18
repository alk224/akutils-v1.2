#!/usr/bin env

## parse_cats.sh to make temp categories file

## Trap function on exit.
function finish {
if [[ -f $mapcatstemp ]]; then
	rm $mapcatstemp
fi
if [[ -f $filtertemp ]]; then
	rm $filtertemp
fi

}
trap finish EXIT


## Define variables
	stdout="$1"
	stderr="$2"
	mapfile="$3"
	cats="$4"
	catlist="$5"
	randcode="$6"
	tempdir="$7"

	mapcatstemp="$tempdir/${randcode}_mapping_categories.temp"
	filtertemp="$tempdir/${randcode}_cats_filter.temp"

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

## Parse mapping file categories and create temp file
	mapcats=$(mapcats.sh $mapfile | grep -e "^Categories: " | sed 's/Categories: //')
	IN=$mapcats
	OIFS=$IFS
	IFS=','
	arr=$IN

	echo > $mapcatstemp
	for x in $arr; do
		echo $x >> $mapcatstemp
	done
	IFS=$OIFS
	sed -i '/^\s*$/d' $mapcatstemp

## Filter any erroneous categories
	for line in `cat $catlist`; do
		grep $line $mapcatstemp >> $filtertemp
	done
cat $filtertemp > $catlist

exit 0
