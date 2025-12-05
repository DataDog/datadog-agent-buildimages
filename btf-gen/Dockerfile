FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ARG PYTHON_VERSION=3.12.6
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS
ARG AWSCLI_VERSION=2.27.30
ARG AWSCLI_CHECKSUM=2bda389190cf1509584e1bcfb6c9ffe4343ffb1804cf8a9cd96ed874870f7f94

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    clang \
    curl \
    git \
    libcap-dev \
    libelf-dev \
    libz-dev \
    llvm \
    llvm-dev \
    lld \
    ninja-build \
    software-properties-common \
    make  \
    zlib1g-dev  \
    libbz2-dev  \
    libreadline-dev  \
    libsqlite3-dev  \
    unzip \
    wget  \
    libncurses5-dev  \
    xz-utils  \
    tk-dev  \
    libxml2-dev  \
    libxmlsec1-dev  \
    libffi-dev  \
    liblzma-dev \
    && apt-get clean \
    && curl --retry 10 -fsSLo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip \
    && echo "${AWSCLI_CHECKSUM} awscliv2.zip" | sha256sum --check \
    && unzip -q awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip \
    rm -rf /var/lib/apt/lists/*

# Python install
ENV PYTHONUTF8 1
ENV PYENV_ROOT="/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS

RUN git clone --depth=1 https://github.com/pyenv/pyenv.git ${PYENV_ROOT} && \
     pyenv install ${PYTHON_VERSION} && \
     pyenv global ${PYTHON_VERSION} && \
     pip install "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}" && \
     dda -v self dep sync -f legacy-build && \
     pyenv rehash

# Install authanywhere for infra token management
ADD --checksum=sha256:05d14b25e4607cc9e14867f2a0f38774869ae609eec890168e57de9a1b428e37 "https://binaries.ddbuild.io/dd-source/authanywhere/v0.0.2/authanywhere-tar.tar.gz" /tmp/authanywhere/authanywhere-tar.tar.gz
RUN --mount=type=bind,src=./setup/authanywhere.sh,dst=/mnt/setup/authanywhere.sh /mnt/setup/authanywhere.sh

COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

RUN git clone https://github.com/libbpf/bpftool.git
WORKDIR bpftool

# Pinned to the latest version to avoid having bpftool change under us when updating images.
# Can be updated to a newer version if needed, no restrictions on the specific version
# for now.
RUN git reset --hard 77a72987353fcae8ce330fd87d4c7afb7677a169 && \
    git submodule update --init

RUN make -C src/ V=1 install
