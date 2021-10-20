FROM ubuntu as CURL_GETTER
RUN apt-get update && apt-get install -y wget
RUN wget https://github.com/moparisthebest/static-curl/releases/download/v7.79.1/curl-amd64
ENV CACERT_BUNDLE_VERSION=2021-09-30
RUN wget https://curl.se/ca/cacert-${CACERT_BUNDLE_VERSION}.pem -O /cacert.pem

# We use OpenSUSE 42.3, which is based on SLES 12.3
FROM registry.ddbuild.io/images/mirror/opensuse/archive:42.3

# Build Args
ARG GIMME_GO_VERSION=1.16.7
ARG DD_PIP_VERSION=19.1
ARG DD_SETUPTOOLS_VERSION=44.1.1
ARG DD_SETUPTOOLS_VERSION_PY3=52.0.0
ARG IBM_MQ_VERSION=9.2.2.0
ARG CMAKE_VERSION=3.14.4
ARG CLANG_VERSION=8.0.0
ARG DD_TARGET_ARCH=x64

# Environment
ENV GOPATH /go
ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV DD_PIP_VERSION $DD_PIP_VERSION
ENV DD_SETUPTOOLS_VERSION $DD_SETUPTOOLS_VERSION
# TODO: this wasn't there in builders
ENV DD_SETUPTOOLS_VERSION_PY3 $DD_SETUPTOOLS_VERSION_PY3
ENV IBM_MQ_VERSION $IBM_MQ_VERSION
ENV CMAKE_VERSION $CMAKE_VERSION
ENV CLANG_VERSION $CLANG_VERSION
# TODO: this was miniconda2 in builders
ENV CONDA_PATH /root/miniconda3
ENV DD_TARGET_ARCH $DD_TARGET_ARCH
ENV POSTGRESQL_VERSION=9.0.3-1.6.1
ENV PATH="/opt/datadog/bin:${PATH}"

# Add our profile to the image that adds RVM and Conda to environment
COPY ./suse-x64/ddprofile.sh /etc/profile.d/

# Disable repositories with non-oss software
RUN rm /etc/zypp/repos.d/NON*
# TODO: seems that libffi-devel is provided by libffi-devel-gcc5,
# but there's no gcc5; will this work?
RUN zypper clean -a && zypper --non-interactive refresh && \
    zypper --non-interactive install \
      bison bzip2 curl gawk gcc48 gcc48-c++ gdbm-devel gettext-tools git \
      gettext-runtime less libffi-devel libtool libcurl-devel libexpat-devel \
      libopenssl1_0_0 libopenssl-devel make openssl perl perl-Module-Build \
      patch procps rsync readline-devel rpm-build sqlite3-devel \
      tar xz which zlib-devel

# Remove all zypper repositories in the image to prevent errors when using zypper.
RUN zypper clean -a && rm -rf /etc/zypp/repos.d/*

# Make gcc 4.8 the default one
RUN ln -sfn /usr/bin/gcc-4.8 /usr/bin/gcc
RUN ln -sfn /usr/bin/g++-4.8 /usr/bin/g++

# Update curl with a statically linked binary
COPY --from=CURL_GETTER /cacert.pem /etc/ssl/certs/ca-certificates.crt
COPY --from=CURL_GETTER /curl-amd64 /opt/datadog/bin/curl
RUN chmod +x /opt/datadog/bin/curl

# Add postgresql-devel + dependencies packages, needed for psycopg2.
# Note: These packages were copied from the https://ftp5.gwdg.de/pub/opensuse/discontinued/distribution/11.4/repo/oss/ mirror.
# We don't know if we can fully trust the packages from this repository, but we can't use the official repositories anymore (see note above).
RUN curl -sL -O https://dd-agent-omnibus.s3.amazonaws.com/postgres/libecpg6-${POSTGRESQL_VERSION}.x86_64.rpm \
    && curl -sL -O https://dd-agent-omnibus.s3.amazonaws.com/postgres/libpq5-${POSTGRESQL_VERSION}.x86_64.rpm \
    && curl -sL -O https://dd-agent-omnibus.s3.amazonaws.com/postgres/postgresql-devel-${POSTGRESQL_VERSION}.x86_64.rpm \
    && zypper --non-interactive install ./libecpg6-${POSTGRESQL_VERSION}.x86_64.rpm ./libpq5-${POSTGRESQL_VERSION}.x86_64.rpm ./postgresql-devel-${POSTGRESQL_VERSION}.x86_64.rpm \
    && rm ./libecpg6-${POSTGRESQL_VERSION}.x86_64.rpm ./libpq5-${POSTGRESQL_VERSION}.x86_64.rpm ./postgresql-devel-${POSTGRESQL_VERSION}.x86_64.rpm

# Gimme
RUN curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
RUN chmod +x /bin/gimme
RUN gimme $GIMME_GO_VERSION
COPY ./gobin.sh /etc/profile.d/

# Add systemd headers
COPY ./rpm-headers/systemd /usr/include/systemd

# IBM MQ
RUN mkdir -p /opt/mqm \
    && curl "https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqdev/redist/${IBM_MQ_VERSION}-IBM-MQC-Redist-LinuxX64.tar.gz" -o /tmp/mq_client.tar.gz \
    && tar -C /opt/mqm -xf /tmp/mq_client.tar.gz \
    && rm -rf /tmp/mq_client.tar.gz

# CONDA
COPY ./setup_python.sh /setup_python.sh
RUN ./setup_python.sh
COPY ./conda.sh /etc/profile.d/conda.sh
ENV PATH "${CONDA_PATH}/bin:${PATH}"
ENV PKG_CONFIG_LIBDIR "${PKG_CONFIG_LIBDIR}:${CONDA_PATH}/lib/pkgconfig"

# RVM
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/*
RUN rm -rf /gpg-keys
RUN curl -sSL https://get.rvm.io | bash -s stable
RUN bash -l -c "rvm autolibs disable" # do not try to fetch requirements from system repos
RUN bash -l -c "rvm install 2.7 --with-openssl-dir=${CONDA_PATH} && rvm cleanup all"
RUN bash -l -c "gem install bundler --no-document"

# CMake
RUN set -ex \
    && curl -sL -o cmake.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
    && mkdir -p /opt/cmake/ \
    && sh cmake.sh --skip-license --prefix=/opt/cmake \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && rm cmake.sh

# Install clang and llvm version 8
# Using build for sles11 because the versions built for other distros target glibcs that are too new to be used from this image
RUN curl -LO https://releases.llvm.org/${CLANG_VERSION}/clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz && \
    tar -xf clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz --no-same-owner --strip 1 -kC /usr/ && \
    rm clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz

# To build the EBPF code we need kernel headers for Linux 4.9
RUN curl -Sl -O https://dd-agent-omnibus.s3.amazonaws.com/kernel-4.9-headers-rpm-x64.tgz && \
    tar xf kernel-4.9-headers-rpm-x64.tgz --no-same-owner --strip 1 -C /usr && \
    rm kernel-4.9-headers-rpm-x64.tgz

# Rust is needed to compile the cryptography python lib
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.41.0
ENV PATH "~/.cargo/bin:${PATH}"

# Entrypoint
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# create the agent build folder within $GOPATH
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

ENTRYPOINT ["/entrypoint.sh"]
