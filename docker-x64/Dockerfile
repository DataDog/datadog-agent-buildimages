FROM 486234852809.dkr.ecr.us-east-1.amazonaws.com/docker:20.10-py3

ARG PYTHON_VERSION=3.11.8

RUN apt-get update &&  \
    apt-get install -y make  \
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

RUN python3 -m pip install -r requirements.txt

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/
