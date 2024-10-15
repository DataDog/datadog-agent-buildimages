#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# https://zsh.sourceforge.io/FAQ/zshfaq01.html#l7

VERSION="5.9"
url="https://www.zsh.org/pub/zsh-${VERSION}.tar.xz"

archive_name=$(basename "${url}")
workdir="/tmp/setup-${archive_name}"
mkdir -p "${workdir}"
curl "${url}" -Lo "${workdir}/${archive_name}"
tar -xf "${workdir}/${archive_name}" -C "${workdir}" --strip-components 1

pushd "${workdir}"
./configure --with-tcsetpgrp
make -j "$(nproc)"
make install
popd
rm -rf "${workdir}"
