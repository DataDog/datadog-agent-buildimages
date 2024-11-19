#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

VERSION="0.99.1"

arch=$(uname -m)
if [[ "${arch}" == "aarch64" ]]; then
    DIGEST="7dfc447641e32e42e37ea09f3c9df253c4fb8f87fe2c7c44919b791460d8d242"
else
    DIGEST="bf1224c7866a670022232c2e832a9f63141378d1f1c3552defa4200902c4379a"
fi
url="https://github.com/nushell/nushell/releases/download/${VERSION}/nu-${VERSION}-${arch}-unknown-linux-musl.tar.gz"
install_dir="${HOME}/.nushell"

mkdir -p "${install_dir}"
curl "${url}" -Lo archive.tar.gz

digest="$(openssl dgst -sha256 archive.tar.gz | cut -d' ' -f2)"
if [[ "${digest}" != "${DIGEST}" ]]; then
    echo "Digest mismatch"
    echo "Expected: ${DIGEST}"
    echo "Got: ${digest}"
    exit 1
fi

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
