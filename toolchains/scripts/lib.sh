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
# "arm-linux-gnueabihf" instead. aix isn't crosstool-ng-built, and its triplet
# is versioned after the targeted AIX release.
toolchain_triplet() {
    local target_arch="$1"

    case "${target_arch}" in
        armhf) echo "arm-linux-gnueabihf" ;;
        aix)
            local aix_version
            aix_version=$(. toolchains/aix/aix-version.env; echo "${AIX_VERSION}")
            echo "powerpc-ibm-aix${aix_version}"
            ;;
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

    if [[ "${target_arch}" == "aix" ]]; then
        echo "datadog-agent-buildimages/aix/toolchain/${channel}/${hash}/${host_arch}/${triplet}-gcc.tar.xz"
        return
    fi

    echo "toolchains/${channel}/${hash}/${host_arch}/${triplet}-gcc.tar.xz"
}

resolve_toolchain_hash() {
    local host_arch="$1"
    local target_arch="$2"

    if [[ "${target_arch}" == "aix" ]]; then
        { cat \
            toolchains/aix/build-aix-cross.sh \
            toolchains/aix/aix-patches/*/*.patch \
            toolchains/aix/aix-version.env \
            toolchains/scripts/build-aix-toolchain.sh; \
          echo "${AIX_SYSROOT_URL}"; \
        } | sha256sum | cut -d' ' -f1
        return
    fi

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
    status=$(curl --retry 10 -s -o /dev/null -w "%{http_code}" --head "https://dd-agent-build-artifacts.s3.amazonaws.com/$1")
    [[ "${status}" == "200" ]]
}

mass_artifact_exists() {
    local status
    status=$(curl --retry 10 -s -o /dev/null -w "%{http_code}" --head "https://mass-read.us1.ddbuild.io/internal/artifact/$1")
    [[ "${status}" == "200" ]]
}

artifact_exists() {
    local target_arch="$1"
    local key="$2"

    if [[ "${target_arch}" == "aix" ]]; then
        mass_artifact_exists "${key}"
    else
        s3_artifact_exists "${key}"
    fi
}

# main/ is always trusted, even off the default branch: a PR that doesn't touch the
# recipe should reuse the canonical artifact instead of rebuilding it. branches/ is
# trusted for local builds (never pushed anywhere) and for CI builds on the branch
# that published it, but skipped for CI builds on the default branch, since that's
# the channel that produces the shared, published images.
resolve_toolchain_channel() {
    local host_arch="$1"
    local target_arch="$2"
    local hash="$3"
    local main_key branch_key

    main_key=$(toolchain_artifact_key "${host_arch}" "${target_arch}" "${hash}" main)
    if artifact_exists "${target_arch}" "${main_key}"; then
        echo "main"
        return
    fi

    if [[ "${CI:-}" != "true" ]] || [[ "${CI_COMMIT_BRANCH:-}" != "${CI_DEFAULT_BRANCH:-}" ]]; then
        branch_key=$(toolchain_artifact_key "${host_arch}" "${target_arch}" "${hash}" branches)
        if artifact_exists "${target_arch}" "${branch_key}"; then
            echo "branches"
        fi
    fi
}
