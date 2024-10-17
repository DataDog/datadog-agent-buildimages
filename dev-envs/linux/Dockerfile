ARG ARCH=arm
FROM datadog/agent-buildimages-deb_${ARCH}

## Set up shells first so that config can be modified as part of subsequent steps

# Set up Zsh
COPY zsh.sh /setup/zsh.sh
RUN /setup/zsh.sh

# Set up Oh My Zsh
COPY oh-my-zsh.sh /setup/oh-my-zsh.sh
RUN /setup/oh-my-zsh.sh

# Set up scripts
COPY scripts /root/scripts
COPY scripts.sh /setup/scripts.sh
RUN /setup/scripts.sh

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
RUN rm -rf /setup

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

EXPOSE 22
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
