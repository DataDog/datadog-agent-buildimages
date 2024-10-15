#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# https://starship.rs/guide/

VERSION="v1.20.1"
COMMIT="cbc22a316db52f253719e258a3cd3c8fa4e1495b"

sh -c "$(curl -fsSL https://raw.githubusercontent.com/starship/starship/${COMMIT}/install/install.sh)" -- --yes --version "${VERSION}"

cat <<'EOF' >> "${HOME}/.zshrc"
eval "$(starship init zsh)"
EOF
