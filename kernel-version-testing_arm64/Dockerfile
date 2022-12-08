FROM debian:bookworm

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
	curl \
	git \
	xz-utils \
    debootstrap \
    wget \
    qemu-utils
