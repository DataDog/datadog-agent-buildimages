#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail
umask 0002

set-ev DD_SHARED_DIR "/.shared"

# Advertise full terminal capabilities
set-ev TERM "xterm-256color"
set-ev COLORTERM "truecolor"

# Allow dynamic dependencies again as they are disabled in build images
set-ev DDA_NO_DYNAMIC_DEPS "0"

# This is effectively required for builds
set-ev OMNIBUS_FORCE_PACKAGES "1"


# Reproduce what's left of the build image environment without sourcing /root/.bashrc
rvm_environment_file="/opt/dd/rvm/gems/default/environment"
[[ -f "${rvm_environment_file}" ]]
ruby_version_line="$(sed -n "s/^export RUBY_VERSION='\(ruby-[^']\+\)'$/\1/p" "${rvm_environment_file}")"
[[ -n "${ruby_version_line}" ]]

set-ev GEM_HOME "/opt/dd/rvm/gems/${ruby_version_line}"
set-ev GEM_PATH "/opt/dd/rvm/gems/${ruby_version_line}:/opt/dd/rvm/gems/${ruby_version_line}@global"
# Reverse order to match the original
"${HOME}/.scripts/path-prepend" "/opt/dd/rvm/rubies/${ruby_version_line}/bin"
"${HOME}/.scripts/path-prepend" "/opt/dd/rvm/gems/${ruby_version_line}@global/bin"
"${HOME}/.scripts/path-prepend" "/opt/dd/rvm/gems/${ruby_version_line}/bin"

# Claude Code and Codex CLI: keep global state under XDG config (seeded from image defaults).
"${HOME}/.scripts/set-ev" CLAUDE_CONFIG_DIR "${XDG_CONFIG_HOME}/claude"
"${HOME}/.scripts/set-ev" CODEX_HOME "${XDG_CONFIG_HOME}/codex"
