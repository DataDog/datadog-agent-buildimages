#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# https://zsh.sourceforge.io/FAQ/zshfaq01.html#l7

# NOTE: When updating, switch back to using the official zsh.org URL.
# The sourceforge URL is only used because the official URL is down.
# For version 5.9, we have verified the digest to be the same, but for future releases the official download URL should be used.
# VERSION="5.9"
DIGEST="9b8d1ecedd5b5e81fbf1918e876752a7dd948e05c1a0dba10ab863842d45acd5"
# url="https://www.zsh.org/pub/zsh-${VERSION}.tar.xz"
url="https://sourceforge.net/projects/zsh/files/zsh/5.9/zsh-5.9.tar.xz/download"

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
./configure --with-tcsetpgrp --sysconfdir=/etc/zsh --enable-etcdir=/etc/zsh
make -j "$(nproc)"
make install
popd
rm -rf "${workdir}"

# https://github.com/ohmyzsh/ohmyzsh
OH_MY_ZSH_COMMIT="b26b5002633e865b70e17933536fe4dc99127898"

(
    umask 0002
    mkdir -p "${HOME}/.oh-my-zsh"
    curl -fsSL "https://github.com/ohmyzsh/ohmyzsh/archive/${OH_MY_ZSH_COMMIT}.tar.gz" |
        tar -xz -C "${HOME}/.oh-my-zsh" --strip-components 1

    mkdir -p "${HOME}/.config/zsh"
    cat <<'EOF' > "${HOME}/.config/zsh/oh-my-zsh.zsh"
export ZSH="${HOME}/.oh-my-zsh"
ZSH_THEME="robbyrussell"
zstyle ':omz:update' mode disabled
plugins=(
    git
)

source "${ZSH}/oh-my-zsh.sh"
EOF

    # Set up Oh My Zsh and Starship toggles.
    cat <<'EOF' >> "${HOME}/.zshrc"
source "${HOME}/.config/zsh/oh-my-zsh.zsh"
# eval "$(starship init zsh)"
EOF
)
