FROM debian:bullseye

ARG DEBIAN_FRONTEND=noninteractive
ARG GIMME_GO_VERSION=1.15.11

ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV GOPATH=/go

RUN apt update && apt full-upgrade -y && apt install -y \
        awscli \
        bison \
        cmake \
        curl \
        flex \
        git \
        libelf-dev \
        linux-headers-amd64 \
        python \
        python3-pip \
        python3-distro \
        python3-distutils \
        python3-invoke \
        python3-pip \
        libtinfo-dev \
        libtinfo5 \
        wget

RUN wget -O /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme && chmod +x /bin/gimme
RUN gimme $GIMME_GO_VERSION

# create the agent build folder within $GOPATH
RUN mkdir -p $GOPATH/src/github.com/DataDog/datadog-agent

# install clang from the website since the package manager can change at any time
RUN wget "https://releases.llvm.org/8.0.0/clang+llvm-8.0.0-x86_64-linux-gnu-ubuntu-18.04.tar.xz" -O /tmp/clang.tar.xz  -o /dev/null
RUN mkdir -p /opt/clang
RUN tar xf /tmp/clang.tar.xz  -C /opt/clang --strip-components=1
ENV PATH /opt/clang/bin:${PATH}
