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
docker pull registry.ddbuild.io/ci/datadog-agent-devenv:1-<platform>
```


Option 2: Build the image locally

From the repository root, set the DDA and Golang version:

```
source dda.env && source go.env
```

build the docker image

```
docker buildx build --platform linux/amd64,linux/arm64 --build-arg="GO_VERSION=${GO_VERSION}" --build-arg="DDA_VERSION=${DDA_VERSION}" -t registry.ddbuild.io/ci/datadog-agent-devenv:1 -f devcontainer/Dockerfile .
```

The Go version currently in use in the default image can be found [here](https://github.com/DataDog/datadog-agent-buildimages/blob/main/go.env).
