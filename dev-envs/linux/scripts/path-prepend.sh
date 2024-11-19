#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

rc_files=(
    "${HOME}/.profile"
    "${HOME}/.bashrc"
    "${HOME}/.zshenv"
)
for rc_file in "${rc_files[@]}"; do
cat <<EOF >> "${rc_file}"
export PATH="$1:\${PATH}"
EOF
done

cat <<EOF >> "${NUSHELL_ENV_FILE}"
\$env.PATH = (\$env.PATH | split row (char esep) | prepend '$1')
EOF
