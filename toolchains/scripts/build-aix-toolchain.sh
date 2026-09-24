#!/usr/bin/env bash

set -euo pipefail

source "${CI_PROJECT_DIR}/toolchains/scripts/lib.sh"
source "${CI_PROJECT_DIR}/toolchains/aix/aix-version.env"

TRIPLET=$(toolchain_triplet aix)

WORKDIR=$(mktemp -d)
echo "Building AIX cross-compiler in ${WORKDIR}"

SYSROOT_TARBALL="${WORKDIR}/aix-sysroot.tar.gz"
curl --retry 10 -fL "${AIX_SYSROOT_URL}" -o "${SYSROOT_TARBALL}"

# Resolve the sysroot root ourselves (rather than relying on build-aix-cross.sh's
# own auto-locate) so we know exactly which directory to package alongside the
# compiler below.
SYSROOT_EXTRACTED="${WORKDIR}/sysroot-extracted"
mkdir -p "${SYSROOT_EXTRACTED}"
tar -xf "${SYSROOT_TARBALL}" -C "${SYSROOT_EXTRACTED}"

SYSROOT_INC=$(find "${SYSROOT_EXTRACTED}" -type d -path '*/usr/include' -print -quit)
[[ -n "${SYSROOT_INC}" ]] || { echo "Could not locate usr/include in the downloaded AIX sysroot" >&2; exit 1; }
SYSROOT_DIR=$(cd "${SYSROOT_INC}/../.." && pwd)

PREFIX="${WORKDIR}/compiler"
"${CI_PROJECT_DIR}/toolchains/aix/build-aix-cross.sh" \
    --sysroot "${SYSROOT_DIR}" \
    --prefix "${PREFIX}" \
    --aix-version "${AIX_VERSION}" \
    --binutils-version "${BINUTILS_VERSION}" \
    --gcc-version "${GCC_VERSION}"

# linux/scripts/aix-cross.sh expects the archive to contain compiler/ and
# sysroot/ at the top level.
PACKAGE_DIR="${WORKDIR}/package"
mkdir -p "${PACKAGE_DIR}"
cp -a "${PREFIX}" "${PACKAGE_DIR}/compiler"
cp -a "${SYSROOT_DIR}" "${PACKAGE_DIR}/sysroot"
tar cJf "${CI_PROJECT_DIR}/${TRIPLET}-gcc.tar.xz" -C "${PACKAGE_DIR}" compiler sysroot
