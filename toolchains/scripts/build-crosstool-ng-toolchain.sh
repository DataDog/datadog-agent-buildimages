#!/usr/bin/env bash

set -euo pipefail

source "${CI_PROJECT_DIR}/toolchains/scripts/lib.sh"
source "${CI_PROJECT_DIR}/toolchains/crosstool-ng/ctng-version.env"

CONFIG="${CI_PROJECT_DIR}/$(toolchain_config_path "${TOOLCHAIN_HOST_ARCH}" "${TOOLCHAIN_TARGET_ARCH}")"
TRIPLET=$(toolchain_triplet "${TOOLCHAIN_TARGET_ARCH}")

WORKDIR=$(mktemp -d)
echo "Building crosstool-ng in ${WORKDIR}"
cd "${WORKDIR}"

gpg --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys 1F30EF2E
curl --retry 10 -LO "https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/crosstool-ng-${CTNG_VERSION}.tar.xz"
curl --retry 10 -LO "https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/crosstool-ng-${CTNG_VERSION}.tar.xz.sig"
gpg --verify "crosstool-ng-${CTNG_VERSION}.tar.xz.sig"

tar xf "crosstool-ng-${CTNG_VERSION}.tar.xz"
cd "crosstool-ng-${CTNG_VERSION}"
patch -p1 < "${CI_PROJECT_DIR}/toolchains/crosstool-ng/ctng.patch"

./configure --enable-local && make -j"$(nproc)"
export CT_ALLOW_BUILD_AS_ROOT_SURE=yes

trap '
    cp -f build.log "${CI_PROJECT_DIR}/build.log" 2>/dev/null
    find .build -name config.log -print0 2>/dev/null | tar cJf "${CI_PROJECT_DIR}/config-logs.tar.xz" --null -T - 2>/dev/null
    true
' EXIT

cp "${CONFIG}" .config
./ct-ng upgradeconfig
./ct-ng build

# crosstool-ng names its x-tools output directory after the target triplet.
tar cJf "${CI_PROJECT_DIR}/${TRIPLET}-gcc.tar.xz" -C "/root/x-tools/${TRIPLET}" .
