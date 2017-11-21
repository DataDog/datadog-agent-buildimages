FROM debian:wheezy-backports
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Environment
ENV GIMME_GO_VERSION 1.9.1
ENV GOPATH /
ENV CONDA_PATH /root/miniconda2

RUN echo "deb http://deb.debian.org/debian wheezy contrib non-free" >> /etc/apt/sources.list
RUN apt-get update && apt-get install -y fakeroot curl git procps bzip2 \
  python2.7-dev python-pip \
  libsnmp-base libsnmp-dev snmp-mibs-downloader

# Invoke
RUN pip install -i https://pypi.python.org/simple/ invoke
RUN pip install -i https://pypi.python.org/simple/ awscli==1.11.152

# RVM
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
RUN curl -sSL https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.3 && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --no-ri --no-rdoc"

# Gimme
RUN curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
RUN chmod +x /bin/gimme
RUN gimme $GIMME_GO_VERSION

# Docker
RUN curl -fsSL https://get.docker.com/ | sh

# Entrypoint
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# create the agent build folder within $GOPATH
RUN mkdir -p /src/github.com/DataDog/datadog-agent

ENTRYPOINT ["/entrypoint.sh"]
