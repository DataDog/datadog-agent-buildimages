#!/bin/bash

# Setups a MacOS builder that can do unsigned builds of the MacOS Agent.
# The .build_setup file is populated with the correct envvar definitions to do the build,
# which are then used by the build script.

# Prerequisites:
# - A MacOS 10.13.6 (High Sierra) box

export GO_VERSION=1.13.8
export RUBY_VERSION=2.4

# Install or upgrade brew (will also install Command Line Tools)
CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# Install ruby & bundler
brew install ruby@$RUBY_VERSION -f
export PATH="/usr/local/opt/ruby@$RUBY_VERSION/bin:/usr/local/lib/ruby/gems/$RUBY_VERSION.0/bin:$PATH"
echo 'export PATH="/usr/local/opt/ruby@'$RUBY_VERSION'/bin:/usr/local/lib/ruby/gems/'$RUBY_VERSION'.0/bin:$PATH"' >> ~/.build_setup
gem install bundle -f

# Install build tools
brew uninstall python@2 || true # Uninstall python 2 if present
brew upgrade python -f || brew install python -f # If python 3 is already present, upgrade it. Otherwise install it.
ln -s /usr/local/bin/pip3 /usr/local/bin/pip # Use pip3 by default

brew install pkg-config -f
brew install cmake -f

mkdir -p $HOME/go
export GOPATH=$HOME/go
echo 'export GOPATH=$HOME/go' >> ~/.build_setup
export PATH="$GOPATH/bin:$PATH"
echo 'export PATH="$GOPATH/bin:$PATH"' >> ~/.build_setup

brew install gimme
eval `gimme $GO_VERSION`
echo 'eval `gimme '$GO_VERSION'`' >> ~/.build_setup
