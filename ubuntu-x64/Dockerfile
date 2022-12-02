FROM ubuntu as CURL_GETTER
ENV CURL_VERSION=7.79.1
ENV CURL_SHA256="0a89440848db3ba21d38b93b450d90fb84d4d0fa5562aa9c6933070b0eddc960"
RUN apt-get update && apt-get install -y wget
RUN wget https://github.com/moparisthebest/static-curl/releases/download/v${CURL_VERSION}/curl-amd64
RUN echo "${CURL_SHA256}  curl-amd64" | sha256sum --check

FROM ubuntu:14.04

# Build Args
ARG GIT_VERSION=2.10.1
ARG GIT_SHA256="78553f786f1a66cb68983c170be482558028a3376056c0f2ed366f331b1e35f2"
ARG GO_VERSION=1.18.8
ARG IBM_MQ_VERSION=9.2.4.0
ARG IBM_MQ_SHA256="d0d583eba72daf20b3762976f8831c2e23150ace90509520e12f8cda5b5bdb49"
ARG CMAKE_VERSION=3.23.0
ARG CMAKE_SHA256="5eaf3ded8255b3d149c7aad68c473f01c2345dce872e03c92f2e9c0185dfa75a"
ARG CLANG_VERSION=8.0.0
ARG CLANG_SHA256="9ef854b71949f825362a119bf2597f744836cb571131ae6b721cd102ffea8cd0"
ARG DD_TARGET_ARCH=x64
ARG RUST_VERSION=1.60.0
ARG RUSTC_SHA256="3dc5ef50861ee18657f9db2eeb7392f9c2a6c95c90ab41e45ab4ca71476b4338"
ARG RUSTUP_VERSION=1.24.3
ARG RUSTUP_SHA256="3dc5ef50861ee18657f9db2eeb7392f9c2a6c95c90ab41e45ab4ca71476b4338"

# Environment
ENV GOPATH /go
ENV GIT_VERSION $GIT_VERSION
ENV GIT_SHA256 $GIT_SHA256
ENV GO_VERSION $GO_VERSION
ENV IBM_MQ_VERSION $IBM_MQ_VERSION
ENV IBM_MQ_SHA256 $IBM_MQ_SHA256
ENV CMAKE_VERSION $CMAKE_VERSION
ENV CMAKE_SHA256 $CMAKE_SHA256
ENV CLANG_VERSION $CLANG_VERSION
ENV CLANG_SHA256 $CLANG_SHA256
ENV CONDA_PATH /root/miniconda3
ENV DD_TARGET_ARCH $DD_TARGET_ARCH
ENV RUST_VERSION $RUST_VERSION
ENV RUSTC_SHA256 $RUSTC_SHA256

# Mitigation for CVE-2019-3462
RUN echo 'Acquire::http::AllowRedirect"false";' >> /etc/apt/apt.conf.d/20datadog

# Setup APT to always use backports
RUN echo -e 'Package: *\nPin: release a=trusty-backports\nPin-Priority: 500' > /etc/apt/preferences


RUN apt-get update && apt-get install -y fakeroot procps bzip2 \
  build-essential pkg-config libssl-dev libcurl4-openssl-dev libexpat-dev libpq-dev libz-dev \
  libsystemd-journal-dev rpm tar gettext libtool autopoint autoconf pkg-config flex \
  selinux-basics

# Update curl with a statically linked binary
COPY --from=CURL_GETTER /curl-amd64 /usr/local/bin/curl
RUN chmod +x /usr/local/bin/curl

# Git
RUN curl -OL https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz \
    && echo "${GIT_SHA256}  git-${GIT_VERSION}.tar.gz" | sha256sum --check \
    # --no-same-owner: git tarball has a file with UID 110493 which makes pulling this image fail, because we use docker user namespacing and we can't have >65K UIDs. \
    && tar xzf git-${GIT_VERSION}.tar.gz --no-same-owner \
    && cd git-${GIT_VERSION} \
    && make prefix=/usr/local all \
    && make prefix=/usr/local install \
    && cd .. \
    && rm -rf git-${GIT_VERSION} git-${GIT_VERSION}.tar.gz

RUN git config --global user.email "package@datadoghq.com"
RUN git config --global user.name "Bits"

# IBM MQ
RUN mkdir -p /opt/mqm \
    && curl "https://s3.amazonaws.com/dd-agent-omnibus/ibm-mq-backup/${IBM_MQ_VERSION}-IBM-MQC-Redist-LinuxX64.tar.gz" -o /tmp/mq_client.tar.gz \
    && echo "${IBM_MQ_SHA256}  /tmp/mq_client.tar.gz" | sha256sum --check \
    && tar -C /opt/mqm -xf /tmp/mq_client.tar.gz \
    && rm -rf /tmp/mq_client.tar.gz

# CONDA
COPY ./python-packages-versions.txt /python-packages-versions.txt
COPY ./setup_python.sh /setup_python.sh
COPY ./requirements.txt ./requirements-py2.txt /
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
RUN /bin/bash -l -c "gem install bundler --no-document"

# CMake
RUN set -ex \
    && curl -sL -o cmake.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh \
    && echo "${CMAKE_SHA256}  cmake.sh" | sha256sum --check \
    && mkdir -p /opt/cmake/ \
    && sh cmake.sh --skip-license --prefix=/opt/cmake \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && rm cmake.sh

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
# Starting with go1.16, we need to build go from source, as the publicly distributed
# go binaries are built with a linker (binutils) version that's higher than what we have in
# the deb_x64 builder (the builder has 2.22, while go1.16 uses 2.26). Therefore, we need to
# build go manually in the builder for it to work with the linker present in the builder image.
# See: https://github.com/golang/go/issues/43996#issuecomment-782547917
# TODO: investigate if we could use gvm to do this for us.
COPY ./setup_go.sh /setup_go.sh
RUN ./setup_go.sh
COPY ./gobin.sh /etc/profile.d/

# Download and install golangci-lint
RUN curl -sSfL -o golangci-lint-install.sh https://raw.githubusercontent.com/golangci/golangci-lint/v1.44.2/install.sh \
    && echo "1c2edb726aad6bf7d260d95c370bd9ec0fb1a8651e6db6f77f250dd66067de0c  golangci-lint-install.sh" | sha256sum --check \
    && sh ./golangci-lint-install.sh -b $GOPATH/bin v1.21.0 \
    && echo "942efc00799b83aebaf6628c34e1151467b7fa21f0cfd78554279dc73f8c8ef3  $GOPATH/bin/golangci-lint" | sha256sum --check \
    && rm golangci-lint-install.sh

# Rust is needed to compile some python libs
RUN curl -sSL -o rustup-init https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init \
    && echo "${RUSTUP_SHA256}  rustup-init" | sha256sum --check \
    && chmod +x ./rustup-init \
    && ./rustup-init -y --profile minimal --default-toolchain ${RUST_VERSION} \
    && echo "${RUSTC_SHA256}  $HOME/.cargo/bin/rustc" | sha256sum --check \
    && rm ./rustup-init
ENV PATH "~/.cargo/bin:${PATH}"

# Entrypoint
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# create the agent build folder within $GOPATH
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

# Force umask to 0022
RUN echo "umask 0022" >> /root/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
