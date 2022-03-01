#!/bin/bash

set -ex

source python-packages-versions.txt

function detect_distro(){
    local KNOWN_DISTRIBUTION="(Debian|Ubuntu|RedHat|CentOS|openSUSE|Amazon|Arista|SUSE)"
    DISTRIBUTION=$(lsb_release -d 2>/dev/null | grep -Eo $KNOWN_DISTRIBUTION  || grep -Eo $KNOWN_DISTRIBUTION /etc/issue 2>/dev/null || grep -Eo $KNOWN_DISTRIBUTION /etc/Eos-release 2>/dev/null || grep -m1 -Eo $KNOWN_DISTRIBUTION /etc/os-release 2>/dev/null || uname -s)
}

case $DD_TARGET_ARCH in
"x64")
    DD_CONDA_VERSION=4.9.2
    CONDA_URL=https://repo.anaconda.com/miniconda/Miniconda3-py39_${DD_CONDA_VERSION}-Linux-x86_64.sh
    # FIXME: Pinning specific zlib version as the latest one doesn't work in our old builders:
    # version GLIBC_2.14 not found (required by /root/miniconda3/envs/ddpy2/lib/python2.7/lib-dynload/../../libz.so.1)
    PY2_VERSION="2 zlib=1.2.11=h7b6447c_3"
    # FIXME: Pinning specific build since the last version doesn't seem to work with the glibc in the base image
    # FIXME: Pinning OpenSSL to a version that's compatible with the Python build we pin (we get `SSL module is not available` errors with OpenSSL 1.1.1l)
    PY3_VERSION="3.8.10=hdb3f193_7 openssl=1.1.1k=h27cfd23_0 zlib=1.2.11=h7b6447c_3"
    ;;
"aarch64")
    DD_CONDA_VERSION=4.9.2-7
    CONDA_URL=https://github.com/conda-forge/miniforge/releases/download/${DD_CONDA_VERSION}/Miniforge3-Linux-aarch64.sh
    PY2_VERSION=2
    PY3_VERSION=3.8.10
    ;;
"armhf")
    detect_distro
    if [ -f /etc/debian_version ] || [ "$DISTRIBUTION" == "Debian" ] || [ "$DISTRIBUTION" == "Ubuntu" ]; then
        echo "Installing Python from source (deb_armhf)"
        DEBIAN_FRONTEND=noninteractive apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
        zip wget build-essential checkinstall libreadline-gplv2-dev \
        libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev \
        libc6-dev libbz2-dev libffi-dev zlib1g-dev
        wget https://www.python.org/ftp/python/3.9.9/Python-3.9.9.tgz
        tar xzf Python-3.9.9.tgz
        pushd /Python-3.9.9
           ./configure
           make -j 8
           make install
        popd
        rm -rf Python-3.9.9
        rm Python-3.9.9.tgz
        ln -sf /usr/bin/python3.9 /usr/bin/python3
    elif [ -f /etc/redhat-release ] || [ "$DISTRIBUTION" == "RedHat" ] || [ "$DISTRIBUTION" == "CentOS" ] || [ "$DISTRIBUTION" == "Amazon" ]; then
        echo "Installing system Python (rpm_armhf)"
        yum install -y python3-devel # This installs python 3.6 on arm32v7/centos:7
        DD_GET_PIP_URL=https://bootstrap.pypa.io/pip/3.6/get-pip.py
    fi

    curl "${DD_PIP_GET_URL}" | python3 - pip==${DD_PIP_VERSION_PY3} setuptools==${DD_SETUPTOOLS_VERSION_PY3}
    python3 -m pip install distro==1.4.0
    python3 -m pip install -r requirements.txt
    exit 0
    ;;
*)
    echo "Unknown or unsupported architecture ${DD_TARGET_ARCH}"
    exit -1
esac

curl -fsL -o ~/miniconda.sh $CONDA_URL
bash ~/miniconda.sh -b
rm ~/miniconda.sh

PATH="${CONDA_PATH}/bin:${PATH}"
conda init bash
source /root/.bashrc

# Setup pythons
conda create -n ddpy2 python python=$PY2_VERSION
conda create -n ddpy3 python python=$PY3_VERSION

# Update pip, setuptools and misc deps
conda activate ddpy2
pip install -i https://pypi.python.org/simple pip==${DD_PIP_VERSION}
pip install setuptools==${DD_SETUPTOOLS_VERSION}
pip install -r requirements-py2.txt

# Update pip, setuptools and misc deps
conda activate ddpy3
pip install -i https://pypi.python.org/simple pip==${DD_PIP_VERSION_PY3}
pip install setuptools==${DD_SETUPTOOLS_VERSION_PY3}
pip install -r requirements.txt


if [ "$DD_TARGET_ARCH" = "aarch64" ] ; then
    # Conda creates "lib" but on Amazon Linux, the embedded Python2 we use in unit tests will look in "lib64" instead
    ln -s "${CONDA_PATH}/envs/ddpy2/lib" "${CONDA_PATH}/envs/ddpy2/lib64"
fi
