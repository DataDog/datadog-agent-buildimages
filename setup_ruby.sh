#!/bin/bash

set -ex

RUBY_MAJOR=2.7
RUBY_VERSION=2.7.7

RUN apt-get -y update && apt-get -y install curl make gcc libssl-dev

curl -OL https://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz
tar -xzf ruby-$RUBY_VERSION.tar.gz
rm -rf ruby-$RUBY_VERSION.tar.gz

mkdir -p ruby-$RUBY_VERSION/build

pushd ruby-$RUBY_VERSION/build
../configure --with-openssl-dir="$CONDA_PATH"
make install
popd

rm -rf ruby-$RUBY_VERSION