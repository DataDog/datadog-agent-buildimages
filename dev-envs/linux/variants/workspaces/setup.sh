#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

dog_home="/opt/doghome"
bits_home="/home/bits"

groupadd --gid 501 dog
useradd --gid dog --uid 501 --home-dir "${dog_home}" --shell /bin/bash --groups users,build-shared,sudo dog

workspace_env_file="${DD_BUILD_CONFIG_ROOT}/dd-agent-workspace-env.sh"
install -d -m 0775 "$(dirname "${workspace_env_file}")"
while IFS= read -r line; do
    printf 'export %s=%q\n' "${line%%=*}" "${line#*=}"
done < <(env | grep -Ev "^(CODEX_HOME=|CLAUDE_CONFIG_DIR=|HOME=|USER=|MAIL=|LS_COLORS=|HOSTNAME=|PWD=|TERM=|SHLVL=|LANGUAGE=|OTEL_.*=|TRACEPARENT=|_=)") > "${workspace_env_file}"

# Workspaces mount a much larger instance-storage volume on ~/.cache (workspaces `base` feature), while
# the snapshot above puts every cache variable (XDG_CACHE_HOME, GOCACHE, GOPATH...) under
# DD_BUILD_CACHE_ROOT on the root disk: re-root them all, so that new cache variables follow too.
# XDG_CACHE_HOME is re-rooted, not dropped: the datadog-agent `tools/bazel` wrapper only wires its
# --disk_cache when it is set.
# Kept as is: DD_BUILD_CACHE_ROOT (the root itself, not a cache path), DOTSLASH_CACHE (the PATH entry
# for the `ddtool` helpers, see tools.sh, points into it) and UV_CACHE_DIR (uv hardlinks from its cache
# into environments that stay on the root disk: across filesystems it warns and falls back to copies).
# `${HOME}` stays literal so it resolves when the file is sourced. Only plain-path values are rewritten:
# lists (`:`) and values needing `%q` escapes are left untouched rather than corrupted inside the quotes.
sed -i -E \
    -e '/^export (DD_BUILD_CACHE_ROOT|DOTSLASH_CACHE|UV_CACHE_DIR)=/b' \
    -e "s|^(export [A-Za-z_][A-Za-z0-9_]*)=${DD_BUILD_CACHE_ROOT}(/[A-Za-z0-9_./+@%,=-]*)?\$|\\1=\"\${HOME}/.cache\\2\"|" \
    "${workspace_env_file}"
# Fail the build if the re-root did not apply.
# shellcheck disable=SC2016 # the literal `${HOME}` is intended
grep -qxF 'export XDG_CACHE_HOME="${HOME}/.cache"' "${workspace_env_file}"

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
