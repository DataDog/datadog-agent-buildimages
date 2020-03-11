FROM debian:wheezy-backports
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Build Args
ARG GIMME_GO_VERSION=1.13.8
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

RUN apt-get update && apt-get install -y fakeroot curl git procps bzip2 \
  build-essential pkg-config\
  rpm tar gettext libtool autopoint autoconf pkg-config flex

RUN apt-get install -y libsystemd-journal-dev/wheezy-backports

# The license does not recognize debian based systems for some reason
# It's a bug in this version. So, it has been rewritten
COPY ./deb-x64/mqlicense.sh /mqlicense.sh

# IBM MQ
# IBM MQ is required in the builder.
# It cannot be shipped with the agent for licensing reasons,
# so it can't be included in Omnibus
RUN mkdir -p /tmp/mq \
    && cd /tmp/mq \
    && curl -LO $MQ_URL \
    && tar -zxvf ./*.tar.gz \
    # Recommended: Create the mqm user ID with a fixed UID and group, so that the file permissions work between different images
    && groupadd --gid 1000 mqm \
    && useradd --uid 1000 --gid mqm --home-dir /var/mqm mqm \
    && usermod -G mqm root \
    && cd /tmp/mq/MQServer \
    # Accept the MQ license
    && cp /mqlicense.sh . \
    && chmod +x mqlicense.sh \
    && ./mqlicense.sh -text_only -accept \
    && rpm -ivh --force-debian *.rpm \
    # Recommended: Set the default MQ installation (makes the MQ commands available on the PATH)
    && /opt/mqm/bin/setmqinst -p /opt/mqm -i \
    && echo /opt/mqm/lib64 > /etc/ld.so.conf.d/ibm_mq.conf \
    && ldconfig \
    # Clean up all the downloaded files
    && rm -rf /tmp/mq

# Conda
RUN curl -sL -o ~/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-${DD_CONDA_VERSION}-Linux-x86_64.sh
RUN bash ~/miniconda.sh -b
COPY ./conda.sh /etc/profile.d/

# RVM
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/*
RUN rm -rf /gpg-keys
RUN curl -sSL https://get.rvm.io | bash -s stable --version latest-1.29
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.3 && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --no-document"

# CONDA prep
ENV PKG_CONFIG_LIBDIR "${PKG_CONFIG_LIBDIR}:${CONDA_PATH}/lib/pkgconfig"
ENV PATH "${CONDA_PATH}/bin:${PATH}"
RUN conda init bash

# Setup pythons
RUN conda create -n ddpy2 python python=2
RUN conda create -n ddpy3 python python=3.8

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


# Gimme
RUN curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
RUN chmod +x /bin/gimme
RUN gimme $GIMME_GO_VERSION
COPY ./gobin.sh /etc/profile.d/

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
RUN curl -O http://releases.llvm.org/${CLANG_VERSION}/clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz && \
    tar -xf clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz --no-same-owner --strip 1 -kC /usr/ && \
    rm clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz

# To build the EBPF code we need kernel headers for Linux 4.9
RUN curl -Sl -O https://dd-agent-omnibus.s3.amazonaws.com/kernel-4.9-headers-deb-x64.tgz && \
    tar xf kernel-4.9-headers-deb-x64.tgz --no-same-owner --strip 1 -C /usr && \
    rm kernel-4.9-headers-deb-x64.tgz

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
