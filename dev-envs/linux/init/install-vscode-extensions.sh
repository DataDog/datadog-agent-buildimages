#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail
PS4='+[$(date +%T.%3N)] '

if [[ "$#" -ne 3 ]]; then
    echo "Usage: install-vscode-extensions <manifest-json> <editor> <server-binary>" >&2
    exit 1
fi

manifest_path="$1"
editor_name="$2"
server_binary="$3"

server_dir="$(dirname "${server_binary}")"
server_basename="$(basename "${server_binary}")"
prefix="${server_basename%%-*}"
commit_hash="${server_basename#*-}"

extensions_manifest="${server_dir}/extensions/extensions.json"

resolve_cli_binary() {
    local channel candidate
    for channel in Stable Insiders; do
        candidate="${server_dir}/cli/servers/${channel}-${commit_hash}/server/bin/${prefix}-server"
        if [[ -x "${candidate}" ]]; then
            echo "${candidate}"
            return 0
        fi
    done
    return 1
}

installed_ids() {
    if [[ -f "${extensions_manifest}" ]]; then
        jq -r '.[].identifier.id' "${extensions_manifest}"
    fi
}

mapfile -t desired < <(
    jq -r --arg editor "${editor_name}" \
        'to_entries[] | select(.value | index($editor)) | .key' \
        "${manifest_path}"
)

if [[ "${#desired[@]}" -eq 0 ]]; then
    echo "No extensions to install for ${editor_name}"
    exit 0
fi

mapfile -t installed < <(installed_ids)
declare -A installed_set=()
for id in "${installed[@]}"; do
    installed_set["${id}"]=1
done

missing=()
for ext in "${desired[@]}"; do
    if [[ -z "${installed_set["${ext}"]:-}" ]]; then
        missing+=("${ext}")
    fi
done

if [[ "${#missing[@]}" -eq 0 ]]; then
    echo "All extensions already installed for ${editor_name}"
    exit 0
fi

cli_binary=""
timeout=300
interval=2
elapsed=0
while true; do
    if cli_binary="$(resolve_cli_binary)"; then
        break
    fi
    if [[ ! -f "${server_binary}" ]]; then
        echo "Server binary disappeared, aborting" >&2
        exit 1
    fi
    if [[ "${elapsed}" -ge "${timeout}" ]]; then
        echo "Timed out waiting for CLI binary after ${timeout}s" >&2
        exit 1
    fi
    sleep "${interval}"
    elapsed=$((elapsed + interval))
done

failed=false
for ext in "${missing[@]}"; do
    if "${cli_binary}" --accept-server-license-terms --install-extension "${ext}"; then
        echo "Installed extension: ${ext}"
    else
        echo "Failed to install extension: ${ext}" >&2
        failed=true
    fi
done

if [[ "${failed}" == "true" ]]; then
    exit 1
fi
