ARG BASE_IMAGE=arm32v7/centos:7

FROM ubuntu as CERT_GETTER
ENV CACERT_BUNDLE_VERSION=2024-07-02
ENV CACERT_BUNDLE_SHA256="1bf458412568e134a4514f5e170a328d11091e071c7110955c9884ed87972ac9"
RUN apt-get update && apt-get install -y wget
RUN wget https://curl.se/ca/cacert-${CACERT_BUNDLE_VERSION}.pem -O /cacert.pem
RUN echo "${CACERT_BUNDLE_SHA256}  /cacert.pem" | sha256sum --check

FROM ${BASE_IMAGE}

# Build Args
ARG MSGO_SHA256_LINUX_ARMV6L
ARG GO_VERSION
ARG GO_SHA256_LINUX_ARMV6L
ARG RUST_VERSION=1.76.0
ARG RUSTC_SHA256="f21c44b01678c645d8fbba1e55e4180a01ac5af2d38bcbd14aa665e0d96ed69a"
ARG RUSTUP_VERSION=1.26.0
ARG RUSTUP_SHA256="f21c44b01678c645d8fbba1e55e4180a01ac5af2d38bcbd14aa665e0d96ed69a"
ARG RUSTUP_ARCH="armv7-unknown-linux-gnueabihf"
ARG DD_TARGET_ARCH=armhf
ARG BUNDLER_VERSION=2.4.20
ARG GIT_VERSION=2.10.1
ARG GIT_SHA256="78553f786f1a66cb68983c170be482558028a3376056c0f2ed366f331b1e35f2"

# Environment
ENV GOPATH /go
ENV GO_VERSION $GO_VERSION
ENV DD_TARGET_ARCH $DD_TARGET_ARCH
ENV BUNDLER_VERSION $BUNDLER_VERSION

# configure yum and rpm for running on non-armv7l architectures
RUN echo "armhfp" > /etc/yum/vars/basearch && \
    echo "armv7hl" > /etc/yum/vars/arch && \
    echo "armv7hl-redhat-linux-gnu" > /etc/rpm/platform && \
    mkdir -p /usr/local/etc/rpm && \
    echo "armv7hl-redhat-linux-gnu" > /usr/local/etc/rpm/platform

# Resolves a nasty NOKEY warning that appears when using yum
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-AltArch-Arm32

# Centos 7 EOLed on July 1st, 2024. We need to switch to vault.centos.org to get the packages
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo && \
    sed -i 's/^#.*baseurl=http/baseurl=http/g' /etc/yum.repos.d/*.repo && \
    sed -i 's/^mirrorlist=http/#mirrorlist=http/g' /etc/yum.repos.d/*.repo

# The last two lines contain dependencies for build of newer rpm
RUN yum -y install @development which perl-ExtUtils-MakeMaker ncurses-compat-libs git procps \
    curl-devel expat-devel gettext-devel openssl-devel systemd-devel zlib-devel bzip2 glibc-static tar pkgconfig  \
    libtool autoconf policycoreutils-python \
    bzip2-devel e2fsprogs-devel file-devel libacl-devel libarchive-devel libattr-devel \
    libxml2-devel lzo-devel nss nss-devel popt-devel sharutils xz-devel java \
    && yum clean all

COPY --from=CERT_GETTER /cacert.pem /etc/pki/tls/certs/ca-bundle.crt

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

# Git
RUN curl -OL "https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz" \
    && echo "${GIT_SHA256}  git-${GIT_VERSION}.tar.gz" | sha256sum --check \
    # --no-same-owner: git tarball has a file with UID 110493 which makes pulling this image fail, because we use docker user namespacing and we can't have >65K UIDs. \
    && tar xzf "git-${GIT_VERSION}.tar.gz" --no-same-owner \
    && cd "git-${GIT_VERSION}" \
    && make -j$(nproc) all \
    && make prefix=/usr/local install \
    && cd .. \
    && rm -rf "git-${GIT_VERSION}" "git-${GIT_VERSION}.tar.gz"

RUN git config --global user.email "package@datadoghq.com" && \
    git config --global user.name "Bits"

# This trick preloads a dynamic library that will replace the uname syscall to pretend the machine is armv7l
# The fakearmv7l library gets installed in "/usr/local/lib/libfakearmv7l.so"
RUN git clone --depth 1 https://github.com/DataDog/fakearmv7l ; \
        cd fakearmv7l ; \
        make ; \
        make install ; \
        cd .. ; \
        rm -rf ./fakearmv7l ; \
        export LD_PRELOAD="/usr/local/lib/libfakearmv7l.so"

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
RUN /bin/bash -l -c "rvm install --with-arch='armv7-a' -C '--build' -C 'arm-linux-gnueabihf' 2.7 && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --version $BUNDLER_VERSION --no-document"
RUN echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc

# Rust is needed to compile the SDS library
RUN curl -sSL -o rustup-init https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${RUSTUP_ARCH}/rustup-init \
    && echo "${RUSTUP_SHA256}  rustup-init" | sha256sum --check \
    && chmod +x ./rustup-init \
    && ./rustup-init -y --default-host=${RUSTUP_ARCH} --profile minimal --default-toolchain ${RUST_VERSION} \
    && echo "${RUSTC_SHA256}  ${HOME}/.cargo/bin/rustc" | sha256sum --check \
    && rm ./rustup-init
ENV PATH "~/.cargo/bin:${PATH}"

# CONDA
COPY python-packages-versions.txt setup_python.sh requirements.txt requirements-py2.txt /
COPY requirements /requirements
RUN ./setup_python.sh

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# Go
COPY setup_go.sh /
RUN ./setup_go.sh
ENV PATH="${GOPATH}/bin:${PATH}"

# Force umask to 0022
RUN echo "umask 0022" >> /root/.bashrc

# Entrypoint - only for local usage, Kubernetes-based Gitlab runners overwrite this
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
