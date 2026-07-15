#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# The AWS CLI needs groff to render its help text.
apt-get update && apt-get install -y --no-install-recommends groff-base
