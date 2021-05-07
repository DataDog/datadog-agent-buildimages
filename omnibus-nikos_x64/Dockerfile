FROM debian:wheezy-backports

# Build Args
ARG GIMME_GO_VERSION=1.15.11
ARG DD_CONDA_VERSION=4.7.12
ARG DD_PIP_VERSION=19.1
ARG DD_SETUPTOOLS_VERSION=44.1.1
ARG CMAKE_VERSION=3.14.4
ARG CLANG_VERSION=8.0.0
ARG DD_TARGET_ARCH=x64

# Environment
ENV GOPATH /go
ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV DD_PIP_VERSION $DD_PIP_VERSION
ENV DD_SETUPTOOLS_VERSION $DD_SETUPTOOLS_VERSION
ENV CMAKE_VERSION $CMAKE_VERSION
ENV CLANG_VERSION $CLANG_VERSION
ENV CONDA_PATH /root/miniconda3
ENV DD_CONDA_VERSION $DD_CONDA_VERSION
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

RUN apt-get update && apt-get install -y fakeroot cmake curl bzip2 g++ git \
  build-essential pkg-config libssl-dev libcurl4-openssl-dev libz-dev \
  tar pkg-config wget xz-utils zlib1g-dev

# CMake
RUN set -ex \
    && curl -sL -o cmake.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
    && mkdir -p /opt/cmake/ \
    && sh cmake.sh --skip-license --prefix=/opt/cmake \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && rm cmake.sh

# RVM
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/*
RUN rm -rf /gpg-keys
RUN curl -sSL https://get.rvm.io | bash -s stable --version latest-1.29
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.6.6 && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --no-document"

# CONDA
COPY ./setup_python.sh /setup_python.sh
RUN ./setup_python.sh
COPY ./conda.sh /etc/profile.d/conda.sh
ENV PATH "${CONDA_PATH}/bin:${PATH}"
ENV PKG_CONFIG_LIBDIR "${PKG_CONFIG_LIBDIR}:${CONDA_PATH}/lib/pkgconfig"

RUN conda install -c psi4 gcc-5
RUN conda install -c anaconda python=3.8

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
COPY ./omnibus-nikos/automake.patch automake-1.16/automake.patch
RUN cd automake-1.16 && patch -p1 < automake.patch
RUN cd automake-1.16 && ./bootstrap && ./configure --prefix=/usr/local && make -j 5 && make install
RUN rm -rf automake-1.16 automake-1.16.tar.gz

COPY ./entrypoint-sysprobe.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
