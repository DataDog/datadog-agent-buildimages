#!/usr/bin/env bash
set -euo pipefail

for dir in "$@"; do
    chown -R root:build-shared "${dir}"
    find "${dir}" -type d -exec sh -c \
        'chmod g+ws "$@" && setfacl -d -m g:build-shared:rwx,m:rwx "$@"' sh {} +
    setfacl -R -m g:build-shared:rwX,m:rwX "${dir}"
done
