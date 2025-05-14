#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

set-ev DD_SHARED_DIR "${HOME}/.shared"
set-ev DD_REPOS_DIR "${HOME}/repos"
# These environment variables are set in docker directives, we want them available when we ssh into the container
set-ev DD_CC "${DD_CC}"
set-ev DD_CXX "${DD_CXX}"
set-ev DD_CMAKE_TOOLCHAIN "${DD_CMAKE_TOOLCHAIN}"
