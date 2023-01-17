FROM debian:bookworm

ARG DEBIAN_FRONTEND=noninteractive
ENV AWSCLI_VERSION=1.25.55
ENV INVOKE_VERSION=1.6.0

RUN apt-get update && apt-get install -y --no-install-recommends \
	bpftool \
	curl \
	git \
	ninja-build \
	python3 \
	python3-pip \
	xz-utils

RUN pip install awscli==${AWSCLI_VERSION} invoke==${INVOKE_VERSION}

COPY ./entrypoint-sysprobe.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
