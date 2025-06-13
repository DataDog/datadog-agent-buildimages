#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

VS_CODE_VERSION="1.98.0"

arch=$(uname -m)
if [[ $arch == "aarch64" ]]; then
    DIGEST="1deb69c76288fb2f60a65fdcd0e5e4a484318cb822b88bc3f82ea51e36492460"
    arch="arm64"
else
    DIGEST="7ac5717e59b09ac86b04786f6ff713e83d3744a0d936aeee0608917a765d986c"
    arch="x64"
fi
metadata_url="https://update.code.visualstudio.com/api/versions/${VS_CODE_VERSION}/linux-${arch}/stable"

commit=$(curl -s "${metadata_url}" | jq -r .version)
server_download_url="https://update.code.visualstudio.com/commit:${commit}/server-linux-${arch}/stable"
cli_download_url="https://update.code.visualstudio.com/${VS_CODE_VERSION}/cli-linux-x64/stable"

vscode_root_dir="${HOME}/.vscode-server"
vscode_binary="${vscode_root_dir}/code-${commit}"
vscode_install_dir="${vscode_root_dir}/cli/servers/Stable-${commit}"
vscode_unpack_dir="${vscode_install_dir}/server"

curl "${server_download_url}" -Lo "vscode-server-linux-${arch}.tar.gz"
digest=$(openssl dgst -sha256 "vscode-server-linux-${arch}.tar.gz" | cut -d' ' -f2)
if [[ "${digest}" != "${DIGEST}" ]]; then
    echo "Digest mismatch"
    echo "Expected: ${DIGEST}"
    echo "Got: ${digest}"
    exit 1
fi

mkdir -p "${vscode_unpack_dir}"
tar --no-same-owner -xf "vscode-server-linux-${arch}.tar.gz" -C "${vscode_unpack_dir}" --strip-components 1
rm "vscode-server-linux-${arch}.tar.gz"

curl "${cli_download_url}" -Lo "vscode_cli_alpine_${arch}_cli.tar.gz"
tar --no-same-owner -xf "vscode_cli_alpine_${arch}_cli.tar.gz" -C "${vscode_root_dir}"
mv "${vscode_root_dir}/code" "${vscode_binary}"
rm "vscode_cli_alpine_${arch}_cli.tar.gz"

ln -s "${vscode_root_dir}/cli/servers/Stable-${commit}/server/bin/code-server" /usr/local/bin/code-server

ln -s "${vscode_root_dir}/extensions" "${HOME}/.vscode-extensions"
install-vscode-extensions /setup/default-vscode-extensions.txt
