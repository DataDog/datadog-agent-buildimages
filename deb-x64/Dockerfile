FROM ubuntu as CURL_GETTER
ENV CURL_VERSION=7.79.1
ENV CURL_SHA256="0a89440848db3ba21d38b93b450d90fb84d4d0fa5562aa9c6933070b0eddc960"
RUN apt-get update && apt-get install -y wget
RUN wget https://github.com/moparisthebest/static-curl/releases/download/v${CURL_VERSION}/curl-amd64
RUN echo "${CURL_SHA256}  curl-amd64" | sha256sum --check

FROM ubuntu:14.04

# Build Args
ARG GIT_VERSION=2.10.1
ARG GIT_SHA256="78553f786f1a66cb68983c170be482558028a3376056c0f2ed366f331b1e35f2"
ARG GO_VERSION
ARG GO_SHA256_LINUX_AMD64
ARG IBM_MQ_VERSION=9.2.4.0
ARG IBM_MQ_SHA256="d0d583eba72daf20b3762976f8831c2e23150ace90509520e12f8cda5b5bdb49"
ARG CMAKE_VERSION=3.23.0
ARG CMAKE_SHA256="5eaf3ded8255b3d149c7aad68c473f01c2345dce872e03c92f2e9c0185dfa75a"
ARG CLANG_VERSION=8.0.0
ARG CLANG_SHA256="9ef854b71949f825362a119bf2597f744836cb571131ae6b721cd102ffea8cd0"
ARG DD_TARGET_ARCH=x64
ARG RUST_VERSION=1.64.0
ARG RUSTC_SHA256="0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db"
ARG RUSTUP_VERSION=1.26.0
ARG RUSTUP_SHA256="0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db"
ARG PATCHELF_VERSION=0.13.1
ARG PATCHELF_SHA256="f6d5ecdb51ad78e963233cfde15020f9eebc9d9c7c747aaed54ce39c284ad019"
ARG BUNDLER_VERSION=2.4.20
ARG DPKG_VERSION=1.18.4
ARG DPKG_SHA256=19f332e26d40ee45c976ff9ef1a3409792c1f303acff714deea3b43bb689dc41
ARG GETTEXT_VERSION=0.19.8
ARG GETTEXT_SHA256=9c1781328238caa1685d7bc7a2e1dcf1c6c134e86b42ed554066734b621bd12f
ARG LIBLZMA_VERSION=5.2.11
ARG LIBLZMA_SHA256=503b4a9fb405e70e1d3912e418fdffe5de27e713e58925fb67e12d20d03a77bc

# Environment
ENV GOPATH /go
ENV GO_VERSION $GO_VERSION
ENV CONDA_PATH /root/miniforge3
ENV DD_TARGET_ARCH $DD_TARGET_ARCH

# Remove the early return on non-interactive shells, which makes sourcing the file not activate conda
RUN grep -v return /root/.bashrc >> /root/newbashrc && cp /root/newbashrc /root/.bashrc

# Uncommenting the two lines below makes APT use a gpgv wrapper that ignores key expiration
# date but checks package signatures. Useful when the base distro is unsupported for
# a long time and its repodata signatures expire.
#COPY gpgvnoexpkeysig /usr/local/sbin
#RUN echo 'Dir::Bin::gpg "/usr/local/sbin/gpgvnoexpkeysig";' >> /etc/apt/apt.conf.d/20datadog

# Mitigation for CVE-2019-3462
RUN echo 'Acquire::http::AllowRedirect"false";' >> /etc/apt/apt.conf.d/20datadog
# Ignore expired repos signature
# Jessie is EOL, security updates repo will not get any newer updates, or will do so
# in arbitrary, unscheduled timeframes. At the time of this writing the repo has
# expired making the following option necessary for apt to work.
RUN echo 'Acquire::Check-Valid-Until "false";' >> /etc/apt/apt.conf.d/20datadog

RUN apt-get update && apt-get install -y fakeroot procps bzip2 \
  build-essential pkg-config libssl-dev libcurl4-openssl-dev libexpat-dev libpq-dev libz-dev \
  libsystemd-journal-dev rpm tar gettext libtool autopoint autoconf pkg-config flex \
  selinux-basics libtool software-properties-common default-jre texinfo pxz wget binutils-2.26

# Ubuntu 14.04 comes with gcc 4.8 by default, which has a tough time compiling newer Go versions
# NOTE: we *could* uninstall gcc 4.8, but the "rvm requirements" run later on would reinstall
# it and there's not way to prevent that. So leave it be and use update-alternatives to select 4.9
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test
RUN apt-get update \
    && apt-get install -y gcc-9 g++-9 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 0

# Ensure we're using the newest binutils
ENV PATH "/usr/lib/binutils-2.26/bin:$PATH"

# Update curl with a statically linked binary
COPY --from=CURL_GETTER /curl-amd64 /usr/local/bin/curl
RUN chmod +x /usr/local/bin/curl

# The dpkg version we want to install requires a more recent version of
# gettext than the one shipped in ubuntu 14.04. Even though we disable i18n,
# their buildsystem still needs gettext
RUN curl -LO https://ftp.gnu.org/gnu/gettext/gettext-${GETTEXT_VERSION}.tar.xz \
    && echo "${GETTEXT_SHA256}  gettext-${GETTEXT_VERSION}.tar.xz" | sha256sum --check \
    && tar xf "gettext-${GETTEXT_VERSION}.tar.xz" \
    && cd "gettext-${GETTEXT_VERSION}" \
    && ./configure --prefix=/usr && make -j$(nproc) && make install \
    && cd / \
    && rm -rf "gettext-${GETTEXT_VERSION}"

# Now install a recent enough liblzma (5.2+) which supports parallel compression
RUN curl -LO https://github.com/tukaani-project/xz/releases/download/v${LIBLZMA_VERSION}/xz-${LIBLZMA_VERSION}.tar.xz \
    && echo "${LIBLZMA_SHA256} /xz-5.2.11.tar.xz" | sha256sum --check \
    && tar -xf /xz-${LIBLZMA_VERSION}.tar.xz \
    && cd xz-${LIBLZMA_VERSION} \
    && ./configure --prefix=/usr/ \
    && make -j$(nproc) && make install \
    && cp /usr/lib/liblzma.so* /lib/x86_64-linux-gnu/ \
    && rm -rf /xz-${LIBLZMA_VERSION}

RUN curl -LO https://salsa.debian.org/dpkg-team/dpkg/-/archive/${DPKG_VERSION}/dpkg-${DPKG_VERSION}.tar.bz2 \
    && echo "${DPKG_SHA256}  dpkg-${DPKG_VERSION}.tar.bz2" | sha256sum --check \
    && tar -xf "dpkg-${DPKG_VERSION}.tar.bz2" \
    && cd "dpkg-${DPKG_VERSION}" \
    && echo 1.18.4 > .dist-version \
    && autoreconf -vfi \
    && mkdir build && cd build \
    && PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ../configure --disable-nls --disable-dselect --prefix=/usr --localstatedir=/var \
    && make -j$(nproc) \
    && make install \
    && rm -rf /dpkg-${DPKG_VERSION}.tar.bz2 /dpkg-${DPKG_VERSION}

# Git
RUN curl -OL https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz \
    && echo "${GIT_SHA256}  git-${GIT_VERSION}.tar.gz" | sha256sum --check \
    # --no-same-owner: git tarball has a file with UID 110493 which makes pulling this image fail, because we use docker user namespacing and we can't have >65K UIDs. \
    && tar xzf git-${GIT_VERSION}.tar.gz --no-same-owner \
    && cd git-${GIT_VERSION} \
    && make -j$(nproc) prefix=/usr/local all \
    && make prefix=/usr/local install \
    && cd .. \
    && rm -rf git-${GIT_VERSION} git-${GIT_VERSION}.tar.gz

RUN git config --global user.email "package@datadoghq.com" && \
    git config --global user.name "Bits"

# IBM MQ
RUN mkdir -p /opt/mqm \
    && curl "https://s3.amazonaws.com/dd-agent-omnibus/ibm-mq-backup/${IBM_MQ_VERSION}-IBM-MQC-Redist-LinuxX64.tar.gz" -o /tmp/mq_client.tar.gz \
    && echo "${IBM_MQ_SHA256}  /tmp/mq_client.tar.gz" | sha256sum --check \
    && tar -C /opt/mqm -xf /tmp/mq_client.tar.gz \
    && rm -rf /tmp/mq_client.tar.gz

# CONDA
COPY python-packages-versions.txt setup_python.sh requirements.txt requirements-py2.txt /
COPY requirements /requirements
RUN ./setup_python.sh
ENV PATH "${CONDA_PATH}/condabin:${PATH}"
ENV PKG_CONFIG_LIBDIR "${PKG_CONFIG_LIBDIR}:${CONDA_PATH}/lib/pkgconfig"

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/

# RVM
COPY ./rvm/gpg-keys /gpg-keys
RUN gpg --import /gpg-keys/*
RUN rm -rf /gpg-keys
RUN curl -sSL -o get-rvm.sh https://raw.githubusercontent.com/rvm/rvm/1.29.12/binscripts/rvm-installer \
    && echo "fea24461e98d41528d6e28684aa4c216dbe903869bc3fcdb3493b6518fae2e7e  get-rvm.sh" | sha256sum --check \
    && bash get-rvm.sh stable --version 1.29.12 \
    && echo "d2de0b610ee321489e5c673fe749e13be8fb34c0aa08a74446d87f95a17de730  /usr/local/rvm/bin/rvm" | sha256sum --check \
    && rm get-rvm.sh
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.7 --with-openssl-dir=${CONDA_PATH} && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --version $BUNDLER_VERSION --no-document"
RUN echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc

# CMake
RUN set -ex \
    && curl -sL -o cmake.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh \
    && echo "${CMAKE_SHA256}  cmake.sh" | sha256sum --check \
    && mkdir -p /opt/cmake/ \
    && sh cmake.sh --skip-license --prefix=/opt/cmake \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && rm cmake.sh

# Install clang and llvm version 8
RUN curl -LO https://releases.llvm.org/${CLANG_VERSION}/clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-14.04.tar.xz \
    && echo "${CLANG_SHA256}  clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-14.04.tar.xz" | sha256sum --check \
    && tar -xf clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-14.04.tar.xz --no-same-owner --strip 1 -kC /usr/ \
    && rm clang+llvm-${CLANG_VERSION}-x86_64-linux-gnu-ubuntu-14.04.tar.xz

# To build the EBPF code we need kernel headers for Linux 4.9
RUN curl -Sl -O https://dd-agent-omnibus.s3.amazonaws.com/kernel-4.9-headers-deb-x64.tgz \
    && echo "245f31a066460a51849365009557f61350e46579288e3f46cf9f44b3f5bee3ed  kernel-4.9-headers-deb-x64.tgz" | sha256sum --check \
    && tar xf kernel-4.9-headers-deb-x64.tgz --no-same-owner --strip 1 -C /usr \
    && rm kernel-4.9-headers-deb-x64.tgz

# Go
RUN curl -sL -o /tmp/golang.tar.gz https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz \
  && echo "$GO_SHA256_LINUX_AMD64  /tmp/golang.tar.gz" | sha256sum --check \
  && tar -C /usr/local -xzf /tmp/golang.tar.gz \
  && rm -f /tmp/golang.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
ENV PATH="${GOPATH}/bin:${PATH}"

# Rust is needed to compile some python libs
RUN curl -sSL -o rustup-init https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init \
    && echo "${RUSTUP_SHA256}  rustup-init" | sha256sum --check \
    && chmod +x ./rustup-init \
    && ./rustup-init -y --profile minimal --default-toolchain ${RUST_VERSION} \
    && echo "${RUSTC_SHA256}  $HOME/.cargo/bin/rustc" | sha256sum --check \
    && rm ./rustup-init
ENV PATH "~/.cargo/bin:${PATH}"

# Setup patchelf
RUN curl -L -o patchelf-${PATCHELF_VERSION}.tar.gz https://github.com/NixOS/patchelf/archive/refs/tags/${PATCHELF_VERSION}.tar.gz \
    && echo "${PATCHELF_SHA256}  patchelf-${PATCHELF_VERSION}.tar.gz" | sha256sum --check \
    && tar xvzf patchelf-${PATCHELF_VERSION}.tar.gz \
    && cd patchelf-${PATCHELF_VERSION}  \
    && ./bootstrap.sh \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && cd - \
    && rm -rf patchelf-${PATCHELF_VERSION} \
    && rm patchelf-${PATCHELF_VERSION}.tar.gz

# create the agent build folder within $GOPATH
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

# Force umask to 0022
RUN echo "umask 0022" >> /root/.bashrc

# Entrypoint - only for local usage, Kubernetes-based Gitlab runners overwrite this
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
