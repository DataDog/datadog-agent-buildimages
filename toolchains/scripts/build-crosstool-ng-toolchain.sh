#!/usr/bin/env bash

set -euxo pipefail

source "${CI_PROJECT_DIR}/toolchains/crosstool-ng/ctng-version.env"

WORKDIR=$(mktemp -d)
echo "Building crosstool-ng in ${WORKDIR}"
cd "${WORKDIR}"

gpg --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys 1F30EF2E
curl -LO "https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/crosstool-ng-${CTNG_VERSION}.tar.xz"
curl -LO "https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/crosstool-ng-${CTNG_VERSION}.tar.xz.sig"
gpg --verify "crosstool-ng-${CTNG_VERSION}.tar.xz.sig"

tar xf "crosstool-ng-${CTNG_VERSION}.tar.xz"
cd "crosstool-ng-${CTNG_VERSION}"
patch -p1 < "${CI_PROJECT_DIR}/toolchains/crosstool-ng/ctng.patch"

./configure --enable-local && make -j"$(nproc)"
export CT_ALLOW_BUILD_AS_ROOT_SURE=yes

cp "${CI_PROJECT_DIR}/toolchains/crosstool-ng/${TOOLCHAIN_HOST_ARCH}/config-${TOOLCHAIN_TARGET_ARCH}-unknown-gnu-linux-glibc${TOOLCHAIN_TARGET_GLIBC_VERSION}" .config
./ct-ng upgradeconfig
./ct-ng build

tar cJf "${CI_PROJECT_DIR}/${TOOLCHAIN_TARGET_ARCH}-unknown-linux-gnu-gcc.tar.xz" -C "/root/x-tools/${TOOLCHAIN_TARGET_ARCH}-unknown-linux-gnu" .
