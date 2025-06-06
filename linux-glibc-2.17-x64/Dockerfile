FROM ubuntu:24.04 AS base

# Build Args - common arguments used across stages
ARG GO_VERSION
ARG GO_SHA256_LINUX_AMD64
ARG MSGO_SHA256_LINUX_AMD64
ARG MSGO_PATCH
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS=1
ARG CTNG_VERSION=1.26.0
ARG IBM_MQ_VERSION=9.2.4.0
ARG IBM_MQ_SHA256="d0d583eba72daf20b3762976f8831c2e23150ace90509520e12f8cda5b5bdb49"
ARG RUST_VERSION=1.76.0
ARG RUSTC_SHA256="0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db"
ARG RUSTUP_VERSION=1.26.0
ARG RUSTUP_SHA256="0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db"
ARG BUNDLER_VERSION=2.4.20
ARG DD_TARGET_ARCH
ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=a0c0449e640c8be5dcf7b7b093d5884f6a85406dbb86bbad0ea06becad5aaab8
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_amd64.zip"
ARG CI_UPLOADER_VERSION=2.38.1
ARG CI_UPLOADER_SHA=4e56d449e6396ae4c7356f07fc5372a28999aacb012d4343a3b8a9389123aa38
ARG PROTOBUF_VERSION=29.3
ARG PROTOBUF_FILENAME="protoc-${PROTOBUF_VERSION}-linux-x86_64.zip"
ARG PROTOBUF_CHECKSUM=3e866620c5be27664f3d2fa2d656b5f3e09b5152b42f1bedbf427b333e90021a

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
    linux-headers-generic libc6-dev-i386 jq libsystemd-dev clang-format \
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
COPY linux-glibc-2.17-x64/config-x86_64-unknown-gnu-linux-glibc2.17 /build/crosstool-ng-${CTNG_VERSION}/.config
COPY linux-glibc-2.17-x64/config-aarch64-unknown-gnu-linux-glibc2.23 /build/crosstool-ng-${CTNG_VERSION}/.config-aarch64
COPY linux-glibc-2.17-x64/ctng.patch /root/ctng.patch

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
    ./ct-ng upgradeconfig && \
    ./ct-ng build && \
    mkdir -p /opt/toolchains/ && \
    mv /root/x-tools/x86_64-unknown-linux-gnu/ /opt/toolchains/x86_64 && \
    mv .config-aarch64 .config && \
    ./ct-ng upgradeconfig && \
    ./ct-ng build && \
    mv /root/x-tools/aarch64-unknown-linux-gnu/ /opt/toolchains/aarch64

# FROM base as ibm-mq-builder
FROM base as ibm-mq-builder
ARG IBM_MQ_VERSION
ARG IBM_MQ_SHA256
RUN mkdir -p /opt/mqm \
    && curl "https://s3.amazonaws.com/dd-agent-omnibus/ibm-mq-backup/${IBM_MQ_VERSION}-IBM-MQC-Redist-LinuxX64.tar.gz" -o /tmp/mq_client.tar.gz \
    && echo "${IBM_MQ_SHA256}  /tmp/mq_client.tar.gz" | sha256sum --check \
    && tar -C /opt/mqm -xf /tmp/mq_client.tar.gz \
    && rm -rf /tmp/mq_client.tar.gz

# Final image with all components
FROM base

# Copy built components from previous stages
COPY --from=crosstool-builder /opt/toolchains /opt/toolchains
COPY --from=ibm-mq-builder /opt/mqm /opt/mqm

# Copy configuration files
COPY linux-glibc-2.17-x64/toolchain_x86-64.cmake /opt/cmake/x86_64-unknown-linux-gnu.toolchain.cmake
COPY linux-glibc-2.17-x64/cargo-config.toml ${HOME}/.cargo/config.toml

# Set environment variables for the toolchain
ENV DD_CC_PATH="/opt/toolchains/x86_64/bin/x86_64-unknown-linux-gnu-gcc"
ENV DD_CXX_PATH="/opt/toolchains/x86_64/bin/x86_64-unknown-linux-gnu-g++"
ENV DD_CMAKE_TOOLCHAIN_PATH="/opt/cmake/x86_64-unknown-linux-gnu.toolchain.cmake"
ENV PATH=/opt/toolchains/x86_64/bin:/opt/toolchains/aarch64/bin:$PATH
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

# Protobuf installation in a single layer
ARG PROTOBUF_VERSION
ARG PROTOBUF_FILENAME
ARG PROTOBUF_CHECKSUM
RUN curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/${PROTOBUF_FILENAME} \
    && echo "${PROTOBUF_CHECKSUM}  ${PROTOBUF_FILENAME}" | sha256sum --check \
    && unzip -o ${PROTOBUF_FILENAME} -d protoc3 \
    && mv protoc3/bin/* /usr/bin/ \
    && mv protoc3/include/* /usr/include/ \
    && rm -rf protoc3 \
    && rm ${PROTOBUF_FILENAME}

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
RUN curl -sSL -o rustup-init https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init \
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
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${CI_UPLOADER_VERSION}/datadog-ci_linux-x64 --output "/usr/local/bin/datadog-ci" && \
    echo "${CI_UPLOADER_SHA} /usr/local/bin/datadog-ci" | sha256sum --check && \
    chmod +x /usr/local/bin/datadog-ci

# Final setup
RUN echo "umask 0022" >> /root/.bashrc \
    && mkdir -p /go/src/github.com/DataDog/datadog-agent

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
