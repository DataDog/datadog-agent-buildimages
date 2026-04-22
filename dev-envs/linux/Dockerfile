ARG BASE_IMAGE=datadog/agent-buildimages-linux
ARG BASE_IMAGE_TAG=latest

FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG} AS base

ARG DDA_VERSION=""

# We set up shells first so that config can be modified as part of subsequent steps.
# Shells require scripts to set environment variables and add to PATH. These same
# scripts require the shells to be set up, leaving us with a cyclical dependency.
# To break this cycle:
# hadolint global ignore=DL3059
# 1. Set up shells using only workspace-mounted scripts to update environment variables, (no ~/.scripts yet)
RUN --mount=type=bind,src=./zsh.sh,dst=/mnt/zsh.sh /mnt/zsh.sh
RUN --mount=type=bind,src=./nushell.sh,dst=/mnt/nushell.sh --mount=type=bind,src=./scripts/,dst=/mnt/scripts/ /mnt/nushell.sh
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
# Set up Python
RUN --mount=type=bind,src=./python.sh,dst=/mnt/python.sh /mnt/python.sh
# Set up dda
RUN --mount=type=bind,src=./dda.sh,dst=/mnt/dda.sh DDA_VERSION=${DDA_VERSION} /mnt/dda.sh
# Set up Docker
RUN --mount=type=bind,src=./docker.sh,dst=/mnt/docker.sh /mnt/docker.sh
# Set up fonts
RUN --mount=type=bind,src=./fonts.sh,dst=/mnt/fonts.sh /mnt/fonts.sh
# Set up Starship prompt
RUN --mount=type=bind,src=./starship.sh,dst=/mnt/starship.sh /mnt/starship.sh
# Set up Visual Studio Code
RUN --mount=type=bind,src=./vscode.sh,dst=/mnt/vscode.sh --mount=type=bind,src=./default-vscode-extensions.txt,dst=/mnt/default-vscode-extensions.txt /mnt/vscode.sh
# Set up Claude Code
RUN --mount=type=bind,src=./claude.sh,dst=/mnt/claude.sh /mnt/claude.sh
# Run steps that must happen last
RUN --mount=type=bind,src=./finalize.sh,dst=/mnt/finalize.sh /mnt/finalize.sh
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# MCP
EXPOSE 9000

COPY entrypoint-common.sh /entrypoint-common.sh

# ---- devenv: full dev-env with SSH ----
FROM base AS devenv

# Set up OpenSSH server
# IMPORTANT: make sure this comes last so Git operations don't use SSH during building
RUN --mount=type=bind,src=./ssh.sh,dst=/mnt/ssh.sh /mnt/ssh.sh
# SSH
EXPOSE 22

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# ---- workspace: no SSH, no AWS CLI ----
FROM base AS workspace

# Create the dog group and user
RUN set -x \
    && groupadd --gid 501 dog  \
    && useradd --gid 501 --uid 501 --create-home --groups users dog

# Remove AWS CLI v2 (breaking if we keep it, because we try to reinstall it in workspace base feature)
# https://docs.aws.amazon.com/cli/latest/userguide/uninstall.html
RUN rm -f /usr/local/bin/aws /usr/local/bin/aws_completer \
    && rm -rf /usr/local/aws-cli

COPY entrypoint-workspace.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
