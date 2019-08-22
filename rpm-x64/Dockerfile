FROM centos:6

# Build Args
ARG GIMME_GO_VERSION=1.12.9
ARG DD_CONDA_VERSION=4.2.12
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
ENV CONDA_PATH /root/miniconda2
ENV DD_CONDA_VERSION $DD_CONDA_VERSION

RUN yum groupinstall -y development
RUN yum -y install \
  which perl-ExtUtils-MakeMaker \
  centos-release-scl pkgconfig \
  curl-devel expat-devel gettext-devel openssl-devel zlib-devel bzip2 \
  glibc-static tar

# Git
RUN curl -OL https://www.kernel.org/pub/software/scm/git/git-2.10.1.tar.gz
# --no-same-owner: git tarball has a file with UID 110493 which makes pulling this image fail, because we use docker user namespacing and we can't have >65K UIDs.
RUN tar xzf git-2.10.1.tar.gz --no-same-owner
RUN cd git-2.10.1 && make prefix=/usr/local all
RUN cd git-2.10.1 && make prefix=/usr/local install
RUN rm -rf git-2.10.1 git-2.10.1.tar.gz

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
RUN curl -sL -o ~/miniconda.sh https://repo.continuum.io/miniconda/Miniconda2-${DD_CONDA_VERSION}-Linux-x86_64.sh
RUN bash ~/miniconda.sh -b
COPY ./conda.sh /etc/profile.d/
ENV PKG_CONFIG_LIBDIR $PKG_CONFIG_LIBDIR:$CONDA_PATH/lib/pkgconfig

# The miniconda libreadline is broken. It breaks system tools by including it on the ld_library_path.
# use the sytem libreadline instead.
RUN rm /root/miniconda2/lib/libreadline.so && rm /root/miniconda2/lib/libreadline.so.6 && rm /root/miniconda2/lib/libreadline.so.6.2 && ln -s /lib64/libreadline.so.6 /root/miniconda2/lib/libreadline.so && ln -s /lib64/libreadline.so.6 /root/miniconda2/lib/libreadline.so.6 && ln -s /lib64/libreadline.so.6 /root/miniconda2/lib/libreadline.so.6.2

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
    && ./mqlicense.sh -text_only -accept \
    && rpm -ivh *.rpm \
    # Recommended: Set the default MQ installation (makes the MQ commands available on the PATH)
    && /opt/mqm/bin/setmqinst -p /opt/mqm -i \
    && echo /opt/mqm/lib64 > /etc/ld.so.conf.d/ibm_mq.conf \
    && ldconfig \
    # Clean up all the downloaded files
    && rm -rf /tmp/mq

# Update pip and setuptools
RUN ${CONDA_PATH}/bin/pip install -i https://pypi.python.org/simple pip==${DD_PIP_VERSION}
RUN ${CONDA_PATH}/bin/pip install  --ignore-installed setuptools==${DD_SETUPTOOLS_VERSION}

RUN ${CONDA_PATH}/bin/pip install invoke awscli==1.11.152

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
RUN curl -O http://releases.llvm.org/${CLANG_VERSION}/clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz && \
    tar -xf clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz --no-same-owner --strip 1 -kC /usr/ && \
    rm clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz

# To build the EBPF code we need kernel headers for Linux 4.9
RUN rm -r /usr/src/kernels/* && \
    curl -Sl -O https://dd-agent-omnibus.s3.amazonaws.com/kernel-4.9-headers-rpm-x64.tgz && \
    tar xf kernel-4.9-headers-rpm-x64.tgz --no-same-owner --strip 1 -C /usr && \
    rm kernel-4.9-headers-rpm-x64.tgz

# Update GCC: CentOS6 gcc-4.4 is a little too far behind what we use with the debian builder
RUN curl -o /etc/yum.repos.d/devtools-1.1.repo https://people.centos.org/tru/devtools-1.1/devtools-1.1.repo
RUN yum --enablerepo=testing-1.1-devtools-6 -y install devtoolset-1.1-gcc devtoolset-1.1-gcc-c++

ENV CC=/opt/centos/devtoolset-1.1/root/usr/bin/gcc
ENV CPP=/opt/centos/devtoolset-1.1/root/usr/bin/cpp
ENV CXX=/opt/centos/devtoolset-1.1/root/usr/bin/c++

# Entrypoint
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# create the agent build folder within $GOPATH
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

# Force umask to 0022
RUN echo "umask 0022" >> /root/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
