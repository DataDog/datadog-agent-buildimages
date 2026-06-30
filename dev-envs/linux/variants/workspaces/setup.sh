#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

dog_home="/opt/doghome"
bits_home="/home/bits"

groupadd --gid 501 dog
useradd --gid dog --uid 501 --home-dir "${dog_home}" --shell /bin/bash --groups users,build-shared,sudo dog
    
while IFS= read -r line; do
    printf 'export %s=%q\n' "${line%%=*}" "${line#*=}"
done < <(env | grep -Ev "^(HOME=|USER=|MAIL=|LS_COLORS=|HOSTNAME=|PWD=|TERM=|SHLVL=|LANGUAGE=|_=)") > /etc/profile.d/dd-agent-workspace-env.sh

seed_home() {
    local home="$1"
    local owner="$2"
    local group="$3"
    install -d -m 0755 -o "${owner}" -g "${group}" "${home}"
    chown -R "${owner}:${group}" "${home}"
    chmod -R u+rwX,go+rX "${home}"
    chmod 0755 "${home}"
}

seed_home "${dog_home}" dog dog

install -d -m 0755 -o dog -g dog "${dog_home}/sbin"

passwd -d dog
usermod -U dog

# Workspaces historically grants sudo through the dog group. Keep that contract
# while the build image's sudo group rule covers local dev-env behavior.
cat >/etc/sudoers.d/95-dog-nopasswd <<'EOF'
%dog ALL=(ALL:ALL) NOPASSWD:ALL
EOF
chmod 0440 /etc/sudoers.d/95-dog-nopasswd
