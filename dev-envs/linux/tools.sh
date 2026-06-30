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

set-ev SKIM_DEFAULT_COMMAND "fd ."

(
  umask 0002
  procs_config_dir="${DD_BUILD_CONFIG_ROOT}/procs"
  mkdir -p "${procs_config_dir}"

  # Necessary for working in our containers
  cat > "${procs_config_dir}/config.toml" <<'EOF'
show_self_parents = true
EOF
)

(
  umask 0002
  # TODO: Use our path when `XDG_CONFIG_HOME` is supported.
  # https://github.com/bootandy/dust/issues/577
  # dust_config_dir="${DD_BUILD_CONFIG_ROOT}/dust"
  dust_config_dir="${HOME}/.config/dust"
  mkdir -p "${dust_config_dir}"

  # Note that the option names aren't identical to the command-line options.
  # https://github.com/bootandy/dust/blob/master/src/config.rs
  cat > "${dust_config_dir}/config.toml" <<'EOF'
no-bars = true
collapse = [".git"]
EOF
)

(
  umask 0002
  git_config_dir="${DD_BUILD_CONFIG_ROOT}/git"
  delta_gitconfig="${git_config_dir}/delta"
  jj_config_dir="${DD_BUILD_CONFIG_ROOT}/jj"
  mkdir -p "${git_config_dir}" "${jj_config_dir}"

  # Configure Git to use diffnav as the diff pager and Delta for everything else
  cat > "${delta_gitconfig}" <<'EOF'
[core]
pager = delta
[pager]
diff = diffnav
[interactive]
diffFilter = delta --color-only
[merge]
conflictStyle = zdiff3
[delta]
navigate = true
hyperlinks = true
true-color = always
EOF
  git config --global include.path "${delta_gitconfig}"

  # Configure Jujutsu to use Delta:
  # https://dandavison.github.io/delta/configuration.html#jujutsu
  cat > "${jj_config_dir}/config.toml" <<'EOF'
[ui]
pager = "delta"
diff-formatter = ":git"
EOF
)

curl_opts=(
  --fail              # fail on HTTP errors (>=400), prevents saving an error page
  --silent            # no progress meter or extra output
  --show-error        # but still show errors (important for debugging)
  --location          # follow redirects
  --retry 2           # retry N more times on transient errors
  --retry-connrefused # also if connection is refused (CDN saturation cases)
)

(
  # Ensure that these are installed to the system-wide bin directory rather than
  # a directory persisted for users.
  export GOBIN=/usr/local/bin

  # The following tools are required for Visual Studio Code's Go extension:
  # https://github.com/golang/vscode-go#quick-start
  #
  # If any are unavailable the extension will download upon editor startup which is a poor experience

  # Feature request for standalone binaries:
  # https://github.com/golang/go/issues/79066
  go install golang.org/x/tools/gopls@latest

  # Optional tools for Visual Studio Code's Go extension:
  # https://github.com/golang/vscode-go/wiki/tools
  go install github.com/josharian/impl@latest
  go install github.com/fatih/gomodifytags@latest
)

GOLANGCI_LINT_VERSION="$(curl "${curl_opts[@]}" https://raw.githubusercontent.com/DataDog/datadog-agent/main/internal/tools/go.mod | grep -Po '/golangci-lint.+v\K.+')"
install-binary \
    --version "${GOLANGCI_LINT_VERSION}" \
    --ignore-digests \
    --url "https://github.com/golangci/golangci-lint/releases/download/v{{version}}/golangci-lint-{{version}}-linux-${short_arch}.tar.gz" \
    --name "golangci-lint"

# We need to add the binary directory to PATH because `ddtool` creates helpers that are symlinked to and live
# alongside itself which are expected to be available to users after running the helper installation command.
ddtool_binary_dir="$(dirname "$(dotslash -- fetch /usr/local/bin/ddtool)")"
path-append "${ddtool_binary_dir}"
