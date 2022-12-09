FROM debian:bookworm

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bison \
    flex \
    build-essential \
    libssl-dev \
    libelf-dev \
    bc \
	curl \
	git \
	xz-utils \
    debootstrap \
    wget \
    qemu-utils
