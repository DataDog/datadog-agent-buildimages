ARG BASE_IMAGE=amazonlinux:2.0.20181114
FROM ${BASE_IMAGE}

# Build Args
ARG GIMME_GO_VERSION=1.14.12
ARG DD_CONDA_VERSION=4.7.12-0
ARG DD_PIP_VERSION=19.1
ARG DD_SETUPTOOLS_VERSION=44.1.1
ARG CMAKE_VERSION=3.14.4
ARG CLANG_VERSION=8.0.0
ARG DD_TARGET_ARCH=aarch64


# Environment
ENV GOPATH /go
ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV DD_PIP_VERSION $DD_PIP_VERSION
ENV DD_SETUPTOOLS_VERSION $DD_SETUPTOOLS_VERSION
ENV CMAKE_VERSION $CMAKE_VERSION
ENV CLANG_VERSION $CLANG_VERSION
ENV CONDA_PATH /root/miniforge3
ENV DD_CONDA_VERSION $DD_CONDA_VERSION
ENV DD_TARGET_ARCH $DD_TARGET_ARCH

# The last two lines contain dependencies for build of newer rpm
RUN yum -y install @development which perl-ExtUtils-MakeMaker ncurses-compat-libs git procps \
    curl-devel expat-devel gettext-devel openssl-devel systemd-devel zlib-devel bzip2 glibc-static python-devel tar pkgconfig  \
    libtool autoconf policycoreutils-python \
    bzip2-devel e2fsprogs-devel file-devel libacl-devel libarchive-devel libattr-devel \
    libxml2-devel lzo-devel nss nss-devel popt-devel sharutils xz-devel

# Build new rpm
COPY patches/rpm-4.15.1-fix-rpmbuild-segfault.patch /tmp
# The sed command basically replaces this:
#   --pipe 'rpm --addsign `grep ".*: .*\.rpm$"|cut -d: -f2` < "/dev/"`ps -p $$ -o tty | tail -n 1`' \
# (which makes `rpmbuild --sign` fail when there's no tty - e.g. in Gitlab) with this:
#   --pipe 'rpm --addsign `grep ".*: .*\.rpm$"|cut -d: -f2`' \
# (which makes `rpmbuild --sign` succeed even without tty)
RUN curl -sL -o /tmp/rpm-4.15.1.tar.bz2 http://ftp.rpm.org/releases/rpm-4.15.x/rpm-4.15.1.tar.bz2 \
    && cd /tmp \
    && tar -xjf /tmp/rpm-4.15.1.tar.bz2 \
    && cd rpm-4.15.1 \
    && cat /tmp/rpm-4.15.1-fix-rpmbuild-segfault.patch | patch -p1 \
    && ./configure --without-lua --without-audit \
    && make \
    && make install \
    && sed -i -e 's/ <.*/\x27 \\/' /usr/local/lib/rpm/rpmpopt-4.15.1 \
    && cd / \
    && rm -rf /tmp/rpm-4.15.1-fix-rpmbuild-segfault.patch /tmp/rpm-4.15.1.tar.bz2 /tmp/rpm-4.15.1

# Rebuild RPM database with the new rpm
RUN mkdir -p /usr/local/var/lib/rpm \
    && cp /var/lib/rpm/Packages /usr/local/var/lib/rpm/Packages \
    && /usr/local/bin/rpm --rebuilddb

# RVM
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/*
RUN rm -rf /gpg-keys
RUN curl -sSL https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.3 && rvm cleanup all"
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

# CMake. Pre-built using the build-cmake.sh script, to speed-up docker build.
RUN curl -sL -O https://dd-agent-omnibus.s3.amazonaws.com/cmake-${CMAKE_VERSION}-amzn-aarch64.tar.xz && \
    tar xf cmake-${CMAKE_VERSION}-amzn-aarch64.tar.xz --no-same-owner -kC / && \
    rm cmake-${CMAKE_VERSION}-amzn-aarch64.tar.xz
ENV PATH="/opt/cmake/bin:$PATH"

# Install clang and llvm version 8. Pre-built because building takes ~4 hours.
# This was built from sources on centos 7, using the build-clang.sh script
RUN curl -sL -o clang_llvm.tar.xz https://dd-agent-omnibus.s3.amazonaws.com/clang%2Bllvm-${CLANG_VERSION}-aarch64-linux.tar.xz && \
    tar xf clang_llvm.tar.xz --no-same-owner -kC / && \
    rm clang_llvm.tar.xz
ENV PATH="/opt/clang/bin:$PATH"

# Entrypoint
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# create the agent build folder within $GOPATH
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

# Force umask to 0022
RUN echo "umask 0022" >> /root/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
