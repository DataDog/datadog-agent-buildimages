FROM debian:bullseye

RUN apt update && apt full-upgrade -y  && apt install -y  \
        awscli \
        bison \
        cmake \
        curl \
        flex \
        git \
        go-dep \
        golang \
        libelf-dev \
        linux-headers-arm64 \
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

# install clang from the website since the package manager can change at any time
RUN wget "https://releases.llvm.org/8.0.0/clang+llvm-8.0.0-aarch64-linux-gnu.tar.xz" -O /tmp/clang.tar.xz  -o /dev/null
RUN mkdir -p /opt/clang
RUN tar xf /tmp/clang.tar.xz  -C /opt/clang --strip-components=1
ENV PATH /opt/clang/bin:${PATH}
