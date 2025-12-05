FROM ruby:2.7.5-bullseye

ENV BUNDLER_VERSION=1.17.3
ARG DATADOG_CI_VERSION=3.9.0
ARG DATADOG_CI_SHA=1b62407af5d4e99827a6903a0e893a17cadf94d1da42e86a76fb5f2b44b2a1e5
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS
ARG PYTHON_VERSION=3.12.6
ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=a0c0449e640c8be5dcf7b7b093d5884f6a85406dbb86bbad0ea06becad5aaab8
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_amd64.zip"

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  apt-transport-https autoconf automake bison curl \
  g++ gawk gcc git jq \
  libc6-dev libffi-dev libssl-dev libgdbm-dev libgmp-dev libncurses5-dev \
  libreadline6-dev libsqlite3-dev libtool libyaml-dev \
  make openssh-client pkg-config rsync sqlite3 zlib1g-dev \
  && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ focal main" | \
      tee /etc/apt/sources.list.d/azure-cli.list && \
      curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
  && apt-get update && apt-get install -y azure-cli=2.40.0-1~focal \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${DATADOG_CI_VERSION}/datadog-ci_linux-x64 --output "/usr/local/bin/datadog-ci" \
  && echo "${DATADOG_CI_SHA} /usr/local/bin/datadog-ci" | sha256sum --check \
  && chmod +x /usr/local/bin/datadog-ci

# Python install
ENV PYTHONUTF8 1
ENV PYENV_ROOT="/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS

RUN git clone --depth=1 https://github.com/pyenv/pyenv.git ${PYENV_ROOT} && \
     pyenv install ${PYTHON_VERSION} && \
     pyenv global ${PYTHON_VERSION}

# Python
RUN pip3 install "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}" \
 && dda -v self dep sync -f legacy-build \
 && pyenv rehash

# Ruby
RUN gem install bundler --version ${BUNDLER_VERSION}
COPY dd-agent-testing/Gemfile dd-agent-testing/Gemfile.lock ./
RUN bundle install
RUN bundle show

# Install vault: https://github.com/hashicorp/vault/blob/main/CHANGELOG.md https://releases.hashicorp.com/vault
RUN curl -LO https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME} && \
  echo "${VAULT_CHECKSUM} ${VAULT_FILENAME}" | sha256sum --check && \
  unzip -o ${VAULT_FILENAME} -d /usr/bin vault && \
  rm ${VAULT_FILENAME}

# Install authanywhere for infra token management
ADD --checksum=sha256:05d14b25e4607cc9e14867f2a0f38774869ae609eec890168e57de9a1b428e37 "https://binaries.ddbuild.io/dd-source/authanywhere/v0.0.2/authanywhere-tar.tar.gz" /tmp/authanywhere/authanywhere-tar.tar.gz
RUN --mount=type=bind,src=./setup/authanywhere.sh,dst=/mnt/authanywhere.sh /mnt/authanywhere.sh

# create the agent build folder within $GOPATH
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent
