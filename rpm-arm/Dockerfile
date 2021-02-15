ARG BASE_IMAGE=arm32v7/centos:7
FROM ${BASE_IMAGE}

# Build Args
ARG GIMME_GO_VERSION=1.14.12
ARG DD_PIP_VERSION=19.1
ARG DD_SETUPTOOLS_VERSION=41.0.1
ARG CMAKE_VERSION=3.14.4
ARG CLANG_VERSION=8.0.0
ARG DD_TARGET_ARCH=armhf

# Environment
ENV GOPATH /go
ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV DD_PIP_VERSION $DD_PIP_VERSION
ENV DD_SETUPTOOLS_VERSION $DD_SETUPTOOLS_VERSION
ENV CMAKE_VERSION $CMAKE_VERSION
ENV CLANG_VERSION $CLANG_VERSION
ENV DD_TARGET_ARCH $DD_TARGET_ARCH

# configure yum and rpm for running on non-armv7l architectures
RUN echo "armhfp" > /etc/yum/vars/basearch && \
    echo "armv7hl" > /etc/yum/vars/arch && \
    echo "armv7hl-redhat-linux-gnu" > /etc/rpm/platform

# Resolves a nasty NOKEY warning that appears when using yum
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-AltArch-Arm32

RUN yum groupinstall -y development && yum -y install which perl-ExtUtils-MakeMaker ncurses-compat-libs git procps \
    curl-devel expat-devel gettext-devel openssl-devel systemd-devel zlib-devel bzip2 glibc-static python-devel tar pkgconfig  \
    libtool autoconf policycoreutils-python

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
RUN curl -sSL https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.3 && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --no-document"

# Pip & Invoke
COPY ./setup_python.sh /setup_python.sh
RUN ./setup_python.sh

# Gimme
RUN curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
RUN chmod +x /bin/gimme

# GIMME_ARCH = GOARCH, so must be a valid entry from `goarchlist` here:
# https://github.com/golang/go/blob/master/src/go/build/syslist.go
# Also see https://github.com/travis-ci/gimme/blob/master/gimme#L880
RUN GIMME_ARCH=arm gimme $GIMME_GO_VERSION

COPY ./gobin.sh /etc/profile.d/

# Entrypoint
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# create the agent build folder within $GOPATH
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

# Force umask to 0022
RUN echo "umask 0022" >> /root/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
