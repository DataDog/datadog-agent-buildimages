#!/usr/bin/env bash

set -euo pipefail

KEY="$1"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://dd-agent-build-artifacts.s3.amazonaws.com/${KEY}")

[[ "${STATUS}" == "200" ]]
