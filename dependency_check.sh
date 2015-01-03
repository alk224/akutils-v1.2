#!/bin/bash

## Check for required dependencies:
echo "
		Checking for required dependencies...
"

scriptdir="$( cd "$( dirname "$0" )" && pwd )"


for line in `cat $scriptdir/eqw_resources/dependencies.list`; do
	dependcount=`command -v $line | wc -w`
	if [[ $dependcount == 0 ]]; then
	echo "
		$line is not in your path.  Dependencies not satisfied.
		Exiting.
	"
	exit 1
	else
	if [[ $dependcount -ge 1 ]]; then
	echo "		$line is in your path..."
	fi
	fi
done
echo "
		All dependencies satisfied.  Proceeding...
"


# command -v smalt >/dev/null 2>&1 || { echo >&2 "I require smalt but it's not installed.  Aborting."; exit 1; }
## 
## hash print_qiime_config.py 2>/dev/null || { echo >&2 "I require foo but it's not installed.  Aborting."; }
##
