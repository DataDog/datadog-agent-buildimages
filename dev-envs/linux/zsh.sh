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
    zsh_config_dir="${DD_BUILD_CONFIG_ROOT}/zsh"
    omz_config="${zsh_config_dir}/oh-my-zsh.zsh"
    mkdir -p "${zsh_config_dir}"
    cat <<EOF > "${omz_config}"
export ZSH="\${XDG_DATA_HOME}/oh-my-zsh"
OH_MY_ZSH_COMMIT="${OH_MY_ZSH_COMMIT}"

if [[ ! -f "\${ZSH}/oh-my-zsh.sh" ]]; then
    echo "Setting up Oh My Zsh ..."
    zsh_data_dir="\$(dirname "\${ZSH}")"
    mkdir -p "\${zsh_data_dir}"
    omz_tmp="\$(mktemp -d "\${zsh_data_dir}/oh-my-zsh.tmp.XXXXXX")"
    # Keep full ancestry so Oh My Zsh updates can fast-forward cleanly from the pinned commit.
    git clone --quiet --filter=blob:none --single-branch --no-checkout https://github.com/ohmyzsh/ohmyzsh.git "\${omz_tmp}"
    git -C "\${omz_tmp}" reset --quiet --hard "\${OH_MY_ZSH_COMMIT}"
    # Oh My Zsh's compaudit refuses to load completions from group/other-writable directories.
    chmod -R go-w "\${omz_tmp}"
    rm -rf "\${ZSH}"
    mv "\${omz_tmp}" "\${ZSH}"
fi

ZSH_THEME="robbyrussell"
plugins=(
    git
)

# Use append-only history for bind-mounted history files whose ownership may differ.
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
unsetopt HIST_SAVE_BY_COPY
unsetopt SHARE_HISTORY

source "\${ZSH}/oh-my-zsh.sh"
EOF
)

# Set up Oh My Zsh and Starship toggles.
cat <<'EOF' >> "${HOME}/.zshrc"
# Set up Oh My Zsh.
source "${XDG_CONFIG_HOME}/zsh/oh-my-zsh.zsh"

# Set up Starship.
# eval "$(starship init zsh)"
EOF
