#!/usr/bin/env bash
set -euxo pipefail

version=1.27.0  # seldom updated; pinned primarily for integrity verification rather than reproducibility

echo "Installing Bazelisk $version as Bazel bootstrapper..."
case $(uname -m) in
  x86_64) arch=amd64 && sha256=e1508323f347ad1465a887bc5d2bfb91cffc232d11e8e997b623227c6b32fb76 ;;
  aarch64) arch=arm64 && sha256=bb608519a440d45d10304eb684a73a2b6bb7699c5b0e5434361661b25f113a5d ;;
  *) echo >&2 "Unsupported machine: $(uname -m)"; exit 1 ;;
esac

tmp_dir=$(mktemp -d)
trap 'rm -rv -- $tmp_dir' EXIT

bazelisk=$tmp_dir/bazelisk$version
curl -fsSL -o "$bazelisk" https://github.com/bazelbuild/bazelisk/releases/download/v$version/bazelisk-linux-$arch
sha256sum --check --strict <(echo "$sha256 *$bazelisk")
chmod 755 "$bazelisk"
mv "$bazelisk" /usr/local/bin
ln -s bazelisk$version /usr/local/bin/bazelisk
ln -s bazelisk /usr/local/bin/bazel

echo "Verifying Bazelisk $version properly bootstraps Bazel..."
readlink -f "$(command -v bazel)" | tee /dev/stderr | grep -Fqx /usr/local/bin/bazelisk$version
BAZELISK_HOME=$tmp_dir USE_BAZEL_VERSION=7.6.1 BAZELISK_BASE_URL=https://github.com/bazelbuild/bazel/releases/download bazel --version | tee /dev/stderr | grep -Fqx 'bazel 7.6.1'
