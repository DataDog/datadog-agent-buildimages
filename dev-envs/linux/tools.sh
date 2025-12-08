#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

arch=$(uname -m)
if [[ "$arch" == "aarch64" ]]; then
  short_arch="arm64"
else
  short_arch="amd64"
fi

# Install DotSlash
install-binary \
    --version "0.5.8" \
    --digest "cfdba94857f06e6b2d16aaebbfe24d73751d26fbd2173adef29a2df9078e2770" \
    --digest "35ac3bac979d56f6e6faefd1907de2373d35287321aeb48e82e34edfe1501cd8" \
    --url "https://github.com/facebook/dotslash/releases/download/v{{version}}/dotslash-linux-musl.${arch}.tar.gz" \
    --name "dotslash" \
    --top-level

# Generate DotSlash files
python3 /tools/dotslash/generate.py \
    --config-dir /tools/dotslash/config \
    --output-dir /usr/local/bin \
    --tools-file /mnt/tools.txt \
    --ignore-unavailable

# Install architecture-specific tools that don't have pre-built binaries for aarch64
AMBR_VERSION="0.6.0"
if [[ $arch == "aarch64" ]]; then
    rustup default stable
    cargo install --locked amber@${AMBR_VERSION}
fi

procs --gen-config > "${HOME}/.procs.toml"
# Necessary for working in our containers
sed -i 's/show_self_parents = false/show_self_parents = true/' "${HOME}/.procs.toml"

# Configure Git to use delta as the pager:
# https://dandavison.github.io/delta/get-started.html
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global merge.conflictStyle zdiff3

mkdir -p "${HOME}/.config"
mkdir -p "${DD_REPOS_DIR}"
gfold -d classic "${DD_REPOS_DIR}" --dry-run > "${HOME}/.config/gfold.toml"

curl_opts=(
  --fail              # fail on HTTP errors (>=400), prevents saving an error page
  --silent            # no progress meter or extra output
  --show-error        # but still show errors (important for debugging)
  --location          # follow redirects
  --retry 2           # retry N more times on transient errors
  --retry-connrefused # also if connection is refused (CDN saturation cases)
)

# The following tools are required for Visual Studio Code's Go extension:
# https://github.com/golang/vscode-go#quick-start
#
# If any are unavailable the extension will download upon editor startup which is a poor experience
go install golang.org/x/tools/gopls@latest

# Optional tools for Visual Studio Code's Go extension:
# https://github.com/golang/vscode-go/wiki/tools
go install github.com/go-delve/delve/cmd/dlv@latest
go install github.com/josharian/impl@latest
go install github.com/fatih/gomodifytags@latest

GOLANGCI_LINT_VERSION="$(curl "${curl_opts[@]}" https://raw.githubusercontent.com/DataDog/datadog-agent/main/internal/tools/go.mod | grep -Po '/golangci-lint.+v\K.+')"
install-binary \
    --version "${GOLANGCI_LINT_VERSION}" \
    --digest "4830e93721c979daa00921ebcb311bb0165d9ad9b0dc89708cbbca1b02ef1f0a" \
    --digest "fff5b69c2e411e064bb102a94e9eeee5c1ed4a72f130350326065f49bae90523" \
    --url "https://github.com/golangci/golangci-lint/releases/download/v{{version}}/golangci-lint-{{version}}-linux-${short_arch}.tar.gz" \
    --name "golangci-lint"
