#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

rc_files=(
    "${HOME}/.profile"
    "${HOME}/.bashrc"
    "${HOME}/.zshenv"
)
home_prefix="${HOME%/}/"
path_expr="$1"
nu_expr="'$1'"
if [[ "$1" == "${HOME}" ]]; then
    path_expr="\$HOME"
    nu_expr="\$env.HOME"
elif [[ "$1" == "${home_prefix}"* ]]; then
    relative_path="${1#${home_prefix}}"
    path_expr="\$HOME/${relative_path}"
    nu_expr="(\$env.HOME | path join '${relative_path}')"
fi
for rc_file in "${rc_files[@]}"; do
cat <<EOF >> "${rc_file}"
export PATH="${path_expr}:\${PATH}"
EOF
done

cat <<EOF >> "${HOME}/.config/nushell/env.nu"
\$env.PATH = (\$env.PATH | split row (char esep) | prepend ${nu_expr})
EOF
