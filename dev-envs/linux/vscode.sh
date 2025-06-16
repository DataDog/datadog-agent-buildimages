#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

VSCODE_VERSION="1.101.0"
CURSOR_VERSION="1.1.3"

arch=$(uname -m)
if [[ $arch == "aarch64" ]]; then
    arch="arm64"
    VSCODE_SERVER_DIGEST="64a4f3030995ae2143d73edec32bf6213607125448157d7f3a485b2e7c547a91"
    VSCODE_CLI_DIGEST="97b1f372294e8bd56a540d49d3224c92678a16cbd1d44178acf52f4ff2d81b36"
    CURSOR_SERVER_DIGEST="d8d5cf4d9b73e144995d286ee91df0f5a3ada62f2517f76e1626d048cb8545b2"
    CURSOR_CLI_DIGEST="5a2d4e75ec0f38aefc6d77968374f0ab20dd1f932175400a51ff04f29555fd62"
else
    arch="x64"
    VSCODE_SERVER_DIGEST="2480b91d84770ff2eafe31689e2fd24541258ae43bdadddf491395498a234d66"
    VSCODE_CLI_DIGEST="e5c6d8e350cf5c6c82af799cdf434ae998a5eb39fe54d821c850d8f9971daead"
    CURSOR_SERVER_DIGEST="0a8ca01323e61a0cd5ad2644b1bd05ace0c847b0e7dcda1d0db904f99f473ff2"
    CURSOR_CLI_DIGEST="03fffda66ca8aab163144c71c3e337e9a92f7e577a018e0921d4d6314e790708"
fi

# VS Code
vscode_metadata_url="https://update.code.visualstudio.com/api/versions/${VSCODE_VERSION}/linux-${arch}/stable"
vscode_commit=$(curl -s "${vscode_metadata_url}" | jq -r .version)
vscode_server_url="https://update.code.visualstudio.com/commit:${vscode_commit}/server-linux-${arch}/stable"
vscode_cli_url="https://update.code.visualstudio.com/${VSCODE_VERSION}/cli-linux-${arch}/stable"

# Cursor
cursor_metadata_url="https://raw.githubusercontent.com/oslook/cursor-ai-downloads/refs/heads/main/version-history.json"
# {"versions": [{"version": "...", "platforms": {...}}, ...]}
cursor_artifact_url=$(curl -s "${cursor_metadata_url}" | jq -r --arg version "${CURSOR_VERSION}" '.versions[] | select(.version == $version) | .platforms["linux-x64"]')
# https://downloads.cursor.com/production/<COMMIT>/<PLATFORM>/<ARCH>/<ARTIFACT>
cursor_commit=$(echo "${cursor_artifact_url}" | cut -d'/' -f5)
# The direct links always have `0` as the last character for some reason, perhaps an attempt at obfuscation
cursor_commit_id="${cursor_commit%?}0"
# Path from the official AppImage artifacts under `/usr/share/cursor/resources/app/product.json`
cursor_server_url="https://cursor.blob.core.windows.net/remote-releases/${CURSOR_VERSION}-${cursor_commit_id}/vscode-reh-linux-${arch}.tar.gz"
# Path from intercepting `wget` calls
cursor_cli_url="https://cursor.blob.core.windows.net/remote-releases/${cursor_commit_id}/cli-alpine-${arch}.tar.gz"

# Create shared extensions directory
extensions_root_dir="${HOME}/.vscode-extensions"
mkdir -p "${extensions_root_dir}"

# Create function to install VS Code server
function install_vscode() {
    commit="$1"
    root_dir_name="$2"
    server_download_url="$3"
    server_digest="$4"
    cli_download_url="$5"
    cli_digest="$6"

    root_dir="${HOME}/${root_dir_name}"
    install_dir="${root_dir}/cli/servers/Stable-${commit}"
    unpack_dir="${install_dir}/server"

    curl "${server_download_url}" -Lo "vscode_server.tar.gz"
    digest=$(openssl dgst -sha256 "vscode_server.tar.gz" | cut -d' ' -f2)
    if [[ "${digest}" != "${server_digest}" ]]; then
        echo "Digest mismatch"
        echo "Expected: ${server_digest}"
        echo "Got: ${digest}"
        exit 1
    fi

    mkdir -p "${unpack_dir}"
    tar --no-same-owner -xf "vscode_server.tar.gz" -C "${unpack_dir}" --strip-components 1
    rm "vscode_server.tar.gz"

    # Inside the bin directory there will be a binary called `code-server`, `cursor-server`, etc.
    # We need to capture the first word of the name (e.g. `code` or `cursor`) for use later
    bin_dir="${unpack_dir}/bin"
    binary_name=""
    pushd "${bin_dir}"
    for binary in *; do
        if [[ "${binary}" =~ ^([^-]+)-server$ ]]; then
            binary_name="${BASH_REMATCH[1]}"
        fi
    done
    popd

    if [[ -z "${binary_name}" ]]; then
        echo "Could not find server binary in ${bin_dir}"
        exit 1
    fi
    ln -s "${bin_dir}/${binary_name}-server" "/usr/local/bin/${binary_name}-server"

    curl "${cli_download_url}" -Lo "vscode_cli.tar.gz"
    digest=$(openssl dgst -sha256 "vscode_cli.tar.gz" | cut -d' ' -f2)
    if [[ "${digest}" != "${cli_digest}" ]]; then
        echo "Digest mismatch"
        echo "Expected: ${cli_digest}"
        echo "Got: ${digest}"
        exit 1
    fi
    tar --no-same-owner -xf "vscode_cli.tar.gz" -C "${root_dir}"
    mv "${root_dir}/${binary_name}" "${root_dir}/${binary_name}-${commit}"
    rm "vscode_cli.tar.gz"

    extensions_dir="${extensions_root_dir}/${binary_name}"
    mkdir -p "${extensions_dir}"
    ln -s "${extensions_dir}" "${root_dir}/extensions"

    install-vscode-extensions /setup/default-vscode-extensions.txt "${binary_name}-server"
}

install_vscode \
    "${vscode_commit}" \
    ".vscode-server" \
    "${vscode_server_url}" \
    "${VSCODE_SERVER_DIGEST}" \
    "${vscode_cli_url}" \
    "${VSCODE_CLI_DIGEST}"

install_vscode \
    "${cursor_commit_id}" \
    ".cursor-server" \
    "${cursor_server_url}" \
    "${CURSOR_SERVER_DIGEST}" \
    "${cursor_cli_url}" \
    "${CURSOR_CLI_DIGEST}"
