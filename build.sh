#!/bin/bash
set -euo pipefail

# Build and push to internal ECR
WORKDIR="."
if [[ "$DOCKERFILE" == "dev-envs/linux/Dockerfile" ]]; then WORKDIR="dev-envs/linux"; fi
CACHE_KEY="cache-${DD_TARGET_ARCH}"
CACHE_SOURCE="--cache-from type=registry,ref=registry.ddbuild.io/ci/datadog-agent-buildimages/$IMAGE${ECR_TEST_ONLY}:${CACHE_KEY}"
# Do not use cache on periodic pipeline where we want to test our dependencies.
if [[ "$CI_PIPELINE_SOURCE" == "schedule" || -n "${PREVENT_CACHE:-}" ]]; then
    CACHE_SOURCE="--no-cache"
fi
PUSH=""
if [[ "$CI_PIPELINE_SOURCE" != "schedule" ]]; then
    PUSH="--push"
fi

# Collect build arguments
GO_BUILD_ARGS=$(sed -e 's/^/--build-arg /' go.env | tr '\n' ' ')
DDA_BUILD_ARGS=$(sed -e 's/^/--build-arg /' dda.env| tr '\n' ' ')
if [[ -f "${BUILD_ARGS_FILE:-}" ]]; then
    CUSTOM_BUILD_ARGS=$(sed -e 's/^/--build-arg /' "${BUILD_ARGS_FILE}" | tr '\n' ' ')
fi

echo "Run buildx build"
docker buildx build \
--platform $PLATFORM \
--pull $PUSH \
--cache-to type=registry,ref=registry.ddbuild.io/ci/datadog-agent-buildimages/$IMAGE${ECR_TEST_ONLY}:${CACHE_KEY},mode=max ${CACHE_SOURCE} \
--build-arg BASE_IMAGE=${BASE_IMAGE:-} \
--build-arg BASE_IMAGE_TAG=${BASE_IMAGE_TAG:-} \
--build-arg ARCH=${ARCH:-} \
--build-arg DD_TARGET_ARCH=${DD_TARGET_ARCH:-} \
--build-arg BUILDENV_REGISTRY=${BUILDENV_REGISTRY:-} \
$GO_BUILD_ARGS \
$DDA_BUILD_ARGS \
${CUSTOM_BUILD_ARGS:-} \
--tag registry.ddbuild.io/ci/datadog-agent-buildimages/$IMAGE${ECR_TEST_ONLY}:$IMAGE_VERSION \
--file $DOCKERFILE $WORKDIR \
--output type=docker,dest=./$IMAGE-$IMAGE_VERSION.tar

# Statistics
if [[ "$CI_PIPELINE_SOURCE" != "schedule" ]]; then
    crane manifest registry.ddbuild.io/ci/datadog-agent-buildimages/$IMAGE${ECR_TEST_ONLY}:$IMAGE_VERSION | jq
    crane config registry.ddbuild.io/ci/datadog-agent-buildimages/$IMAGE${ECR_TEST_ONLY}:$IMAGE_VERSION | jq
    export SIZE=$(crane manifest registry.ddbuild.io/ci/datadog-agent-buildimages/$IMAGE${ECR_TEST_ONLY}:$IMAGE_VERSION | jq '.config.size + ([.layers[].size] | add)')
    ./send-metrics.sh $IMAGE $SIZE $CI_COMMIT_REF_NAME
fi
