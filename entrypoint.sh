#!/bin/bash
set -e

source /root/.bashrc

cat .local-to-cat-file || echo "No local-to-cat-file found"

exec "$@"
