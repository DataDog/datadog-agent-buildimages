#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# Remove side effects of APT installations
apt-get clean && rm -rf /var/lib/apt/lists/*

# Remove cache directories
cache_dirs=(
    "${HOME}/.cache/go-build"
    "/go/pkg/mod"
    "${HOME}/.cache/pip"
    "${HOME}/.cargo/registry"
    "${HOME}/.cargo/git"
    "/omnibus/vendor/bundle"
    "/omnibus/cache"
    "/tmp/omnibus-git-cache"
)

for cache_dir in "${cache_dirs[@]}"; do
    rm -rf "$cache_dir"
done
