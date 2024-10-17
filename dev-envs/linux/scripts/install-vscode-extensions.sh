#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

xargs -a "$1" -L 1 code-server --accept-server-license-terms --force --install-extension
