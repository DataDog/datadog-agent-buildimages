#!/usr/bin/env bash
set -euxo pipefail

mkdir ruby-build
tar -C ruby-build --strip-components=1 -xzf ruby-build.tar.gz
PREFIX=/usr/local ./ruby-build/install.sh

# ruby-build verifies the checksum of every archive it downloads, and vendors OpenSSL 1.1.1
# under "${RUBY_PATH}/openssl" because Ruby 2.7's openssl extension does not support the
# OpenSSL 3.x of the base image. The whole Ruby installation is therefore self-contained in
# "${RUBY_PATH}", which is why it keeps working once copied as-is into the final image.
RUBY_CONFIGURE_OPTS="--disable-install-doc" ruby-build "${RUBY_VERSION}" "${RUBY_PATH}"

export PATH="${RUBY_PATH}/bin:${PATH}"
ruby -ropenssl -e 'puts RUBY_DESCRIPTION, OpenSSL::OPENSSL_LIBRARY_VERSION'
gem install bundler --version "${BUNDLER_VERSION}" --no-document
