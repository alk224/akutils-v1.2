#!/usr/bin/env bash
#
#  dependency_check_slave.sh - Test system for commands used in akutils workflows
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

## Loop through full dependency list
echo "
Checking for required dependencies...
"
if [[ -f "$repodir/akutils_resources/akutils.dependencies.result" ]]; then
rm $repodir/akutils_resources/akutils.dependencies.result
fi

for line in `cat $repodir/akutils_resources/akutils.dependencies.list | cut -f1`; do
#	scriptuse=`grep "$line" $scriptdir/akutils_resources/akutils.dependencies.list | cut -f2`
	titlecount=`echo $line | grep "#" | wc -l`
	if [[ "$titlecount" == 1 ]]; then
	echo "" >> $repodir/akutils_resources/akutils.dependencies.result
	grep "$line" $repodir/akutils_resources/akutils.dependencies.list >> $repodir/akutils_resources/akutils.dependencies.result
	elif [[ $titlecount == 0 ]]; then
	dependcount=`command -v $line 2>/dev/null | wc -w`
	if [[ "$dependcount" == 0 ]]; then
	echo "$line	FAIL" >> $repodir/akutils_resources/akutils.dependencies.result
	else
	if [[ "$dependcount" -ge 1 ]]; then
	echo "$line	pass" >> $repodir/akutils_resources/akutils.dependencies.result
	fi
	fi
	fi
done
echo "" >> $repodir/akutils_resources/akutils.dependencies.result

## Count results and print to screen
	dependencycount=`grep -v "#" $repodir/akutils_resources/akutils.dependencies.list | sed '/^$/d' | wc -l`
	passcount=`grep "pass" $repodir/akutils_resources/akutils.dependencies.result | wc -l`
	failcount=`grep "FAIL" $repodir/akutils_resources/akutils.dependencies.result | wc -l`

if [[ "$failcount" == 0 ]]; then
	sed -i "1i No failures!  akutils workflows should run OK." $repodir/akutils_resources/akutils.dependencies.result
elif [[ "$failcount" -ge 1 ]]; then
	sed -i "1i Some dependencies are not in your path.  Correct failures and rerun\ndependency check." $repodir/akutils_resources/akutils.dependencies.result
fi

sed -i "1i Dependency check results for akutils:\n\nTested $dependencycount dependencies\nPassed: $passcount/$dependencycount\nFailed: $failcount/$dependencycount" $repodir/akutils_resources/akutils.dependencies.result

echo "Test complete."
head -7 $repodir/akutils_resources/akutils.dependencies.result | tail -6
echo "For more detailed results, execute:
akutils check_result
"

exit 0
