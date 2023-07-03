#!/bin/bash
# ./check-changed [directories]
# directories should be absolute paths

set -e

pushd "$(dirname "$0")" > /dev/null

ROOT=$(readlink -f "$(pwd -P)"/..)

_ci_debug() {
    msg="$1"
    if [ -n "${DEBUG}" ]; then
        echo "${msg}" >&2
    elif [ -n "${CIRCLECI}" ]; then
        echo "${msg}" >&2
    fi
}

_ci_debug "Checking for any changed files"
_ci_debug "ROOT=${ROOT}"
_ci_debug

function get_changed {
    base_branch=$(<$ROOT/.base_branch)
    [ -f $1/.base_branch ] && base_branch=$(<$1/.base_branch);
    _ci_debug "- checking $1 (base_branch=${base_branch})"
    diff=""
    for file in $(git -C $1 --no-pager diff --name-only HEAD $base_branch); do
        diff+=" $1/$file"
    done
    echo "$diff"
}

changed=""
for directory in $@; do
    if [ -d $directory ]; then
        dir_change=$(get_changed "$directory")
        if [ -n "$dir_change" ]; then
            changed+=" $dir_change"
        fi
    fi
done

echo "$changed"
