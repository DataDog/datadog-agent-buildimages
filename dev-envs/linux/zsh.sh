#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# https://zsh.sourceforge.io/FAQ/zshfaq01.html#l7

VERSION="5.9"
DIGEST="9b8d1ecedd5b5e81fbf1918e876752a7dd948e05c1a0dba10ab863842d45acd5"
url="https://sourceforge.net/projects/zsh/files/zsh/${VERSION}/zsh-${VERSION}.tar.xz/download"

archive_name=$(basename "${url}")
workdir="/tmp/setup-${archive_name}"
mkdir -p "${workdir}"
curl "${url}" -Lo "${workdir}/${archive_name}"

digest=$(openssl dgst -sha256 "${workdir}/${archive_name}" | cut -d' ' -f2)
if [[ "${digest}" != "${DIGEST}" ]]; then
    echo "Digest mismatch"
    echo "Expected: ${DIGEST}"
    echo "Got: ${digest}"
    exit 1
fi

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
