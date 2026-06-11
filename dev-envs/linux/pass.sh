#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

apt-get update && apt-get install -y pass

# NOTE: We create a separate gpg dir for pass, and configure pass to always use that gpg
# homedir. This ensures we don't conflict with a forwarded gpg-agent
export PASS_GPG_HOME=${XDG_CONFIG_HOME}/.config/password-store/gpg
mkdir -m 700 -p \$PASS_GPG_HOME
gpg --homedir \$PASS_GPG_HOME --batch --passphrase '' --quick-generate-key --yes password-store
PASSWORD_STORE_GPG_OPTS="--homedir \$PASS_GPG_HOME" pass init 'password-store'
set-ev PASSWORD_STORE_GPG_OPTS "--homedir \"${PASS_GPG_HOME}\""
