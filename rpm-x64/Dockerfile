ARG BASE_IMAGE="centos:6"

FROM ubuntu as CERT_GETTER
ENV CACERT_BUNDLE_VERSION=2023-01-10
ENV CACERT_BUNDLE_SHA256="fb1ecd641d0a02c01bc9036d513cb658bbda62a75e246bedbc01764560a639f0"
RUN apt-get update && apt-get install -y wget
RUN wget "https://curl.se/ca/cacert-${CACERT_BUNDLE_VERSION}.pem" -O /cacert.pem
RUN echo "${CACERT_BUNDLE_SHA256}  /cacert.pem" | sha256sum --check

FROM $BASE_IMAGE
ARG BASE_IMAGE

# Build Args
ARG GIT_VERSION=2.10.1
ARG GIT_SHA256="78553f786f1a66cb68983c170be482558028a3376056c0f2ed366f331b1e35f2"
ARG GIMME_GO_VERSION=1.19.8
ARG IBM_MQ_VERSION=9.2.4.0
ARG IBM_MQ_SHA256="d0d583eba72daf20b3762976f8831c2e23150ace90509520e12f8cda5b5bdb49"
ARG CMAKE_VERSION=3.23.0
ARG CMAKE_SHA256="5eaf3ded8255b3d149c7aad68c473f01c2345dce872e03c92f2e9c0185dfa75a"
ARG CLANG_VERSION=8.0.0
ARG CLANG_SHA256="7e2846ff60c181d1f27d97c23c25a2295f5730b6d88612ddd53b4cbb8177c4b9"
ARG DD_TARGET_ARCH=x64
ARG RUST_VERSION=1.60.0
ARG RUSTC_SHA256="3dc5ef50861ee18657f9db2eeb7392f9c2a6c95c90ab41e45ab4ca71476b4338"
ARG RUSTUP_VERSION=1.24.3
ARG RUSTUP_SHA256="3dc5ef50861ee18657f9db2eeb7392f9c2a6c95c90ab41e45ab4ca71476b4338"
ARG PERLBREW_VERSION=0.96
ARG PERLBREW_SHA256="c3996e4fae37a0ae01839cdd73752fb7b17e81bac2a8b39712463a7d518c4945"
ARG PERL_VERSION=5.36.0
ARG BINUTILS_VERSION="2.39"
ARG BINUTILS_SHA256="d12ea6f239f1ffe3533ea11ad6e224ffcb89eb5d01bbea589e9158780fa11f10"
ARG GCC_VERSION=10.4.0
ARG GCC_SHA256=ab1974017834430de27fd803ade4389602a7d6ca1362496c57bef384b2a4cb07

# Environment
ENV GOPATH /go
ENV GIT_VERSION $GIT_VERSION
ENV GIT_SHA256 $GIT_SHA256
ENV GIMME_GO_VERSION $GIMME_GO_VERSION
ENV IBM_MQ_VERSION $IBM_MQ_VERSION
ENV IBM_MQ_SHA256 $IBM_MQ_SHA256
ENV CMAKE_VERSION $CMAKE_VERSION
ENV CMAKE_SHA256 $CMAKE_SHA256
ENV CLANG_VERSION $CLANG_VERSION
ENV CLANG_SHA256 $CLANG_SHA256
ENV CONDA_PATH /root/miniconda3
ENV DD_TARGET_ARCH $DD_TARGET_ARCH
ENV RUST_VERSION $RUST_VERSION
ENV RUSTC_SHA256 $RUSTC_SHA256
ENV PERLBREW_VERSION $PERLBREW_VERSION
ENV PERLBREW_SHA256 $PERLBREW_SHA256
ENV PERL_VERSION $PERL_VERSION
ENV BINUTILS_VERSION $BINUTILS_VERSION
ENV BINUTILS_SHA256 $BINUTILS_SHA256
ENV BASE_IMAGE $BASE_IMAGE
ENV GCC_VERSION $GCC_VERSION

# persist RHEL major for readable output
RUN echo $(cat /etc/redhat-release | cut -d'.' -f1 | awk '{print $NF}') > /etc/redhat-release-major

# Enable the vault (archive) repos, as we are past CentOS6 EOL
RUN if [[ $(cat /etc/redhat-release-major) == 6 ]]; then \ 
    sed -is 's/enabled=0/enabled=1/g' /etc/yum.repos.d/CentOS-Vault.repo && \
    sed -ie 's/6\.9/6.10/g' /etc/yum.repos.d/CentOS-Vault.repo && \
    rm /etc/yum.repos.d/CentOS-Base.repo; fi

# The last two lines contain dependencies for build of newer libarchive and rpm
RUN yum -y install \
  @development \
  which perl-ExtUtils-MakeMaker perl-parent \
  pkgconfig \
  curl-devel expat-devel gettext-devel openssl-devel zlib-devel bzip2 \
  glibc-static tar libtool \
  bzip2-devel e2fsprogs-devel file-devel libacl-devel libattr-devel \
  libxml2-devel lzo-devel nss nss-devel popt-devel postgresql-devel sharutils xz-devel java \
  texinfo \
  && yum clean all

RUN if [[ $(cat /etc/redhat-release-major) != 6 ]]; then \ 
     yum -y install policycoreutils-python; \ 
    fi

COPY --from=CERT_GETTER /cacert.pem /etc/pki/tls/certs/ca-bundle.crt

# We install our own ruby, let's remove the system one. It made rvm fail to build ruby for some reason
RUN yum remove -y ruby

# Autoconf
# We need a newer version of autoconf to compile procps-ng and also new rpm version (installing 2.69 over 2.63).
RUN if [[ "$(cat /etc/redhat-release-major)" == 6 ]]; then \ 
    curl -sL -o /tmp/autoconf-2.69.tar.gz https://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz \
    && echo "954bd69b391edc12d6a4a51a2dd1476543da5c6bbf05a95b59dc0dd6fd4c2969  /tmp/autoconf-2.69.tar.gz" | sha256sum --check \
    && cd /tmp \
    && tar -xvf /tmp/autoconf-2.69.tar.gz --no-same-owner \
    && cd autoconf-2.69 \
    && ./configure \
    && make && make install \
    && cd / \
    && rm -rf /tmp/autoconf-2.69 /tmp/autoconf-2.69.tar.gz; fi

# New libarchive is required for the new rpm version
RUN if [[ "$(cat /etc/redhat-release-major)" == 6 ]]; then \ 
    curl -sL -o /tmp/libarchive-3.1.2-12.el7.src.rpm https://vault.centos.org/7.7.1908/os/Source/SPackages/libarchive-3.1.2-12.el7.src.rpm \
    && echo "9584008f5afe3fc18351c40c2cb627193f1d7c92480dea0161f11f6b63e575d2  /tmp/libarchive-3.1.2-12.el7.src.rpm" | sha256sum --check \
    && rpmbuild --rebuild /tmp/libarchive-3.1.2-12.el7.src.rpm \
    && rpm -Uvh --nodeps /root/rpmbuild/RPMS/x86_64/* \
    && rm -rf /tmp/libarchive-3.1.2-12.el7.src.rpm /root/rpmbuild; fi

# Actually build new rpm
COPY patches/rpm-4.15.1-fix-rpmbuild-segfault.patch /tmp
# Cannot use HTTPS here: cert name is invalid
RUN if [[ "$(cat /etc/redhat-release-major)" == 6 ]]; then \ 
    curl -sL -o /tmp/rpm-4.15.1.tar.bz2 http://ftp.rpm.org/releases/rpm-4.15.x/rpm-4.15.1.tar.bz2 \
    && echo "ddef45f9601cd12042edfc9b6e37efcca32814e1e0f4bb8682d08144a3e2d230  /tmp/rpm-4.15.1.tar.bz2" | sha256sum --check \
    && cd /tmp \
    && tar -xjf /tmp/rpm-4.15.1.tar.bz2 \
    && cd rpm-4.15.1 \
    && cat /tmp/rpm-4.15.1-fix-rpmbuild-segfault.patch | patch -p1 \
    && ./configure --without-lua --without-audit \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/rpm-4.15.1-fix-rpmbuild-segfault.patch /tmp/rpm-4.15.1.tar.bz2 /tmp/rpm-4.15.1; fi

# Rebuild RPM database with the new rpm
RUN if [[ "$(cat /etc/redhat-release-major)" == 6 ]]; then \ 
    mkdir -p /usr/local/var/lib/rpm \
    && cp /var/lib/rpm/Packages /usr/local/var/lib/rpm/Packages \
    && /usr/local/bin/rpm --rebuilddb; fi

# Git
RUN curl -OL "https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz" \
    && echo "${GIT_SHA256}  git-${GIT_VERSION}.tar.gz" | sha256sum --check \
    # --no-same-owner: git tarball has a file with UID 110493 which makes pulling this image fail, because we use docker user namespacing and we can't have >65K UIDs. \
    && tar xzf "git-${GIT_VERSION}.tar.gz" --no-same-owner \
    && cd "git-${GIT_VERSION}" \
    && make prefix=/usr/local all \
    && make prefix=/usr/local install \
    && cd .. \
    && rm -rf "git-${GIT_VERSION}" "git-${GIT_VERSION}.tar.gz"

RUN git config --global user.email "package@datadoghq.com"
RUN git config --global user.name "Bits"

# CONDA
COPY ./python-packages-versions.txt /python-packages-versions.txt
COPY ./setup_python.sh /setup_python.sh
COPY ./requirements.txt ./requirements-py2.txt /
RUN ./setup_python.sh
ENV PATH "${CONDA_PATH}/condabin:${PATH}"
ENV PKG_CONFIG_LIBDIR "${PKG_CONFIG_LIBDIR}:${CONDA_PATH}/lib/pkgconfig"

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
RUN /bin/bash -l -c "rvm install 2.6 --with-openssl-dir=${CONDA_PATH} && rvm cleanup all"
RUN /bin/bash -l -c "gem install bundler --no-document"

# Upgrade binutils
RUN curl -sL -O "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz" \
    && echo "${BINUTILS_SHA256}  ./binutils-${BINUTILS_VERSION}.tar.gz" | sha256sum --check \
    && tar -zxvf "./binutils-${BINUTILS_VERSION}.tar.gz" \
    && cd "binutils-${BINUTILS_VERSION}" \
    && ./configure --prefix=/usr/local/binutils --disable-gprofng && make && make install \
    && cd - \
    && rm -rf "binutils-${BINUTILS_VERSION}" \
    && rm -rf "binutils-${BINUTILS_VERSION}.tar.gz"

# Override updated linker system-wide
RUN ln -sf /usr/local/binutils/bin/ld /usr/bin/ld

# Gimme
RUN curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/v1.5.4/gimme
RUN echo "03b295636d4e22870b6f6e9bc06a71d65311ae90d3d48cbc7071f82dd5837fbc  /bin/gimme" | sha256sum --check
RUN chmod +x /bin/gimme
RUN gimme $GIMME_GO_VERSION
COPY ./gobin.sh /etc/profile.d/


# IBM MQ
RUN mkdir -p /opt/mqm \
    && curl "https://s3.amazonaws.com/dd-agent-omnibus/ibm-mq-backup/${IBM_MQ_VERSION}-IBM-MQC-Redist-LinuxX64.tar.gz" -o /tmp/mq_client.tar.gz \
    && echo "${IBM_MQ_SHA256}  /tmp/mq_client.tar.gz" | sha256sum --check \
    && tar -C /opt/mqm -xf /tmp/mq_client.tar.gz \
    && rm -rf /tmp/mq_client.tar.gz

# Add systemd headers
COPY ./rpm-headers/systemd /usr/include/systemd

# CMake
RUN set -ex \
    && curl -sL -o cmake.sh "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh" \
    && echo "${CMAKE_SHA256}  cmake.sh" | sha256sum --check \
    && mkdir -p /opt/cmake/ \
    && sh cmake.sh --skip-license --prefix=/opt/cmake \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && rm cmake.sh

# Install clang and llvm version 8
# Using build for sles11 because the versions built for other distros target glibcs that are too new to be used from this image
RUN curl -LO "https://releases.llvm.org/${CLANG_VERSION}/clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz" \
    && echo "${CLANG_SHA256}  clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz" | sha256sum --check \
    && tar -xf "clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz" --no-same-owner --strip 1 -kC /usr/ \
    && rm "clang+llvm-${CLANG_VERSION}-x86_64-linux-sles11.3.tar.xz"

# To build the EBPF code we need kernel headers for Linux 4.9
RUN rm -r /usr/src/kernels/* \
    && curl -Sl -O https://dd-agent-omnibus.s3.amazonaws.com/kernel-4.9-headers-rpm-x64.tgz \
    && echo "1657ffa995654bc96405d4dbce0b17a55cd1eabd19479bc1611b0cb4f3c01fcc  kernel-4.9-headers-rpm-x64.tgz" | sha256sum --check \
    && tar xf kernel-4.9-headers-rpm-x64.tgz --no-same-owner --strip 1 -C /usr \
    && rm kernel-4.9-headers-rpm-x64.tgz

# Update GCC: CentOS6 gcc-4.4 is a little too far behind what we use with the debian builder
# Copy (and import through the repo file) the CERN signing key:
# pub   1024D/1D1E034B 2005-06-27
# uid                  CERN Linux Support (RPM signing key for CERN Linux Support) <linux.support@cern.ch>
COPY rpm-x64/RPM-GPG-KEY-cern /etc/pki/rpm-gpg/RPM-GPG-KEY-cern
RUN if [[ "$(cat /etc/redhat-release-major)" == 6 ]]; then \ 
      curl -o /etc/yum.repos.d/slc6-devtoolset.repo https://linuxsoft.cern.ch/cern/devtoolset/slc6-devtoolset.repo \
      && echo "17a8cb10265d7c9ff285aa563c526ae0acc1871f54fcecd198ca9d3441322dfd  /etc/yum.repos.d/slc6-devtoolset.repo" | sha256sum --check \
      && yum --enablerepo=slc6-devtoolset -y install devtoolset-1.1-gcc devtoolset-1.1-gcc-c++ && yum clean all; fi

# HACK: we need to resort to echo'ing to bashrc because these ENV vars are conditional
#       on the centos version; only required for centos 6 based images.
RUN if [[ "$(cat /etc/redhat-release-major)" == 6 ]]; then \ 
      echo "export CC=/opt/rh/devtoolset-1.1/root/usr/bin/gcc" >> /root/.bashrc \
      && echo "export CPP=/opt/rh/devtoolset-1.1/root/usr/bin/cpp" >> /root/.bashrc \
      && echo "export CXX=/opt/rh/devtoolset-1.1/root/usr/bin/c++" >> /root/.bashrc; fi

# Update GCC: Get gcc 4.9.2 from devtoolset-3. devtoolset-3 is not maintained anymore, so we have to get it from
# an old mirror copy.
# Copy (and import through the repo file) the CERN signing key:
# pub   rsa2048 2015-05-21 [SCEA] [expired: 2020-05-19]
#       143E840EC0D0AD21E646CDD8FBCE6502094D442C
# uid           rhscl_devtoolset-3 (None) <rhscl#devtoolset-3@copr.fedorahosted.org>COPY rpm-x64/RPM-GPG-KEY-fedora /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora
COPY rpm-x64/RPM-GPG-KEY-fedora /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora

RUN if [[ "$(cat /etc/redhat-release-major)" == 6 ]]; then \ 
      curl -o /etc/yum.repos.d/fedora-devtoolset-3.repo https://copr.fedorainfracloud.org/coprs/rhscl/devtoolset-3/repo/epel-6/rhscl-devtoolset-3-epel-6.repo \
      && echo "fa9186082638633fbae5229060c68b06875f58682fb7aa4941aa171fb638b78f  /etc/yum.repos.d/fedora-devtoolset-3.repo" | sha256sum --check \
      && yum --enablerepo=copr:copr.fedorainfracloud.org:rhscl:devtoolset-3 -y install devtoolset-3-gcc && yum clean all; fi

# Download and install golangci-lint
RUN curl -sSfL -o golangci-lint-install.sh https://raw.githubusercontent.com/golangci/golangci-lint/v1.44.2/install.sh \
    && echo "1c2edb726aad6bf7d260d95c370bd9ec0fb1a8651e6db6f77f250dd66067de0c  golangci-lint-install.sh" | sha256sum --check \
    && sh ./golangci-lint-install.sh -b $GOPATH/bin v1.21.0 \
    && echo "942efc00799b83aebaf6628c34e1151467b7fa21f0cfd78554279dc73f8c8ef3  $GOPATH/bin/golangci-lint" | sha256sum --check \
    && rm golangci-lint-install.sh

# Rust is needed to compile some python libs
RUN curl -sSL -o rustup-init "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init" \
    && echo "${RUSTUP_SHA256}  rustup-init" | sha256sum --check \
    && chmod +x ./rustup-init \
    && ./rustup-init -y --profile minimal --default-toolchain "${RUST_VERSION}" \
    && echo "${RUSTC_SHA256}  $HOME/.cargo/bin/rustc" | sha256sum --check \
    && rm ./rustup-init
ENV PATH "~/.cargo/bin:${PATH}"

# Perl >= 5.14 is needed to compile the libxcrypt project
RUN curl -sSL -o perlbrew-install.sh "https://raw.githubusercontent.com/gugod/App-perlbrew/release-${PERLBREW_VERSION}/perlbrew-install" \
    && echo "${PERLBREW_SHA256}  perlbrew-install.sh" | sha256sum --check \
    && bash ./perlbrew-install.sh \
    && source /root/perl5/perlbrew/etc/bashrc \
    && perlbrew install "perl-${PERL_VERSION}" \
    && perlbrew switch "${PERL_VERSION}" \
    && echo "source /root/perl5/perlbrew/etc/bashrc" >> /root/.bashrc \
    && rm perlbrew-install.sh

# gcc
COPY ./build-gcc.sh /build-gcc.sh
RUN chmod +x /build-gcc.sh \
    && /build-gcc.sh \
    && rm /build-gcc.sh

# Entrypoint
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# create the agent build folder within $GOPATH
RUN mkdir -p /go/src/github.com/DataDog/datadog-agent

# Force umask to 0022
RUN echo "umask 0022" >> /root/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
