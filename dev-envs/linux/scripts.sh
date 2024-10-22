#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

scripts_dir="${HOME}/scripts"
cd "${scripts_dir}"
for f in *; do
    mv -- "$f" "${f%.sh}"
done
find . -maxdepth 1 -type f -exec chmod +x {} \;

# Necessary during this stage because scripts call each other
export PATH="${scripts_dir}:${PATH}"

./path-prepend "${scripts_dir}"

# Properly add directories to PATH that were only added as Docker directives
./path-append "${HOME}/.cargo/bin"
./path-append "/go/bin"
./path-append "/usr/local/go/bin"
./path-append "/root/miniforge3/condabin"
./path-append "/usr/lib/binutils-2.26/bin"
