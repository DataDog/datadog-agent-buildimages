#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail
PS4='+[$(date +%T.%3N)] '

startup_indicator="/.started"
TARGET_USER="dd"
TARGET_GROUP="dd"

# Reassert shared-root metadata on every start so it survives root recreation.
/init/ensure-shared-roots.sh

if [[ ! -f "${startup_indicator}" ]]; then
    # 1001 is used by the base build image's default user
    if [[ -n "${HOST_UID:-}" ]]; then
        legacy_tooling=false
        TARGET_UID="${HOST_UID}"
        TARGET_GID="${HOST_GID:-${HOST_UID}}"
    else
        legacy_tooling=true
        TARGET_UID="${HOST_UID:-1002}"
        TARGET_GID="${HOST_GID:-1002}"
    fi
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

    if [[ "${legacy_tooling}" == "true" ]]; then
        cp -a "${HOME}/." /root/
        set-ev DD_SHARED_DIR /root/.shared
        set-ev DD_REPOS_DIR /root/repos
    fi

    # Choose login shell for the target user
    if [[ "${legacy_tooling}" == "true" ]]; then
        chsh_user="root"
    else
        chsh_user="${TARGET_USER}"
    fi
    shell="${DD_SHELL:-zsh}"
    if [[ "${shell}" == "zsh" ]]; then
        chsh -s /usr/local/bin/zsh "${chsh_user}"
    elif [[ "${shell}" == "nu" ]]; then
        chsh -s /usr/local/bin/nu "${chsh_user}"
    elif [[ "${shell}" == "bash" ]]; then
        chsh -s /bin/bash "${chsh_user}"
    else
        echo "Unsupported shell: ${shell}"
        exit 1
    fi

    # Persist environment for SSH sessions
    env | grep -Ev "^(HOME=|USER=|MAIL=|LS_COLORS=|HOSTNAME=|PWD=|TERM=|SHLVL=|LANGUAGE=|_=)" >> /etc/environment

    # Run the startup logic as the target user
    if [[ "${legacy_tooling}" == "true" ]]; then
        /init/startup.sh
    else
        USER="${TARGET_USER}" gosu "${TARGET_USER}" /init/startup.sh
    fi

    # Record startup success
    touch "${startup_indicator}"
fi

# Start background services immune to SIGHUP so they survive the exec below.
# Child processes inherit the SIG_IGN disposition set by nohup.
gosu "${TARGET_USER}" nohup /init/run-services.sh &

# On first and subsequent starts, run SSHD as PID 1
exec /usr/local/sbin/sshd -D -e
