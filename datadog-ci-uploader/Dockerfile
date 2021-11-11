FROM ubuntu:20.04

# for apt to be noninteractive
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV N_VERSION=8.0.0
ENV NODE_VERSION=16.13.0
ENV AWSCLI_VERSION=1.16.240

RUN apt update && apt install -y curl git python3 python3-pip
RUN pip install awscli==${AWSCLI_VERSION}

RUN curl -L https://raw.githubusercontent.com/tj/n/v${N_VERSION}/bin/n -o n && \
    bash n ${NODE_VERSION} && \
    npm install -g @datadog/datadog-ci
