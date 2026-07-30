#!/usr/bin/env bash

set -euxo pipefail

source "${CI_PROJECT_DIR}/toolchains/crosstool-ng/ctng-version.env"

CONFIG="${CI_PROJECT_DIR}/$(cd "${CI_PROJECT_DIR}" && ./toolchains/scripts/toolchain-config-path.sh "${TOOLCHAIN_HOST_ARCH}" "${TOOLCHAIN_TARGET_ARCH}")"

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

cp "${CONFIG}" .config
./ct-ng upgradeconfig
./ct-ng build

# crosstool-ng names its x-tools output directory after the target triplet. Every arch we
# build uses the "<arch>-unknown-linux-gnu" triplet, except armhf, whose EABIHF ABI produces
# "arm-unknown-linux-gnueabihf" instead.
case "${TOOLCHAIN_TARGET_ARCH}" in
    armhf) XTOOLS_DIR=arm-unknown-linux-gnueabihf ;;
    *)     XTOOLS_DIR=${TOOLCHAIN_TARGET_ARCH}-unknown-linux-gnu ;;
esac

tar cJf "${CI_PROJECT_DIR}/${TOOLCHAIN_TARGET_ARCH}-unknown-linux-gnu-gcc.tar.xz" -C "/root/x-tools/${XTOOLS_DIR}" .
