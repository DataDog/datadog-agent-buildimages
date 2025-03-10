#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# Re-install dda if DDA_VERSION is set, otherwise link the dda from the conda environment
if [[ -n "${DDA_VERSION}" ]]; then
    "${HOME}/.venv/bin/pip" install "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}"
else
    ln -s "$(/root/miniforge3/condabin/conda run -n ddpy3 which dda)" /usr/local/bin/dda
fi

dda self telemetry disable
