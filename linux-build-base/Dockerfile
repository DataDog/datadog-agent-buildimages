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
    libncurses5-dev
