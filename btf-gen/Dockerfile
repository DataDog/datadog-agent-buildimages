FROM debian:bullseye

ARG DEBIAN_FRONTEND=noninteractive
ARG PYTHON_VERSION=3.11.8

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    clang \
    curl \
    git \
    libcap-dev \
    libelf-dev \
    libz-dev \
    llvm \
    llvm-dev \
    lld \
    ninja-build \
    software-properties-common \
    make  \
    zlib1g-dev  \
    libbz2-dev  \
    libreadline-dev  \
    libsqlite3-dev  \
    wget  \
    libncurses5-dev  \
    xz-utils  \
    tk-dev  \
    libxml2-dev  \
    libxmlsec1-dev  \
    libffi-dev  \
    liblzma-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Python install
ENV PYENV_ROOT="/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"

RUN git clone --depth=1 https://github.com/pyenv/pyenv.git ${PYENV_ROOT} && \
     pyenv install ${PYTHON_VERSION} && \
     pyenv global ${PYTHON_VERSION}

COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

RUN git clone --recurse-submodules https://github.com/libbpf/bpftool.git
WORKDIR bpftool
RUN git reset --hard cb3deb23d34abdb33f6bcc5fadeee676e538e2ff
COPY btf-gen/Makefile.patch ./
RUN git apply Makefile.patch

RUN make -C src/ V=1 install

COPY requirements ./
RUN pip install -r btf-gen.txt
