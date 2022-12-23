FROM debian:buster

ARG KERNEL_EXTRA_CONFIG_VERSION
ARG DEBIAN_FRONTEND=noninteractive

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
    cmake

# Install pahole
RUN mkdir /dwarve
RUN git config --global http.sslverify false
RUN git clone https://github.com/acmel/dwarves.git /dwarves
WORKDIR "/dwarves"
RUN git checkout v1.22
RUN mkdir build
WORKDIR "/dwarves/build"
RUN cmake -D__LIB=lib -DCMAKE_INSTALL_PREFIX=/usr/ ..
RUN make install

# Prepare environement for kernel compilation
WORKDIR "/root"
RUN mkdir kernel-packages
RUN wget https://dd-agent-omnibus.s3.amazonaws.com/kernel-version-testing/kernel-custom-repo.tar.gz -O kernel-custom-repo.tar.gz
RUN tar -xzf kernel-custom-repo.tar.gz
RUN rm kernel-custom-repo.tar.gz
COPY ./kernel-version-testing/extra.config-$KERNEL_EXTRA_CONFIG_VERSION ./
COPY ./kernel-version-testing/tags-commits ./

# This is used to synchronize the expected config version
RUN echo $KERNEL_EXTRA_CONFIG_VERSION > config.version

COPY ./entrypoint-sysprobe.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
