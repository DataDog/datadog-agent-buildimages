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
    DD_CONDA_SHA256="536817d1b14cb1ada88900f5be51ce0a5e042bae178b5550e62f61e223deae7c"
    CONDA_URL=https://repo.anaconda.com/miniconda/Miniconda3-py39_${DD_CONDA_VERSION}-Linux-x86_64.sh
    # FIXME: Pinning specific zlib version as the latest one doesn't work in our old builders:
    # version GLIBC_2.14 not found (required by /root/miniconda3/envs/ddpy2/lib/python2.7/lib-dynload/../../libz.so.1)
    PY2_VERSION="2 zlib=1.2.11=h7b6447c_3"
    # FIXME: Pinning specific build (Python 3.9.5, zlib, xz) since the last versions don't seem to work with the glibc in the base image
    # FIXME: Pinning OpenSSL to a version that's compatible with the Python build we pin (we get `SSL module is not available` errors with OpenSSL 1.1.1l)
    PY3_VERSION="3.9.5=hdb3f193_3 certifi=2022.12.7=py39h06a4308_0 ld_impl_linux-64=2.38=h1181459_0 libgcc-ng=9.1.0=hdf63c60_0 libstdcxx-ng=9.1.0=hdf63c60_0 openssl=1.1.1k=h27cfd23_0 xz=5.2.5=h7b6447c_0 zlib=1.2.11=h7b6447c_3"
    ;;
"aarch64")
    DD_CONDA_VERSION=4.9.2-7
    DD_CONDA_SHA256="ea7d631e558f687e0574857def38d2c8855776a92b0cf56cf5285bede54715d9"
    CONDA_URL=https://github.com/conda-forge/miniforge/releases/download/${DD_CONDA_VERSION}/Miniforge3-Linux-aarch64.sh
    PY2_VERSION=2
    PY3_VERSION=3.9.5
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
        yum install -y gcc openssl-devel bzip2-devel libffi-devel wget make
    fi

    wget https://www.python.org/ftp/python/3.9.5/Python-3.9.5.tgz
    echo "e0fbd5b6e1ee242524430dee3c91baf4cbbaba4a72dd1674b90fda87b713c7ab Python-3.9.5.tgz" | sha256sum --check
    tar xzf Python-3.9.5.tgz
    pushd /Python-3.9.5
        ./configure
        make -j 8
        make install
    popd
    rm -rf Python-3.9.5
    rm Python-3.9.5.tgz
    ln -sf /usr/bin/python3.9 /usr/bin/python3

    python3 -m pip install distro==1.4.0
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

# Update pip, setuptools and misc deps
conda activate ddpy3
pip install -i https://pypi.python.org/simple pip==${DD_PIP_VERSION_PY3}
pip install setuptools==${DD_SETUPTOOLS_VERSION_PY3}
pip install --no-build-isolation "cython<3.0.0" PyYAML==5.4.1
pip install -r requirements.txt


if [ "$DD_TARGET_ARCH" = "aarch64" ] ; then
    # Conda creates "lib" but on Amazon Linux, the embedded Python2 we use in unit tests will look in "lib64" instead
    ln -s "${CONDA_PATH}/envs/ddpy2/lib" "${CONDA_PATH}/envs/ddpy2/lib64"
fi

# Add python3's invoke to the PATH even when ddpy3 is not active, since we want to use python3 invoke to run python2 tests
ln -s ${CONDA_PATH}/envs/ddpy3/bin/inv /usr/local/bin

echo "conda activate ddpy3" >> /root/.bashrc
