# Datadog Agent builders

This repo contains the Dockerfiles of the images used to build the rpm and deb
packages for the Datadog [Agent][agent].

## How to use

You can follow [these instructions][agent-omnibus] to build a package locally:
please notice rpm packages are signed, so you won't be able to exactly reproduce
the same artifact that's distributed through the official Yum repository.

If you're a Datadog employee building new images used in the Datadog Agent
pipeline, you will have to replace the `DATADOG_AGENT_BUILDIMAGES` variable
in the [.gitlab-ci.yml](https://github.com/DataDog/datadog-agent/blob/master/.gitlab-ci.yml)
of the [datadog-agent repository][agent] to use the newly created images.

[agent]: https://github.com/DataDog/datadog-agent
[agent-omnibus]: https://github.com/DataDog/datadog-agent/blob/master/docs/dev/agent_omnibus.md

## Upgrading Golang version

Upgrade all `GIMME_GO_VERSION` in the Dockerfiles like in
[this](https://github.com/DataDog/datadog-agent-buildimages/commit/812e0f81340d30bdcbf930399561f1209bb0e166) commit.

Also upgrade the `GO_VERSION` in the Dockerfiles that build Go from source and in `windows/Dockerfile`.

Once pushed, Gitlab will build and push the containers to aws for you. Look for
the pipeline and get the new images ID (in each job log). The
new images ID should resemble something like
`datadog-agent-buildimages/rpm_x64:v1581559-c7ff053`

Update the `.gitlab-ci.yml` file in the `datadog-agent` repo to use the new images,
push a new PR and see if gitlab is still green.

## Building on Windows
See Building on Windows [README.md](windows/README.md)
