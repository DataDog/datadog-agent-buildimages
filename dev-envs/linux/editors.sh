#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

dda self mcp-server configure-editors
