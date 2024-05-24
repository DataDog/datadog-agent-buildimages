You can override values with a `docker-compose.override.yaml`. For instance to mount another folder in the devenv

```
version: "3.7"
services:
  agent-devenv:
    volumes:
      - ${HOME}/Documents/Dev:/home/datadog/dev
```

To start the devenv:

```
# For ARM64:
docker compose up -d

# For AMD64:
docker compose -f docker-compose.amd64.yaml up -d
```

You may need to pull the image manually or build it locally before starting:

Option 1: Pull the image from the CI registry (AMD64/ARM64)

```
aws-vault exec sso-build-stable-developer -- docker pull 486234852809.dkr.ecr.us-east-1.amazonaws.com/ci/datadog-agent-devenv:1-<platform>
```

If it does not work, make sure you have proper credentials helpers set in Docker:
```
cat ~/.docker/config.json
{
  "credHelpers": {
    "486234852809.dkr.ecr.us-east-1.amazonaws.com": "ecr-login"
  }
}
```

Option 2: Build the image locally

```
DOCKER_BUILDKIT=1 docker build -t 486234852809.dkr.ecr.us-east-1.amazonaws.com/ci/datadog-agent-devenv:1 .
```
