FROM debian:bookworm

ARG DEBIAN_FRONTEND=noninteractive
ENV AWSCLI_VERSION=1.25.55
ENV INVOKE_VERSION=1.6.0

RUN apt-get update && apt-get install -y --no-install-recommends \
	bpftool \
    build-essential \
	curl \
	git \
    libssl-dev \
    zlib1g-dev \
	ninja-build \
    patch \
	python3-pip \
	xz-utils

ENV PYENV_ROOT="${HOME}/.pyenv"
ENV PATH="${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:${PATH}"

RUN curl -s -S -L https://raw.githubusercontent.com/pyenv/pyenv-installer/a08318c86abe0ebb68e0301e5d6861a860b8c765/bin/pyenv-installer > pyenv-installer.sh
RUN echo "33ba007f17d31215349fd0a693a77fd3d332063fb3a44b8994dfde87728b94e1  pyenv-installer.sh" | sha256sum --check
RUN bash pyenv-installer.sh

RUN pyenv install -s 3.7.9
RUN pyenv global 3.7.9
RUN python --version

RUN pip install awscli==${AWSCLI_VERSION} invoke==${INVOKE_VERSION}
