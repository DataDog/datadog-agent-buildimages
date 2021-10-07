FROM ubuntu as CURL_GETTER
RUN apt-get update && apt-get install -y wget
RUN wget https://github.com/moparisthebest/static-curl/releases/download/v7.79.1/curl-amd64

FROM debian:wheezy-backports

# Build Args
ARG GIMME_GO_VERSION=1.15.13
ARG DD_PIP_VERSION=19.1
ARG DD_SETUPTOOLS_VERSION=44.1.1
ARG DD_SETUPTOOLS_VERSION_PY3=52.0.0
ARG CMAKE_VERSION=3.14.4
ARG CLANG_VERSION=8.0.0
ARG CONDA_VERSION=4.9.2
ARG DD_TARGET_ARCH=x64

# Environment
ENV GOPATH /go
ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV DD_PIP_VERSION $DD_PIP_VERSION
ENV DD_SETUPTOOLS_VERSION $DD_SETUPTOOLS_VERSION
ENV DD_SETUPTOOLS_VERSION_PY3 $DD_SETUPTOOLS_VERSION_PY3
ENV CMAKE_VERSION $CMAKE_VERSION
ENV CLANG_VERSION $CLANG_VERSION
ENV CONDA_PATH /root/miniconda3
ENV CONDA_VERSION $CONDA_VERSION
ENV DD_TARGET_ARCH $DD_TARGET_ARCH

# Mitigation for CVE-2019-3462
RUN echo 'Acquire::http::AllowRedirect"false";' >> /etc/apt/apt.conf.d/20datadog
# Ignore expired repos signature
# Wheezy is EOL, security updates repo will not get any newer updates, or will do so
# in arbitrary, unscheduled timeframes. At the time of this writing the repo has
# expired making the following option necessary for apt to work.
RUN echo 'Acquire::Check-Valid-Until "false";' >> /etc/apt/apt.conf.d/20datadog

RUN echo "deb http://archive.debian.org/debian wheezy main contrib non-free" > /etc/apt/sources.list && \
 echo "deb http://archive.debian.org/debian wheezy-backports main contrib non-free" > /etc/apt/sources.list.d/backports.list && \
 echo "deb http://archive.debian.org/debian-security wheezy/updates main contrib non-free" > /etc/apt/sources.list.d/security.list

RUN apt-get update && apt-get install -y fakeroot cmake bzip2 g++ git \
  build-essential pkg-config libssl-dev libcurl4-openssl-dev libz-dev \
  tar pkg-config xz-utils zlib1g-dev

# Update curl with a statically linked binary
COPY --from=CURL_GETTER /curl-amd64 /usr/local/bin/curl
RUN chmod +x /usr/local/bin/curl

# CMake
RUN set -ex \
    && curl -sL -o cmake.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
    && mkdir -p /opt/cmake/ \
    && sh cmake.sh --skip-license --prefix=/opt/cmake \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && rm cmake.sh

# CONDA
RUN curl -fsL -o ~/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-py39_${CONDA_VERSION}-Linux-x86_64.sh
RUN bash ~/miniconda.sh -b -p $CONDA_PATH
RUN rm ~/miniconda.sh
COPY ./conda.sh /etc/profile.d/conda.sh
ENV PATH "${CONDA_PATH}/bin:${PATH}"
ENV PKG_CONFIG_LIBDIR "${PKG_CONFIG_LIBDIR}:${CONDA_PATH}/lib/pkgconfig"

# RVM
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/*
RUN rm -rf /gpg-keys
RUN curl -sSL https://get.rvm.io | bash -s stable --version latest-1.29
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.6.6 --with-openssl-dir=${CONDA_PATH} && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --no-document"

# Use conda to install gcc5
# Must be done after installing ruby with RVM, otherwise conda's gcc is used to build ruby and it doesn't work
RUN conda install -c psi4 gcc-5
RUN conda install -c anaconda python=3.8

# Install ssl in a custom location
RUN curl -L -O http://www.openssl.org/source/openssl-1.1.1k.tar.gz
RUN tar -xzf openssl-1.1.1k.tar.gz
RUN cd openssl-1.1.1k && ./config --prefix=/home/openssl --openssldir=/home/openssl
RUN cd openssl-1.1.1k && make -j 8 && make install

# Install python3.8 with custom openssl
RUN curl -O -k https://www.python.org/ftp/python/3.8.0/Python-3.8.0.tar.xz
RUN tar -xf Python-3.8.0.tar.xz -C /tmp/
RUN cd /tmp/Python-3.8.0 && LDFLAGS="${LDFLAGS} -Wl,-rpath=/home/openssl/lib" ./configure --with-openssl=/home/openssl
RUN cd /tmp/Python-3.8.0 && make -j 8 && make install

RUN python -m pip install awscli meson ninja

# Install clang and llvm version 8
# Using build for sles11 because the versions built for other distros target glibcs that are too new to be used from this image
RUN curl -LO https://releases.llvm.org/${CLANG_VERSION}/clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz && \
    tar -xf clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz --no-same-owner --strip 1 -kC /usr/ && \
    rm clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz

# Install glibc 2.16
RUN curl -LO https://ftp.gnu.org/gnu/glibc/glibc-2.16.0.tar.gz && \
  tar zxvf glibc-2.16.0.tar.gz && \
  cd glibc-2.16.0 && \
  mkdir build && \
  cd build && \
  ../configure --prefix=/opt/glibc-2.16 && \
  make -j 8 && \
  make install

# Gimme
RUN curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
RUN chmod +x /bin/gimme
RUN gimme $GIMME_GO_VERSION
COPY ./gobin.sh /etc/profile.d/

# Automake
RUN curl -OL https://ftp.gnu.org/gnu/automake/automake-1.16.tar.gz
RUN tar xzf automake-1.16.tar.gz
# Patch automake to resolve a build error from building with a version of perl which is too old (see patch for more details)
COPY ./omnibus-nikos_x64/automake.patch automake-1.16/automake.patch
RUN cd automake-1.16 && patch -p1 < automake.patch
RUN cd automake-1.16 && ./bootstrap && ./configure --prefix=/usr/local && make -j 5 && make install
RUN rm -rf automake-1.16 automake-1.16.tar.gz

COPY ./entrypoint-sysprobe.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
