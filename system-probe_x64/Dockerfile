FROM debian:buster

ARG DEBIAN_FRONTEND=noninteractive
ARG GIMME_GO_VERSION=1.19.5

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
        default-jre \
        wget \
        xz-utils

ENV GO_VERSION $GIMME_GO_VERSION
ENV GOPATH=/usr/local/go

RUN wget -O /tmp/golang.tar.gz https://go.dev/dl/go1.18.6.linux-amd64.tar.gz
RUN echo "bb05f179a773fed60c6a454a24141aaa7e71edfd0f2d465ad610a3b8f1dc7fe8 /tmp/golang.tar.gz" | sha256sum --check
RUN tar -C /usr/local -xzf /tmp/golang.tar.gz
ENV PATH "${GOPATH}/bin:${PATH}"

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
