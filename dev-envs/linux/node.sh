#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# Node.js (with npm/npx) is required by `dda review`, which runs the `find-guidelines`
# script from DataDog/code-review-action via `npm exec`.
# The version and digests come from node.env, see the Renovate config.
: "${NODE_VERSION:?}" "${NODE_SHA256_LINUX_X64:?}" "${NODE_SHA256_LINUX_ARM64:?}"

arch=$(uname -m)
if [[ "$arch" == "aarch64" ]]; then
  node_arch="arm64"
  node_digest="${NODE_SHA256_LINUX_ARM64}"
else
  node_arch="x64"
  node_digest="${NODE_SHA256_LINUX_X64}"
fi

archive="node-v${NODE_VERSION}-linux-${node_arch}.tar.xz"
archive_path="/tmp/${archive}"

curl --fail --silent --show-error --location --retry 2 --retry-connrefused \
  "https://nodejs.org/dist/v${NODE_VERSION}/${archive}" -o "${archive_path}"
echo "${node_digest}  ${archive_path}" | sha256sum --check --strict

# Install to the system-wide prefix rather than a directory persisted for users.
tar -xJf "${archive_path}" -C /usr/local --strip-components=1 --no-same-owner \
  --exclude='*/CHANGELOG.md' --exclude='*/LICENSE' --exclude='*/README.md'
rm "${archive_path}"

node --version
npm --version
