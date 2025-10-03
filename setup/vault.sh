#!/usr/bin/env bash
set -euxo pipefail

unzip -o vault.zip -d /usr/bin vault

# AWS v2 cli
unzip -q awscliv2.zip
./aws/install
