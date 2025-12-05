#!/bin/bash

set -ex
source /root/.bashrc
uv export --no-editable --no-hashes -o requirements.txt

# The repo is cloned without any git metadata, so we need this otherwise setuptools-scm will fail
export SETUPTOOLS_SCM_PRETEND_VERSION=${DDA_VERSION}

# building msgspec>=0.20.0 is failing because it requires C11 stdatomic.h e.g.:
# src/msgspec/_core.c:7:23: fatal error: stdatomic.h: No such file or directory
cat > /tmp/constraints.txt << 'EOF'
msgspec<0.20.0
EOF

pip install -r requirements.txt -c /tmp/constraints.txt

dda self telemetry disable
dda config set update.mode off
dda -v self dep sync -f legacy-build

conda clean -a
