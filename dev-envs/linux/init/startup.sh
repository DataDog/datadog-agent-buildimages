#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail
PS4='+[$(date +%T.%3N)] '

# This file accumulates all startup logic from every tool and runs when the container starts. Certain tools
# need to be set up during the image entrypoint so that user volumes are available. For example, we need to
# modify the Starship prompt config but we also need the default to be what the user provides. In this case
# we copy what is in the volume to the proper location and then modify that.

# Seed persisted config with image defaults without overwriting user changes.
cp -r --update=none "${DD_DEFAULT_CONFIG_ROOT}/." "${XDG_CONFIG_HOME}/"

# Persist history files
for shell in sh bash zsh; do
    history_file="${DD_SHARED_DIR}/shell/${shell}/.${shell}_history"
    if [[ -f "${history_file}" ]]; then
        ln -s "${history_file}" "${HOME}/.${shell}_history"
    fi
done

if [[ -d "${DD_SHARED_DIR}/shell/nu" ]]; then
    nu_history_dir="${XDG_CONFIG_HOME}/nushell"
    find "${DD_SHARED_DIR}/shell/nu" -name "history.sqlite3*" -type f -print0 | while IFS= read -r -d '' history_file; do
        ln -s "${history_file}" "${nu_history_dir}/$(basename "${history_file}")"
    done
fi

# Remove annoying container indicator from prompt:
# https://github.com/starship/starship/issues/6174
if [[ -f "${DD_SHARED_DIR}/shell/starship.toml" ]]; then
    cp "${DD_SHARED_DIR}/shell/starship.toml" "${XDG_CONFIG_HOME}/starship.toml"
fi
cat <<'EOF' >> "${XDG_CONFIG_HOME}/starship.toml"
[container]
disabled = true
EOF
# https://github.com/starship/starship/issues/896
set-ev STARSHIP_CONFIG "${XDG_CONFIG_HOME}/starship.toml"

# Persist remote SSH servers for VS Code-based editors
vscode_editors_root="${XDG_DATA_HOME}/editors"
if [[ ! -d "${vscode_editors_root}" ]]; then
    mkdir -p "${vscode_editors_root}"
    # Link each top level server directory in the home directory to the data root
    for server_dir in ".vscode-server" ".cursor-server"; do
        # The name of the persisted data directory is the part of the server directory name
        # between the leading dot and the first hyphen
        persisted_name="${server_dir#.}"
        persisted_name="${persisted_name%%-*}"
        persisted_data_dir="${vscode_editors_root}/${persisted_name}"
        mkdir -p "${persisted_data_dir}"
        ln -s "${persisted_data_dir}" "${HOME}/${server_dir}"
    done
fi

# Configure gfold
gfold -d classic "${DD_REPO_ROOT}" --dry-run > "${XDG_CONFIG_HOME}/gfold.toml"

# Configure Git to use the user's name and email
if [[ -n "${GIT_AUTHOR_NAME:-}" ]]; then
    git config --global user.name "${GIT_AUTHOR_NAME}"
fi
if [[ -n "${GIT_AUTHOR_EMAIL:-}" ]]; then
    git config --global user.email "${GIT_AUTHOR_EMAIL}"
fi

# Reset saved data/cache directories from previous runs
dda config restore

# Configure telemetry if enabled
if [[ -n "${DDA_TELEMETRY_API_KEY:-}" ]]; then
    set-ev DDA_TELEMETRY_API_KEY "${DDA_TELEMETRY_API_KEY}"
    dda self telemetry enable
fi
