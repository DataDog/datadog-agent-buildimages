#!/usr/bin/env bash
set -euxo pipefail

mkdir /tmp/vault
cd /tmp/vault

curl -LO https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_FILENAME}
echo "${VAULT_SHA256} ${VAULT_FILENAME}" | sha256sum --check
unzip -o ${VAULT_FILENAME} -d /usr/bin vault
rm ${VAULT_FILENAME}

# AWS v2 cli
curl --retry 10 -fsSLo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}-${AWSCLI_VERSION}.zip
echo "${AWSCLI_SHA256} awscliv2.zip" | sha256sum --check
unzip -q awscliv2.zip
./aws/install
rm -r aws awscliv2.zip

rm -r /tmp/vault
