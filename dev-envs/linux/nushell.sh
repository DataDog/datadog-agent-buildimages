#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

umask 0002

nu_config_dir="${DD_BUILD_CONFIG_ROOT}/nushell"
mkdir -p "${nu_config_dir}"

cat <<'EOF' > "${nu_config_dir}/config.nu"
# https://www.nushell.sh/book/configuration.html#remove-welcome-message
$env.config.show_banner = false

# Better command history
$env.config.history.file_format = "sqlite"
$env.config.history.isolation = true

# https://starship.rs/#nushell
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
EOF
