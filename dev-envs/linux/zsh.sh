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

# https://github.com/ohmyzsh/ohmyzsh#basic-installation
OH_MY_ZSH_COMMIT="61bacd95b285a9792a05d1c818d9cee15ebe53c6"

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/${OH_MY_ZSH_COMMIT}/tools/install.sh)"

# Fix locale broken by Oh My Zsh:
# https://github.com/starship/starship/issues/2176#issuecomment-1783086362
cat <<'EOF' >> "${HOME}/.zshrc"
export LC_ALL="C.UTF-8"
export LANG="C.UTF-8"
EOF
