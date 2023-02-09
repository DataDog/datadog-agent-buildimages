FROM debian:bullseye

ARG DEBIAN_FRONTEND=noninteractive
ENV AWSCLI_VERSION=1.25.55
ENV INVOKE_VERSION=1.6.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    clang \
	curl \
	git \
    libelf-dev \
    llvm \
	ninja-build \
	python3 \
	python3-pip \
	xz-utils \
    zlib1g-dev

RUN git clone --recurse-submodules https://github.com/libbpf/bpftool.git
RUN make -C bpftool/src V=1 install

RUN pip install awscli==${AWSCLI_VERSION} invoke==${INVOKE_VERSION}
