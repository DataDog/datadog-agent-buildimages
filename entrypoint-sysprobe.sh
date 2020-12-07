#!/bin/bash
set -e

eval "$(gimme)"

exec "$@"
