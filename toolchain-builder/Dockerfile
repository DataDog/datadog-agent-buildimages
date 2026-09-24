ARG BASE_IMAGE_REGISTRY=docker.io
ARG ADMS_CLI_VERSION=0.0.23
ARG ADMS_CLI_DIGEST=sha256:5bf1995d2ab75e99698cdaa9f11cf38d7ee743d4ddf6e6b9aea2531a727c3eb5

FROM registry.ddbuild.io/adms-cli:${ADMS_CLI_VERSION}@${ADMS_CLI_DIGEST} AS adms_cli

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

COPY --from=adms_cli /usr/local/bin/adms /usr/local/bin/adms

ARG ARCH
ARG AWSCLI_VERSION=2.27.30
ARG AWSCLI_SHA256
ADD --checksum=sha256:${AWSCLI_SHA256} https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}-${AWSCLI_VERSION}.zip awscliv2.zip
RUN unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip
