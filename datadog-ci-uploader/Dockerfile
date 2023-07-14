FROM ubuntu:20.04

# for apt to be noninteractive
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV N_VERSION=8.0.0
ENV N_SHA256="e0af3182861d91bbc65478bfad7b25e7cbbe200a4f7443baeeaf9c2b732da776"
ENV NODE_VERSION=16.13.0
ENV AWSCLI_VERSION=1.16.240
ENV CODEOWNERS_VERSION=0.4.0
ENV INVOKE_VERSION=1.6.0
ENV DATADOG_CI_VERSION=2.17.0

RUN apt update && apt install -y curl git python3 python3-pip
RUN pip install awscli==${AWSCLI_VERSION} codeowners==${CODEOWNERS_VERSION} invoke==${INVOKE_VERSION}

RUN curl -L https://raw.githubusercontent.com/tj/n/v${N_VERSION}/bin/n -o n \
    && echo "${N_SHA256}  n" | sha256sum --check \
    && bash n ${NODE_VERSION} \
    && npm install -g @datadog/datadog-ci@${DATADOG_CI_VERSION}
