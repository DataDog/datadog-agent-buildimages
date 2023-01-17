#!/bin/bash
set -e

if [ -n "$GIMME_GO_VERSION" ] ; then
    eval "$(gimme)"
fi

exec "$@"
