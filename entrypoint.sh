#!/bin/bash -l
set -e

source /root/.bashrc

conda activate ddpy3 || true # We use system python3 on some images, allow this to fail

if [ "$TARGET_ARCH" = "arm64v8" ] ; then
    export GIMME_ARCH=arm64
elif [ "$TARGET_ARCH" = "arm32v7" ] ; then
    export GIMME_ARCH=arm
fi
eval "$(gimme)"

exec "$@"
