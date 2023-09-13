FROM debian:bullseye

ARG DEBIAN_FRONTEND=noninteractive
ENV AWSCLI_VERSION=1.25.55
ENV INVOKE_VERSION=2.2.0
ENV OYAML_VERSION=1.0

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

RUN git clone --recurse-submodules https://github.com/libbpf/bpftool.git
WORKDIR bpftool
RUN git reset --hard cb3deb23d34abdb33f6bcc5fadeee676e538e2ff
COPY btf-gen/Makefile.patch ./
RUN git apply Makefile.patch

RUN make -C src/ V=1 install

RUN pip install awscli==${AWSCLI_VERSION} invoke==${INVOKE_VERSION} oyaml==${OYAML_VERSION}
