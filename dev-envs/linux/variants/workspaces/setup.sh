#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

dog_home="/opt/doghome"
bits_home="/home/bits"

groupadd --gid 501 dog
useradd --gid dog --uid 501 --home-dir "${dog_home}" --shell /bin/bash --groups users,build-shared,sudo dog
# useradd --gid dog --uid 2000 --home-dir "${bits_home}" --shell /usr/local/bin/zsh --groups users,build-shared,sudo bits
# if getent group docker >/dev/null; then
#     usermod -a -G docker bits
# fi

seed_home() {
    local home="$1"
    local owner="$2"
    local group="$3"
    install -d -m 0755 -o "${owner}" -g "${group}" "${home}"
    # cp -a /home/dd/. "${home}/"
    chown -R "${owner}:${group}" "${home}"
    chmod -R u+rwX,go+rX "${home}"
    chmod 0755 "${home}"
}

seed_home "${dog_home}" dog dog
# seed_home "${bits_home}" bits dog

install -d -m 0755 -o dog -g dog "${dog_home}/sbin"
# install -d -m 700 -o bits -g dog "${bits_home}/.ssh"

passwd -d dog
# passwd -d bits
usermod -U dog
# usermod -U bits

# Workspaces historically grants sudo through the dog group. Keep that contract
# while the build image's sudo group rule covers local dev-env behavior.
cat >/etc/sudoers.d/95-dog-nopasswd <<'EOF'
%dog ALL=(ALL:ALL) NOPASSWD:ALL
EOF
chmod 0440 /etc/sudoers.d/95-dog-nopasswd

# zsh does not source /etc/profile.d by default. Workspaces and the Agent
# feature both write *-workspace-env.sh snippets there.
# install -d /etc/zsh
# cat >/etc/zsh/zshenv <<'EOF'
# if [[ -z "$PATH" || "$PATH" == "/bin:/usr/bin" ]]; then
#     export PATH="/usr/local/bin:/usr/bin:/bin:/usr/games"
# fi

# for s in $(find /etc/profile.d/ -type f -name "*-workspace-env.sh" | sort); do
#     source "$s"
# done
# EOF
