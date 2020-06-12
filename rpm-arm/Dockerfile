## Valid archs are
# amd64, arm32v7, arm64v8, i386, ppc64le
ARG BASE_IMAGE=arm64v8/centos:7
FROM ${BASE_IMAGE}

# Build Args
ARG GIMME_GO_VERSION=1.13.8
ARG DD_PIP_VERSION=19.1
ARG DD_SETUPTOOLS_VERSION=41.0.1
ARG CMAKE_VERSION=3.14.4
ARG CLANG_VERSION=8.0.0
ARG DD_TARGET_ARCH=arm64v8

# Environment
ENV GOPATH /go
ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV DD_PIP_VERSION $DD_PIP_VERSION
ENV DD_SETUPTOOLS_VERSION $DD_SETUPTOOLS_VERSION
ENV CMAKE_VERSION $CMAKE_VERSION
ENV CLANG_VERSION $CLANG_VERSION
ENV DD_TARGET_ARCH $DD_TARGET_ARCH

# configure yum and rpm for running on non-armv7l architectures
RUN if [ "$DD_TARGET_ARCH" = "arm32v7" ] ; then echo "armhfp" > /etc/yum/vars/basearch && \
    echo "armv7hl" > /etc/yum/vars/arch && \
    echo "armv7hl-redhat-linux-gnu" > /etc/rpm/platform ; fi

# Resolves a nasty NOKEY warning that appears when using yum
RUN if [ "$DD_TARGET_ARCH" = "arm32v7" ] ; then rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-AltArch-Arm32 ; fi

RUN yum groupinstall -y development && yum -y install which perl-ExtUtils-MakeMaker ncurses-compat-libs git procps \
    curl-devel expat-devel gettext-devel openssl-devel systemd-devel zlib-devel bzip2 glibc-static python-devel tar pkgconfig  \
    libtool autoconf policycoreutils-python gcc-4.9 g++-4.9

# This trick preloads a dynamic libary that will replace the uname syscall to pretend the machine is armv7l
# The fakearmv7l library gets installed in "/usr/local/lib/libfakearmv7l.so"
RUN if [ "$DD_TARGET_ARCH" = "arm32v7" ] ; then \
        git clone https://github.com/DataDog/fakearmv7l ; \
        cd fakearmv7l ; \
        make ; \
        make install ; \
        cd .. ; \
        rm -rf ./fakearmv7l ; \
    fi

# RVM
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/*
RUN rm -rf /gpg-keys
RUN curl -sSL https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.3 && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --no-document"

# Pip & Invoke
RUN curl "https://bootstrap.pypa.io/get-pip.py" | python2.7 - pip==${DD_PIP_VERSION} setuptools==${DD_SETUPTOOLS_VERSION}
RUN pip install invoke distro==1.4.0 awscli==1.16.240

# Gimme
RUN curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
RUN chmod +x /bin/gimme

# GIMME_ARCH = GOARCH, so must be a valid entry from `goarchlist` here:
# https://github.com/golang/go/blob/master/src/go/build/syslist.go
# Also see https://github.com/travis-ci/gimme/blob/master/gimme#L880
RUN if [ "$DD_TARGET_ARCH" = "arm64v8" ] ; then \
        GIMME_ARCH=arm64 gimme $GIMME_GO_VERSION ; \
    else \
        GIMME_ARCH=arm gimme $GIMME_GO_VERSION ; \
    fi

COPY ./gobin.sh /etc/profile.d/

# CMake. Pre-built using the build-cmake.sh script, to speed-up docker build.
RUN if [ "$DD_TARGET_ARCH" = "arm64v8" ] ; then curl -sL -O https://dd-agent-omnibus.s3.amazonaws.com/cmake-${CMAKE_VERSION}-amzn-aarch64.tar.xz && \
    tar xf cmake-${CMAKE_VERSION}-amzn-aarch64.tar.xz --no-same-owner -kC / && \
    rm cmake-${CMAKE_VERSION}-amzn-aarch64.tar.xz ; fi
ENV PATH="/opt/cmake/bin:$PATH"

# Install clang and llvm version 8. Pre-built because building takes ~4 hours.
# This was built from sources on centos 7, using the build-clang.sh script
RUN if [ "$DD_TARGET_ARCH" = "arm64v8" ] ; then curl -sL -o clang_llvm.tar.xz https://dd-agent-omnibus.s3.amazonaws.com/clang%2Bllvm-${CLANG_VERSION}-aarch64-linux.tar.xz && \
    tar xf clang_llvm.tar.xz --no-same-owner -kC / && \
    rm clang_llvm.tar.xz ; fi
ENV PATH="/opt/clang/bin:$PATH"

# Entrypoint
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# create the agent build folder within $GOPATH
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

# Force umask to 0022
RUN echo "umask 0022" >> /root/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
