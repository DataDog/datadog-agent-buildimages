#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

mkdir "$HOME"/.scripts
(
    cd "$(dirname "${BASH_SOURCE[0]}")"/scripts
    for f in *.sh; do
        install -m 755 "$f" "$HOME"/.scripts/"${f%.sh}"
    done
)
"$HOME"/.scripts/path-prepend "$HOME"/.scripts
