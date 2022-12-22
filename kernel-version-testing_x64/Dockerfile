FROM debian:buster

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
RUN mkdir /dwarves
RUN git clone https://github.com/acmel/dwarves.git -O /dwarves
WORKDIR "/dwarves"
RUN git checkout v1.22
RUN mkdir build
WORKDIR "/dwarves/build"
RUN cmake -D__LIB=lib -DCMAKE_INSTALL_PREFIX=/usr/ ..
RUN make install

# Prepare environement for kernel compilation
RUN mkdir /kernel-packages
RUN wget https://dd-agent-omnibus.s3.amazonaws.com/kernel-version-testing/kernel-custom-repo.tar.gz -O /root/kernel-custom-repo.tar.gz
WORKDIR "/root"
RUN tar -xzf kernel-custom-repo.tar.gz
RUN rm kernel-custom-repo.tar.gz

COPY ./entrypoint-sysprobe.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
