FROM 486234852809.dkr.ecr.us-east-1.amazonaws.com/docker:20.10

ARG PYTHON_VERSION=3.11.8
ARG CI_UPLOADER_VERSION=2.38.1
ARG CI_UPLOADER_SHA=90ee346ea639e2d70a45b70e2d1491e5749099665df06a2e6d80ddc9fd90fe0c
ARG VAULT_VERSION=1.17.2

RUN apt-get update &&  \
    DEBIAN_FRONTEND=noninteractive apt-get install -y make  \
      build-essential  \
      libssl-dev  \
      zlib1g-dev  \
      libbz2-dev  \
      libreadline-dev  \
      libsqlite3-dev  \
      wget  \
      curl  \
      llvm  \
      libncurses5-dev  \
      xz-utils  \
      tk-dev  \
      libxml2-dev  \
      libxmlsec1-dev  \
      libffi-dev  \
      liblzma-dev &&  \
    apt-get clean &&  \
    rm -rf /var/lib/apt/lists/*

# Python install
ENV PYENV_ROOT="/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"

RUN git clone --depth=1 https://github.com/pyenv/pyenv.git ${PYENV_ROOT} && \
     pyenv install ${PYTHON_VERSION} && \
     pyenv global ${PYTHON_VERSION}

COPY requirements.txt /
COPY requirements /requirements

RUN pip install -r requirements.txt

# Install vault: https://developer.hashicorp.com/vault/install
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com focal main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt update && apt install -y vault=${VAULT_VERSION}-1 && apt clean && rm -rf /var/lib/apt/lists/*

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# CI uploader, to send tags for extra visibility into CI
RUN curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${CI_UPLOADER_VERSION}/datadog-ci_linux-arm64 --output "/usr/local/bin/datadog-ci" && \
  echo "${CI_UPLOADER_SHA} /usr/local/bin/datadog-ci" | sha256sum --check && \
  chmod +x /usr/local/bin/datadog-ci
