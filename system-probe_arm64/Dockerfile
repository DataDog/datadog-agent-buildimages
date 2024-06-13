FROM debian:bullseye

ARG DEBIAN_FRONTEND=noninteractive
ARG GO_VERSION
ARG GO_SHA256_LINUX_ARM64
ARG DD_TARGET_ARCH=aarch64

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils && apt-get dist-upgrade -y && apt-get install -y --no-install-recommends \
        bison \
        cmake \
        curl \
        flex \
        g++ \
        gcc \
        git \
        jq \
        libbpf-dev \
        libedit-dev \
        libelf-dev \
        libfl-dev \
        libstdc++-9-dev \
        libtinfo-dev \
        libtinfo5 \
        libxml2-dev \
        libzip-dev \
        $(apt-cache search --names-only linux-headers-5.* | \
          cut -d " " -f 1 | \
          grep "\-arm64$" | \
          sort -Vr | \
          head -n 1 | \
          cut -f 2-3 -d " ") \
        linux-libc-dev \
        make \
        ninja-build \
        openssh-client \
        patch \
        pkg-config \
        default-jre \
        wget \
        xz-utils

ENV GO_VERSION $GO_VERSION
ENV GOPATH=/go
ENV CONDA_PATH /root/miniforge3
ENV DD_TARGET_ARCH $DD_TARGET_ARCH

# CONDA
COPY python-packages-versions.txt setup_python.sh requirements.txt requirements-py2.txt /
COPY requirements /requirements
RUN ./setup_python.sh
ENV PATH "${CONDA_PATH}/condabin:${PATH}"
ENV PATH "${CONDA_PATH}/envs/ddpy3/bin:${PATH}"
ENV PKG_CONFIG_LIBDIR "${PKG_CONFIG_LIBDIR}:${CONDA_PATH}/lib/pkgconfig"

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

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/
