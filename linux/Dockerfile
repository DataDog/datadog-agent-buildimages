FROM ubuntu:24.04 AS builder_base

# Remove the early return on non-interactive shells
RUN grep -v return /root/.bashrc >> /root/newbashrc && cp /root/newbashrc /root/.bashrc

# Install common dependencies
ARG ADDITIONAL_PACKAGE
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


FROM builder_base AS texinfo_builder
# Build texinfo to get a bugfix version
ADD https://gnu.googlesource.com/texinfo.git#60d3edc4b74b4e1e5ef55e53de394d3b65506c47 /tmp/texinfo
RUN ls /tmp/texinfo
RUN --mount=type=bind,src=./setup/texinfo.sh,dst=/mnt/setup/texinfo.sh cd /tmp/texinfo && /mnt/setup/texinfo.sh && rm -rf /tmp/texinfo

FROM texinfo_builder AS crosstool_ng_builder
# CTNG depends on texinfo
# Build cross-compilation toolchain
ARG CTNG_VERSION
ARG CTNG_ARCH
ARG CTNG_CROSS_ARCH
ARG GLIBC_VERSION
ARG CROSS_GLIBC_VERSION

# TODO: Add checksum
# NOTE: tar archives from remote URLs are not automatically extracted (https://docs.docker.com/reference/dockerfile/#adding-local-tar-archives)
ADD https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/crosstool-ng-${CTNG_VERSION}.tar.xz \
    https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/crosstool-ng-${CTNG_VERSION}.tar.xz.sig \
    /tmp/crosstool-ng/

COPY linux/${CTNG_ARCH}/toolchain_${CTNG_ARCH}.cmake /opt/cmake/${CTNG_ARCH}-unknown-linux-gnu.toolchain.cmake
COPY linux/${CTNG_ARCH}/cargo-config.toml /root/.cargo/config.toml
COPY linux/${CTNG_ARCH}/config-${CTNG_ARCH}-unknown-gnu-linux-glibc${GLIBC_VERSION} /tmp/crosstool-ng/crosstool-ng-${CTNG_VERSION}/.config
COPY linux/${CTNG_ARCH}/config-${CTNG_CROSS_ARCH}-unknown-gnu-linux-glibc${CROSS_GLIBC_VERSION} /tmp/crosstool-ng/crosstool-ng-${CTNG_VERSION}/.config-${CTNG_CROSS_ARCH}
COPY linux/ctng.patch /root/ctng.patch
RUN --mount=type=bind,src=./setup/ctng.sh,dst=/mnt/setup/ctng.sh cd /tmp/crosstool-ng && /mnt/setup/ctng.sh && rm -rf /tmp/crosstool-ng

FROM builder_base AS dpkg_armhf_builder
# Build dpkg-armhf
ARG DPKG_ARMHF_VERSION
ARG DPKG_ARMHF_SHA256

ADD --checksum=sha256:${DPKG_ARMHF_SHA256} "https://salsa.debian.org/dpkg-team/dpkg/-/archive/${DPKG_ARMHF_VERSION}/dpkg-${DPKG_ARMHF_VERSION}.tar.bz2" \
    /tmp/dpkg-armhf/
RUN --mount=type=bind,src=./setup/dpkg.sh,dst=/mnt/setup/dpkg.sh cd /tmp/dpkg-armhf && /mnt/setup/dpkg.sh && rm -rf /tmp/dpkg-armhf

FROM builder_base AS python_builder
# Python and Conda setup

ARG PY3_VERSION
ARG CONDA_VERSION
ARG CONDA_SHA256
ARG CONDA_ARCH

# Common environment variables
ENV PYTHONUTF8=1
ENV CONDA_PATH=/root/miniforge3
ENV PATH="${CONDA_PATH}/condabin:${PATH}"

ADD --checksum=sha256:${CONDA_SHA256} "https://github.com/conda-forge/miniforge/releases/download/${CONDA_VERSION}/Miniforge3-Linux-${CONDA_ARCH}.sh" /tmp/conda/miniconda.sh
RUN --mount=type=bind,src=./setup/python.sh,dst=/mnt/setup/python.sh \
    --mount=type=bind,src=./python-packages-versions.txt,dst=/mnt/python-packages-versions.txt \
    cd /tmp/conda && /mnt/setup/python.sh && rm -rf /tmp/conda

ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS=1
ADD https://github.com/DataDog/datadog-agent-dev.git#${DDA_VERSION} /tmp/dda
RUN --mount=type=bind,src=./setup/dda.sh,dst=/mnt/setup/dda.sh cd /tmp/dda && /mnt/setup/dda.sh && rm -rf /tmp/dda

FROM builder_base AS rvm_builder
# RVM setup
ARG RVM_VERSION
ARG BUNDLER_VERSION
ARG RVM_SHA256

ADD --checksum=sha256:${RVM_SHA256} \
    "https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION}/binscripts/rvm-installer" \
    /tmp/rvm/get-rvm.sh
COPY ./rvm/gpg-keys /gpg-keys
# TODO: Maybe deprecate the get-rvm.sh script and manually download and extract a tar.
# The script we download does a lot of extra checking that we don't need in a Docker build.
RUN --mount=type=bind,src=./setup/rvm.sh,dst=/mnt/setup/rvm.sh cd /tmp/rvm && /mnt/setup/rvm.sh && rm -rf /tmp/rvm

FROM builder_base AS protobuf_builder
# Protobuf
ARG PROTOBUF_VERSION
ARG PROTOBUF_SHA256
ARG PROTOBUF_ARCH
ENV PROTOBUF_FILENAME="protoc-${PROTOBUF_VERSION}-linux-${PROTOBUF_ARCH}.zip"

ADD --checksum=sha256:${PROTOBUF_SHA256} "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/${PROTOBUF_FILENAME}" /tmp/protobuf/${PROTOBUF_FILENAME}
RUN --mount=type=bind,src=./setup/protobuf.sh,dst=/mnt/setup/protobuf.sh cd /tmp/protobuf && /mnt/setup/protobuf.sh && rm -rf /tmp/protobuf

FROM builder_base AS go_builder
# Go setup
ARG GO_VERSION
ARG GO_SHA256
ARG MSGO_SHA256
ARG GO_ARCH
ARG MSGO_PATCH

ENV GOPATH=/go


ADD https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz /tmp/go/go.tar.gz
ADD https://aka.ms/golang/release/latest/go${GO_VERSION}-${MSGO_PATCH}.linux-${GO_ARCH}.tar.gz /tmp/go/msgo.tar.gz
RUN --mount=type=bind,src=./setup/go.sh,dst=/mnt/setup/go.sh cd /tmp/go && /mnt/setup/go.sh && rm -rf /tmp/go
ENV PATH="${GOPATH}/bin:${PATH}"

FROM builder_base AS bazelisk_builder
# Install & verify Bazelisk as Bazel bootstrapper
ARG BAZELISK_VERSION
ARG BAZELISK_ARCH
ARG BAZELISK_SHA256

ADD --chmod=755 --checksum=sha256:${BAZELISK_SHA256} "https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-linux-${BAZELISK_ARCH}" /tmp/bazelisk/bazelisk
ENV PATH="/usr/local/bin:${PATH}"
RUN --mount=type=bind,src=./setup/bazelisk.sh,dst=/mnt/setup/bazelisk.sh cd /tmp/bazelisk && /mnt/setup/bazelisk.sh && rm -rf /tmp/bazelisk

FROM builder_base AS rust_builder
# Rust setup
# TODO: Maybe deprecate the rustup-init script and manually download and extract a tar.
ARG RUST_VERSION
ARG RUSTUP_VERSION
ARG RUSTUP_SHA256
ARG RUSTUP_ARCH

ADD --checksum=sha256:${RUSTUP_SHA256} "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${RUSTUP_ARCH}-unknown-linux-gnu/rustup-init" /tmp/rust/rustup-init
RUN --mount=type=bind,src=./setup/rust.sh,dst=/mnt/setup/rust.sh cd /tmp/rust && /mnt/setup/rust.sh && rm -rf /tmp/rust
ENV PATH="/root/.cargo/bin:${PATH}"

FROM builder_base AS vault_builder
# Install vault
ARG VAULT_VERSION
ARG AWSCLI_VERSION
ARG VAULT_SHA256
ARG AWSCLI_SHA256
ARG VAULT_ARCH
ARG AWSCLI_ARCH
ENV VAULT_FILENAME="vault_${VAULT_VERSION}_linux_${VAULT_ARCH}.zip"

ADD --checksum=sha256:${VAULT_SHA256} "https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME}" /tmp/vault/vault.zip
ADD --checksum=sha256:${AWSCLI_SHA256} "https://awscli.amazonaws.com/awscli-exe-linux-${AWSCLI_ARCH}-${AWSCLI_VERSION}.zip" /tmp/vault/awscliv2.zip
RUN --mount=type=bind,src=./setup/vault.sh,dst=/mnt/setup/vault.sh cd /tmp/vault && /mnt/setup/vault.sh && rm -rf /tmp/vault


FROM builder_base AS pulumi_builder
# Install Pulumi
# TODO: Add logic to download the tarball directly instead of relying on this script
# It's sort of dumb to checksum and cache a script instead of the actual tarball we're interested in
ARG PULUMI_SHA256
ADD --checksum=sha256:${PULUMI_SHA256} https://get.pulumi.com/ /tmp/pulumi/get-pulumi.sh
ARG PULUMI_VERSION
RUN chmod +x /tmp/pulumi/get-pulumi.sh && /tmp/pulumi/get-pulumi.sh --version $PULUMI_VERSION && mv ~/.pulumi/bin/* /usr/local/bin

FROM builder_base AS datadog_ci_builder
# Install CI uploader
ARG DATADOG_CI_VERSION
ARG DATADOG_CI_SHA256
ARG DATADOG_CI_ARCH

ADD --checksum=sha256:${DATADOG_CI_SHA256} "https://github.com/DataDog/datadog-ci/releases/download/v${DATADOG_CI_VERSION}/datadog-ci_linux-${DATADOG_CI_ARCH}" /usr/local/bin/datadog-ci
RUN chmod +x /usr/local/bin/datadog-ci

FROM builder_base AS authanywhere_builder
# Install authanywhere for infra token management
ADD --checksum=sha256:05d14b25e4607cc9e14867f2a0f38774869ae609eec890168e57de9a1b428e37 "https://binaries.ddbuild.io/dd-source/authanywhere/v0.0.2/authanywhere-tar.tar.gz" /tmp/authanywhere/authanywhere-tar.tar.gz
RUN --mount=type=bind,src=./setup/authanywhere.sh,dst=/mnt/setup/authanywhere.sh cd /tmp/authanywhere && /mnt/setup/authanywhere.sh && rm -rf /tmp/authanywhere

FROM go_builder AS datadog_packages_builder
# Install datadog-packages
ARG DATADOG_PACKAGES_VERSION
ENV DATADOG_PACKAGES_VERSION=${DATADOG_PACKAGES_VERSION}
RUN --mount=type=secret,id=ci-job-token,env=CI_JOB_TOKEN --mount=type=bind,src=./setup/datadog_packages.sh,dst=/mnt/setup/datadog_packages.sh /mnt/setup/datadog_packages.sh

FROM builder_base AS final

# Copy built tools
# NOTE: We try to copy the least-often-used tools first to reduce the likelihood of cache misses

# Protobuf
COPY --from=protobuf_builder /usr/bin/protoc /usr/bin/protoc
COPY --from=protobuf_builder /usr/include/google /usr/include/google

# Vault
COPY --from=vault_builder /usr/local/bin/aws* /usr/local/bin/
COPY --from=vault_builder /usr/local/aws* /usr/local/

# Authanywhere
COPY --from=authanywhere_builder /usr/local/bin/authanywhere /usr/local/bin/authanywhere

# Pulumi
COPY --from=pulumi_builder /usr/local/bin/pulumi /usr/local/bin/pulumi

# Install dd-octo-sts
COPY --from=registry.ddbuild.io/dd-octo-sts:v1.9.3 /usr/local/bin/dd-octo-sts /usr/local/bin/dd-octo-sts

# Datadog packages
COPY --from=datadog_packages_builder /go/bin/datadog-package /go/bin/datadog-package

# RVM
COPY --from=rvm_builder /usr/local/rvm /usr/local/rvm

# Rust
COPY --from=rust_builder /root/.cargo /root/.cargo

# Datadog CI
COPY --from=datadog_ci_builder /usr/local/bin/datadog-ci /usr/local/bin/datadog-ci

# Crosstool-ng
COPY --from=crosstool_ng_builder /opt/toolchains /opt/toolchains

# Dpkg-armhf
COPY --from=dpkg_armhf_builder /opt/dpkg-armhf /opt/dpkg-armhf

# Bazelisk
COPY --from=bazelisk_builder /usr/bin/bazel* /usr/bin/

# Go
COPY --from=go_builder /usr/local/go /usr/local/go

# Conda & Python
ENV CONDA_PATH=/root/miniforge3
COPY --from=python_builder ${CONDA_PATH} ${CONDA_PATH}


RUN echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc

# Common environment setup
# Git configuration
RUN git config --global user.email "package@datadoghq.com" && \
    git config --global user.name "Bits"


RUN echo "umask 0022" >> /root/.bashrc && \
    mkdir -p /go/src/github.com/DataDog/datadog-agent

# Set up environment
ARG CTNG_ARCH
ARG CTNG_CROSS_ARCH
ENV PATH=/opt/toolchains/${CTNG_ARCH}/bin:/opt/toolchains/${CTNG_CROSS_ARCH}/bin:$PATH

# Ensure pkg-config will not look into the system directories
ENV PKG_CONFIG_LIBDIR=""

# Set the version of the Rust toolchain to use by default
ARG RUST_VERSION
RUN /root/.cargo/bin/rustup default ${RUST_VERSION}

# Label the image
ARG PROTOBUF_VERSION
ARG VAULT_VERSION
ARG AWSCLI_VERSION
ARG RVM_VERSION
ARG BUNDLER_VERSION
ARG RUSTUP_VERSION
ARG DATADOG_CI_VERSION
ARG GLIBC_VERSION
ARG CTNG_VERSION
ARG DPKG_ARMHF_VERSION
ARG GO_VERSION
ARG DDA_VERSION
ARG DATADOG_PACKAGES_VERSION
ARG PULUMI_VERSION

LABEL protobuf_version="${PROTOBUF_VERSION}"
LABEL vault_version="${VAULT_VERSION}"
LABEL awscli_version="${AWSCLI_VERSION}"
LABEL rvm_version="${RVM_VERSION}"
LABEL bundler_version="${BUNDLER_VERSION}"
LABEL rust_version="${RUST_VERSION}"
LABEL rustup_version="${RUSTUP_VERSION}"
LABEL datadog_ci_version="${DATADOG_CI_VERSION}"
LABEL glibc_version="${GLIBC_VERSION}"
LABEL ctng_version="${CTNG_VERSION}"
LABEL dpkg_armhf_version="${DPKG_ARMHF_VERSION}"
LABEL go_version="${GO_VERSION}"
LABEL dda_version="${DDA_VERSION}"
LABEL datadog_packages_version="${DATADOG_PACKAGES_VERSION}"
LABEL pulumi_version="${PULUMI_VERSION}"
LABEL dd_octo_sts_version="${DD_OCTO_STS_VERSION}"
LABEL maintainer="DataDog"
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
