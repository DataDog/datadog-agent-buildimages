#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

git_dir="${HOME}/git"

# Temporarily required for the ARM image, see:
# https://confluence.atlassian.com/bitbucketserverkb/bitbucket-server-repository-import-fails-with-error-remote-https-is-not-a-git-command-1103438202.html
apt-get update && apt-get install -y libcurl4-openssl-dev

# https://git-scm.com/book/en/v2/Getting-Started-Installing-Git#_installing_from_source
install-from-source \
    --version "2.37.3" \
    --digest "730ea150a9af30e6301d3ff4169567d5a5c52950e122c1a10d21998f7a7f70d7" \
    --url "https://github.com/git/git/archive/refs/tags/v{{version}}.tar.gz" \
    --relative-path "git-{{version}}" \
    --configure-script "make configure && ./configure --prefix=\"${git_dir}\"" \
    --install-script "make prefix=\"${git_dir}\" -j \"$(nproc)\" all && make prefix=\"${git_dir}\" install"

# The Agent build defines an older version but we require a newer one for SSH signing so we
# install at a different path so as to not conflict with the build process
path-prepend "${git_dir}/bin"

# Set up signing:
# https://github.blog/open-source/git/highlights-from-git-2-34/#tidbits
git config --global commit.gpgsign true
git config --global gpg.format ssh
git config --global gpg.ssh.defaultKeyCommand "ssh-add -L"

# Set up easier tracking:
# https://git-scm.com/docs/git-config#Documentation/git-config.txt-pushdefault
# https://git-scm.com/docs/git-config#Documentation/git-config.txt-pushautoSetupRemote
git config --global push.default current
git config --global push.autoSetupRemote true
