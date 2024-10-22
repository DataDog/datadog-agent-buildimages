#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# https://github.com/ohmyzsh/ohmyzsh#basic-installation

COMMIT="61bacd95b285a9792a05d1c818d9cee15ebe53c6"

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/${COMMIT}/tools/install.sh)"

# Fix locale broken by Oh My Zsh:
# https://github.com/starship/starship/issues/2176#issuecomment-1783086362
cat <<'EOF' >> "${HOME}/.zshrc"
export LC_ALL="C.UTF-8"
export LANG="C.UTF-8"
EOF
