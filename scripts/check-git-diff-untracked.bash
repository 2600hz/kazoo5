#!/bin/bash
# ./check-git-diff.bash [directories]
# directories should be absolute paths

set -e

pushd "$(dirname "$0")" > /dev/null

ROOT=$(readlink -f "$(pwd -P)"/..)
DIRS=()

untracked=0
list=0

while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--list)
            list=1
            shift
            ;;
        *)
            DIRS+=("$1")
            shift
            ;;
    esac
done

set -- "${DIRS[@]}"

diff_untracked_files() {
    files="$(git -C $1 status --porcelain --untracked-files | grep '^\?' | sed -e 's/^\?//g' -e 's/^\? *//g' -e 's/^ *//g' -e 's/ *$//g')"
    if [ -z "$files" ]; then
        return
    fi

    if [ $list -eq 1 ]; then
        untracked=$((untracked+1))
        echo $1
        return
    fi

    echo
    printf "\e[1;36m${0##*/}:\e[1;37m $@ \e[00m\n"
    echo


    for file in $files; do
        untracked=$((untracked+1))
        git -C $1 --no-pager diff --no-index /dev/null $file || true
    done
}

for directory in $@; do
    if [ -d $directory ]; then
        diff_untracked_files "$directory"
    fi
done

exit $untracked
