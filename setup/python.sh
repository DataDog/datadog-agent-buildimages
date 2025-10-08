#!/bin/bash

set -ex

source "$(dirname "${BASH_SOURCE[0]}")"/../python-packages-versions.txt

bash miniconda.sh -b
rm miniconda.sh

conda init bash
source /root/.bashrc

# Setup pythons
conda create -n ddpy3 python python=$PY3_VERSION

# Update pip, setuptools and misc deps
conda activate ddpy3
pip install -i https://pypi.python.org/simple pip==${DD_PIP_VERSION_PY3}
pip install setuptools==${DD_SETUPTOOLS_VERSION_PY3}
pip install --no-build-isolation "cython<3.0.0" PyYAML==${DD_PYYAML_VERSION_PY3}

pip install uv==${DD_UV_VERSION}

# TODO: Why this if we install it just above ?
pip uninstall -y cython # remove cython to prevent further issue with nghttp2
conda clean -a
echo "conda activate ddpy3" >> /root/.bashrc

