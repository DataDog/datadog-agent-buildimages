#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

curl -fsSL https://claude.ai/install.sh | bash
