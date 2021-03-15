FROM debian:buster

ARG DEBIAN_FRONTEND=noninteractive
ARG GIMME_GO_VERSION=1.14.12

ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV GOPATH=/go

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils && apt-get dist-upgrade -y && apt-get install -y --no-install-recommends \
        awscli \
        bison \
        bzip2 \
        build-essential \
        cmake \
        curl \
        fakeroot \
        flex \
        g++ \
        gcc \
        git \
        libelf-dev \
        libreadline-dev \
        libssl-dev \
        libstdc++-8-dev \
        libtinfo-dev \
        libtinfo5 \
        libxml2-dev \
        linux-headers-arm64 \
        meson \
        ninja-build \
        pkg-config \
        perl \
        python \
        python3-distro \
        python3-distutils \
        python3-setuptools \
        python3-pip \
        wget \
        xz-utils \
        zlib1g-dev

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

# install bundler
RUN curl -L https://github.com/rbenv/ruby-build/archive/v20210309.tar.gz | tar -zxf - -C /tmp/ && \
        cd /tmp/ruby-build-* && \
        ./install.sh && \
        cd / && \
        ruby-build 2.6.1 /usr/local
RUN gem install bundler --no-document

COPY ./entrypoint-sysprobe.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
