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
COPY linux/${DATADOG_CI_ARCH}/toolchain_${ARCH}.cmake /opt/cmake/${ARCH}-unknown-linux-gnu.toolchain.cmake
COPY linux/${DATADOG_CI_ARCH}/cargo-config.toml /root/.cargo/config.toml
COPY linux/ctng.patch /root/ctng.patch

# Build texinfo to get a bugfix version
ADD https://gnu.googlesource.com/texinfo.git#60d3edc4b74b4e1e5ef55e53de394d3b65506c47 /tmp/texinfo
RUN --mount=type=bind,src=./setup/texinfo.sh,dst=/mnt/setup/texinfo.sh cd /tmp/texinfo && /mnt/setup/texinfo.sh && rm -rf /tmp/texinfo

# Build cross-compilation toolchain
# TODO: Add checksum
# NOTE: tar archives from remote URLs are not automatically extracted (https://docs.docker.com/reference/dockerfile/#adding-local-tar-archives)
ADD https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/crosstool-ng-${CTNG_VERSION}.tar.xz \
    https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/crosstool-ng-${CTNG_VERSION}.tar.xz.sig \
    /tmp/crosstool-ng/

COPY linux/${DATADOG_CI_ARCH}/config-${ARCH}-unknown-gnu-linux-glibc${GLIBC_VERSION} /tmp/crosstool-ng/crosstool-ng-${CTNG_VERSION}/.config
COPY linux/${DATADOG_CI_ARCH}/config-${CROSS_ARCH}-unknown-gnu-linux-glibc${CROSS_GLIBC_VERSION} /tmp/crosstool-ng/crosstool-ng-${CTNG_VERSION}/.config-${CROSS_ARCH}
RUN --mount=type=bind,src=./setup/ctng.sh,dst=/mnt/setup/ctng.sh cd /tmp/crosstool-ng && /mnt/setup/ctng.sh && rm -rf /tmp/crosstool-ng

# Build dpkg-armhf
ADD --checksum=sha256:${DPKG_ARMHF_SHA256} "https://salsa.debian.org/dpkg-team/dpkg/-/archive/${DPKG_ARMHF_VERSION}/dpkg-${DPKG_ARMHF_VERSION}.tar.bz2" \
    /tmp/dpkg-armhf/
RUN --mount=type=bind,src=./setup/dpkg.sh,dst=/mnt/setup/dpkg.sh cd /tmp/dpkg-armhf && /mnt/setup/dpkg.sh && rm -rf /tmp/dpkg-armhf

# CONDA setup
# TODO: Refactor this once we have multistage so that each architecture has its own intermediate image
ENV DDA_VERSION=$DDA_VERSION
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS
RUN --mount=type=bind,src=./setup/python.sh,dst=/mnt/setup/python.sh \
    --mount=type=bind,src=./python-packages-versions.txt,dst=/mnt/python-packages-versions.txt \
    /mnt/setup/python.sh
ENV PATH="${CONDA_PATH}/condabin:${PATH}"

# RVM setup
ADD --checksum=sha256:fea24461e98d41528d6e28684aa4c216dbe903869bc3fcdb3493b6518fae2e7e \
    "https://raw.githubusercontent.com/rvm/rvm/1.29.12/binscripts/rvm-installer" \
    /tmp/rvm/get-rvm.sh
COPY ./rvm/gpg-keys /gpg-keys
# TODO: Maybe deprecate the get-rvm.sh script and manually download and extract a tar.
# The script we download does a lot of extra checking that we don't need in a Docker build.
RUN --mount=type=bind,src=./setup/rvm.sh,dst=/mnt/setup/rvm.sh cd /tmp/rvm && /mnt/setup/rvm.sh && rm -rf /tmp/rvm

# Protobuf
ADD --checksum=sha256:${PROTOBUF_SHA256} "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/${PROTOBUF_FILENAME}" /tmp/protobuf/${PROTOBUF_FILENAME}
RUN --mount=type=bind,src=./setup/protobuf.sh,dst=/mnt/setup/protobuf.sh cd /tmp/protobuf && /mnt/setup/protobuf.sh && rm -rf /tmp/protobuf

# Go setup
# TODO: Refactor this once we have multistage so that each architecture has its own intermediate image
ENV GOPATH=/go
RUN --mount=type=bind,src=./setup/go.sh,dst=/mnt/setup/go.sh /mnt/setup/go.sh
ENV PATH="${GOPATH}/bin:${PATH}"

# Install & verify Bazelisk as Bazel bootstrapper
# TODO: Refactor this once we have multistage so that each architecture has its own intermediate image
RUN --mount=type=bind,src=./setup/bazelisk.sh,dst=/mnt/setup/bazelisk.sh /mnt/setup/bazelisk.sh

# Rust setup
# TODO: Maybe deprecate the rustup-init script and manually download and extract a tar.
ADD --checksum=sha256:${RUSTUP_SHA256} "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${ARCH}-unknown-linux-gnu/rustup-init" /tmp/rust/rustup-init
RUN --mount=type=bind,src=./setup/rust.sh,dst=/mnt/setup/rust.sh cd /tmp/rust && /mnt/setup/rust.sh && rm -rf /tmp/rust
ENV PATH="/root/.cargo/bin:${PATH}"
RUN /root/.cargo/bin/rustup default ${RUST_VERSION}


# Install vault
ADD --checksum=sha256:${VAULT_SHA256} "https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME}" /tmp/vault/vault.zip
ADD --checksum=sha256:${AWSCLI_SHA256} "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}-${AWSCLI_VERSION}.zip" /tmp/vault/awscliv2.zip
RUN --mount=type=bind,src=./setup/vault.sh,dst=/mnt/setup/vault.sh cd /tmp/vault && /mnt/setup/vault.sh && rm -rf /tmp/vault

# Install Pulumi
# TODO: Add logic to download the tarball directly instead of relying on this script
# It's sort of dumb to checksum and cache a script instead of the actual tarball we're interested in
ADD --checksum=sha256:1fe472a5915b416299df9a1b490e7e6d573d3c9f41c662ff4322a79bf4bf0550 https://get.pulumi.com/ /tmp/pulumi/get-pulumi.sh
RUN chmod +x /tmp/pulumi/get-pulumi.sh && /tmp/pulumi/get-pulumi.sh --version $PULUMI_VERSION && mv ~/.pulumi/bin/* /usr/local/bin

# Install dd-octo-sts
COPY --from=registry.ddbuild.io/dd-octo-sts:v1.9.3 /usr/local/bin/dd-octo-sts /usr/local/bin/dd-octo-sts


# Install CI uploader
ADD --checksum=sha256:${DATADOG_CI_SHA256} "https://github.com/DataDog/datadog-ci/releases/download/v${DATADOG_CI_VERSION}/datadog-ci_linux-${DATADOG_CI_ARCH}" /usr/local/bin/datadog-ci
RUN chmod +x /usr/local/bin/datadog-ci

# Install authanywhere for infra token management
ADD --checksum=sha256:05d14b25e4607cc9e14867f2a0f38774869ae609eec890168e57de9a1b428e37 "https://binaries.ddbuild.io/dd-source/authanywhere/v0.0.2/authanywhere-tar.tar.gz" /tmp/authanywhere/authanywhere-tar.tar.gz
RUN --mount=type=bind,src=./setup/authanywhere.sh,dst=/mnt/setup/authanywhere.sh cd /tmp/authanywhere && /mnt/setup/authanywhere.sh && rm -rf /tmp/authanywhere
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
