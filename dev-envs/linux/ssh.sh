#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# Use PAM for environment variable persistence
apt-get update && apt-get install -y --no-install-recommends libpam0g-dev libpam-modules automake

cat <<'EOF' >> /etc/pam.d/sshd
session required pam_env.so
EOF

install-from-source \
    --version "V_9_9_P2" \
    --digest "082dffcf651b9db762ddbe56ca25cc75a0355a7bea41960b47f3c139974c5e3e" \
    --url "https://github.com/openssh/openssh-portable/archive/refs/tags/{{version}}.tar.gz" \
    --relative-path "openssh-portable-{{version}}" \
    --configure-script "autoreconf && ./configure --with-pam"

useradd -r -s /sbin/nologin sshd

# Ameliorate transient network issues for things that can
# retry like Visual Studio Code's Remote - SSH extension
passwd -d root
cat <<'EOF' >> /usr/local/etc/sshd_config
PermitRootLogin yes
PermitEmptyPasswords yes
UsePAM yes
EOF

# Add GitHub to known hosts:
# https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
mkdir -p "${HOME}/.ssh"
cat <<'EOF' >> "${HOME}/.ssh/known_hosts"
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
EOF

# Force SSH for Go dependencies
cat <<'EOF' >> "${HOME}/.gitconfig"
[url "ssh://git@github.com/"]
insteadOf = https://github.com/
EOF
