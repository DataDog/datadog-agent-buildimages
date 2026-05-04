#!/usr/bin/env bash
set -euxo pipefail

cat <<EOF >> /etc/rvmrc
rvm_path=${RVM_PATH}
EOF

gpg --import /gpg-keys/*
rm -rf /gpg-keys
bash get-rvm.sh stable --version 1.29.12
echo "d2de0b610ee321489e5c673fe749e13be8fb34c0aa08a74446d87f95a17de730  ${RVM_PATH}/bin/rvm" | sha256sum --check

# Setup rvm in the current shell - rvm.sh has some unbound variables that need to be ignored, so we set +u to ignore them
set +u
source "${RVM_PATH}/scripts/rvm"
rvm requirements
rvm install 2.7 --with-openssl-dir=${CONDA_PATH}
rvm cleanup all
gem install bundler --version $BUNDLER_VERSION --no-document
echo "source ${RVM_PATH}/scripts/rvm" >> /root/.bashrc
