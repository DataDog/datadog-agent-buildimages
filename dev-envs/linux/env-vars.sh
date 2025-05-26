#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

set-ev DD_SHARED_DIR "${HOME}/.shared"
set-ev DD_REPOS_DIR "${HOME}/repos"

# Advertise full terminal capabilities
set-ev TERM "xterm-256color"
set-ev COLORTERM "truecolor"

# Allow dynamic dependencies again as they are disabled in build images
set-ev DDA_NO_DYNAMIC_DEPS "0"

# These environment variables are set in docker directives, we want them available when we ssh into the container
set-ev DD_CC_PATH "${DD_CC_PATH}"
set-ev DD_CXX_PATH "${DD_CXX_PATH}"
set-ev DD_CMAKE_TOOLCHAIN_PATH "${DD_CMAKE_TOOLCHAIN_PATH}"
