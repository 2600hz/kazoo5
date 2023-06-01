#!/bin/bash

# A script to checkout apps (and core if required) to latest tag or a suitable git ref
# according to manifests.
#
# The scripts only supports tags or fix branch/tags and everything must starts with a
# valid semver for tag and fix semver for fix branch/tag.
#
# This simply just search for list of apps under the app directory (base on project type)
# and then if this is a simple tag, runs git describe to find the latest tag in base branch
# and then checks out.
#
# For fix, either fix tag, fix release branch, fix branch/pr, this clones and runs the
# scripts from build-manifests and build-manifest-overrides to resolve the apps
# version/refs an checks out anything that it can find, for those that does not exists in
# manifests files, it uses latest tag from their base branch.
#
# This tries to preserve the old behavior of this script which was check out apps to their
# latest base branch. The old script was being called by CircleCI Orb ONLY during
# rag/release.
#
# But to support the fix branch the functionality is now extend to support resolving the
# versions. As a workaround this script is being called during compile/compile-test ONLY
# CI. For local testing and setup simply call this script directly with proper options.
#
# If you don't specify project name and version/ref, it uses latest tags of base branch.
#
# - `-r|-repo-name`: The name of project must be its GitHub repository name
# - `-v|-repo-version`: The project version is either a tag/release that starts with semver or
#   a fix branch name that starts with a valid semver
#
#   Valid options:
#     5.1.1
#     5.1.1.1
#     5.1.1.1-lol
#   Non valid options:
#     master
#     main
#     KZOO-111
#     lol-5.1.1.1
#     5.1a.1
#     really-anything-else-that-is-not-start-with-a_valid_semver_:)
#
# Examples:
#
# To resolve apps base on specific version of kazoo-crossbar:
#   ./scripts/checkout_kapps_latest_tag.sh -v 5.1.27.1 -r kazoo-crossbar
#
# To resolve apps to their latest base branch:
#   ./scripts/checkout_kapps_latest_tag.sh -b origin/5.1

set -e -o pipefail

echo '██   ██  █████  ███████  ██████   ██████'
echo '██  ██  ██   ██    ███  ██    ██ ██    ██'
echo '█████   ███████   ███   ██    ██ ██    ██'
echo '██  ██  ██   ██  ███    ██    ██ ██    ██'
echo '██   ██ ██   ██ ███████  ██████   ██████'
echo ''
echo '███    ███  █████  ███    ██ ██ ███████ ███████ ███████ ████████  ██████'
echo '████  ████ ██   ██ ████   ██ ██ ██      ██      ██         ██    ██    ██'
echo '██ ████ ██ ███████ ██ ██  ██ ██ █████   █████   ███████    ██    ██    ██'
echo '██  ██  ██ ██   ██ ██  ██ ██ ██ ██      ██           ██    ██    ██    ██'
echo '██      ██ ██   ██ ██   ████ ██ ██      ███████ ███████    ██     ██████'
echo

pushd "$(dirname "$0")/.." > /dev/null || exit 1
ROOT="$(pwd -P)"
export ROOT

CHECKOUT_WAS_HERE="${ROOT}/.checkout_kapps_was_here"

# option vars
_base_branch=
_manifests_root_path="${ROOT}/../manifests"
_project_name="${CIRCLE_PROJECT_REPONAME:-${GITHUB_REPOSITORY}}"
_project_ref="${CIRCLE_TAG:-${CIRCLE_BRANCH:-${GITHUB_REF_NAME}}}"
while [ $# -gt 0 ]; do
    arg="${1}"
    case ${arg} in
        -b|-base-branch)
            if [ -n "$2" ]; then
                _base_branch="${2}"
                shift
            fi
            ;;
        -ci)
            CI=true
            ;;
        -m|-manifests-root-path)
            if [ -n "$2" ]; then
                _manifests_root_path="${2}"
                shift
            fi
            ;;
        -r|repo-name)
            if [ -n "$2" ]; then
                _project_name="${2}"
                shift
            fi
            ;;
        -v|repo-version)
            if [ -n "$2" ]; then
                _project_ref="${2}"
                shift
            fi
            ;;
        *)
            ;;
    esac
    shift
done
unset arg

# main global vars
_release_branch=
_release_major=
_release_minor=

_project_type=
_apps_dir="${ROOT}/applications"
_pkg_name=
_meta_pkg=

_is_project_fix_branch=
_is_project_tag=

_clean_after_checkout="${CLEAN_AFTER}"

# 1) What if we get no src repo/vsn option and we have to find out the latest tag from git describe
# and the latest tag in 5.2 branch was a fix branch/pr/tag for one of app?
# 2) What if this happens when there is src repo/vsn?
# 3) can we extend this to support master or non-release branches? Like dependent PRs?
is_fix_branch() {
    if echo "${1}" | grep -Eo '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' >/dev/null; then
        echo true
    fi
}

is_tag() {
    if echo "${1}" | grep -Eo '^[0-9]+\.[0-9]+\.[0-9]+$' >/dev/null; then
        echo true
    fi
}

valid_vsn_examples() {
    echo "Valid options:"
    echo "  5.1.1"
    echo "  5.1.1.1"
    echo "  5.1.1.1-lol"
    echo "Non valid options:"
    echo "  master"
    echo "  main"
    echo "  KZOO-111"
    echo "  lol-5.1.1.1"
    echo "  5.1a.1"
    echo "  really-anything-else-that-is-not-start-with-a_valid_semver_:)"
}

valid_base_examples() {
    echo "Valid value examples:"
    echo "  origin/5.0"
    echo "  origin/5.1"
    echo
    echo "Non valid value examples:"
    echo "  5.1"
    echo "  master"
    echo "  origin/master"
    echo "  origin/lol"
}

if [ -n "${CI}" ]; then
    if [ -f "${CHECKOUT_WAS_HERE}" ]; then
        echo "Already ran $0, skipping..."
        exit 0
    fi

    if [ -z "${_project_name}" ]; then
        echo "Required repository name variable is not defined You can set it as environment variables or use option"
        echo
        echo
        echo "For example in CircleCI the variable is set to:"
        echo "  CIRCLE_PROJECT_REPONAME=kazo-crossbar"
        echo
        echo "In Github Actions, the variable is set to:"
        echo "  GITHUB_REPOSITORY=2600hz/kazoo-crossbar"
        echo
        echo "Or you can just simply set option:"
        echo "  $0 -r kazoo-crossbar <other_options>"
        exit 1
    fi
    # clean repo name under github actions
    _project_name="${_project_name#2600hz/}"

    if [ -z "${_project_ref}" ]; then
        echo "Required repository ref variable is not defined You can set it as environment variables or use option"
        echo "Ref is either a tag name or a branch name and must be start with a valid Semver format:"
        echo
        valid_vsn_examples
        echo
        echo
        echo "For example in CircleCI on tag the variable is set to:"
        echo "  CIRCLE_TAG=5.1.27"
        echo "For PRs and branch push:"
        echo "  CIRCLE_BRANCH=5.1.27.1-always-fixing-something-for-love-of-our-customer"
        echo
        echo "In Github Actions, the variable is set to:"
        echo "  GITHUB_REF_NAME=5.1.27.1-KZOO-101"
        echo
        echo "Or you can just simply set option:"
        echo "  $0 -v 5.1.27.1 <other_options>"
        exit 1
    fi

    if [ -z "$(is_fix_branch "${_project_ref}")" ] && [ -z "$(is_tag "${_project_ref}")" ]; then
        echo "This is not a release/tag or a fix branch/tag, skipping..."
        exit 0
    fi
    _clean_after_checkout=true
fi

if [ -n "${_project_name}" ] && [ "${_project_name}" = "kazoo5" ]; then
    echo "Not supported repo ${_project_name}"
    if [ -n "${CI}" ]; then
        exit 0
    fi
    exit 1
fi

# override vars if src options are used
if [ -n "${_project_name}" ] && [ -n "${_project_ref}" ]; then
    echo "=== Setting up variables to checkout apps to version/branch suitable for repository ${_project_name} ref ${_project_ref}"
    if ! echo "${_project_ref}" | grep -Eo '^[0-9]+\.[0-9]+\.[0-9]+' >/dev/null; then
        echo "Invalid semver for project ${_project_name} version."
        echo "Expected the version to start with Major.Minor.Patch, for example: 5.1.100"
        echo "but got ${_project_ref}"
        echo
        valid_vsn_examples
        exit 1
    fi
    _release_major="$(echo "${_project_ref}" | grep -Eo '^[0-9]+\.' | sed 's/\.//g')"
    _release_minor="$(echo "${_project_ref}" | grep -Eo '^[0-9]+\.[0-9]+' | sed -E 's/^[0-9]+\.//g')"
    _base_branch="origin/${_release_major}.${_release_minor}"
    _release_branch="${_release_major}.${_release_minor}"

    _is_project_fix_branch="$(is_fix_branch "${_project_ref}")"
    _is_project_tag="$(is_tag "${_project_ref}")"

    case "${_project_name}" in
        kazoo-ui-phone)
            echo "Not supported repo ${_project_name}"
            exit 1
            ;;
        kazoo-configs-*)
            echo "Not supported repo ${_project_name}"
            exit 1
            ;;
        kazoo5)
            echo "Not supported repo ${_project_name}"
            exit 1
            ;;
        kazoo-core)
            _project_type=kazoo-core
            _apps_dir="${ROOT}/applications"
            _pkg_name=kazoo-core
            _meta_pkg=meta-kazoo-applications
            ;;
        kazoo-*)
            _project_type=kazoo-application
            _apps_dir="${ROOT}/applications"
            _src_appname="${_project_name#kazoo-}"
            _src_appname="${_src_appname//-/_}"
            _pkg_name="kazoo-application-${_project_name#kazoo-}"
            _meta_pkg=meta-kazoo-applications
            ;;
        monster-ui)
            _project_type=monster-ui-core
            _apps_dir="${ROOT}/src/apps"
            _pkg_name="monster-ui-core"
            _meta_pkg=meta-monster-ui
            ;;
        monster-ui-*)
            _project_type=monster-ui-application
            _apps_dir="${ROOT}/src/apps"
            _src_appname="${_project_name#monster-ui-}"
            _pkg_name="monster-ui-application-${_project_name#monster-ui-}"
            _meta_pkg=meta-monster-ui
            ;;
        commland-core)
            _project_type=commland-core
            _apps_dir="${ROOT}/applications"
            _pkg_name="commland-core"
            _meta_pkg=meta-commland
            ;;
        commland-*)
            _project_type=commland-application
            _apps_dir="${ROOT}/applications"
            _src_appname="${_project_name#commland-}"
            _pkg_name="commland-application-${_project_name#commland-}"
            _meta_pkg=meta-commland
            ;;
        *)
            echo "Not supported repo ${_project_name}"
            exit 1
            ;;
    esac
else
    echo "=== Setting up the variables to checkout apps to their latest tag in base branch since no repository name was given"

    if [ -z "${BASE_BRANCH}" ] && [ -f "${ROOT}"/.base_branch ]; then
        BASE_BRANCH="$(cat "${ROOT}"/.base_branch)"
    fi
    _base_branch="${_base_branch:-${BASE_BRANCH}}"
    _release_branch="${_base_branch#origin/}"
    _release_major=$(echo "${_release_branch}" | grep -Eo '^[0-9]+\.' | sed 's/\.//g' || true)
    _release_minor=$(echo "${_release_branch}" | grep -Eo '^[0-9]+\.[0-9]+' | sed -E 's/^[0-9]+\.//g' || true)
fi

if [ -z "${_base_branch}" ]; then
    echo "BASE_BRANCH is required but is not set in environment or .base_branch file."
    echo "Check you have '.base_branch' file at the root of your project source code"
    echo "Base branch starts with 'origin/' like: 'origin/5.1'"
    echo
    valid_base_examples
    exit 1
fi
if ! echo "${_release_branch}" | grep -Eo '^[0-9]+\.[0-9]+' >/dev/null; then
    echo "Invalid semver for base branch: ${_base_branch}"
    echo "Expect the base branch to be in Major.Minor format"
    echo
    valid_base_examples
    exit 1
fi
if [ -z "${_release_minor}" ]; then
    echo "Could not determined release major/minor from ${_project_ref:-${_base_branch}}"
    exit 1
fi

if [ ! -d "${_apps_dir}" ]; then
    echo "Applications directory ${_apps_dir} does not exists"
    exit 1
fi

echo "Project type: ${_project_type:-N/A}"
echo "Applications directory: ${_apps_dir}"
echo "Base branch: ${_base_branch}"
echo "Release branch: ${_release_branch}"
echo "Project repository name: ${_project_name:-N/A}"
echo "Project repository git ref: ${_project_ref:-N/A}"
echo "Is Fix Branch: ${_is_project_fix_branch:-false}"
echo "Is Release/Tag: ${_is_project_tag:-false}"
echo

echo ":: Searching for apps in directory ${_apps_dir}/"
_apps=
if [ -n "${_src_appname}" ]; then
    _apps="$(find "${_apps_dir}"/ -maxdepth 1 -type d -not -name '.erlang.mk' -not -name "${_apps_dir//*\//}" -not -name "${_src_appname}" -printf '%f ')"
else
    _apps="$(find "${_apps_dir}"/ -maxdepth 1 -type d -not -name '.erlang.mk' -not -name "${_apps_dir//*\//}" -printf '%f ')"
fi
echo

checkout_repo() {
    set -e -o pipefail

    local _repo="${1}"
    local _path="${2}"
    local _semver_commitish="${3}"
    local _output_log=
    _output_log="$(mktemp)"

    if [ -z "${_semver_commitish}" ]; then
        echo "finding latest tag from origin/${_release_branch} branch"

        # we need to add origin so _commitish_ will still works by checking the origin and
        # not local
        _semver_commitish="$(git -C "${_path}" describe --tags --abbrev=0 "origin/${_release_branch}" 2>"${_output_log}" || true)"
        if [ -z "${_semver_commitish}" ]; then
            echo "no tag found in branch '${_release_branch}' not going to git checkout,"
            echo "pretending this is the first tag of this branch and use latest changes in the branch"
            if [ -f "${_output_log}" ]; then
                # echo "git describe log:"
                # cat "${_output_log}"
                rm "${_output_log}"
            fi
            return
        fi
        if [ -n "$(is_fix_branch "${_semver_commitish}")" ] && [ -z "${_is_project_fix_branch}" ]; then
            echo "latest tag ${_semver_commitish} looks like a fix tag, but the build for project ${_project_name:-'unspecified'} is not."
            echo "This is an invalid state and can cause problems, please ask lead developers and remove this tag ${_semver_commitish}"
            echo "Fix tags MUST NOT leak to normal release tags!"
            echo
            echo "Release/Tags built from a fix branch MUST be in their respective fix release branch:"
            echo "  git checkout 5.1.0 && git checout -b 5.1.0.1"
            echo "  # then in GitHub when creating the release set the target to 5.1.0.1"
            echo
            exit 1
        fi
    fi

    echo "git checkout ${_semver_commitish}"

    # Historically, some repos have mismatched their branch name and .base_branch
    # or even have mismatch tags in their release branch, like 4.3.1 in a 5.0 branch.
    # Here we check that given tag is really matching the given base branch and avoid failures
    # and bad builds
    _tag_major=$(echo "${_semver_commitish}" | grep -Eo '^[0-9]+' || true)
    _tag_minor=$(echo "${_semver_commitish}" | grep -Eo '^[0-9]+\.[0-9]+' | sed -E 's/^[0-9]+\.//g' || true)
    if [ -z "${_tag_major}" ] || [ -z "${_tag_minor}" ]; then
        echo "could not determined major or minor version from ref ${_semver_commitish} in ${_repo}."
        echo "tag name or branch name MUST at least start with Major.Minor format"
        echo
        echo "Either check the release/tag name of this repo ${_repo} is starts with a semver format,"
        echo "or check the override manifest file that the version that set is starts with a semver format."
        exit 1
    fi
    if [ "${_tag_major}" -lt "${_release_major}" ]; then
        echo "tag ${_repo}:${_semver_commitish} major version ${_tag_major} is not greater than base branch ${_base_branch} release major ${_release_major}"
        exit 1
    fi
    if [ "${_tag_minor}" -lt "${_release_minor}" ]; then
        echo "latest ${_repo}:${_semver_commitish} minor version ${_tag_minor} is not greater than base branch ${_base_branch} release minor ${_release_minor}"
        exit 1
    fi

    # now actually checkout out
    # don't use origin/, tags don't need them
    if ! git -C "${_path}" checkout "${_semver_commitish}" >/dev/null 2>"${_output_log}"; then
        echo "git checkout ${_semver_commitish} failed"
        if [ -f "${_output_log}" ]; then
            echo "git checkout log:"
            cat "${_output_log}"
            rm "${_output_log}"
        fi
        exit 1
    fi

    [ -f "${_output_log}" ] && rm "${_output_log}"
}

checkout_app_repo() {
    set -e -o pipefail

    local _repo="${1}"
    local _semver_commitish="${2}"

    _path="${_apps_dir}/${_repo}"

    # skip non app directories
    [ ! -d "${_path}/.git" ] && return
    # skip current ci building repo
    [ -n "${_src_appname}" ] && [ "${_repo}" = "${_src_appname}" ] && return

    echo ":: processing ${_repo}"

    checkout_repo "${_repo}" "${_path}" "${_semver_commitish}"

    if [ -n "${_clean_after_checkout}" ]; then
        git -C "${_path}" clean -x -d -f >/dev/null 2>&1
    fi
}

# always check with circleci orb, look in init-workspace and compile commands
maybe_checkout_core() {
    local _core_path=
    local _core_pkg=
    case "${_project_type}" in
        kazoo-application)
            _core_path="${ROOT}/core"
            _core_pkg="kazoo-core"
            ;;
        monster-ui-application)
            _core_path="${ROOT}"
            _core_pkg="monster-ui-core"
            ;;
        commland-application)
            _core_path="${ROOT}"
            _core_pkg="commland-core"
            ;;
        *)
            echo "The project name is ${_project_name}, CI steps should have already taken care of git checkout core, skipping..."
            return
            ;;
    esac

    echo ":: This is an app repository, going to resolve core ${_core_pkg} package using build-manifest-overrides"
    local _cmd="${_manifests_root_path}/build-manifest-overrides/scripts/resolve-override.sh"
    # do not use -k or -keep-going maybe?
    local _resolved=
    _resolved="$("${_cmd}" -k -m "${_meta_pkg}" -s "${_pkg_name}" -v "${_project_ref}" "${_core_pkg}" | sed -r 's/^.+:\s*//g')"

    echo ":: Resolved core ${_core_pkg} package to ${_resolved}, running git checkout"

    # Can't really clean if this is mui or commland core since it would also deletes the cloned apps!
    checkout_repo "${_core_pkg}" "${_core_path}" "${_resolved}"
}

_setup_manifests_repos() {
    # expected dir structure:
    # manifests/
    # ├── build-manifest-overrides
    # └── build-manifests
    echo ":: Setting up build-manifests and override repos"
    if [ ! -d "${_manifests_root_path}/build-manifests" ]; then
        echo "cloning build-manifests repo to ${_manifests_root_path}/build-manifests"
        mkdir -p "${_manifests_root_path}"
        git clone git@github.com:2600hz/build-manifests.git "${_manifests_root_path}/build-manifests"
    fi
    if [ ! -d "${_manifests_root_path}/build-manifest-overrides" ]; then
        echo "cloning build-manifests repo to ${_manifests_root_path}/build-manifest-overrides"
        mkdir -p "${_manifests_root_path}"
        git clone git@github.com:2600hz/build-manifest-overrides.git "${_manifests_root_path}/build-manifest-overrides"
    fi
    _manifests_root_path="$(realpath "${_manifests_root_path}")"

    echo "using main manifests from ${_manifests_root_path}/build-manifests"
    echo "using override manifests from ${_manifests_root_path}/build-manifest-overrides"
}

app_appname_to_pkgname() {
    case "${_project_type}" in
        kazoo-core)
            ;&
        kazoo-application)
            case "${1}" in
                call_inspector)
                    echo "kazoo-application-${1}"
                    ;;
                media_mgr)
                    echo "kazoo-application-${1}"
                    ;;
                *)
                    echo "kazoo-application-${1//_/-}"
                    ;;
            esac
            ;;
        monster-ui*)
            echo "monster-ui-application-${1}"
            ;;
        commland*)
            echo "commland-application-${1}"
            ;;
    esac
}

app_pkgname_to_appname() {
    case "${_project_type}" in
        kazoo*)
            local _tmp="${1#kazoo-application-}"
            echo "${_tmp//-/_}"
            ;;
        monster-ui*)
            echo "${1#monster-ui-application-}"
            ;;
        commland*)
            echo "${1#commland-application-}"
            ;;
    esac
}

finish_checkouts() {
    if [ -n "${CI}" ]; then
        touch "${CHECKOUT_WAS_HERE}"
    fi
    exit 0
}

# if this is a CI run on a fix release/branch then find the apps latest tag from manifests
if [ -n "${_is_project_fix_branch}" ]; then
    echo ">> This is a fix branch going to use the build-manifests and build-manifest-overrides to find branches/versions"
    echo "suitable for repository ${_project_name} ref ${_project_ref}"

    _setup_manifests_repos
    # ./scripts/resolve-overrides.sh -m meta-kazoo-applications -s kazoo-application-crossbar -v 5.1.27.1 \
    #     kazoo-core kazoo-application-ecallmgr kazoo-application-desktop [... other packages to list]
    echo ":: Calling build-manifest-overrides to resolve refs for dependencies"
    _cmd="${_manifests_root_path}/build-manifest-overrides/scripts/resolve-override.sh"
    _longest_pkg_name=
    _pkg=
    declare -A _pkgs=()
    # creating an assassinate array of all apps with key being pkg name and their value is
    # version/branch which will be populate when we call resolve-override script.
    # If no version is resolved then checkout function will get latest tag.
    for app in ${_apps}; do
        # skip non app-repo directories (like in mui-apploader, etc...)
        [ ! -d "${_apps_dir}/${app}/.git" ] && continue
        # skip current ci building repo
        [ -n "${_src_appname}" ] && [ "${app}" = "${_src_appname}" ] && continue
        _pkg="$(app_appname_to_pkgname "${app}")"
        _pkgs["${_pkg}"]=""
        if [ -n "${_longest_pkg_name}" ] && [ "${#_pkg}" -gt "${_longest_pkg_name}" ]; then
            _longest_pkg_name="${#_pkg}"
        elif [ -z "${_longest_pkg_name}" ]; then
            _longest_pkg_name="${#_pkg}"
        fi
    done

    # can't use mapfile since centos bash version is old, it needs at least bash 4.4
    # not save to use unquote too, so we run and store in a tmp var. do not redirect to
    # while since we don't catch a pipe/redirect failure. Then we iterate over and
    # set associated array.
    # Other solution is use `sed 's/: /:SEMVER:/g'` and loop over. look at manifests
    # 'scripts/resolved-version.sh':
    # _name="${_pkg%:SEMVER:*}"
    # _vsn="${_pkg#*:SEMVER:}"
    #
    # using -k or -keep-going so if no version found in manifest we fall back to find the
    # latest tag
    _resolved="$("${_cmd}" -k -m "${_meta_pkg}" -s "${_pkg_name}" -v "${_project_ref}" "${!_pkgs[@]}")"
    while IFS='' read -r line; do
        _pkgs["${line%%:*}"]="${line#*: }"
    done <<<"${_resolved}"

    echo ":: Resolved refs for the following dependencies:"
    # print resolved packages in a nice table
    for _pkg in "${!_pkgs[@]}"; do
        printf "  %-${_longest_pkg_name:-30}s | %-50s\n" "${_pkg}" "${_pkgs[${_pkg}]:-not found in manifests, going to use the latest tag}"
    done
    unset _pkg

    echo
    echo ">> Git checking out apps"
    for _pkg in "${!_pkgs[@]}"; do
        checkout_app_repo "$(app_pkgname_to_appname "${_pkg}")" "${_pkgs[${_pkg}]}"
    done

    echo
    echo ">> Check if we need to git checkout core app too"
    maybe_checkout_core

    finish_checkouts
fi

if [ -n "${_is_project_tag}" ]; then
    echo ">> This is a release tag, going to checkout apps to their latest base branch tags"
else
    echo ">> Not a fix branch, going to checkout apps to their latest base branch tags"
fi

for app in ${_apps} ; do
    checkout_app_repo "${app}"
done

finish_checkouts
