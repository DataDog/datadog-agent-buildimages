#!/bin/sh
set -eu

BUILDX_VERSION=0.38.2-dd.3
buildx_arch="$(dpkg --print-architecture)"
case "$buildx_arch" in
  amd64) buildx_sha256=d974b718dd988bfe661346e8e2ac5751be55475883ae796ae9dea9d0f6cbe0b2 ;;
  arm64) buildx_sha256=b22f3da81c913eb76da05143ba49ec3de06224b617161c969c43022add397b29 ;;
  *) echo "Unsupported Buildx architecture: $buildx_arch" >&2; exit 1 ;;
esac
buildx_tmp="$(mktemp -d)"
trap 'rm -rf "$buildx_tmp"' EXIT
curl -fsSL -o "$buildx_tmp/buildx.tar.gz" \
  "https://depot-read-api-github-releases.us1.ddbuild.io/internal/mirror/github-releases/DataDog/buildx/releases/download/v${BUILDX_VERSION}/buildx_${BUILDX_VERSION}_linux_${buildx_arch}.tar.gz"
printf '%s  %s\n' "$buildx_sha256" "$buildx_tmp/buildx.tar.gz" | sha256sum -c -
tar -xzf "$buildx_tmp/buildx.tar.gz" -C "$buildx_tmp" buildx
install -D -m 0755 "$buildx_tmp/buildx" /usr/local/libexec/docker/cli-plugins/docker-buildx
buildx_selected="$(docker buildx version)"
case "$buildx_selected" in
  "github.com/docker/buildx v${BUILDX_VERSION} "*) printf '%s\n' "$buildx_selected" ;;
  *) echo "Unexpected Buildx client: $buildx_selected" >&2; exit 1 ;;
esac
