#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

repo_spec="$1"
if [[ "${repo_spec}" == */* ]]; then
    owner="${repo_spec%%/*}"
    repo="${repo_spec#*/}"
else
    owner="DataDog"
    repo="${repo_spec}"
fi

normalized_owner="${owner,,}"
if [[ "${normalized_owner}" == "ddoghq" || "${normalized_owner}" == ddoghq-* ]]; then
    if [[ "${owner}" != "${normalized_owner}" ]]; then
        echo "Enterprise repository owner '${owner}' must use canonical lowercase casing: '${normalized_owner}/${repo}'." >&2
        exit 1
    fi
    if [[ ! -f "${DD_SHARED_DIR}/git-ssh/keys/github-com-ddoghq-auth.pub" ]]; then
        echo "The host did not provide a usable enterprise SSH identity for ${owner}. Run 'dda env dev ssh doctor' on the host for details." >&2
        echo "After fixing the host identity, recreate the developer environment to enable enterprise access." >&2
        exit 1
    fi
fi

remote="https://github.com/${owner}/${repo}"
clone_dir="${DD_REPO_ROOT}/${repo}"
branch="${2:-}"

if [[ -d "${clone_dir}" && -n "$(ls -A "${clone_dir}")" ]]; then
  exit
fi

if [[ -z "${branch}" ]]; then
    git clone "${remote}" "${clone_dir}" --depth 1
else
    if git ls-remote --exit-code --heads "${remote}" "${branch}" > /dev/null; then
        git clone "${remote}" "${clone_dir}" --depth 1 --branch "${branch}" --single-branch
    else
        git clone "${remote}" "${clone_dir}" --depth 1

        # Shell plugins make this noisy
        set +x
        cd "${clone_dir}"
        set -x

        git switch -c "${branch}"
    fi
fi

# The first time is a bit slow so do that now for a better experience
gfold "${clone_dir}" > /dev/null 2>&1
