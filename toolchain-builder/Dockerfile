ARG BASE_IMAGE_REGISTRY=docker.io
FROM ${BASE_IMAGE_REGISTRY}/ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qy && apt-get install -y --no-install-recommends ca-certificates

COPY --from=registry.ddbuild.io/images/datadog-ca-certs:standard /certs/ /usr/local/share/ca-certificates/
RUN chmod -R o-w /usr/local/share/ca-certificates && update-ca-certificates

RUN apt-get update -qy && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    wget \
    unzip \
    xz-utils \
    ninja-build \
    libncurses5-dev \
    automake autoconf autopoint gettext help2man \
    libtool libtool-bin gperf bison flex gawk pkg-config \
    patch texinfo perl python3-dev gnupg dirmngr gpg-agent rsync

ARG AWSCLI_VERSION=2.27.30
RUN curl --retry 10 -fsSLo awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m)-${AWSCLI_VERSION}.zip" && \
    unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip
