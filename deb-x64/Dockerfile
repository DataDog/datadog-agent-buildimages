FROM ubuntu:14.04 as base

# Build Args - common arguments used across stages
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
ARG CI_UPLOADER_VERSION=2.38.1
ARG CI_UPLOADER_SHA=4e56d449e6396ae4c7356f07fc5372a28999aacb012d4343a3b8a9389123aa38
ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=a0c0449e640c8be5dcf7b7b093d5884f6a85406dbb86bbad0ea06becad5aaab8
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_amd64.zip"
ARG PROTOBUF_VERSION=29.3
ARG PROTOBUF_CHECKSUM=3e866620c5be27664f3d2fa2d656b5f3e09b5152b42f1bedbf427b333e90021a
ARG PROTOBUF_FILENAME="protoc-${PROTOBUF_VERSION}-linux-x86_64.zip"

# Environment common to all stages
ENV PYTHONUTF8=1
ENV GOPATH=/go
ENV GO_VERSION=$GO_VERSION
ENV CONDA_PATH=/root/miniforge3
ENV DD_TARGET_ARCH=$DD_TARGET_ARCH

# APT configuration (merged into one layer)
RUN grep -v return /root/.bashrc >> /root/newbashrc && cp /root/newbashrc /root/.bashrc \
    && echo 'Acquire::http::AllowRedirect"false";' >> /etc/apt/apt.conf.d/20datadog \
    && echo 'Acquire::Check-Valid-Until "false";' >> /etc/apt/apt.conf.d/20datadog \
    && apt-get update && apt-get install -y wget curl software-properties-common \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get install -y gcc-9 g++-9 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 0 \
    && echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc \
    && echo "umask 0022" >> /root/.bashrc

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# FROM base as curl-builder
FROM ubuntu as curl-builder
ENV CURL_VERSION=7.79.1
ENV CURL_SHA256="0a89440848db3ba21d38b93b450d90fb84d4d0fa5562aa9c6933070b0eddc960"
RUN apt-get update && apt-get install -y wget
RUN wget https://github.com/moparisthebest/static-curl/releases/download/v${CURL_VERSION}/curl-amd64
RUN echo "${CURL_SHA256}  curl-amd64" | sha256sum --check

# FROM base as gettext-builder
FROM base as gettext-builder
ARG GETTEXT_VERSION
ARG GETTEXT_SHA256
RUN apt-get update && apt-get install -y build-essential \
    && curl -LO https://mirrors.ibiblio.org/pub/mirrors/gnu/gettext/gettext-${GETTEXT_VERSION}.tar.xz \
    && echo "${GETTEXT_SHA256}  gettext-${GETTEXT_VERSION}.tar.xz" | sha256sum --check \
    && tar xf "gettext-${GETTEXT_VERSION}.tar.xz" \
    && cd "gettext-${GETTEXT_VERSION}" \
    && ./configure --prefix=/usr/local/gettext && make -j$(nproc) && make install \
    && cd / \
    && rm -rf "gettext-${GETTEXT_VERSION}*"

# FROM base as liblzma-builder
FROM base as liblzma-builder
ARG GIT_VERSION
ARG GIT_SHA256
RUN apt-get update && apt-get install -y build-essential autoconf libtool libssl-dev libcurl4-openssl-dev libexpat-dev zlib1g-dev gettext \
    && curl -OL https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz \
    && echo "${GIT_SHA256}  git-${GIT_VERSION}.tar.gz" | sha256sum --check \
    && tar xzf git-${GIT_VERSION}.tar.gz --no-same-owner \
    && cd git-${GIT_VERSION} \
    && make -j$(nproc) prefix=/usr/local all \
    && make prefix=/usr/local install \
    && cd / \
    && rm -rf git-${GIT_VERSION} git-${GIT_VERSION}.tar.gz \
    && git clone -b v${LIBLZMA_VERSION} https://github.com/tukaani-project/xz.git \
    && cd xz \
    && autoreconf -vif \
    && ./configure --prefix=/usr/local/liblzma \
    && make -j$(nproc) && make install \
    && cd / \
    && rm -rf /xz

# FROM base as dpkg-builder
FROM base as dpkg-builder
ARG DPKG_VERSION
ARG DPKG_SHA256
COPY --from=gettext-builder /usr/local/gettext /usr/local/
RUN apt-get update && apt-get install -y build-essential autoconf autopoint pkg-config \
    && curl -LO https://salsa.debian.org/dpkg-team/dpkg/-/archive/${DPKG_VERSION}/dpkg-${DPKG_VERSION}.tar.bz2 \
    && echo "${DPKG_SHA256}  dpkg-${DPKG_VERSION}.tar.bz2" | sha256sum --check \
    && tar -xf "dpkg-${DPKG_VERSION}.tar.bz2" \
    && cd "dpkg-${DPKG_VERSION}" \
    && echo 1.18.4 > .dist-version \
    && PATH=/usr/local/gettext/bin:$PATH \
    && CFLAGS=-I/usr/local/gettext/include LDFLAGS=-L/usr/local/gettext/lib \
    && autoreconf -vfi \
    && mkdir build && cd build \
    && ../configure --disable-nls --disable-dselect --prefix=/usr/local/dpkg --localstatedir=/var \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -rf /dpkg-${DPKG_VERSION}.tar.bz2 /dpkg-${DPKG_VERSION}

# FROM base as cmake-builder
FROM base as cmake-builder
ARG CMAKE_VERSION
ARG CMAKE_SHA256
RUN curl -sL -o cmake.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh \
    && echo "${CMAKE_SHA256}  cmake.sh" | sha256sum --check \
    && mkdir -p /opt/cmake/ \
    && sh cmake.sh --skip-license --prefix=/opt/cmake \
    && rm cmake.sh

# FROM base as patchelf-builder
FROM base as patchelf-builder
ARG PATCHELF_VERSION
ARG PATCHELF_SHA256
RUN apt-get update && apt-get install -y build-essential autoconf automake \
    && curl -L -o patchelf-${PATCHELF_VERSION}.tar.gz https://github.com/NixOS/patchelf/archive/refs/tags/${PATCHELF_VERSION}.tar.gz \
    && echo "${PATCHELF_SHA256}  patchelf-${PATCHELF_VERSION}.tar.gz" | sha256sum --check \
    && tar xvzf patchelf-${PATCHELF_VERSION}.tar.gz \
    && cd patchelf-${PATCHELF_VERSION} \
    && ./bootstrap.sh \
    && ./configure --prefix=/usr/local/patchelf \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -rf patchelf-${PATCHELF_VERSION} patchelf-${PATCHELF_VERSION}.tar.gz

# Final image with all tools combined
FROM base

# Copy all built components from previous stages
COPY --from=curl-builder /curl-amd64 /usr/local/bin/curl
COPY --from=liblzma-builder /usr/local/bin/git* /usr/local/bin/
COPY --from=liblzma-builder /usr/local/libexec/git-core /usr/local/libexec/git-core
COPY --from=liblzma-builder /usr/local/liblzma /usr/local/
COPY --from=dpkg-builder /usr/local/dpkg /usr/local/
COPY --from=cmake-builder /opt/cmake /opt/cmake
COPY --from=patchelf-builder /usr/local/patchelf /usr/local/

# Set permissions for copied binaries
RUN chmod +x /usr/local/bin/curl \
    && ln -sf /usr/local/bin/git /usr/bin/git \
    && ln -sf /usr/local/dpkg/bin/dpkg /usr/bin/dpkg \
    && ln -sf /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && ln -sf /usr/local/patchelf/bin/patchelf /usr/local/bin/patchelf \
    && cp /usr/local/liblzma/lib/liblzma.so* /lib/x86_64-linux-gnu/

# Configure git
RUN git config --global user.email "package@datadoghq.com" && \
    git config --global user.name "Bits"

# Install core dependencies in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    fakeroot procps bzip2 build-essential pkg-config libssl-dev libcurl4-openssl-dev \
    libexpat-dev libpq-dev libz-dev libsystemd-journal-dev rpm tar gettext libtool \
    autopoint autoconf pkg-config flex selinux-basics libtool default-jre texinfo pxz \
    binutils-2.26 unzip shellcheck \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# CI uploader
ARG CI_UPLOADER_VERSION
ARG CI_UPLOADER_SHA
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${CI_UPLOADER_VERSION}/datadog-ci_linux-x64 --output "/usr/local/bin/datadog-ci" && \
    echo "${CI_UPLOADER_SHA} /usr/local/bin/datadog-ci" | sha256sum --check && \
    chmod +x /usr/local/bin/datadog-ci

# CONDA environment setup in a single layer
COPY python-packages-versions.txt setup_python.sh /
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS
ENV DDA_VERSION=$DDA_VERSION
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS
RUN ./setup_python.sh
ENV PATH "${CONDA_PATH}/condabin:${PATH}"
ENV PKG_CONFIG_LIBDIR "${PKG_CONFIG_LIBDIR}:${CONDA_PATH}/lib/pkgconfig"

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
    && /bin/bash -l -c "gem install bundler --version $BUNDLER_VERSION --no-document"

# Install Codecov uploader
COPY setup_codecov.sh /
RUN ./setup_codecov.sh

# Install clang and llvm in a single layer
ARG CLANG_VERSION
ARG CLANG_SHA256
RUN curl -LO https://releases.llvm.org/${CLANG_VERSION}/clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-14.04.tar.xz \
    && echo "${CLANG_SHA256}  clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-14.04.tar.xz" | sha256sum --check \
    && tar -xf clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-14.04.tar.xz --no-same-owner --strip 1 -kC /usr/ \
    && rm clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-14.04.tar.xz

# Install kernel headers in a single layer
RUN curl -Sl -O https://dd-agent-omnibus.s3.amazonaws.com/kernel-4.9-headers-deb-x64.tgz \
    && echo "245f31a066460a51849365009557f61350e46579288e3f46cf9f44b3f5bee3ed  kernel-4.9-headers-deb-x64.tgz" | sha256sum --check \
    && tar xf kernel-4.9-headers-deb-x64.tgz --no-same-owner --strip 1 -C /usr \
    && rm kernel-4.9-headers-deb-x64.tgz

# Install Go in a single layer
ARG GO_VERSION
ARG GO_SHA256_LINUX_AMD64
RUN curl -sL -o /tmp/golang.tar.gz https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz \
    && echo "$GO_SHA256_LINUX_AMD64  /tmp/golang.tar.gz" | sha256sum --check \
    && tar -C /usr/local -xzf /tmp/golang.tar.gz \
    && rm -f /tmp/golang.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
ENV PATH="${GOPATH}/bin:${PATH}"

# Install Rust in a single layer
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

# Install vault in a single layer
ARG VAULT_VERSION
ARG VAULT_CHECKSUM
ARG VAULT_FILENAME
RUN curl -LO https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME} && \
    echo "${VAULT_CHECKSUM} ${VAULT_FILENAME}" | sha256sum --check && \
    unzip -o ${VAULT_FILENAME} -d /usr/bin vault && \
    rm ${VAULT_FILENAME}

# Install protobuf in a single layer
ARG PROTOBUF_VERSION
ARG PROTOBUF_CHECKSUM
ARG PROTOBUF_FILENAME
RUN curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/${PROTOBUF_FILENAME} \
    && echo "${PROTOBUF_CHECKSUM}  ${PROTOBUF_FILENAME}" | sha256sum --check \
    && unzip -o ${PROTOBUF_FILENAME} -d protoc3 \
    && mv protoc3/bin/* /usr/bin/ \
    && mv protoc3/include/* /usr/include/ \
    && rm -rf protoc3 \
    && rm ${PROTOBUF_FILENAME}

# Create the agent build folder
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

# Entrypoint - only for local usage, Kubernetes-based Gitlab runners overwrite this
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
