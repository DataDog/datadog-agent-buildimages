FROM debian:bookworm

ARG DEBIAN_FRONTEND=noninteractive
ARG GO_VERSION
ARG GO_SHA256_LINUX_ARM64
ARG DD_TARGET_ARCH=aarch64
ARG CI_UPLOADER_VERSION=2.38.1
ARG CI_UPLOADER_SHA=90ee346ea639e2d70a45b70e2d1491e5749099665df06a2e6d80ddc9fd90fe0c

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
        libstdc++-11-dev \
        libtinfo-dev \
        libtinfo5 \
        libxml2-dev \
        libzip-dev \
        $(apt-cache search --names-only linux-headers-5.* | \
          cut -d " " -f 1 | \
          grep "[0-9]-arm64$" | \
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

# CI uploader, to send junit to ci-visibility during CI tests
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${CI_UPLOADER_VERSION}/datadog-ci_linux-arm64 --output "/usr/local/bin/datadog-ci" && \
  echo "${CI_UPLOADER_SHA} /usr/local/bin/datadog-ci" | sha256sum --check && \
  chmod +x /usr/local/bin/datadog-ci

# install clang from the website since the package manager can change at any time
RUN wget "https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-aarch64-linux-gnu.tar.xz" -O /tmp/clang.tar.xz  -o /dev/null
RUN echo "dcaa1bebbfbb86953fdfbdc7f938800229f75ad26c5c9375ef242edad737d999  /tmp/clang.tar.xz" | sha256sum --check
RUN mkdir -p /opt/clang
RUN tar xf /tmp/clang.tar.xz --no-same-owner -C /opt/clang --strip-components=1
ENV PATH "/opt/clang/bin:${PATH}"

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/
