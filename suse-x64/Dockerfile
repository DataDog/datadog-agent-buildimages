FROM ubuntu as CURL_GETTER
RUN apt-get update && apt-get install -y wget
ENV CURL_VERSION=7.79.1
ENV CURL_SHA256="0a89440848db3ba21d38b93b450d90fb84d4d0fa5562aa9c6933070b0eddc960"
ENV CACERT_BUNDLE_VERSION=2023-01-10
ENV CACERT_BUNDLE_SHA256="fb1ecd641d0a02c01bc9036d513cb658bbda62a75e246bedbc01764560a639f0"
RUN apt-get update && apt-get install -y wget
RUN wget https://github.com/moparisthebest/static-curl/releases/download/v${CURL_VERSION}/curl-amd64
RUN echo "${CURL_SHA256}  curl-amd64" | sha256sum --check
RUN wget https://curl.se/ca/cacert-${CACERT_BUNDLE_VERSION}.pem -O /cacert.pem
RUN echo "${CACERT_BUNDLE_SHA256}  /cacert.pem" | sha256sum --check

# We use OpenSUSE 42.1, which is based on SLES 12.1
FROM opensuse/archive:42.1

# Build Args
ARG GIMME_GO_VERSION=1.19.7
ARG IBM_MQ_VERSION=9.2.4.0
ARG IBM_MQ_SHA256="d0d583eba72daf20b3762976f8831c2e23150ace90509520e12f8cda5b5bdb49"
ARG CMAKE_VERSION=3.23.0
ARG CMAKE_SHA256="5eaf3ded8255b3d149c7aad68c473f01c2345dce872e03c92f2e9c0185dfa75a"
ARG CLANG_VERSION=8.0.0
ARG CLANG_SHA256="7e2846ff60c181d1f27d97c23c25a2295f5730b6d88612ddd53b4cbb8177c4b9"
ARG DD_TARGET_ARCH=x64
ARG RUST_VERSION=1.60.0
ARG RUSTC_SHA256="3dc5ef50861ee18657f9db2eeb7392f9c2a6c95c90ab41e45ab4ca71476b4338"
ARG RUSTUP_VERSION=1.24.3
ARG RUSTUP_SHA256="3dc5ef50861ee18657f9db2eeb7392f9c2a6c95c90ab41e45ab4ca71476b4338"
ARG GCC_VERSION=10.4.0
ARG GCC_SHA256=ab1974017834430de27fd803ade4389602a7d6ca1362496c57bef384b2a4cb07

# Environment
ENV GOPATH /go
ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV IBM_MQ_VERSION $IBM_MQ_VERSION
ENV IBM_MQ_SHA256 $IBM_MQ_SHA256
ENV CMAKE_VERSION $CMAKE_VERSION
ENV CMAKE_SHA256 $CMAKE_SHA256
ENV CLANG_VERSION $CLANG_VERSION
ENV CLANG_SHA256 $CLANG_SHA256
ENV CONDA_PATH /root/miniconda3
ENV DD_TARGET_ARCH $DD_TARGET_ARCH
ENV RUST_VERSION $RUST_VERSION
ENV RUSTC_SHA256 $RUSTC_SHA256
ENV GCC_VERSION $GCC_VERSION

ENV PATH="/opt/datadog/bin:${PATH}"

# Add our profile to the image that adds RVM and Conda to environment
COPY ./suse-x64/ddprofile.sh /etc/profile.d/
# Add /etc/profile to the image (taken from 42.3 image) -- it is missing from 42.1 the image
COPY ./suse-x64/profile /etc/profile

# Store cpu core number
RUN export cpu_count=$(grep process /proc/cpuinfo | wc -l)

# Disable repositories with non-oss software
RUN rm /etc/zypp/repos.d/*non*

# Change location of the OSS-Update repo
# Its former location was http://download.opensuse.org/update/42.1/,
# its new location is http://download.opensuse.org/update/leap/42.1/oss/
RUN sed -i "s/baseurl=http:\/\/download.opensuse.org\/update\/42.1\//baseurl=http:\/\/download.opensuse.org\/update\/leap\/42.1\/oss\//" /etc/zypp/repos.d/oss-update.repo

# Install all distro-level dependencies
RUN zypper clean -a && zypper --non-interactive refresh && \
    zypper --non-interactive install \
      bison bzip2 curl flex gawk gcc48 gcc48-c++ gdbm-devel gettext-tools git \
      gettext-runtime less libffi-devel libtool libcurl-devel libexpat-devel \
      libopenssl1_0_0 libopenssl-devel make openssl perl perl-Module-Build \
      patch postgresql-devel procps rsync readline-devel rpm-build sqlite3-devel \
      tar xz which zlib-devel java mozilla-nspr-devel mozilla-nss-devel popt-devel \ 
      libbeecrypt-devel file-magic file-devel libarchive-devel libdb-4_8 libdb-4_8-devel

# Remove all zypper repositories in the image to prevent errors when using zypper.
# While the repos are available right now, they might go out of order in the future,
# which could then make builds fail. We shouldn't be installing any packages
# later on anyway.
RUN zypper clean -a && rm -rf /etc/zypp/repos.d/*

# Make gcc 4.8 the default one
RUN ln -sfn /usr/bin/gcc-4.8 /usr/bin/gcc
RUN ln -sfn /usr/bin/g++-4.8 /usr/bin/g++

# Update curl with a statically linked binary
COPY --from=CURL_GETTER /cacert.pem /etc/ssl/certs/ca-certificates.crt
COPY --from=CURL_GETTER /curl-amd64 /opt/datadog/bin/curl
RUN chmod +x /opt/datadog/bin/curl

# Gimme
RUN curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/v1.5.4/gimme
RUN echo "03b295636d4e22870b6f6e9bc06a71d65311ae90d3d48cbc7071f82dd5837fbc  /bin/gimme" | sha256sum --check
RUN chmod +x /bin/gimme
RUN gimme $GIMME_GO_VERSION
COPY ./gobin.sh /etc/profile.d/

# Add systemd headers
COPY ./rpm-headers/systemd /usr/include/systemd

# IBM MQ
RUN mkdir -p /opt/mqm \
    && curl "https://s3.amazonaws.com/dd-agent-omnibus/ibm-mq-backup/${IBM_MQ_VERSION}-IBM-MQC-Redist-LinuxX64.tar.gz" -o /tmp/mq_client.tar.gz \
    && echo "${IBM_MQ_SHA256}  /tmp/mq_client.tar.gz" | sha256sum --check \
    && tar -C /opt/mqm -xf /tmp/mq_client.tar.gz \
    && rm -rf /tmp/mq_client.tar.gz

# CONDA
COPY ./python-packages-versions.txt /python-packages-versions.txt
COPY ./setup_python.sh /setup_python.sh
COPY ./requirements.txt ./requirements-py2.txt /
RUN ./setup_python.sh
ENV PATH "${CONDA_PATH}/condabin:${PATH}"
ENV PKG_CONFIG_LIBDIR "${PKG_CONFIG_LIBDIR}:${CONDA_PATH}/lib/pkgconfig"

# RVM
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/*
RUN rm -rf /gpg-keys
RUN curl -sSL -o get-rvm.sh https://raw.githubusercontent.com/rvm/rvm/1.29.12/binscripts/rvm-installer \
    && echo "fea24461e98d41528d6e28684aa4c216dbe903869bc3fcdb3493b6518fae2e7e  get-rvm.sh" | sha256sum --check \
    && bash get-rvm.sh stable --version 1.29.12 \
    && echo "d2de0b610ee321489e5c673fe749e13be8fb34c0aa08a74446d87f95a17de730  /usr/local/rvm/bin/rvm" | sha256sum --check \
    && rm get-rvm.sh
RUN bash -l -c "rvm autolibs disable" # do not try to fetch requirements from system repos
RUN bash -l -c "rvm install -j ${cpu_count} 2.7 --with-openssl-dir=${CONDA_PATH} && rvm cleanup all"
RUN bash -l -c "gem install bundler --no-document"

# CMake
RUN set -ex \
    && curl -sL -o cmake.sh "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh" \
    && echo "${CMAKE_SHA256}  cmake.sh" | sha256sum --check \
    && mkdir -p /opt/cmake/ \
    && sh cmake.sh --skip-license --prefix=/opt/cmake \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && rm cmake.sh

# Install clang and llvm version 8
# Using build for sles11 because the versions built for other distros target glibcs that are too new to be used from this image
RUN curl -LO "https://releases.llvm.org/${CLANG_VERSION}/clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz" \
    && echo "${CLANG_SHA256}  clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz" | sha256sum --check \
    && tar -xf "clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz" --no-same-owner --strip 1 -kC /usr/ \
    && rm "clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz"

# To build the EBPF code we need kernel headers for Linux 4.9
RUN curl -Sl -O https://dd-agent-omnibus.s3.amazonaws.com/kernel-4.9-headers-rpm-x64.tgz \
    && echo "1657ffa995654bc96405d4dbce0b17a55cd1eabd19479bc1611b0cb4f3c01fcc  kernel-4.9-headers-rpm-x64.tgz" | sha256sum --check \
    && rm kernel-4.9-headers-rpm-x64.tgz

# Rust is needed to compile some python libs
RUN curl -sSL -o rustup-init https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init \
    && echo "${RUSTUP_SHA256}  rustup-init" | sha256sum --check \
    && chmod +x ./rustup-init \
    && ./rustup-init -y --profile minimal --default-toolchain ${RUST_VERSION} \
    && echo "${RUSTC_SHA256}  $HOME/.cargo/bin/rustc" | sha256sum --check \
    && rm ./rustup-init
ENV PATH "~/.cargo/bin:${PATH}"

# gcc
COPY ./build-gcc.sh /build-gcc.sh
RUN chmod +x /build-gcc.sh \
    && /build-gcc.sh \
    && rm /build-gcc.sh

RUN curl -sL -o /tmp/rpm-4.14.3.tar.bz2 http://ftp.rpm.org/releases/rpm-4.14.x/rpm-4.14.3.tar.bz2 \
    && cd /tmp \
    && echo "13711268181a6e201eb9d4eb06384a7fcc42dcc6c9057a62c53472cfc5ba44b5  rpm-4.14.3.tar.bz2" | sha256sum --check \
    && tar -xjf /tmp/rpm-4.14.3.tar.bz2 \
    && cd rpm-4.14.3/ \
    && ./configure --with-posixmutexes --with-external-db --without-lua CPPFLAGS="-I/usr/include/nspr4 -I/usr/include/nss3 -I/usr/include/db4"\
    && make -j ${cpu_count} \
    && make install \
    && ldconfig

# Rebuild RPM database with the new rpm
RUN mkdir -p /usr/local/var/lib/rpm \
    && cp /var/lib/rpm/Packages /usr/local/var/lib/rpm/Packages \
    && /usr/local/bin/rpm --rebuilddb
# Entrypoint
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# create the agent build folder within $GOPATH
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

# Force umask to 0022
RUN echo "umask 0022" >> /root/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
