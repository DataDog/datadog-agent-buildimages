#!/bin/bash

set -ex

# NOTE: This script will not work outside of the Dockerfile build context (writing to /build)

cd /build

curl -LO "https://salsa.debian.org/dpkg-team/dpkg/-/archive/${DPKG_ARMHF_VERSION}/dpkg-${DPKG_ARMHF_VERSION}.tar.bz2"
echo "${DPKG_ARMHF_SHA256}  dpkg-${DPKG_ARMHF_VERSION}.tar.bz2" | sha256sum --check

tar -xf "dpkg-${DPKG_ARMHF_VERSION}.tar.bz2"
cd "dpkg-${DPKG_ARMHF_VERSION}"

echo "${DPKG_ARMHF_VERSION}" > .dist-version
autoreconf -vfi

mkdir build && cd build
export DPKG_PREFIX=/opt/dpkg-armhf
PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ../configure \
    --host=arm-linux-gnueabihf \
    --build=arm-linux-gnueabihf \
    --program-suffix=-armhf \
    --prefix="${DPKG_PREFIX}" \
    --sysconfdir="${DPKG_PREFIX}/etc" \
    --localstatedir="${DPKG_PREFIX}/var" \
    --disable-nls \
    --disable-dselect

make -j"$(nproc)"
make install
mkdir -p "${DPKG_PREFIX}/var/lib/dpkg" "${DPKG_PREFIX}/var/cache/dpkg"

install -m 0755 /dev/stdin "${DPKG_PREFIX}/bin/dpkg" <<EOF
#!/bin/sh
exec "${DPKG_PREFIX}/bin/dpkg-armhf" \\
    --admindir="${DPKG_PREFIX}/var/lib/dpkg" \\
    --instdir="${DPKG_PREFIX}" \\
    "\$@"
EOF

rm -rf /build
