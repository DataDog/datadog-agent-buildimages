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

startup_indicator="/.started"

# On first start, realign the image-provided user to the host's UID/GID before anything
# else runs. This must happen up front because the startup below writes host-owned
# files, and because editors and CLIs exec in as this user as soon as the container
# runs, so it must already exist with the right IDs. The image normally pre-creates the
# user, so this only adjusts its IDs; the fallback handles images that do not.
if [[ ! -f "${startup_indicator}" ]]; then
    TARGET_UID="${HOST_UID:-}"
    TARGET_GID="${HOST_GID:-${TARGET_UID}}"

    if ! id "${TARGET_USER}" >/dev/null 2>&1; then
        # Create the user when the image did not pre-create it.
        TARGET_UID="${TARGET_UID:-1000}"
        TARGET_GID="${TARGET_GID:-${TARGET_UID}}"
        getent group "${TARGET_GID}" >/dev/null || groupadd -g "${TARGET_GID}" "${TARGET_GROUP}"
        useradd -u "${TARGET_UID}" -g "${TARGET_GID}" -G build-shared,sudo "${TARGET_USER}"
    elif [[ -n "${TARGET_UID}" ]]; then
        # Realign the pre-created user's GID and then its UID to the host's.
        if [[ "$(id -g "${TARGET_USER}")" != "${TARGET_GID}" ]]; then
            if getent group "${TARGET_GID}" >/dev/null; then
                usermod -g "${TARGET_GID}" "${TARGET_USER}"
            else
                groupmod -g "${TARGET_GID}" "$(id -gn "${TARGET_USER}")"
            fi
        fi
        if [[ "$(id -u "${TARGET_USER}")" != "${TARGET_UID}" ]]; then
            usermod -u "${TARGET_UID}" "${TARGET_USER}"
        fi
    fi

    # Grant the target user access to the host-mounted Docker socket. The socket's
    # group varies across Linux, macOS, and Windows hosts, so follow the mounted
    # socket rather than assuming the image's docker group is relevant.
    if [[ -S /var/run/docker.sock ]]; then
        docker_sock_gid="$(stat -c "%g" /var/run/docker.sock)"
        docker_sock_group="$(getent group "${docker_sock_gid}" | cut -d: -f1 || true)"

        if [[ -z "${docker_sock_group}" ]]; then
            docker_sock_group="docker-host"
            if getent group "${docker_sock_group}" >/dev/null; then
                docker_sock_group="docker-host-${docker_sock_gid}"
            fi
            groupadd -g "${docker_sock_gid}" "${docker_sock_group}"
        fi

        if ! id -G "${TARGET_USER}" | tr " " "\n" | grep -Fxq "${docker_sock_gid}"; then
            usermod -aG "${docker_sock_group}" "${TARGET_USER}"
        fi
    fi

    TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
fi

# Reassert shared-root metadata on every start so it survives root recreation.
/init/ensure-shared-roots.sh

if [[ ! -f "${startup_indicator}" ]]; then
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

    # Make the target home match the runtime user before the first startup creates runtime state.
    chown -R "${TARGET_USER}:" "${TARGET_HOME}"
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
