#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

VERSION="3.12.7"
RELEASE="20241008"

arch=$(uname -m)
url="https://github.com/indygreg/python-build-standalone/releases/download/${RELEASE}/cpython-${VERSION}+${RELEASE}-${arch}_v2-unknown-linux-gnu-install_only.tar.gz"

curl "${url}" -Lo cpython.tar.gz
mkdir -p /tools
tar -xf cpython.tar.gz -C /tools
rm cpython.tar.gz

/tools/python/bin/python -m venv "${HOME}/.venv"
path-prepend "${HOME}/.venv/bin"
