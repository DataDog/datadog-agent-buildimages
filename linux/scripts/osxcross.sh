#!/usr/bin/env bash

set -euxo pipefail

# Verify the SDK checksum
echo "${MACOSX_SDK_SHA256}  tarballs/MacOSX${MACOSX_SDK_VERSION}.sdk.tar.xz" | sha256sum -c -

# Pre-extract the SDK into the target SDK directory.
# The build.sh at certain commits has a bug where its internal SDK
# extraction resolves paths incorrectly. By pre-extracting the SDK
# to the expected location, build.sh detects it and skips extraction.
mkdir -p target/SDK
tar xJf "tarballs/MacOSX${MACOSX_SDK_VERSION}.sdk.tar.xz" -C target/SDK/

# Build osxcross
UNATTENDED=1 TARGET_DIR=/opt/osxcross ./build.sh

# Remove unnecessary content like man pages and files supporting iOS
rm -rf \
    "/opt/osxcross/SDK/MacOSX${MACOSX_SDK_VERSION}.sdk/System/iOSSupport" \
    "/opt/osxcross/SDK/MacOSX${MACOSX_SDK_VERSION}.sdk/usr/share/man"
