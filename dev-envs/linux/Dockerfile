ARG ARCH=arm64
ARG TAG=latest
FROM datadog/agent-buildimages-deb_${ARCH}:${TAG}

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

# Set up Python
COPY python.sh /setup/python.sh
RUN /setup/python.sh

# Set up fonts
COPY fonts.sh /setup/fonts.sh
RUN /setup/fonts.sh

# Set up Starship prompt
COPY starship.sh /setup/starship.sh
RUN /setup/starship.sh

# Set up OpenSSH server
COPY ssh.sh /setup/ssh.sh
RUN /setup/ssh.sh

# Set up Git
COPY git.sh /setup/git.sh
RUN /setup/git.sh

# Set up Visual Studio Code
COPY default-vscode-extensions.txt /setup/default-vscode-extensions.txt
COPY vscode.sh /setup/vscode.sh
RUN /setup/vscode.sh

# Remove setup files
# hadolint ignore=DL3059
RUN rm -rf /setup

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

EXPOSE 22
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
