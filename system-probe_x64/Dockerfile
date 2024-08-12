FROM debian:bullseye

ARG DEBIAN_FRONTEND=noninteractive
ARG GO_VERSION
ARG GO_SHA256_LINUX_AMD64
ARG DD_TARGET_ARCH=x64
ARG CI_UPLOADER_VERSION=2.38.1
ARG CI_UPLOADER_SHA=4e56d449e6396ae4c7356f07fc5372a28999aacb012d4343a3b8a9389123aa38

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils && apt-get dist-upgrade -y && apt-get install -y --no-install-recommends \
        bison \
        curl \
        flex \
        g++ \
        gcc \
        gcc-multilib \
        git \
        jq \
        libbpf-dev \
        libdw-dev \
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
          grep "[0-9]-amd64$" | \
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

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

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

RUN wget -O /tmp/golang.tar.gz https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz \
  && echo "$GO_SHA256_LINUX_AMD64  /tmp/golang.tar.gz" | sha256sum --check \
  && tar -C /usr/local -xzf /tmp/golang.tar.gz \
  && rm -f /tmp/golang.tar.gz
ENV PATH "/usr/local/go/bin:${PATH}"
ENV PATH "${GOPATH}/bin:${PATH}"

# CI uploader, to send junit to ci-visibility during CI tests
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${CI_UPLOADER_VERSION}/datadog-ci_linux-x64 --output "/usr/local/bin/datadog-ci" && \
    echo "${CI_UPLOADER_SHA} /usr/local/bin/datadog-ci" | sha256sum --check && \
    chmod +x /usr/local/bin/datadog-ci

# install clang from the website since the package manager can change at any time
RUN wget "https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz" -O /tmp/clang.tar.xz  -o /dev/null \
  && echo "54ec30358afcc9fb8aa74307db3046f5187f9fb89fb37064cdde906e062ebf36  /tmp/clang.tar.xz" | sha256sum --check \
  && mkdir -p /opt/clang \
  && tar xf /tmp/clang.tar.xz --no-same-owner -C /opt/clang --strip-components=1 \
  && rm -f /tmp/clang.tar.xz
ENV PATH "/opt/clang/bin:${PATH}"

RUN wget "https://github.com/Kitware/CMake/releases/download/v3.30.2/cmake-3.30.2-linux-x86_64.tar.gz" -O /tmp/cmake.tar.gz -o /dev/null \
  && echo "cdd7fb352605cee3ae53b0e18b5929b642900e33d6b0173e19f6d4f2067ebf16  /tmp/cmake.tar.gz" | sha256sum --check \
  && mkdir -p /opt/cmake \
  && tar xf /tmp/cmake.tar.gz --no-same-owner -C /opt/cmake --strip-components=1 \
  && rm -f /tmp/cmake.tar.gz
ENV PATH "/opt/cmake/bin:${PATH}"

RUN git clone https://github.com/brycekahle/dwarves.git \
  && pushd dwarves \
  && git reset --hard 525a600eb26609176de8eda8fd70ad1fc096fe0a \
  && mkdir build \
  && cd build \
  && cmake -D__LIB=lib ..
  && make install \
  && echo "/usr/local/lib" > /etc/ld.so.conf.d/pahole.conf \
  && ldconfig \
  && popd \
  && rm -rf dwarves
ENV PATH "/usr/local/bin:${PATH}"
