# Datadog Agent builders

This repo contains the Dockerfiles of the images used to build the rpm and deb
packages for the Datadog [Agent][agent].

Test

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
### Invoke task
The `update-go` invoke task updates all Go versions and SHA256 of the repository.

For example:
```sh
inv update-go -v 1.20.8
```
You can use the `--check-archive` argument to have the task download the archives and check that
their SHA256 are the expected ones.

Note that the task does all changes locally and doesn't create a branch or a PR.

### Manual process
Upgrade all `GO_VERSION` and hashes in the Dockerfiles like in
[this](https://github.com/DataDog/datadog-agent-buildimages/commit/4fdacd48725fdbab84d8fc0e27f9fc23ac5e7d9a) commit.

Also upgrade `windows/helpers/phase2/install_docker.ps1`.

Once pushed, Gitlab will build and push the containers to aws for you. Look for
the pipeline and get the new images ID (in each job log). The
new images ID should resemble something like
`datadog-agent-buildimages/rpm_x64:v1581559-c7ff053`

Update the `.gitlab-ci.yml` file in the `datadog-agent` repo to use the new images,
push a new PR and see if gitlab is still green.

## Building on Windows
See Building on Windows [README.md](windows/README.md)
