#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

branch="$1"
repo="$(basename "$(pwd)")"
remote="https://github.com/DataDog/${repo}"

if [[ -z "$(git ls-remote --heads "${remote}" "${branch}")" ]]; then
    git switch -c "${branch}"
else
    git remote set-branches --add origin "${branch}"
    git fetch --depth 1 origin "${branch}"
    git switch "${branch}"
fi
