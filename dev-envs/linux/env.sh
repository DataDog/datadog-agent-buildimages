#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

source /setup/shellrc.sh

path-prepend "${HOME}/.scripts"
