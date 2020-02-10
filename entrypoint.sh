#!/bin/bash -l
set -e

source /root/.bashrc

conda activate ddpy3 || true # We use system python3 on some images, allow this to fail

eval "$(gimme)"

exec "$@"
