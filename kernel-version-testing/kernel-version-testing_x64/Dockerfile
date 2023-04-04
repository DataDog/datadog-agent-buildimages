FROM ubuntu:xenial

ARG DEBIAN_FRONTEND=noninteractive
ARG KERNEL_EXTRA_CONFIG_VERSION=0.1

RUN apt-get update && apt-get install -y --no-install-recommends \
    bison \
    flex \
    build-essential \
    libssl-dev \
    libelf-dev \
    bc \
    curl \
    git \
    xz-utils \
    debootstrap \
    wget \
    qemu-utils \
    fakeroot \
    rsync \
    python3 \
    libdw-dev \
    cmake \
    kmod \
    cpio \
    ca-certificates \
    openssh-client

# Install pahole
RUN git -c http.sslVerify=false clone --recurse-submodules https://github.com/acmel/dwarves.git /dwarves
WORKDIR "/dwarves"
RUN git config http.sslVerify "false"
RUN git checkout v1.22
RUN mkdir build
WORKDIR "/dwarves/build"
RUN cmake -D__LIB=lib -DCMAKE_INSTALL_PREFIX=/usr/ ..
RUN make install

WORKDIR "/"
RUN rm -r dwarves

COPY ./kernel-version-testing/extra.config-$KERNEL_EXTRA_CONFIG_VERSION /
COPY ./entrypoint-sysprobe.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
