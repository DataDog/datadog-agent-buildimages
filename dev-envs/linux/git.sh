#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

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
