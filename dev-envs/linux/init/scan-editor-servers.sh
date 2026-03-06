#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail
PS4='+[$(date +%T.%3N)] '

manifest_path="/etc/default-vscode-extensions.json"
if [[ -f "${DD_SHARED_DIR}/editors/default-vscode-extensions.json" ]]; then
    manifest_path="${DD_SHARED_DIR}/editors/default-vscode-extensions.json"
fi

editors_root="${XDG_DATA_HOME}/editors"
declare -A editor_by_server_binary=()

register_server_binary() {
    local server_binary="$1"
    if [[ "${server_binary}" =~ ^${editors_root}/vscode/code-[[:xdigit:]]+$ ]]; then
        editor_by_server_binary["${server_binary}"]="vscode"
    elif [[ "${server_binary}" =~ ^${editors_root}/cursor/cursor-[[:xdigit:]]+$ ]]; then
        editor_by_server_binary["${server_binary}"]="cursor"
    fi
}

# With --emit-events-to json-stdio, watchexec sends one JSON event per line.
while IFS= read -r event_json; do
    [[ -n "${event_json}" ]] || continue

    # From each watchexec JSON event, extract only rename targets (Name(To)) which are files,
    # so temporary/source paths (Name(From)) never trigger extension installation.
    mapfile -t event_paths < <(
        jq -r '
            if any(.tags[]?; .kind == "fs" and ((.full // "") | test("Name\\(To\\)"))) then
                (.tags[]? | select(.kind == "path" and ((.filetype // "") == "file")) | .absolute) // empty
            else
                empty
            end
        ' <<< "${event_json}" || true
    )

    for event_path in "${event_paths[@]}"; do
        [[ -n "${event_path}" ]] || continue
        register_server_binary "${event_path}"
    done
done

# TODO: Remove this when watchexec sends an event for every matched filter
#       on startup, see: https://github.com/watchexec/watchexec/issues/992
# Watchexec startup run has no event payload; sweep existing binaries so
# interrupted extension installs can resume after container restarts.
# Extensions are shared across servers of the same type, so only the most
# recently modified binary per editor is needed for recovery.
if [[ "${#editor_by_server_binary[@]}" -eq 0 ]]; then
    newest_by_editor() {
        local pattern="$1"
        shopt -s nullglob
        local candidates=($pattern)
        shopt -u nullglob
        local newest=""
        for candidate in "${candidates[@]}"; do
            [[ -f "${candidate}" ]] || continue
            if [[ -z "${newest}" ]] || [[ "${candidate}" -nt "${newest}" ]]; then
                newest="${candidate}"
            fi
        done
        if [[ -n "${newest}" ]]; then
            echo "${newest}"
        fi
    }

    for newest in \
        "$(newest_by_editor "${editors_root}/vscode/code-*")" \
        "$(newest_by_editor "${editors_root}/cursor/cursor-*")"
    do
        [[ -n "${newest}" ]] || continue
        register_server_binary "${newest}"
    done
fi

for server_binary in "${!editor_by_server_binary[@]}"; do
    editor_name="${editor_by_server_binary["${server_binary}"]}"
    /init/install-vscode-extensions.sh "${manifest_path}" "${editor_name}" "${server_binary}" || \
        echo "Extension installation failed for ${editor_name} server ${server_binary}, will retry later." >&2
done
