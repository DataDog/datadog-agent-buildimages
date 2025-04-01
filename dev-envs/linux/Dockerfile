ARG BASE_IMAGE=datadog/agent-buildimages-linux-glibc-2-23-arm64
ARG BASE_IMAGE_TAG=latest

FROM rust:alpine AS tool-builder

RUN apk add --no-cache build-base=0.5-r3 zlib-dev=1.3.1-r2 zlib-static=1.3.1-r2 \
 && cargo install gfold@2025.2.1 --locked --root /tools

FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG}

COPY --from=tool-builder /tools/bin/gfold /usr/local/bin/gfold

ARG DDA_VERSION=""

# Allow dynamic dependencies again as they are disabled in build images
ENV DDA_NO_DYNAMIC_DEPS=0

# Set up scripts
COPY scripts /root/.scripts
COPY scripts.sh /setup/scripts.sh
RUN /setup/scripts.sh

# We set up shells first so that config can be modified as part of subsequent steps.
# Shells require scripts to set environment variables and add to PATH. These same
# scripts require the shells to be set up, leaving us with a cyclical dependency.
# To break this cycle, each shell's step adds required setup logic to a file that
# is sourced before globally making modifications to PATH for shells.
COPY env.sh /setup/env.sh
COPY <<-"EOF" /setup/shellrc.sh
set -euxo pipefail

export PATH="${HOME}/.scripts:${PATH}"
EOF

# Set up Zsh
COPY zsh.sh /setup/zsh.sh
RUN /setup/zsh.sh

# Set up Nushell
COPY nushell.sh /setup/nushell.sh
RUN /setup/nushell.sh

# Set up environment from previous steps
# hadolint ignore=DL3059
RUN /setup/env.sh

# Set up environment variables
COPY env-vars.sh /setup/env-vars.sh
RUN /setup/env-vars.sh

# Set up utilities
COPY utils.sh /setup/utils.sh
RUN /setup/utils.sh

# Set up Git
COPY git.sh /setup/git.sh
RUN /setup/git.sh

# Set up Python
COPY python.sh /setup/python.sh
RUN /setup/python.sh

# Set up dda
COPY dda.sh /setup/dda.sh
RUN DDA_VERSION=${DDA_VERSION} /setup/dda.sh

# Set up fonts
COPY fonts.sh /setup/fonts.sh
RUN /setup/fonts.sh

# Set up Starship prompt
COPY starship.sh /setup/starship.sh
RUN /setup/starship.sh

# Set up Visual Studio Code
COPY default-vscode-extensions.txt /setup/default-vscode-extensions.txt
COPY vscode.sh /setup/vscode.sh
RUN /setup/vscode.sh

# Set up OpenSSH server
# IMPORTANT: make sure this comes last so Git operations don't use SSH during building
COPY ssh.sh /setup/ssh.sh
RUN /setup/ssh.sh

# Remove setup files
# hadolint ignore=DL3059
RUN rm -rf /setup

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

EXPOSE 22
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
