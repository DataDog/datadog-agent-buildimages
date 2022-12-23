FROM debian:buster

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
    cpio

# Install pahole
RUN git -c http.sslVerify=false clone --recurse-submodules https://github.com/acmel/dwarves.git /dwarves
WORKDIR "/dwarves"
RUN git config http.sslVerify "false"
RUN git checkout v1.22
RUN mkdir build
WORKDIR "/dwarves/build"
RUN cmake -D__LIB=lib -DCMAKE_INSTALL_PREFIX=/usr/ ..
RUN make install

# Prepare environement for kernel compilation
WORKDIR "/"
RUN wget -q --no-check-certificate https://dd-agent-omnibus.s3.amazonaws.com/kernel-version-testing/kernel-custom-repo.tar.gz -O kernel-custom-repo.tar.gz
RUN tar -xzf kernel-custom-repo.tar.gz -C /root
RUN rm kernel-custom-repo.tar.gz
WORKDIR "/root"
COPY ./kernel-version-testing/extra.config-$KERNEL_EXTRA_CONFIG_VERSION ./
COPY ./kernel-version-testing/tags-commits ./
# This is used to synchronize the expected config version
RUN echo $KERNEL_EXTRA_CONFIG_VERSION > config.version

COPY ./entrypoint-sysprobe.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
