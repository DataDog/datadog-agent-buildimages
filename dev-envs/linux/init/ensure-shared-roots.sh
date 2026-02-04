#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail
PS4='+[$(date +%T.%3N)] '

ensure_shared_root() {
    root="$1"
    mkdir -p "${root}"
    chgrp build-shared "${root}"
    chmod g+rws,o+rx "${root}"
    setfacl -m g:build-shared:rwx,m:rwx "${root}"
    setfacl -d -m g:build-shared:rwx,m:rwx "${root}"
}

roots=("$@")
if [[ "${#roots[@]}" -eq 0 ]]; then
    roots=(
        "${DD_BUILD_DATA_ROOT}"
        "${DD_BUILD_CACHE_ROOT}"
        "${DD_BUILD_CONFIG_ROOT}"
    )
fi

for root in "${roots[@]}"; do
    ensure_shared_root "${root}"
done
