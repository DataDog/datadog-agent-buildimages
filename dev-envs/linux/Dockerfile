ARG BASE_IMAGE=datadog/agent-buildimages-linux-glibc-2-23-arm64
ARG BASE_IMAGE_TAG=latest

FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG} AS base

ARG DDA_VERSION=""

# Copy all setup scripts at once
COPY scripts /root/.scripts
COPY scripts.sh /setup/scripts.sh
COPY env.sh /setup/env.sh
COPY zsh.sh /setup/zsh.sh
COPY nushell.sh /setup/nushell.sh
COPY env-vars.sh /setup/env-vars.sh
COPY tools.sh /setup/tools.sh
COPY git.sh /setup/git.sh
COPY python.sh /setup/python.sh
COPY dda.sh /setup/dda.sh
COPY docker.sh /setup/docker.sh
COPY fonts.sh /setup/fonts.sh
COPY starship.sh /setup/starship.sh
COPY default-vscode-extensions.txt /setup/default-vscode-extensions.txt
COPY vscode.sh /setup/vscode.sh
COPY ssh.sh /setup/ssh.sh
COPY entrypoint.sh /entrypoint.sh

# Create shellrc file for environment setup
RUN echo 'set -euxo pipefail\n\nexport PATH="${HOME}/.scripts:${PATH}"' > /setup/shellrc.sh

# Group installation steps to optimize layers
# 1. Setup scripts and basic environment
RUN /setup/scripts.sh && \
    /setup/zsh.sh && \
    /setup/nushell.sh && \
    /setup/env.sh && \
    /setup/env-vars.sh

# 2. Install tools and development essentials
RUN /setup/tools.sh && \
    /setup/git.sh && \
    /setup/python.sh && \
    DDA_VERSION=${DDA_VERSION} /setup/dda.sh && \
    /setup/docker.sh

# 3. Install UI/UX improvements and final components
RUN /setup/fonts.sh && \
    /setup/starship.sh && \
    /setup/vscode.sh && \
    /setup/ssh.sh && \
    # Clean up after installations
    rm -rf /setup && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Expose SSH port
EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
