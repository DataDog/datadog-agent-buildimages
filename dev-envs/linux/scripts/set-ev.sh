#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

rc_files=(
    # https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html
    "${HOME}/.profile"
    "${HOME}/.bashrc"
    # https://zsh.sourceforge.io/Intro/intro_3.html
    "${HOME}/.zshenv"
)
home_prefix="${HOME%/}/"
value_expr="$2"
nu_expr="'$2'"
if [[ "$2" == "${HOME}" ]]; then
    value_expr="\$HOME"
    nu_expr="\$env.HOME"
elif [[ "$2" == "${home_prefix}"* ]]; then
    relative_value="${2#${home_prefix}}"
    value_expr="\$HOME/${relative_value}"
    nu_expr="(\$env.HOME | path join '${relative_value}')"
fi
for rc_file in "${rc_files[@]}"; do
cat <<EOF >> "${rc_file}"
export $1="${value_expr}"
EOF
done

# https://www.nushell.sh/book/configuration.html#configuration-overview
cat <<EOF >> "${HOME}/.config/nushell/env.nu"
\$env.$1 = ${nu_expr}
EOF
