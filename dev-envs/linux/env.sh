#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

source /setup/shellrc.sh

path-prepend "${HOME}/.scripts"

# Properly add directories to PATH that were only added as Docker directives
path-append "${HOME}/.cargo/bin"
path-append "/go/bin"
path-append "/usr/local/go/bin"
path-append "/root/miniforge3/condabin"
path-append "/usr/lib/binutils-2.26/bin"
