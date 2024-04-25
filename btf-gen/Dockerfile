FROM debian:bullseye

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    clang \
    curl \
    git \
    libcap-dev \
    libelf-dev \
    libz-dev \
    llvm \
    llvm-dev \
    lld \
    ninja-build \
    pigz \
    python3 \
    python3-pip \
    xz-utils \
    zstd

COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

RUN git clone --recurse-submodules https://github.com/libbpf/bpftool.git
WORKDIR bpftool
RUN git reset --hard cb3deb23d34abdb33f6bcc5fadeee676e538e2ff
COPY btf-gen/Makefile.patch ./
RUN git apply Makefile.patch

RUN make -C src/ V=1 install

COPY requirements ./
RUN pip install -r btf-gen.txt
