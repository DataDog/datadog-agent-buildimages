FROM debian:buster

ARG DEBIAN_FRONTEND=noninteractive
ARG GIMME_GO_VERSION=1.15.13

ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV GOPATH=/go

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils && apt-get dist-upgrade -y && apt-get install -y --no-install-recommends \
        awscli \
        bison \
        cmake \
        curl \
        flex \
        g++ \
        gcc \
        git \
        libbpf-dev \
        libedit-dev \
        libelf-dev \
        libfl-dev \
        libstdc++-8-dev \
        libtinfo-dev \
        libtinfo5 \
        libxml2-dev \
        libzip-dev \
        linux-headers-arm64 \
        linux-libc-dev \
        make \
        ninja-build \
        patch \
        python \
        python3-distro \
        python3-distutils \
        python3-netaddr \
        python3-setuptools \
        python3-pip \
        python3-pyroute2 \
        wget \
        xz-utils

RUN wget -O /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme && chmod +x /bin/gimme
RUN chmod +x /bin/gimme
RUN gimme $GIMME_GO_VERSION

COPY ./gobin.sh /etc/profile.d/

# create the agent build folder within $GOPATH
RUN mkdir -p $GOPATH/src/github.com/DataDog/datadog-agent

# install clang from the website since the package manager can change at any time
RUN wget "https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.1/clang+llvm-11.0.1-aarch64-linux-gnu.tar.xz" -O /tmp/clang.tar.xz  -o /dev/null
RUN mkdir -p /opt/clang
RUN tar xf /tmp/clang.tar.xz --no-same-owner -C /opt/clang --strip-components=1
ENV PATH "/opt/clang/bin:${PATH}"

RUN python3 -m pip install invoke==1.4.1

COPY ./entrypoint-sysprobe.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
