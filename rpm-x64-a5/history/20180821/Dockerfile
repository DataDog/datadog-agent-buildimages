FROM datadog/docker-dd-agent-build-rpm-x64:20180108
MAINTAINER Remi Hakim @remh

# Update go to 1.10.3
RUN curl -o /tmp/go1.10.3.linux-amd64.tar.gz https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf /tmp/go1.10.3.linux-amd64.tar.gz
