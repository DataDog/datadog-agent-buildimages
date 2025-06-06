FROM ubuntu:24.04 AS base

# Build Args - common arguments used across stages
ARG GO_VERSION
ARG GO_SHA256_LINUX_ARM64
ARG MSGO_SHA256_LINUX_ARM64
ARG MSGO_PATCH
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS=1
ARG CTNG_VERSION=1.26.0
ARG RUST_VERSION=1.76.0
ARG RUSTC_SHA256="673e336c81c65e6b16dcdede33f4cc9ed0f08bde1dbe7a935f113605292dc800"
ARG RUSTUP_VERSION=1.26.0
ARG RUSTUP_SHA256="673e336c81c65e6b16dcdede33f4cc9ed0f08bde1dbe7a935f113605292dc800"
ARG BUNDLER_VERSION=2.4.20
ARG DD_TARGET_ARCH
ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=1cdfd33e218ef145dbc3d71ac4164b89e453ff81b780ed178274bc1ba070e6e9
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_arm64.zip"
ARG CI_UPLOADER_VERSION=2.38.1
ARG CI_UPLOADER_SHA=90ee346ea639e2d70a45b70e2d1491e5749099665df06a2e6d80ddc9fd90fe0c

# Environment variables common to all stages
ENV PYTHONUTF8=1
ENV CONDA_PATH=/root/miniforge3

# Base system dependencies
RUN apt update -qy && apt install -y --no-install-recommends \
    wget xz-utils gpg build-essential flex texinfo unzip \
    help2man file gawk libtool-bin bison libncurses-dev \
    python-is-python3 git cmake curl fakeroot procps bzip2 \
    pkg-config libssl-dev libcurl4-openssl-dev libexpat-dev libpq-dev libz-dev \
    rpm tar gettext autopoint autoconf clang libtool-bin \
    pkg-config flex meson selinux-basics squashfs-tools gpg xz-utils gnupg2 patchelf cpio \
    linux-headers-generic jq libsystemd-dev clang-format \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && grep -v return /root/.bashrc >> /root/newbashrc && cp /root/newbashrc /root/.bashrc \
    && git config --global user.email "package@datadoghq.com" \
    && git config --global user.name "Bits"

# FROM base as texinfo-builder
FROM base as texinfo-builder
RUN cd /build && \
    git clone https://gnu.googlesource.com/texinfo && \
    cd texinfo && \
    git reset --hard 60d3edc4b74b4e1e5ef55e53de394d3b65506c47 && \
    ./autogen.sh && \
    ./configure && make -j$(nproc) && make install && \
    rm -rf /build/texinfo

# FROM base as crosstool-builder
FROM texinfo-builder as crosstool-builder
ARG CTNG_VERSION
COPY linux-glibc-2.23-arm64/config-aarch64-unknown-gnu-linux-glibc2.23 /build/crosstool-ng-${CTNG_VERSION}/.config
COPY linux-glibc-2.23-arm64/config-x86_64-unknown-gnu-linux-glibc2.17 /build/crosstool-ng-${CTNG_VERSION}/.config-x86
COPY linux-glibc-2.23-arm64/ctng.patch /root/ctng.patch

RUN cd /build && \
    wget https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/crosstool-ng-${CTNG_VERSION}.tar.xz && \
    gpg --keyserver pgp.surfnet.nl --recv-keys 1F30EF2E && \
    wget https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/crosstool-ng-${CTNG_VERSION}.tar.xz.sig && \
    gpg --verify crosstool-ng-${CTNG_VERSION}.tar.xz.sig && \
    tar xf crosstool-ng-${CTNG_VERSION}.tar.xz && \
    cd /build/crosstool-ng-${CTNG_VERSION} && \
    patch -p1 < /root/ctng.patch && \
    ./configure --enable-local && make -j$(nproc) && \
    export CT_ALLOW_BUILD_AS_ROOT_SURE=yes && \
    ./ct-ng upgradeconfig && ./ct-ng build && \
    mkdir -p /opt/toolchains/ && \
    mv /root/x-tools/aarch64-unknown-linux-gnu/ /opt/toolchains/aarch64 && \
    mv .config-x86 .config && \
    ./ct-ng upgradeconfig && \
    ./ct-ng build && \
    mv /root/x-tools/x86_64-unknown-linux-gnu/ /opt/toolchains/x86_64

# Final image with all components
FROM base

# Copy built components from previous stages
COPY --from=crosstool-builder /opt/toolchains /opt/toolchains

# Copy configuration files
COPY linux-glibc-2.23-arm64/toolchain_aarch64.cmake /opt/cmake/aarch64-unknown-linux-gnu.toolchain.cmake
COPY linux-glibc-2.23-arm64/cargo-config.toml ${HOME}/.cargo/config.toml

# Set environment variables for the toolchain
ENV DD_CC_PATH="/opt/toolchains/aarch64/bin/aarch64-unknown-linux-gnu-gcc"
ENV DD_CXX_PATH="/opt/toolchains/aarch64/bin/aarch64-unknown-linux-gnu-g++"
ENV DD_CMAKE_TOOLCHAIN_PATH="/opt/cmake/aarch64-unknown-linux-gnu.toolchain.cmake"
ENV PATH=/opt/toolchains/aarch64/bin:/opt/toolchains/x86_64/bin:$PATH
ENV PKG_CONFIG_LIBDIR=""

# CONDA installation in a single layer
COPY python-packages-versions.txt setup_python.sh /
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS
ENV DDA_VERSION=$DDA_VERSION
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS
RUN ./setup_python.sh
ENV PATH "${CONDA_PATH}/condabin:${PATH}"

# RVM installation in a single layer
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/* && rm -rf /gpg-keys \
    && curl -sSL -o get-rvm.sh https://raw.githubusercontent.com/rvm/rvm/1.29.12/binscripts/rvm-installer \
    && echo "fea24461e98d41528d6e28684aa4c216dbe903869bc3fcdb3493b6518fae2e7e  get-rvm.sh" | sha256sum --check \
    && bash get-rvm.sh stable --version 1.29.12 \
    && echo "d2de0b610ee321489e5c673fe749e13be8fb34c0aa08a74446d87f95a17de730  /usr/local/rvm/bin/rvm" | sha256sum --check \
    && rm get-rvm.sh \
    && /bin/bash -l -c "rvm requirements" \
    && /bin/bash -l -c "rvm install 2.7 --with-openssl-dir=${CONDA_PATH} && rvm cleanup all" \
    && /bin/bash -l -c "gem install bundler --version $BUNDLER_VERSION --no-document" \
    && echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc

# Go installation in a single layer
ENV GOPATH=/go
COPY setup_go.sh /
RUN ./setup_go.sh
ENV PATH="${GOPATH}/bin:${PATH}"

# Rust installation in a single layer
ARG RUST_VERSION
ARG RUSTC_SHA256
ARG RUSTUP_VERSION
ARG RUSTUP_SHA256
RUN curl -sSL -o rustup-init https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/aarch64-unknown-linux-gnu/rustup-init \
    && echo "${RUSTUP_SHA256}  rustup-init" | sha256sum --check \
    && chmod +x ./rustup-init \
    && ./rustup-init -y --profile minimal --default-toolchain ${RUST_VERSION} \
    && echo "${RUSTC_SHA256}  $HOME/.cargo/bin/rustc" | sha256sum --check \
    && rm ./rustup-init
ENV PATH "${HOME}/.cargo/bin:${PATH}"

# Vault installation in a single layer
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
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${CI_UPLOADER_VERSION}/datadog-ci_linux-arm64 --output "/usr/local/bin/datadog-ci" && \
    echo "${CI_UPLOADER_SHA} /usr/local/bin/datadog-ci" | sha256sum --check && \
    chmod +x /usr/local/bin/datadog-ci

# Final setup
RUN echo "umask 0022" >> /root/.bashrc \
    && mkdir -p /go/src/github.com/DataDog/datadog-agent

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
