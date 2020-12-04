#!/bin/bash -l
set -e

source /root/.bashrc

eval "$(gimme)"

export PATH="/opt/clang/bin:$PATH"

exec "$@"
