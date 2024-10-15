#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

cd "${HOME}/.scripts"
for f in *; do
    mv -- "$f" "${f%.sh}"
done
find . -maxdepth 1 -type f -exec chmod +x {} \;
