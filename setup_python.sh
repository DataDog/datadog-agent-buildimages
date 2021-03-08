#!/bin/bash

set -ex

case $DD_TARGET_ARCH in
"x64")
    CONDA_URL=https://repo.anaconda.com/miniconda/Miniconda3-${DD_CONDA_VERSION}-Linux-x86_64.sh
    ;;
"aarch64")
    CONDA_URL=https://github.com/conda-forge/miniforge/releases/download/${DD_CONDA_VERSION}/Miniforge3-Linux-aarch64.sh
    ;;
*)
    echo "Using system python since DD_TARGET_ARCH is $DD_TARGET_ARCH"
    curl "https://bootstrap.pypa.io/pip/2.7/get-pip.py" | python2.7 - pip==${DD_PIP_VERSION} setuptools==${DD_SETUPTOOLS_VERSION}
    pip install invoke==1.4.1 distro==1.4.0 awscli==1.16.240
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
    && pip install invoke==1.4.1 distro==1.4.0 awscli==1.16.240

# Update pip, setuptools and misc deps
conda activate ddpy3 \
    && pip install -i https://pypi.python.org/simple pip==${DD_PIP_VERSION} \
    && pip install --ignore-installed setuptools==${DD_SETUPTOOLS_VERSION} \
    && pip install invoke==1.4.1 distro==1.4.0 awscli==1.16.240

