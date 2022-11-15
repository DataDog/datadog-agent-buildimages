FROM debian:buster

ARG RUST_VERSION=1.65.0
ARG RUSTC_SHA256="3dc5ef50861ee18657f9db2eeb7392f9c2a6c95c90ab41e45ab4ca71476b4338"
ARG RUSTUP_VERSION=1.24.3
ARG RUSTUP_SHA256="3dc5ef50861ee18657f9db2eeb7392f9c2a6c95c90ab41e45ab4ca71476b4338"

ARG DEBIAN_FRONTEND=noninteractive
ARG GIMME_GO_VERSION=1.18.8

ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV GOPATH=/go

# We need up-to-date kernel headers to be able to use newly available eBPF helpers in programs.
RUN echo "deb http://deb.debian.org/debian buster-backports main" | tee -a /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils && apt-get dist-upgrade -y && apt-get install -y --no-install-recommends \
        bison \
        cmake \
        curl \
        flex \
        g++ \
        gcc \
        gcc-multilib \
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
        $(apt-cache search --names-only linux-headers-5.* | \
          cut -d " " -f 1 | \
          grep "\-common$" | \
          sed -rn 's/(.*deb10\.)([0-9]+)-common/\2 \0 \1\2-amd64/p' | \
          sort -gr | \
          head -n 1 | \
          cut -f 2-3 -d " ") \
        linux-libc-dev \
        make \
        ninja-build \
        patch \
        pkg-config \
        python \
        python3-distro \
        python3-distutils \
        python3-netaddr \
        python3-setuptools \
        python3-pip \
        python3-pyroute2 \
        python3-dev \
        wget \
        xz-utils

RUN wget -O /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/v1.5.4/gimme
RUN echo "03b295636d4e22870b6f6e9bc06a71d65311ae90d3d48cbc7071f82dd5837fbc  /bin/gimme" | sha256sum --check
RUN chmod +x /bin/gimme
RUN gimme $GIMME_GO_VERSION

ENV PATH "${GOPATH}/bin:${PATH}"

# create the agent build folder within $GOPATH
RUN mkdir -p $GOPATH/src/github.com/DataDog/datadog-agent

RUN curl -sSL -o rustup-init https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init \
    && echo "${RUSTUP_SHA256}  rustup-init" | sha256sum --check \
    && chmod +x ./rustup-init \
    && ./rustup-init -y --profile minimal --default-toolchain ${RUST_VERSION} \
    && echo "${RUSTC_SHA256}  $HOME/.cargo/bin/rustc" | sha256sum --check \
    && rm ./rustup-init
ENV PATH "~/.cargo/bin:${PATH}"

# install clang from the website since the package manager can change at any time
RUN wget "https://github.com/llvm/llvm-project/releases/download/llvmorg-12.0.1/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz" -O /tmp/clang.tar.xz  -o /dev/null
RUN echo "6b3cc55d3ef413be79785c4dc02828ab3bd6b887872b143e3091692fc6acefe7  /tmp/clang.tar.xz" | sha256sum --check
RUN mkdir -p /opt/clang
RUN tar xf /tmp/clang.tar.xz --no-same-owner -C /opt/clang --strip-components=1
ENV PATH "/opt/clang/bin:${PATH}"

COPY ./requirements.txt /
RUN python3 -m pip install wheel
RUN python3 -m pip install -r requirements.txt

COPY ./entrypoint-sysprobe.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
