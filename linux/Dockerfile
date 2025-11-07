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
ARG PULUMI_VERSION

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
    wget xz-utils gpg build-essential flex texinfo unzip \
    help2man file gawk libtool-bin bison libncurses-dev \
    python-is-python3 git cmake curl fakeroot procps bzip2 \
    pkg-config libssl-dev libcurl4-openssl-dev libexpat-dev libpq-dev libz-dev \
    rpm tar gettext autopoint autoconf clang libtool-bin \
    pkg-config flex meson selinux-basics squashfs-tools gpg xz-utils gnupg2 patchelf cpio \
    linux-headers-generic jq libsystemd-dev clang-format libseccomp-dev shellcheck \
    ${ADDITIONAL_PACKAGE}

# Git configuration
RUN git config --global user.email "package@datadoghq.com" && \
    git config --global user.name "Bits"

# Copy architecture-specific configuration files
COPY linux/${DATADOG_CI_ARCH}/config-${ARCH}-unknown-gnu-linux-glibc${GLIBC_VERSION} /build/crosstool-ng-${CTNG_VERSION}/.config
COPY linux/${DATADOG_CI_ARCH}/config-${CROSS_ARCH}-unknown-gnu-linux-glibc${CROSS_GLIBC_VERSION} /build/crosstool-ng-${CTNG_VERSION}/.config-${CROSS_ARCH}
COPY linux/${DATADOG_CI_ARCH}/toolchain_${ARCH}.cmake /opt/cmake/${ARCH}-unknown-linux-gnu.toolchain.cmake
COPY linux/${DATADOG_CI_ARCH}/cargo-config.toml /root/.cargo/config.toml
COPY linux/ctng.patch /root/ctng.patch

# Build texinfo to get a bugfix version
RUN cd /build && \
    git clone https://gnu.googlesource.com/texinfo && \
    cd texinfo && \
    git reset --hard 60d3edc4b74b4e1e5ef55e53de394d3b65506c47 && \
    ./autogen.sh && \
    ./configure && make -j$(ncproc) && make install && \
    rm -rf /build/texinfo

# Build cross-compilation toolchain
RUN cd /build && \
    wget https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/crosstool-ng-${CTNG_VERSION}.tar.xz && \
    gpg --keyserver keyserver.ubuntu.com --recv-keys 1F30EF2E && \
    wget https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/crosstool-ng-${CTNG_VERSION}.tar.xz.sig && \
    gpg --verify crosstool-ng-${CTNG_VERSION}.tar.xz.sig && \
    tar xf crosstool-ng-${CTNG_VERSION}.tar.xz && \
    cd /build/crosstool-ng-${CTNG_VERSION} && \
    patch -p1 < /root/ctng.patch && \
    ./configure --enable-local && make -j$(nproc) && \
    export CT_ALLOW_BUILD_AS_ROOT_SURE=yes && \
    ./ct-ng upgradeconfig && \
    ./ct-ng build && \
    mkdir -p /opt/toolchains/ && \
    mv /root/x-tools/${ARCH}-unknown-linux-gnu/ /opt/toolchains/${ARCH} && \
    mv .config-${CROSS_ARCH} .config && \
    ./ct-ng upgradeconfig && \
    ./ct-ng build && \
    mv /root/x-tools/${CROSS_ARCH}-unknown-linux-gnu/ /opt/toolchains/${CROSS_ARCH} && \
    rm -rf /build

RUN curl -LO "https://salsa.debian.org/dpkg-team/dpkg/-/archive/${DPKG_ARMHF_VERSION}/dpkg-${DPKG_ARMHF_VERSION}.tar.bz2" && \
    echo "${DPKG_ARMHF_SHA256}  dpkg-${DPKG_ARMHF_VERSION}.tar.bz2" | sha256sum --check && \
    tar -xf "dpkg-${DPKG_ARMHF_VERSION}.tar.bz2" && \
    cd "dpkg-${DPKG_ARMHF_VERSION}" && \
    echo "${DPKG_ARMHF_VERSION}" > .dist-version && \
    autoreconf -vfi && \
    mkdir build && cd build && \
    export DPKG_PREFIX=/opt/dpkg-armhf && \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
    ../configure \
      --host=arm-linux-gnueabihf \
      --build=arm-linux-gnueabihf \
      --program-suffix=-armhf \
      --prefix="${DPKG_PREFIX}" \
      --sysconfdir="${DPKG_PREFIX}/etc" \
      --localstatedir="${DPKG_PREFIX}/var" \
      --disable-nls \
      --disable-dselect && \
    make -j"$(nproc)" && \
    make install && \
    mkdir -p "${DPKG_PREFIX}/var/lib/dpkg" "${DPKG_PREFIX}/var/cache/dpkg" && \
    install -m 0755 /dev/stdin "${DPKG_PREFIX}/bin/dpkg" <<EOF
#!/bin/sh
exec "${DPKG_PREFIX}/bin/dpkg-armhf" \\
    --admindir="${DPKG_PREFIX}/var/lib/dpkg" \\
    --instdir="${DPKG_PREFIX}" \\
    "\$@"
EOF

# CONDA setup
ENV DDA_VERSION=$DDA_VERSION
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS
RUN --mount=type=bind,dst=/mnt /mnt/setup/python.sh
ENV PATH="${CONDA_PATH}/condabin:${PATH}"

# RVM setup
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/* && \
    rm -rf /gpg-keys && \
    curl -sSL -o get-rvm.sh https://raw.githubusercontent.com/rvm/rvm/1.29.12/binscripts/rvm-installer && \
    echo "fea24461e98d41528d6e28684aa4c216dbe903869bc3fcdb3493b6518fae2e7e  get-rvm.sh" | sha256sum --check && \
    bash get-rvm.sh stable --version 1.29.12 && \
    echo "d2de0b610ee321489e5c673fe749e13be8fb34c0aa08a74446d87f95a17de730  /usr/local/rvm/bin/rvm" | sha256sum --check && \
    rm get-rvm.sh
RUN /bin/bash -l -c "rvm requirements" && \
    /bin/bash -l -c "rvm install 2.7 --with-openssl-dir=${CONDA_PATH} && rvm cleanup all" && \
    /bin/bash -l -c "gem install bundler --version $BUNDLER_VERSION --no-document" && \
    echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc

# Protobuf
RUN curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/${PROTOBUF_FILENAME} \
    && echo "${PROTOBUF_SHA256}  ${PROTOBUF_FILENAME}" | sha256sum --check \
    && unzip -o ${PROTOBUF_FILENAME} -d protoc3 \
    && mv protoc3/bin/* /usr/bin/ \
    && mv protoc3/include/* /usr/include/ \
    && rm -rf protoc3 \
    && rm ${PROTOBUF_FILENAME}

# Go setup
ENV GOPATH=/go
RUN --mount=type=bind,dst=/mnt /mnt/setup/go.sh
ENV PATH="${GOPATH}/bin:${PATH}"

# Install & verify Bazelisk as Bazel bootstrapper
RUN --mount=type=bind,dst=/mnt /mnt/setup/bazelisk.sh

# Rust setup
RUN curl -sSL -o rustup-init https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${ARCH}-unknown-linux-gnu/rustup-init && \
    echo "${RUSTUP_SHA256}  rustup-init" | sha256sum --check && \
    chmod +x ./rustup-init && \
    ./rustup-init -y --profile minimal --default-toolchain ${RUST_VERSION} && \
    echo "${RUSTUP_SHA256}  /root/.cargo/bin/rustc" | sha256sum --check && \
    rm ./rustup-init
ENV PATH="/root/.cargo/bin:${PATH}"

# Install vault
RUN curl -LO https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME} && \
    echo "${VAULT_SHA256} ${VAULT_FILENAME}" | sha256sum --check && \
    unzip -o ${VAULT_FILENAME} -d /usr/bin vault && \
    rm ${VAULT_FILENAME} && \
    # AWS v2 cli
    curl --retry 10 -fsSLo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}-${AWSCLI_VERSION}.zip && \
    echo "${AWSCLI_SHA256} awscliv2.zip" | sha256sum --check && \
    unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Install Pulumi
RUN curl --retry 10 -fsSL https://get.pulumi.com/ | bash -s -- --version $PULUMI_VERSION && \
    mv ~/.pulumi/bin/* /usr/bin

# Install dd-octo-sts
COPY --from=registry.ddbuild.io/dd-octo-sts:v1.9.3 /usr/local/bin/dd-octo-sts /usr/local/bin/dd-octo-sts


# Install CI uploader
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${DATADOG_CI_VERSION}/datadog-ci_linux-${DATADOG_CI_ARCH} --output "/usr/local/bin/datadog-ci" && \
    echo "${DATADOG_CI_SHA256} /usr/local/bin/datadog-ci" | sha256sum --check && \
    chmod +x /usr/local/bin/datadog-ci

# Install authanywhere for infra token management
RUN --mount=type=bind,dst=/mnt /mnt/setup/authanywhere.sh


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
