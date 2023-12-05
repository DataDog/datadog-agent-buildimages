FROM ubuntu:22.04

ARG CTNG_VERSION=1.26.0
ENV CONDA_PATH /root/miniconda3
ARG IBM_MQ_VERSION=9.2.4.0
ARG IBM_MQ_SHA256="d0d583eba72daf20b3762976f8831c2e23150ace90509520e12f8cda5b5bdb49"

ENV DD_TARGET_ARCH x64

RUN apt update -qy && apt install -y \
    wget xz-utils gpg build-essential flex texinfo unzip \
    help2man file gawk libtool-bin bison libncurses-dev \
    python-is-python3

COPY linux-glibc-2.17-x64/config-x86_64-unknown-gnu-linux-glibc2.17 /build/crosstool-ng-${CTNG_VERSION}/.config
COPY linux-glibc-2.17-x64/toolchain.cmake /opt/cmake/x86_64-unknown-linux-gnu.toolchain.cmake

RUN apt update -y && apt install -y git cmake curl fakeroot procps bzip2 \
    pkg-config libssl-dev libcurl4-openssl-dev libexpat-dev libpq-dev libz-dev \
    rpm tar gettext autopoint autoconf clang golang-1.20 golang-1.20-go libtool-bin \
    pkg-config flex meson selinux-basics squashfs-tools gpg zstd

RUN git config --global user.email "package@datadoghq.com"
RUN git config --global user.name "Bits"

RUN cd /build && \
    wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-${CTNG_VERSION}.tar.xz && \
    gpg --keyserver pgp.surfnet.nl --recv-keys 1F30EF2E && \
    wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-${CTNG_VERSION}.tar.xz.sig && \
    gpg --verify crosstool-ng-${CTNG_VERSION}.tar.xz.sig && \
    tar xf crosstool-ng-${CTNG_VERSION}.tar.xz && \
    cd /build/crosstool-ng-${CTNG_VERSION} && \
    ./configure --enable-local && make -j$(nproc) && \
    export CT_ALLOW_BUILD_AS_ROOT_SURE=yes && \
    ./ct-ng upgradeconfig && ./ct-ng build && \
    mv /root/x-tools/x86_64-unknown-linux-gnu/ /opt/toolchains/ && \
    rm -rf /build

# IBM MQ
RUN mkdir -p /opt/mqm \
    && curl "https://s3.amazonaws.com/dd-agent-omnibus/ibm-mq-backup/${IBM_MQ_VERSION}-IBM-MQC-Redist-LinuxX64.tar.gz" -o /tmp/mq_client.tar.gz \
    && echo "${IBM_MQ_SHA256}  /tmp/mq_client.tar.gz" | sha256sum --check \
    && tar -C /opt/mqm -xf /tmp/mq_client.tar.gz \
    && rm -rf /tmp/mq_client.tar.gz

# CONDA
COPY python-packages-versions.txt setup_python.sh requirements.txt requirements-py2.txt /
COPY requirements /requirements

RUN grep -v return /root/.bashrc >> /root/newbashrc && cp /root/newbashrc /root/.bashrc

RUN ./setup_python.sh
ENV PATH "${CONDA_PATH}/condabin:${PATH}"

# RVM
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/*
RUN rm -rf /gpg-keys
RUN curl -sSL -o get-rvm.sh https://raw.githubusercontent.com/rvm/rvm/1.29.12/binscripts/rvm-installer \
    && echo "fea24461e98d41528d6e28684aa4c216dbe903869bc3fcdb3493b6518fae2e7e  get-rvm.sh" | sha256sum --check \
    && bash get-rvm.sh stable --version 1.29.12 \
    && echo "d2de0b610ee321489e5c673fe749e13be8fb34c0aa08a74446d87f95a17de730  /usr/local/rvm/bin/rvm" | sha256sum --check \
    && rm get-rvm.sh
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.7 --with-openssl-dir=${CONDA_PATH} && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --no-document"
RUN /bin/bash -l -c "gem install fpm --no-document"
RUN echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc

RUN echo "umask 0022" >> /root/.bashrc
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

ENV PATH=/usr/lib/go-1.20/bin:$PATH
ENV PATH=/opt/toolchains/bin:$PATH

# Ensure pkg-config will not look into the system directories
ENV PKG_CONFIG_LIBDIR ""

ENTRYPOINT ["/entrypoint.sh"]
