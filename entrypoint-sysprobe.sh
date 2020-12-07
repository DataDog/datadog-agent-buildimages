#!/bin/bash
set -e

source /root/.bashrc

eval "$(gimme)"

exec "$@"
