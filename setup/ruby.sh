#!/usr/bin/env bash
set -euxo pipefail

version=20261013  # seldom updated; pinned primarily for integrity verification rather than reproducibility
sha256=9e683b1d8efe337ae27c31f995641e22761af603bb0f783d22c5d2f99252758c

: "${RUBY_VERSION:?must be set to the Ruby version to install}"
: "${BUNDLER_VERSION:?must be set to the Bundler version to install}"
RUBY_PATH="${RUBY_PATH:-/usr/local/ruby}"

tmp_dir=$(mktemp -d)
# On failure ruby-build only prints the path of its log file, which disappears along with
# the build step, so show the end of it before exiting.
cleanup() {
    local status=$?
    if [[ ${status} -ne 0 ]]; then
        tail -n 50 /tmp/ruby-build.*.log 2>/dev/null || true
    fi
    rm -rf -- "${tmp_dir}"
}
trap cleanup EXIT

echo "Installing ruby-build $version..."
curl -fsSL -o "$tmp_dir/ruby-build.tar.gz" "https://github.com/rbenv/ruby-build/archive/refs/tags/v$version.tar.gz"
echo "$sha256  $tmp_dir/ruby-build.tar.gz" | sha256sum --check
mkdir "$tmp_dir/ruby-build"
tar -C "$tmp_dir/ruby-build" --strip-components=1 -xzf "$tmp_dir/ruby-build.tar.gz"
PREFIX=/usr/local "$tmp_dir/ruby-build/install.sh"

# ruby-build verifies the checksum of every source archive it downloads. It also picks up
# RUBY_CONFIGURE_OPTS and <PACKAGE>_CONFIGURE_OPTS from the environment, which callers use
# to adjust the build for their architecture. It links against the system OpenSSL when that
# one is supported by the Ruby being installed, and builds OpenSSL 1.1.1 in "${RUBY_PATH}"
# otherwise.
echo "Installing Ruby ${RUBY_VERSION} in ${RUBY_PATH}..."
RUBY_CONFIGURE_OPTS="--disable-install-doc ${RUBY_CONFIGURE_OPTS:-}" ruby-build "${RUBY_VERSION}" "${RUBY_PATH}"

export PATH="${RUBY_PATH}/bin:${PATH}"
ruby -ropenssl -ryaml -e 'puts RUBY_DESCRIPTION, OpenSSL::OPENSSL_LIBRARY_VERSION'
gem install bundler --version "${BUNDLER_VERSION}" --no-document
