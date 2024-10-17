#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

arch=$(uname -m)
if [[ $arch == "aarch64" ]]; then
  short_arch="arm64"
else
  short_arch="amd64"
fi
if [[ $arch == "aarch64" ]]; then
  rtarget="aarch64-unknown-linux-gnu"
else
  rtarget="${arch}-unknown-linux-musl"
fi

JQ_VERSION="1.7.1"
curl "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-${short_arch}" -Lo /usr/local/bin/jq
chmod +x /usr/local/bin/jq

RG_VERSION="14.1.1"
curl "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-${arch}-unknown-linux-musl.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin --strip-components=1 --wildcards "*/rg"
chmod +x /usr/local/bin/rg
rm archive.tar.gz

FD_VERSION="10.2.0"
curl "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-${arch}-unknown-linux-musl.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin --strip-components=1 --wildcards "*/fd"
chmod +x /usr/local/bin/fd
rm archive.tar.gz

BM_VERSION="0.10.2"
curl "https://github.com/ClementTsang/bottom/releases/download/${BM_VERSION}/bottom_${arch}-unknown-linux-musl.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin btm
chmod +x /usr/local/bin/btm
rm archive.tar.gz

DU_VERSION="1.1.1"
curl "https://github.com/bootandy/dust/releases/download/v${DU_VERSION}/dust-v${DU_VERSION}-${arch}-unknown-linux-musl.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin --strip-components=1 --wildcards "*/dust"
chmod +x /usr/local/bin/dust
rm archive.tar.gz

YZ_VERSION="0.3.3"
curl "https://github.com/sxyazi/yazi/releases/download/v${YZ_VERSION}/yazi-${arch}-unknown-linux-musl.zip" -Lo archive.zip
unzip -j archive.zip "yazi-${arch}-unknown-linux-musl/ya*" -d /usr/local/bin
chmod +x /usr/local/bin/{ya,yazi}
rm archive.zip

FZ_VERSION="0.55.0"
curl "https://github.com/junegunn/fzf/releases/download/v${FZ_VERSION}/fzf-${FZ_VERSION}-linux_${short_arch}.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin fzf
chmod +x /usr/local/bin/fzf
rm archive.tar.gz

EZ_VERSION="0.20.2"
curl "https://github.com/eza-community/eza/releases/download/v${EZ_VERSION}/eza_${rtarget}.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin --strip-components=1 --wildcards "*/eza"
chmod +x /usr/local/bin/eza
rm archive.tar.gz

HF_VERSION="1.18.0"
curl "https://github.com/sharkdp/hyperfine/releases/download/v${HF_VERSION}/hyperfine-v${HF_VERSION}-${rtarget}.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin --strip-components=1 --wildcards "*/hyperfine"
chmod +x /usr/local/bin/hyperfine
rm archive.tar.gz

BT_VERSION="0.24.0"
curl "https://github.com/sharkdp/bat/releases/download/v${BT_VERSION}/bat-v${BT_VERSION}-${rtarget}.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin --strip-components=1 --wildcards "*/bat"
chmod +x /usr/local/bin/bat
rm archive.tar.gz

AM_VERSION="0.6.0"
if [[ $arch == "x86_64" ]]; then
    curl "https://github.com/dalance/amber/releases/download/v${AM_VERSION}/amber-v${AM_VERSION}-${arch}-lnx.zip" -Lo archive.zip
    unzip -j archive.zip ambr ambs -d /usr/local/bin
    chmod +x /usr/local/bin/{ambr,ambs}
    rm archive.zip
else
  cargo install amber@${AM_VERSION}
fi

PS_VERSION="0.14.6"
if [[ $arch == "x86_64" ]]; then
    curl "https://github.com/dalance/procs/releases/download/v${PS_VERSION}/procs-v${PS_VERSION}-${arch}-linux.zip" -Lo archive.zip
    unzip -j archive.zip procs -d /usr/local/bin
    chmod +x /usr/local/bin/procs
    rm archive.zip
else
  cargo install procs@${PS_VERSION}
fi

PD_VERSION="0.9.3"
if [[ $arch == "x86_64" ]]; then
    curl "https://github.com/KSXGitHub/parallel-disk-usage/releases/download/${PD_VERSION}/pdu-${arch}-unknown-linux-musl" -Lo /usr/local/bin/pdu
    chmod +x /usr/local/bin/pdu
else
  cargo install parallel-disk-usage@${PS_VERSION}
fi

GF_VERSION="4.5.0"
# https://github.com/nickgerace/gfold/issues/260
# Eventually try to download to improve build time, currently the only available
# Linux binary was built on a newer version of glibc and there is no musl build
# if [[ $arch == "x86_64" ]]; then
#     curl "https://github.com/nickgerace/gfold/releases/download/${GF_VERSION}/gfold-linux-gnu-${short_arch}" -Lo /usr/local/bin/gfold
#     chmod +x /usr/local/bin/gfold
# else
#   cargo install gfold@${GF_VERSION}
# fi
cargo install gfold@${GF_VERSION}
mkdir -p "${HOME}/.config"
mkdir -p "${DD_REPOS_DIR}"
gfold -d classic "${DD_REPOS_DIR}" --dry-run > "${HOME}/.config/gfold.toml"

# The following tools are required for Visual Studio Code's Go extension:
# https://github.com/golang/vscode-go#quick-start
#
# If either are unavailable the extension will download upon editor startup which is a poor experience
GP_VERSION="0.16.2"
go install "golang.org/x/tools/gopls@v${GP_VERSION}"

GSC_VERSION="2024.1.1"
curl "https://github.com/dominikh/go-tools/releases/download/${GSC_VERSION}/staticcheck_linux_amd64.tar.gz" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C /usr/local/bin --strip-components=1 --wildcards "*/staticcheck"
chmod +x /usr/local/bin/staticcheck
rm archive.tar.gz
