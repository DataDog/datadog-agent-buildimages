#!/usr/bin/env bash
set -euxo pipefail

gpg --import /gpg-keys/*
rm -rf /gpg-keys
bash get-rvm.sh stable --version 1.29.12
echo "d2de0b610ee321489e5c673fe749e13be8fb34c0aa08a74446d87f95a17de730  /usr/local/rvm/bin/rvm" | sha256sum --check
rm get-rvm.sh
# Reload shell
exec bash -l
rvm requirements
rvm install 2.7 --with-openssl-dir=${CONDA_PATH}
rvm cleanup all
gem install bundler --version $BUNDLER_VERSION --no-document
echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc
