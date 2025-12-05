#!/usr/bin/env bash
set -euxo pipefail

gpg --import /gpg-keys/*
rm -rf /gpg-keys
curl -sSL -o get-rvm.sh https://raw.githubusercontent.com/rvm/rvm/1.29.12/binscripts/rvm-installer
echo "fea24461e98d41528d6e28684aa4c216dbe903869bc3fcdb3493b6518fae2e7e  get-rvm.sh" | sha256sum --check
bash get-rvm.sh stable --version 1.29.12
echo "d2de0b610ee321489e5c673fe749e13be8fb34c0aa08a74446d87f95a17de730  /usr/local/rvm/bin/rvm" | sha256sum --check
rm get-rvm.sh
# Setup rvm in the current shell - rvm.sh has some unbound variables that need to be ignored, so we set +u to ignore them
set +u
source /etc/profile.d/rvm.sh
rvm requirements
rvm install 2.7 --with-openssl-dir=${CONDA_PATH}
rvm cleanup all
gem install bundler --version $BUNDLER_VERSION --no-document
echo 'source /usr/local/rvm/scripts/rvm' >> /root/.bashrc
