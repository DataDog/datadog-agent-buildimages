ARG BASE_IMAGE=amazonlinux:2.0.20181114

FROM ubuntu as CERT_GETTER
ENV CACERT_BUNDLE_VERSION=2024-07-02
ENV CACERT_BUNDLE_SHA256="1bf458412568e134a4514f5e170a328d11091e071c7110955c9884ed87972ac9"
RUN apt-get update && apt-get install -y wget
RUN wget https://curl.se/ca/cacert-${CACERT_BUNDLE_VERSION}.pem -O /cacert.pem
RUN echo "${CACERT_BUNDLE_SHA256}  /cacert.pem" | sha256sum --check

FROM ${BASE_IMAGE}

# Build Args
ARG GO_VERSION
ARG GO_SHA256_LINUX_ARM64
ARG RUST_VERSION=1.76.0
ARG RUSTC_SHA256="673e336c81c65e6b16dcdede33f4cc9ed0f08bde1dbe7a935f113605292dc800"
ARG RUSTUP_VERSION=1.26.0
ARG RUSTUP_SHA256="673e336c81c65e6b16dcdede33f4cc9ed0f08bde1dbe7a935f113605292dc800"
ARG RUSTUP_ARCH="aarch64-unknown-linux-gnu"
ARG BINUTILS_VERSION="2.39"
ARG BINUTILS_SHA256="d12ea6f239f1ffe3533ea11ad6e224ffcb89eb5d01bbea589e9158780fa11f10"
ARG CMAKE_VERSION=3.23.0
ARG CMAKE_SHA256="9f8d42ef0b33d1bea47afe15875435dac58503d6a3b58842b473fd811e6df172"
ARG CLANG_VERSION=8.0.0
ARG CLANG_SHA256="a77eb8fde0a475c25d46dccdeb851a83cbeeeb11779fa2218ae19db9cd0e51f9"
ARG DD_TARGET_ARCH=aarch64
ARG BUNDLER_VERSION=2.4.20
ARG PATCHELF_VERSION=0.13.1
ARG PATCHELF_SHA256="f6d5ecdb51ad78e963233cfde15020f9eebc9d9c7c747aaed54ce39c284ad019"
ARG CI_UPLOADER_VERSION=2.38.1
ARG CI_UPLOADER_SHA=90ee346ea639e2d70a45b70e2d1491e5749099665df06a2e6d80ddc9fd90fe0c

# Environment
ENV GOPATH /go
ENV GO_VERSION $GO_VERSION
ENV CONDA_PATH /root/miniforge3
ENV DD_TARGET_ARCH $DD_TARGET_ARCH

# The last two lines contain dependencies for build of newer rpm
RUN yum -y install @development which perl-core perl-ExtUtils-MakeMaker ncurses-compat-libs git procps \
    curl-devel expat-devel gettext-devel openssl-devel systemd-devel zlib-devel bzip2 glibc-static python-devel tar pkgconfig  \
    libtool autoconf policycoreutils-python texinfo \
    bzip2-devel e2fsprogs-devel file-devel libacl-devel libarchive-devel libattr-devel \
    libxml2-devel lzo-devel nss nss-devel popt-devel sharutils xz-devel java wget \
    && yum clean all

COPY --from=CERT_GETTER /cacert.pem /etc/pki/tls/certs/ca-bundle.crt

# Upgrade binutils
RUN curl -sL -O "https://mirrors.ibiblio.org/pub/mirrors/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz" \
    && echo "${BINUTILS_SHA256}  ./binutils-${BINUTILS_VERSION}.tar.gz" | sha256sum --check \
    && tar -zxvf "./binutils-${BINUTILS_VERSION}.tar.gz" \
    && cd "binutils-${BINUTILS_VERSION}" \
    && ./configure --prefix=/usr/local/binutils --disable-gprofng && make -j$(nproc) && make install \
    && cd - \
    && rm -rf "binutils-${BINUTILS_VERSION}" \
    && rm -rf "binutils-${BINUTILS_VERSION}.tar.gz"

# Upgrade some perl modules since some of our dependencies require some "new" features
# that were not available in centos 7
RUN cpanp -i List::Util 1.66

# Build new rpm
COPY patches/rpm-4.15.1-fix-rpmbuild-segfault.patch /tmp
# Cannot use HTTPS here: cert name is invalid
RUN curl -sL -o /tmp/rpm-4.15.1.tar.bz2 http://ftp.rpm.org/releases/rpm-4.15.x/rpm-4.15.1.tar.bz2 \
    && echo "ddef45f9601cd12042edfc9b6e37efcca32814e1e0f4bb8682d08144a3e2d230  /tmp/rpm-4.15.1.tar.bz2" | sha256sum --check \
    && cd /tmp \
    && tar -xjf /tmp/rpm-4.15.1.tar.bz2 \
    && cd rpm-4.15.1 \
    && cat /tmp/rpm-4.15.1-fix-rpmbuild-segfault.patch | patch -p1 \
    && ./configure --without-lua --without-audit \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/rpm-4.15.1-fix-rpmbuild-segfault.patch /tmp/rpm-4.15.1.tar.bz2 /tmp/rpm-4.15.1

# Rebuild RPM database with the new rpm
RUN mkdir -p /usr/local/var/lib/rpm \
    && cp /var/lib/rpm/Packages /usr/local/var/lib/rpm/Packages \
    && /usr/local/bin/rpm --rebuilddb

RUN git config --global user.email "package@datadoghq.com" && \
    git config --global user.name "Bits"

# CI uploader, to send junit to ci-visibility during CI tests
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${CI_UPLOADER_VERSION}/datadog-ci_linux-arm64 --output "/usr/local/bin/datadog-ci" \
    && echo "${CI_UPLOADER_SHA}  /usr/local/bin/datadog-ci" | sha256sum --check \
    && chmod +x /usr/local/bin/datadog-ci

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
RUN /bin/bash -l -c "rvm install 2.7 --with-openssl-dir=${CONDA_PATH} && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --version $BUNDLER_VERSION --no-document"
RUN echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc

# Override updated linker system-wide
RUN ln -sf /usr/local/binutils/bin/ld /usr/bin/ld

# Go
RUN curl -sL -o /tmp/golang.tar.gz https://go.dev/dl/go$GO_VERSION.linux-arm64.tar.gz \
  && echo "$GO_SHA256_LINUX_ARM64  /tmp/golang.tar.gz" | sha256sum --check \
  && tar -C /usr/local -xzf /tmp/golang.tar.gz \
  && rm -f /tmp/golang.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
ENV PATH="${GOPATH}/bin:${PATH}"

# Rust is needed to compile the SDS library
RUN curl -sSL -o rustup-init "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${RUSTUP_ARCH}/rustup-init" \
    && echo "${RUSTUP_SHA256}  rustup-init" | sha256sum --check \
    && chmod +x ./rustup-init \
    && ./rustup-init -y --profile minimal --default-toolchain "${RUST_VERSION}" \
    && echo "${RUSTC_SHA256}  $HOME/.cargo/bin/rustc" | sha256sum --check \
    && rm ./rustup-init
ENV PATH "~/.cargo/bin:${PATH}"

# CMake
RUN set -ex \
    && curl -sL -o cmake.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-aarch64.sh \
    && echo "${CMAKE_SHA256}  cmake.sh" | sha256sum --check \
    && mkdir -p /opt/cmake/ \
    && sh cmake.sh --skip-license --prefix=/opt/cmake \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && rm cmake.sh

# Install Codecov uploader
COPY setup_codecov.sh /
RUN ./setup_codecov.sh

# Install clang and llvm version 8. Pre-built because building takes ~4 hours.
# This was built from sources on centos 7, using the build-clang.sh script
RUN curl -sL -o clang_llvm.tar.xz https://dd-agent-omnibus.s3.amazonaws.com/clang%2Bllvm-${CLANG_VERSION}-aarch64-linux.tar.xz \
    && echo "${CLANG_SHA256}  clang_llvm.tar.xz" | sha256sum --check \
    && tar xf clang_llvm.tar.xz --no-same-owner -kC / \
    && rm clang_llvm.tar.xz
ENV PATH="/opt/clang/bin:$PATH"

# Force umask to 0022
RUN echo "umask 0022" >> /root/.bashrc

# Entrypoint - only for local usage, Kubernetes-based Gitlab runners overwrite this
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
