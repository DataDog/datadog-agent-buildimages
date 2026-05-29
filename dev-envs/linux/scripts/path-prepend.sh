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

cat <<EOF >> "${XDG_CONFIG_HOME}/nushell/config.nu"
\$env.PATH = (\$env.PATH | prepend '$1')
EOF
