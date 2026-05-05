#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

dog_home="/home/dog"

groupadd --gid 501 dog
useradd --gid 501 --uid 501 --home-dir "${dog_home}" --groups users,build-shared,sudo dog

install -d -m 2775 -o root -g build-shared "${dog_home}"
cp -a /home/dd/. "${dog_home}/"
chgrp -R build-shared "${dog_home}"
chmod -R g+rwX "${dog_home}"
chmod g+rws,o+rx "${dog_home}"
setfacl -R -m g:build-shared:rwX,m:rwX "${dog_home}"
setfacl -d -m g:build-shared:rwx,m:rwx "${dog_home}"

passwd -d dog
usermod -U dog

# The workspace feature creates bits later with dog as its primary group.
sed -i '/^build-shared:/ s/$/,bits/' /etc/group

# Remove AWS CLI v2 since the workspace base feature will reinstall it.
# https://docs.aws.amazon.com/cli/latest/userguide/uninstall.html
rm -f /usr/local/bin/aws /usr/local/bin/aws_completer
rm -rf /usr/local/aws-cli
