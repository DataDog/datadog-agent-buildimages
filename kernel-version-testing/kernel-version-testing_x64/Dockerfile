FROM ubuntu:xenial AS base

ARG DEBIAN_FRONTEND=noninteractive
ARG KERNEL_EXTRA_CONFIG_VERSION=0.1

# Install system dependencies in a single layer
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
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# FROM base AS pahole-builder
FROM base AS pahole-builder
RUN git -c http.sslVerify=false clone --recurse-submodules https://github.com/acmel/dwarves.git /dwarves \
    && cd /dwarves \
    && git config http.sslVerify "false" \
    && git checkout v1.22 \
    && mkdir build \
    && cd /dwarves/build \
    && cmake -D__LIB=lib -DCMAKE_INSTALL_PREFIX=/usr/ .. \
    && make install

# Final image
FROM base

# Copy built pahole from builder
COPY --from=pahole-builder /usr/bin/pahole /usr/bin/pahole
COPY --from=pahole-builder /usr/lib/libdwarves* /usr/lib/

# Add configuration and entrypoint
COPY ./kernel-version-testing/extra.config-$KERNEL_EXTRA_CONFIG_VERSION /
COPY ./entrypoint-sysprobe.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
