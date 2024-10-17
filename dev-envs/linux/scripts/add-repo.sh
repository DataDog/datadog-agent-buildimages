#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

git clone "https://github.com/DataDog/$1" "${DD_REPOS_DIR}/$1"

# The first time is a bit slow so do that now for a better experience
gfold > /dev/null 2>&1
