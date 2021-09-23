#!/bin/bash

# turn off `e` so if git command failed we can print the appropiate error and exit.
# set +e
pushd "$(dirname "$0")" > /dev/null

ROOT=$(readlink -f "$(pwd -P)"/..)

# safety checks
[ -z "${BASE_BRANCH}" ] && echo "BASE_BRANCH is required but is not set in environment. Base branch example: origin/5.0" && exit 1

_release_branch=$(echo ${BASE_BRANCH} | sed 's|origin/||g')
_release_major=$(echo ${_release_branch} | egrep -o '^[0-9]')
_release_minor=$(echo ${_release_branch} | egrep -o '^[0-9]+\.[0-9]+' | sed -E 's/^[0-9]+\.//g')

echo "BASE_BRANCH: ${BASE_BRANCH}"
echo "Base major version: ${_release_major}"
echo "Base minor version: ${_release_minor}"
echo

if [ -z "${_release_major}" ] || [ -z "${_release_minor}" ]; then
    echo "This script is designed to run in a release branch with branch name like {MAJOR}.{MINOR} for example 5.0"
    echo "but it cannot find base major and minor version from current BASE_BRANCH ${BASE_BRANCH}"
    exit 1
fi

# warnings
[ -z "${CIRCLE_PROJECT_REPONAME}" ] && echo "CIRCLE_PROJECT_REPONAME is not set, this script is designed to run in CI"
_target_repo="$(echo $CIRCLE_PROJECT_REPONAME | sed 's/kazoo-//g' | sed 's/-/_/g')"

for app in `ls ${ROOT}/applications` ; do
    _path="${ROOT}/applications/${app}"

    # skip non directories
    [ ! -d "${_path}" ] && continue
    # skip current ci building repo
    [ -n "${_target_repo}" ] && [ "${app}" = "${_target_repo}" ] && continue

    echo ":: Checking ${app} repo for its latest tag..."

    pushd ${_path} > /dev/null

    _current_branch=$(git rev-parse --abbrev-ref HEAD)
    [ -z "${_current_branch}" ] && echo 'can not find current branch, is this a git repo?' && exit 1

    if [ "${_current_branch}" != "${_release_branch}" ]; then
        echo "Current ${app} branch ${_current_branch} is not matching base branch ${BASE_BRANCH}"
        echo "Check '.base_branch' in root of repo in branch ${_current_branch}."
        echo "DO NOT FORGET to remove trailing space or new line at the end of the file."
        exit 1
    fi

    _latest_tag="$(git describe --tags --abbrev=0)"

    if [ -z "${_latest_tag}" ]; then
        echo "WARNING: cannot find the latest tag for ${app} from branch ${_current_branch}."
        echo "         Pretending this is the first tag/release"
        continue
    fi

    # The reason we check this major/minor thing is that some repo (like appex_client)
    # can report false release tags like 4.3.0 or something (for example if you are on master branch)
    # so we force check this to make sure eveyone are on the right branch and tag.
    # NOTE: check latest tag major/minor is not less than the base branch version we are building.
    _latest_major=$(echo ${_latest_tag} | egrep -o '^[0-9]+')
    _latest_minor=$(echo ${_latest_tag} | egrep -o '^[0-9]+\.[0-9]+' | sed -E 's/^[0-9]+\.//g')
    if [ -z "${_latest_major}" ] || [ -z "${_latest_minor}" ]; then
        echo "Cannot find ${app}:${_latest_tag} current major or minor version, are you on a release branch?"
        echo
        echo "This script is designed to run in a release branch with branch name like {MAJOR}.{MINOR} for example 5.0"
        echo "but it cannot find base major and minor version from current branch ${_current_branch}"
        exit 1
    fi
    if [ ${_latest_major} -lt ${_release_major} ]; then
        echo "Latest ${app}:${_latest_tag} major version ${_latest_major} is not greater than base branch ${BASE_BRANCH} release major ${_release_major}"
        exit 1
    fi
    if [ "${_latest_minor}" -lt "${_release_minor}" ]; then
        echo "Latest ${app}:${_latest_tag} minor version ${_latest_minor} is not greater than base branch ${BASE_BRANCH} release minor ${_release_minor}"
        exit 1
    fi
    echo "found latest tag '${_latest_tag}', checking out"
    git checkout ${_latest_tag}
    # echo "make a pristine environment for the ${app}"
    git clean -x -d -f
    popd > /dev/null
done
