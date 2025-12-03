#!/usr/bin/env bash
set -euxo pipefail

tmp_dir=$(mktemp -d)
trap 'rm -rv -- $tmp_dir' EXIT

mv bazelisk /usr/local/bin
ln -s bazelisk /usr/local/bin/bazel

echo "Verifying Bazelisk properly bootstraps Bazel..."
readlink -f "$(command -v bazel)" | tee /dev/stderr | grep -Fqx /usr/local/bin/bazelisk
BAZELISK_HOME=$tmp_dir USE_BAZEL_VERSION=7.6.1 bazel --version | tee /dev/stderr | grep -Fqx 'bazel 7.6.1'
