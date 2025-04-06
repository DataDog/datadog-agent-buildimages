#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

VERSION="3.12.7"
RELEASE="20241016"

arch=$(uname -m)
if [[ "$arch" == "aarch64" ]]; then
    DIGEST="bba3c6be6153f715f2941da34f3a6a69c2d0035c9c5396bc5bb68c6d2bd1065a"
    cpu_variant=""
else
    DIGEST="c3055f2aaa2ca942cbf652bf8655f69390cdf920ae911a6778a8d92c6169a808"
    cpu_variant="_v2"
fi
url="https://github.com/indygreg/python-build-standalone/releases/download/${RELEASE}/cpython-${VERSION}+${RELEASE}-${arch}${cpu_variant}-unknown-linux-gnu-install_only.tar.gz"

curl "${url}" -Lo cpython.tar.gz
mkdir -p /tools
tar -xf cpython.tar.gz -C /tools

digest=$(openssl dgst -sha256 cpython.tar.gz | cut -d' ' -f2)
if [[ "${digest}" != "${DIGEST}" ]]; then
    echo "Digest mismatch"
    echo "Expected: ${DIGEST}"
    echo "Got: ${digest}"
    exit 1
fi
rm cpython.tar.gz

/tools/python/bin/python -m venv "${HOME}/.venv"

"${HOME}/.venv/bin/pip" install "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}"
"${HOME}/.venv/bin/dda" -v self dep sync -f legacy-tasks

path-prepend "${HOME}/.venv/bin"
