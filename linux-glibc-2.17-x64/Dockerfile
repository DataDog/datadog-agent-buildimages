FROM ubuntu:24.04

ARG GO_VERSION
ARG GO_SHA256_LINUX_AMD64
ARG MSGO_SHA256_LINUX_AMD64
ARG MSGO_PATCH
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS=1
ARG CTNG_VERSION=1.26.0
ARG RUST_VERSION=1.76.0
ARG RUSTC_SHA256="0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db"
ARG RUSTUP_VERSION=1.26.0
ARG RUSTUP_SHA256="0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db"
ARG BUNDLER_VERSION=2.4.20
ARG DD_TARGET_ARCH
ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=a0c0449e640c8be5dcf7b7b093d5884f6a85406dbb86bbad0ea06becad5aaab8
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_amd64.zip"
ARG DATADOG_CI_VERSION=3.9.0
ARG DATADOG_CI_SHA=1b62407af5d4e99827a6903a0e893a17cadf94d1da42e86a76fb5f2b44b2a1e5
ARG PROTOBUF_VERSION=29.3
ARG PROTOBUF_FILENAME="protoc-${PROTOBUF_VERSION}-linux-x86_64.zip"
ARG PROTOBUF_CHECKSUM=3e866620c5be27664f3d2fa2d656b5f3e09b5152b42f1bedbf427b333e90021a
ARG AWSCLI_VERSION=2.27.30
ARG AWSCLI_CHECKSUM=2bda389190cf1509584e1bcfb6c9ffe4343ffb1804cf8a9cd96ed874870f7f94

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
    linux-headers-generic libc6-dev-i386 jq libsystemd-dev clang-format

COPY linux-glibc-2.17-x64/config-x86_64-unknown-gnu-linux-glibc2.17 /build/crosstool-ng-${CTNG_VERSION}/.config
COPY linux-glibc-2.17-x64/config-aarch64-unknown-gnu-linux-glibc2.23 /build/crosstool-ng-${CTNG_VERSION}/.config-aarch64
COPY linux-glibc-2.17-x64/toolchain_x86-64.cmake /opt/cmake/x86_64-unknown-linux-gnu.toolchain.cmake
COPY linux-glibc-2.17-x64/cargo-config.toml ${HOME}/.cargo/config.toml
COPY linux-glibc-2.17-x64/ctng.patch /root/ctng.patch

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
    ./ct-ng upgradeconfig && \
    ./ct-ng build && \
    mkdir -p /opt/toolchains/ && \
    mv /root/x-tools/x86_64-unknown-linux-gnu/ /opt/toolchains/x86_64 && \
    mv .config-aarch64 .config && \
    ./ct-ng upgradeconfig && \
    ./ct-ng build && \
    mv /root/x-tools/aarch64-unknown-linux-gnu/ /opt/toolchains/aarch64 && \
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

# Protobuf
RUN curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/${PROTOBUF_FILENAME} \
    && echo "${PROTOBUF_CHECKSUM}  ${PROTOBUF_FILENAME}" | sha256sum --check \
    && unzip -o ${PROTOBUF_FILENAME} -d protoc3 \
    && mv protoc3/bin/* /usr/bin/ \
    && mv protoc3/include/* /usr/include/ \
    && rm -rf protoc3 \
    && rm ${PROTOBUF_FILENAME}

# Go
ENV GOPATH=/go
COPY setup_go.sh /
RUN ./setup_go.sh
ENV PATH="${GOPATH}/bin:${PATH}"

# Rust is needed to compile the SDS library
RUN curl -sSL -o rustup-init https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init \
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
  rm ${VAULT_FILENAME} && \
  # AWS v2 cli
  curl --retry 10 -fsSLo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip && \   
  echo "${AWSCLI_CHECKSUM} awscliv2.zip" | sha256sum --check && \
  unzip -q awscliv2.zip && \
  ./aws/install && \
  rm -rf aws awscliv2.zip

# CI uploader, to send junit to ci-visibility during CI tests
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${DATADOG_CI_VERSION}/datadog-ci_linux-x64 --output "/usr/local/bin/datadog-ci" && \
  echo "${DATADOG_CI_SHA} /usr/local/bin/datadog-ci" | sha256sum --check && \
  chmod +x /usr/local/bin/datadog-ci

RUN echo "umask 0022" >> /root/.bashrc
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

ENV PATH=/opt/toolchains/x86_64/bin:/opt/toolchains/aarch64/bin:$PATH

# Ensure pkg-config will not look into the system directories
ENV PKG_CONFIG_LIBDIR ""

ENTRYPOINT ["/entrypoint.sh"]
