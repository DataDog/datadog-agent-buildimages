FROM debian:bullseye

ARG DEBIAN_FRONTEND=noninteractive
ARG GO_VERSION
ARG GO_SHA256_LINUX_ARM64
ARG DD_TARGET_ARCH=aarch64
ARG CI_UPLOADER_VERSION=2.38.1
ARG CI_UPLOADER_SHA=90ee346ea639e2d70a45b70e2d1491e5749099665df06a2e6d80ddc9fd90fe0c
ARG CLANG_VERSION=19.1.0-rc4
ARG CLANG_SHA256SUM=b69713a45f5f2bfc35a0ccee1e85d105558e1fe4298efacdd18e755a4dac7449
ARG LLVM_SHA256SUM=b3ed818e6cc8c8b20734106a908eee1012b682e02f9e383624fe2c676700c691
ARG CLANG_CMAKE_SHA256SUM=3133936cc4a5dfc4bdb629e649d9d915b51a41b2941af45dc41972fd81669dfc

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils && apt-get dist-upgrade -y && apt-get install -y --no-install-recommends \
        bison \
        curl \
        flex \
        g++ \
        gcc \
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

RUN wget "https://github.com/Kitware/CMake/releases/download/v3.30.2/cmake-3.30.2-linux-aarch64.tar.gz" -O /tmp/cmake.tar.gz -o /dev/null \
  && echo "d18f50f01b001303d21f53c6c16ff12ee3aa45df5da1899c2fe95be7426aa026  /tmp/cmake.tar.gz" | sha256sum --check \
  && mkdir -p /opt/cmake \
  && tar xf /tmp/cmake.tar.gz --no-same-owner -C /opt/cmake --strip-components=1 \
  && rm -f /tmp/cmake.tar.gz
ENV PATH "/opt/cmake/bin:${PATH}"

RUN mkdir llvm-project \
  && cd llvm-project \
  && wget "https://github.com/llvm/llvm-project/releases/download/llvmorg-${CLANG_VERSION}/clang-${CLANG_VERSION}.src.tar.xz" -O clang.src.tar.xz \
  && wget "https://github.com/llvm/llvm-project/releases/download/llvmorg-${CLANG_VERSION}/llvm-${CLANG_VERSION}.src.tar.xz" -O llvm.src.tar.xz \
  && wget "https://github.com/llvm/llvm-project/releases/download/llvmorg-${CLANG_VERSION}/cmake-${CLANG_VERSION}.src.tar.xz" -O cmake.src.tar.xz \
  && echo -e "${CLANG_SHA256SUM} clang.src.tar.xz\n${LLVM_SHA256SUM} llvm.src.tar.xz\n${CLANG_CMAKE_SHA256SUM} cmake.src.tar.xz" | sha256sum --check \
  && mkdir clang llvm cmake \
  && tar xf clang.src.tar.xz --strip-components=1 --no-same-owner -C clang \
  && tar xf llvm.src.tar.xz --strip-components=1 --no-same-owner -C llvm \
  && tar xf cmake.src.tar.xz --strip-components=1 --no-same-owner -C cmake \
  && mkdir build \
  && cd build \
  && cmake -DLLVM_ENABLE_PROJECTS=clang \
    -DLLVM_TARGETS_TO_BUILD="AArch64;BPF" \
    -DCMAKE_INSTALL_PREFIX=/opt/clang \
    -G "Ninja" \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DLLVM_BUILD_TOOLS=ON \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
    -DLLVM_ENABLE_BINDINGS=OFF \
    -DLLVM_PARALLEL_COMPILE_JOBS=4 \
    -DLLVM_PARALLEL_LINK_JOBS=4 \
    -DLLVM_ENABLE_UNWIND_TABLES=OFF \
    -DLLVM_DISTRIBUTION_COMPONENTS="clang" \
    -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON \
    -DLLVM_DEFAULT_TARGET_TRIPLE="aarch64-unknown-linux-gnu" \
    ../llvm \
  && cmake --build . --target install \
  && cp bin/llc /opt/clang/bin/llc \
  && cp bin/llvm-dis /opt/clang/bin/llvm-dis \
  && cd ../.. \
  && rm -rf llvm-project
ENV PATH "/opt/clang/bin:${PATH}"

RUN git clone https://github.com/brycekahle/dwarves.git \
  && cd dwarves \
  && git reset --hard 525a600eb26609176de8eda8fd70ad1fc096fe0a \
  && mkdir build \
  && cd build \
  && cmake -D__LIB=lib .. \
  && make install \
  && echo "/usr/local/lib" > /etc/ld.so.conf.d/pahole.conf \
  && ldconfig \
  && cd ../.. \
  && rm -rf dwarves
ENV PATH "/usr/local/bin:${PATH}"
