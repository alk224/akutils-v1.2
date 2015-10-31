#!/usr/bin/env bash
## Logging slave script
## Author: Andrew Krohn
## Date: 2015-10-29
## License: MIT
## Version 0.0.1

## Define variables from inputs
stdout="$1"
stderr="$2"
log="$3"

## Logging function
echo "***** stdout:" >> $log
cat $stdout >> $log
echo "***** stderr:" >> $log
cat $stderr >> $log
echo "" >> $log

exit 0
