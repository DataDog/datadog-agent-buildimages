#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

set-ev PATH "\$PATH:$1"
