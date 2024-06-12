ARG BASE_IMAGE=arm64v8/ubuntu:16.04

FROM ubuntu as CURL_GETTER
ENV CURL_AARCH64_VERSION=7.79.1
ENV CURL_AARCH64_SHA256="234cc67f7caae0a0e1222bd70b513c78f65e058397bc271191ede66d12ec0366"
ENV CURL_ARMV7_VERSION=7.79.1
ENV CURL_ARMV7_SHA256="db08ec3a16ce0a8db0ce512a55adb619f6fbc6005f151abb4a31333f26780cc3"
RUN apt-get update && apt-get install -y wget
RUN wget https://github.com/moparisthebest/static-curl/releases/download/v${CURL_ARMV7_VERSION}/curl-armv7
RUN echo "${CURL_ARMV7_SHA256}  curl-armv7" | sha256sum --check
RUN wget https://github.com/moparisthebest/static-curl/releases/download/v${CURL_AARCH64_VERSION}/curl-aarch64
RUN echo "${CURL_AARCH64_SHA256}  curl-aarch64" | sha256sum --check

## Valid archs are
# amd64, arm32v7, arm64v8, i386, ppc64le, s390x
FROM ${BASE_IMAGE}

# Build Args
ARG GO_VERSION
ARG GO_SHA256_LINUX_ARM64
ARG GO_SHA256_LINUX_ARMV6L
ARG CMAKE_VERSION=3.23.0
ARG CMAKE_SHA256="9f8d42ef0b33d1bea47afe15875435dac58503d6a3b58842b473fd811e6df172"
ARG CLANG_VERSION=18.1.6
ARG CLANG_SHA256="bcb3d53d3bd1027bc7f26544dff8cdc5ff74776add6eb994047326b284147a90"
ARG DD_TARGET_ARCH=aarch64
ARG BUNDLER_VERSION=2.4.20
ARG RUSTUP_VERSION=1.26.0
ARG RUST_VERSION=1.76.0

ARG RUSTC_SHA256_AARCH64="673e336c81c65e6b16dcdede33f4cc9ed0f08bde1dbe7a935f113605292dc800"
ARG RUSTUP_SHA256_AARCH64="673e336c81c65e6b16dcdede33f4cc9ed0f08bde1dbe7a935f113605292dc800"
ARG RUSTUP_ARCH_AARCH64="aarch64-unknown-linux-gnu"

ARG RUSTC_SHA256_ARMHF="f21c44b01678c645d8fbba1e55e4180a01ac5af2d38bcbd14aa665e0d96ed69a"
ARG RUSTUP_SHA256_ARMHF="f21c44b01678c645d8fbba1e55e4180a01ac5af2d38bcbd14aa665e0d96ed69a"
ARG RUSTUP_ARCH_ARMHF="armv7-unknown-linux-gnueabihf"

ARG PATCHELF_VERSION=0.13.1
ARG PATCHELF_SHA256="f6d5ecdb51ad78e963233cfde15020f9eebc9d9c7c747aaed54ce39c284ad019"
ARG DPKG_VERSION=1.18.4
ARG DPKG_SHA256=19f332e26d40ee45c976ff9ef1a3409792c1f303acff714deea3b43bb689dc41
ARG LIBLZMA_VERSION=5.2.11

# Environment
ENV GOPATH /go
ENV CONDA_PATH /root/miniforge3
ENV DD_TARGET_ARCH $DD_TARGET_ARCH

# Remove the early return on non-interactive shells, which makes sourcing the file not activate conda
RUN grep -v return /root/.bashrc >> /root/newbashrc && cp /root/newbashrc /root/.bashrc

RUN apt-get update && apt-get install -y fakeroot curl git procps bzip2 \
    build-essential pkg-config tar libsystemd-dev libkrb5-dev \
    gettext libtool autopoint autoconf libtool-bin \
    selinux-basics default-jre flex wget

# Ubuntu 16.04 comes with gcc 5.4 by default, which doesn't work with the race detector starting with Go 1.22
# NOTE: we *could* uninstall gcc 4.8, but the "rvm requirements" run later on would reinstall
# it and there's not way to prevent that. So leave it be and use update-alternatives to select 9
RUN apt install -y software-properties-common \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get install -y gcc-9 g++-9 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 0

# Update curl with a statically linked binary
COPY --from=CURL_GETTER /curl-aarch64 /usr/local/bin/curl-aarch64
COPY --from=CURL_GETTER /curl-armv7 /usr/local/bin/curl-armv7
RUN if [ "$DD_TARGET_ARCH" = "aarch64" ] ; then \
        cp /usr/local/bin/curl-aarch64 /usr/local/bin/curl; \
    else \
        cp /usr/local/bin/curl-armv7 /usr/local/bin/curl; \
    fi
RUN chmod +x /usr/local/bin/curl

# CONDA
COPY python-packages-versions.txt setup_python.sh requirements.txt requirements-py2.txt /
COPY requirements /requirements
RUN ./setup_python.sh
ENV PATH "${CONDA_PATH}/condabin:${PATH}"
ENV PKG_CONFIG_LIBDIR "${PKG_CONFIG_LIBDIR}:${CONDA_PATH}/lib/pkgconfig"

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# Patchelf
RUN curl -L -o patchelf-${PATCHELF_VERSION}.tar.gz https://github.com/NixOS/patchelf/archive/refs/tags/${PATCHELF_VERSION}.tar.gz \
    && echo "${PATCHELF_SHA256}  patchelf-${PATCHELF_VERSION}.tar.gz" | sha256sum --check \
    && tar xvzf patchelf-${PATCHELF_VERSION}.tar.gz \
    && cd patchelf-${PATCHELF_VERSION}  \
    && ./bootstrap.sh \
    && ./configure \
    && make \
    && make install \
    && cd - \
    && rm -rf patchelf-${PATCHELF_VERSION} \
    && rm patchelf-${PATCHELF_VERSION}.tar.gz

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
RUN if [ "$DD_TARGET_ARCH" = "aarch64" ] ; then \
        /bin/bash -l -c "rvm install --with-openssl-dir=${CONDA_PATH} 2.7 && rvm cleanup all" ; \
    else \
        /bin/bash -l -c "rvm install --with-openssl-dir=${CONDA_PATH} --with-arch='armv7-a' -C '--build' -C 'arm-linux-gnueabihf' 2.7 && rvm cleanup all" ; \
    fi
RUN /bin/bash -l -c "gem install bundler --version $BUNDLER_VERSION --no-document"
RUN echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc

# Go
RUN if [ "$DD_TARGET_ARCH" = "aarch64" ] ; then \
    curl -sL -o /tmp/golang.tar.gz https://go.dev/dl/go$GO_VERSION.linux-arm64.tar.gz \
    && echo "$GO_SHA256_LINUX_ARM64  /tmp/golang.tar.gz" | sha256sum --check \
    && tar -C /usr/local -xzf /tmp/golang.tar.gz \
    && rm -f /tmp/golang.tar.gz ; fi

RUN if [ "$DD_TARGET_ARCH" = "armhf" ] ; then \
    curl -sL -o /tmp/golang.tar.gz https://go.dev/dl/go$GO_VERSION.linux-armv6l.tar.gz \
    && echo "$GO_SHA256_LINUX_ARMV6L /tmp/golang.tar.gz" | sha256sum --check \
    && tar -C /usr/local -xzf /tmp/golang.tar.gz \
    && rm -f /tmp/golang.tar.gz ; fi

ENV PATH="/usr/local/go/bin:${PATH}"
ENV PATH="${GOPATH}/bin:${PATH}"

# Rust is needed to compile the SDS library
RUN if [ "$DD_TARGET_ARCH" = "armhf" ] ; then \
        export RUSTUP_SHA256=${RUSTUP_SHA256_ARMHF} \
               RUSTUP_ARCH=${RUSTUP_ARCH_ARMHF} \
               RUSTC_SHA256=${RUSTC_SHA256_ARMHF} \
    ; else if [ "$DD_TARGET_ARCH" = "aarch64" ]; then \
        export RUSTUP_SHA256=${RUSTUP_SHA256_AARCH64} \
               RUSTUP_ARCH=${RUSTUP_ARCH_AARCH64} \
               RUSTC_SHA256=${RUSTC_SHA256_AARCH64} \
    ; fi && curl -sSL -o rustup-init https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${RUSTUP_ARCH}/rustup-init \
    && echo "${RUSTUP_SHA256}  rustup-init" | sha256sum --check \
    && chmod +x ./rustup-init \
    && ./rustup-init -y --profile minimal --default-toolchain ${RUST_VERSION} \
    && echo "${RUSTC_SHA256}  $HOME/.cargo/bin/rustc" | sha256sum --check \
    && rm ./rustup-init; fi
ENV PATH "~/.cargo/bin:${PATH}"

# Now install a recent enough liblzma (5.2+) which supports parallel compression
RUN if [ "$DD_TARGET_ARCH" = "armhf" ] ; then \
    LIB_DEST="arm-linux-gnueabihf"; \
    else \
    LIB_DEST="aarch64-linux-gnu"; \
    fi && \
    git clone -b v${LIBLZMA_VERSION} https://git.tukaani.org/xz.git \
    && cd xz \
    && autoreconf -vif \
    && ./configure --prefix=/usr/ \
    && make -j$(nproc) && make install \
    && cp /usr/lib/liblzma.so* /lib/${LIB_DEST}/ \
    && rm -rf /xz

RUN if [ "$DD_TARGET_ARCH" = "armhf" ] ; then \
    LIB_DEST="arm-linux-gnueabihf"; \
    EXTRA_CONFIGURE_OPTIONS="--host=arm-linux-gnueabihf --build=arm-linux-gnueabihf"; \
    else \
    LIB_DEST="aarch64-linux-gnu"; \
    fi && \
    curl -LO https://salsa.debian.org/dpkg-team/dpkg/-/archive/${DPKG_VERSION}/dpkg-${DPKG_VERSION}.tar.bz2 \
    && echo "${DPKG_SHA256}  dpkg-${DPKG_VERSION}.tar.bz2" | sha256sum --check \
    && tar -xf "dpkg-${DPKG_VERSION}.tar.bz2" \
    && cd "dpkg-${DPKG_VERSION}" \
    && echo 1.18.4 > .dist-version \
    && autoreconf -vfi \
    && mkdir build && cd build \
    && PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ../configure --disable-nls --disable-dselect --prefix=/usr --localstatedir=/var ${EXTRA_CONFIGURE_OPTIONS} \
    && make -j$(nproc) \
    && make install

# CMake
RUN if [ "$DD_TARGET_ARCH" = "aarch64" ] ; then set -ex \
    && curl -sL -o cmake.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-aarch64.sh \
    && echo "${CMAKE_SHA256}  cmake.sh" | sha256sum --check \
    && mkdir -p /opt/cmake/ \
    && sh cmake.sh --skip-license --prefix=/opt/cmake \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && rm cmake.sh ; fi

# Install Codecov uploader
COPY setup_codecov.sh /
RUN ./setup_codecov.sh

# Install clang and llvm version 8. Pre-built because building takes ~4 hours.
# This was built from sources on centos 7, using the build-clang.sh script
RUN if [ "$DD_TARGET_ARCH" = "aarch64" ] ; then curl -LO "https://github.com/llvm/llvm-project/releases/download/llvmorg-${CLANG_VERSION}/clang+llvm-${CLANG_VERSION}-aarch64-linux-gnu.tar.xz
" \
    && echo "${CLANG_SHA256}  clang+llvm-${CLANG_VERSION}-aarch64-linux-gnu.tar.xz" | sha256sum --check \
    && tar -xf "clang+llvm-${CLANG_VERSION}-aarch64-linux-gnu.tar.xz" --no-same-owner --strip 1 -kC /usr/ \
    && rm "clang+llvm-${CLANG_VERSION}-aarch64-linux-gnu.tar.xz"

RUN git config --global user.email "package@datadoghq.com"
RUN git config --global user.name "Bits"

# Force umask to 0022
RUN echo "umask 0022" >> /root/.bashrc

# Entrypoint - only for local usage, Kubernetes-based Gitlab runners overwrite this
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
