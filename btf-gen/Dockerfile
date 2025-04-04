FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ARG PYTHON_VERSION=3.12.6
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS

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
    wget  \
    libncurses5-dev  \
    xz-utils  \
    tk-dev  \
    libxml2-dev  \
    libxmlsec1-dev  \
    libffi-dev  \
    liblzma-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Python install
ENV PYENV_ROOT="/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS

RUN git clone --depth=1 https://github.com/pyenv/pyenv.git ${PYENV_ROOT} && \
     pyenv install ${PYTHON_VERSION} && \
     pyenv global ${PYTHON_VERSION} && \
     pip install "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}" && \
     dda -v self dep sync -f legacy-build -f legacy-btf-gen && \
     pyenv rehash

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
