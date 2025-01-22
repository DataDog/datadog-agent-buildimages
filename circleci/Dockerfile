# We cannot use Ubuntu 22.04 because the E2E tests
# are currently using a Docker Compose v1 imaged based on Debian.
# The glibc version is too old to allow running CGO binaries built on Ubuntu 22.04
# We'll be able to migrate when we get rid of Docker Compose or use Docker Compose v2
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

ARG PYTHON_VERSION=3.12.6
ARG CMAKE_VERSION=3.30.2
ARG DEVA_VERSION
ARG DEVA_NO_DYNAMIC_DEPS

# Pre-requisites
# Python 3 dev is required for rtloader
RUN set -ex \
    && apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    clang-format \
    curl \
    default-jre \
    doxygen \
    file \
    g++ \
    gcc \
    git \
    gnupg ca-certificates \
    graphviz \
    libpq-dev \
    libsnmp-base \
    libsnmp-dev \
    libssl-dev \
    libsystemd-dev \
    make \
    pkg-config \
    snmp-mibs-downloader \
    ssh \
    build-essential  \
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
    liblzma-dev &&  \
    apt-get clean &&  \
    rm -rf /var/lib/apt/lists/*

# Golang
ARG GO_VERSION
ARG GO_SHA256_LINUX_AMD64
ENV GO_VERSION $GO_VERSION
ENV GOPATH /go
RUN curl -sL -o /tmp/golang.tar.gz https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz \
    && echo "$GO_SHA256_LINUX_AMD64 /tmp/golang.tar.gz" | sha256sum --check \
    && tar -C /usr/local -xzf /tmp/golang.tar.gz \
    && rm -f /tmp/golang.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
ENV PATH="${GOPATH}/bin:${PATH}"
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

# CMake
ENV CMAKE_NAME cmake-$CMAKE_VERSION-linux-x86_64
ENV CMAKE_ARCHIVE $CMAKE_NAME.tar.gz
ENV CMAKE_DEST_DIR /cmake
ENV PATH $CMAKE_DEST_DIR/bin/:$PATH
RUN set -ex \
    && curl -sL -O https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/$CMAKE_ARCHIVE \
    && tar xzf $CMAKE_ARCHIVE \
    && mv $CMAKE_NAME $CMAKE_DEST_DIR \
    && rm $CMAKE_ARCHIVE

# Install Codecov uploader
COPY setup_codecov.sh /
RUN ./setup_codecov.sh

# Other dependencies

# Python
ENV PYENV_ROOT="/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
ENV DEVA_NO_DYNAMIC_DEPS=$DEVA_NO_DYNAMIC_DEPS

RUN git clone --depth=1 https://github.com/pyenv/pyenv.git ${PYENV_ROOT} && \
     pyenv install ${PYTHON_VERSION} && \
     pyenv global ${PYTHON_VERSION} && \
     pip3 install "git+https://github.com/DataDog/datadog-agent-dev.git@${DEVA_VERSION}" && \
     deva -v self dep sync -f legacy-build -f legacy-circleci && \
     pyenv rehash

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# Setup entrypoint
WORKDIR $GOPATH
