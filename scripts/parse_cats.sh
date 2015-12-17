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
	log="$3"
	mapfile="$4"
	cats="$5"
	catlist="$6"
	randcode="$7"
	tempdir="$8"

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
echo "
catlist:"
cat $catlist

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
echo "
mapcatslist:"
cat $mapcatstemp

## Filter any erroneous categories
	for line in `cat $catlist`; do
		grep $line $mapcatstemp >> $filtertemp
	done
cat $filtertemp > $catlist
echo "
catlist:"
cat $catlist

exit 0
