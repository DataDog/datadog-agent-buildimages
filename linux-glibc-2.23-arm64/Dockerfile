FROM ubuntu:24.04

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
ARG DATADOG_CI_VERSION=3.9.0
ARG DATADOG_CI_SHA=abb2ef649b3407496fbcf9b634a4b1dbe5f6d5141e273d7fdf272a3e4bc3de4d

ENV PYTHONUTF8 1
ENV CONDA_PATH /root/miniforge3

# Remove the early return on non-interactive shells, which makes sourcing the file not activate conda
RUN grep -v return /root/.bashrc >> /root/newbashrc && cp /root/newbashrc /root/.bashrc

RUN apt update -qy && apt install -y \
    wget xz-utils gpg build-essential flex texinfo unzip \
    help2man file gawk libtool-bin bison libncurses-dev \
    python-is-python3 git cmake curl fakeroot procps bzip2 \
    pkg-config libssl-dev libcurl4-openssl-dev libexpat-dev libpq-dev libz-dev \
    rpm tar gettext autopoint autoconf clang libtool-bin \
    pkg-config flex meson selinux-basics squashfs-tools gpg xz-utils gnupg2 patchelf cpio \
    linux-headers-generic jq libsystemd-dev clang-format

COPY linux-glibc-2.23-arm64/config-aarch64-unknown-gnu-linux-glibc2.23 /build/crosstool-ng-${CTNG_VERSION}/.config
COPY linux-glibc-2.23-arm64/config-x86_64-unknown-gnu-linux-glibc2.17 /build/crosstool-ng-${CTNG_VERSION}/.config-x86
COPY linux-glibc-2.23-arm64/toolchain_aarch64.cmake /opt/cmake/aarch64-unknown-linux-gnu.toolchain.cmake
COPY linux-glibc-2.23-arm64/cargo-config.toml ${HOME}/.cargo/config.toml
COPY linux-glibc-2.23-arm64/ctng.patch /root/ctng.patch

RUN git config --global user.email "package@datadoghq.com"
RUN git config --global user.name "Bits"

# Build texinfo to get a bugfix version
# Otherwise generating glibc doc with a recent version
# causes a segfault. The fix isn't yet released as a package
# https://git.savannah.gnu.org/cgit/texinfo.git/commit/?id=60d3edc4b74b4e1e5ef55e53de394d3b65506c47
RUN cd /build && \
    git clone https://gnu.googlesource.com/texinfo && \
    cd texinfo && \
    git reset --hard 60d3edc4b74b4e1e5ef55e53de394d3b65506c47 && \
    ./autogen.sh && \
    ./configure && make -j$(ncproc) && make install && \
    rm -rf /build/texinfo

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
    mv /root/x-tools/x86_64-unknown-linux-gnu/ /opt/toolchains/x86_64 && \
    rm -rf /build


# CONDA
COPY python-packages-versions.txt setup_python.sh /
ENV DDA_VERSION=$DDA_VERSION
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS
RUN ./setup_python.sh
ENV PATH "${CONDA_PATH}/condabin:${PATH}"

# RVM
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/*
RUN rm -rf /gpg-keys
RUN curl -sSL -o get-rvm.sh https://raw.githubusercontent.com/rvm/rvm/1.29.12/binscripts/rvm-installer \
    && echo "fea24461e98d41528d6e28684aa4c216dbe903869bc3fcdb3493b6518fae2e7e  get-rvm.sh" | sha256sum --check \
    && bash get-rvm.sh stable --version 1.29.12 \
    && echo "d2de0b610ee321489e5c673fe749e13be8fb34c0aa08a74446d87f95a17de730  /usr/local/rvm/bin/rvm" | sha256sum --check \
    && rm get-rvm.sh
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.7 --with-openssl-dir=${CONDA_PATH} && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --version $BUNDLER_VERSION --no-document"
RUN echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc

# Go
ENV GOPATH=/go
COPY setup_go.sh /
RUN ./setup_go.sh
ENV PATH="${GOPATH}/bin:${PATH}"

# Rust is needed to compile the SDS library
RUN curl -sSL -o rustup-init https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/aarch64-unknown-linux-gnu/rustup-init \
    && echo "${RUSTUP_SHA256}  rustup-init" | sha256sum --check \
    && chmod +x ./rustup-init \
    && ./rustup-init -y --profile minimal --default-toolchain ${RUST_VERSION} \
    && echo "${RUSTC_SHA256}  $HOME/.cargo/bin/rustc" | sha256sum --check \
    && rm ./rustup-init
ENV PATH "${HOME}/.cargo/bin:${PATH}"

# Install vault: https://github.com/hashicorp/vault/blob/main/CHANGELOG.md https://releases.hashicorp.com/vault
RUN curl -LO https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME} && \
  echo "${VAULT_CHECKSUM} ${VAULT_FILENAME}" | sha256sum --check && \
  unzip -o ${VAULT_FILENAME} -d /usr/bin vault && \
  rm ${VAULT_FILENAME}

# CI uploader, to send junit to ci-visibility during CI tests
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${CI_UPLOADER_VERSION}/datadog-ci_linux-arm64 --output "/usr/local/bin/datadog-ci" && \
  echo "${CI_UPLOADER_SHA} /usr/local/bin/datadog-ci" | sha256sum --check && \
  chmod +x /usr/local/bin/datadog-ci
DATADOG_CI
RUN echo "DATADOG_CI >> /root/.bashrc
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

ENV PATH=/opt/toolchains/aarch64/bin:/opt/toolchains/x86_64/bin:$PATH

# Ensure pkg-config will not look into the system directories
ENV PKG_CONFIG_LIBDIR ""

ENTRYPOINT ["/entrypoint.sh"]
