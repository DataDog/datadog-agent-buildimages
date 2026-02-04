#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# Remove side effects of APT installations
apt-get clean && rm -rf /var/lib/apt/lists/*

# Keep build roots but clear their contents.
# Preserving the root directory inode keeps its ownership/mode/default ACL metadata.
clear_root_contents() {
    root="$1"
    mkdir -p "${root}"
    find "${root}" -mindepth 1 -delete
}

# Snapshot image-baked config defaults from dd into dd-build.
mkdir -p "${DD_BUILD_CONFIG_ROOT}" "${DD_DEFAULT_CONFIG_ROOT}"
cp -a "${DD_BUILD_CONFIG_ROOT}/." "${DD_DEFAULT_CONFIG_ROOT}/"

# Keep roots but clear mutable contents in the final image.
clear_root_contents "${DD_BUILD_CACHE_ROOT}"
clear_root_contents "${DD_BUILD_CONFIG_ROOT}"

# Ensure runtime users can read image-baked defaults for first-run config seeding.
chgrp -R build-shared "${DD_DEFAULT_CONFIG_ROOT}"
chmod -R g+rX "${DD_DEFAULT_CONFIG_ROOT}"
setfacl -R -m g:build-shared:rX,m:rX "${DD_DEFAULT_CONFIG_ROOT}"

# Pre-install tools that are used by the entrypoint
required_tools=(
    "gosu"
    "jq"
    "watchexec"
)
for tool in "${required_tools[@]}"; do
    # TODO: Remove permission fix once DotSlash changes the defaults, see:
    #       https://github.com/facebook/dotslash/issues/107
    tool_path=$(dotslash -- fetch "/usr/local/bin/${tool}")
    chmod a+rx "${tool_path}"
done
