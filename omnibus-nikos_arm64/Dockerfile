ARG GIMME_GO_VERSION=1.16.7
ARG CLANG_VERSION=8.0.0

FROM ubuntu as CURL_GETTER
RUN apt-get update && apt-get install -y wget
RUN wget https://github.com/moparisthebest/static-curl/releases/download/v7.79.1/curl-aarch64

FROM arm64v8/ubuntu:16.04

# Environment
ENV GOPATH /go
ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV CLANG_VERSION $CLANG_VERSION

RUN apt-get update && apt-get install -y fakeroot cmake curl bzip2 g++ gcc git \
  build-essential pkg-config libssl-dev libcurl4-openssl-dev libz-dev \
  tar pkg-config xz-utils zlib1g-dev

# Update curl with a statically linked binary
COPY --from=CURL_GETTER /curl-aarch64 /usr/bin/curl
RUN chmod +x /usr/bin/curl

# RVM
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/*
RUN rm -rf /gpg-keys
RUN curl -sSL https://get.rvm.io | bash -s stable --version latest-1.29
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.6.6 && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --no-document"

# Install python 3.8
RUN curl -O -k https://www.python.org/ftp/python/3.8.0/Python-3.8.0.tar.xz && \
        tar -xf Python-3.8.0.tar.xz -C /tmp/
RUN cd /tmp/Python-3.8.0 && ./configure
RUN cd /tmp/Python-3.8.0 && make -j 8 && make install

RUN python3.8 -m pip install --upgrade pip --user
RUN python3.8 -m pip install awscli meson ninja

# Install clang and llvm version 8
RUN curl -sL -o clang_llvm.tar.xz https://dd-agent-omnibus.s3.amazonaws.com/clang%2Bllvm-${CLANG_VERSION}-aarch64-linux.tar.xz && \
    tar xf clang_llvm.tar.xz --no-same-owner -kC / && \
    rm clang_llvm.tar.xz
ENV PATH="/opt/clang/bin:$PATH"

# Gimme
RUN curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
RUN chmod +x /bin/gimme
RUN gimme $GIMME_GO_VERSION
COPY ./gobin.sh /etc/profile.d/

# Automake
RUN curl -OL https://ftp.gnu.org/gnu/automake/automake-1.16.tar.gz
RUN tar xzf automake-1.16.tar.gz
COPY ./omnibus-nikos_x64/automake.patch automake-1.16/automake.patch
RUN cd automake-1.16 && patch -p1 < automake.patch
RUN cd automake-1.16 && ./bootstrap && ./configure --prefix=/usr/local && make -j 5 && make install
RUN rm -rf automake-1.16 automake-1.16.tar.gz

COPY ./entrypoint-sysprobe.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
