ARG BASE_IMAGE="centos:7"

FROM ubuntu as CERT_GETTER
ENV CACERT_BUNDLE_VERSION=2025-05-20
ENV CACERT_BUNDLE_SHA256="ab3ee3651977a4178a702b0b828a4ee7b2bbb9127235b0ab740e2e15974bf5db"
RUN apt-get update && apt-get install -y wget
RUN wget "https://curl.se/ca/cacert-${CACERT_BUNDLE_VERSION}.pem" -O /cacert.pem
RUN echo "${CACERT_BUNDLE_SHA256}  /cacert.pem" | sha256sum --check

FROM $BASE_IMAGE AS base
ARG BASE_IMAGE

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
ARG CLANG_SHA256="7e2846ff60c181d1f27d97c23c25a2295f5730b6d88612ddd53b4cbb8177c4b9"
ARG DD_TARGET_ARCH=x64
ARG RUST_VERSION=1.76.0
ARG RUSTC_SHA256="0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db"
ARG RUSTUP_VERSION=1.26.0
ARG RUSTUP_SHA256="0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db"
ARG BINUTILS_VERSION="2.39"
ARG BINUTILS_SHA256="d12ea6f239f1ffe3533ea11ad6e224ffcb89eb5d01bbea589e9158780fa11f10"
ARG BUNDLER_VERSION=2.4.20
ARG CI_UPLOADER_VERSION=2.38.1
ARG CI_UPLOADER_SHA="4e56d449e6396ae4c7356f07fc5372a28999aacb012d4343a3b8a9389123aa38"
ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=a0c0449e640c8be5dcf7b7b093d5884f6a85406dbb86bbad0ea06becad5aaab8
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_amd64.zip"

# Environment common to all stages
ENV PYTHONUTF8=1
ENV GOPATH=/go
ENV GO_VERSION=$GO_VERSION
ENV CONDA_PATH=/root/miniforge3
ENV DD_TARGET_ARCH=$DD_TARGET_ARCH

# Base system configuration (merged into one layer)
RUN echo $(cat /etc/redhat-release | cut -d'.' -f1 | awk '{print $NF}') > /etc/redhat-release-major \
    && sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
    && sed -i 's/^#.*baseurl=http/baseurl=http/g' /etc/yum.repos.d/*.repo \
    && sed -i 's/^mirrorlist=http/#mirrorlist=http/g' /etc/yum.repos.d/*.repo \
    && yum -y install epel-release centos-release-scl \
    && yum-config-manager --enable rhel-server-rhscl-7-rpms \
    && sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
    && sed -i 's/^#.*baseurl=http/baseurl=http/g' /etc/yum.repos.d/*.repo \
    && sed -i 's/^mirrorlist=http/#mirrorlist=http/g' /etc/yum.repos.d/*.repo \
    && echo 'source /opt/rh/devtoolset-11/enable' >> /root/.bashrc \
    && echo 'umask 0022' >> /root/.bashrc

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# FROM base as rpm-builder
FROM base as rpm-builder
RUN yum -y install \
  @development \
  which perl-ExtUtils-MakeMaker perl-parent perl-core \
  pkgconfig \
  curl-devel expat-devel gettext-devel openssl-devel zlib-devel bzip2 \
  glibc-static tar libtool \
  bzip2-devel e2fsprogs-devel file-devel libacl-devel libattr-devel \
  libxml2-devel lzo-devel nss nss-devel popt-devel postgresql-devel sharutils xz-devel java \
  texinfo wget policycoreutils-python libarchive-devel patchelf devtoolset-11 \
  && yum clean all \
  && yum remove -y ruby

COPY patches/rpm-4.15.1-fix-rpmbuild-segfault.patch /tmp
# Cannot use HTTPS here: cert name is invalid
RUN curl -sL -o /tmp/rpm-4.15.1.tar.bz2 http://ftp.rpm.org/releases/rpm-4.15.x/rpm-4.15.1.tar.bz2 \
    && echo "ddef45f9601cd12042edfc9b6e37efcca32814e1e0f4bb8682d08144a3e2d230  /tmp/rpm-4.15.1.tar.bz2" | sha256sum --check \
    && cd /tmp \
    && tar -xjf /tmp/rpm-4.15.1.tar.bz2 \
    && cd rpm-4.15.1 \
    && cat /tmp/rpm-4.15.1-fix-rpmbuild-segfault.patch | patch -p1 \
    && ./configure --without-lua --without-audit \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -rf /tmp/rpm-4.15.1-fix-rpmbuild-segfault.patch /tmp/rpm-4.15.1.tar.bz2 /tmp/rpm-4.15.1

# FROM base as git-builder
FROM base as git-builder
ARG GIT_VERSION
ARG GIT_SHA256
RUN yum -y install \
  curl-devel expat-devel gettext-devel openssl-devel zlib-devel make gcc \
  && yum clean all \
  && curl -OL "https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz" \
  && echo "${GIT_SHA256}  git-${GIT_VERSION}.tar.gz" | sha256sum --check \
  # --no-same-owner: git tarball has a file with UID 110493 which makes pulling this image fail, because we use docker user namespacing and we can't have >65K UIDs. \
  && tar xzf "git-${GIT_VERSION}.tar.gz" --no-same-owner \
  && cd "git-${GIT_VERSION}" \
  && make -j$(nproc) prefix=/usr/local all \
  && make prefix=/usr/local install \
  && cd .. \
  && rm -rf "git-${GIT_VERSION}" "git-${GIT_VERSION}.tar.gz"

# FROM base as binutils-builder
FROM base as binutils-builder
ARG BINUTILS_VERSION
ARG BINUTILS_SHA256
RUN yum -y install gcc make texinfo \
    && yum clean all \
    && curl -sL -O "https://mirrors.ibiblio.org/pub/mirrors/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz" \
    && echo "${BINUTILS_SHA256}  ./binutils-${BINUTILS_VERSION}.tar.gz" | sha256sum --check \
    && tar -zxvf "./binutils-${BINUTILS_VERSION}.tar.gz" \
    && cd "binutils-${BINUTILS_VERSION}" \
    && ./configure --prefix=/usr/local/binutils --disable-gprofng && make -j$(nproc) && make install \
    && cd - \
    && rm -rf "binutils-${BINUTILS_VERSION}" \
    && rm -rf "binutils-${BINUTILS_VERSION}.tar.gz"

# FROM base as cmake-builder
FROM base as cmake-builder
ARG CMAKE_VERSION
ARG CMAKE_SHA256
RUN curl -sL -o cmake.sh "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh" \
    && echo "${CMAKE_SHA256}  cmake.sh" | sha256sum --check \
    && mkdir -p /opt/cmake/ \
    && sh cmake.sh --skip-license --prefix=/opt/cmake \
    && rm cmake.sh

# Final image with all tools combined
FROM base

# Copy all built components from previous stages
COPY --from=CERT_GETTER /cacert.pem /etc/pki/tls/certs/ca-bundle.crt
COPY --from=rpm-builder /usr/local/bin/rpm* /usr/local/bin/
COPY --from=rpm-builder /usr/local/lib/rpm /usr/local/lib/rpm
COPY --from=git-builder /usr/local/bin/git* /usr/local/bin/
COPY --from=git-builder /usr/local/libexec/git-core /usr/local/libexec/git-core
COPY --from=binutils-builder /usr/local/binutils /usr/local/binutils
COPY --from=cmake-builder /opt/cmake /opt/cmake

# Set permissions for copied binaries and symlinks
RUN ln -sf /usr/local/bin/git /usr/bin/git \
    && ln -sf /usr/local/binutils/bin/ld /usr/bin/ld \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && mkdir -p /usr/local/var/lib/rpm \
    && cp /var/lib/rpm/Packages /usr/local/var/lib/rpm/Packages \
    && /usr/local/bin/rpm --rebuilddb

# Configure git
RUN git config --global user.email "package@datadoghq.com" && \
    git config --global user.name "Bits"

# Install core dependencies in a single layer
RUN yum -y install \
  which perl-ExtUtils-MakeMaker perl-parent perl-core \
  pkgconfig \
  curl-devel expat-devel gettext-devel openssl-devel zlib-devel bzip2 \
  glibc-static tar libtool \
  bzip2-devel e2fsprogs-devel file-devel libacl-devel libattr-devel \
  libxml2-devel lzo-devel nss nss-devel popt-devel postgresql-devel sharutils xz-devel \
  texinfo wget policycoreutils-python libarchive-devel patchelf devtoolset-11 \
  && yum clean all \
  && cpanp -i List::Util 1.66

# CI uploader, to send junit to ci-visibility during CI tests
ARG CI_UPLOADER_VERSION
ARG CI_UPLOADER_SHA
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${CI_UPLOADER_VERSION}/datadog-ci_linux-x64 --output "/usr/local/bin/datadog-ci" \
    && echo "${CI_UPLOADER_SHA}  /usr/local/bin/datadog-ci" | sha256sum --check \
    && chmod +x /usr/local/bin/datadog-ci

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
    && /bin/bash -l -c "rvm install 2.6 --with-openssl-dir=${CONDA_PATH} && rvm cleanup all" \
    && /bin/bash -l -c "gem install bundler --version $BUNDLER_VERSION --no-document"

# Install Codecov uploader
COPY setup_codecov.sh /
RUN ./setup_codecov.sh

# Install clang and llvm in a single layer
ARG CLANG_VERSION
ARG CLANG_SHA256
RUN curl -LO "https://releases.llvm.org/${CLANG_VERSION}/clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz" \
    && echo "${CLANG_SHA256}  clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz" | sha256sum --check \
    && tar -xf "clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz" --no-same-owner --strip 1 -kC /usr/ \
    && rm "clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz"

# Install kernel headers in a single layer
RUN rm -r /usr/src/kernels/* \
    && curl -Sl -O https://dd-agent-omnibus.s3.amazonaws.com/kernel-4.9-headers-rpm-x64.tgz \
    && echo "1657ffa995654bc96405d4dbce0b17a55cd1eabd19479bc1611b0cb4f3c01fcc  kernel-4.9-headers-rpm-x64.tgz" | sha256sum --check \
    && tar xf kernel-4.9-headers-rpm-x64.tgz --no-same-owner --strip 1 -C /usr \
    && rm kernel-4.9-headers-rpm-x64.tgz

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
RUN curl -sSL -o rustup-init "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init" \
    && echo "${RUSTUP_SHA256}  rustup-init" | sha256sum --check \
    && chmod +x ./rustup-init \
    && ./rustup-init -y --profile minimal --default-toolchain "${RUST_VERSION}" \
    && echo "${RUSTC_SHA256}  $HOME/.cargo/bin/rustc" | sha256sum --check \
    && rm ./rustup-init
ENV PATH "${HOME}/.cargo/bin:${PATH}"

# Install Vault in a single layer
ARG VAULT_VERSION
ARG VAULT_CHECKSUM
ARG VAULT_FILENAME
RUN curl -LO https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME} && \
    echo "${VAULT_CHECKSUM} ${VAULT_FILENAME}" | sha256sum --check && \
    unzip -o ${VAULT_FILENAME} -d /usr/bin vault && \
    rm ${VAULT_FILENAME}

# Add systemd headers
COPY ./rpm-headers/systemd /usr/include/systemd

# Entrypoint - only for local usage, Kubernetes-based Gitlab runners overwrite this
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
