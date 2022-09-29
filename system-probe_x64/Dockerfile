FROM debian:buster

ARG DEBIAN_FRONTEND=noninteractive
ARG GIMME_GO_VERSION=1.18.6

ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV GOPATH=/go

# We need up-to-date kernel headers to be able to use newly available eBPF helpers in programs.
RUN echo "deb http://deb.debian.org/debian buster-backports main" | tee -a /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils && apt-get dist-upgrade -y && apt-get install -y --no-install-recommends \
        bison \
        cmake \
        curl \
        flex \
        g++ \
        gcc \
        gcc-multilib \
        git \
        libbpf-dev \
        libedit-dev \
        libelf-dev \
        libfl-dev \
        libstdc++-8-dev \
        libtinfo-dev \
        libtinfo5 \
        libxml2-dev \
        libzip-dev \
        $(apt-cache search --names-only linux-headers-5.* | \
          cut -d " " -f 1 | \
          grep "\-common$" | \
          sed -rn 's/(.*deb10\.)([0-9]+)-common/\2 \0 \1\2-amd64/p' | \
          sort -gr | \
          head -n 1 | \
          cut -f 2-3 -d " ") \
        linux-libc-dev \
        make \
        ninja-build \
        patch \
        pkg-config \
        python \
        python3-distro \
        python3-distutils \
        python3-netaddr \
        python3-setuptools \
        python3-pip \
        python3-pyroute2 \
        python3-dev \
        wget \
        xz-utils \
        lsb-release \
        software-properties-common \
        gnupg 

RUN wget -O /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/v1.5.4/gimme
RUN echo "03b295636d4e22870b6f6e9bc06a71d65311ae90d3d48cbc7071f82dd5837fbc  /bin/gimme" | sha256sum --check
RUN chmod +x /bin/gimme
RUN gimme $GIMME_GO_VERSION

ENV PATH "${GOPATH}/bin:${PATH}"

# create the agent build folder within $GOPATH
RUN mkdir -p $GOPATH/src/github.com/DataDog/datadog-agent

# install clang from the website since the package manager can change at any time
RUN wget https://apt.llvm.org/llvm.sh -O /tmp/llvm.sh
RUN echo "417d84fce3e1820775598b1c3c33185bb36becf64ad744bf8b97b80128dc9649  /tmp/llvm.sh" | sha256sum --check
RUN chmod +x /tmp/llvm.sh
RUN /tmp/llvm.sh 14

RUN echo "141d7956bbec3aad276d9f99304bcc910226ea5678d16cc3c78ca8b4bc85279c  /usr/bin/clang-14" | sha256sum --check
RUN echo "1f2f4d7a3dda9dbfe45880289c1bb2a86aa50211823b6877b89bd33c62162fde  /usr/bin/llc-14" | sha256sum --check
RUN mkdir -p /opt/clang/bin
RUN ln -s /usr/bin/clang-14 /opt/clang/bin/clang
RUN ln -s /usr/bin/llc-14 /opt/clang/bin/llc
RUN ln -s /usr/bin/llvm-strip-14 /opt/clang/bin/llvm-strip
ENV PATH "/opt/clang/bin:${PATH}"

COPY ./requirements.txt /
RUN python3 -m pip install wheel
RUN python3 -m pip install -r requirements.txt

COPY ./entrypoint-sysprobe.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
