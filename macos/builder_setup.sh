#!/bin/bash

set -e

# Setups a MacOS builder that can do unsigned builds of the MacOS Agent.
# The .build_setup file is populated with the correct envvar definitions to do the build,
# which are then used by the build script.

# Prerequisites:
# - A MacOS 10.13.6 (High Sierra) box

# About brew packages:
# We use a custom homebrew tap (DataDog/datadog-agent-macos-build)
# to keep pinned versions of the software we need.

# How to update a version of a brew package:
# 1. See the instructions of the DataDog/homebrew-datadog-agent-macos-build repo
#    to add a formula for the new version you want to use.
# 2. Update here the version of the formula to use.
export PKG_CONFIG_VERSION=0.29.2
export RUBY_VERSION=2.4.10
export PYTHON_VERSION=3.8.11
# Pin cmake version without sphinx-doc, which causes build issues
export CMAKE_VERSION=3.18.2.2
export GIMME_VERSION=1.5.4

export BUNDLER_VERSION=2.1.4

export GO_VERSION=1.16.7
export IBM_MQ_VERSION=9.2.2.0

# Install or upgrade brew (will also install Command Line Tools)
CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# Add our custom repository
brew tap DataDog/datadog-agent-macos-build

brew uninstall python@2 -f || true # Uninstall python 2 if present
brew uninstall python -f || true # Uninstall python 3 if present

# Install cmake
brew install DataDog/datadog-agent-macos-build/cmake@$CMAKE_VERSION -f
brew link --overwrite cmake@$CMAKE_VERSION

# Install pkg-config
brew install DataDog/datadog-agent-macos-build/pkg-config@$PKG_CONFIG_VERSION -f
brew link --overwrite pkg-config@$PKG_CONFIG_VERSION

# Install ruby (depends on pkg-config)
brew install DataDog/datadog-agent-macos-build/ruby@$RUBY_VERSION -f

# Brew link cannot be done, as there is a system ruby version (at least up to MacOS 10.14). You need to add the
# new ruby to the PATH directly.

# Note: ${RUBY_VERSION%.*} takes RUBY_VERSION but leaves out the shortest string (from the right) that
# matches what's after the %. Here, that means we leave out the bugfix version.
# That's needed because gems are stored in a folder named MAJOR.MINOR.0, whatever the bugfix version is.
export PATH="/usr/local/opt/ruby@$RUBY_VERSION/bin:/usr/local/lib/ruby/gems/${RUBY_VERSION%.*}.0/bin:$PATH"
echo 'export PATH="/usr/local/opt/ruby@'$RUBY_VERSION'/bin:/usr/local/lib/ruby/gems/'${RUBY_VERSION%.*}'.0/bin:$PATH"' >> ~/.build_setup

# Install bundler
gem install bundler -v $BUNDLER_VERSION -f

# Install python
brew install DataDog/datadog-agent-macos-build/python@$PYTHON_VERSION -f
brew link --overwrite python@$PYTHON_VERSION

mkdir -p $HOME/go
export GOPATH=$HOME/go
echo 'export GOPATH=$HOME/go' >> ~/.build_setup
export PATH="$GOPATH/bin:$PATH"
echo 'export PATH="$GOPATH/bin:$PATH"' >> ~/.build_setup

# Install gimme
brew install DataDog/datadog-agent-macos-build/gimme@$GIMME_VERSION -f
brew link --overwrite gimme@$GIMME_VERSION
eval `gimme $GO_VERSION`
echo 'eval `gimme '$GO_VERSION'`' >> ~/.build_setup

# Install IBM MQ
sudo mkdir -p /opt/mqm
curl "https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqdev/mactoolkit/${IBM_MQ_VERSION}-IBM-MQ-Toolkit-MacX64.pkg" -o /tmp/mq_client.pkg
sudo installer -pkg /tmp/mq_client.pkg -target /
sudo rm -rf /tmp/mq_client.pkg
