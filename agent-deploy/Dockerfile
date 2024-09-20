# The gitlab-agent-deploy image is used in our Gitlab deploy and promotion pipelines.

# NOTE: this image is used:
# - in the agent-release-management repository, to promote A5/A6/A7 packages to prod
# - in the datadog-agent repository, to promote A6/A7 packages to staging
# - ["soon" as of 2020-09-29] in the mars-jenkins-scripts repository, to promote A5 packages to staging
# When updating the gitlab-agent-deploy image, don't forget to update these three repos
# and test that promotion jobs work as expected with the new image.

FROM registry.ddbuild.io/images/mirror/ubuntu:18.04

ARG RUBY_VERSION_ARG=2.4.10
ARG BUNDLER_VERSION_ARG=1.17.3
ARG AWSCLI_VERSION_ARG=1.11.18
ARG RPM_S3_VERSION_ARG=0.8.0
ARG GOLANG_VERSION=1.21.7
ARG GOLANG_SHASUM=13b76a9b2a26823e53062fa841b07087d48ae2ef2936445dc34c4ae03293702c
ARG CI_UPLOADER_SHASUM=4e56d449e6396ae4c7356f07fc5372a28999aacb012d4343a3b8a9389123aa38
ARG CI_UPLOADER_VERSION=2.38.1
ARG PYTHON_VERSION=3.11.8
ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=a0c0449e640c8be5dcf7b7b093d5884f6a85406dbb86bbad0ea06becad5aaab8
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_amd64.zip"

ENV RUBY_VERSION=$RUBY_VERSION_ARG \
    BUNDLER_VERSION=$BUNDLER_VERSION_ARG \
    AWSCLI_VERSION=$AWSCLI_VERSION_ARG \
    RPM_S3_VERSION=$RPM_S3_VERSION_ARG

# Remove the early return on non-interactive shells, which makes sourcing the file not activate conda
RUN grep -v return /root/.bashrc >> /root/newbashrc && cp /root/newbashrc /root/.bashrc

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    createrepo \
    curl \
    git \
    gnupg1 \
    libffi-dev \
    libgmp-dev \
    libssl-dev \
    procps \
    python-boto \
    python-deltarpm \
    python2.7-dev \
    shellcheck \
    make  \
    zlib1g-dev  \
    libbz2-dev  \
    libreadline-dev  \
    libsqlite3-dev  \
    wget  \
    llvm  \
    libncurses5-dev  \
    xz-utils  \
    tk-dev  \
    libxml2-dev  \
    libxmlsec1-dev  \
    libffi-dev  \
    liblzma-dev \
    unzip \
    ca-certificates \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt update \
    && apt install gh -y \
    && curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${CI_UPLOADER_VERSION}/datadog-ci_linux-x64 --output "/usr/local/bin/datadog-ci" \
    && echo "${CI_UPLOADER_SHASUM} /usr/local/bin/datadog-ci" | sha256sum --check \
    && chmod +x /usr/local/bin/datadog-ci \
    && rm -rf /var/lib/apt/lists/*

# Use gnupg1 instead of gnupg2, our scripts and rpm-s3 are currently not compatible with gnupg2
RUN mv /usr/bin/gpg /usr/bin/gpg2 && ln -s /usr/bin/gpg1 /usr/bin/gpg

# Python 2 deps
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py \
 && python2 get-pip.py

RUN python2 -m pip install \
    awscli==1.18.140 \
    boto3==1.14.7 \
    pexpect==3.2

# Python install
ENV PYENV_ROOT="/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"

RUN git clone --depth=1 https://github.com/pyenv/pyenv.git ${PYENV_ROOT} && \
     pyenv install ${PYTHON_VERSION} && \
     pyenv global ${PYTHON_VERSION}

# Python 3 deps
COPY requirements.txt /requirements.txt
COPY requirements /requirements
RUN pip3 install pip \
 && pip3 install --upgrade pip \
 && pip3 install -r requirements.txt -r requirements/agent-deploy.txt

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# Setup git credentials so we can create commits
RUN git config --global user.email "package@datadoghq.com" && \
    git config --global user.name "Bits"

# Install Mono
RUN gpg --no-default-keyring --keyring /usr/share/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list \
    && chmod 644 /usr/share/keyrings/mono-official-archive-keyring.gpg \
    && apt update \
    && apt install -y mono-devel

# Install .NET
RUN mkdir -p /root/.dotnet \
    && cd /root/.dotnet \
    && wget https://download.visualstudio.microsoft.com/download/pr/17b6759f-1af0-41bc-ab12-209ba0377779/e8d02195dbf1434b940e0f05ae086453/dotnet-sdk-6.0.100-linux-x64.tar.gz \
    && tar -xf dotnet-sdk-6.0.100-linux-x64.tar.gz \
    && rm -rf dotnet-sdk-6.0.100-linux-x64.tar.gz 

ENV DOTNET_ROOT=/root/.dotnet
ENV PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools

# Install Chocolatey
RUN git clone https://github.com/chocolatey/choco.git \
    && cd choco \
    && ./build.sh \
    && cp -r ./code_drop/temp/_PublishedApps/choco /opt/chocolatey \
    && export ChocolateyInstall=/opt/chocolatey \
    && cp ./docker/choco_wrapper /usr/local/bin/choco

# RVM
COPY ./rvm/gpg-keys /gpg-keys
COPY ./agent-deploy/Gemfile ./agent-deploy/Gemfile.lock ./

RUN gpg --import --no-tty /gpg-keys/*
RUN rm -rf /gpg-keys
RUN curl -sSL https://get.rvm.io | bash -s stable --version latest-1.29
RUN /bin/bash -l -c "rvm install ${RUBY_VERSION}"
RUN /bin/bash -l -c "rvm --default use ${RUBY_VERSION} && \
    gem install bundler --version 1.17.3 && \
    bundle install"
RUN /bin/bash -l -c "rvm alias create default ${RUBY_VERSION}"
RUN echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc

# s3cmd
RUN cd opt && curl -sSL https://downloads.sourceforge.net/project/s3tools/s3cmd/1.5.2/s3cmd-1.5.2.tar.gz > s3cmd-1.5.2.tar.gz && \
	tar -xzvf s3cmd-1.5.2.tar.gz && \
	ln -s `pwd`/s3cmd-1.5.2/s3cmd /usr/bin/s3cmd

# rpm-s3
RUN git clone --depth 1 --branch $RPM_S3_VERSION https://github.com/DataDog/rpm-s3 /opt/rpm-s3
RUN printf '#!/bin/bash\nexec /opt/rpm-s3/bin/rpm-s3 $@' > /usr/local/bin/rpm-s3
RUN chmod +x /usr/local/bin/rpm-s3

# jq
RUN curl -fsSL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq && \
    chmod +x /usr/local/bin/jq

# golang
RUN curl -LO https://go.dev/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz && \
    echo "${GOLANG_SHASUM}  go${GOLANG_VERSION}.linux-amd64.tar.gz" | sha256sum --check && \
    tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz && \
    rm -f go${GOLANG_VERSION}.linux-amd64.tar.gz
ENV PATH="$PATH:/usr/local/go/bin"

# Install vault: https://github.com/hashicorp/vault/blob/main/CHANGELOG.md https://releases.hashicorp.com/vault
RUN curl -LO https://releases.hashicorp.com/vault/$VAULT_VERSION/$VAULT_FILENAME \
    && echo "${VAULT_CHECKSUM}  ${VAULT_FILENAME}" | sha256sum --check \
    && unzip $VAULT_FILENAME \
    && rm $VAULT_FILENAME \
    && mv vault /usr/bin/vault \
    && chmod +x /usr/bin/vault

# Add the deploy scripts
COPY ./agent-deploy/deploy-scripts /deploy_scripts
RUN chmod +x /deploy_scripts/check_apt_pool.sh
RUN chmod +x /deploy_scripts/fail_deb_is_pkg_already_exists.sh
RUN /bin/bash -l -c "cd /deploy_scripts/cloudfront-invalidation && \
                     bundle install"

# Entrypoint
COPY ./agent-deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
