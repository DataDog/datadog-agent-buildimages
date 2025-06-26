FROM ubuntu as CURL_GETTER
ENV CURL_VERSION=7.79.1
ENV CURL_SHA256="0a89440848db3ba21d38b93b450d90fb84d4d0fa5562aa9c6933070b0eddc960"
RUN apt-get update && apt-get install -y wget
RUN wget https://github.com/moparisthebest/static-curl/releases/download/v${CURL_VERSION}/curl-amd64
RUN echo "${CURL_SHA256}  curl-amd64" | sha256sum --check

FROM ubuntu:16.04

# Build Args
ARG GIT_VERSION=2.10.1
ARG GIT_SHA256="78553f786f1a66cb68983c170be482558028a3376056c0f2ed366f331b1e35f2"
ARG GO_VERSION
ARG GO_SHA256_LINUX_AMD64
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS=1
ARG CMAKE_VERSION=3.30.2
ARG CMAKE_SHA256="33f5a7680578481ce0403dc5a814afae613f2f6f88d632a3bda0f7ff5f4dedfc"
ARG CLANG_VERSION=8.0.0
ARG CLANG_SHA256="9ef854b71949f825362a119bf2597f744836cb571131ae6b721cd102ffea8cd0"
ARG DD_TARGET_ARCH=x64
ARG RUST_VERSION=1.76.0
ARG RUSTC_SHA256="0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db"
ARG RUSTUP_VERSION=1.26.0
ARG RUSTUP_SHA256="0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db"
ARG PATCHELF_VERSION=0.13.1
ARG PATCHELF_SHA256="f6d5ecdb51ad78e963233cfde15020f9eebc9d9c7c747aaed54ce39c284ad019"
ARG BUNDLER_VERSION=2.4.20
ARG DPKG_VERSION=1.18.4
ARG DPKG_SHA256=19f332e26d40ee45c976ff9ef1a3409792c1f303acff714deea3b43bb689dc41
ARG GETTEXT_VERSION=0.19.8
ARG GETTEXT_SHA256=9c1781328238caa1685d7bc7a2e1dcf1c6c134e86b42ed554066734b621bd12f
ARG LIBLZMA_VERSION=5.2.11
ARG DATADOG_CI_VERSION=3.9.0
ARG DATADOG_CI_SHA=1b62407af5d4e99827a6903a0e893a17cadf94d1da42e86a76fb5f2b44b2a1e5
ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=a0c0449e640c8be5dcf7b7b093d5884f6a85406dbb86bbad0ea06becad5aaab8
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_amd64.zip"
ARG PROTOBUF_VERSION=29.3
ARG PROTOBUF_CHECKSUM=3e866620c5be27664f3d2fa2d656b5f3e09b5152b42f1bedbf427b333e90021a
ARG PROTOBUF_FILENAME="protoc-${PROTOBUF_VERSION}-linux-x86_64.zip"
ARG AWSCLI_VERSION=2.27.30
ARG AWSCLI_CHECKSUM=2bda389190cf1509584e1bcfb6c9ffe4343ffb1804cf8a9cd96ed874870f7f94

# Environment
ENV PYTHONUTF8 1
ENV GOPATH /go
ENV GO_VERSION $GO_VERSION
ENV CONDA_PATH /root/miniforge3
ENV DD_TARGET_ARCH $DD_TARGET_ARCH

# Remove the early return on non-interactive shells, which makes sourcing the file not activate conda
RUN grep -v return /root/.bashrc >> /root/newbashrc && cp /root/newbashrc /root/.bashrc

# Uncommenting the two lines below makes APT use a gpgv wrapper that ignores key expiration
# date but checks package signatures. Useful when the base distro is unsupported for
# a long time and its repodata signatures expire.
#COPY gpgvnoexpkeysig /usr/local/sbin
#RUN echo 'Dir::Bin::gpg "/usr/local/sbin/gpgvnoexpkeysig";' >> /etc/apt/apt.conf.d/20datadog

# Mitigation for CVE-2019-3462
RUN echo 'Acquire::http::AllowRedirect"false";' >> /etc/apt/apt.conf.d/20datadog
# Ignore expired repos signature
# Jessie is EOL, security updates repo will not get any newer updates, or will do so
# in arbitrary, unscheduled timeframes. At the time of this writing the repo has
# expired making the following option necessary for apt to work.
RUN echo 'Acquire::Check-Valid-Until "false";' >> /etc/apt/apt.conf.d/20datadog

RUN apt-get update && apt-get install -y fakeroot procps bzip2 \
  build-essential pkg-config libssl-dev libcurl4-openssl-dev libexpat-dev libpq-dev libz-dev \
  libsystemd-dev rpm tar gettext libtool autopoint autoconf pkg-config flex \
  selinux-basics libtool software-properties-common default-jre texinfo pxz wget \
  binutils unzip

# Ubuntu 14.04 comes with gcc 4.8 by default, which has a tough time compiling newer Go versions
# NOTE: we *could* uninstall gcc 4.8, but the "rvm requirements" run later on would reinstall
# it and there's not way to prevent that. So leave it be and use update-alternatives to select 4.9
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test
RUN apt-get update \
    && apt-get install -y gcc-9 g++-9 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 0

# Ensure we're using the newest binutils
ENV PATH "/usr/lib/binutils-2.26/bin:$PATH"

# Update curl with a statically linked binary
COPY --from=CURL_GETTER /curl-amd64 /usr/local/bin/curl
RUN chmod +x /usr/local/bin/curl

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# The dpkg version we want to install requires a more recent version of
# gettext than the one shipped in ubuntu 14.04. Even though we disable i18n,
# their buildsystem still needs gettext
RUN curl -LO https://mirrors.ibiblio.org/pub/mirrors/gnu/gettext/gettext-${GETTEXT_VERSION}.tar.xz \
    && echo "${GETTEXT_SHA256}  gettext-${GETTEXT_VERSION}.tar.xz" | sha256sum --check \
    && tar xf "gettext-${GETTEXT_VERSION}.tar.xz" \
    && cd "gettext-${GETTEXT_VERSION}" \
    && ./configure --prefix=/usr && make -j$(nproc) && make install \
    && cd / \
    && rm -rf "gettext-${GETTEXT_VERSION}*"

# Git
RUN curl -OL https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz \
    && echo "${GIT_SHA256}  git-${GIT_VERSION}.tar.gz" | sha256sum --check \
    # --no-same-owner: git tarball has a file with UID 110493 which makes pulling this image fail, because we use docker user namespacing and we can't have >65K UIDs. \
    && tar xzf git-${GIT_VERSION}.tar.gz --no-same-owner \
    && cd git-${GIT_VERSION} \
    && make -j$(nproc) prefix=/usr/local all \
    && make prefix=/usr/local install \
    && cd .. \
    && rm -rf git-${GIT_VERSION} git-${GIT_VERSION}.tar.gz

RUN git config --global user.email "package@datadoghq.com" && \
    git config --global user.name "Bits"


# Now install a recent enough liblzma (5.2+) which supports parallel compression
RUN git clone -b v${LIBLZMA_VERSION} https://github.com/tukaani-project/xz.git \
    && cd xz \
    && autoreconf -vif \
    && ./configure --prefix=/usr/ \
    && make -j$(nproc) && make install \
    && cp /usr/lib/liblzma.so* /lib/x86_64-linux-gnu/ \
    && rm -rf /xz

RUN curl -LO https://salsa.debian.org/dpkg-team/dpkg/-/archive/${DPKG_VERSION}/dpkg-${DPKG_VERSION}.tar.bz2 \
    && echo "${DPKG_SHA256}  dpkg-${DPKG_VERSION}.tar.bz2" | sha256sum --check \
    && tar -xf "dpkg-${DPKG_VERSION}.tar.bz2" \
    && cd "dpkg-${DPKG_VERSION}" \
    && echo 1.18.4 > .dist-version \
    && autoreconf -vfi \
    && mkdir build && cd build \
    && PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ../configure --disable-nls --disable-dselect --prefix=/usr --localstatedir=/var \
    && make -j$(nproc) \
    && make install \
    && rm -rf /dpkg-${DPKG_VERSION}.tar.bz2 /dpkg-${DPKG_VERSION}

# CI uploader, to send junit to ci-visibility during CI tests
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${DATADOG_CI_VERSION}/datadog-ci_linux-x64 --output "/usr/local/bin/datadog-ci" && \
    echo "${DATADOG_CI_SHA} /usr/local/bin/datadog-ci" | sha256sum --check && \
    chmod +x /usr/local/bin/datadog-ci

# CONDA
COPY python-packages-versions.txt setup_python.sh /
ENV DDA_VERSION=$DDA_VERSION
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS
RUN ./setup_python.sh
ENV PATH "${CONDA_PATH}/condabin:${PATH}"
ENV PKG_CONFIG_LIBDIR "${PKG_CONFIG_LIBDIR}:${CONDA_PATH}/lib/pkgconfig"

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

# CMake
RUN set -ex \
    && curl -sL -o cmake.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh \
    && echo "${CMAKE_SHA256}  cmake.sh" | sha256sum --check \
    && mkdir -p /opt/cmake/ \
    && sh cmake.sh --skip-license --prefix=/opt/cmake \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && rm cmake.sh

# Install Codecov uploader
COPY setup_codecov.sh /
RUN ./setup_codecov.sh

# Install clang and llvm version 8
RUN curl -LO https://releases.llvm.org/${CLANG_VERSION}/clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-14.04.tar.xz \
    && echo "${CLANG_SHA256}  clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-14.04.tar.xz" | sha256sum --check \
    && tar -xf clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-14.04.tar.xz --no-same-owner --strip 1 -kC /usr/ \
    && rm clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-14.04.tar.xz

# To build the EBPF code we need kernel headers for Linux 4.9
RUN curl -Sl -O https://dd-agent-omnibus.s3.amazonaws.com/kernel-4.9-headers-deb-x64.tgz \
    && echo "245f31a066460a51849365009557f61350e46579288e3f46cf9f44b3f5bee3ed  kernel-4.9-headers-deb-x64.tgz" | sha256sum --check \
    && tar xf kernel-4.9-headers-deb-x64.tgz --no-same-owner --strip 1 -C /usr \
    && rm kernel-4.9-headers-deb-x64.tgz

# Go
RUN curl -sL -o /tmp/golang.tar.gz https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz \
  && echo "$GO_SHA256_LINUX_AMD64  /tmp/golang.tar.gz" | sha256sum --check \
  && tar -C /usr/local -xzf /tmp/golang.tar.gz \
  && rm -f /tmp/golang.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
ENV PATH="${GOPATH}/bin:${PATH}"

RUN go install golang.org/dl/go1.25rc1@latest && mv $(which go1.25rc1) /usr/local/go/bin/go

# Rust is needed to compile the SDS library
RUN curl -sSL -o rustup-init https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init \
    && echo "${RUSTUP_SHA256}  rustup-init" | sha256sum --check \
    && chmod +x ./rustup-init \
    && ./rustup-init -y --profile minimal --default-toolchain ${RUST_VERSION} \
    && echo "${RUSTC_SHA256}  $HOME/.cargo/bin/rustc" | sha256sum --check \
    && rm ./rustup-init
ENV PATH "${HOME}/.cargo/bin:${PATH}"

# Setup patchelf
RUN curl -L -o patchelf-${PATCHELF_VERSION}.tar.gz https://github.com/NixOS/patchelf/archive/refs/tags/${PATCHELF_VERSION}.tar.gz \
    && echo "${PATCHELF_SHA256}  patchelf-${PATCHELF_VERSION}.tar.gz" | sha256sum --check \
    && tar xvzf patchelf-${PATCHELF_VERSION}.tar.gz \
    && cd patchelf-${PATCHELF_VERSION}  \
    && ./bootstrap.sh \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && cd - \
    && rm -rf patchelf-${PATCHELF_VERSION} \
    && rm patchelf-${PATCHELF_VERSION}.tar.gz

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


# Install protobuf
RUN curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/${PROTOBUF_FILENAME} \
    && echo "${PROTOBUF_CHECKSUM}  ${PROTOBUF_FILENAME}" | sha256sum --check \
    && unzip -o ${PROTOBUF_FILENAME} -d protoc3 \
    && mv protoc3/bin/* /usr/bin/ \
    && mv protoc3/include/* /usr/include/ \
    && rm -rf protoc3 \
    && rm ${PROTOBUF_FILENAME}

# Install linter tools
RUN apt-get update \
    && apt-get install -y shellcheck

# create the agent build folder within $GOPATH
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

# Force umask to 0022
RUN echo "umask 0022" >> /root/.bashrc

# Entrypoint - only for local usage, Kubernetes-based Gitlab runners overwrite this
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
