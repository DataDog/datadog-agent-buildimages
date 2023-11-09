FROM debian:buster

ARG DEBIAN_FRONTEND=noninteractive
# If you want to change the Go version, please use the update-go invoke task
ARG GO_VERSION=1.20.11
ARG GO_SHA256_LINUX_ARM64=7908a49c6ce9d48af9b5ba76ccaa0769da45d8b635259a01065b3739acef4ada

# We need up-to-date kernel headers to be able to use newly available eBPF helpers in programs.
RUN echo "deb http://deb.debian.org/debian buster-backports main" | tee -a /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils && apt-get dist-upgrade -y && apt-get install -y --no-install-recommends \
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
        $(apt-cache search --names-only linux-headers-5.* | \
          cut -d " " -f 1 | \
          grep "\-common$" | \
          sed -rn 's/(.*deb10\.)([0-9]+)-common/\2 \0 \1\2-arm64/p' | \
          sort -gr | \
          head -n 1 | \
          cut -f 2-3 -d " ") \
        linux-libc-dev \
        make \
        ninja-build/buster-backports \
        openssh-client \
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
        xsltproc \
        xz-utils

ENV GO_VERSION $GO_VERSION
ENV GOPATH=/go

RUN wget -O /tmp/golang.tar.gz https://go.dev/dl/go$GO_VERSION.linux-arm64.tar.gz \
  && echo "$GO_SHA256_LINUX_ARM64  /tmp/golang.tar.gz" | sha256sum --check \
  && tar -C /usr/local -xzf /tmp/golang.tar.gz \
  && rm -f /tmp/golang.tar.gz
ENV PATH "/usr/local/go/bin:${PATH}"
ENV PATH "${GOPATH}/bin:${PATH}"

# install clang from the website since the package manager can change at any time
RUN wget "https://github.com/llvm/llvm-project/releases/download/llvmorg-12.0.1/clang+llvm-12.0.1-aarch64-linux-gnu.tar.xz" -O /tmp/clang.tar.xz  -o /dev/null
RUN echo "3d4ad804b7c85007686548cbc917ab067bf17eaedeab43d9eb83d3a683d8e9d4  /tmp/clang.tar.xz" | sha256sum --check
RUN mkdir -p /opt/clang
RUN tar xf /tmp/clang.tar.xz --no-same-owner -C /opt/clang --strip-components=1
ENV PATH "/opt/clang/bin:${PATH}"

COPY requirements.txt /
COPY /requirements /requirements
RUN python3 -m pip install -r requirements.txt

# External calls configuration
COPY .awsconfig $HOME/.aws/config
COPY .curlrc .wgetrc $HOME/

# Install pulumi
RUN curl -fsSL https://raw.githubusercontent.com/pulumi/get.pulumi.com/f06767e3b26451439c066c94e0a907e6d6ec3d85/dist/install.sh > install-pulumi.sh
RUN echo "060d39770476f7d11de7c75dc1e1780f6492455555b36f4d3ff18f89752ebfc6  install-pulumi.sh" | sha256sum --check
RUN bash install-pulumi.sh --version 3.48.0
ENV PATH "/root/.pulumi/bin:${PATH}"
ENV PULUMI_CONFIG_PASSPHRASE "1234"
