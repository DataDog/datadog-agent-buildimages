FROM 486234852809.dkr.ecr.us-east-1.amazonaws.com/docker:20.10 AS base

# Build Args - common arguments used across stages
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
ARG XAR_CHECKSUM=9bd417fe646fc0c6ded939521d9f6adb2455cc778d46f95a8e6f751e41b70ac3

# Environment variables
ENV PYTHONUTF8=1
ENV PYENV_ROOT="/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS
ENV GOPATH=/go
ENV GO_VERSION=$GO_VERSION
ENV PATH="/go/bin:/usr/local/go/bin:${PATH}"

# Base system dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      make \
      build-essential \
      libssl-dev \
      zlib1g-dev \
      libbz2-dev \
      libreadline-dev \
      libsqlite3-dev \
      wget \
      curl \
      llvm \
      libncurses5-dev \
      xz-utils \
      tk-dev \
      libxml2-dev \
      libxmlsec1-dev \
      libffi-dev \
      liblzma-dev \
      rpm2cpio \
      cpio \
      dmg2img \
      autoconf \
      p7zip-full \
      git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# FROM base as xar-builder
FROM base as xar-builder
ARG XAR_CHECKSUM
RUN curl -sL -o /tmp/master.tar.gz https://github.com/mackyle/xar/archive/master.tar.gz && \
    echo "$XAR_CHECKSUM /tmp/master.tar.gz" | sha256sum --check && \
    tar -C /tmp -xzf /tmp/master.tar.gz && \
    cd /tmp/xar-master/xar && chmod +x autogen.sh && \
    sed -i -e "s/OpenSSL_add_all_ciphers/OPENSSL_init_crypto/g" configure.ac && \
    ./autogen.sh && make && make install && \
    rm /tmp/master.tar.gz && rm -rf /tmp/xar-master/

# Final image with all components
FROM base

# Copy all built components from previous stages
COPY --from=xar-builder /usr/local/bin/xar /usr/local/bin/
COPY --from=xar-builder /usr/local/lib/libxar* /usr/local/lib/

# Install Python with pyenv
ARG PYTHON_VERSION
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS
RUN git clone --depth=1 https://github.com/pyenv/pyenv.git ${PYENV_ROOT} && \
    pyenv install ${PYTHON_VERSION} && \
    pyenv global ${PYTHON_VERSION} && \
    pip install "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}" && \
    dda -v self dep sync -f legacy-build -f legacy-notifications && \
    pyenv rehash

# Install Go in a single layer
ARG GO_VERSION
ARG GO_SHA256_LINUX_AMD64
RUN curl -sL -o /tmp/golang.tar.gz https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz && \
    echo "$GO_SHA256_LINUX_AMD64  /tmp/golang.tar.gz" | sha256sum --check && \
    tar -C /usr/local -xzf /tmp/golang.tar.gz && \
    rm -f /tmp/golang.tar.gz

# Install Vault in a single layer
ARG VAULT_VERSION
ARG VAULT_CHECKSUM
ARG VAULT_FILENAME
RUN curl -LO https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME} && \
    echo "${VAULT_CHECKSUM} ${VAULT_FILENAME}" | sha256sum --check && \
    unzip -o ${VAULT_FILENAME} -d /usr/bin vault && \
    rm ${VAULT_FILENAME}

# CI uploader in a single layer
ARG CI_UPLOADER_VERSION
ARG CI_UPLOADER_SHA
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${CI_UPLOADER_VERSION}/datadog-ci_linux-x64 --output "/usr/local/bin/datadog-ci" && \
    echo "${CI_UPLOADER_SHA} /usr/local/bin/datadog-ci" | sha256sum --check && \
    chmod +x /usr/local/bin/datadog-ci
