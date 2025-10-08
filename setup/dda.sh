#!/bin/bash

set -ex
source /root/.bashrc
uv export --no-editable --no-hashes -o requirements.txt

# The repo is cloned without any git metadata, so we need this otherwise setuptools-scm will fail
export SETUPTOOLS_SCM_PRETEND_VERSION=${DDA_VERSION}
pip install -r requirements.txt

dda self telemetry disable
dda config set update.mode off
dda -v self dep sync -f legacy-build

conda clean -a
