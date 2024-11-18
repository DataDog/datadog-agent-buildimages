#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# This file accumulates all startup logic from every tool and runs when the container starts. Certain tools
# need to be set up during the image entrypoint so that user volumes are available. For example, we need to
# modify the Starship prompt config but we also need the default to be what the user provides. In this case
# we copy what is in the volume to the proper location and then modify that.

# Persist history files
for shell in sh bash zsh; do
    history_file="${DD_SHARED_DIR}/shell/${shell}/.${shell}_history"
    if [[ -f "${history_file}" ]]; then
        ln -s "${history_file}" "${HOME}/.${shell}_history"
    fi
done

if [[ -d "${DD_SHARED_DIR}/shell/nu" ]]; then
    nu_history_dir="$(dirname "${NUSHELL_ENV_FILE}")"
    find "${DD_SHARED_DIR}/shell/nu" -name "history.sqlite3*" -type f -print0 | while IFS= read -r -d '' history_file; do
        ln -s "${history_file}" "${nu_history_dir}/$(basename "${history_file}")"
    done
fi

# Remove annoying container indicator from prompt:
# https://github.com/starship/starship/issues/6174
mkdir -p "${HOME}/.config"
if [[ -f "${DD_SHARED_DIR}/shell/starship.toml" ]]; then
    cp "${DD_SHARED_DIR}/shell/starship.toml" "${HOME}/.config/starship.toml"
fi
cat <<'EOF' >> "${HOME}/.config/starship.toml"
[container]
disabled = true
EOF
