#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# This file accumulates all startup logic from every tool and runs when the container starts. Certain tools
# need to be set up during the image entrypoint so that user volumes are available. For example, we need to
# modify the Starship prompt config but we also need the default to be what the user provides. In this case
# we copy what is in the volume to the proper location and then modify that.

# Remove annoying container indicator from prompt:
# https://github.com/starship/starship/issues/6174
mkdir -p "${HOME}/.config"
if [[ -f "${DD_MOUNT_DIR}/shell/starship.toml" ]]; then
  cp "${DD_MOUNT_DIR}/shell/starship.toml" "${HOME}/.config/starship.toml"
fi
cat <<'EOF' >> "${HOME}/.config/starship.toml"
[container]
disabled = true
EOF
