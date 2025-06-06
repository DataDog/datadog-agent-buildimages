FROM ubuntu:22.04 AS base

# Build Args - common arguments used across stages
ARG TARGETARCH
ARG GO_VERSION
ARG DDA_VERSION
ARG DDA_NO_DYNAMIC_DEPS=1
ARG PYTHON_VERSION=3.12
ARG CMAKE_VERSION=3.30.2
ARG CMAKE_SHA256_AMD64="33f5a7680578481ce0403dc5a814afae613f2f6f88d632a3bda0f7ff5f4dedfc"
ARG CMAKE_SHA256_ARM64="8a6636e72a6ddfe50e0087472bff688f337df48b00a7728b12d7b70b5b459fc5"

# Environment variables common to all stages
ENV DEBIAN_FRONTEND=noninteractive
ENV DATADOG_AGENT_EMBEDDED_PATH=/opt/datadog-agent/embedded
ENV DDA_NO_DYNAMIC_DEPS=${DDA_NO_DYNAMIC_DEPS}
ENV GOPATH=/home/datadog/go
ENV GOROOT=/usr/local/go
ENV PATH="/home/datadog/.local/bin:/home/datadog/go/bin:/usr/local/go/bin:${PATH}"

# Install common packages in a single layer
RUN apt-get update && apt-get upgrade -y && \
    # Add Python PPA
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository -y 'ppa:deadsnakes/ppa' && \
    # Add Kubernetes repo
    mkdir -p /etc/apt/keyrings && \
    apt-get install -y --no-install-recommends curl gnupg && \
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list && \
    # Install all dependencies
    apt-get update && apt-get install -y --no-install-recommends \
    # Common + Agent dependencies
    wget build-essential apt-transport-https libsystemd-dev sudo vim git \
    procps ruby ruby-dev autoconf automake libtool libtool-bin gettext autopoint \
    checkpolicy policycoreutils policycoreutils-python-utils bison pkg-config \
    docker.io docker-buildx docker-compose-v2 ninja-build \
    # Network feature tests
    openjdk-11-jre-headless \
    # System-probe dependencies
    clang llvm bpfcc-tools libbpcc-dev libelf-dev linux-headers-generic \
    # Python
    python${PYTHON_VERSION} python${PYTHON_VERSION}-dev python${PYTHON_VERSION}-venv \
    # Kubernetes
    kubectl && \
    # Clean up
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# FROM base AS cmake-builder
FROM base AS cmake-builder
ARG TARGETARCH
ARG CMAKE_VERSION
ARG CMAKE_SHA256_AMD64
ARG CMAKE_SHA256_ARM64

# Install CMake for the appropriate architecture
RUN if [ "$TARGETARCH" = "arm64" ] ; then \
    curl -sL -o cmake.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-aarch64.sh && \
    echo "${CMAKE_SHA256_ARM64}  cmake.sh" | sha256sum --check ; \
    else \
    curl -sL -o cmake.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh && \
    echo "${CMAKE_SHA256_AMD64}  cmake.sh" | sha256sum --check ; \
    fi && \
    mkdir -p /opt/cmake/ && \
    sh cmake.sh --skip-license --prefix=/opt/cmake && \
    rm cmake.sh

# Final image
FROM base

# Copy CMake from builder stage
COPY --from=cmake-builder /opt/cmake /opt/cmake
RUN ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake

# Set up Python configuration
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 2 && \
    # Install latest pip
    curl -sSL https://bootstrap.pypa.io/get-pip.py | python3

# Create user with appropriate permissions
RUN useradd -g 20 -u 503 -m datadog -s /bin/bash -G sudo,root && \
    echo 'datadog ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/datadog && \
    # Setup directory permissions
    mkdir -p $DATADOG_AGENT_EMBEDDED_PATH && chown -R 503:20 $DATADOG_AGENT_EMBEDDED_PATH && \
    mkdir -p /var/cache/omnibus && chmod 775 /var/cache/omnibus && \
    chmod 775 /opt /var/log /etc /etc/init /etc/init.d /lib/systemd/system /usr/bin

# Install Golang
RUN curl -sL https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz | tar -C /usr/local -xz

# Install Python and Ruby dependencies
RUN pip3 install --no-cache-dir pyasn1==0.6.0 && \
    pip3 install --no-cache-dir "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}" && \
    dda -v self dep sync -f legacy-tasks && \
    gem install bundler

# Switch to datadog user for remaining operations
USER datadog
WORKDIR /home/datadog

# Set up Go environment and install Go tools
RUN mkdir -p /home/datadog/go/bin && \
    go install golang.org/x/tools/gopls@latest && \
    go install github.com/cweill/gotests/gotests@v1.6.0 && \
    go install github.com/fatih/gomodifytags@v1.16.0 && \
    go install github.com/josharian/impl@v1.1.0 && \
    go install github.com/haya14busa/goplay/cmd/goplay@v1.0.0 && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install gotest.tools/gotestsum@latest

CMD [ "sleep", "infinity" ]
