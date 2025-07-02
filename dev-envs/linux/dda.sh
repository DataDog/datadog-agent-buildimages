#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# Re-install dda if INSTALL_DDA is set, otherwise link the dda from the conda environment
if [[ -n "${INSTALL_DDA:-}" ]]; then
    "${HOME}/.venv/bin/pip" install "git+https://github.com/DataDog/datadog-agent-dev.git@${DDA_VERSION}"
else
    ln -s "$(/root/miniforge3/condabin/conda run -n ddpy3 which dda)" /usr/local/bin/dda
fi

dda self telemetry disable
dda self dep sync -f mcp
