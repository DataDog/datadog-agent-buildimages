#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

source /entrypoint-common.sh

exec sleep infinity
