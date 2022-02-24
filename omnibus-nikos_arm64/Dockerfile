FROM ubuntu as CURL_GETTER
ENV WGET_AARCH64_VERSION=7.79.1
ENV WGET_AARCH64_SHA256="234cc67f7caae0a0e1222bd70b513c78f65e058397bc271191ede66d12ec0366"
ENV WGET_ARMV7_VERSION=7.79.1
ENV WGET_ARMV7_SHA256="db08ec3a16ce0a8db0ce512a55adb619f6fbc6005f151abb4a31333f26780cc3"
RUN apt-get update && apt-get install -y wget
RUN wget https://github.com/moparisthebest/static-curl/releases/download/v7.79.1/curl-armv7
RUN echo "${WGET_ARMV7_SHA256}  curl-armv7" | sha256sum --check
RUN wget https://github.com/moparisthebest/static-curl/releases/download/v7.79.1/curl-aarch64
RUN echo "${WGET_AARCH64_SHA256}  curl-aarch64" | sha256sum --check

FROM arm64v8/ubuntu:16.04

# Build Args
ARG GIMME_GO_VERSION=1.17.6
ARG CLANG_VERSION=8.0.0
ARG CLANG_SHA256="a77eb8fde0a475c25d46dccdeb851a83cbeeeb11779fa2218ae19db9cd0e51f9"

# Environment
ENV GOPATH /go
ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV CLANG_VERSION $CLANG_VERSION
ENV CLANG_SHA256 $CLANG_SHA256

RUN apt-get update && apt-get install -y fakeroot cmake curl bzip2 g++ gcc git \
  build-essential pkg-config libssl-dev libcurl4-openssl-dev libz-dev \
  tar pkg-config xz-utils zlib1g-dev

# Update curl with a statically linked binary
COPY --from=CURL_GETTER /curl-aarch64 /usr/local/bin/curl
RUN chmod +x /usr/local/bin/curl

# RVM
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/*
RUN rm -rf /gpg-keys
# TODO: To be able to check sums, we need to pin the rvm install script, which cannot
# be done using the https://get.rvm.io URL.
RUN curl -sSL https://get.rvm.io | bash -s stable --version latest-1.29
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.6.6 && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --no-document"

# Install python 3.8
RUN curl -O -k https://www.python.org/ftp/python/3.8.0/Python-3.8.0.tar.xz \
    && echo "b356244e13fb5491da890b35b13b2118c3122977c2cd825e3eb6e7d462030d84  Python-3.8.0.tar.xz" | sha256sum --check \
    && tar -xf Python-3.8.0.tar.xz -C /tmp/
RUN cd /tmp/Python-3.8.0 && ./configure
RUN cd /tmp/Python-3.8.0 && make -j 8 && make install

RUN python3.8 -m pip install --upgrade pip --user
RUN python3.8 -m pip install meson ninja
COPY ./requirements.txt /requirements.txt
RUN python3.8 -m pip install -r requirements.txt

# Install clang and llvm version 8
RUN curl -sL -o clang_llvm.tar.xz https://dd-agent-omnibus.s3.amazonaws.com/clang%2Bllvm-${CLANG_VERSION}-aarch64-linux.tar.xz \
    && echo "${CLANG_SHA256}  clang_llvm.tar.xz" | sha256sum --check \
    && tar xf clang_llvm.tar.xz --no-same-owner -kC / \
    && rm clang_llvm.tar.xz
ENV PATH="/opt/clang/bin:$PATH"

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
COPY ./omnibus-nikos_x64/automake.patch automake-1.16/automake.patch
RUN cd automake-1.16 && patch -p1 < automake.patch
RUN cd automake-1.16 && ./bootstrap && ./configure --prefix=/usr/local && make -j 5 && make install
RUN rm -rf automake-1.16 automake-1.16.tar.gz

COPY ./entrypoint-sysprobe.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
