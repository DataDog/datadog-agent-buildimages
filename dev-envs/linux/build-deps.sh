#!/bin/bash -l
set -euxo pipefail

apt-get update && apt-get install -y libsystemd-dev

