#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

remote="https://github.com/DataDog/$1"
clone_dir="${DD_REPOS_DIR}/$1"
branch="${2:-}"

if [[ -d "${clone_dir}" ]]; then
  exit
fi

if [[ -z "${branch}" ]]; then
    git clone "${remote}" "${clone_dir}" --depth 1
else
    if [[ -n "$(git ls-remote --heads "${remote}" | grep -E "refs/heads/${branch}$")" ]]; then
        git clone "${remote}" "${clone_dir}" --depth 1 --branch "${branch}" --single-branch
    else
        git clone "${remote}" "${clone_dir}" --depth 1

        # Shell plugins make this noisy
        set +x
        cd "${clone_dir}"
        set -x

        git switch -c "${branch}"
    fi
fi

# The first time is a bit slow so do that now for a better experience
gfold "${clone_dir}" > /dev/null 2>&1
