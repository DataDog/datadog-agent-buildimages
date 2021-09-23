FROM centos:6

# Build Args
ARG GIMME_GO_VERSION=1.15.13
ARG DD_PIP_VERSION=19.1
ARG DD_SETUPTOOLS_VERSION=44.1.1
ARG DD_SETUPTOOLS_VERSION_PY3=52.0.0
ARG IBM_MQ_VERSION=9.2.2.0
ARG CMAKE_VERSION=3.14.4
ARG CLANG_VERSION=8.0.0
ARG DD_TARGET_ARCH=x64

# Environment
ENV GOPATH /go
ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV DD_PIP_VERSION $DD_PIP_VERSION
ENV DD_SETUPTOOLS_VERSION $DD_SETUPTOOLS_VERSION
ENV DD_SETUPTOOLS_VERSION_PY3 $DD_SETUPTOOLS_VERSION_PY3
ENV IBM_MQ_VERSION $IBM_MQ_VERSION
ENV CMAKE_VERSION $CMAKE_VERSION
ENV CLANG_VERSION $CLANG_VERSION
ENV CONDA_PATH /root/miniconda3
ENV DD_TARGET_ARCH $DD_TARGET_ARCH

# Enable the vault (archive) repos, as we are past CentOS6 EOL
RUN sed -is 's/enabled=0/enabled=1/g' /etc/yum.repos.d/CentOS-Vault.repo && \
    sed -ie 's/6\.9/6.10/g' /etc/yum.repos.d/CentOS-Vault.repo && \
    rm /etc/yum.repos.d/CentOS-Base.repo

# The last two lines contain dependencies for build of newer libarchive and rpm
RUN yum -y install \
  @development \
  which perl-ExtUtils-MakeMaker \
  pkgconfig \
  curl-devel expat-devel gettext-devel openssl-devel zlib-devel bzip2 \
  glibc-static tar libtool \
  bzip2-devel e2fsprogs-devel file-devel libacl-devel libattr-devel \
  libxml2-devel lzo-devel nss nss-devel popt-devel sharutils xz-devel

# Autoconf
# We need a newer version of autoconf to compile procps-ng and also new rpm version (installing 2.69 over 2.63).
RUN curl -sL -o /tmp/autoconf-2.69.tar.gz https://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz \
    && cd /tmp \
    && tar -xvf /tmp/autoconf-2.69.tar.gz --no-same-owner \
    && cd autoconf-2.69 \
    && ./configure \
    && make && make install \
    && cd / \
    && rm -rf /tmp/autoconf-2.69 /tmp/autoconf-2.69.tar.gz

# New libarchive is required for the new rpm version
RUN curl -sL -o /tmp/libarchive-3.1.2-12.el7.src.rpm https://vault.centos.org/7.7.1908/os/Source/SPackages/libarchive-3.1.2-12.el7.src.rpm \
    && rpmbuild --rebuild /tmp/libarchive-3.1.2-12.el7.src.rpm \
    && rpm -Uvh --nodeps /root/rpmbuild/RPMS/x86_64/* \
    && rm -rf /tmp/libarchive-3.1.2-12.el7.src.rpm /root/rpmbuild

# Actually build new rpm
COPY patches/rpm-4.15.1-fix-rpmbuild-segfault.patch /tmp
RUN curl -sL -o /tmp/rpm-4.15.1.tar.bz2 http://ftp.rpm.org/releases/rpm-4.15.x/rpm-4.15.1.tar.bz2 \
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
RUN /bin/bash -l -c "rvm install 2.7 && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --no-document"

# CONDA
COPY ./setup_python.sh /setup_python.sh
RUN ./setup_python.sh
COPY ./conda.sh /etc/profile.d/conda.sh
ENV PATH "${CONDA_PATH}/bin:${PATH}"
ENV PKG_CONFIG_LIBDIR "${PKG_CONFIG_LIBDIR}:${CONDA_PATH}/lib/pkgconfig"

# Gimme
RUN curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
RUN chmod +x /bin/gimme
RUN gimme $GIMME_GO_VERSION
COPY ./gobin.sh /etc/profile.d/


# IBM MQ
RUN mkdir -p /opt/mqm \
    && curl "https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqdev/redist/${IBM_MQ_VERSION}-IBM-MQC-Redist-LinuxX64.tar.gz" -o /tmp/mq_client.tar.gz \
    && tar -C /opt/mqm -xf /tmp/mq_client.tar.gz \
    && rm -rf /tmp/mq_client.tar.gz

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

# Update GCC: CentOS6 gcc-4.4 is a little too far behind what we use with the debian builder
# Copy (and import through the repo file) the CERN signing key:
# pub   1024D/1D1E034B 2005-06-27
# uid                  CERN Linux Support (RPM signing key for CERN Linux Support) <linux.support@cern.ch>
COPY rpm-x64/RPM-GPG-KEY-cern /etc/pki/rpm-gpg/RPM-GPG-KEY-cern
RUN curl -o /etc/yum.repos.d/slc6-devtoolset.repo https://linuxsoft.cern.ch/cern/devtoolset/slc6-devtoolset.repo
RUN yum --enablerepo=slc6-devtoolset -y install devtoolset-1.1-gcc devtoolset-1.1-gcc-c++

ENV CC=/opt/rh/devtoolset-1.1/root/usr/bin/gcc
ENV CPP=/opt/rh/devtoolset-1.1/root/usr/bin/cpp
ENV CXX=/opt/rh/devtoolset-1.1/root/usr/bin/c++

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
