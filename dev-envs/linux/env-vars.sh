#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

set-ev DD_SHARED_DIR "/.shared"

# Advertise full terminal capabilities
set-ev TERM "xterm-256color"
set-ev COLORTERM "truecolor"

# Allow dynamic dependencies again as they are disabled in build images
set-ev DDA_NO_DYNAMIC_DEPS "0"

# These are effectively required for builds
set-ev OMNIBUS_FORCE_PACKAGES "1"
