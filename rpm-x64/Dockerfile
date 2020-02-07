FROM centos:7

# Build Args
ARG GIMME_GO_VERSION=1.13.11
ARG DD_CONDA_VERSION=4.7.10
ARG DD_PIP_VERSION=19.1
ARG DD_SETUPTOOLS_VERSION=41.0.1
ARG MQ_URL=https://s3.amazonaws.com/dd-agent-tarball-mirror/mqadv_dev80_linux_x86-64.tar.gz
ARG CMAKE_VERSION=3.14.4
ARG CLANG_VERSION=8.0.0

# Environment
ENV GOPATH /go
ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV DD_PIP_VERSION $DD_PIP_VERSION
ENV DD_SETUPTOOLS_VERSION $DD_SETUPTOOLS_VERSION
ENV MQ_URL $MQ_URL
ENV CMAKE_VERSION $CMAKE_VERSION
ENV CLANG_VERSION $CLANG_VERSION
ENV CONDA_PATH /root/miniconda3
ENV DD_CONDA_VERSION $DD_CONDA_VERSION

RUN yum groupinstall -y development
RUN yum -y install \
  which perl-ExtUtils-MakeMaker \
  centos-release-scl pkgconfig \
  curl-devel expat-devel gettext-devel openssl-devel zlib-devel bzip2 \
  glibc-static tar libtool git

# Git
RUN git config --global user.email "package@datadoghq.com"
RUN git config --global user.name "Bits"

# RVM
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/*
RUN rm -rf /gpg-keys
RUN curl -sSL https://get.rvm.io | bash -s stable --version latest-1.29
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.3 && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --no-document"

# Gimme
RUN curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
RUN chmod +x /bin/gimme
RUN gimme $GIMME_GO_VERSION
COPY ./gobin.sh /etc/profile.d/

# Conda
RUN curl -sL -o ~/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-${DD_CONDA_VERSION}-Linux-x86_64.sh
RUN bash ~/miniconda.sh -b
COPY ./conda.sh /etc/profile.d/
ENV PATH "${CONDA_PATH}/bin:${PATH}"

ENV PKG_CONFIG_LIBDIR $PKG_CONFIG_LIBDIR:$CONDA_PATH/lib/pkgconfig

# Setup pythons
RUN conda create -n ddpy2 python python=2
RUN conda create -n ddpy3 python python=3.8

# IBM MQ
# IBM MQ is required in the builder.
# It cannot be shipped with the agent for licensing reasons,
# so it can't be included in Omnibus
RUN mkdir -p /tmp/mq \
    && cd /tmp/mq \
    && curl -LO $MQ_URL \
    && tar -zxvf ./*.tar.gz \
    # Recommended: Create the mqm user ID with a fixed UID and group, so that the file permissions work between different images
    && groupadd --gid 1001 mqm \
    && useradd --uid 1001 --gid mqm --home-dir /var/mqm mqm \
    && usermod -G mqm root \
    && cd /tmp/mq/MQServer \
    # Accept the MQ license
    && ./mqlicense.sh -text_only -accept \
    && rpm -ivh *.rpm \
    # Recommended: Set the default MQ installation (makes the MQ commands available on the PATH)
    && /opt/mqm/bin/setmqinst -p /opt/mqm -i \
    && echo /opt/mqm/lib64 > /etc/ld.so.conf.d/ibm_mq.conf \
    && ldconfig \
    # Clean up all the downloaded files
    && rm -rf /tmp/mq

# CONDA prep
RUN conda init bash

# Update pip, setuptools and misc deps
RUN source /root/.bashrc && conda activate ddpy2 \
    && pip install -i https://pypi.python.org/simple pip==${DD_PIP_VERSION} \
    && pip install --ignore-installed setuptools==${DD_SETUPTOOLS_VERSION} \
    && pip install invoke distro==1.4.0 awscli==1.16.240

# Update pip, setuptools and misc deps
RUN source /root/.bashrc && conda activate ddpy3 \
    && pip install -i https://pypi.python.org/simple pip==${DD_PIP_VERSION} \
    && pip install --ignore-installed setuptools==${DD_SETUPTOOLS_VERSION} \
    && pip install invoke distro==1.4.0 awscli==1.16.240

# Add systemd headers
COPY ./rpm-headers/systemd /usr/include/systemd

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
RUN rm -r /usr/src/kernels/* && \
    curl -Sl -O https://dd-agent-omnibus.s3.amazonaws.com/kernel-4.9-headers-rpm-x64.tgz && \
    tar xf kernel-4.9-headers-rpm-x64.tgz --no-same-owner --strip 1 -C /usr && \
    rm kernel-4.9-headers-rpm-x64.tgz

# Download and install golangci-lint
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $GOPATH/bin v1.21.0

# Download and install libc glibc_version_header headers
# dropped in /usr/local/glibc_version_header-0.1
RUN set -ex \
    && curl -sL -o glibc_version_header.tar.gz https://github.com/wheybags/glibc_version_header/tarball/master \
    && mkdir /usr/local/glibc_version_header \
    && tar -xf glibc_version_header.tar.gz --strip 1 -C /usr/local/glibc_version_header \
    && rm glibc_version_header.tar.gz

# Entrypoint
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# create the agent build folder within $GOPATH
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

# Force umask to 0022
RUN echo "umask 0022" >> /root/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
