#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

groupadd -f dog
useradd -m -g dog -s /bin/bash dog

# Base image installs AWS CLI v2; dev-env does not need it
# https://docs.aws.amazon.com/cli/latest/userguide/uninstall.html
rm -f /usr/local/bin/aws /usr/local/bin/aws_completer
rm -rf /usr/local/aws-cli

# Remove side effects of APT installations
apt-get clean && rm -rf /var/lib/apt/lists/*

# Remove cache directories
dotslash -- clean

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
