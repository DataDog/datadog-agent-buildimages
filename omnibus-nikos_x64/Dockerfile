FROM ubuntu as CURL_GETTER
ENV WGET_VERSION=7.79.1
ENV WGET_SHA256="0a89440848db3ba21d38b93b450d90fb84d4d0fa5562aa9c6933070b0eddc960"
RUN apt-get update && apt-get install -y wget
RUN wget https://github.com/moparisthebest/static-curl/releases/download/v${WGET_VERSION}/curl-amd64
RUN echo "${WGET_SHA256}  curl-amd64" | sha256sum --check

# NOTE: we can't upgrade to Debian Jessie, because that has glibc 2.19 and
# we still need to support CentOS 7.6+ with nikos, which has glibc 2.17.
# We can upgrade the base image once we drop support for CentOS 7.
FROM debian:wheezy-backports

# Build Args
ARG GIMME_GO_VERSION=1.17.6
ARG CMAKE_VERSION=3.23.0
ARG CMAKE_SHA256="5eaf3ded8255b3d149c7aad68c473f01c2345dce872e03c92f2e9c0185dfa75a"
ARG CLANG_VERSION=8.0.0
ARG CLANG_SHA256="7e2846ff60c181d1f27d97c23c25a2295f5730b6d88612ddd53b4cbb8177c4b9"
ARG CONDA_VERSION=4.9.2
ARG CONDA_SHA256="536817d1b14cb1ada88900f5be51ce0a5e042bae178b5550e62f61e223deae7c"

# Environment
ENV GOPATH /go
ENV CONDA_PATH /root/miniconda3
ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV CMAKE_VERSION $CMAKE_VERSION
ENV CMAKE_SHA256 $CMAKE_SHA256
ENV CLANG_VERSION $CLANG_VERSION
ENV CLANG_SHA256 $CLANG_SHA256
ENV CONDA_VERSION $CONDA_VERSION
ENV CONDA_SHA256 $CONDA_SHA256

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

RUN apt-get update && apt-get install -y fakeroot procps bzip2 g++ gcc git \
  build-essential pkg-config libssl-dev libcurl4-openssl-dev libz-dev \
  tar pkg-config xz-utils zlib1g-dev

# Update curl with a statically linked binary
COPY --from=CURL_GETTER /curl-amd64 /usr/local/bin/curl
RUN chmod +x /usr/local/bin/curl

# CMake
RUN set -ex \
    && curl -sL -o cmake.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh \
    && echo "${CMAKE_SHA256}  cmake.sh" | sha256sum --check \
    && mkdir -p /opt/cmake/ \
    && sh cmake.sh --skip-license --prefix=/opt/cmake \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && rm cmake.sh

# CONDA
RUN curl -fsL -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-py39_${CONDA_VERSION}-Linux-x86_64.sh
RUN echo "${CONDA_SHA256}  miniconda.sh" | sha256sum --check
RUN bash miniconda.sh -b -p $CONDA_PATH
RUN rm miniconda.sh
COPY ./conda.sh /etc/profile.d/conda.sh
ENV PATH "${CONDA_PATH}/bin:${PATH}"
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
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.6.6 --with-openssl-dir=${CONDA_PATH} && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --no-document"

# Use conda to install gcc5
# Must be done after installing ruby with RVM, otherwise conda's gcc is used to build ruby and it doesn't work
RUN conda install -c psi4 gcc-5 isl=0.12.2

# Install ssl in a custom location
RUN curl -L -O http://www.openssl.org/source/openssl-1.1.1k.tar.gz
RUN echo "892a0875b9872acd04a9fde79b1f943075d5ea162415de3047c327df33fbaee5  openssl-1.1.1k.tar.gz" | sha256sum --check
RUN tar -xzf openssl-1.1.1k.tar.gz
RUN cd openssl-1.1.1k && ./config --prefix=/home/openssl --openssldir=/home/openssl
RUN cd openssl-1.1.1k && make -j 8 && make install

# Install python3.8 with custom openssl
RUN curl -O -k https://www.python.org/ftp/python/3.8.0/Python-3.8.0.tar.xz
RUN echo "b356244e13fb5491da890b35b13b2118c3122977c2cd825e3eb6e7d462030d84  Python-3.8.0.tar.xz" | sha256sum --check
RUN tar -xf Python-3.8.0.tar.xz -C /tmp/
RUN cd /tmp/Python-3.8.0 && LDFLAGS="${LDFLAGS} -Wl,-rpath=/home/openssl/lib" ./configure --with-openssl=/home/openssl
RUN cd /tmp/Python-3.8.0 && make -j 8 && make install

RUN python3.8 -m pip install meson ninja
COPY ./requirements.txt ./requirements-py2.txt /
RUN python3.8 -m pip install -r requirements.txt

# Install clang and llvm version 8
# Using build for sles11 because the versions built for other distros target glibcs that are too new to be used from this image
RUN curl -LO https://releases.llvm.org/${CLANG_VERSION}/clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz \
    && echo "${CLANG_SHA256}  clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz" | sha256sum --check \
    && tar -xf clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz --no-same-owner --strip 1 -kC /usr/ \
    && rm clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz

# Install glibc 2.16
RUN curl -LO https://ftp.gnu.org/gnu/glibc/glibc-2.16.0.tar.gz \
  && echo "a75be51658cc1cfb6324ec6dbdbed416526c44c14814823129f0fcc74c279f6e  glibc-2.16.0.tar.gz" | sha256sum --check \
  && tar zxvf glibc-2.16.0.tar.gz \
  && cd glibc-2.16.0 \
  && mkdir build \
  && cd build \
  && ../configure --prefix=/opt/glibc-2.16 \
  && make -j 8 \
  && make install

# Gimme
RUN curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/v1.5.4/gimme
RUN echo "03b295636d4e22870b6f6e9bc06a71d65311ae90d3d48cbc7071f82dd5837fbc  /bin/gimme" | sha256sum --check
RUN chmod +x /bin/gimme
RUN gimme $GIMME_GO_VERSION
COPY ./gobin.sh /etc/profile.d/

# Automake
RUN curl -OL https://ftp.gnu.org/gnu/automake/automake-1.16.tar.gz
RUN echo "80da43bb5665596ee389e6d8b64b4f122ea4b92a685b1dbd813cd1f0e0c2d83f  automake-1.16.tar.gz"  | sha256sum --check
RUN tar xzf automake-1.16.tar.gz
# Patch automake to resolve a build error from building with a version of perl which is too old (see patch for more details)
COPY ./omnibus-nikos_x64/automake.patch automake-1.16/automake.patch
RUN cd automake-1.16 && patch -p1 < automake.patch
RUN cd automake-1.16 && ./bootstrap && ./configure --prefix=/usr/local && make -j 5 && make install
RUN rm -rf automake-1.16 automake-1.16.tar.gz

COPY ./entrypoint-sysprobe.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
