ARG BASE_IMAGE_REGISTRY=docker.io
FROM ${BASE_IMAGE_REGISTRY}/ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qy && apt-get install -y --no-install-recommends \
    ca-certificates \
    build-essential \
    curl \
    git \
    unzip \
    xz-utils \
    ninja-build \
    libncurses5-dev \
    automake autoconf autopoint gettext help2man \
    libtool libtool-bin gperf bison flex gawk pkg-config \
    patch texinfo perl python3-dev gnupg dirmngr gpg-agent rsync && \
    rm -rf /var/lib/apt/lists/*

COPY --from=registry.ddbuild.io/images/datadog-ca-certs:standard /certs/ /usr/local/share/ca-certificates/
RUN chmod -R o-w /usr/local/share/ca-certificates && update-ca-certificates

ARG ARCH
ARG AWSCLI_VERSION=2.27.30
ARG AWSCLI_SHA256
ADD --checksum=sha256:${AWSCLI_SHA256} https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}-${AWSCLI_VERSION}.zip awscliv2.zip
RUN unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip
