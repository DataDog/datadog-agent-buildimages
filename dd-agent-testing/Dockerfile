FROM ruby:2.7.5-bullseye AS base

# Build Args - common arguments used across stages
ENV BUNDLER_VERSION=1.17.3
ARG CI_UPLOADER_VERSION=2.38.1
ARG CI_UPLOADER_SHA=4e56d449e6396ae4c7356f07fc5372a28999aacb012d4343a3b8a9389123aa38
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS
ARG PYTHON_VERSION=3.12.6
ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=a0c0449e640c8be5dcf7b7b093d5884f6a85406dbb86bbad0ea06becad5aaab8
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_amd64.zip"

# Environment variables
ENV PYTHONUTF8=1
ENV PYENV_ROOT="/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
ENV DDA_NO_DYNAMIC_DEPS=$DDA_NO_DYNAMIC_DEPS

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# Install system dependencies in a single layer
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  apt-transport-https autoconf automake bison curl \
  g++ gawk gcc git jq \
  libc6-dev libffi-dev libssl-dev libgdbm-dev libgmp-dev libncurses5-dev \
  libreadline6-dev libsqlite3-dev libtool libyaml-dev \
  make openssh-client pkg-config rsync sqlite3 zlib1g-dev \
  && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ focal main" | \
      tee /etc/apt/sources.list.d/azure-cli.list && \
      curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
  && apt-get update && apt-get install -y azure-cli=2.40.0-1~focal \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Final image
FROM base

# Install CI uploader in a single layer
ARG CI_UPLOADER_VERSION
ARG CI_UPLOADER_SHA
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${CI_UPLOADER_VERSION}/datadog-ci_linux-x64 --output "/usr/local/bin/datadog-ci" \
  && echo "${CI_UPLOADER_SHA} /usr/local/bin/datadog-ci" | sha256sum --check \
  && chmod +x /usr/local/bin/datadog-ci

# Install Python with pyenv in a single layer
ARG PYTHON_VERSION
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS
RUN git clone --depth=1 https://github.com/pyenv/pyenv.git ${PYENV_ROOT} && \
     pyenv install ${PYTHON_VERSION} && \
     pyenv global ${PYTHON_VERSION} && \
     pip3 install "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}" && \
     dda -v self dep sync -f legacy-build && \
     pyenv rehash

# Install Ruby dependencies in a single layer
ENV BUNDLER_VERSION
RUN gem install bundler --version ${BUNDLER_VERSION}
COPY dd-agent-testing/Gemfile dd-agent-testing/Gemfile.lock ./
RUN bundle install && bundle show

# Install Vault in a single layer
ARG VAULT_VERSION
ARG VAULT_CHECKSUM
ARG VAULT_FILENAME
RUN curl -LO https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME} && \
  echo "${VAULT_CHECKSUM} ${VAULT_FILENAME}" | sha256sum --check && \
  unzip -o ${VAULT_FILENAME} -d /usr/bin vault && \
  rm ${VAULT_FILENAME}

# Create the agent build folder
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent
