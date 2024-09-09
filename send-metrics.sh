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

API_KEY=$(aws ssm get-parameter --region us-east-1 --name ci.datadog-agent.datadog_api_key_org2 --with-decryption  --query Parameter.Value --out text)
NOW="$(date '+%s')"
curl -X POST "https://api.datadoghq.com/api/v2/series" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "DD-API-KEY: ${API_KEY}" \
    --silent -S \
    -d @- << EOF
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
