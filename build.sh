#!/bin/bash
set -euxo pipefail

# Build and push to internal ECR
WORKDIR="."
if [[ "$DOCKERFILE" == "dev-envs/linux/Dockerfile" ]]; then WORKDIR="dev-envs/linux"; fi

# == Caching logic == #
function sanitize() {
    # Docker uses the Go reference format for images: https://pkg.go.dev/github.com/distribution/reference#pkg-overview
    # A tag name must match the following regex: /[\w][\w.-]{0,127}/
    # Git branch names can contain disallowed characters, so we need to sanitize them.
    # `\n` is included here as the pipe adds a newline to the end of the string - not allowing it would mean we get an extra `_` at the end.
    echo "$1" | tr -C '\na-zA-Z0-9_.-' '_'
}

# Setup keys
BRANCH_NAME="${CI_COMMIT_BRANCH:-unknown}"
CACHE_KEY_BRANCH="$(sanitize "cache-${BRANCH_NAME}-${DD_TARGET_ARCH}")"
CACHE_KEY_MAIN="$(sanitize "cache-${CI_DEFAULT_BRANCH}-${DD_TARGET_ARCH}")"

CACHE_DETAILS_BRANCH="type=registry,ref=registry.ddbuild.io/ci/datadog-agent-buildimages/$IMAGE:${CACHE_KEY_BRANCH}"
CACHE_DETAILS_MAIN="type=registry,ref=registry.ddbuild.io/ci/datadog-agent-buildimages/$IMAGE:${CACHE_KEY_MAIN}"

# Cache pull logic: pull from branch preferentially, fallback to main if no hit
# Do not use cache on periodic pipeline where we want to test our dependencies.
if [[ "$CI_PIPELINE_SOURCE" == "schedule" || -n "${PREVENT_CACHE:-}" ]]; then
    CACHE_PULL_ARGS="--no-cache"
else
    CACHE_PULL_ARGS="--cache-from ${CACHE_DETAILS_BRANCH} --cache-from ${CACHE_DETAILS_MAIN}"
fi

# Cache push logic: only push to branch cache
# Since on main CACHE_DETAILS_BRANCH == CACHE_DETAILS_MAIN, this works as expected.
CACHE_PUSH_ARGS="--cache-to ${CACHE_DETAILS_BRANCH}"

# == Image push logic == #
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

# Pass the CI_JOB_TOKEN if necessary
CI_JOB_TOKEN_ARG=
case "$IMAGE" in
    gitlab_agent_deploy|linux)
        CI_JOB_TOKEN_ARG="--build-arg CI_JOB_TOKEN_ARG=${CI_JOB_TOKEN:-}"
        ;;
esac

echo "Run buildx build"
docker buildx build \
--platform $PLATFORM \
--pull $PUSH \
$CACHE_PUSH_ARGS \
$CACHE_PULL_ARGS \
--build-arg BASE_IMAGE=${BASE_IMAGE:-} \
--build-arg BASE_IMAGE_TAG=${BASE_IMAGE_TAG:-} \
--build-arg ARCH=${ARCH:-} \
--build-arg DD_TARGET_ARCH=${DD_TARGET_ARCH:-} \
--build-arg BUILDENV_REGISTRY=${BUILDENV_REGISTRY:-} \
$CI_JOB_TOKEN_ARG \
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
