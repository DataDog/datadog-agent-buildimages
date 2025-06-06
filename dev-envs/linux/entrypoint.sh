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
        echo "Enabling telemetry"
        set-ev DDA_TELEMETRY_API_KEY "${DDA_TELEMETRY_API_KEY}"
        dda self telemetry enable
    fi

    # Set Git config
    if [[ -n "${GIT_AUTHOR_NAME:-}" ]]; then
        echo "Setting Git author name: ${GIT_AUTHOR_NAME}"
        git config --global user.name "${GIT_AUTHOR_NAME}"
    fi
    if [[ -n "${GIT_AUTHOR_EMAIL:-}" ]]; then
        echo "Setting Git author email: ${GIT_AUTHOR_EMAIL}"
        git config --global user.email "${GIT_AUTHOR_EMAIL}"
    fi

    # Restore default configuration to account for changes during startup like Git author details
    dda config restore

    # Update the UID/GID of the user to match the host
    if [[ "${RUNNING_IN_DEVCONTAINER:-}" == "true" ]]; then
        if [[ -n "${HOST_GID:-}" ]]; then
            echo "Updating GID to match host: ${HOST_GID}"
            groupmod --gid "${HOST_GID}" datadog
            usermod --gid "${HOST_GID}" datadog
        fi
        if [[ -n "${HOST_UID:-}" ]]; then
            echo "Updating UID to match host: ${HOST_UID}"
            usermod --uid "${HOST_UID}" datadog
        fi

        # Change the ownership of all files to the datadog user
        echo "Changing ownership of all files to datadog:datadog"
        find / -xdev -user 0 -exec chown -h datadog:datadog {} \; 2>/dev/null || true
    fi

    # Create the startup indicator file
    touch "${startup_indicator}"
fi

if [[ "${RUNNING_IN_DEVCONTAINER:-}" == "true" ]]; then
    exec su datadog -c "/usr/local/sbin/sshd -D -e"
else
    /usr/local/sbin/sshd -D -e
fi
