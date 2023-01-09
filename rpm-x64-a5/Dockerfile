FROM ubuntu as CURL_GETTER
ENV CURL_VERSION=7.79.1
ENV CURL_SHA256="0a89440848db3ba21d38b93b450d90fb84d4d0fa5562aa9c6933070b0eddc960"
RUN apt-get update && apt-get install -y wget
RUN wget https://github.com/moparisthebest/static-curl/releases/download/v${CURL_VERSION}/curl-amd64
RUN echo "${CURL_SHA256}  curl-amd64" | sha256sum --check


FROM centos:5.11
MAINTAINER Remi Hakim @remh

ARG PERL_VERSION=5.28.1
ARG CURL_VERSION=7.64.0
ARG BUNDLER_VERSION_ARG=1.17.3
ARG RUBY_VERSION_ARG=2.5
ARG GOLANG_VERSION_ARG=1.10.3
ARG TAR_VERSION_ARG=1.23
ARG GIT_VERSION_ARG=2.27.1
ARG OPENSSL_VERSION_ARG=1.1.0j

RUN rm -f /etc/yum.repos.d/*

COPY ./CentOS-Base.repo \
     ./libselinux.repo /etc/yum.repos.d/

# Update curl with a statically linked binary
COPY --from=CURL_GETTER /curl-amd64 /usr/local/bin/curl
RUN chmod +x /usr/local/bin/curl

RUN yum --disableplugin=fastestmirror -d10 -y update
RUN yum  --disableplugin=fastestmirror -y install \
    automake \
    autoconf \
    install \
    fakeroot \
    gpg \
    make \
    perl-ExtUtils-MakeMaker \
    rpm-build \
    which \
    xz \
    # Dependencies below are for rrdtool..
    intltool \
    gettext \
    cairo-devel \
    libxml2-devel \
    pango-devel \
    pango \
    libpng-devel \
    freetype \
    freetype-devel \
    libart_lgpl-devel \
    gcc \
    groff \
    wget \
    automake \
    libffi-devel \
    libyaml-devel


# Install Perl from source.
# OpenSSL requires >= 5.10.0, repositories have 5.8.8.
RUN set -ex; \
    cd /usr/local/src; \
    curl --insecure http://www.cpan.org/src/5.0/perl-$PERL_VERSION.tar.gz -LO; \
    tar -xf perl-$PERL_VERSION.tar.gz; \
    rm -f perl-$PERL_VERSION.tar.gz; \
    cd perl-$PERL_VERSION; \
    ./Configure -des; \
    make -j $(grep -c processor /proc/cpuinfo); \
    make install; \
    cd ..; \
    rm -rf perl-$PERL_VERSION

ENV OPENSSL_DIR /usr/local/ssl

RUN curl -o /tmp/openssl-$OPENSSL_VERSION_ARG.tar.gz http://artfiles.org/openssl.org/source/old/$(echo $OPENSSL_VERSION_ARG | awk '{print substr($0,0, length($0)-1)}')/openssl-$OPENSSL_VERSION_ARG.tar.gz && \
    cd /tmp && tar -xzf /tmp/openssl-$OPENSSL_VERSION_ARG.tar.gz && \
    cd /tmp/openssl-$OPENSSL_VERSION_ARG && ./Configure linux-x86_64 no-shared --prefix=${OPENSSL_DIR} --openssldir=${OPENSSL_DIR} -fPIC && make && make install && \
    echo "${OPENSSL_DIR}/lib" >> /etc/ld.so.conf && ldconfig && \
    cd - && rm -rf /tmp/openssl-$OPENSSL_VERSION_ARG && rm /tmp/openssl-$OPENSSL_VERSION_ARG.tar.gz


RUN mkdir -p /etc/ssl/certs/ && curl --insecure -sSL -o /etc/ssl/certs/ca-certificates.crt https://curl.se/ca/cacert-2022-10-11.pem  

# Install tar >> 1.23 so that Omnibus can use the -J option
RUN curl -o /tmp/tar-$TAR_VERSION_ARG.tar.gz -L http://ftp.gnu.org/gnu/tar/tar-$TAR_VERSION_ARG.tar.gz
RUN cd /tmp && tar -xzf /tmp/tar-$TAR_VERSION_ARG.tar.gz && \
    rm -f /bin/tar /bin/gtar && \
    cd /tmp/tar-$TAR_VERSION_ARG && FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/ && make && make install && \
    ln -sf /bin/tar /bin/gtar && \
    cd - && rm -rf /tmp/tar-$TAR_VERSION_ARG.tar.gz

ENV CURL_DIR /opt/curl

RUN curl -L -o /tmp/curl-${CURL_VERSION}.tar.gz https://curl.haxx.se/download/curl-$CURL_VERSION.tar.gz
RUN cd /tmp && tar -xzf /tmp/curl-${CURL_VERSION}.tar.gz && \
    cd /tmp/curl-${CURL_VERSION} && \
    LIBS="-ldl" ./configure --enable-static --prefix=${CURL_DIR} --with-ssl=${OPENSSL_DIR} && \
    make all && \
    make install && \
    cd - && \
    rm -rf /tmp/curl-${CURL_VERSION} && \
    rm -f /tmp/curl-${CURL_VERSION}.tar.gz

ENV PATH="/opt/curl/bin:${PATH}"

RUN mkdir -p /etc/ld.so.conf.d/ && echo "/opt/curl/lib" > /etc/ld.so.conf.d/optcurl.conf && ldconfig

# now build git
# dependencies
RUN yum -y install \
    expat-devel \
    gettext-devel \
    perl-devel \
    zlib-devel

RUN curl -o /tmp/git-$GIT_VERSION_ARG.tar.gz -L https://www.kernel.org/pub/software/scm/git/git-$GIT_VERSION_ARG.tar.gz && \
    cd /tmp && tar -xzf /tmp/git-$GIT_VERSION_ARG.tar.gz && \
    cd /tmp/git-$GIT_VERSION_ARG && make configure && ./configure --with-ssl --prefix=/usr \
       OPENSSLDIR=${OPENSSL_DIR} \
       CURLDIR=${CURL_DIR} \
       CPPFLAGS="-I${CURL_DIR}/include -I${OPENSSL_DIR}/include" \
       LDFLAGS="-ldl -L${CURL_DIR}/lib -L${OPENSSL_DIR}/lib" && make all && make install && \
    cd - && rm -rf /tmp/git-$GIT_VERSION_ARG && rm -f /tmp/git-$GIT_VERSION_ARG.tar.gz

# Set up an RVM with Ruby 2.1.5
# RUN gpg --keyserver hkp://keys.openpgp.org --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl --insecure -sSL https://get.rvm.io | bash -s stable && \
    /bin/bash -l -c "rvm requirements" && \
    /bin/bash -l -c "rvm install 2.1.5" && \
    rm -rf /usr/local/rvm/src/ruby-2.1.5


# setup ruby 2.2.2 with bootstrap ruby, setting up the CERTS
ENV CPPFLAGS "-I/usr/local/rvm/gems/ruby-$RUBY_VERSION_ARG/include"
RUN /bin/bash -l -c "rvm install $RUBY_VERSION_ARG --with-openssl-dir=${OPENSSL_DIR} --with-curl-lib" && \
    /bin/bash -l -c "rvm --default use $RUBY_VERSION_ARG" && \
    /opt/curl/bin/curl -kfsSL curl.haxx.se/ca/cacert.pem \
                       -o $(/bin/bash -l -c "ruby -ropenssl -e 'puts OpenSSL::X509::DEFAULT_CERT_FILE'") && \
    /bin/bash -l -c "gem install bundler -v $BUNDLER_VERSION_ARG" && rm -rf /usr/local/rvm/src/ruby-$RUBY_VERSION_ARG
RUN unset CPPFLAGS

# Install go (required by to build gohai)
# Update go to 1.10.3
RUN curl -o /tmp/go$GOLANG_VERSION_ARG.linux-amd64.tar.gz https://dl.google.com/go/go$GOLANG_VERSION_ARG.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf /tmp/go$GOLANG_VERSION_ARG.linux-amd64.tar.gz && \
    echo "PATH=$PATH:/usr/local/go/bin" | tee /etc/profile.d/go.sh


RUN git config --global user.email "package@datadoghq.com" && \
    git config --global user.name "Centos Omnibus Package" && \
    git config --global url."https://".insteadOf git:// && \
    git clone https://github.com/DataDog/dd-agent-omnibus.git

RUN cd dd-agent-omnibus && \
    /bin/bash -l -c "OMNIBUS_RUBY_BRANCH='datadog-5.5.0' bundle install --binstubs"

RUN git clone https://github.com/DataDog/integrations-extras.git
RUN git clone --progress https://github.com/DataDog/integrations-core.git

RUN echo -e '[datadog]\nname = Datadog, Inc.\nbaseurl = http://yum.datadoghq.com/rpm/x86_64/\nenabled=1\ngpgcheck=1\npriority=1\ngpgkey=http://yum.datadoghq.com/DATADOG_RPM_KEY.public' > /etc/yum.repos.d/datadog.repo

ADD checkout_omnibus_branch.sh /

VOLUME ["/dd-agent-omnibus/pkg"]

ENTRYPOINT /bin/bash -l /checkout_omnibus_branch.sh
