FROM debian:bullseye

ARG DEBIAN_FRONTEND=noninteractive
ARG DD_TARGET_ARCH=x64

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
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
    xz-utils

COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

ENV CONDA_PATH /root/miniforge3
ENV DD_TARGET_ARCH $DD_TARGET_ARCH

# CONDA
COPY python-packages-versions.txt setup_python.sh requirements.txt requirements-py2.txt /
COPY requirements /requirements
RUN ./setup_python.sh
ENV PATH "${CONDA_PATH}/condabin:${PATH}"
ENV PKG_CONFIG_LIBDIR "${PKG_CONFIG_LIBDIR}:${CONDA_PATH}/lib/pkgconfig"

RUN git clone --recurse-submodules https://github.com/brycekahle/bpftool.git
WORKDIR bpftool
RUN git reset --hard 1c25a06e38e9ff848ba66622d08a0147ed9ddc2e

RUN make -C src/ V=1 install

# Entrypoint - only for local usage, Kubernetes-based Gitlab runners overwrite this
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
