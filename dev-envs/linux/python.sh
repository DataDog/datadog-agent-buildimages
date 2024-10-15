#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

VERSION="3.12.7"
RELEASE="20241016"

arch=$(uname -m)
if [[ "$arch" == "aarch64" ]]; then
    cpu_variant=""
else
    cpu_variant="_v2"
fi
url="https://github.com/indygreg/python-build-standalone/releases/download/${RELEASE}/cpython-${VERSION}+${RELEASE}-${arch}${cpu_variant}-unknown-linux-gnu-install_only.tar.gz"

curl "${url}" -Lo cpython.tar.gz
mkdir -p /tools
tar -xf cpython.tar.gz -C /tools
rm cpython.tar.gz

/tools/python/bin/python -m venv "${HOME}/.venv"

"${HOME}/.venv/bin/pip" install -r https://raw.githubusercontent.com/DataDog/datadog-agent/main/requirements.txt

path-prepend "${HOME}/.venv/bin"
