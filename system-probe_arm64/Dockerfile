FROM debian:bullseye

RUN apt update && apt full-upgrade -y && apt install -y  \
        awscli \
        bison \
        clang-9 \
        cmake \
        curl \
        flex \
        git \
        go-dep \
        golang \
        libclang-9-dev \
        libelf-dev \
        linux-headers-arm64 \
        libtinfo5 \
        llvm-9 \
        python3 \
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

RUN ln -s /usr/bin/clang-9  /usr/bin/clang
RUN ln -s /usr/bin/llc-9 /usr/bin/llc
