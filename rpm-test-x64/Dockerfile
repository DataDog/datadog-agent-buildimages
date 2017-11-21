FROM centos:7

# Environment
ENV GOPATH /
ENV GIMME_GO_VERSION 1.9.1
ENV CONDA_PATH /root/miniconda2

RUN yum groupinstall -y development
RUN yum -y install \
  which perl-ExtUtils-MakeMaker \
  curl-devel expat-devel gettext-devel openssl-devel zlib-devel bzip2 \
  net-snmp net-snmp-devel \
  glibc-static

# Git
RUN curl -O https://www.kernel.org/pub/software/scm/git/git-2.10.1.tar.gz
# --no-same-owner: git tarball has a file with UID 110493 which makes pulling this image fail, because we use docker user namespacing and we can't have >65K UIDs.
RUN tar xzf git-2.10.1.tar.gz --no-same-owner
RUN cd git-2.10.1 && make prefix=/usr/local all
RUN cd git-2.10.1 && make prefix=/usr/local install
RUN rm -rf git-2.10.1 git-2.10.1.tar.gz

RUN git config --global user.email "package@datadoghq.com"
RUN git config --global user.name "Bits"

# Gimme
RUN curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
RUN chmod +x /bin/gimme
RUN gimme $GIMME_GO_VERSION

# Docker
RUN curl -fsSL get.docker.com -o get-docker.sh
RUN sh get-docker.sh

# Conda
RUN curl -sL -o ~/miniconda.sh https://repo.continuum.io/miniconda/Miniconda2-4.2.12-Linux-x86_64.sh
RUN bash ~/miniconda.sh -b
COPY ./conda.sh /etc/profile.d/
ENV PKG_CONFIG_LIBDIR $PKG_CONFIG_LIBDIR:$CONDA_PATH/lib/pkgconfig
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$CONDA_PATH/lib

# Entrypoint
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# Invoke
RUN $CONDA_PATH/bin/pip install invoke

# create the agent build folder within $GOPATH
RUN mkdir -p /src/github.com/DataDog/datadog-agent

ENTRYPOINT ["/entrypoint.sh"]
