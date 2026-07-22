#!/usr/bin/env bash

set -euxo pipefail

gpg --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys 1F30EF2E
gpg --verify crosstool-ng-${CTNG_VERSION}.tar.xz.sig

tar xf crosstool-ng-${CTNG_VERSION}.tar.xz
cd crosstool-ng-${CTNG_VERSION}
patch -p1 < /root/ctng.patch

./configure --enable-local && make -j$(nproc)
export CT_ALLOW_BUILD_AS_ROOT_SURE=yes

# crosstool-ng names its x-tools output directory after the target triplet. Every arch we
# build uses the "<arch>-unknown-linux-gnu" triplet, except armhf, whose EABIHF ABI produces
# "arm-unknown-linux-gnueabihf" instead.
xtools_dir() {
    case "$1" in
        armhf) echo "arm-unknown-linux-gnueabihf" ;;
        *)     echo "$1-unknown-linux-gnu" ;;
    esac
}

./ct-ng upgradeconfig
./ct-ng build

mkdir -p /opt/toolchains/
mv /root/x-tools/$(xtools_dir ${CTNG_ARCH})/ /opt/toolchains/${CTNG_ARCH}
mv .config-${CTNG_CROSS_ARCH} .config
./ct-ng upgradeconfig
./ct-ng build
mv /root/x-tools/$(xtools_dir ${CTNG_CROSS_ARCH})/ /opt/toolchains/${CTNG_CROSS_ARCH}

if [ -n "${CTNG_ARMHF_ARCH:-}" ]; then
    mv .config-${CTNG_ARMHF_ARCH} .config
    ./ct-ng upgradeconfig
    ./ct-ng build
    mv /root/x-tools/$(xtools_dir ${CTNG_ARMHF_ARCH})/ /opt/toolchains/${CTNG_ARMHF_ARCH}
fi
