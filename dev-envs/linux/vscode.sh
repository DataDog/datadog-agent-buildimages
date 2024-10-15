#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# glibc version 2.28 or higher is now required and support for older machines ends in February 2025.
# Building from source is difficult on this very old architecture and I was unable to get cross
# compilation to work without build errors. This needs to happen sometime in the next few months.
# - https://aka.ms/vscode-remote/faq/old-linux
# - https://github.com/microsoft/vscode/issues/203967#issuecomment-1923440629
# - https://github.com/microsoft/vscode/issues/203375
# - https://github.com/microsoft/vscode/wiki/How-to-Contribute#prerequisites
VERSION="1.85.2"

arch=$(uname -m)
if [[ $arch == "aarch64" ]]; then
  arch="arm64"
else
  arch="x64"
fi
metadata_url="https://update.code.visualstudio.com/api/versions/${VERSION}/linux-${arch}/stable"

commit=$(curl -s "${metadata_url}" | jq -r .version)
server_download_url="https://update.code.visualstudio.com/commit:${commit}/server-linux-${arch}/stable"
cli_download_url="https://update.code.visualstudio.com/${VERSION}/cli-linux-x64/stable"

vscode_root_dir="${HOME}/.vscode-server"
vscode_binary="${vscode_root_dir}/code-${commit}"
vscode_install_dir="${vscode_root_dir}/cli/servers/Stable-${commit}"
vscode_unpack_dir="${vscode_install_dir}/server"

curl "${server_download_url}" -Lo "vscode-server-linux-${arch}.tar.gz"
mkdir -p "${vscode_unpack_dir}"
tar --no-same-owner -xf "vscode-server-linux-${arch}.tar.gz" -C "${vscode_unpack_dir}" --strip-components 1
rm "vscode-server-linux-${arch}.tar.gz"

curl "${cli_download_url}" -Lo "vscode_cli_alpine_${arch}_cli.tar.gz"
tar --no-same-owner -xf "vscode_cli_alpine_${arch}_cli.tar.gz" -C "${vscode_root_dir}"
mv "${vscode_root_dir}/code" "${vscode_binary}"
rm "vscode_cli_alpine_${arch}_cli.tar.gz"

ln -s "${vscode_root_dir}/cli/servers/Stable-${commit}/server/bin/code-server" /usr/local/bin/code-server

# Found in:
# https://github.com/microsoft/vscode/blob/1.94.2/resources/server/bin/helpers/check-requirements-linux.sh#L21
#
# It appears to be doing nothing, https://github.com/microsoft/vscode/issues/231537
#
# We still install during the build to install extensions which are persisted across VS Code versions.
touch "/tmp/vscode-skip-server-requirements-check"

install-vscode-extensions /setup/default-vscode-extensions.txt
