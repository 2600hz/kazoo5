#!/bin/bash

set -e -o pipefail

# echo ' _____ _               _    _                           _'
# echo '/  __ \ |             | |  (_)                         | |'
# echo '| /  \/ |__   ___  ___| | ___ _ __   __ _    ___  _   _| |_'
# echo '| |   | |_ \ / _ \/ __| |/ / | |_ \ / _` |  / _ \| | | | __|'
# echo '| \__/\ | | |  __/ (__|   <| | | | | (_| | | (_) | |_| | |_'
# echo ' \____/_| |_|\___|\___|_|\_\_|_| |_|\__, |  \___/ \__,_|\__|'
# echo ' _       _            _     _   __   __/ |'
# echo '| |     | |          | |   | | / /  |___/'
# echo '| | __ _| |_ ___  ___| |_  | |/ /  __ _ _______   ___'
# echo '| |/ _\ | __/ _ \/ __| __| |    \ / _` |_  / _ \ / _ \ '
# echo '| | (_| | ||  __/\__ \ |_  | |\  \ (_| |/ / (_) | (_) |'
# echo '|_|\__,_|\__\___||___/\__| \_| \_/\__,_/___\___/ \___/'
# echo

# TODO: we need to run this either on fetch-apps or compile to support all old branches
# when fixing otherwise we must update orbs in those branches
# TODO: if this is circleci then create a lock file to avoid re-run of this script
# maybe orb is running this on tag and we may run this in compile/fetch-apps
# TODO: make sure we run this on fix PRs, release should be okay tho
# TODO: make sure this runs properly on fix prs
# TODO: checkout core too if CIRCLE_PROJECT_REPONAME is not core

pushd "$(dirname "$0")/.." > /dev/null || exit 1
ROOT="$(pwd -P)"
export ROOT

if [ -z "${BASE_BRANCH}" ]; then
    BASE_BRANCH="$(cat "${ROOT}"/.base_branch 2>/dev/null || true)"
fi

_base_branch=
_manifests_root_path=
_src_repo=
_src_vsn=
_project_type=
while [ $# -gt 0 ]; do
    arg="${1}"
    case ${arg} in
        -b|-base-branch)
            if [ -n "$2" ]; then
                _base_branch="${2}"
                shift
            fi
            ;;
        -m|-manifests-root-path)
            if [ -n "$2" ]; then
                _manifests_root_path="${2}"
                shift
            fi
            ;;
        -s|src-name)
            if [ -n "$2" ]; then
                _src_repo="${2}"
                shift
            fi
            ;;
        -t|-project-type)
            if [ -n "$2" ]; then
                _project_type="${2}"
                shift
            fi
            ;;
        -v|src-version)
            if [ -n "$2" ]; then
                _src_vsn="${2}"
                shift
            fi
            ;;
        *)
            ;;
    esac
    shift
done
unset arg

_manifests_root_path="${_manifests_root_path:-${ROOT}/../manifests}"
_base_branch="${_base_branch:-${BASE_BRANCH}}"
_release_branch="${_base_branch#origin/}"
_release_major=$(echo "${_release_branch}" | grep -Eo '^[0-9]+\.' | sed 's/\.//g' || true)
_release_minor=$(echo "${_release_branch}" | grep -Eo '^[0-9]+\.[0-9]+' | sed -E 's/^[0-9]+\.//g' || true)

# override vars if src options are used
_src_repo="${_src_repo:-${CIRCLE_PROJECT_REPONAME}}"
_src_vsn="${_src_vsn:-${CIRCLE_TAG}}"
if [ -n "${_src_repo}" ] && [ -n "${_src_vsn}" ]; then
    echo "${_src_vsn}" | grep -Eo '^[0-9]+\.[0-9]+\.[0-9]+' >/dev/null || { echo "Invalid semver for source version: ${_src_vsn}"; exit 1; }
    _release_major="$(echo "${_src_vsn}" | grep -Eo '^[0-9]+\.' | sed 's/\.//g')"
    _release_minor="$(echo "${_src_vsn}" | grep -Eo '^[0-9]+\.[0-9]+' | sed -E 's/^[0-9]+\.//g')"
    _base_branch="origin/${_release_major}.${_release_minor}"
    _release_branch="${_release_major}.${_release_minor}"
fi

[ -z "${_base_branch}" ] && { echo "BASE_BRANCH is required but is not set in environment."; exit 1; }
echo "${_release_branch}" | grep -Eo '^[0-9]+\.[0-9]+' >/dev/null || { echo "Invalid semver for base branch: ${_base_branch}"; exit 1; }
[ -z "${_release_minor}" ] && { echo "Could not determined release major/minor from ${_src_vsn:-${_base_branch}}"; exit 1; }

if [ -n "${_src_repo}" ] ; then
    case "${_src_repo}" in
        kazoo-ui-phone)
            echo "Not supported repo ${_src_repo}"
            exit 1
            ;;
        kazoo-configs-*)
            echo "Not supported repo ${_src_repo}"
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
            _src_appname="${_src_repo#kazoo-}"
            _src_appname="${_src_appname//-/_}"
            _pkg_name="kazoo-application-${_src_repo#kazoo-}"
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
            _src_appname="${_src_repo#monster-ui-}"
            _pkg_name="monster-ui-application-${_src_repo#monster-ui-}"
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
            _src_appname="${_src_repo#commland-}"
            _pkg_name="commland-application-${_src_repo#commland-}"
            _meta_pkg=meta-commland
            ;;
        *)
            echo "Not supported repo ${_src_repo}"
            exit 1
            ;;
    esac
fi
_apps_dir="${_apps_dir:-${ROOT}/applications}"

if [ ! -d "${_apps_dir}" ]; then
    echo "Applications directory ${_apps_dir} does not exists"
    exit 1
fi

echo "Project type: ${_project_type:-N/A}"
echo "Applications directory: ${_apps_dir}"
echo "Base branch: ${_base_branch}"
echo "Release branch: ${_release_branch}"
echo "Source repository name: ${_src_repo:-N/A}"
echo "Source repository version: ${_src_vsn:-N/A}"
echo

if [ -n "${_src_appname}" ]; then
    _apps="$(find "${_apps_dir}"/ -maxdepth 1 -type d -not -name '.erlang.mk' -not -name "${_apps_dir//*\//}" -not -name "${_src_appname}" -printf '%f ')"
else
    _apps="$(find "${_apps_dir}"/ -maxdepth 1 -type d -not -name '.erlang.mk' -not -name "${_apps_dir//*\//}" -printf '%f ')"
fi

# 1) What if we get no src repo/vsn option and we have to find out the latest tag from git describe
# and the latest tag in 5.2 branch was a fix branch/pr/tag for one of app?
# 2) What if this happens when there is src repo/vsn?
# 3) can we extend this to support master or non-release branches? like dependent PRs?
is_fix_branch() {
    if echo "${1}" | grep -Eo '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' >/dev/null; then
        echo true
    fi
}

checkout_repo() {
    set -e -o pipefail

    local _app="${1}"
    local _app_tag="${2}"
    local _output_log=
    _output_log="$(mktemp)"

    _path="${_apps_dir}/${_app}"

    # skip non app directories
    [ ! -d "${_path}/.git" ] && return
    # skip current ci building repo
    [ -n "${_src_appname}" ] && [ "${_app}" = "${_src_appname}" ] && return

    echo ":: processing ${_app}"

    if [ -z "${_app_tag}" ]; then
        echo "finding latest tag"

        # we need to add origin so _commitish_ will still works by checking the origin and
        # not local
        _app_tag="$(git -C "${_path}" describe --tags --abbrev=0 "origin/${_release_branch}" 2>"${_output_log}" || true)"
        if [ -z "${_app_tag}" ]; then
            echo "no tag found for release branch '${_release_branch}' pretending this is the first tag of this branch"
            if [ -f "${_output_log}" ]; then
                echo
                echo "git checkout log:"
                cat "${_output_log}"
                rm "${_output_log}"
            fi
            return
        fi
        if [ -n "$(is_fix_branch "${_app_tag}")" ] && [ -z "${_src_repo}" ] && [ -z "${_src_vsn}" ]; then
            echo "latest tag ${_app_tag} look like a fix tag, but the build is not specified"
            echo "a source repository to resolve version using build-manifest-overrides"
            exit 1
        fi
    fi

    echo "checking out to tag ${_app_tag}"

    # Historically, some repos have mismatched their branch name and .base_branch
    # or even have mistmatch tags in their release branch, like 4.3.1 in a 5.0 branch.
    # Here we check that given tag is really matching the given base branch and avoid failures
    # and bad builds
    _tag_major=$(echo "${_app_tag}" | grep -Eo '^[0-9]+')
    _tag_minor=$(echo "${_app_tag}" | grep -Eo '^[0-9]+\.[0-9]+' | sed -E 's/^[0-9]+\.//g')
    if [ -z "${_tag_major}" ] || [ -z "${_tag_minor}" ]; then
        echo "could not determined major or minor version from tag ${_app_tag} in ${_app}."
        echo "tag name MUST start with Major.Minor format"
        exit 1
    fi
    if [ "${_tag_major}" -lt "${_release_major}" ]; then
        echo "tag ${_app}:${_app_tag} major version ${_tag_major} is not greater than base branch ${_base_branch} release major ${_release_major}"
        exit 1
    fi
    if [ "${_tag_minor}" -lt "${_release_minor}" ]; then
        echo "latest ${_app}:${_app_tag} minor version ${_tag_minor} is not greater than base branch ${_base_branch} release minor ${_release_minor}"
        exit 1
    fi

    # now actually checkout out
    # don't use origin/, tags don't need them
    if ! git -C "${_path}" checkout "${_app_tag}" >/dev/null  2>"${_output_log}"; then
        echo "git checkout ${_app_tag} failed"
        if [ -f "${_output_log}" ]; then
            echo
            echo "git checkout log:"
            cat "${_output_log}"
            rm "${_output_log}"
        fi
        ## TODO: dev
        return
        # exit 1
    fi
    git -C "${_path}" clean -x -d -f >/dev/null 2>&1

    [ -f "${_output_log}" ] && rm "${_output_log}"
}

_setup_manifests_repos() {
    # expected dir structure:
    # manifests/
    # ├── build-manifest-overrides
    # └── build-manifests
    if [ ! -d "${_manifests_root_path}/build-manifests" ]; then
        echo "cloning required build-manifests repo to ${_manifests_root_path}/build-manifests"
        mkdir -p "${_manifests_root_path}"
        git clone git@github.com:2600hz/build-manifests.git "${_manifests_root_path}/build-manifests"
    fi
    if [ ! -d "${_manifests_root_path}/build-manifest-overrides" ]; then
        echo "cloning required build-manifests repo to ${_manifests_root_path}/build-manifest-overrides"
        mkdir -p "${_manifests_root_path}"
        git clone git@github.com:2600hz/build-manifest-overrides.git "${_manifests_root_path}/build-manifest-overrides"
    fi
    _manifests_root_path="$(realpath "${_manifests_root_path}")"
}

appname_to_pkgname() {
    case "${_project_type}" in
        kazoo-core)
            echo "kazoo-core"
            ;;
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
        monster-ui-core)
            echo "monster-ui-core"
            ;;
        monster-ui-application)
            echo "monster-ui-application-${1}"
            ;;
        commland-core)
            echo "commland-core"
            ;;
        commland-application)
            echo "commland-application-${1}"
            ;;
    esac
}

pkgname_to_appname() {
    case "${_project_type}" in
        kazoo-core)
            echo "${1#kazoo-}"
            ;;
        kazoo-application)
            local _tmp="${1#kazoo-application-}"
            echo "${_tmp//-/_}"
            ;;
        monster-ui-core)
            echo "${1#monster-ui-}"
            ;;
        monster-ui-application)
            echo "${1#monster-ui-application-}"
            ;;
        commland-core)
            echo "${1#commland-}"
            ;;
        commland-application)
            echo "${1#commland-application-}"
            ;;
    esac
}

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
            # the repo is core, orb shouldve already checkout the tag
            return
            ;;
    esac
    _cmd="${_manifests_root_path}/build-manifest-overrides/scripts/resolve-override.sh"
    # do not use -k or -keep-going
    _resolved="$("${_cmd}" -m "${_meta_pkg}" -s "${_pkg_name}" -v "${_src_vsn}" "${_core_pkg}")"

}

# if this is a CI run on a fix release/branch then find the apps latest tag from manifests
if [ -n "${_src_repo}" ] && [ -n "${_src_vsn}" ] && [ -n "$(is_fix_branch "${_src_vsn}")" ]; then
    # ./scripts/resolve-overrides.sh -m meta-kazoo-applications -s kazoo-application-crossbar -v 5.1.27.1 \
    #     kazoo-core kazoo-application-ecallmgr kazoo-application-desktop [... other packages to list]
    _cmd="${_manifests_root_path}/build-manifest-overrides/scripts/resolve-override.sh"
    declare -A _pkgs=()
    for app in ${_apps}; do
        _pkgs["$(appname_to_pkgname "${app}")"]=""
    done

    while IFS='' read -r line; do
        _pkgs["${line%%:*}"]="${line#*: }"
    # do not use -k or -keep-going
    done < <("${_cmd}" -k -m "${_meta_pkg}" -s "${_pkg_name}" -v "${_src_vsn}" "${!_pkgs[@]}")

    for _pkg in "${!_pkgs[@]}"; do
        checkout_repo "$(pkgname_to_appname "${_pkg}")" "${_pkgs[${_pkg}]}"
    done

    exit 0
fi

echo "no source repo and version were given, chechking out latest release tags"
for app in ${_apps} ; do
    checkout_repo "${app}"
done
