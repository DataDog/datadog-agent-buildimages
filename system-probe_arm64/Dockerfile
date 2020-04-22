FROM debian:bullseye

RUN apt update && apt full-upgrade -y
RUN apt install -y \
        awscli \
        bison \
        clang-8 \
        cmake \
        curl \
        flex \
        git \
        go-dep \
        golang \
        libclang-8-dev \
        libelf-dev \
        linux-headers-arm64 \
        llvm \
        python \
        python3-pip \
        python3-distro \
        python3-distutils \
        python3-invoke \
        python3-pip \
        wget

RUN wget -O /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme && chmod +x /bin/gimme

ENV GOPATH=/go

# create the agent build folder within $GOPATH
RUN mkdir -p $GOPATH/src/github.com/DataDog/datadog-agent

RUN ln /usr/bin/clang-8  /usr/bin/clang
RUN ln -s /usr/lib/llvm-8 /usr/lib/llvm
