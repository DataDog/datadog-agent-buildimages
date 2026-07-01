FROM 486234852809.dkr.ecr.us-east-1.amazonaws.com/docker:20.10-py3

ARG VAULT_VERSION=1.17.2
ARG VAULT_CHECKSUM=1cdfd33e218ef145dbc3d71ac4164b89e453ff81b780ed178274bc1ba070e6e9
ARG VAULT_FILENAME="vault_${VAULT_VERSION}_linux_arm64.zip"

COPY requirements.txt /
COPY requirements /requirements

RUN python3 -m pip install -r requirements.txt

# Install vault: https://github.com/hashicorp/vault/blob/main/CHANGELOG.md https://releases.hashicorp.com/vault
RUN apt-get update && apt-get install -y --no-install-recommends unzip \
    && curl -LO https://releases.hashicorp.com/vault/$VAULT_VERSION/$VAULT_FILENAME \
    && echo "${VAULT_CHECKSUM}  ${VAULT_FILENAME}" | sha256sum --check \
    && unzip -o $VAULT_FILENAME -d /usr/bin vault \
    && rm $VAULT_FILENAME \
    && chmod +x /usr/bin/vault

# External calls configuration
COPY .awsconfig /root/.aws/config
COPY .curlrc .wgetrc /root/
