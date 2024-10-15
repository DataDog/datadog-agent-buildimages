#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

set-ev DD_SHARED_DIR "${HOME}/.shared"
set-ev DD_REPOS_DIR "${HOME}/repos"
