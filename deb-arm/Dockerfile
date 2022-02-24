ARG BASE_IMAGE=arm64v8/ubuntu:16.04

FROM ubuntu as CURL_GETTER
ENV WGET_AARCH64_VERSION=7.79.1
ENV WGET_AARCH64_SHA256="234cc67f7caae0a0e1222bd70b513c78f65e058397bc271191ede66d12ec0366"
ENV WGET_ARMV7_VERSION=7.79.1
ENV WGET_ARMV7_SHA256="db08ec3a16ce0a8db0ce512a55adb619f6fbc6005f151abb4a31333f26780cc3"
RUN apt-get update && apt-get install -y wget
RUN wget https://github.com/moparisthebest/static-curl/releases/download/v7.79.1/curl-armv7
RUN echo "${WGET_ARMV7_SHA256}  curl-armv7" | sha256sum --check
RUN wget https://github.com/moparisthebest/static-curl/releases/download/v7.79.1/curl-aarch64
RUN echo "${WGET_AARCH64_SHA256}  curl-aarch64" | sha256sum --check

## Valid archs are
# amd64, arm32v7, arm64v8, i386, ppc64le, s390x
FROM ${BASE_IMAGE}

# Build Args
ARG GIMME_GO_VERSION=1.17.6
ARG CMAKE_VERSION=3.14.4
ARG CMAKE_SHA256="546b4526ea2844d530699cb1e0a267095e3cb095188700abab83af1d2f525334"
ARG CLANG_VERSION=8.0.0
ARG CLANG_SHA256="a77eb8fde0a475c25d46dccdeb851a83cbeeeb11779fa2218ae19db9cd0e51f9"
ARG DD_TARGET_ARCH=aarch64


# Environment
ENV GOPATH /go
ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV CMAKE_VERSION $CMAKE_VERSION
ENV CMAKE_SHA256 $CMAKE_SHA256
ENV CLANG_VERSION $CLANG_VERSION
ENV CLANG_SHA256 $CLANG_SHA256
ENV CONDA_PATH /root/miniforge3
ENV DD_TARGET_ARCH $DD_TARGET_ARCH

# Remove the early return on non-interactive shells, which makes sourcing the file not activate conda
RUN grep -v return /root/.bashrc >> /root/newbashrc && cp /root/newbashrc /root/.bashrc

RUN apt-get update && apt-get install -y fakeroot curl git procps bzip2 \
    build-essential pkg-config tar libsystemd-dev libkrb5-dev \
    gettext libtool autopoint autoconf libtool-bin \
    selinux-basics

# Update curl with a statically linked binary
COPY --from=CURL_GETTER /curl-aarch64 /usr/local/bin/curl-aarch64
COPY --from=CURL_GETTER /curl-armv7 /usr/local/bin/curl-armv7
RUN if [ "$DD_TARGET_ARCH" = "aarch64" ] ; then \
        cp /usr/local/bin/curl-aarch64 /usr/local/bin/curl; \
    else \
        cp /usr/local/bin/curl-armv7 /usr/local/bin/curl; \
    fi
RUN chmod +x /usr/local/bin/curl

# CONDA
COPY ./python-packages-versions.txt /python-packages-versions.txt
COPY ./setup_python.sh /setup_python.sh
COPY ./requirements.txt /requirements.txt
RUN ./setup_python.sh
COPY ./conda.sh /etc/profile.d/conda.sh
ENV PATH "${CONDA_PATH}/bin:${PATH}"
ENV PKG_CONFIG_LIBDIR "${PKG_CONFIG_LIBDIR}:${CONDA_PATH}/lib/pkgconfig"

# RVM
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/*
RUN rm -rf /gpg-keys
RUN curl -sSL -o get-rvm.sh https://raw.githubusercontent.com/rvm/rvm/1.29.12/binscripts/rvm-installer \
    && echo "fea24461e98d41528d6e28684aa4c216dbe903869bc3fcdb3493b6518fae2e7e  get-rvm.sh" | sha256sum --check \
    && bash get-rvm.sh stable --version latest-1.29 \
    && rm get-rvm.sh
RUN /bin/bash -l -c "rvm requirements"
RUN if [ "$DD_TARGET_ARCH" = "aarch64" ] ; then \
        /bin/bash -l -c "rvm install --with-openssl-dir=${CONDA_PATH} 2.7 && rvm cleanup all" ; \
    else \
        /bin/bash -l -c "rvm install --with-openssl-dir=${CONDA_PATH} --with-arch='armv7-a' -C '--build' -C 'arm-linux-gnueabihf' 2.7 && rvm cleanup all" ; \
    fi
RUN /bin/bash -l -c "gem install bundler --no-document"

# Gimme
RUN curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/v1.5.4/gimme
RUN echo "03b295636d4e22870b6f6e9bc06a71d65311ae90d3d48cbc7071f82dd5837fbc  /bin/gimme" | sha256sum --check
RUN chmod +x /bin/gimme

# GIMME_ARCH = GOARCH, so must be a valid entry from `goarchlist` here:
# https://github.com/golang/go/blob/master/src/go/build/syslist.go
# Also see https://github.com/travis-ci/gimme/blob/master/gimme#L880
RUN if [ "$DD_TARGET_ARCH" = "aarch64" ] ; then \
        GIMME_ARCH=arm64 gimme $GIMME_GO_VERSION ; \
    else \
        GIMME_ARCH=arm gimme $GIMME_GO_VERSION ; \
    fi

COPY ./gobin.sh /etc/profile.d/

# CMake. Pre-built using the build-cmake.sh script, to speed-up docker build.
RUN if [ "$DD_TARGET_ARCH" = "aarch64" ] ; then curl -sL -O https://dd-agent-omnibus.s3.amazonaws.com/cmake-${CMAKE_VERSION}-ubuntu-aarch64.tar.xz \
    && echo "${CMAKE_SHA256}  cmake-${CMAKE_VERSION}-ubuntu-aarch64.tar.xz" | sha256sum --check \
    && tar xf cmake-${CMAKE_VERSION}-ubuntu-aarch64.tar.xz --no-same-owner -kC / \
    && rm cmake-${CMAKE_VERSION}-ubuntu-aarch64.tar.xz ; fi
ENV PATH="/opt/cmake/bin:$PATH"

# Install clang and llvm version 8. Pre-built because building takes ~4 hours.
# This was built from sources on centos 7, using the build-clang.sh script
RUN if [ "$DD_TARGET_ARCH" = "aarch64" ] ; then curl -sL -o clang_llvm.tar.xz https://dd-agent-omnibus.s3.amazonaws.com/clang%2Bllvm-${CLANG_VERSION}-aarch64-linux.tar.xz \
    && echo "${CLANG_SHA256}  clang_llvm.tar.xz" | sha256sum --check \
    && tar xf clang_llvm.tar.xz --no-same-owner -kC / \
    && rm clang_llvm.tar.xz ; fi
ENV PATH="/opt/clang/bin:$PATH"

# Entrypoint
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# create the agent build folder within $GOPATH
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

# Force umask to 0022
RUN echo "umask 0022" >> /root/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
