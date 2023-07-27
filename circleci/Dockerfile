# We cannot use Ubuntu 22.04 because the E2E tests
# are currently using a Docker Compose v1 imaged based on Debian.
# The glibc version is too old to allow running CGO binaries built on Ubuntu 22.04
# We'll be able to migrate when we get rid of Docker Compose or use Docker Compose v2
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

# Pre-requisites
# Python 3 dev is required for rtloader
RUN set -ex \
    && apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
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
    python3 \
    python3-dev \
    python3-distutils \
    python3-pip \
    python3-setuptools \
    python3-yaml \
    snmp-mibs-downloader \
    ssh \
    xz-utils

# Golang
ENV GO_VERSION 1.20.6
ENV GOPATH /go
RUN curl -sL -o /tmp/golang.tar.gz https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz \
    && echo "b945ae2bb5db01a0fb4786afde64e6fbab50b67f6fa0eb6cfa4924f16a7ff1eb /tmp/golang.tar.gz" | sha256sum --check \
    && tar -C /usr/local -xzf /tmp/golang.tar.gz \
    && rm -f /tmp/golang.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
ENV PATH="${GOPATH}/bin:${PATH}"
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

# CMake
ENV CMAKE_NAME cmake-3.13.3-Linux-x86_64
ENV CMAKE_ARCHIVE $CMAKE_NAME.tar.gz
ENV CMAKE_DEST_DIR /cmake
ENV PATH $CMAKE_DEST_DIR/bin/:$PATH
RUN set -ex \
    && curl -sL -O https://github.com/Kitware/CMake/releases/download/v3.13.3/$CMAKE_ARCHIVE \
    && tar xzf $CMAKE_ARCHIVE \
    && mv $CMAKE_NAME $CMAKE_DEST_DIR \
    && rm $CMAKE_ARCHIVE

# Codecov
ENV CODECOV_VERSION=0.6.1
RUN curl https://keybase.io/codecovsecurity/pgp_keys.asc | gpg --no-default-keyring --keyring trustedkeys.gpg --import \
    && curl -Os https://uploader.codecov.io/v${CODECOV_VERSION}/linux/codecov \
    && curl -Os https://uploader.codecov.io/v${CODECOV_VERSION}/linux/codecov.SHA256SUM \
    && curl -Os https://uploader.codecov.io/v${CODECOV_VERSION}/linux/codecov.SHA256SUM.sig \
    && gpgv codecov.SHA256SUM.sig codecov.SHA256SUM \
    && shasum -a 256 -c codecov.SHA256SUM \
    && rm codecov.SHA256SUM.sig codecov.SHA256SUM \
    && mv codecov /usr/local/bin/codecov \
    && chmod +x /usr/local/bin/codecov

# Other dependencies
RUN set -ex \
    # clang-format
    && echo "deb http://apt.llvm.org/focal/ llvm-toolchain-focal main" >> /etc/apt/sources.list \
    && curl -sL https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
    && apt-get update \
    && apt-get -t llvm-toolchain-focal install -y --no-install-recommends \
    clang-format

# Python
COPY ./requirements.txt /
COPY ./circleci/requirements.txt /circleci_requirements.txt
RUN python3 -m pip install -r requirements.txt -r circleci_requirements.txt

# Setup entrypoint
WORKDIR $GOPATH