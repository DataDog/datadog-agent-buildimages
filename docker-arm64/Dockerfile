ARG BUILDENV_REGISTRY
FROM ${BUILDENV_REGISTRY}/images/docker:27.3.1

ARG PYTHON_VERSION=3.12.6
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS
ARG GO_VERSION
ARG GO_SHA256_LINUX_ARM64
ARG DATADOG_CI_VERSION=3.9.0
ARG DATADOG_CI_SHA=abb2ef649b3407496fbcf9b634a4b1dbe5f6d5141e273d7fdf272a3e4bc3de4d
ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=1cdfd33e218ef145dbc3d71ac4164b89e453ff81b780ed178274bc1ba070e6e9
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_arm64.zip"
ARG AWSCLI_VERSION=2.27.30
ARG AWSCLI_CHECKSUM=cdb480c2f6e1ff2bb0ac234da4ee121c7864d58b2aeddec0e5449a66dc1efc2c

RUN apt-get update &&  \
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
      liblzma-dev &&  \
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
 && dda -v self dep sync -f legacy-build \
 && pyenv rehash

# Install Go
RUN curl -sL -o /tmp/golang.tar.gz https://go.dev/dl/go$GO_VERSION.linux-arm64.tar.gz \
  && echo "$GO_SHA256_LINUX_ARM64  /tmp/golang.tar.gz" | sha256sum --check \
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
  curl --retry 10 -fsSLo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-aarch64-${AWSCLI_VERSION}.zip && \
  echo "${AWSCLI_CHECKSUM} awscliv2.zip" | sha256sum --check && \
  unzip -q awscliv2.zip && \
  ./aws/install && \
  rm -rf aws awscliv2.zip

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# CI uploader, to send tags for extra visibility into CI
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${DATADOG_CI_VERSION}/datadog-ci_linux-arm64 --output "/usr/local/bin/datadog-ci" && \
  echo "${DATADOG_CI_SHA} /usr/local/bin/datadog-ci" | sha256sum --check && \
  chmod +x /usr/local/bin/datadog-ci
