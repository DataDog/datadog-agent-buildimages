#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# Snapshot the current exported environment into a login-shell snippet under
# /etc/profile.d so interactive sessions see the same variables as at the end
# of the image build (after all prior RUN steps in this Dockerfile).

readonly out="/etc/profile.d/99-datadog-agent-dev-build-env.sh"

# Variables to omit: session-specific, identity (wrong for non-root users), or
# bash dynamic state that must not be pinned.
should_skip() {
    case "$1" in
        _ | PWD | OLDPWD | SHLVL | RANDOM | SECONDS | LINENO | HOME | USER | LOGNAME | MAIL | HOSTNAME)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

umask 022
mkdir -p /etc/profile.d

{
    printf '%s\n' '# Generated at image build time by dump-build-env-profile-d.sh; do not edit.'
    printf '%s\n' '# Re-sources build-time exports for login shells (bash/sh via /etc/profile).'
    while IFS= read -r name; do
        [[ -z "${name}" ]] && continue
        should_skip "${name}" && continue
        if [[ "$(declare -p "${name}" 2>/dev/null || true)" =~ ^declare\ -[a-zA-Z-]*r ]]; then
            continue
        fi
        value="${!name}"
        printf 'export %s=%q\n' "${name}" "${value}"
    done < <(compgen -e | LC_ALL=C sort -u)
} >"${out}.tmp"
mv "${out}.tmp" "${out}"
chmod 0644 "${out}"

# Sanity: generated file must not be empty aside from comments
if ! grep -q '^export ' "${out}"; then
    echo "warning: no export lines written to ${out}" >&2
fi
