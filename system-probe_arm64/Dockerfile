FROM debian:bullseye

RUN apt update && apt full-upgrade -y
RUN apt install -y \
        awscli \
        bison \
        clang \
        cmake \
        flex \
        git \
        go-dep \
        golang \
        libclang-dev \
        libelf-dev \
        linux-headers-arm64 \
        llvm \
        python \
        python-pip \
        python3-distro \
        python3-distutils \
        python3-invoke \
        python3-pip


ENV GOPATH=/go

# create the agent build folder within $GOPATH
RUN mkdir -p $GOPATH/src/github.com/DataDog/datadog-agent
