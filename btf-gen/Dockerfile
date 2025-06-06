FROM ubuntu:22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
ARG PYTHON_VERSION=3.12.6
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS

# Environment variables common to all stages
ENV PYTHONUTF8=1
ENV PYENV_ROOT="/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS

# Install base dependencies in a single layer
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
    make \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    wget \
    libncurses5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# FROM base as bpftool-builder
FROM base as bpftool-builder
RUN git clone https://github.com/libbpf/bpftool.git && \
    cd bpftool && \
    # Pinned to the latest version to avoid having bpftool change under us when updating images.
    # Can be updated to a newer version if needed, no restrictions on the specific version
    # for now.
    git reset --hard 77a72987353fcae8ce330fd87d4c7afb7677a169 && \
    git submodule update --init && \
    make -C src/ V=1

# Final image
FROM base

# Copy built components
COPY --from=bpftool-builder /bpftool/src/bpftool /usr/local/bin/bpftool

# Install Python with pyenv in a single layer
ARG PYTHON_VERSION
ARG DDA_VERSION
RUN git clone --depth=1 https://github.com/pyenv/pyenv.git ${PYENV_ROOT} && \
    pyenv install ${PYTHON_VERSION} && \
    pyenv global ${PYTHON_VERSION} && \
    pip install "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}" && \
    dda -v self dep sync -f legacy-build -f legacy-btf-gen && \
    pyenv rehash
