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
    python3 \
    python3-pip \
    xz-utils

COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

RUN git clone --recurse-submodules https://github.com/brycekahle/bpftool.git
WORKDIR bpftool
RUN git reset --hard 1c25a06e38e9ff848ba66622d08a0147ed9ddc2e
COPY btf-gen/Makefile.patch ./
RUN git apply Makefile.patch

RUN make -C src/ V=1 install

COPY requirements ./
RUN pip install -r btf-gen.txt
