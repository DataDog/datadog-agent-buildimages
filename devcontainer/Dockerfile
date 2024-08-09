FROM ubuntu:22.04

ARG TARGETARCH
ARG GO_VERSION
ARG PYTHON_VERSION=3.11
ENV DEBIAN_FRONTEND=noninteractive
ENV DATADOG_AGENT_EMBEDDED_PATH=/opt/datadog-agent/embedded

RUN apt-get update && apt-get upgrade -y && \
    # Common + Agent (Core/Trace/Process) dependencies
    apt-get install -y wget software-properties-common build-essential apt-transport-https libsystemd-dev cmake sudo vim git curl procps ruby ruby-dev autoconf automake libtool libtool-bin gettext autopoint checkpolicy policycoreutils policycoreutils-python-utils bison pkg-config docker.io docker-buildx docker-compose-v2 ninja-build \
    # Network feature tests
    openjdk-11-jre-headless \
    # System-probe dependencies
    clang llvm bpfcc-tools libbpfcc-dev libelf-dev linux-headers-generic &&\
    # Python setup
    add-apt-repository -y 'ppa:deadsnakes/ppa' &&\
    apt-get install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-dev python${PYTHON_VERSION}-venv python3-pip &&\
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists

# Setup python3.11 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 2 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

# Create user
RUN useradd -g 20 -u 503 -m datadog -s /bin/bash -G sudo,root && \
    echo 'datadog ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/datadog && \
    pip3 install --no-cache-dir -r https://raw.githubusercontent.com/DataDog/datadog-agent/master/requirements.txt && \
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
WORKDIR /home/datadog
CMD [ "sleep", "infinity" ]
