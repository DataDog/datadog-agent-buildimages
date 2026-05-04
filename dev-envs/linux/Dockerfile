ARG BASE_IMAGE=datadog/agent-buildimages-linux
ARG BASE_IMAGE_TAG=latest

FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG} AS base

ARG DDA_VERSION=""

# Ensure all setup runs as root, even though the base build image now defaults
# to a non-root user. The entrypoint will later drop to a host-mapped UID/GID
# for developers.
# hadolint global ignore=DL3002
USER root

# Set up HOME as root-owned and build-shared writable so host-mapped users
# with unknown UID/GID can use it without chown.
ENV HOME=/home/dd
ENV PATH="${HOME}/.local/bin:${PATH}"
RUN mkdir -p "${HOME}" && \
    chgrp build-shared "${HOME}" && \
    chmod g+rws,o+rx "${HOME}" && \
    setfacl -m g:build-shared:rwx,m:rwx "${HOME}" && \
    setfacl -d -m g:build-shared:rwx,m:rwx "${HOME}"

# We set up shells first so that config can be modified as part of subsequent steps.
# Shells require scripts to set environment variables and add to PATH. These same
# scripts require the shells to be set up, leaving us with a cyclical dependency.
# To break this cycle:
# hadolint global ignore=DL3059
# 1. Set up shells using only workspace-mounted scripts to update environment variables, (no ~/.scripts yet)
RUN --mount=type=bind,src=./zsh.sh,dst=/mnt/zsh.sh /mnt/zsh.sh
RUN --mount=type=bind,src=./nushell.sh,dst=/mnt/nushell.sh \
    --mount=type=bind,src=./scripts/set-ev.sh,dst=/mnt/scripts/set-ev.sh \
    --mount=type=bind,src=./scripts/path-append.sh,dst=/mnt/scripts/path-append.sh \
    /mnt/nushell.sh
# 2. Set up scripts into ~/.scripts and update PATH accordingly, (only explicit access to ~/.scripts)
RUN --mount=type=bind,src=./scripts.sh,dst=/mnt/scripts.sh --mount=type=bind,src=./scripts/,dst=/mnt/scripts/ /mnt/scripts.sh
# 3. Proceed with subsequent steps relying solely on the installed scripts in PATH.

# Set up environment variables
RUN --mount=type=bind,src=./env-vars.sh,dst=/mnt/env-vars.sh /mnt/env-vars.sh
# Set up tools
RUN --mount=type=bind,src=./tools.sh,dst=/mnt/tools.sh \
    --mount=type=bind,src=./tools.txt,dst=/mnt/tools.txt \
    --mount=type=bind,from=dotslash,target=/tools/dotslash \
    /mnt/tools.sh
# Set up Git
RUN --mount=type=bind,src=./git.sh,dst=/mnt/git.sh /mnt/git.sh
# Set up dda
RUN --mount=type=bind,src=./dda.sh,dst=/mnt/dda.sh DDA_VERSION=${DDA_VERSION} /mnt/dda.sh
# Set up Docker
RUN --mount=type=bind,src=./docker.sh,dst=/mnt/docker.sh /mnt/docker.sh
# Set up fonts
RUN --mount=type=bind,src=./fonts.sh,dst=/mnt/fonts.sh /mnt/fonts.sh
# Set up Starship prompt
RUN --mount=type=bind,src=./starship.sh,dst=/mnt/starship.sh /mnt/starship.sh
# Set up editor integrations
RUN --mount=type=bind,src=./editors.sh,dst=/mnt/editors.sh /mnt/editors.sh

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
# This is where we store default configuration for the image
# which is used to seed the user's configuration.
ENV DD_DEFAULT_CONFIG_ROOT="/var/config/dd-defaults"
# Runtime config should target the persisted config root.
ENV XDG_CONFIG_HOME="${DD_BUILD_CONFIG_ROOT}"

# MCP
EXPOSE 9000

COPY init/ /init/
COPY default-vscode-extensions.json /etc/default-vscode-extensions.json
ENTRYPOINT ["/init/entrypoint.sh"]

# This is a variant used by Datadog-internal tooling.
FROM base AS workspace

# Create the dog group and user
RUN set -x \
    && groupadd --gid 501 dog  \
    && useradd --gid 501 --uid 501 --create-home --groups users dog

# Remove AWS CLI v2 (breaking if we keep it, because we try to reinstall it in workspace base feature)
# https://docs.aws.amazon.com/cli/latest/userguide/uninstall.html
RUN rm -f /usr/local/bin/aws /usr/local/bin/aws_completer \
    && rm -rf /usr/local/aws-cli

# Finalization must happen last
RUN --mount=type=bind,src=./finalize.sh,dst=/mnt/finalize.sh /mnt/finalize.sh

# Sleep indefinitely to keep the container running
CMD ["sleep", "infinity"]

# This is the standard image used by Agent dev env tooling and it
# MUST be the last stage in the file so that it's the default target.
FROM base AS standard

# Set up OpenSSH server
# IMPORTANT: make sure this comes last so Git operations don't use SSH during building
RUN --mount=type=bind,src=./ssh.sh,dst=/mnt/ssh.sh /mnt/ssh.sh

# Finalization must happen last
RUN --mount=type=bind,src=./finalize.sh,dst=/mnt/finalize.sh /mnt/finalize.sh

# SSH
EXPOSE 22

# Run SSH server
CMD ["/usr/local/sbin/sshd", "-D", "-e"]
