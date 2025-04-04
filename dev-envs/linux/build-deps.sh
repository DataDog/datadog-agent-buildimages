#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

apt-get update && apt-get install -y libsystemd-dev

