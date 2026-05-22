#!/bin/bash
IFS=$'\n\t'
set -euo pipefail

workspace_user="bits"
shell_name="bash"
real_user=""
github_username=""
workspace_name=""
docker_host=""

while getopts u:g:s:w:h: flag; do
    case "${flag}" in
        u) real_user="${OPTARG}" ;;
        g) github_username="${OPTARG}" ;;
        s) shell_name="${OPTARG}" ;;
        w) workspace_name="${OPTARG}" ;;
        h) docker_host="${OPTARG}" ;;
        *) exit 1 ;;
    esac
done

home_dir="$(getent passwd "${workspace_user}" | cut -d: -f6)"
ssh_dir="${home_dir}/.ssh"
authorized_keys="${ssh_dir}/authorized_keys"

set_environment() {
    local key="$1"
    local value="$2"

    if grep -q "^${key}=" /etc/environment; then
        sed -i "s#^${key}=.*#${key}=${value}#" /etc/environment
    else
        echo "${key}=${value}" >> /etc/environment
    fi
}

install -d -m 700 -o "${workspace_user}" -g dog "${ssh_dir}"

if [[ -s "${authorized_keys}" ]]; then
    echo "User is already authorized"
    exit 0
fi

if [[ -n "${real_user}" ]]; then
    set_environment REAL_USER "${real_user}"
fi

if [[ -n "${workspace_name}" ]]; then
    set_environment WORKSPACE_NAME "${workspace_name}"
    if [[ "$(hostname)" != "${workspace_name}" ]]; then
        hostname "${workspace_name}"
    fi
    if ! grep -Fq "${workspace_name}" /etc/hosts; then
        echo "127.0.0.1 ${workspace_name}" >> /etc/hosts
    fi
fi

if [[ -n "${docker_host}" ]] && ! grep -Fq "host.docker.internal" /etc/hosts; then
    echo "${docker_host} host.docker.internal" >> /etc/hosts
fi

shell_path="$(command -v "${shell_name}")"
chsh -s "${shell_path}" "${workspace_user}"

if [[ -z "${github_username}" ]]; then
    echo "GitHub username is required to authorize ${workspace_user}" >&2
    exit 1
fi
# do user specific configuration *as* the user (to ensure permissions and paths are correct)
su - bits << EOF
    echo "Fetching keys from github.com/${github_username}"
    curl "https://github.com/${github_username}.keys" -o ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys

    echo "Setting up password-store"
    # NOTE: We create a separate gpg dir for pass, and configure pass to always use that gpg
    # homedir. This ensures we don't conflict with a forwarded gpg-agent
    export PASS_GPG_HOME=\$HOME/.config/password-store/gpg
    mkdir -m 700 -p \$PASS_GPG_HOME
    gpg --homedir \$PASS_GPG_HOME --batch --passphrase '' --quick-generate-key --yes password-store
    PASSWORD_STORE_GPG_OPTS="--homedir \$PASS_GPG_HOME" pass init 'password-store'

    if [ -e /etc/container-config/compose.yaml ]; then
        echo "Copying some files"
        cp /etc/container-config/compose.yaml ~/dd/compose.yaml
    fi

    if command -v dd-gitsign &> /dev/null; then
        echo "Setting up dd-gitsign"
        GIT_DISPLAY_NAME=\$(curl -s https://api.github.com/users/${github_username} | jq -r '.name // "${github_username}"')
        GIT_EMAIL="${workspace_user}@datadoghq.com"
        dd-gitsign install --remote --github="${github_username}" --name "\${GIT_DISPLAY_NAME}" --email "\${GIT_EMAIL}"
    fi
EOF

curl --fail --silent --show-error --location \
    "https://github.com/${github_username}.keys" \
    -o "${authorized_keys}"

chown "${workspace_user}:dog" "${authorized_keys}"
chmod 600 "${authorized_keys}"
