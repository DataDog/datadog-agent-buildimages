FROM 486234852809.dkr.ecr.us-east-1.amazonaws.com/docker:20.10-py3

COPY ./requirements.txt .

RUN python3 -m pip install -r requirements.txt

# Patch docker-squash until it supports Docker 6.0.0
# See https://github.com/goldmann/docker-squash/pull/210
COPY ./patch-docker-squash.patch .
RUN set -x \
  && apt-get update \
  && apt-get -y install patch \
  && patch -p1 < /patch-docker-squash.patch \
  && rm /patch-docker-squash.patch \
  && apt-get -y remove patch \
  && apt-get -y clean \
  && rm -rf /var/lib/apt/lists/*
