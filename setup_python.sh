#!/bin/bash

set -ex

source python-packages-versions.txt

function detect_distro(){
    local KNOWN_DISTRIBUTION="(Debian|Ubuntu|RedHat|CentOS|openSUSE|Amazon|Arista|SUSE)"
    DISTRIBUTION=$(lsb_release -d 2>/dev/null | grep -Eo $KNOWN_DISTRIBUTION  || grep -Eo $KNOWN_DISTRIBUTION /etc/issue 2>/dev/null || grep -Eo $KNOWN_DISTRIBUTION /etc/Eos-release 2>/dev/null || grep -m1 -Eo $KNOWN_DISTRIBUTION /etc/os-release 2>/dev/null || uname -s)
}

PY2_VERSION=2
PY3_VERSION=3.11.5
DD_CONDA_VERSION=4.9.2-7

case $DD_TARGET_ARCH in
"x64")
    DD_CONDA_SHA256="91d5aa5f732b5e02002a371196a2607f839bab166970ea06e6ecc602cb446848"
    CONDA_URL=https://github.com/conda-forge/miniforge/releases/download/${DD_CONDA_VERSION}/Miniforge3-Linux-x86_64.sh
    ;;
"aarch64")
    DD_CONDA_SHA256="ea7d631e558f687e0574857def38d2c8855776a92b0cf56cf5285bede54715d9"
    CONDA_URL=https://github.com/conda-forge/miniforge/releases/download/${DD_CONDA_VERSION}/Miniforge3-Linux-aarch64.sh
    ;;
"armhf")
    detect_distro
    echo "Installing Python from source (armhf)"
    if [ -f /etc/debian_version ] || [ "$DISTRIBUTION" == "Debian" ] || [ "$DISTRIBUTION" == "Ubuntu" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
        zip wget build-essential checkinstall libreadline-gplv2-dev \
        libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev \
        libc6-dev libbz2-dev libffi-dev zlib1g-dev
    elif [ -f /etc/redhat-release ] || [ "$DISTRIBUTION" == "RedHat" ] || [ "$DISTRIBUTION" == "CentOS" ] || [ "$DISTRIBUTION" == "Amazon" ]; then
        yum install -y gcc openssl-devel bzip2-devel libffi-devel wget make perl-IPC-Cmd
    fi
    OPENSSL_VERSION="3.0.12"
    OPENSSL_SHA256="f93c9e8edde5e9166119de31755fc87b4aa34863662f67ddfcba14d0b6b69b61"
    PYTHON_SHA256="a12a0a013a30b846c786c010f2c19dd36b7298d888f7c4bd1581d90ce18b5e58"

    wget https://ftp.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
    echo "$OPENSSL_SHA256 openssl-$OPENSSL_VERSION.tar.gz" | sha256sum --check
    tar xzf openssl-$OPENSSL_VERSION.tar.gz
    pushd openssl-$OPENSSL_VERSION
      ./config --prefix=/usr -Wl,-Bsymbolic-functions -fPIC shared no-ssl2 no-ssl3 linux-generic32
      make -j $(nproc)
      make install
    popd
    rm -rf openssl-$OPENSSL_VERSION.tar.gz openssl-$OPENSSL_VERSION

    wget https://www.python.org/ftp/python/$PY3_VERSION/Python-$PY3_VERSION.tgz
    echo "$PYTHON_SHA256 Python-$PY3_VERSION.tgz" | sha256sum --check
    tar xzf Python-$PY3_VERSION.tgz
    pushd /Python-$PY3_VERSION
        ./configure --with-openssl=/usr --with-openssl-rpath=auto
        make -j $(nproc)
        make install
    popd
    rm -rf Python-$PY3_VERSION Python-$PY3_VERSION.tgz
    ln -sf /usr/bin/python3.11 /usr/bin/python3

    python3 -m pip install distro==1.4.0 wheel==0.40.0
    python3 -m pip install --no-build-isolation "cython<3.0.0" PyYAML==5.4.1
    python3 -m pip install -r requirements.txt
    exit 0
    ;;
*)
    echo "Unknown or unsupported architecture ${DD_TARGET_ARCH}"
    exit -1
esac

curl -fsL -o miniconda.sh $CONDA_URL
echo "${DD_CONDA_SHA256}  miniconda.sh" | sha256sum --check
bash miniconda.sh -b
rm miniconda.sh

PATH="${CONDA_PATH}/condabin:${PATH}"
conda init bash
source /root/.bashrc

# Make sure requirements are installed also on the system python
# This is needed because some tests jobs (py2 test jobs) run invoke using the system python
python3 -m pip install --no-build-isolation "cython<3.0.0" PyYAML==5.4.1
python3 -m pip install -r requirements.txt

# Setup pythons
conda create -n ddpy2 python python=$PY2_VERSION
conda create -n ddpy3 python python=$PY3_VERSION

# Update pip, setuptools and misc deps
conda activate ddpy2
pip install -i https://pypi.python.org/simple pip==${DD_PIP_VERSION}
pip install setuptools==${DD_SETUPTOOLS_VERSION}
pip install --no-build-isolation "cython<3.0.0" PyYAML==5.4.1
pip install -r requirements-py2.txt
pip uninstall -y cython # remove cython to prevent further issue with nghttp2

# Update pip, setuptools and misc deps
conda activate ddpy3
pip install -i https://pypi.python.org/simple pip==${DD_PIP_VERSION_PY3}
pip install setuptools==${DD_SETUPTOOLS_VERSION_PY3}
pip install --no-build-isolation "cython<3.0.0" PyYAML==5.4.1
pip install -r requirements.txt
pip uninstall -y cython # remove cython to prevent further issue with nghttp2


if [ "$DD_TARGET_ARCH" = "aarch64" ] ; then
    # Conda creates "lib" but on Amazon Linux, the embedded Python2 we use in unit tests will look in "lib64" instead
    ln -s "${CONDA_PATH}/envs/ddpy2/lib" "${CONDA_PATH}/envs/ddpy2/lib64"
fi

# Add python3's invoke to the PATH even when ddpy3 is not active, since we want to use python3 invoke to run python2 tests
ln -s ${CONDA_PATH}/envs/ddpy3/bin/inv /usr/local/bin

echo "conda activate ddpy3" >> /root/.bashrc
