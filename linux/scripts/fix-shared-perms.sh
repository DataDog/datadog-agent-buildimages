#!/usr/bin/env bash
set -euo pipefail

for dir in "$@"; do
    chown -R root:build-shared "${dir}"
    chmod -R g+rwX "${dir}"
    find "${dir}" -type d -exec sh -c \
        'chmod g+rwxs,o+rx "$@"' sh {} +
done
