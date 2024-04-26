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
    python3 \
    python3-pip \
    unzip \
    wget \
    xz-utils

COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

RUN git clone --recurse-submodules https://github.com/libbpf/bpftool.git
WORKDIR bpftool
RUN git reset --hard cb3deb23d34abdb33f6bcc5fadeee676e538e2ff
COPY btf-gen/Makefile.patch ./
RUN git apply Makefile.patch

RUN make -C src/ V=1 install

# install ninja from website
RUN wget https://github.com/ninja-build/ninja/releases/download/v1.12.0/ninja-linux.zip -O /tmp/ninja.zip -o /dev/null
RUN echo "ddc96efa3c7c9d41de733d15e2eda07a8a212555cb43f35d727e080d2ca687ab  /tmp/ninja.zip" | sha256sum --check
RUN mkdir -p /opt/ninja
RUN unzip /tmp/ninja.zip -d /opt/ninja
ENV PATH "/opt/ninja:${PATH}"

COPY requirements ./
RUN pip install -r btf-gen.txt
