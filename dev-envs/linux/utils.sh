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

install-binary \
    --version "0.26.3" \
    --digest "95a9570dd98789e710e27a00f60413a959d9448d8a0a945af5b7c3c0883fe2df" \
    --digest "0f08d966bb6d3774a5045f22ec8389073a650d331b26d88fb7a228ed780ac6a6" \
    --url "https://github.com/extrawurst/gitui/releases/download/v{{version}}/gitui-linux-${arch}.tar.gz" \
    --name "gitui"

install-binary \
    --version "1.7.1" \
    --digest "5942c9b0934e510ee61eb3e30273f1b3fe2590df93933a93d7c58b81d19c8ff5" \
    --digest "4dd2d8a0661df0b22f1bb9a1f9830f06b6f3b8f7d91211a1ef5d7c4f06a8b4a5" \
    --url "https://github.com/jqlang/jq/releases/download/jq-{{version}}/jq-linux-${short_arch}" \
    --name "jq"

install-binary \
    --version "14.1.1" \
    --digest "4cf9f2741e6c465ffdb7c26f38056a59e2a2544b51f7cc128ef28337eeae4d8e" \
    --digest "c827481c4ff4ea10c9dc7a4022c8de5db34a5737cb74484d62eb94a95841ab2f" \
    --url "https://github.com/BurntSushi/ripgrep/releases/download/{{version}}/ripgrep-{{version}}-${rtarget}.tar.gz" \
    --name "rg"

install-binary \
    --version "10.2.0" \
    --digest "d9bfa25ec28624545c222992e1b00673b7c9ca5eb15393c40369f10b28f9c932" \
    --digest "4e8e596646d047d904f2c5ca74b39dccc69978b6e1fb101094e534b0b59c1bb0" \
    --url "https://github.com/sharkdp/fd/releases/download/v{{version}}/fd-v{{version}}-${arch}-unknown-linux-musl.tar.gz" \
    --name "fd"

install-binary \
    --version "0.10.2" \
    --digest "520c9e3f1c2e9f076693b59277b680806670af8fb5bea2a9feecc6176dc6a151" \
    --digest "6ac953d3d95d06aa1864c85ba99bdca2e9d9b8f1ff0619213c980714b1a641f7" \
    --url "https://github.com/ClementTsang/bottom/releases/download/{{version}}/bottom_${arch}-unknown-linux-musl.tar.gz" \
    --name "btm" \
    --top-level

install-binary \
    --version "0.3.3" \
    --digest "fca5dad0c292864c4725fc15a4c29292797fc65d9d89015db771c961dbe30a9b" \
    --digest "23c211c13fb6129c6b9b018594ae8e4a8ef3cb9401a9bcbe24e2cdfa58593bfa" \
    --url "https://github.com/sxyazi/yazi/releases/download/v{{version}}/yazi-${arch}-unknown-linux-musl.zip" \
    --name "ya" \
    --name "yazi" \
    --unpack-command "unzip -j \"{{file_path}}\" \"yazi-${arch}-unknown-linux-musl/ya*\" -d /usr/local/bin"

install-binary \
    --version "0.55.0" \
    --digest "4df2393776942780ddab2cea713ddaac06cd5c3886cd23bc9119a6d3aa1e02bd" \
    --digest "7affbfb35ed2da650da7b62a9590eb9bc2fb083cfe055c9f4c794b0bbfeaefcc" \
    --url "https://github.com/junegunn/fzf/releases/download/v{{version}}/fzf-{{version}}-linux_${short_arch}.tar.gz" \
    --name "fzf" \
    --top-level

install-binary \
    --version "0.20.2" \
    --digest "5bdf1a4b63783962ff99629ea6e06b08cff812b4b564ba3982ab73d053a7d7fd" \
    --digest "720b00b9f1244253600aecbc3377d5e5df886a6d0301d8a3c3ee917961586718" \
    --url "https://github.com/eza-community/eza/releases/download/v{{version}}/eza_${rtarget}.tar.gz" \
    --name "eza"

install-binary \
    --version "1.18.0" \
    --digest "ef3855ad6a1bf97055a90dc3dfc5d4a48494cb80344027db932a96341d415193" \
    --digest "1174db3a55247a89d8f6161101e15455a2ebdca6948d42e9bc50b78c1d771e4a" \
    --url "https://github.com/sharkdp/hyperfine/releases/download/v{{version}}/hyperfine-v{{version}}-${rtarget}.tar.gz" \
    --name "hyperfine"

install-binary \
    --version "0.24.0" \
    --digest "d39a21e3da57fe6a3e07184b3c1dc245f8dba379af569d3668b6dcdfe75e3052" \
    --digest "feccae9a0576d97609c57e32d3914c5116136eab0df74c2ab74ef397d42c5b10" \
    --url "https://github.com/sharkdp/bat/releases/download/v{{version}}/bat-v{{version}}-${rtarget}.tar.gz" \
    --name "bat"

AMBR_VERSION="0.6.0"
if [[ $arch == "x86_64" ]]; then
    install-binary \
        --version "${AMBR_VERSION}" \
        --digest "139630ebdbd1170efc92892b64bf2e48d18f1cd38e48c501c045af1e5852ad66" \
        --url "https://github.com/dalance/amber/releases/download/v{{version}}/amber-v{{version}}-${arch}-lnx.zip" \
        --name "ambr" \
        --name "ambs"
else
    cargo install --locked amber@${AMBR_VERSION}
fi

PROCS_VERSION="0.14.6"
if [[ $arch == "x86_64" ]]; then
    install-binary \
        --version "${PROCS_VERSION}" \
        --digest "90d4d9dd6d1f9894169632c8316e46ff2e696ad0e3b950698aa1c52d74c013dd" \
        --url "https://github.com/dalance/procs/releases/download/v{{version}}/procs-v{{version}}-${arch}-linux.zip" \
        --name "procs"
else
    cargo install --locked procs@${PROCS_VERSION}
fi
procs --gen-config > "${HOME}/.procs.toml"
# Necessary for working in our containers
sed -i 's/show_self_parents = false/show_self_parents = true/' "${HOME}/.procs.toml"

PDU_VERSION="0.11.0"
if [[ $arch == "x86_64" ]]; then
    install-binary \
        --version "${PDU_VERSION}" \
        --digest "7da2abd0c438e0317271b34e4122d1d5818b124e3d70867309d4a92bfb34ac69" \
        --url "https://github.com/KSXGitHub/parallel-disk-usage/releases/download/{{version}}/pdu-${arch}-unknown-linux-musl" \
        --name "pdu"
else
    cargo install --locked parallel-disk-usage@${PDU_VERSION}
fi

install-binary \
    --version "0.18.2" \
    --digest "b7ea845004762358a00ef9127dd9fd723e333c7e4b9cb1da220c3909372310ee" \
    --digest "adf7674086daa4582f598f74ce9caa6b70c1ba8f4a57d2911499b37826b014f9" \
    --url "https://github.com/dandavison/delta/releases/download/{{version}}/delta-{{version}}-${rtarget}.tar.gz" \
    --name "delta"
# Configure Git to use delta as the pager:
# https://dandavison.github.io/delta/get-started.html
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global merge.conflictStyle zdiff3

install-binary \
    --version "2025.2.1-ofek-1" \
    --digest "f12e13b8e2a64595491a340a46b19f545de55be1be396fcb745a1494103f0ac6" \
    --digest "4e9f6d84eb774ef192639b72f4d2f2db70556ffd77d2816d34efc19a7d271703" \
    --url "https://github.com/nickgerace/gfold/releases/download/{{version}}/gfold-linux-musl-${arch//_/-}" \
    --name "gfold"
mkdir -p "${HOME}/.config"
mkdir -p "${DD_REPOS_DIR}"
gfold -d classic "${DD_REPOS_DIR}" --dry-run > "${HOME}/.config/gfold.toml"

# The following tools are required for Visual Studio Code's Go extension:
# https://github.com/golang/vscode-go#quick-start
#
# If either are unavailable the extension will download upon editor startup which is a poor experience
GOPLS_VERSION="0.16.2"
go install "golang.org/x/tools/gopls@v${GOPLS_VERSION}"

install-binary \
    --version "2024.1.1" \
    --digest "6e9398fcaff2b36e1d15e84a647a3a14733b7c2dd41187afa2c182a4c3b32180" \
    --digest "4cf69c1f5cdd86810a07d830ff90c253e8da8a5817bb57caee8c9807493fc557" \
    --url "https://github.com/dominikh/go-tools/releases/download/{{version}}/staticcheck_linux_${short_arch}.tar.gz" \
    --name "staticcheck"
