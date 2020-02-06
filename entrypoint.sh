#!/bin/bash -l
set -e

source /root/.bashrc && conda activate ddpy3
eval "$(gimme)"

exec "$@"
