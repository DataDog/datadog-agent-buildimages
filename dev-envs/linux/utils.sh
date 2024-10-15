#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

arch=$(uname -m)
if [[ "$arch" == "aarch64" ]]; then
  short_arch="arm64"
  rtarget="aarch64-unknown-linux-gnu"
else
  short_arch="amd64"
  rtarget="${arch}-unknown-linux-musl"
fi

GITUI_VERSION="0.26.3"
curl "https://github.com/extrawurst/gitui/releases/download/v${GITUI_VERSION}/gitui-linux-${arch}.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin --strip-components=1 --wildcards "*/gitui"
chmod +x /usr/local/bin/gitui
rm archive.tar.gz

JQ_VERSION="1.7.1"
curl "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-${short_arch}" -Lo /usr/local/bin/jq
chmod +x /usr/local/bin/jq

RG_VERSION="14.1.1"
curl "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-${rtarget}.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin --strip-components=1 --wildcards "*/rg"
chmod +x /usr/local/bin/rg
rm archive.tar.gz

FD_VERSION="10.2.0"
curl "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-${arch}-unknown-linux-musl.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin --strip-components=1 --wildcards "*/fd"
chmod +x /usr/local/bin/fd
rm archive.tar.gz

BTM_VERSION="0.10.2"
curl "https://github.com/ClementTsang/bottom/releases/download/${BTM_VERSION}/bottom_${arch}-unknown-linux-musl.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin btm
chmod +x /usr/local/bin/btm
rm archive.tar.gz

YAZI_VERSION="0.3.3"
curl "https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-${arch}-unknown-linux-musl.zip" -Lo archive.zip
unzip -j archive.zip "yazi-${arch}-unknown-linux-musl/ya*" -d /usr/local/bin
chmod +x /usr/local/bin/{ya,yazi}
rm archive.zip

FZF_VERSION="0.55.0"
curl "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_${short_arch}.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin fzf
chmod +x /usr/local/bin/fzf
rm archive.tar.gz

EZA_VERSION="0.20.2"
curl "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_${rtarget}.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin --strip-components=1 --wildcards "*/eza"
chmod +x /usr/local/bin/eza
rm archive.tar.gz

HYPERFINE_VERSION="1.18.0"
curl "https://github.com/sharkdp/hyperfine/releases/download/v${HYPERFINE_VERSION}/hyperfine-v${HYPERFINE_VERSION}-${rtarget}.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin --strip-components=1 --wildcards "*/hyperfine"
chmod +x /usr/local/bin/hyperfine
rm archive.tar.gz

BAT_VERSION="0.24.0"
curl "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-${rtarget}.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin --strip-components=1 --wildcards "*/bat"
chmod +x /usr/local/bin/bat
rm archive.tar.gz

AMBR_VERSION="0.6.0"
if [[ $arch == "x86_64" ]]; then
    curl "https://github.com/dalance/amber/releases/download/v${AMBR_VERSION}/amber-v${AMBR_VERSION}-${arch}-lnx.zip" -Lo archive.zip
    unzip -j archive.zip ambr ambs -d /usr/local/bin
    chmod +x /usr/local/bin/{ambr,ambs}
    rm archive.zip
else
  cargo install amber@${AMBR_VERSION}
fi

PROCS_VERSION="0.14.6"
if [[ $arch == "x86_64" ]]; then
    curl "https://github.com/dalance/procs/releases/download/v${PROCS_VERSION}/procs-v${PROCS_VERSION}-${arch}-linux.zip" -Lo archive.zip
    unzip -j archive.zip procs -d /usr/local/bin
    chmod +x /usr/local/bin/procs
    rm archive.zip
else
  cargo install procs@${PROCS_VERSION}
fi
procs --gen-config > "${HOME}/.procs.toml"
# Necessary for working in our containers
sed -i 's/show_self_parents = false/show_self_parents = true/' "${HOME}/.procs.toml"

PDU_VERSION="0.9.3"
if [[ $arch == "x86_64" ]]; then
    curl "https://github.com/KSXGitHub/parallel-disk-usage/releases/download/${PDU_VERSION}/pdu-${arch}-unknown-linux-musl" -Lo /usr/local/bin/pdu
    chmod +x /usr/local/bin/pdu
else
  cargo install parallel-disk-usage@${PDU_VERSION}
fi

DELTA_VERSION="0.18.2"
curl "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-${rtarget}.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin --strip-components=1 --wildcards "*/delta"
chmod +x /usr/local/bin/delta
rm archive.tar.gz
# Configure Git to use delta as the pager:
# https://dandavison.github.io/delta/get-started.html
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global merge.conflictStyle zdiff3

GFOLD_VERSION="4.5.0"
# https://github.com/nickgerace/gfold/issues/260
# Eventually try to download to improve build time, currently the only available
# Linux binary was built on a newer version of glibc and there is no musl build
# if [[ $arch == "x86_64" ]]; then
#     curl "https://github.com/nickgerace/gfold/releases/download/${GFOLD_VERSION}/gfold-linux-gnu-${short_arch}" -Lo /usr/local/bin/gfold
#     chmod +x /usr/local/bin/gfold
# else
#   cargo install gfold@${GFOLD_VERSION}
# fi
cargo install gfold@${GFOLD_VERSION}
mkdir -p "${HOME}/.config"
mkdir -p "${DD_REPOS_DIR}"
gfold -d classic "${DD_REPOS_DIR}" --dry-run > "${HOME}/.config/gfold.toml"

# The following tools are required for Visual Studio Code's Go extension:
# https://github.com/golang/vscode-go#quick-start
#
# If either are unavailable the extension will download upon editor startup which is a poor experience
GOPLS_VERSION="0.16.2"
go install "golang.org/x/tools/gopls@v${GOPLS_VERSION}"

STATICCHECK_VERSION="2024.1.1"
curl "https://github.com/dominikh/go-tools/releases/download/${STATICCHECK_VERSION}/staticcheck_linux_amd64.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin --strip-components=1 --wildcards "*/staticcheck"
chmod +x /usr/local/bin/staticcheck
rm archive.tar.gz
