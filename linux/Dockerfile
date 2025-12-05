ARG BASE_IMAGE=ubuntu:24.04

# Create different base stages for subsequent build stages
# Common dependencies for all stages
FROM ${BASE_IMAGE} AS common_base
RUN apt-get update -qy && apt-get install -y --no-install-recommends \
    ca-certificates

# Minimal base for stages doing simple extraction (no compilation)
FROM common_base AS extraction_base
# Do an apt update only once at the beginning
RUN apt-get update -qy && apt-get install -y --no-install-recommends \
    tar unzip xz-utils bzip2

# Base for compilation stages - includes all other packages needed for building tools
# TODO: Investigate which ones are used in which stages and only install them there
FROM extraction_base AS build_base
RUN apt-get update -qy && apt-get install -y --no-install-recommends \
    # Meta-package providing gcc, g++, make, libc6-dev, etc.
    build-essential \
    automake autoconf autopoint gettext help2man \
    libtool libtool-bin libz-dev libssl-dev \
    libffi-dev libgdbm-dev libncurses-dev \
    libpq-dev libreadline-dev libyaml-dev \
    libcurl4-openssl-dev libexpat-dev libsystemd-dev libseccomp-dev \
    wget curl git gpg dirmngr gpg-agent patch texinfo \
    perl python3-dev \
    bison flex pkg-config gawk \
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


FROM build_base AS texinfo_builder
# Build texinfo to get a bugfix version
ADD https://gnu.googlesource.com/texinfo.git#60d3edc4b74b4e1e5ef55e53de394d3b65506c47 /tmp/texinfo
RUN --mount=type=bind,src=./setup/texinfo.sh,dst=/mnt/texinfo.sh cd /tmp/texinfo && /mnt/texinfo.sh

FROM texinfo_builder AS crosstool_ng_builder
# CTNG depends on texinfo
# Build cross-compilation toolchain

# Install crosstool-ng specific dependencies (not included in build_base)
RUN apt-get install -y --no-install-recommends \
    gperf flex libncurses5-dev rsync meson ninja-build

ARG CTNG_VERSION=1.26.0
ARG CROSS_ARCH
ARG GLIBC_VERSION
ARG CROSS_GLIBC_VERSION

# Re-export as env for use in LABEL steps in the final stage
ENV CTNG_VERSION=$CTNG_VERSION
ENV GLIBC_VERSION=$GLIBC_VERSION

# TODO: Add checksum
# NOTE: tar archives from remote URLs are not automatically extracted (https://docs.docker.com/reference/dockerfile/#adding-local-tar-archives)
ADD https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/crosstool-ng-${CTNG_VERSION}.tar.xz \
    https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/crosstool-ng-${CTNG_VERSION}.tar.xz.sig \
    /tmp/crosstool-ng/

COPY linux/${BUILDARCH}/toolchain_${ARCH}.cmake /opt/cmake/${ARCH}-unknown-linux-gnu.toolchain.cmake
COPY linux/${BUILDARCH}/cargo-config.toml /root/.cargo/config.toml
COPY linux/${BUILDARCH}/config-${ARCH}-unknown-gnu-linux-glibc${GLIBC_VERSION} /tmp/crosstool-ng/crosstool-ng-${CTNG_VERSION}/.config
COPY linux/${BUILDARCH}/config-${CROSS_ARCH}-unknown-gnu-linux-glibc${CROSS_GLIBC_VERSION} /tmp/crosstool-ng/crosstool-ng-${CTNG_VERSION}/.config-${CROSS_ARCH}
COPY linux/ctng.patch /root/ctng.patch
RUN --mount=type=bind,src=./setup/ctng.sh,dst=/mnt/ctng.sh cd /tmp/crosstool-ng && /mnt/ctng.sh && rm -rf /tmp/crosstool-ng

FROM build_base AS dpkg_armhf_builder
# Build dpkg-armhf
ARG DPKG_ARMHF_VERSION=1.18.4
ARG DPKG_ARMHF_SHA256
# Re-export as env for use in LABEL steps in the final stage
ENV DPKG_ARMHF_VERSION=$DPKG_ARMHF_VERSION

# Install dpkg-specific build dependencies
RUN apt-get install -y --no-install-recommends \
    libmd-dev libbz2-dev liblzma-dev

ADD --checksum=sha256:${DPKG_ARMHF_SHA256} "https://salsa.debian.org/dpkg-team/dpkg/-/archive/${DPKG_ARMHF_VERSION}/dpkg-${DPKG_ARMHF_VERSION}.tar.bz2" \
    /tmp/dpkg-armhf/
RUN --mount=type=bind,src=./setup/dpkg.sh,dst=/mnt/dpkg.sh cd /tmp/dpkg-armhf && /mnt/dpkg.sh && rm -rf /tmp/dpkg-armhf

FROM build_base AS python_builder
# CONDA setup
# TODO: Refactor this once we have multistage so that each architecture has its own intermediate image

ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS=1
# Re-export as env for use in LABEL steps in the final stage
ENV DDA_VERSION=$DDA_VERSION
# Common environment variables
ENV PYTHONUTF8=1
ENV CONDA_PATH=/root/miniforge3

RUN --mount=type=bind,src=./setup/python.sh,dst=/mnt/python.sh \
    --mount=type=bind,src=./python-packages-versions.txt,dst=/mnt/python-packages-versions.txt \
    /mnt/python.sh
ENV PATH="${CONDA_PATH}/condabin:${PATH}"

FROM python_builder AS rvm_builder
# Somehow building RVM needs some opensslstuff from the python_builder stage

ARG RVM_VERSION=1.29.12
ARG BUNDLER_VERSION=2.4.20
ARG RVM_SHA256=fea24461e98d41528d6e28684aa4c216dbe903869bc3fcdb3493b6518fae2e7e
ARG CONDA_PATH
ENV CONDA_PATH=$CONDA_PATH
ENV RVM_VERSION=$RVM_VERSION
ENV BUNDLER_VERSION=$BUNDLER_VERSION

ADD --checksum=sha256:${RVM_SHA256} \
    "https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION}/binscripts/rvm-installer" \
    /tmp/rvm/get-rvm.sh
COPY ./rvm/gpg-keys /gpg-keys
# TODO: Maybe deprecate the get-rvm.sh script and manually download and extract a tar.
# The script we download does a lot of extra checking that we don't need in a Docker build.
RUN --mount=type=bind,src=./setup/rvm.sh,dst=/mnt/rvm.sh cd /tmp/rvm && /mnt/rvm.sh && rm -rf /tmp/rvm

FROM extraction_base AS protobuf_builder
# Protobuf
ARG PROTOBUF_VERSION=29.3
ARG PROTOBUF_SHA256
ARG PROTOBUF_ARCH
# Re-export as env for use in LABEL steps in the final stage
ENV PROTOBUF_VERSION=$PROTOBUF_VERSION
ENV PROTOBUF_FILENAME="protoc-${PROTOBUF_VERSION}-linux-${PROTOBUF_ARCH}.zip"

ADD --checksum=sha256:${PROTOBUF_SHA256} "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/${PROTOBUF_FILENAME}" /tmp/protobuf/${PROTOBUF_FILENAME}
RUN --mount=type=bind,src=./setup/protobuf.sh,dst=/mnt/protobuf.sh cd /tmp/protobuf && /mnt/protobuf.sh && rm -rf /tmp/protobuf

FROM build_base AS go_builder
# Go setup
# TODO: Refactor this once we have multistage so that each architecture has its own intermediate image
ARG GO_VERSION
ARG GO_SHA256_LINUX_AMD64
ARG GO_SHA256_LINUX_ARM64
ARG MSGO_SHA256_LINUX_AMD64
ARG MSGO_SHA256_LINUX_ARM64
ARG MSGO_PATCH

# Re-export as env for use in LABEL steps in the final stage
ENV GO_VERSION=$GO_VERSION

ENV GOPATH=/go
ENV MS_GOTOOLCHAIN_TELEMETRY_ENABLED=0
RUN --mount=type=bind,src=./setup/go.sh,dst=/mnt/go.sh /mnt/go.sh
ENV PATH="${GOPATH}/bin:${PATH}"

FROM common_base AS bazelisk_builder
# Install & verify Bazelisk as Bazel bootstrapper
# TODO: Refactor this once we have multistage so that each architecture has its own intermediate image
RUN --mount=type=bind,src=./setup/bazelisk.sh,dst=/mnt/bazelisk.sh /mnt/bazelisk.sh

FROM common_base AS rust_builder
# Rust setup
# TODO: Maybe deprecate the rustup-init script and manually download and extract a tar.
ARG RUST_VERSION=1.91.0
ARG RUSTUP_VERSION=1.26.0
ARG RUSTUP_SHA256
# Re-export as env for use in LABEL steps in the final stage
ENV RUST_VERSION=$RUST_VERSION
ENV RUSTUP_VERSION=$RUSTUP_VERSION

ADD --checksum=sha256:${RUSTUP_SHA256} "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${ARCH}-unknown-linux-gnu/rustup-init" /tmp/rust/rustup-init
RUN --mount=type=bind,src=./setup/rust.sh,dst=/mnt/rust.sh cd /tmp/rust && /mnt/rust.sh && rm -rf /tmp/rust
ENV PATH="/root/.cargo/bin:${PATH}"

FROM extraction_base AS vault_builder
# Install vault & awscli
ARG VAULT_VERSION=1.17.2
ARG AWSCLI_VERSION=2.27.30
ARG VAULT_SHA256
ARG AWSCLI_SHA256
ARG VAULT_ARCH
ARG AWSCLI_ARCH
# Re-export as env for use in LABEL steps in the final stage
ENV VAULT_VERSION=$VAULT_VERSION
ENV AWSCLI_VERSION=$AWSCLI_VERSION
ENV VAULT_FILENAME="vault_${VAULT_VERSION}_linux_${VAULT_ARCH}.zip"

ADD --checksum=sha256:${VAULT_SHA256} "https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME}" /tmp/vault/vault.zip
ADD --checksum=sha256:${AWSCLI_SHA256} "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}-${AWSCLI_VERSION}.zip" /tmp/vault/awscliv2.zip
RUN --mount=type=bind,src=./setup/vault.sh,dst=/mnt/vault.sh cd /tmp/vault && /mnt/vault.sh && rm -rf /tmp/vault

FROM build_base AS pulumi_builder
# Install Pulumi
# TODO: Add logic to download the tarball directly instead of relying on this script
# It's sort of dumb to checksum and cache a script instead of the actual tarball we're interested in
ADD --checksum=sha256:1fe472a5915b416299df9a1b490e7e6d573d3c9f41c662ff4322a79bf4bf0550 https://get.pulumi.com/ /tmp/pulumi/get-pulumi.sh
ARG PULUMI_VERSION=3.207.0
RUN chmod +x /tmp/pulumi/get-pulumi.sh && /tmp/pulumi/get-pulumi.sh --version $PULUMI_VERSION && mv ~/.pulumi/bin/* /usr/local/bin

FROM common_base AS datadog_ci_builder
# Install CI uploader
ARG DATADOG_CI_VERSION=3.9.0
ARG DATADOG_CI_SHA256
ARG DATADOG_CI_ARCH

# Re-export as env for use in LABEL steps in the final stage
ENV DATADOG_CI_VERSION=$DATADOG_CI_VERSION

ADD --checksum=sha256:${DATADOG_CI_SHA256} "https://github.com/DataDog/datadog-ci/releases/download/v${DATADOG_CI_VERSION}/datadog-ci_linux-${DATADOG_CI_ARCH}" /usr/local/bin/datadog-ci
RUN chmod +x /usr/local/bin/datadog-ci

FROM extraction_base AS authanywhere_builder
# Install authanywhere for infra token management
ADD --checksum=sha256:05d14b25e4607cc9e14867f2a0f38774869ae609eec890168e57de9a1b428e37 "https://binaries.ddbuild.io/dd-source/authanywhere/v0.0.2/authanywhere-tar.tar.gz" /tmp/authanywhere/authanywhere-tar.tar.gz
RUN --mount=type=bind,src=./setup/authanywhere.sh,dst=/mnt/authanywhere.sh /mnt/authanywhere.sh

FROM go_builder AS datadog_packages_builder
# Install datadog-packages
ENV GOPATH=/go
ENV PATH="${GOPATH}/bin:/usr/local/go/bin:${PATH}"
RUN --mount=type=secret,id=ci-job-token,env=CI_JOB_TOKEN --mount=type=bind,src=./setup/datadog_packages.sh,dst=/mnt/datadog_packages.sh /mnt/datadog_packages.sh


FROM common_base AS final

ARG ADDITIONAL_PACKAGE
# Install extra runtime dependencies needed by the CI
# These are the packages actually used when building datadog-agent, not for building the tools in this Dockerfile\
# TODO: See if we can remove some of these, we currently reinstall everything that was present before #997
RUN apt-get update -qy && apt-get install -y --no-install-recommends \
    autoconf autopoint \
    bison build-essential \
    bzip2 \
    clang clang-format cmake cpio curl \
    fakeroot file flex \
    gawk gettext git gnupg2 gpg \
    help2man \
    yq \
    libcurl4-openssl-dev libexpat1-dev libgdbm-dev libgmp-dev libncurses-dev \
    libpq-dev libreadline-dev libseccomp-dev libsqlite3-dev libssl-dev \
    libsystemd-dev libtool-bin libyaml-dev linux-headers-generic \
    meson \
    patchelf pkg-config python-is-python3 \
    rpm \
    selinux-basics shellcheck sqlite3 squashfs-tools \
    texinfo \
    unzip \
    wget \
    xsltproc \
    xz-utils \
    zlib1g-dev \
    ${ADDITIONAL_PACKAGE} \
    && rm -rf /var/lib/apt/lists/*

# Install Google Cloud SDK
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt update -qy && \
    apt install -y google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin && \
    rm -rf /var/lib/apt/lists/*

# Git configuration
RUN git config --global user.email "package@datadoghq.com" && \
    git config --global user.name "Bits"

# Copy built tools
# NOTE: We try to copy the least-often-used tools first to reduce the likelihood of cache misses

# Protobuf
COPY --from=protobuf_builder /usr/bin/protoc /usr/bin/protoc
COPY --from=protobuf_builder /usr/include/google /usr/include/google
LABEL protobuf_version="${PROTOBUF_VERSION}"

# Texinfo
COPY --from=texinfo_builder /usr/local /usr/local

# Vault
COPY --from=vault_builder /usr/bin/vault /usr/bin/vault
COPY --from=vault_builder /usr/local/bin/aws* /usr/local/bin/
COPY --from=vault_builder /usr/local/aws* /usr/local/
LABEL vault_version="${VAULT_VERSION}"
LABEL awscli_version="${AWSCLI_VERSION}"


# Authanywhere
COPY --from=authanywhere_builder /usr/local/bin/authanywhere /usr/local/bin/authanywhere

# Pulumi
COPY --from=pulumi_builder /usr/local/bin/pulumi /usr/local/bin/pulumi
LABEL pulumi_version="${PULUMI_VERSION}"

# Install dd-octo-sts
COPY --from=registry.ddbuild.io/dd-octo-sts:v1.9.3 /usr/local/bin/dd-octo-sts /usr/local/bin/dd-octo-sts

# Datadog packages
COPY --from=datadog_packages_builder /go/bin/datadog-package /go/bin/datadog-package

# RVM
COPY --from=rvm_builder /usr/local/rvm /usr/local/rvm
LABEL rvm_version="${RVM_VERSION}"
LABEL bundler_version="${BUNDLER_VERSION}"

# Rust
COPY --from=rust_builder /root/.cargo /root/.cargo
LABEL rust_version="${RUST_VERSION}"
LABEL rustup_version="${RUSTUP_VERSION}"

# Datadog CI
COPY --from=datadog_ci_builder /usr/local/bin/datadog-ci /usr/local/bin/datadog-ci
LABEL datadog_ci_version="${DATADOG_CI_VERSION}"


# Crosstool-ng
COPY --from=crosstool_ng_builder /opt/toolchains /opt/toolchains
COPY --from=crosstool_ng_builder /opt/cmake /opt/cmake
# Takes values from the ENV steps in the builder stage
LABEL glibc_version="${GLIBC_VERSION}"
LABEL ctng_version="${CTNG_VERSION}"

# Dpkg-armhf
COPY --from=dpkg_armhf_builder /opt/dpkg-armhf /opt/dpkg-armhf
LABEL dpkg_armhf_version="${DPKG_ARMHF_VERSION}"

# Bazelisk
COPY --from=bazelisk_builder /usr/bin/bazel* /usr/bin/

# Go
COPY --from=go_builder /usr/local/go /usr/local/go
LABEL go_version="${GO_VERSION}"

# Conda & Python
COPY --from=python_builder ${CONDA_PATH} ${CONDA_PATH}
LABEL dda_version="${DDA_VERSION}"
# Copy conda's bash initialization
COPY --from=python_builder /root/.bashrc /root/.bashrc.conda

# Set up missing environment variables
ENV GOPATH=/go
ENV PYTHONUTF8=1

# Merge conda initialization with main bashrc
RUN cat /root/.bashrc.conda >> /root/.bashrc && rm /root/.bashrc.conda

RUN echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc

# Common environment setup
# Git configuration
RUN git config --global user.email "package@datadoghq.com" && \
    git config --global user.name "Bits"

RUN echo "umask 0022" >> /root/.bashrc && \
    mkdir -p /go/src/github.com/DataDog/datadog-agent

# Set up environment
ENV PATH="${CONDA_PATH}/condabin:${GOPATH}/bin:/root/.cargo/bin:/usr/local/go/bin:/opt/toolchains/${ARCH}/bin:/opt/toolchains/${CROSS_ARCH}/bin:${PATH}"

# Ensure pkg-config will not look into the system directories
ENV PKG_CONFIG_LIBDIR=""

# Set the version of the Rust toolchain to use by default
ARG RUST_VERSION
RUN /root/.cargo/bin/rustup default ${RUST_VERSION}

LABEL maintainer="DataDog"
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
