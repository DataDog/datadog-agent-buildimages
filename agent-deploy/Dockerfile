# The gitlab-agent-deploy image is used in our Gitlab deploy and promotion pipelines.

# NOTE: this image is used:
# - in the agent-release-management repository, to promote A5/A6/A7 packages to prod
# - in the datadog-agent repository, to promote A6/A7 packages to staging
# - ["soon" as of 2020-09-29] in the mars-jenkins-scripts repository, to promote A5 packages to staging
# When updating the gitlab-agent-deploy image, don't forget to update these three repos
# and test that promotion jobs work as expected with the new image.

FROM registry.ddbuild.io/images/mirror/ubuntu:18.04 AS base

# Build Args - common arguments used across stages
ARG RUBY_VERSION_ARG=2.7.8
ARG BUNDLER_VERSION_ARG=2.5.21
ARG AWSCLI_VERSION_ARG=1.34.33
ARG RPM_S3_VERSION_ARG=0.8.0
ARG GO_VERSION
ARG GO_SHA256_LINUX_AMD64
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS
ARG CI_UPLOADER_SHASUM=4e56d449e6396ae4c7356f07fc5372a28999aacb012d4343a3b8a9389123aa38
ARG CI_UPLOADER_VERSION=2.38.1
ARG PYTHON_VERSION=3.12.6
ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=a0c0449e640c8be5dcf7b7b093d5884f6a85406dbb86bbad0ea06becad5aaab8
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_amd64.zip"

# Environment variables common to all stages
ENV RUBY_VERSION=$RUBY_VERSION_ARG \
    BUNDLER_VERSION=$BUNDLER_VERSION_ARG \
    AWSCLI_VERSION=$AWSCLI_VERSION_ARG \
    RPM_S3_VERSION=$RPM_S3_VERSION_ARG \
    PYTHONUTF8=1 \
    DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS \
    PYENV_ROOT="/.pyenv" \
    PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH" \
    GOPATH=/go \
    GO_VERSION=$GO_VERSION \
    PATH="$PATH:/usr/local/go/bin:${GOPATH}/bin:$PATH"

# Base system preparation
RUN grep -v return /root/.bashrc >> /root/newbashrc && cp /root/newbashrc /root/.bashrc \
    && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
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
    make \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    wget \
    llvm \
    libncurses5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev \
    unzip \
    ca-certificates \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt update \
    && apt install gh -y \
    && rm -rf /var/lib/apt/lists/* \
    && mv /usr/bin/gpg /usr/bin/gpg2 && ln -s /usr/bin/gpg1 /usr/bin/gpg \
    && git config --global user.email "package@datadoghq.com" \
    && git config --global user.name "Bits"

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# FROM base as mono-builder
FROM base as mono-builder
RUN gpg --no-default-keyring --keyring /usr/share/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list \
    && chmod 644 /usr/share/keyrings/mono-official-archive-keyring.gpg \
    && apt update \
    && apt install -y mono-devel

# FROM base as dotnet-builder
FROM base as dotnet-builder
RUN UBUNTU_VERSION=$(cat /etc/os-release | grep VERSION_ID | cut -d = -f 2 | xargs) \
    && wget https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt update \
    && apt install -y dotnet-sdk-6.0

# FROM base as choco-builder
FROM base as choco-builder
RUN git clone https://github.com/chocolatey/choco.git \
    && cd choco \
    && ./build.sh \
    && mkdir -p /opt/chocolatey \
    && cp -r ./code_drop/temp/_PublishedApps/choco /opt/chocolatey \
    && cp ./docker/choco_wrapper /usr/local/bin/choco

# FROM base as s3cmd-builder
FROM base as s3cmd-builder
RUN cd /opt && curl -sSL https://downloads.sourceforge.net/project/s3tools/s3cmd/1.5.2/s3cmd-1.5.2.tar.gz > s3cmd-1.5.2.tar.gz \
    && tar -xzvf s3cmd-1.5.2.tar.gz

# Final image with all components
FROM base

# Copy built components from builder stages
COPY --from=mono-builder /usr/lib/mono /usr/lib/mono
COPY --from=mono-builder /usr/bin/mono* /usr/bin/
COPY --from=dotnet-builder /usr/share/dotnet /usr/share/dotnet
COPY --from=dotnet-builder /usr/bin/dotnet /usr/bin/dotnet
COPY --from=choco-builder /opt/chocolatey /opt/chocolatey
COPY --from=choco-builder /usr/local/bin/choco /usr/local/bin/choco
COPY --from=s3cmd-builder /opt/s3cmd-1.5.2 /opt/s3cmd-1.5.2
RUN ln -s /opt/s3cmd-1.5.2/s3cmd /usr/bin/s3cmd

ENV ChocolateyInstall=/opt/chocolatey

# Install CI uploader in a single layer
ARG CI_UPLOADER_SHASUM
ARG CI_UPLOADER_VERSION
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${CI_UPLOADER_VERSION}/datadog-ci_linux-x64 --output "/usr/local/bin/datadog-ci" \
    && echo "${CI_UPLOADER_SHASUM} /usr/local/bin/datadog-ci" | sha256sum --check \
    && chmod +x /usr/local/bin/datadog-ci

# Install Python 2 dependencies in a single layer
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py \
    && python2 get-pip.py \
    && python2 -m pip install \
    awscli==1.18.140 \
    boto3==1.14.7 \
    pexpect==3.2 \
    && rm get-pip.py

# Install Python 3 with pyenv in a single layer
ARG PYTHON_VERSION
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS
RUN git clone --depth=1 https://github.com/pyenv/pyenv.git ${PYENV_ROOT} \
    && pyenv install ${PYTHON_VERSION} \
    && pyenv global ${PYTHON_VERSION} \
    && pip3 install pip \
    && pip3 install --upgrade pip \
    && pip3 install "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}" \
    && dda -v self dep sync -f legacy-build -f legacy-agent-deploy \
    && pyenv rehash

# Install RVM and Ruby in a single layer
ARG RUBY_VERSION_ARG
ARG BUNDLER_VERSION_ARG
COPY ./rvm/gpg-keys /gpg-keys
COPY ./agent-deploy/Gemfile ./agent-deploy/Gemfile.lock ./
RUN gpg --import --no-tty /gpg-keys/* && rm -rf /gpg-keys \
    && curl -sSL https://get.rvm.io | bash -s stable --version latest-1.29 \
    && /bin/bash -l -c "rvm install ${RUBY_VERSION}" \
    && /bin/bash -l -c "rvm --default use ${RUBY_VERSION} && \
    gem install bundler --version 1.17.3 && \
    bundle install" \
    && /bin/bash -l -c "rvm alias create default ${RUBY_VERSION}" \
    && echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc

# Install rpm-s3 in a single layer
ARG RPM_S3_VERSION_ARG
RUN git clone --depth 1 --branch $RPM_S3_VERSION https://github.com/DataDog/rpm-s3 /opt/rpm-s3 \
    && printf '#!/bin/bash\nexec /opt/rpm-s3/bin/rpm-s3 $@' > /usr/local/bin/rpm-s3 \
    && chmod +x /usr/local/bin/rpm-s3

# Install additional tools in a single layer
RUN curl -fsSL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq \
    && chmod +x /usr/local/bin/jq

# Install Go in a single layer
ARG GO_VERSION
ARG GO_SHA256_LINUX_AMD64
RUN curl -LO https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz \
    && echo "${GO_SHA256_LINUX_AMD64}  go${GO_VERSION}.linux-amd64.tar.gz" | sha256sum --check \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
    && rm -f go${GO_VERSION}.linux-amd64.tar.gz

# Install Vault in a single layer
ARG VAULT_VERSION
ARG VAULT_CHECKSUM
ARG VAULT_FILENAME
RUN curl -LO https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME} \
    && echo "${VAULT_CHECKSUM} ${VAULT_FILENAME}" | sha256sum --check \
    && unzip -o ${VAULT_FILENAME} -d /usr/bin vault \
    && rm ${VAULT_FILENAME}

# Add the deploy scripts
COPY ./agent-deploy/deploy-scripts /deploy_scripts
RUN chmod +x /deploy_scripts/check_apt_pool.sh \
    && chmod +x /deploy_scripts/fail_deb_is_pkg_already_exists.sh \
    && /bin/bash -l -c "cd /deploy_scripts/cloudfront-invalidation && bundle install"

# Set up entrypoint
COPY ./agent-deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
