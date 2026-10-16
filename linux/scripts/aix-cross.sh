#!/usr/bin/env bash

set -euxo pipefail

# /opt/aix-cross must exist even when not populated below: the final image
# stage COPYs it unconditionally. It won't be populated if fetching the
# toolchain was skipped or failed (see the aix_cross_builder stage).
mkdir -p /opt/aix-cross

if [ ! -d /opt/aix-cross/compiler/bin ]; then
    exit 0
fi

# Thin wrapper scripts in bin/ call the real compiler drivers with --sysroot
# so the toolchain is relocatable regardless of where the sysroot was during
# the build. Other tools (ar, as, ld, ...) don't accept --sysroot, so they
# are only symlinked.
mkdir -p /opt/aix-cross/bin
for tool in /opt/aix-cross/compiler/bin/powerpc-ibm-aix*; do
    name="$(basename "$tool")"
    case "$name" in
        *-gcc|*-gcc-*|*-g++|*-cpp)
            printf '#!/bin/sh\nexec "%s" --sysroot=/opt/aix-cross/sysroot "$@"\n' "$tool" \
                > "/opt/aix-cross/bin/$name"
            chmod +x "/opt/aix-cross/bin/$name"
            ;;
        *)
            ln -s "$tool" "/opt/aix-cross/bin/$name"
            ;;
    esac
done
