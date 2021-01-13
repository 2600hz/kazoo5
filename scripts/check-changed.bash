#!/bin/bash
# ./check-changed [directories]
# directories should be absolute paths

set -e

pushd "$(dirname "$0")" > /dev/null

ROOT=$(readlink -f "$(pwd -P)"/..)

echo "Checking for any changed files" >&2
echo "ROOT=${ROOT}" >&2
echo >&2

function get_changed {
    base_branch=$(<$ROOT/.base_branch)
    [ -f $1/.base_branch ] && base_branch=$(<$1/.base_branch);
    echo "- checking $1 (base_branch=${base_branch})" >&2
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
