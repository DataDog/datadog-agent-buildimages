ARG BASE_IMAGE=ubuntu:noble-20251013

# Specify dd-octo-sts version in root scope as it is used in a stage definition (FROM instruction)
ARG DD_OCTO_STS_VERSION=latest
ARG DATADOG_PACKAGES_VERSION

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
RUN --mount=type=bind,src=./linux/scripts/texinfo.sh,dst=/mnt/texinfo.sh cd /tmp/texinfo && /mnt/texinfo.sh

FROM texinfo_builder AS crosstool_ng_builder
# CTNG depends on texinfo
# Build cross-compilation toolchain

# Install crosstool-ng specific dependencies (not included in build_base)
RUN apt-get install -y --no-install-recommends \
    gperf libncurses5-dev rsync ninja-build

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
RUN --mount=type=bind,src=./linux/scripts/ctng.sh,dst=/mnt/ctng.sh cd /tmp/crosstool-ng && /mnt/ctng.sh && rm -rf /tmp/crosstool-ng

FROM build_base AS dpkg_armhf_builder
# Build dpkg-armhf
ARG DPKG_ARMHF_VERSION
ARG DPKG_ARMHF_SHA256

# Install dpkg-specific build dependencies
RUN apt-get install -y --no-install-recommends \
    libmd-dev libbz2-dev liblzma-dev

ADD --checksum=sha256:${DPKG_ARMHF_SHA256} "https://salsa.debian.org/dpkg-team/dpkg/-/archive/${DPKG_ARMHF_VERSION}/dpkg-${DPKG_ARMHF_VERSION}.tar.bz2" \
    /tmp/dpkg-armhf/
RUN --mount=type=bind,src=./linux/scripts/dpkg.sh,dst=/mnt/dpkg.sh cd /tmp/dpkg-armhf && /mnt/dpkg.sh && rm -rf /tmp/dpkg-armhf

FROM build_base AS python_builder
# Python and Conda setup

ARG PY3_VERSION
ARG CONDA_VERSION
ARG CONDA_SHA256
ARG CONDA_ARCH

# Common environment variables
ENV PYTHONUTF8=1
ARG DD_BUILD_INSTALL_ROOT
ENV CONDA_PATH="${DD_BUILD_INSTALL_ROOT}/miniforge3"
ARG DD_PIP_VERSION_PY3
ARG DD_SETUPTOOLS_VERSION_PY3
ARG DD_UV_VERSION
ENV DD_PIP_VERSION_PY3=$DD_PIP_VERSION_PY3
ENV DD_SETUPTOOLS_VERSION_PY3=$DD_SETUPTOOLS_VERSION_PY3
ENV DD_UV_VERSION=$DD_UV_VERSION
ENV PATH="${CONDA_PATH}/condabin:${PATH}"

ADD --checksum=sha256:${CONDA_SHA256} "https://github.com/conda-forge/miniforge/releases/download/${CONDA_VERSION}/Miniforge3-Linux-${CONDA_ARCH}.sh" /tmp/conda/miniconda.sh

# Remove early return in .bashrc when running in non-interactive shell
# This is needed for `conda init bash` to work properly
RUN grep -v return /root/.bashrc >> /root/newbashrc && cp /root/newbashrc /root/.bashrc

RUN --mount=type=bind,src=./linux/scripts/python.sh,dst=/mnt/python.sh \
    --mount=type=bind,src=./python-packages-versions.txt,dst=/mnt/python-packages-versions.txt \
    cd /tmp/conda && /mnt/python.sh && rm -rf /tmp/conda

ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS=1
ADD https://github.com/DataDog/datadog-agent-dev.git#${DDA_VERSION} /tmp/dda
RUN --mount=type=bind,src=./linux/scripts/dda.sh,dst=/mnt/dda.sh cd /tmp/dda && /mnt/dda.sh && rm -rf /tmp/dda

FROM python_builder AS rvm_builder
# Somehow building RVM needs some OpenSSL stuff from the python_builder stage

ARG RVM_VERSION
ARG BUNDLER_VERSION
ARG RVM_SHA256
ARG DD_BUILD_INSTALL_ROOT
ARG DD_BUILD_CACHE_ROOT
ENV RVM_PATH="${DD_BUILD_INSTALL_ROOT}/rvm"
ENV RUBY_GEM_CACHE_DIR="${DD_BUILD_CACHE_ROOT}/ruby/gems"
ENV BUNDLER_VERSION=$BUNDLER_VERSION

ADD --checksum=sha256:${RVM_SHA256} \
    "https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION}/binscripts/rvm-installer" \
    /tmp/rvm/get-rvm.sh
COPY ./rvm/gpg-keys /gpg-keys
# TODO: Maybe deprecate the get-rvm.sh script and manually download and extract a tar.
# The script we download does a lot of extra checking that we don't need in a Docker build.
RUN --mount=type=bind,src=./linux/scripts/rvm.sh,dst=/mnt/rvm.sh cd /tmp/rvm && /mnt/rvm.sh && rm -rf /tmp/rvm

FROM extraction_base AS protobuf_builder
# Protobuf
ARG PROTOBUF_VERSION
ARG PROTOBUF_SHA256
ARG PROTOBUF_ARCH
ENV PROTOBUF_FILENAME="protoc-${PROTOBUF_VERSION}-linux-${PROTOBUF_ARCH}.zip"

ADD --checksum=sha256:${PROTOBUF_SHA256} "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/${PROTOBUF_FILENAME}" /tmp/protobuf/${PROTOBUF_FILENAME}
RUN --mount=type=bind,src=./linux/scripts/protobuf.sh,dst=/mnt/protobuf.sh cd /tmp/protobuf && /mnt/protobuf.sh && rm -rf /tmp/protobuf

FROM build_base AS go_builder
# Go setup
ARG GO_VERSION
ARG GO_SHA256
ARG MSGO_SHA256
ARG GO_ARCH
ARG MSGO_PATCH

ENV GOPATH=/go
ENV MS_GOTOOLCHAIN_TELEMETRY_ENABLED=0

ADD https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz /tmp/go/go.tar.gz
ADD https://aka.ms/golang/release/latest/go${GO_VERSION}-${MSGO_PATCH}.linux-${GO_ARCH}.tar.gz /tmp/go/msgo.tar.gz
RUN --mount=type=bind,src=./linux/scripts/go.sh,dst=/mnt/go.sh cd /tmp/go && /mnt/go.sh && rm -rf /tmp/go
ENV PATH="${GOPATH}/bin:${PATH}"

FROM build_base AS rust_builder
# Rust setup
# TODO: Maybe deprecate the rustup-init script and manually download and extract a tar.
ARG RUST_VERSION
ARG RUSTUP_VERSION
ARG RUSTUP_SHA256
ARG RUSTUP_ARCH

ADD --checksum=sha256:${RUSTUP_SHA256} "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${RUSTUP_ARCH}-unknown-linux-gnu/rustup-init" /tmp/rust/rustup-init
RUN --mount=type=bind,src=./linux/scripts/rust.sh,dst=/mnt/rust.sh cd /tmp/rust && /mnt/rust.sh && rm -rf /tmp/rust
ENV PATH="/root/.cargo/bin:${PATH}"

FROM extraction_base AS vault_builder
# Install vault & awscli
ARG VAULT_VERSION
ARG AWSCLI_VERSION
ARG VAULT_SHA256
ARG AWSCLI_SHA256
ARG VAULT_ARCH
ARG AWSCLI_ARCH
ENV VAULT_FILENAME="vault_${VAULT_VERSION}_linux_${VAULT_ARCH}.zip"

ADD --checksum=sha256:${VAULT_SHA256} "https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME}" /tmp/vault/vault.zip
ADD --checksum=sha256:${AWSCLI_SHA256} "https://awscli.amazonaws.com/awscli-exe-linux-${AWSCLI_ARCH}-${AWSCLI_VERSION}.zip" /tmp/vault/awscliv2.zip
RUN --mount=type=bind,src=./linux/scripts/vault.sh,dst=/mnt/vault.sh cd /tmp/vault && /mnt/vault.sh && rm -rf /tmp/vault


FROM build_base AS pulumi_builder
# Install Pulumi
# TODO: Add logic to download the tarball directly instead of relying on this script
# It's sort of dumb to checksum and cache a script instead of the actual tarball we're interested in
ARG PULUMI_SHA256
ADD --checksum=sha256:${PULUMI_SHA256} https://get.pulumi.com/ /tmp/pulumi/get-pulumi.sh
ARG PULUMI_VERSION
RUN chmod +x /tmp/pulumi/get-pulumi.sh && /tmp/pulumi/get-pulumi.sh --version $PULUMI_VERSION && mv ~/.pulumi/bin/* /usr/local/bin

FROM common_base AS datadog_ci_builder
# Install CI uploader
ARG DATADOG_CI_VERSION
ARG DATADOG_CI_SHA256
ARG DATADOG_CI_ARCH

ADD --checksum=sha256:${DATADOG_CI_SHA256} "https://github.com/DataDog/datadog-ci/releases/download/v${DATADOG_CI_VERSION}/datadog-ci_linux-${DATADOG_CI_ARCH}" /usr/local/bin/datadog-ci
RUN chmod +x /usr/local/bin/datadog-ci

FROM extraction_base AS authanywhere_builder
# Install authanywhere for infra token management
ADD --checksum=sha256:05d14b25e4607cc9e14867f2a0f38774869ae609eec890168e57de9a1b428e37 "https://binaries.ddbuild.io/dd-source/authanywhere/v0.0.2/authanywhere-tar.tar.gz" /tmp/authanywhere/authanywhere-tar.tar.gz
RUN --mount=type=bind,src=./linux/scripts/authanywhere.sh,dst=/mnt/authanywhere.sh cd /tmp/authanywhere && /mnt/authanywhere.sh && rm -rf /tmp/authanywhere

FROM registry.ddbuild.io/dd-octo-sts:$DD_OCTO_STS_VERSION AS dd_octo_sts_builder
# Dummy stage to download dd-octo-sts as it is distributed as a container image

FROM registry.ddbuild.io/ci/datadog-packages/artifact:${DATADOG_PACKAGES_VERSION} AS datadog_packages_builder
# Dummy stage to download datadog-packages as it is distributed as a container image

FROM common_base AS final

# Shared root directories
ARG DD_REPO_ROOT
ARG DD_BUILD_INSTALL_ROOT
ARG DD_BUILD_CACHE_ROOT
ENV DD_REPO_ROOT=${DD_REPO_ROOT}
ENV DD_BUILD_INSTALL_ROOT=${DD_BUILD_INSTALL_ROOT}
ENV DD_BUILD_CACHE_ROOT=${DD_BUILD_CACHE_ROOT}
ENV XDG_CACHE_HOME="${DD_BUILD_CACHE_ROOT}"

# Tool-specific caches
ENV BAZELISK_HOME="${DD_BUILD_CACHE_ROOT}/bazelisk"
ENV GOPATH="${DD_BUILD_CACHE_ROOT}/go"
ENV CARGO_HOME="${DD_BUILD_CACHE_ROOT}/cargo"
ENV UV_CACHE_DIR="${DD_BUILD_CACHE_ROOT}/uv"
ENV PIP_CACHE_DIR="${DD_BUILD_CACHE_ROOT}/pip"
ENV OMNIBUS_CACHE_DIR="${DD_BUILD_CACHE_ROOT}/omnibus/cache"
ENV OMNIBUS_GIT_CACHE_DIR="${DD_BUILD_CACHE_ROOT}/omnibus/git-cache"
ENV BUNDLE_PATH="${DD_BUILD_CACHE_ROOT}/omnibus/bundle"

# Tool-specific installations
ENV DOTSLASH_CACHE="${DD_BUILD_INSTALL_ROOT}/dotslash"
ENV GOBIN="${DD_BUILD_INSTALL_ROOT}/go"
ENV RUSTUP_HOME="${DD_BUILD_INSTALL_ROOT}/rustup"
ENV CARGO_INSTALL_ROOT="${DD_BUILD_INSTALL_ROOT}/cargo"
ENV UV_TOOL_DIR="${DD_BUILD_INSTALL_ROOT}/uv/tools"
ENV UV_PYTHON_INSTALL_DIR="${DD_BUILD_INSTALL_ROOT}/uv/python"
ENV CONDA_PATH="${DD_BUILD_INSTALL_ROOT}/miniforge3"
ENV OMNIBUS_BASE_DIR="${DD_BUILD_INSTALL_ROOT}/omnibus"
ENV RVM_PATH="${DD_BUILD_INSTALL_ROOT}/rvm"

ARG ADDITIONAL_PACKAGE
# Install extra runtime dependencies needed by the CI
# These are the packages actually used when building datadog-agent, not for building the tools in this Dockerfile
# TODO: Explicitly install all packages needed by datadog-agent - currently we rely on some packages only installed as dependencies of other packages.
# In particular, adding `--no-install-recommends` to the apt-get install command will break the build, as we rely on some packages only installed as recommended dependencies of other packages.
# TODO: See if we can remove some of these, we currently reinstall everything that was present before #997
RUN apt-get update -qy && apt-get install -y \
    acl \
    automake autoconf autopoint \
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
    sudo \
    ${ADDITIONAL_PACKAGE} \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Install Google Cloud SDK
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt update -qy && \
    apt install -y google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin && \
    rm -rf /var/lib/apt/lists/*

# Allow members of the `sudo` group to run passwordless sudo
RUN echo '%sudo ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-sudo-nopass && \
    chmod 0440 /etc/sudoers.d/90-sudo-nopass

# Git configuration (system-wide so non-root users see it too)
RUN git config --system user.email "package@datadoghq.com" && \
    git config --system user.name "Bits"

# Group for shared writable build directories (must exist before COPY --chown)
RUN groupadd -g 9001 build-shared

# Ensure shared root directories exist with correct top-level ownership/permissions.
# We keep this non-recursive (fast) and rely on ACLs later for full-tree access.
RUN for dir in \
        "${DD_BUILD_INSTALL_ROOT}" \
        "${DD_BUILD_CACHE_ROOT}" \
        "${DD_REPO_ROOT}"; do \
        if [ -z "${dir}" ]; then \
            continue; \
        fi; \
        mkdir -p "${dir}"; \
        chown root:build-shared "${dir}"; \
        chmod g+rws,o+rx "${dir}"; \
    done

# Ensure that each prefix used by Omnibus is creatable/writable by
# members of build-shared for non-root builds.
RUN for prefix in \
        /opt/datadog-agent \
        /etc/opt/datadog-agent \
        /etc/datadog-agent \
        /etc/init \
        /etc/init.d \
        /lib/pkgconfig \
        /var/log/datadog; do \
        mkdir -p "${prefix}"; \
        chown root:build-shared "${prefix}"; \
        chmod g+rws,o+rx "${prefix}"; \
        setfacl -m g:build-shared:rwx,m:rwx "${prefix}"; \
        setfacl -d -m g:build-shared:rwx,m:rwx "${prefix}"; \
    done

# Omnibus finalize may also move some binaries into system locations (e.g. /usr/bin).
# Grant build-shared write access to the destination directory so non-root builds can
# rename/copy into it.
RUN setfacl -m g:build-shared:rwx,m:rwx /usr/bin

# Copy built tools
# NOTE: We try to copy the least-often-used tools first to reduce the likelihood of cache misses

# Protobuf
COPY --from=protobuf_builder /usr/bin/protoc /usr/bin/protoc
COPY --from=protobuf_builder /usr/include/google /usr/include/google

# Texinfo
COPY --from=texinfo_builder /usr/local /usr/local

# Vault
COPY --from=vault_builder /usr/bin/vault /usr/bin/vault
COPY --from=vault_builder /usr/local/aws-cli /usr/local/aws-cli
# The AWS executable is located in the aws-cli directory, and needs to be symlinked to /usr/local/bin/aws
# Simply copying it does not work because it will then have trouble finding some .so files it comes with.
RUN ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws &&  \
    ln -s /usr/local/aws-cli/v2/current/bin/aws_completer /usr/local/bin/aws_completer

# Authanywhere
COPY --from=authanywhere_builder /usr/local/bin/authanywhere /usr/local/bin/authanywhere

# Pulumi
COPY --from=pulumi_builder /usr/local/bin/pulumi* /usr/local/bin/

# dd-octo-sts
COPY --from=dd_octo_sts_builder /usr/local/bin/dd-octo-sts /usr/local/bin/dd-octo-sts

# Datadog packages
COPY --from=datadog_packages_builder /datadog-package /go/bin/datadog-package

# RVM
COPY --from=rvm_builder --chown=root:build-shared ${RVM_PATH} ${RVM_PATH}
COPY --from=rvm_builder --chown=root:build-shared /etc/rvmrc /etc/rvmrc
ENV BUNDLE_GLOBAL_GEM_CACHE="true"

# Rust
COPY --from=rust_builder --chown=root:build-shared /usr/local/cargo-bin ${CARGO_INSTALL_ROOT}/bin
COPY --from=rust_builder --chown=root:build-shared /root/.rustup ${RUSTUP_HOME}
COPY --from=rust_builder --chown=root:build-shared /root/.cargo ${CARGO_HOME}

# Datadog CI
COPY --from=datadog_ci_builder /usr/local/bin/datadog-ci /usr/local/bin/datadog-ci

# Crosstool-ng
COPY --from=crosstool_ng_builder /opt/toolchains /opt/toolchains
COPY --from=crosstool_ng_builder /opt/cmake /opt/cmake

# Dpkg-armhf
COPY --from=dpkg_armhf_builder /opt/dpkg-armhf /opt/dpkg-armhf

# Codecov uploader
# Nothing to do except download the file, so no need to declare a stage for it
ARG CODECOV_VERSION
ARG CODECOV_ARCH
ARG CODECOV_SHA256

ADD --chmod=755 --checksum=sha256:${CODECOV_SHA256} "https://uploader.codecov.io/v${CODECOV_VERSION}/${CODECOV_ARCH}/codecov" /usr/local/bin/codecov

# Bazelisk
# Nothing to do except download the file, so no need to declare a stage for it
ARG BAZELISK_VERSION
ARG BAZELISK_ARCH
ARG BAZELISK_SHA256

ADD --chmod=755 --checksum=sha256:${BAZELISK_SHA256} "https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-linux-${BAZELISK_ARCH}" /usr/local/bin/bazelisk
# Symlink bazelisk to bazel
RUN ln -s /usr/local/bin/bazelisk /usr/local/bin/bazel

# Verify Bazelisk properly bootstraps Bazel - this also preinstalls Bazel ${TEST_BAZEL_VERSION}
ARG TEST_BAZEL_VERSION
RUN readlink -f "$(command -v bazel)" | tee /dev/stderr | grep -Fqx /usr/local/bin/bazelisk
RUN umask 0002 && \
USE_BAZEL_VERSION=${TEST_BAZEL_VERSION} \
# TODO(incident-47542): Remove this once `releases.bazel.build` is back online
BAZELISK_BASE_URL=https://github.com/bazelbuild/bazel/releases/download \
bazel --version | tee /dev/stderr | grep -Fqx "bazel ${TEST_BAZEL_VERSION}"

# Go
COPY --from=go_builder /usr/local/go /usr/local/go
COPY --from=go_builder /usr/local/msgo /usr/local/msgo

# Conda & Python
COPY --from=python_builder --chown=root:build-shared ${CONDA_PATH} ${CONDA_PATH}
COPY --from=python_builder /root/.bashrc /root/.bashrc.conda

# Set up missing environment variables
ENV MS_GOTOOLCHAIN_TELEMETRY_ENABLED=0
ENV PYTHONUTF8=1
ENV DDA_NO_DYNAMIC_DEPS=1

# Merge conda initialization with main bashrc
RUN cat /root/.bashrc.conda >> /root/.bashrc && rm /root/.bashrc.conda

# Remove early return in .bashrc when running in non-interactive shell
# This is needed for `conda init bash` to work properly
RUN grep -v return /root/.bashrc >> /root/newbashrc && cp /root/newbashrc /root/.bashrc

RUN echo "source ${RVM_PATH}/scripts/rvm" >> /root/.bashrc

# Common environment setup
# TODO: Investigate whether the explicit setting of umask is still necessary as it was
#       introduced a very long time ago and has been copied around ever since. See:
#       https://github.com/DataDog/datadog-agent-buildimages/pull/11
RUN echo "umask 0022" >> /root/.bashrc

# TODO: Remove this to decouple runtime configuration from build configuration
RUN umask 0002 && mkdir -p "${DD_REPO_ROOT}/datadog-agent"

# Set up environment
ARG CTNG_ARCH
ARG CTNG_CROSS_ARCH
ENV PATH="${CONDA_PATH}/condabin:${GOPATH}/bin:${CARGO_INSTALL_ROOT}/bin:/usr/local/go/bin:/opt/toolchains/${CTNG_ARCH}/bin:/opt/toolchains/${CTNG_CROSS_ARCH}/bin:${PATH}"

# Ensure pkg-config will not look into the system directories
ENV PKG_CONFIG_LIBDIR=""

# Ensure shared roots are writable by members of build-shared.
# We apply both:
# - a single recursive access-ACL pass so all existing files/dirs are accessible/writable
#   by members of build-shared (fastest way to touch every inode once)
# - default ACLs + setgid on directories so future writes remain group-writable regardless
#   of the creating process umask
RUN for dir in \
        "${DD_BUILD_INSTALL_ROOT}" \
        "${DD_BUILD_CACHE_ROOT}" \
        "${DD_REPO_ROOT}"; do \
        # Guard against empty args (would otherwise target the current directory).
        if [ -z "${dir}" ]; then \
            continue; \
        fi; \
        # Make sure the root exists and is owned by root:build-shared (non-recursive).
        mkdir -p "${dir}"; \
        chown root:build-shared "${dir}"; \
        chmod g+rws,o+rx "${dir}"; \
        \
        # Single recursive pass over all existing entries.
        if [ -n "$(find "${dir}" -mindepth 1 -print -quit 2>/dev/null)" ]; then \
            if [ "${dir}" = "${DD_BUILD_INSTALL_ROOT}" ]; then \
                # Conda is huge; avoid recursively ACL'ing it.
                # Apply the access ACL to everything else under the install root in one pass.
                find "${dir}" \( -path "${CONDA_PATH}" -o -path "${CONDA_PATH}/*" \) -prune -o \
                    -exec setfacl -m g:build-shared:rwX,m:rwX {} +; \
            else \
                setfacl -R -m g:build-shared:rwX,m:rwX "${dir}"; \
            fi; \
        fi; \
        \
        # Directory-only pass for defaults and group inheritance (much cheaper than full recursion).
        if [ "${dir}" = "${DD_BUILD_INSTALL_ROOT}" ]; then \
            find "${dir}" \( -path "${CONDA_PATH}" -o -path "${CONDA_PATH}/*" \) -prune -o \
                -type d -exec sh -c '\
                    chmod g+s "$@" && \
                    setfacl -d -m g:build-shared:rwx,m:rwx "$@" \
                ' sh {} +; \
        else \
            find "${dir}" -type d -exec sh -c '\
                chmod g+s "$@" && \
                setfacl -d -m g:build-shared:rwx,m:rwx "$@" \
            ' sh {} +; \
        fi; \
    done

# Default non-root user for CI and interactive use.
# 1000 is the default UID for the first user on Debian-based systems.
RUN useradd -m -u 1001 -g build-shared -G sudo -s /bin/bash dd-build && \
    cp /root/.bashrc /home/dd-build/.bashrc && \
    chown dd-build:build-shared /home/dd-build/.bashrc

# Label the image
ARG PROTOBUF_VERSION
ARG VAULT_VERSION
ARG AWSCLI_VERSION
ARG RVM_VERSION
ARG BUNDLER_VERSION
ARG RUST_VERSION
ARG RUSTUP_VERSION
ARG DATADOG_CI_VERSION
ARG GLIBC_VERSION
ARG CTNG_VERSION
ARG DPKG_ARMHF_VERSION
ARG GO_VERSION
ARG DDA_VERSION
ARG DATADOG_PACKAGES_VERSION
ARG PULUMI_VERSION
ARG DD_OCTO_STS_VERSION

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

# USER dd-build
# WORKDIR /home/dd-build

ENTRYPOINT ["/entrypoint.sh"]
