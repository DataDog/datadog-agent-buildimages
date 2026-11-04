#!/usr/bin/env bash
set -euxo pipefail

version=1.30.0  # seldom updated; pinned primarily for integrity verification rather than reproducibility

echo "Installing Bazelisk $version as Bazel bootstrapper..."
case $(uname -m) in
  x86_64) arch=amd64 && sha256=a248ae2b2b62b5baebb748f6fba7203bff1a27e5d01b55399a8406744cb539e8 ;;
  aarch64) arch=arm64 && sha256=b2bcc040c213b44586b121bda6d983c35df121b917c3a7a66fb16f2fa0df1a4f ;;
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
XDG_CACHE_HOME=$tmp_dir USE_BAZEL_VERSION=7.6.1 BAZELISK_BASE_URL=https://github.com/bazelbuild/bazel/releases/download bazel --version | tee /dev/stderr | grep -Fqx 'bazel 7.6.1'
