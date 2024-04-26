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

# install bpftool from website
RUN wget https://github.com/libbpf/bpftool/releases/download/v7.4.0/bpftool-v7.4.0-amd64.tar.gz -O /tmp/bpftool.tar.gz -o /dev/null \
    && echo "68862a7038a269e1d4af5fed53d2b4d763f1cd82a96caa49b76596453bae0c3e  /tmp/bpftool.tar.gz" | sha256sum --check \
    && mkdir -p /opt/bpftool \
    && tar xf /tmp/bpftool.tar.gz --no-same-owner -C /opt/bpftool \
    && chmod +x /opt/bpftool/bpftool \
    && rm -f /tmp/bpftool.tar.gz
ENV PATH "/opt/bpftool:${PATH}"

# install ninja from website
RUN wget https://github.com/ninja-build/ninja/releases/download/v1.12.0/ninja-linux.zip -O /tmp/ninja.zip -o /dev/null \
    && echo "ddc96efa3c7c9d41de733d15e2eda07a8a212555cb43f35d727e080d2ca687ab  /tmp/ninja.zip" | sha256sum --check \
    && mkdir -p /opt/ninja \
    && unzip /tmp/ninja.zip -d /opt/ninja \
    && rm -f /tmp/ninja.zip
ENV PATH "/opt/ninja:${PATH}"

COPY requirements ./
RUN pip install -r btf-gen.txt
