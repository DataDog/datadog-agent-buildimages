#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail
PS4='+[$(date +%T.%3N)] '

# Preserve group write on setgid build-shared directories without default ACLs.
umask 0002

TARGET_USER="${DD_TARGET_USER:-dd}"
TARGET_GROUP="${DD_TARGET_GROUP:-${TARGET_USER}}"
TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6 || true)"
if [[ -z "${TARGET_HOME}" ]]; then
    TARGET_HOME="${HOME}"
fi

# Reassert shared-root metadata on every start so it survives root recreation.
/init/ensure-shared-roots.sh

startup_indicator="/.started"
if [[ ! -f "${startup_indicator}" ]]; then
    if ! id "${TARGET_USER}" >/dev/null 2>&1; then
        # Choose a UID higher than the one used by the base build image's default user (1001)
        TARGET_UID="${HOST_UID:-1002}"
        TARGET_GID="${HOST_GID:-${TARGET_UID}}"

        # Create the primary group if the host GID is not already present.
        if ! getent group "${TARGET_GID}" >/dev/null; then
            groupadd -g "${TARGET_GID}" "${TARGET_GROUP}"
        fi
        useradd -u "${TARGET_UID}" -g "${TARGET_GID}" "${TARGET_USER}"
        TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"

        supplemental_groups=(
            # Write access to shared build directories
            build-shared
            # Allow passwordless sudo
            sudo
        )
        for group in "${supplemental_groups[@]}"; do
            usermod -a -G "${group}" "${TARGET_USER}"
        done
    fi

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

    # Make the target home look like a normal user-owned home before startup creates runtime state.
    # As this is only necessary for the initial run of the container, we first verify the correct owner
    # to potentially improve the time it takes to restart.
    if [[ "$(stat -c %U "${TARGET_HOME}")" != "${TARGET_USER}" ]]; then
        chown -R "${TARGET_USER}:" "${TARGET_HOME}"
    fi
    chmod 0755 "${TARGET_HOME}"

    # Persist environment for SSH sessions
    env | grep -Ev "^(HOME=|USER=|MAIL=|LS_COLORS=|HOSTNAME=|PWD=|TERM=|SHLVL=|LANGUAGE=|_=)" >> /etc/environment

    # Run the startup logic as the target user
    HOME="${TARGET_HOME}" USER="${TARGET_USER}" gosu "${TARGET_USER}" /init/startup.sh

    # Record startup success
    touch "${startup_indicator}"
fi

# Start background services immune to SIGHUP so they survive the exec below.
# Child processes inherit the SIG_IGN disposition set by nohup.
HOME="${TARGET_HOME}" USER="${TARGET_USER}" gosu "${TARGET_USER}" nohup /init/run-services.sh &

# Run the CMD defined by the target stage as PID 1
exec "$@"
