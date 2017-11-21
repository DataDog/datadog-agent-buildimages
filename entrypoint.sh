#!/bin/bash -l
set -e

eval "$(gimme)"

exec "$@"
