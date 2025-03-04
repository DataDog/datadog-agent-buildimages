FROM 486234852809.dkr.ecr.us-east-1.amazonaws.com/docker:20.10

ARG PYTHON_VERSION=3.12.6
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS
ARG GO_VERSION
ARG GO_SHA256_LINUX_AMD64
ARG CI_UPLOADER_VERSION=2.38.1
ARG CI_UPLOADER_SHA=4e56d449e6396ae4c7356f07fc5372a28999aacb012d4343a3b8a9389123aa38
ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=a0c0449e640c8be5dcf7b7b093d5884f6a85406dbb86bbad0ea06becad5aaab8
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_amd64.zip"

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
      liblzma-dev \
      rpm2cpio \
      cpio && \
    apt-get clean &&  \
    rm -rf /var/lib/apt/lists/*

# Python install
ENV PYENV_ROOT="/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS

RUN git clone --depth=1 https://github.com/pyenv/pyenv.git ${PYENV_ROOT} && \
     pyenv install ${PYTHON_VERSION} && \
     pyenv global ${PYTHON_VERSION}

RUN pip install "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}" \
 && pip install -r ../requirements/slack.txt \
 && dda -v self dep sync -f legacy-build \
 && pyenv rehash

# Install Go
RUN curl -sL -o /tmp/golang.tar.gz https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz \
  && echo "$GO_SHA256_LINUX_AMD64  /tmp/golang.tar.gz" | sha256sum --check \
  && tar -C /usr/local -xzf /tmp/golang.tar.gz \
  && rm -f /tmp/golang.tar.gz
ENV GOPATH /go
ENV GO_VERSION $GO_VERSION
ENV PATH="/go/bin:/usr/local/go/bin:${PATH}"

# Install vault: https://github.com/hashicorp/vault/blob/main/CHANGELOG.md https://releases.hashicorp.com/vault
RUN curl -LO https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME} && \
  echo "${VAULT_CHECKSUM} ${VAULT_FILENAME}" | sha256sum --check && \
  unzip -o ${VAULT_FILENAME} -d /usr/bin vault && \
  rm ${VAULT_FILENAME}

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# CI uploader, to send tags for extra visibility into CI
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${CI_UPLOADER_VERSION}/datadog-ci_linux-x64 --output "/usr/local/bin/datadog-ci" && \
  echo "${CI_UPLOADER_SHA} /usr/local/bin/datadog-ci" | sha256sum --check && \
  chmod +x /usr/local/bin/datadog-ci
