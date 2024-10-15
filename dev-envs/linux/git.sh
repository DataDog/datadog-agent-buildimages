#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

VERSION="2.37.3"
url="https://github.com/git/git/archive/refs/tags/v${VERSION}.tar.gz"

archive_name=$(basename "${url}")
workdir="/tmp/setup-${archive_name}"
mkdir -p "${workdir}"
curl "${url}" -Lo "${workdir}/${archive_name}"
tar -xf "${workdir}/${archive_name}" -C "${workdir}" --strip-components 1

pushd "${workdir}"
git_dir="${HOME}/git"
# https://git-scm.com/book/en/v2/Getting-Started-Installing-Git#_installing_from_source
make configure
./configure --prefix="${git_dir}"
make prefix="${git_dir}" -j "$(nproc)" all
make prefix="${git_dir}" install
popd
rm -rf "${workdir}"

# The Agent build defines an older version but we require a newer one for SSH signing so we
# install at a different path so as to not conflict with the build process
path-prepend "${git_dir}/bin"

# Force SSH for Go dependencies
cat <<'EOF' >> "${HOME}/.gitconfig"
[url "ssh://git@github.com/"]
insteadOf = https://github.com/
EOF

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
