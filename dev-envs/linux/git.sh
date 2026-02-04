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

# Tolerate owner mismatches for host-mounted repositories
# TODO: Change the pattern to `${DD_REPO_ROOT}/*` when we upgrade
#       Git to 2.46.0+ for `safe.directory` improvements, see:
#       https://github.com/git/git/blob/master/Documentation/RelNotes/2.46.0.adoc#fixes-since-v245
cat <<EOF >> "${HOME}/.gitconfig"
[safe]
directory = *
EOF
