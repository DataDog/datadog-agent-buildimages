#!/bin/bash

# Fetches the datadog-agent repo, checks out to the requested version
# and does an omnibus build of the Agent.

# Prerequisites:
# - builder_setup.sh has been run
# - $VERSION contains the datadog-agent git ref to target
# - $RELEASE_VERSION contains the release.json version to package. Defaults to $VERSION
# - $AGENT_MAJOR_VERSION contains the major version to release
# - $PYTHON_RUNTIMES contains the included python runtimes
# - $SIGN set to true if signing is enabled
# - if $SIGN is set to true:
#   - $KEYCHAIN_NAME contains the keychain name. Defaults to login.keychain
#   - $KEYCHAIN_PWD contains the keychain password

export RELEASE_VERSION=${RELEASE_VERSION:-$VERSION}
export KEYCHAIN_NAME=${KEYCHAIN_NAME:-"login.keychain"}

# Load build setup vars
source ~/.build_setup

# Clone the repo
go get github.com/DataDog/datadog-agent || true # Go get fails if the datadog-agent repo is already there
cd $GOPATH/src/github.com/Datadog/datadog-agent

# Checkout to correct version
git pull
git checkout "$VERSION"

# Install python deps (invoke, etc.)
python3 -m pip install -r requirements.txt

# Clean up previous builds
sudo rm -rf /opt/datadog-agent ./vendor ./vendor-new /var/cache/omnibus/src/* ./omnibus/Gemfile.lock

# Create target folders
sudo mkdir -p /opt/datadog-agent /var/cache/omnibus && sudo chown "$USER" /opt/datadog-agent /var/cache/omnibus

# Launch omnibus build
if [ "$SIGN" = "true" ]; then
    # Unlock the keychain to get access to the signing certificates
    security unlock-keychain -p "$KEYCHAIN_PWD" "$KEYCHAIN_NAME"
    inv -e agent.omnibus-build --hardened-runtime --python-runtimes "$PYTHON_RUNTIMES" --major-version "$AGENT_MAJOR_VERSION" --release-version "$RELEASE_VERSION"
    # Lock the keychain once we're done
    security lock-keychain "$KEYCHAIN_NAME"
else
    inv -e agent.omnibus-build --skip-sign --python-runtimes "$PYTHON_RUNTIMES" --major-version "$AGENT_MAJOR_VERSION" --release-version "$RELEASE_VERSION"
fi
