#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# The server can be an optional second argument, defaulting to VS Code's binary
server_name="${2:-code-server}"
xargs -a "$1" -L 1 "${server_name}" --accept-server-license-terms --force --install-extension
