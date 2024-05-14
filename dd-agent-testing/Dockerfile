FROM ruby:2.7.5-bullseye

ENV BUNDLER_VERSION=1.17.3
ARG CI_UPLOADER_VERSION=2.30.1
ARG CI_UPLOADER_SHA=873976f0f8de1073235cf558ea12c7b922b28e1be22dc1553bf56162beebf09d
ARG PYTHON_VERSION=3.11

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common && \
  add-apt-repository ppa:deadsnakes/ppa && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
  apt-transport-https autoconf automake bison curl \
  g++ gawk gcc git jq \
  libc6-dev libffi-dev libssl-dev libgdbm-dev libgmp-dev libncurses5-dev \
  libreadline6-dev libsqlite3-dev libtool libyaml-dev \
  make openssh-client pkg-config python${PYTHON_VERSION} python3-pip rsync sqlite3 zlib1g-dev \
  && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ focal main" | \
      tee /etc/apt/sources.list.d/azure-cli.list && \
      curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
  && apt-get update && apt-get install -y azure-cli=2.40.0-1~focal \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${CI_UPLOADER_VERSION}/datadog-ci_linux-x64 --output "/usr/local/bin/datadog-ci" \
  && echo "${CI_UPLOADER_SHA} /usr/local/bin/datadog-ci" | sha256sum --check \
  && chmod +x /usr/local/bin/datadog-ci

# Python
COPY requirements.txt /
COPY requirements /requirements
RUN python3 -m pip install -r requirements.txt

# Ruby
RUN gem install bundler --version ${BUNDLER_VERSION}
COPY dd-agent-testing/Gemfile dd-agent-testing/Gemfile.lock ./
RUN bundle install
RUN bundle show

# create the agent build folder within $GOPATH
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent
