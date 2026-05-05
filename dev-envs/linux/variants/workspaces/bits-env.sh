# shellcheck shell=sh
if [ "$(id -un 2>/dev/null)" = "bits" ]; then
    export XDG_BIN_HOME="${HOME}/.local/bin"
fi
