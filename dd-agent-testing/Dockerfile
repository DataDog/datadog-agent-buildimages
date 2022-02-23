FROM ubuntu:20.04

ENV RUBY_VERSION=2.7.5
ENV BUNDLER_VERSION=1.17.3

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  apt-transport-https autoconf automake bison curl \
  g++ gawk gcc git jq \
  libc6-dev libffi-dev libssl-dev libgdbm-dev libgmp-dev libncurses5-dev \
  libreadline6-dev libsqlite3-dev libtool libyaml-dev \
  make openssh-client pkg-config python3 python3-pip rsync sqlite3 zlib1g-dev \
  && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ bionic main" | \
      tee /etc/apt/sources.list.d/azure-cli.list && \
      curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
  && apt-get update && apt-get install -y azure-cli \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Python
COPY ./requirements.txt /requirements.txt
RUN python3 -m pip install -r requirements.txt

# Ruby
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import --no-tty /gpg-keys/*
RUN curl -sSL https://get.rvm.io | bash -s stable --version latest-1.29
RUN /bin/bash -l -c "rvm install ${RUBY_VERSION}"
RUN /bin/bash -l -c "rvm --default use ${RUBY_VERSION} && \
    gem install bundler --version ${BUNDLER_VERSION}"
RUN /bin/bash -l -c "rvm alias create default ${RUBY_VERSION}"
COPY dd-agent-testing/Gemfile dd-agent-testing/Gemfile.lock ./
RUN bash -l -c "bundle install"
RUN bash -l -c "bundle show"

# create the agent build folder within $GOPATH
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent
