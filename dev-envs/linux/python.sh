#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

VERSION="3.12.7"

uv python install "${VERSION}"
