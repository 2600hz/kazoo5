#!/bin/bash

set -e

pushd "$(dirname "$0")/.." >/dev/null

errors=0
erls=""

# grep for lager:[word]("[A-Z][a-z]...
# ignores log lines with a first word in all caps like HELO or EHLO in fax_smtp
if [ -z "$1" ]; then
    echo "no files to check for logging"
    exit 0
fi

# reading lines and redirect to while to avoid word splitting in file paths
MATCHES="$(grep -Erl "lager:\w+\(\"[A-Z]{1}[a-z]" "${@}" || exit 0)"
while IFS='' read -r ERL; do
    # lager:critical_unsafe has _ in it
    # sed captures lager:[word](" as \1
    # captures A-Z as \2
    # captures the rest of the line as \3
    # changes \2 to the lowercase version using \l
    if [ -n "$ERL" ]; then
        sed -r -i 's/(lager:[a-z_]+\(")([A-Z]{1})([a-z].+)/\1\l\2\3/g' "${ERL}"
        errors=1
        erls="$erls$ERL:1: log lines starting with capital letters"$'\n'
    fi
done <<< "${MATCHES}"

if [ $errors = 1 ]; then
    echo "$erls"
fi

popd >/dev/null

exit $errors
