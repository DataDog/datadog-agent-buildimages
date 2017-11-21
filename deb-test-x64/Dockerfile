FROM debian:stretch
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Environment
ENV GIMME_GO_VERSION 1.9.1
ENV GOPATH /
ENV CONDA_PATH /root/miniconda2

RUN echo "deb http://deb.debian.org/debian stretch contrib non-free" >> /etc/apt/sources.list
RUN apt-get update && apt-get install -y fakeroot curl git procps bzip2 \
  python2.7-dev python-pip \
  libsnmp-base libsnmp-dev snmp-mibs-downloader

# Invoke
RUN pip install invoke

# Gimme
RUN curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
RUN chmod +x /bin/gimme
RUN gimme $GIMME_GO_VERSION

# Conda
RUN curl -sL -o ~/miniconda.sh https://repo.continuum.io/miniconda/Miniconda2-4.2.12-Linux-x86_64.sh
RUN bash ~/miniconda.sh -b
COPY ./conda.sh /etc/profile.d/

# Docker
RUN curl -fsSL https://get.docker.com/ | sh

# Entrypoint
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# create the agent build folder within $GOPATH
RUN mkdir -p /src/github.com/DataDog/datadog-agent

ENTRYPOINT ["/entrypoint.sh"]
