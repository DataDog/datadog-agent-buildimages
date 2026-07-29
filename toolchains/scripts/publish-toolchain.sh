#!/usr/bin/env bash

set -euxo pipefail

curl -sSf "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o awscliv2.zip
unzip -q awscliv2.zip
./aws/install

# Publishing under main/ marks an artifact as canonical/trusted; publishing under
# branches/ keeps PR/feature-branch builds separate so they can never be picked up
# as if they were built from main.
if [[ "${CI_COMMIT_BRANCH:-}" == "${CI_DEFAULT_BRANCH:-}" ]]; then
    CHANNEL="main"
else
    CHANNEL="branches"
fi
KEY=$(./toolchains/scripts/toolchain-artifact-key.sh "${TOOLCHAIN_HOST_ARCH}" "${TOOLCHAIN_TARGET_ARCH}" "${TOOLCHAIN_HASH}" "${CHANNEL}")
ARCHIVE="${CI_PROJECT_DIR}/${TOOLCHAIN_TARGET_ARCH}-unknown-linux-gnu-gcc.tar.xz"

sha256sum "${ARCHIVE}" | awk '{print "sha256:" $1}' > "${ARCHIVE}.sha256"

# The bucket requires if-none-match on writes so artifacts can never be overwritten.
# A 412 here means another pipeline published this exact content-addressed artifact
# concurrently, which is fine: the recipe hash guarantees the content is the same.
upload() {
    local key="$1"
    local body="$2"
    if OUTPUT=$(aws s3api put-object --bucket dd-agent-build-artifacts --key "${key}" --body "${body}" --if-none-match '*' 2>&1); then
        echo "${OUTPUT}"
        return 0
    fi
    if echo "${OUTPUT}" | grep -q "PreconditionFailed"; then
        echo "Already published concurrently by another pipeline, nothing to do: ${key}"
        return 0
    fi
    echo "${OUTPUT}" >&2
    return 1
}

upload "${KEY}" "${ARCHIVE}"
upload "${KEY}.sha256" "${ARCHIVE}.sha256"
