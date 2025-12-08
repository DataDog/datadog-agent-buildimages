FROM ubuntu:24.04

# Common build arguments
ARG DD_TARGET_ARCH
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS=1
ARG CTNG_VERSION=1.26.0
ARG RUST_VERSION=1.91.0
ARG RUSTUP_VERSION=1.26.0
ARG BUNDLER_VERSION=2.4.20
ARG VAULT_VERSION=1.17.2
ARG DATADOG_CI_VERSION=3.9.0
ARG PROTOBUF_VERSION=29.3
ARG AWSCLI_VERSION=2.27.30
ARG DPKG_ARMHF_VERSION=1.18.4
ARG PULUMI_VERSION=3.207.0

# Architecture-specific build arguments
ARG ARCH
ARG VAULT_ARCH
ARG DATADOG_CI_ARCH
ARG PROTOBUF_ARCH
ARG CROSS_ARCH
ARG GLIBC_VERSION
ARG CROSS_GLIBC_VERSION
ARG GO_VERSION
ARG GO_SHA256_LINUX_AMD64
ARG GO_SHA256_LINUX_ARM64
ARG MSGO_SHA256_LINUX_AMD64
ARG MSGO_SHA256_LINUX_ARM64
ARG MSGO_PATCH
ARG RUSTUP_SHA256
ARG VAULT_SHA256
ARG DATADOG_CI_SHA256
ARG PROTOBUF_SHA256
ARG AWSCLI_SHA256
ARG DPKG_ARMHF_SHA256
ARG ADDITIONAL_PACKAGE

LABEL maintainer="DataDog"
LABEL glibc_version="${GLIBC_VERSION}"
LABEL ctng_version="${CTNG_VERSION}"
LABEL rust_version="${RUST_VERSION}"
LABEL rustup_version="${RUSTUP_VERSION}"
LABEL bundler_version="${BUNDLER_VERSION}"
LABEL vault_version="${VAULT_VERSION}"
LABEL datadog_ci_version="${DATADOG_CI_VERSION}"
LABEL protobuf_version="${PROTOBUF_VERSION}"
LABEL awscli_version="${AWSCLI_VERSION}"

# Set architecture-specific variables
ENV VAULT_FILENAME="vault_${VAULT_VERSION}_linux_${VAULT_ARCH}.zip"
ENV PROTOBUF_FILENAME="protoc-${PROTOBUF_VERSION}-linux-${PROTOBUF_ARCH}.zip"
# Common environment variables
ENV PYTHONUTF8=1
ENV CONDA_PATH=/root/miniforge3

# Remove the early return on non-interactive shells
RUN grep -v return /root/.bashrc >> /root/newbashrc && cp /root/newbashrc /root/.bashrc

# Install common dependencies
RUN apt update -qy && apt install -y \
    autoconf \
    autopoint \
    bison \
    build-essential \
    clang \
    wget \
    xz-utils \
    flex \
    texinfo \
    unzip \
    help2man \
    file \
    gawk \
    libtool-bin \
    libncurses-dev \
    python-is-python3 \
    git \
    cmake \
    curl \
    fakeroot \
    procps \
    bzip2 \
    pkg-config \
    libssl-dev \
    libcurl4-openssl-dev \
    libexpat-dev \
    libpq-dev \
    libz-dev \
    rpm \
    tar \
    gettext \
    libtool-bin \
    flex \
    meson \
    selinux-basics \
    squashfs-tools \
    gpg \
    xz-utils \
    gnupg2 \
    patchelf \
    cpio \
    xsltproc \
    linux-headers-generic \
    yq \
    libsystemd-dev \
    clang-format \
    libseccomp-dev \
    shellcheck \
    ${ADDITIONAL_PACKAGE}

# Git configuration
RUN git config --global user.email "package@datadoghq.com" && \
    git config --global user.name "Bits"

# Copy architecture-specific configuration files
# TODO: Do this cleaner
COPY linux/${DATADOG_CI_ARCH}/config-${ARCH}-unknown-gnu-linux-glibc${GLIBC_VERSION} /build/crosstool-ng-${CTNG_VERSION}/.config
COPY linux/${DATADOG_CI_ARCH}/config-${CROSS_ARCH}-unknown-gnu-linux-glibc${CROSS_GLIBC_VERSION} /build/crosstool-ng-${CTNG_VERSION}/.config-${CROSS_ARCH}
COPY linux/${DATADOG_CI_ARCH}/toolchain_${ARCH}.cmake /opt/cmake/${ARCH}-unknown-linux-gnu.toolchain.cmake
COPY linux/${DATADOG_CI_ARCH}/cargo-config.toml /root/.cargo/config.toml
COPY linux/ctng.patch /root/ctng.patch

# Build texinfo to get a bugfix version
RUN --mount=type=bind,src=./setup/texinfo.sh,dst=/mnt/setup/texinfo.sh /mnt/setup/texinfo.sh

# Build cross-compilation toolchain
RUN --mount=type=bind,src=./setup/ctng.sh,dst=/mnt/setup/ctng.sh /mnt/setup/ctng.sh

# Build dpkg-armhf
RUN --mount=type=bind,src=./setup/dpkg.sh,dst=/mnt/setup/dpkg.sh /mnt/setup/dpkg.sh

# CONDA setup
ENV DDA_VERSION=$DDA_VERSION
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS
RUN --mount=type=bind,src=./setup/python.sh,dst=/mnt/setup/python.sh \
    --mount=type=bind,src=./python-packages-versions.txt,dst=/mnt/python-packages-versions.txt \
    /mnt/setup/python.sh
ENV PATH="${CONDA_PATH}/condabin:${PATH}"

# RVM setup
COPY ./rvm/gpg-keys /gpg-keys
RUN --mount=type=bind,src=./setup/rvm.sh,dst=/mnt/setup/rvm.sh /mnt/setup/rvm.sh

# Protobuf
RUN --mount=type=bind,src=./setup/protobuf.sh,dst=/mnt/setup/protobuf.sh /mnt/setup/protobuf.sh

# Go setup
ENV GOPATH=/go
RUN --mount=type=bind,src=./setup/go.sh,dst=/mnt/setup/go.sh /mnt/setup/go.sh
ENV PATH="${GOPATH}/bin:${PATH}"

# Install & verify Bazelisk as Bazel bootstrapper
RUN --mount=type=bind,src=./setup/bazelisk.sh,dst=/mnt/setup/bazelisk.sh /mnt/setup/bazelisk.sh

# Rust setup
RUN --mount=type=bind,src=./setup/rust.sh,dst=/mnt/setup/rust.sh /mnt/setup/rust.sh
ENV PATH="/root/.cargo/bin:${PATH}"
RUN /root/.cargo/bin/rustup default ${RUST_VERSION}


# Install vault
RUN --mount=type=bind,src=./setup/vault.sh,dst=/mnt/setup/vault.sh /mnt/setup/vault.sh

# Install Pulumi
RUN --mount=type=bind,src=./setup/pulumi.sh,dst=/mnt/setup/pulumi.sh /mnt/setup/pulumi.sh

# Install dd-octo-sts
COPY --from=registry.ddbuild.io/dd-octo-sts:v1.9.3 /usr/local/bin/dd-octo-sts /usr/local/bin/dd-octo-sts


# Install CI uploader
RUN --mount=type=bind,src=./setup/ciuploader.sh,dst=/mnt/setup/ciuploader.sh /mnt/setup/ciuploader.sh

# Install authanywhere for infra token management
RUN --mount=type=bind,src=./setup/authanywhere.sh,dst=/mnt/setup/authanywhere.sh /mnt/setup/authanywhere.sh

# Install datadog-packages
RUN --mount=type=secret,id=ci-job-token,env=CI_JOB_TOKEN --mount=type=bind,src=./setup/datadog_packages.sh,dst=/mnt/setup/datadog_packages.sh /mnt/setup/datadog_packages.sh

# Cleanup go caches - go env is only set in bashrc
RUN /usr/local/go/bin/go clean -modcache -cache -testcache

# Common environment setup
RUN echo "umask 0022" >> /root/.bashrc && \
    mkdir -p /go/src/github.com/DataDog/datadog-agent

# Set up environment
ENV PATH=/opt/toolchains/${ARCH}/bin:/opt/toolchains/${CROSS_ARCH}/bin:$PATH

# Ensure pkg-config will not look into the system directories
ENV PKG_CONFIG_LIBDIR=""

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
