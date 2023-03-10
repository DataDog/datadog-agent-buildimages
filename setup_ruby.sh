#!/bin/bash

set -ex

RUBY_MAJOR=2.7
RUBY_VERSION=2.7.7
RUBY_SHA256="e10127db691d7ff36402cfe88f418c8d025a3f1eea92044b162dd72f0b8c7b90"
RUBYGEMS_VERSION=3.4.8

curl -OL https://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz
echo "$RUBY_SHA256  ruby-$RUBY_VERSION.tar.gz" | sha256sum --check
tar -xzf ruby-$RUBY_VERSION.tar.gz
rm -rf ruby-$RUBY_VERSION.tar.gz

CONFIGURE_ARGS="--disable-install-doc --enable-shared --with-baseruby=no --with-openssl-dir='$CONDA_PATH'"
CFLAGS="-O3"

if [[ -n "$RUBY_WITH_ARCH" ]]; then
    CFLAGS="$CFLAGS -march=$RUBY_WITH_ARCH"
fi

if [[ -n "$RUBY_BUILD_ARCH" ]]; then
    CONFIGURE_ARGS="$CONFIGURE_ARGS --build $RUBY_BUILD_ARCH"
fi

mkdir -p ruby-$RUBY_VERSION/build

pushd ruby-$RUBY_VERSION/build
CFLAGS="$CFLAGS" CCFLAGS="$CFLAGS" CXXFLAGS="$CFLAGS" ../configure $CONFIGURE_ARGS
make install
popd

curl -OL https://rubygems.org/rubygems/rubygems-$RUBYGEMS_VERSION.tgz
tar -xzf rubygems-$RUBYGEMS_VERSION.tgz
rm -rf rubygems-$RUBYGEMS_VERSION.tgz

pushd rubygems-$RUBYGEMS_VERSION
ruby setup.rb
popd

rm -rf ruby-$RUBY_VERSION
rm -rf rubygems-$RUBYGEMS_VERSION