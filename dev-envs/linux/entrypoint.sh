#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

startup_indicator="/.started"

if [[ ! -f "${startup_indicator}" ]]; then
    # 1001 is used by the base build image's default user
    TARGET_UID="${LOCAL_UID:-1002}"
    TARGET_GID="${LOCAL_GID:-1002}"
    TARGET_USER="dd"
    TARGET_GROUP="dd"
    TARGET_HOME="/home/${TARGET_USER}"

    # Create primary user and group
    groupadd -g "${TARGET_GID}" "${TARGET_GROUP}"
    useradd -u "${TARGET_UID}" -g "${TARGET_GID}" -m -d "${TARGET_HOME}" -s /bin/bash "${TARGET_USER}"

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

    # Ensure target home directory exists and is owned by the target user
    mkdir -p "${TARGET_HOME}"
    # Ensure the home directory is owned by the target user and group
    chown -R "${TARGET_UID}:${TARGET_GID}" "${TARGET_HOME}"
    # Ensure the home directory contents are group-writable
    chmod -R g+rwX "${TARGET_HOME}"
    # Ensure new files inherit the primary group inside the home directory
    chmod g+s "${TARGET_HOME}"

    # Ensure cache root is writable by the dev user since named volumes are
    # initially owned by the root user.
    cache_root_group="$(stat -c '%G' "${DD_BUILD_CACHE_ROOT}")"
    cache_root_has_default_acl="false"
    if command -v getfacl >/dev/null 2>&1; then
        if getfacl -cp "${DD_BUILD_CACHE_ROOT}" | grep -Fq "default:group:build-shared:rwx"; then
            cache_root_has_default_acl="true"
        fi
    fi

    if [[ "${cache_root_group}" != "build-shared" ]] || \
       [[ ! -g "${DD_BUILD_CACHE_ROOT}" ]] || \
       [[ "${cache_root_has_default_acl}" != "true" ]]; then
        mkdir -p "${DD_BUILD_CACHE_ROOT}"
        if command -v setfacl >/dev/null 2>&1; then
            # Only touch directories (fast): make them group-writable + setgid, and apply
            # access + default ACLs so future writes remain group-writable regardless of umask.
            find "${DD_BUILD_CACHE_ROOT}" -type d -exec sh -c '\
                chgrp build-shared "$@" && \
                chmod g+rws "$@" && \
                setfacl -m g:build-shared:rwx,m:rwx "$@" && \
                setfacl -d -m g:build-shared:rwx,m:rwx "$@" \
            ' sh {} +
        else
            # Best-effort fallback without ACL support.
            find "${DD_BUILD_CACHE_ROOT}" -type d -exec chgrp build-shared {} +
            find "${DD_BUILD_CACHE_ROOT}" -type d -exec chmod g+rws {} +
        fi
    fi

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
    HOME="${TARGET_HOME}" USER="${TARGET_USER}" gosu "${TARGET_USER}" bash -lc startup

    # Record startup success
    touch "${startup_indicator}"
fi

# On first and subsequent starts, run SSHD as PID 1
exec /usr/local/sbin/sshd -D -e
