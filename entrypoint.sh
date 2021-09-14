#!/bin/bash -l
set -e

source /root/.bashrc

if command -v conda; then
  # Only try to use conda if it's installed.
  # On ARM32 images, we use the system Python 3 because conda is not supported.
  conda activate ddpy3
fi

if [ "$DD_TARGET_ARCH" = "aarch64" ] ; then
    export GIMME_ARCH=arm64
elif [ "$DD_TARGET_ARCH" = "armhf" ] ; then
    export GIMME_ARCH=arm
fi

if [ -n "$GIMME_GO_VERSION" ] ; then
    eval "$(gimme)"
fi

exec "$@"
