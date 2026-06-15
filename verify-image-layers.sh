#!/bin/bash
#
# Verify that an image contains only standard tar-based filesystem layers.
#
# A foreign accelerator layer (e.g. a Nydus blob from a COPY --from source or a poisoned
# BuildKit cache) breaks `docker pull` with "failed to register layer: invalid input:
# magic number mismatch". This guard fails the build before such an image is promoted.
#
# Usage: ./verify-image-layers.sh <image-ref>
set -euo pipefail

readonly IMAGE="${1:?usage: verify-image-layers.sh <image-ref>}"

# Every legitimate filesystem-layer media type contains "tar"; accelerator and
# attestation blobs (Nydus, SOCI, in-toto) do not.
layer_media_types() {
    local manifest
    manifest="$(crane manifest "$IMAGE")"

    if jq -e 'has("manifests")' <<<"$manifest" >/dev/null; then
        # For a multi-arch index, descend into each real platform, skipping unknown/unknown
        # attestation manifests.
        jq -r '.manifests[] | "\(.platform.os)/\(.platform.architecture)"' <<<"$manifest" \
            | while read -r platform; do
                [[ "$platform" == "unknown/unknown" ]] && continue
                crane manifest --platform "$platform" "$IMAGE" | jq -r '.layers[]?.mediaType'
            done
    else
        jq -r '.layers[]?.mediaType' <<<"$manifest"
    fi
}

types="$(layer_media_types)"
unexpected="$(grep -ivF tar <<<"$types" | sort -u || true)"

if [[ -n "$unexpected" ]]; then
    {
        echo "ERROR: ${IMAGE} contains non-tar (foreign/accelerator) layer media type(s):"
        echo "$unexpected" | sed 's/^/  - /'
        echo
        echo "These break 'docker pull' for standard clients ('magic number mismatch')."
        echo "They usually leak in from a 'COPY --from' source image or a poisoned BuildKit"
        echo "registry cache. Remediate by purging the 'cache-<branch>-<arch>' cache image"
        echo "(or rebuilding with PREVENT_CACHE=1) and rebuilding from a clean source."
    } >&2
    exit 1
fi

echo "OK: all layers in ${IMAGE} are tar-based filesystem layers."
