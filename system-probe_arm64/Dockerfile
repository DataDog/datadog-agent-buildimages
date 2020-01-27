FROM debian:bullseye

ARG BCC_VERSION=v0.12.0

RUN apt update && apt full-upgrade -y
RUN apt install -y \
        awscli \
        clang \
        git \
        go-dep \
        golang \
        libelf-dev \
        linux-headers-arm64 \
        llvm \
        python3-distutils \
        python3-invoke \
        python-pip

RUN apt install -y \
        bison \
        cmake \
        flex \
        libclang-dev \
    && git clone -b "$BCC_VERSION" --depth=1 https://github.com/iovisor/bcc.git /tmp/bcc \
    && mkdir /tmp/bcc/build \
    && cd /tmp/bcc/build \
    && cmake .. -DCMAKE_INSTALL_PREFIX=/opt/libbcc \
    && make -j "$(nproc)" \
    && make install \
    && cd / \
    && rm -rf /tmp/bcc \
    && apt remove -y \
        bison \
        cmake \
        flex \
        libclang-dev


ENV GOPATH=/go

# create the agent build folder within $GOPATH
RUN mkdir -p $GOPATH/src/github.com/DataDog/datadog-agent
