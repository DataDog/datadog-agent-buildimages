FROM ubuntu:24.04

ARG GO_VERSION
ARG GO_SHA256_LINUX_AMD64
ARG MSGO_SHA256_LINUX_AMD64
ARG IBM_MQ_VERSION=9.2.4.0
ARG IBM_MQ_SHA256="d0d583eba72daf20b3762976f8831c2e23150ace90509520e12f8cda5b5bdb49"
ARG RUST_VERSION=1.76.0
ARG RUSTC_SHA256="0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db"
ARG RUSTUP_VERSION=1.26.0
ARG RUSTUP_SHA256="0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db"
ARG BUNDLER_VERSION=2.4.20
ARG DD_TARGET_ARCH
ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=a0c0449e640c8be5dcf7b7b093d5884f6a85406dbb86bbad0ea06becad5aaab8
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_amd64.zip"
ARG ZIG_VERSION=0.13.0
ARG ZIG_SHA256="d45312e61ebcc48032b77bc4cf7fd6915c11fa16e4aad116b66c9468211230ea"

ENV CONDA_PATH /root/miniforge3

# Remove the early return on non-interactive shells, which makes sourcing the file not activate conda
RUN grep -v return /root/.bashrc >> /root/newbashrc && cp /root/newbashrc /root/.bashrc

RUN apt update -qy && apt install -y \
    wget xz-utils gpg build-essential flex texinfo unzip \
    help2man file gawk libtool-bin bison libncurses-dev \
    python-is-python3 git cmake curl fakeroot procps bzip2 \
    pkg-config libssl-dev libcurl4-openssl-dev libexpat-dev libpq-dev libz-dev \
    rpm tar gettext autopoint autoconf clang libtool-bin \
    pkg-config flex meson selinux-basics squashfs-tools gpg xz-utils gnupg2 patchelf cpio

COPY linux-glibc-2.17-x64/toolchain.cmake /opt/cmake/x86_64-unknown-linux-gnu.toolchain.cmake
COPY linux-glibc-2.17-x64/cargo-config.toml /root/.cargo/config.toml

RUN git config --global user.email "package@datadoghq.com"
RUN git config --global user.name "Bits"

RUN cd /tmp \
    && curl -LO https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz \
    && echo "${ZIG_SHA256}  zig-linux-x86_64-${ZIG_VERSION}.tar.xz" | sha256sum --check \
    && tar xf zig-linux-x86_64-${ZIG_VERSION}.tar.xz \
    && cp zig-linux-x86_64-${ZIG_VERSION}/zig /usr/local/bin/ \
    && cp -R zig-linux-x86_64-${ZIG_VERSION}/lib /usr/local/lib/zig


# IBM MQ
RUN mkdir -p /opt/mqm \
    && curl "https://s3.amazonaws.com/dd-agent-omnibus/ibm-mq-backup/${IBM_MQ_VERSION}-IBM-MQC-Redist-LinuxX64.tar.gz" -o /tmp/mq_client.tar.gz \
    && echo "${IBM_MQ_SHA256}  /tmp/mq_client.tar.gz" | sha256sum --check \
    && tar -C /opt/mqm -xf /tmp/mq_client.tar.gz \
    && rm -rf /tmp/mq_client.tar.gz

# CONDA
COPY python-packages-versions.txt setup_python.sh requirements.txt requirements-py2.txt /
COPY requirements /requirements

RUN ./setup_python.sh
ENV PATH "${CONDA_PATH}/condabin:${PATH}"

# RVM
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/*
RUN rm -rf /gpg-keys
RUN curl -sSL -o get-rvm.sh https://raw.githubusercontent.com/rvm/rvm/1.29.12/binscripts/rvm-installer \
    && echo "fea24461e98d41528d6e28684aa4c216dbe903869bc3fcdb3493b6518fae2e7e  get-rvm.sh" | sha256sum --check \
    && bash get-rvm.sh stable --version 1.29.12 \
    && echo "d2de0b610ee321489e5c673fe749e13be8fb34c0aa08a74446d87f95a17de730  /usr/local/rvm/bin/rvm" | sha256sum --check \
    && rm get-rvm.sh
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.7 --with-openssl-dir=${CONDA_PATH} && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --version $BUNDLER_VERSION --no-document"
RUN echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc

# Go
COPY setup_go.sh /
RUN ./setup_go.sh

# Rust is needed to compile the SDS library
RUN curl -sSL -o rustup-init https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init \
    && echo "${RUSTUP_SHA256}  rustup-init" | sha256sum --check \
    && chmod +x ./rustup-init \
    && ./rustup-init -y --profile minimal --default-toolchain ${RUST_VERSION} \
    && echo "${RUSTC_SHA256}  $HOME/.cargo/bin/rustc" | sha256sum --check \
    && rm ./rustup-init
ENV PATH "~/.cargo/bin:${PATH}"

# Install vault: https://github.com/hashicorp/vault/blob/main/CHANGELOG.md https://releases.hashicorp.com/vault
RUN curl -LO https://releases.hashicorp.com/vault/$VAULT_VERSION/$VAULT_FILENAME \
    && echo "${VAULT_CHECKSUM}  ${VAULT_FILENAME}" | sha256sum --check \
    && unzip $VAULT_FILENAME \
    && rm $VAULT_FILENAME \
    && mv vault /usr/bin/vault \
    && chmod +x /usr/bin/vault

RUN echo "umask 0022" >> /root/.bashrc
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

ENV PATH=/opt/toolchains/bin:$PATH

# Ensure pkg-config will not look into the system directories
ENV PKG_CONFIG_LIBDIR ""

ENTRYPOINT ["/entrypoint.sh"]
