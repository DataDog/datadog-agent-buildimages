#!/bin/bash
set -euxo pipefail

# Build and push to internal ECR
WORKDIR="."
if [[ "$DOCKERFILE" == "dev-envs/linux/Dockerfile" ]]; then
    WORKDIR="dev-envs/linux"
    BUILD_CONTEXT_ARGS="--build-context dotslash=tools/dotslash"
fi

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

# == Build arguments == #
BUILD_ARG_LIST=()
[[ -n "${BASE_IMAGE:-}" ]]         && BUILD_ARG_LIST+=("--build-arg" "BASE_IMAGE=${BASE_IMAGE}")
[[ -n "${BASE_IMAGE_TAG:-}" ]]     && BUILD_ARG_LIST+=("--build-arg" "BASE_IMAGE_TAG=${BASE_IMAGE_TAG}")
[[ -n "${ARCH:-}" ]]               && BUILD_ARG_LIST+=("--build-arg" "ARCH=${ARCH}")
[[ -n "${DD_TARGET_ARCH:-}" ]]     && BUILD_ARG_LIST+=("--build-arg" "DD_TARGET_ARCH=${DD_TARGET_ARCH}")
[[ -n "${BUILDENV_REGISTRY:-}" ]]  && BUILD_ARG_LIST+=("--build-arg" "BUILDENV_REGISTRY=${BUILDENV_REGISTRY}")

# Add build args from go.env
if [[ -f "go.env" ]]; then
    while IFS= read -r line; do
        [[ -n "$line" ]] && BUILD_ARG_LIST+=("--build-arg" "$line")
    done < go.env
fi

# Add build args from dda.env
if [[ -f "dda.env" ]]; then
    while IFS= read -r line; do
        [[ -n "$line" ]] && BUILD_ARG_LIST+=("--build-arg" "$line")
    done < dda.env
fi

# Add build args from custom build args file
if [[ -f "${BUILD_ARGS_FILE:-}" ]]; then
    while IFS= read -r line; do
        [[ -n "$line" ]] && BUILD_ARG_LIST+=("--build-arg" "$line")
    done < "${BUILD_ARGS_FILE}"
fi

# Pass the CI_JOB_TOKEN if necessary
CI_JOB_TOKEN_SECRET=
case "$IMAGE" in
    gitlab_agent_deploy|linux)
        CI_JOB_TOKEN_SECRET="--secret id=ci-job-token,env=CI_JOB_TOKEN"
        ;;
esac

echo "Run buildx build"
docker buildx build \
--platform $PLATFORM \
--pull $PUSH \
$CACHE_PUSH_ARGS \
$CACHE_PULL_ARGS \
"${BUILD_ARG_LIST[@]}" \
$CI_JOB_TOKEN_SECRET \
--tag registry.ddbuild.io/ci/datadog-agent-buildimages/$IMAGE${ECR_TEST_ONLY}:$IMAGE_VERSION \
${BUILD_CONTEXT_ARGS:-} \
--file $DOCKERFILE $WORKDIR \
--output type=docker,dest=./$IMAGE-$IMAGE_VERSION.tar

# Statistics
if [[ "$CI_PIPELINE_SOURCE" != "schedule" ]]; then
    crane manifest registry.ddbuild.io/ci/datadog-agent-buildimages/$IMAGE${ECR_TEST_ONLY}:$IMAGE_VERSION | jq
    crane config registry.ddbuild.io/ci/datadog-agent-buildimages/$IMAGE${ECR_TEST_ONLY}:$IMAGE_VERSION | jq
    export SIZE=$(crane manifest registry.ddbuild.io/ci/datadog-agent-buildimages/$IMAGE${ECR_TEST_ONLY}:$IMAGE_VERSION | jq '.config.size + ([.layers[].size] | add)')
    ./send-metrics.sh $IMAGE $SIZE $CI_COMMIT_REF_NAME
fi
