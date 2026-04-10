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
for rc_file in "${rc_files[@]}"; do
cat <<EOF >> "${rc_file}"
export $1="$2"
EOF
done

# https://www.nushell.sh/book/configuration.html#configuration-overview
cat <<EOF >> "${XDG_CONFIG_HOME}/nushell/env.nu"
\$env.$1 = '$2'
EOF
