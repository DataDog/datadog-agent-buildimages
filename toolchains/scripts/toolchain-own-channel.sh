#!/usr/bin/env bash

set -euo pipefail

# Publishing under main/ marks an artifact as canonical/trusted; publishing under
# branches/ keeps PR/feature-branch builds separate so they can never be picked up
# as if they were built from main.
if [[ "${CI_COMMIT_BRANCH:-}" == "${CI_DEFAULT_BRANCH:-}" ]]; then
    echo "main"
else
    echo "branches"
fi
