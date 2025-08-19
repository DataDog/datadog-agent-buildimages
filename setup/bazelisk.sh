#!/usr/bin/env bash
set -euxo pipefail

echo "Installing Bazelisk as Bazel bootstrapper..."
go install github.com/bazelbuild/bazelisk@v1.27.0
ln -s bazelisk "$(command -v bazelisk | sed 's/bazelisk$/bazel/')"

echo "Verifying Bazelisk properly bootstraps Bazel..."
export BAZELISK_HOME="$(mktemp -d)"
trap 'rm -rv -- "$BAZELISK_HOME"' EXIT
USE_BAZEL_VERSION=7.6.1 bazel --version | grep -Fq 'bazel 7.6.1'
