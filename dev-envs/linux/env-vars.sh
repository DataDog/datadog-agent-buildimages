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

# These are effectively required for builds
set-ev OMNIBUS_BASE_DIR "/omnibus"
set-ev OMNIBUS_GIT_CACHE_DIR "/tmp/omnibus-git-cache"
set-ev OMNIBUS_FORCE_PACKAGES "1"

# Properly set up Ruby's bundle cache
set-ev BUNDLE_PATH "/omnibus/vendor/bundle"
