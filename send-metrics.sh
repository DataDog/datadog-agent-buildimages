#!/bin/bash

# Metrics Origin details:
# https://github.com/DataDog/dd-source/blob/a060ce7a403c2215c44ebfbcc588e42cd9985aeb/domains/metrics/shared/libs/proto/origin/origin.proto#L144

if [ "$#" -ne 3 ]; then
    echo "usage: $0 <image> <size> <branch>"
    exit 1
fi

IMAGE=$1
SIZE=$2
BRANCH=$3

set -e
set +x

# Build the metric payload first; no credentials are needed for this part.
NOW="$(date '+%s')"
export PAYLOAD=$(cat <<EOF
{
  "series": [
    {
      "metadata": {
        "origin": {
          "origin_product": 17,
          "origin_sub_product": 0,
          "origin_product_detail": 0
        }
      },
      "metric": "datadog.buildimages.size",
      "points": [
        {
          "timestamp": ${NOW},
          "value": ${SIZE}
        }
      ],
      "tags": [
        "image:${IMAGE}",
        "branch:${BRANCH}"
      ]
    }
  ]
}
EOF
)

# Mint a short-lived Datadog API key via dd-sts (exchanging the job's OIDC ID
# token, aud: dd-sts, declared in .gitlab/build.yml) and POST the metric with
# the key injected as DD_API_KEY in the wrapped command's environment.
# See the dd-sts user guide:
# https://datadoghq.atlassian.net/wiki/spaces/SECENG/pages/5769659435/User+guide+dd-sts
command -v dd-sts >/dev/null 2>&1 || {
    echo "dd-sts CLI not found; it is installed by the CI job (see .gitlab/build.yml)" >&2
    exit 1
}
dd-sts exchange --policy datadog-agent-buildimages-metrics.yml -- bash -c '
    curl -X POST "https://api.datadoghq.com/api/v2/series" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DD_API_KEY}" \
        --silent -S \
        -d "${PAYLOAD}"
'
