#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail
PS4='+[$(date +%T.%3N)] '

TARGET_USER="dd"
TARGET_GROUP="dd"

# Reassert shared-root metadata on every start so it survives root recreation.
/init/ensure-shared-roots.sh

startup_indicator="/.started"
if [[ ! -f "${startup_indicator}" ]]; then
    # Choose a UID higher than the one used by the base build image's default user (1001)
    TARGET_UID="${HOST_UID:-1002}"
    TARGET_GID="${HOST_GID:-${TARGET_UID}}"

    # Create primary user and group
    groupadd -g "${TARGET_GID}" "${TARGET_GROUP}"
    useradd -u "${TARGET_UID}" -g "${TARGET_GID}" "${TARGET_USER}"

    supplemental_groups=(
        # Write access to shared build directories
        build-shared
        # Allow passwordless sudo
        sudo
    )
    for group in "${supplemental_groups[@]}"; do
        usermod -a -G "${group}" "${TARGET_USER}"
    done

    # Allow passwordless SSH login for the target user
    passwd -d "${TARGET_USER}"
    usermod -U "${TARGET_USER}"

    # Choose login shell for the target user
    shell="${DD_SHELL:-zsh}"
    if [[ "${shell}" == "zsh" ]]; then
        chsh -s /usr/local/bin/zsh "${TARGET_USER}"
    elif [[ "${shell}" == "nu" ]]; then
        chsh -s /usr/local/bin/nu "${TARGET_USER}"
    elif [[ "${shell}" == "bash" ]]; then
        chsh -s /bin/bash "${TARGET_USER}"
    else
        echo "Unsupported shell: ${shell}"
        exit 1
    fi

    # Persist environment for SSH sessions
    env | grep -Ev "^(HOME=|USER=|MAIL=|LS_COLORS=|HOSTNAME=|PWD=|TERM=|SHLVL=|LANGUAGE=|_=)" >> /etc/environment

    # Run the startup logic as the target user
    USER="${TARGET_USER}" gosu "${TARGET_USER}" /init/startup.sh

    # Record startup success
    touch "${startup_indicator}"
fi

# Start background services immune to SIGHUP so they survive the exec below.
# Child processes inherit the SIG_IGN disposition set by nohup.
gosu "${TARGET_USER}" nohup /init/run-services.sh &

# Run the CMD defined by the target stage as PID 1
exec "$@"
