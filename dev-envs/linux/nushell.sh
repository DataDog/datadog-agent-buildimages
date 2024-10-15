#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

VERSION="0.99.1"

arch=$(uname -m)
url="https://github.com/nushell/nushell/releases/download/${VERSION}/nu-${VERSION}-${arch}-unknown-linux-musl.tar.gz"
install_dir="${HOME}/.nushell"

mkdir -p "${install_dir}"
curl "${url}" -Lo archive.tar.gz
tar -xzf archive.tar.gz -C "${install_dir}" --strip-components=1
rm archive.tar.gz

# Materialize the default configuration and suppress interactivity for first-time use
"${install_dir}/nu" -l -c "config env --default | save -f \$nu.env-path" < /dev/null
"${install_dir}/nu" -l -c "config nu --default | save -f \$nu.config-path" < /dev/null

nu_env_file="$("${install_dir}/nu" -l -c "echo \$nu.env-path")"
nu_config_file="$("${install_dir}/nu" -l -c "echo \$nu.config-path")"

# https://www.nushell.sh/book/configuration.html#remove-welcome-message
sed -i 's/show_banner: true/show_banner: false/' "${nu_config_file}"

# Better command history
sed -i 's/file_format: "plaintext"/file_format: "sqlite"/' "${nu_config_file}"
sed -i 's/isolation: false/isolation: true/' "${nu_config_file}"

# https://starship.rs/#nushell
# Remove extra new lines when this is released:
# https://github.com/nushell/nushell/pull/14192
cat <<'EOF' >> "${nu_env_file}"

mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu
EOF

cat <<'EOF' >> "${nu_config_file}"

use ~/.cache/starship/init.nu
EOF

# Queue up post-processing
cat <<EOF >> /setup/shellrc.sh
export NUSHELL_ENV_FILE="${nu_env_file}"
export PATH="${install_dir}:\${PATH}"
EOF

cat <<EOF >> /setup/env.sh
set-ev NUSHELL_ENV_FILE "${nu_env_file}"
path-append "${install_dir}"
EOF
