#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail
PS4='+[$(date +%T.%3N)] '

daemon_log="${XDG_DATA_HOME}/editors/.logs/extension-installation.log"
mkdir -p "$(dirname "${daemon_log}")"

# Resume any interrupted extension installation work for already-present server binaries.
/init/scan-editor-servers.sh >> "${daemon_log}" 2>&1 || true

watchexec_args=(
    # Set the project origin to the editors root directory
    --project-origin "${XDG_DATA_HOME}/editors"
    # Prevent unnecessary recursive directory discovery.
    --no-discover-ignore
    # Watch each editor root for the server binaries.
    --watch-non-recursive vscode
    --watch-non-recursive cursor
    # Match only the server binaries for the hash in the filename that can be used
    # to resolve the CLI binary path. The supported glob syntax is documented here:
    # https://docs.rs/globset/#syntax
    --filter "{code,cursor}-[0-9a-fA-F]*"
    # Wait for the first matching event before invoking the scanner again.
    --postpone
    # Trigger only on atomic rename finalization.
    --fs-events rename
    # Coalesce bursts of filesystem events while binaries are being written.
    --debounce 2s
    # Queue one rerun if another event arrives while the scanner is still running.
    --on-busy-update queue
    # Emit triggering events to scanner stdin as JSON lines.
    --emit-events-to json-stdio
    # Execute the scanner command directly without wrapping it in a shell.
    --shell none
    # Our scanner command.
    -- /init/scan-editor-servers.sh
)
watchexec "${watchexec_args[@]}" >> "${daemon_log}" 2>&1 &
