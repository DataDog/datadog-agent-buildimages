#!/bin/bash

set -ex

function detect_distro(){
    local KNOWN_DISTRIBUTION="(Debian|Ubuntu|RedHat|CentOS|openSUSE|Amazon|Arista|SUSE)"
    DISTRIBUTION=$(lsb_release -d 2>/dev/null | grep -Eo $KNOWN_DISTRIBUTION  || grep -Eo $KNOWN_DISTRIBUTION /etc/issue 2>/dev/null || grep -Eo $KNOWN_DISTRIBUTION /etc/Eos-release 2>/dev/null || grep -m1 -Eo $KNOWN_DISTRIBUTION /etc/os-release 2>/dev/null || uname -s)
}

case $DD_TARGET_ARCH in
"x64")
    DD_CONDA_VERSION=4.9.2
    CONDA_URL=https://repo.anaconda.com/miniconda/Miniconda3-${DD_CONDA_VERSION}-Linux-x86_64.sh
    ;;
"aarch64")
    DD_CONDA_VERSION=4.10.1-1
    CONDA_URL=https://github.com/conda-forge/miniforge/releases/download/${DD_CONDA_VERSION}/Miniforge3-Linux-aarch64.sh
    ;;
*)
    echo "Using system python since DD_TARGET_ARCH is $DD_TARGET_ARCH"
    detect_distro
    if [ -f /etc/debian_version ] || [ "$DISTRIBUTION" == "Debian" ] || [ "$DISTRIBUTION" == "Ubuntu" ]; then
        apt-get update && apt-get install -y software-properties-common
        add-apt-repository -y ppa:deadsnakes/ppa
        apt-get update && apt-get install -y python3.9-dev python3.9-distutils
        ln -sf /usr/bin/python3.9 /usr/bin/python3
    elif [ -f /etc/redhat-release ] || [ "$DISTRIBUTION" == "RedHat" ] || [ "$DISTRIBUTION" == "CentOS" ] || [ "$DISTRIBUTION" == "Amazon" ]; then
        yum install -y python3-devel
    fi

    curl "https://bootstrap.pypa.io/pip/get-pip.py" | python3 - pip==${DD_PIP_VERSION} setuptools==${DD_SETUPTOOLS_VERSION}
    python3 -m pip install invoke==1.4.1 distro==1.4.0 awscli==1.16.240
    exit 0
esac

curl -fsL -o ~/miniconda.sh $CONDA_URL
bash ~/miniconda.sh -b
rm ~/miniconda.sh

PATH="${CONDA_PATH}/bin:${PATH}"
conda init bash
source /root/.bashrc

# Setup pythons
conda create -n ddpy2 python python=2
conda create -n ddpy3 python python=3.8

# Update pip, setuptools and misc deps
conda activate ddpy2 \
    && pip install -i https://pypi.python.org/simple pip==${DD_PIP_VERSION} \
    && pip install --ignore-installed setuptools==${DD_SETUPTOOLS_VERSION} \
    && pip install distro==1.4.0 awscli==1.16.240

# Update pip, setuptools and misc deps
conda activate ddpy3 \
    && pip install -i https://pypi.python.org/simple pip==${DD_PIP_VERSION} \
    && pip install --ignore-installed setuptools==${DD_SETUPTOOLS_VERSION} \
    && pip install invoke==1.4.1 distro==1.4.0 awscli==1.16.240

if [ "$DD_TARGET_ARCH" = "aarch64" ] ; then
    # Conda creates "lib" but on Amazon Linux, the embedded Python2 we use in unit tests will look in "lib64" instead
    ln -s "${CONDA_PATH}/envs/ddpy2/lib" "${CONDA_PATH}/envs/ddpy2/lib64"
fi
