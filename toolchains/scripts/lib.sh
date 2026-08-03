#!/usr/bin/env bash

# Shared helpers for the toolchain build/publish scripts.

toolchain_config_path() {
    local host_arch="$1"
    local target_arch="$2"
    local config="toolchains/crosstool-ng/${host_arch}/config-${target_arch}-unknown-gnu-linux"

    if [[ ! -f "${config}" ]]; then
        echo "No crosstool-ng config found for host=${host_arch} target=${target_arch}: ${config}" >&2
        return 1
    fi

    echo "${config}"
}

# crosstool-ng names the target triplet after the target's ABI. Every arch we build uses
# the "<arch>-linux-gnu" triplet, except armhf, whose EABIHF ABI produces
# "arm-linux-gnueabihf" instead.
toolchain_triplet() {
    local target_arch="$1"

    case "${target_arch}" in
        armhf) echo "arm-linux-gnueabihf" ;;
        *)     echo "${target_arch}-linux-gnu" ;;
    esac
}

toolchain_artifact_key() {
    local host_arch="$1"
    local target_arch="$2"
    local hash="$3"
    local channel="$4"
    local triplet
    triplet=$(toolchain_triplet "${target_arch}")

    echo "toolchains/${channel}/${hash}/${host_arch}/${triplet}-gcc.tar.xz"
}

resolve_toolchain_hash() {
    local host_arch="$1"
    local target_arch="$2"
    local config
    config=$(toolchain_config_path "${host_arch}" "${target_arch}")

    cat \
        "${config}" \
        toolchains/crosstool-ng/ctng.patch \
        toolchains/crosstool-ng/ctng-version.env \
        toolchains/scripts/build-crosstool-ng-toolchain.sh \
        | sha256sum | cut -d' ' -f1
}

s3_artifact_exists() {
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" --head "https://dd-agent-build-artifacts.s3.amazonaws.com/$1")
    [[ "${status}" == "200" ]]
}

# main/ is always trusted, even off the default branch: a PR that doesn't touch the
# recipe should reuse the canonical artifact instead of rebuilding it. branches/ is
# only trusted for the branch that published it in the first place, since it's never
# checked while on the default branch.
resolve_toolchain_channel() {
    local host_arch="$1"
    local target_arch="$2"
    local hash="$3"
    local main_key branch_key

    main_key=$(toolchain_artifact_key "${host_arch}" "${target_arch}" "${hash}" main)
    if s3_artifact_exists "${main_key}"; then
        echo "main"
        return 0
    fi

    if [[ "${CI_COMMIT_BRANCH:-}" != "${CI_DEFAULT_BRANCH:-}" ]]; then
        branch_key=$(toolchain_artifact_key "${host_arch}" "${target_arch}" "${hash}" branches)
        if s3_artifact_exists "${branch_key}"; then
            echo "branches"
            return 0
        fi
    fi

    return 1
}
