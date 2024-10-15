#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

set-ev DD_MOUNT_DIR "${HOME}/mount"
set-ev DD_REPOS_DIR "${HOME}/repos"
