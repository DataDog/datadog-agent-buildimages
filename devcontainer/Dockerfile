FROM ubuntu:24.04

ARG TARGETARCH
ARG GO_VERSION
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS=1
ARG PYTHON_VERSION=3.12
ARG CMAKE_VERSION=3.30.2
ARG CMAKE_SHA256_AMD64="33f5a7680578481ce0403dc5a814afae613f2f6f88d632a3bda0f7ff5f4dedfc"
ARG CMAKE_SHA256_ARM64="8a6636e72a6ddfe50e0087472bff688f337df48b00a7728b12d7b70b5b459fc5"
ENV DEBIAN_FRONTEND=noninteractive
ENV DATADOG_AGENT_EMBEDDED_PATH=/opt/datadog-agent/embedded
ENV DDA_NO_DYNAMIC_DEPS=${DDA_NO_DYNAMIC_DEPS}

RUN apt-get update && apt-get upgrade -y && \
    # Common + Agent (Core/Trace/Process) dependencies
    apt-get install -y wget software-properties-common build-essential apt-transport-https libsystemd-dev sudo vim git curl procps ruby ruby-dev autoconf automake libtool libtool-bin gettext autopoint checkpolicy policycoreutils policycoreutils-python-utils bison flex pkg-config docker.io docker-buildx docker-compose-v2 ninja-build \
    # Network feature tests
    openjdk-11-jre-headless \
    # System-probe dependencies
    clang llvm bpfcc-tools libbpfcc-dev libelf-dev linux-headers-generic &&\
    # Python setup
    add-apt-repository -y 'ppa:deadsnakes/ppa' &&\
    apt-get install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-dev python${PYTHON_VERSION}-venv &&\
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists

# Setup python3.12 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 2

# Install latest pip
RUN curl -sSL https://bootstrap.pypa.io/get-pip.py | python3

# CMake setup
RUN if [ "$TARGETARCH" = "arm64" ] ; then set -ex \
    && curl -sL -o cmake.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-aarch64.sh \
    && echo "${CMAKE_SHA256_ARM64}  cmake.sh" | sha256sum --check \
    && mkdir -p /opt/cmake/ \
    && sh cmake.sh --skip-license --prefix=/opt/cmake \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && rm cmake.sh ; fi

RUN if [ "$TARGETARCH" = "amd64" ] ; then set -ex \
    && curl -sL -o cmake.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh \
    && echo "${CMAKE_SHA256_AMD64}  cmake.sh" | sha256sum --check \
    && mkdir -p /opt/cmake/ \
    && sh cmake.sh --skip-license --prefix=/opt/cmake \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && rm cmake.sh ; fi

# Install & verify Bazelisk as Bazel bootstrapper
RUN --mount=type=bind,src=./setup/bazelisk.sh,dst=/mnt/bazelisk.sh /mnt/bazelisk.sh

# Create user
RUN useradd -g 20 -u 503 -m datadog -s /bin/bash -G sudo,root && \
    echo 'datadog ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/datadog && \
    # Pin pyasn1 to 0.6.0 until the maintainers release a wheel for 0.6.1 version
    pip3 install --no-cache-dir pyasn1==0.6.0 && \
    # Correct some permissions
    mkdir -p $DATADOG_AGENT_EMBEDDED_PATH && chown -R 503:20 $DATADOG_AGENT_EMBEDDED_PATH && \
    # Omnibus setup
    gem install bundler && \
    mkdir -p /var/cache/omnibus && chmod 775 /var/cache/omnibus && \
    chmod 775 /opt /var/log /etc /etc/init /etc/init.d /lib/systemd/system /usr/bin && \
    # Golang setup
    curl -sL https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz | tar -C /usr/local -xz && \
    # Kubernetes (https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management)
    # "Download the public signing key for the Kubernetes package repositories. The same signing key is used for all repositories so you can disregard the version in the URL"
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && apt-get install -y kubectl && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists

USER datadog

# prevents using system package which emits warning logs on every call
RUN pip3 install --no-cache-dir blinker==1.9.0

ENV GOPATH=/home/datadog/go \
    GOROOT=/usr/local/go \
    PATH="/home/datadog/.local/bin:/home/datadog/go/bin:/usr/local/go/bin:${PATH}"
RUN mkdir -p /home/datadog/go/bin
# Golang tooling: install common tooling use by code editors
RUN go install golang.org/x/tools/gopls@latest && \
    go install github.com/cweill/gotests/gotests@v1.6.0 && \
    go install github.com/fatih/gomodifytags@v1.16.0 && \
    go install github.com/josharian/impl@v1.1.0 && \
    go install github.com/haya14busa/goplay/cmd/goplay@v1.0.0 && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install gotest.tools/gotestsum@latest

# Install dda and sync dependencies
# Run as root as dda needs to be installed system-wide
USER root
RUN pip3 install --no-cache-dir "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}" && \
    dda -v self dep sync -f legacy-tasks

# Switch back to the datadog user
USER datadog

WORKDIR /home/datadog
CMD [ "sleep", "infinity" ]
