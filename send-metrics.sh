#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "usage: $0 <image> <size> <branch>"
    exit 1
fi

IMAGE=$1
SIZE=$2
BRANCH=$3

set -e
set +x

API_KEY=$(aws ssm get-parameter --region us-east-1 --name ci.datadog-agent.datadog_api_key_org2 --with-decryption  --query Parameter.Value --out text)

curl -X POST "https://api.datadoghq.com/api/v2/series" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "DD-API-KEY: ${API_KEY}" \
    --silent -S \
    -d @- << EOF
{
    "series":
    [
        {
            "metric": "datadog.buildimages.size",
            "points": [{"timestamp": $(date '+%s'), "value": ${SIZE} }],
            "tags": ["image:${IMAGE}", "branch:${BRANCH}"]
        }
    ]
}
EOF
