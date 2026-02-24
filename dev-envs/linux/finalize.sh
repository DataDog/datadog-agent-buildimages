#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# Remove side effects of APT installations
apt-get clean && rm -rf /var/lib/apt/lists/*

cache_dirs=(
    "${DD_BUILD_CACHE_ROOT}"
    "/omnibus/cache"
)

for cache_dir in "${cache_dirs[@]}"; do
    # Clear contents but preserve directory structure (e.g., for symlink targets)
    find "$cache_dir" -mindepth 1 -delete 2>/dev/null || true
done
