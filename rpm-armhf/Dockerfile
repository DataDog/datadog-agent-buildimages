ARG BASE_IMAGE=arm32v7/centos:7

FROM ubuntu as CERT_GETTER
ENV CACERT_BUNDLE_VERSION=2025-05-20
ENV CACERT_BUNDLE_SHA256="ab3ee3651977a4178a702b0b828a4ee7b2bbb9127235b0ab740e2e15974bf5db"
RUN apt-get update && apt-get install -y wget
RUN wget https://curl.se/ca/cacert-${CACERT_BUNDLE_VERSION}.pem -O /cacert.pem
RUN echo "${CACERT_BUNDLE_SHA256}  /cacert.pem" | sha256sum --check

FROM ${BASE_IMAGE} AS base

# Build Args - common arguments used across stages
ARG GO_VERSION
ARG GO_SHA256_LINUX_ARMV6L
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS=1
ARG RUST_VERSION=1.76.0
ARG RUSTC_SHA256="f21c44b01678c645d8fbba1e55e4180a01ac5af2d38bcbd14aa665e0d96ed69a"
ARG RUSTUP_VERSION=1.26.0
ARG RUSTUP_SHA256="f21c44b01678c645d8fbba1e55e4180a01ac5af2d38bcbd14aa665e0d96ed69a"
ARG RUSTUP_ARCH="armv7-unknown-linux-gnueabihf"
ARG DD_TARGET_ARCH=armhf
ARG BUNDLER_VERSION=2.4.20
ARG GIT_VERSION=2.10.1
ARG GIT_SHA256="78553f786f1a66cb68983c170be482558028a3376056c0f2ed366f331b1e35f2"
ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=e8fa3d269cf90cdaa6e8b4c7e9172c45dce87d0a96f04b041016e9d97c7b9bdc
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_arm.zip"

# Environment common to all stages
ENV PYTHONUTF8=1
ENV GOPATH=/go
ENV GO_VERSION=$GO_VERSION
ENV DD_TARGET_ARCH=$DD_TARGET_ARCH
ENV BUNDLER_VERSION=$BUNDLER_VERSION

# Basic system configuration (merged into one layer)
RUN echo "armhfp" > /etc/yum/vars/basearch && \
    echo "armv7hl" > /etc/yum/vars/arch && \
    echo "armv7hl-redhat-linux-gnu" > /etc/rpm/platform && \
    mkdir -p /usr/local/etc/rpm && \
    echo "armv7hl-redhat-linux-gnu" > /usr/local/etc/rpm/platform && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-AltArch-Arm32 && \
    sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo && \
    sed -i 's/^#.*baseurl=http/baseurl=http/g' /etc/yum.repos.d/*.repo && \
    sed -i 's/^mirrorlist=http/#mirrorlist=http/g' /etc/yum.repos.d/*.repo && \
    echo 'umask 0022' >> /root/.bashrc

# FROM base as git-builder
FROM base as git-builder
ARG GIT_VERSION
ARG GIT_SHA256
RUN yum -y install curl-devel expat-devel gettext-devel openssl-devel zlib-devel make gcc \
    && yum clean all \
    && curl -OL "https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz" \
    && echo "${GIT_SHA256}  git-${GIT_VERSION}.tar.gz" | sha256sum --check \
    && tar xzf "git-${GIT_VERSION}.tar.gz" --no-same-owner \
    && cd "git-${GIT_VERSION}" \
    && make -j$(nproc) all \
    && make prefix=/usr/local install \
    && cd .. \
    && rm -rf "git-${GIT_VERSION}" "git-${GIT_VERSION}.tar.gz"

# FROM base as rpm-builder
FROM base as rpm-builder
RUN yum -y install @development which perl-ExtUtils-MakeMaker ncurses-compat-libs procps \
    curl-devel expat-devel gettext-devel openssl-devel systemd-devel zlib-devel bzip2 glibc-static tar pkgconfig \
    libtool autoconf policycoreutils-python \
    bzip2-devel e2fsprogs-devel file-devel libacl-devel libarchive-devel libattr-devel \
    libxml2-devel lzo-devel nss nss-devel popt-devel sharutils xz-devel \
    && yum clean all

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

# FROM base as fakearmv7l-builder
FROM base as fakearmv7l-builder
RUN yum -y install git gcc make \
    && yum clean all \
    && git clone --depth 1 https://github.com/DataDog/fakearmv7l \
    && cd fakearmv7l \
    && make \
    && make install \
    && cd / \
    && rm -rf ./fakearmv7l

# Final image with all tools combined
FROM base

# Copy all built components from previous stages
COPY --from=CERT_GETTER /cacert.pem /etc/pki/tls/certs/ca-bundle.crt
COPY --from=git-builder /usr/local/bin/git* /usr/local/bin/
COPY --from=git-builder /usr/local/libexec/git-core /usr/local/libexec/git-core
COPY --from=rpm-builder /usr/local/bin/rpm* /usr/local/bin/
COPY --from=rpm-builder /usr/local/lib/rpm /usr/local/lib/rpm
COPY --from=fakearmv7l-builder /usr/local/lib/libfakearmv7l.so /usr/local/lib/

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# Set up RPM database with the new rpm
RUN mkdir -p /usr/local/var/lib/rpm \
    && cp /var/lib/rpm/Packages /usr/local/var/lib/rpm/Packages \
    && /usr/local/bin/rpm --rebuilddb

# Git configuration
RUN git config --global user.email "package@datadoghq.com" && \
    git config --global user.name "Bits"

# Install core dependencies in a single layer
RUN yum -y install which perl-ExtUtils-MakeMaker ncurses-compat-libs procps \
    curl-devel expat-devel gettext-devel openssl-devel systemd-devel zlib-devel bzip2 glibc-static tar pkgconfig \
    libtool autoconf policycoreutils-python java \
    && yum clean all \
    && export LD_PRELOAD="/usr/local/lib/libfakearmv7l.so"

# RVM installation in a single layer
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/* && rm -rf /gpg-keys \
    && curl -sSL -o get-rvm.sh https://raw.githubusercontent.com/rvm/rvm/1.29.12/binscripts/rvm-installer \
    && echo "fea24461e98d41528d6e28684aa4c216dbe903869bc3fcdb3493b6518fae2e7e  get-rvm.sh" | sha256sum --check \
    && bash get-rvm.sh stable --version 1.29.12 \
    && echo "d2de0b610ee321489e5c673fe749e13be8fb34c0aa08a74446d87f95a17de730  /usr/local/rvm/bin/rvm" | sha256sum --check \
    && rm get-rvm.sh \
    && /bin/bash -l -c "rvm requirements" \
    && /bin/bash -l -c "rvm install --with-arch='armv7-a' -C '--build' -C 'arm-linux-gnueabihf' 2.7 && rvm cleanup all" \
    && /bin/bash -l -c "gem install bundler --version $BUNDLER_VERSION --no-document" \
    && echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc

# Install Rust in a single layer
ARG RUST_VERSION
ARG RUSTC_SHA256
ARG RUSTUP_VERSION
ARG RUSTUP_SHA256
ARG RUSTUP_ARCH
RUN curl -sSL -o rustup-init https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${RUSTUP_ARCH}/rustup-init \
    && echo "${RUSTUP_SHA256}  rustup-init" | sha256sum --check \
    && chmod +x ./rustup-init \
    && ./rustup-init -y --default-host=${RUSTUP_ARCH} --profile minimal --default-toolchain ${RUST_VERSION} \
    && echo "${RUSTC_SHA256}  ${HOME}/.cargo/bin/rustc" | sha256sum --check \
    && rm ./rustup-init
ENV PATH "${HOME}/.cargo/bin:${PATH}"

# CONDA environment setup in a single layer
COPY python-packages-versions.txt setup_python.sh /
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS
ENV DDA_VERSION=$DDA_VERSION
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS
RUN ./setup_python.sh

# Install Go in a single layer
ARG GO_VERSION
ARG GO_SHA256_LINUX_ARMV6L
RUN curl -sL -o /tmp/golang.tar.gz https://go.dev/dl/go$GO_VERSION.linux-armv6l.tar.gz \
    && echo "$GO_SHA256_LINUX_ARMV6L  /tmp/golang.tar.gz" | sha256sum --check \
    && tar -C /usr/local -xzf /tmp/golang.tar.gz \
    && rm -f /tmp/golang.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
ENV PATH="${GOPATH}/bin:${PATH}"

# Install Vault in a single layer
ARG VAULT_VERSION
ARG VAULT_CHECKSUM
ARG VAULT_FILENAME
RUN curl -LO https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME} && \
    echo "${VAULT_CHECKSUM} ${VAULT_FILENAME}" | sha256sum --check && \
    unzip -o ${VAULT_FILENAME} -d /usr/bin vault && \
    rm ${VAULT_FILENAME}

# Entrypoint - only for local usage, Kubernetes-based Gitlab runners overwrite this
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
