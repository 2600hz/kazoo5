#!/bin/bash

set -e

pushd "$(dirname "$0")" >/dev/null

ROOT=$(readlink -f "$(pwd -P)"/..)

errors=0
erls=""

# grep for lager:[word]("[A-Z][a-z]...
# ignores log lines with a first word in all caps like HELO or EHLO in fax_smtp
if [ -z "$1" ]; then
    echo "no files to check for logging"
    exit 0
else
    lager_files="$1"
fi

#for ERL in $(egrep -rl "lager:\w+\(\"[A-Z]{1}[a-z]" $lager_files); do
for ERL in $(egrep -rl "lager:\w+\(\"[A-Z]{1}[a-z]" $lager_files); do
    # sed captures lager:[word](" as \1
    # captures A-Z as \2
    # captures the rest of the line as \3
    # changes \2 to the lowercase version using \l
    sed -E -i 's/(lager:[[:alpha:]]+\(")([A-Z]{1})([a-z].+)/\1\l\2\3/g' $ERL
    errors=1
    erls="$erls$ERL:1: log lines starting with capital letters"$'\n'
done

if [ $errors = 1 ]; then
    echo "$erls"
fi

popd >/dev/null

exit $errors
