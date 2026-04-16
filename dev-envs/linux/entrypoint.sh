#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

startup_indicator="/.started"

# Check for the existence of the startup indicator file so that container restarts do not trigger the startup process
if ! [[ -f "${startup_indicator}" ]]; then
    startup

    shell=${DD_SHELL:-"zsh"}
    if [[ "${shell}" == "zsh" ]]; then
        chsh -s /usr/local/bin/zsh
    elif [[ "${shell}" == "nu" ]]; then
        chsh -s "${HOME}/.nushell/nu"
    elif [[ "${shell}" == "bash" ]]; then
        chsh -s /bin/bash
    else
        echo "Unsupported shell: ${shell}"
        exit 1
    fi

    # https://github.com/moby/moby/issues/2569#issuecomment-27973910
    # https://github.com/jenkinsci/docker-ssh-agent/issues/33#issuecomment-597217350
    env | grep -Ev "^(USER=|MAIL=|LS_COLORS=|HOSTNAME=|PWD=|TERM=|SHLVL=|LANGUAGE=|_=)" >> /etc/environment

    # Enable telemetry if the API key is set
    if [[ -n "${DDA_TELEMETRY_API_KEY:-}" ]]; then
        set-ev DDA_TELEMETRY_API_KEY "${DDA_TELEMETRY_API_KEY}"
        dda self telemetry enable
    fi

    # Set Git config
    if [[ -n "${GIT_AUTHOR_NAME:-}" ]]; then
        git config --global user.name "${GIT_AUTHOR_NAME}"
    fi
    if [[ -n "${GIT_AUTHOR_EMAIL:-}" ]]; then
        git config --global user.email "${GIT_AUTHOR_EMAIL}"
    fi

    # Restore default configuration to account for changes during startup like Git author details
    dda config restore

    # Create the startup indicator file
    touch "${startup_indicator}"
fi

/usr/local/sbin/sshd -D -e
