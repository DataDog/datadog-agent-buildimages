FROM debian:wheezy-backports

ARG GO_VERSION=1.16.7
ARG DD_PIP_VERSION=19.1
ARG DD_SETUPTOOLS_VERSION=44.1.1
ARG DD_SETUPTOOLS_VERSION_PY3=52.0.0
ARG IBM_MQ_VERSION=9.2.2.0
ARG CMAKE_VERSION=3.14.4
ARG CLANG_VERSION=8.0.0
ARG DD_TARGET_ARCH=x64

# Environment
ENV GOPATH /go
ENV GO_VERSION $GO_VERSION
ENV DD_PIP_VERSION $DD_PIP_VERSION
ENV DD_SETUPTOOLS_VERSION $DD_SETUPTOOLS_VERSION
ENV DD_SETUPTOOLS_VERSION_PY3 $DD_SETUPTOOLS_VERSION_PY3
ENV IBM_MQ_VERSION $IBM_MQ_VERSION
ENV CMAKE_VERSION $CMAKE_VERSION
ENV CLANG_VERSION $CLANG_VERSION
ENV CONDA_PATH /root/miniconda3
ENV DD_TARGET_ARCH $DD_TARGET_ARCH

# Mitigation for CVE-2019-3462
RUN echo 'Acquire::http::AllowRedirect"false";' >> /etc/apt/apt.conf.d/20datadog
# Ignore expired repos signature
# Wheezy is EOL, security updates repo will not get any newer updates, or will do so
# in arbitrary, unscheduled timeframes. At the time of this writing the repo has
# expired making the following option necessary for apt to work.
RUN echo 'Acquire::Check-Valid-Until "false";' >> /etc/apt/apt.conf.d/20datadog

RUN echo "deb http://archive.debian.org/debian wheezy main contrib non-free" > /etc/apt/sources.list && \
 echo "deb http://archive.debian.org/debian wheezy-backports main contrib non-free" > /etc/apt/sources.list.d/backports.list && \
 echo "deb http://archive.debian.org/debian-security wheezy/updates main contrib non-free" > /etc/apt/sources.list.d/security.list

RUN apt-get update && apt-get install -y wget fakeroot curl procps bzip2 \
  build-essential pkg-config libssl-dev libcurl4-openssl-dev libexpat-dev libz-dev \
  rpm tar gettext libtool autopoint autoconf pkg-config flex \
  selinux-basics

RUN apt-get install -y libsystemd-journal-dev/wheezy-backports

# Update curl with a statically linked binary
RUN curl -L https://github.com/moparisthebest/static-curl/releases/download/v7.79.1/curl-amd64 -o /usr/bin/curl
RUN chmod +x /usr/bin/curl

# Git
RUN curl -OL https://www.kernel.org/pub/software/scm/git/git-2.10.1.tar.gz
# --no-same-owner: git tarball has a file with UID 110493 which makes pulling this image fail, because we use docker user namespacing and we can't have >65K UIDs.
RUN tar xzf git-2.10.1.tar.gz --no-same-owner
RUN cd git-2.10.1 && make prefix=/usr/local all
RUN cd git-2.10.1 && make prefix=/usr/local install
RUN rm -rf git-2.10.1 git-2.10.1.tar.gz

RUN git config --global user.email "package@datadoghq.com"
RUN git config --global user.name "Bits"

# IBM MQ
RUN mkdir -p /opt/mqm \
    && curl "https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqdev/redist/${IBM_MQ_VERSION}-IBM-MQC-Redist-LinuxX64.tar.gz" -o /tmp/mq_client.tar.gz \
    && tar -C /opt/mqm -xf /tmp/mq_client.tar.gz \
    && rm -rf /tmp/mq_client.tar.gz

# CONDA
COPY ./setup_python.sh /setup_python.sh
RUN ./setup_python.sh
COPY ./conda.sh /etc/profile.d/conda.sh
ENV PATH "${CONDA_PATH}/bin:${PATH}"
ENV PKG_CONFIG_LIBDIR "${PKG_CONFIG_LIBDIR}:${CONDA_PATH}/lib/pkgconfig"

# RVM
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/*
RUN rm -rf /gpg-keys
RUN curl -sSL https://get.rvm.io | bash -s stable --version latest-1.29
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.7 --with-openssl-dir=${CONDA_PATH} && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --no-document"

# Docker
# Pin docker to before they broke wheezy
RUN curl -fsSL https://raw.githubusercontent.com/docker/docker-install/a34555fc0214be705330911071a8c3357f26e40b/install.sh | sed -e 's/ftp\.debian\.org/archive.debian.org/g' | sh

# CMake
RUN set -ex \
    && curl -sL -o cmake.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
    && mkdir -p /opt/cmake/ \
    && sh cmake.sh --skip-license --prefix=/opt/cmake \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && rm cmake.sh

# Install clang and llvm version 8
# Using build for sles11 because the versions built for other distros target glibcs that are too new to be used from this image
RUN curl -LO https://releases.llvm.org/${CLANG_VERSION}/clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz && \
    tar -xf clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz --no-same-owner --strip 1 -kC /usr/ && \
    rm clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz

# To build the EBPF code we need kernel headers for Linux 4.9
RUN curl -Sl -O https://dd-agent-omnibus.s3.amazonaws.com/kernel-4.9-headers-deb-x64.tgz && \
    tar xf kernel-4.9-headers-deb-x64.tgz --no-same-owner --strip 1 -C /usr && \
    rm kernel-4.9-headers-deb-x64.tgz

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
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $GOPATH/bin v1.21.0

# Entrypoint
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# create the agent build folder within $GOPATH
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

# Force umask to 0022
RUN echo "umask 0022" >> /root/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
