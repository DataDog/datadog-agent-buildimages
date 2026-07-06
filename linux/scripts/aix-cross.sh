#!/usr/bin/env bash

set -euxo pipefail

# The cross-compiler is a prebuilt x86_64 ELF toolchain: it can only run on
# the amd64 image, so skip installing it anywhere else.
if [ "${TARGETARCH}" != "amd64" ]; then
    exit 0
fi

mkdir -p /opt/aix-cross
tar -xJf aix-cross-toolchain.tar.xz -C /opt/aix-cross

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
