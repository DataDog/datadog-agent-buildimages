ARG BUILDENV_REGISTRY
FROM ${BUILDENV_REGISTRY}/images/docker:27.3.1

ARG PYTHON_VERSION=3.12.6
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS
ARG GO_VERSION
ARG GO_SHA256_LINUX_AMD64
ARG DATADOG_CI_VERSION=3.9.0
ARG DATADOG_CI_SHA=1b62407af5d4e99827a6903a0e893a17cadf94d1da42e86a76fb5f2b44b2a1e5
ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=a0c0449e640c8be5dcf7b7b093d5884f6a85406dbb86bbad0ea06becad5aaab8
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_amd64.zip"
ARG AWSCLI_VERSION=2.27.30
ARG AWSCLI_CHECKSUM=2bda389190cf1509584e1bcfb6c9ffe4343ffb1804cf8a9cd96ed874870f7f94
ARG XAR_CHECKSUM=9bd417fe646fc0c6ded939521d9f6adb2455cc778d46f95a8e6f751e41b70ac3

RUN apt-get clean && apt-get update &&  \
    DEBIAN_FRONTEND=noninteractive apt-get install -y make  \
      build-essential  \
      libssl-dev  \
      zlib1g-dev  \
      libbz2-dev  \
      libreadline-dev  \
      libsqlite3-dev  \
      wget  \
      curl  \
      llvm  \
      libncurses5-dev  \
      xz-utils  \
      tk-dev  \
      libxml2-dev  \
      libxmlsec1-dev  \
      libffi-dev  \
      liblzma-dev \
      rpm2cpio \
      cpio \
      dmg2img \
      autoconf \
      skopeo \
      p7zip-full && \
    apt-get clean &&  \
    rm -rf /var/lib/apt/lists/*

# Python install
ENV PYTHONUTF8 1
ENV PYENV_ROOT="/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS

RUN git clone --depth=1 https://github.com/pyenv/pyenv.git ${PYENV_ROOT} && \
     pyenv install ${PYTHON_VERSION} && \
     pyenv global ${PYTHON_VERSION}

RUN pip install "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}" \
 && dda -v self dep sync -f legacy-build -f legacy-notifications -f gcp \
 && pyenv rehash

# Install Go
RUN curl -sL -o /tmp/golang.tar.gz https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz \
  && echo "$GO_SHA256_LINUX_AMD64  /tmp/golang.tar.gz" | sha256sum --check \
  && tar -C /usr/local -xzf /tmp/golang.tar.gz \
  && rm -f /tmp/golang.tar.gz
ENV GOPATH /go
ENV GO_VERSION $GO_VERSION
ENV PATH="/go/bin:/usr/local/go/bin:${PATH}"

# Install & verify Bazelisk as Bazel bootstrapper
RUN --mount=type=bind,dst=/mnt /mnt/setup/bazelisk.sh

# Install vault: https://github.com/hashicorp/vault/blob/main/CHANGELOG.md https://releases.hashicorp.com/vault
RUN curl -LO https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME} && \
  echo "${VAULT_CHECKSUM} ${VAULT_FILENAME}" | sha256sum --check && \
  unzip -o ${VAULT_FILENAME} -d /usr/bin vault && \
  rm ${VAULT_FILENAME} && \
  # AWS v2 cli
  curl --retry 10 -fsSLo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip && \
  echo "${AWSCLI_CHECKSUM} awscliv2.zip" | sha256sum --check && \
  unzip -q awscliv2.zip && \
  ./aws/install && \
  rm -rf aws awscliv2.zip

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# CI uploader, to send tags for extra visibility into CI
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${DATADOG_CI_VERSION}/datadog-ci_linux-x64 --output "/usr/local/bin/datadog-ci" && \
  echo "${DATADOG_CI_SHA} /usr/local/bin/datadog-ci" | sha256sum --check && \
  chmod +x /usr/local/bin/datadog-ci

# Build xar to open macOS pkg files
# Apply fix for openssl from the following issue
# https://github.com/mackyle/xar/issues/18#issuecomment-379841536
RUN curl -sL -o /tmp/master.tar.gz https://github.com/mackyle/xar/archive/master.tar.gz && \
    echo "$XAR_CHECKSUM /tmp/master.tar.gz" | sha256sum --check && \
    tar -C /tmp -xzf /tmp/master.tar.gz && \
    cd /tmp/xar-master/xar && chmod +x autogen.sh && \
    sed -i -e "s/OpenSSL_add_all_ciphers/OPENSSL_init_crypto/g" configure.ac && \
    ./autogen.sh && make && make install && \
    rm /tmp/master.tar.gz && rm -rf /tmp/xar-master/

# Install authanywhere for infra token management
RUN --mount=type=bind,dst=/mnt /mnt/setup/authanywhere.sh
