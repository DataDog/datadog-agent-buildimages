#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

mkdir ~/.scripts
(
    cd "$(dirname "${BASH_SOURCE[0]}")"/scripts
    for f in *.sh; do
        install -m 755 "$f" ~/.scripts/"${f%.sh}"
    done
)
~/.scripts/path-prepend ~/.scripts
