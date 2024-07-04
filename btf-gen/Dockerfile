FROM ubuntu:22.04

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

RUN git clone https://github.com/libbpf/bpftool.git
WORKDIR bpftool

# Pinned to the latest version to avoid having bpftool change under us when updating images.
# Can be updated to a newer version if needed, no restrictions on the specific version
# for now.
RUN git reset --hard 77a72987353fcae8ce330fd87d4c7afb7677a169 && \
    git submodule update --init

RUN make -C src/ V=1 install

COPY requirements ./
RUN pip install -r btf-gen.txt
