#!/usr/bin/env bash
set -euxo pipefail

mkdir /tmp/datadog-ci
cd /tmp/datadog-ci

curl -fsSL https://github.com/DataDog/datadog-ci/releases/download/v${DATADOG_CI_VERSION}/datadog-ci_linux-${DATADOG_CI_ARCH} --output "/usr/local/bin/datadog-ci"
echo "${DATADOG_CI_SHA256} /usr/local/bin/datadog-ci" | sha256sum --check
chmod +x /usr/local/bin/datadog-ci

rm -rf /tmp/datadog-ci
