#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

branch="$1"

if ! git ls-remote --exit-code --heads origin "${branch}" > /dev/null; then
    git switch -c "${branch}"
else
    git remote set-branches --add origin "${branch}"
    git fetch --depth 1 origin "${branch}"
    git switch "${branch}"
fi
