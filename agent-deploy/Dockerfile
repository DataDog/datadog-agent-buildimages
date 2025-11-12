# The gitlab-agent-deploy image is used in our Gitlab deploy and promotion pipelines.

# NOTE: this image is used:
# - in the agent-release-management repository, to promote A5/A6/A7 packages to prod
# - in the datadog-agent repository, to promote A6/A7 packages to staging
# - ["soon" as of 2020-09-29] in the mars-jenkins-scripts repository, to promote A5 packages to staging
# When updating the gitlab-agent-deploy image, don't forget to update these three repos
# and test that promotion jobs work as expected with the new image.

FROM registry.ddbuild.io/images/mirror/ubuntu:18.04

ARG RUBY_VERSION_ARG=2.7.8
ARG BUNDLER_VERSION_ARG=2.5.21
ARG RPM_S3_VERSION_ARG=0.8.0
ARG GO_VERSION
ARG GO_SHA256_LINUX_AMD64
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS
ARG DATADOG_CI_SHASUM=1b62407af5d4e99827a6903a0e893a17cadf94d1da42e86a76fb5f2b44b2a1e5
ARG DATADOG_CI_VERSION=3.9.0
ARG PYTHON_VERSION=3.12.6
ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=a0c0449e640c8be5dcf7b7b093d5884f6a85406dbb86bbad0ea06becad5aaab8
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_amd64.zip"
ARG AWSCLI_VERSION=2.27.30
ARG AWSCLI_CHECKSUM=2bda389190cf1509584e1bcfb6c9ffe4343ffb1804cf8a9cd96ed874870f7f94
ARG CI_JOB_TOKEN_ARG

ENV RUBY_VERSION=$RUBY_VERSION_ARG \
    BUNDLER_VERSION=$BUNDLER_VERSION_ARG \
    RPM_S3_VERSION=$RPM_S3_VERSION_ARG \
    PYTHONUTF8=1 \
    DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS \
    CI_JOB_TOKEN=$CI_JOB_TOKEN_ARG

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
    && curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${DATADOG_CI_VERSION}/datadog-ci_linux-x64 --output "/usr/local/bin/datadog-ci" \
    && echo "${DATADOG_CI_SHASUM} /usr/local/bin/datadog-ci" | sha256sum --check \
    && chmod +x /usr/local/bin/datadog-ci \
    # AWS v2 cli
    && curl --retry 10 -fsSLo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip \
    && echo "${AWSCLI_CHECKSUM} awscliv2.zip" | sha256sum --check \
    && unzip -q awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip \
    && rm -rf /var/lib/apt/lists/*

# Use gnupg1 instead of gnupg2, our scripts and rpm-s3 are currently not compatible with gnupg2
RUN mv /usr/bin/gpg /usr/bin/gpg2 && ln -s /usr/bin/gpg1 /usr/bin/gpg

# Python 2 deps
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py \
    && python2 get-pip.py

RUN python2 -m pip install \
    boto3==1.14.7 \
    pexpect==3.2

# Python install
ENV PYENV_ROOT="/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"

RUN git clone --depth=1 https://github.com/pyenv/pyenv.git ${PYENV_ROOT} && \
    pyenv install ${PYTHON_VERSION} && \
    pyenv global ${PYTHON_VERSION}

# Python 3 deps
RUN pip3 install pip \
    && pip3 install --upgrade pip \
    && pip3 install "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}" \
    && dda -v self dep sync -f legacy-build -f legacy-agent-deploy \
    && pyenv rehash

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
RUN UBUNTU_VERSION=$(cat /etc/os-release | grep VERSION_ID | cut -d = -f 2 | xargs) && \
    wget https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt update \
    && apt install -y dotnet-sdk-6.0

# Install Chocolatey
RUN git clone https://github.com/chocolatey/choco.git \
    && cd choco \
    && ./build.sh \
    && cp -r ./code_drop/temp/_PublishedApps/choco /opt/chocolatey \
    && cp ./docker/choco_wrapper /usr/local/bin/choco \
    && rm -rf /choco

ENV ChocolateyInstall=/opt/chocolatey

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
RUN curl -LO https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    echo "${GO_SHA256_LINUX_AMD64}  go${GO_VERSION}.linux-amd64.tar.gz" | sha256sum --check && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm -f go${GO_VERSION}.linux-amd64.tar.gz
ENV GOPATH /go
ENV GO_VERSION $GO_VERSION
ENV PATH="$PATH:/usr/local/go/bin"
ENV PATH="${GOPATH}/bin:${PATH}"

# Install & verify Bazelisk as Bazel bootstrapper
RUN --mount=type=bind,dst=/mnt /mnt/setup/bazelisk.sh

# Install vault: https://github.com/hashicorp/vault/blob/main/CHANGELOG.md https://releases.hashicorp.com/vault
RUN curl -LO https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME} && \
  echo "${VAULT_CHECKSUM} ${VAULT_FILENAME}" | sha256sum --check && \
  unzip -o ${VAULT_FILENAME} -d /usr/bin vault && \
  rm ${VAULT_FILENAME}

# Install authanywhere for infra token management
RUN --mount=type=bind,dst=/mnt /mnt/setup/authanywhere.sh

# Install datadog-packages
# TODO: Fallback on github for non Datadog folks
RUN git config --global url."https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.ddbuild.io/DataDog/".insteadOf "https://github.com/DataDog/" && \
    go env -w GOPRIVATE="github.com/DataDog/*" && \
    export PATH="$PATH:$(go env GOPATH)/bin" && \
    go install github.com/DataDog/datadog-packages/cmd/datadog-package@latest

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
