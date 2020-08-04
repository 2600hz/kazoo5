#!/bin/bash
# ./check-git-diff.bash [directories]
# directories should be absolute paths

set -e

pushd "$(dirname "$0")" > /dev/null

ROOT=$(readlink -f "$(pwd -P)"/..)

diff_untracked_files() {
    files="$(git -C $1 status --porcelain --untracked-files | grep '^\?' | sed -e 's/^\?//g' -e 's/^\? *//g' -e 's/^ *//g' -e 's/ *$//g')"
    if [ -z "$files" ]; then
        return
    fi

    echo
    printf "\e[1;36m${0##*/}:\e[1;37m $@ \e[00m\n"
    echo

    for file in $files; do
        git -C $1 --no-pager diff --no-index /dev/null $file || true
    done
}

for directory in $@; do
    if [ -d $directory ]; then
        diff_untracked_files "$directory"
    fi
done
