# Datadog Agent builders

![Docker Image Version](https://img.shields.io/docker/v/datadog/agent-buildimages-deb_x64)
![GitHub License](https://img.shields.io/github/license/datadog/datadog-agent-buildimages)

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

## If you're modifying both datadog-agent and buildimages repositories

If your changes affect both [datadog-agent][agent] and buildimages, you have two option :

### If you need multiple test commits in agent-buildimages
In your datadog-agent-buildimages's PR:
  - Add `branch: your/datadog-agent-branch` in your [.gitlab-ci.yml](https://github.com/DataDog/datadog-agent-buildimages/blob/fcc4843103d3bfdb976da845133ad3edc48754b2/.gitlab-ci.yml#L261-L263) file.
  - Commit and wait for the `dd-gitlab/wait_for_tests` job to appear in the CI, it will indicate if your tests succeeded or failed. Once your tests worked you can move on to the next step.
  - Remove `branch: your/datadog-agent-branch` in your [.gitlab-ci.yml](https://github.com/DataDog/datadog-agent-buildimages/blob/fcc4843103d3bfdb976da845133ad3edc48754b2/.gitlab-ci.yml#L261-L263) file.
  - Commit and don't wait for the `dd-gitlab/wait_for_tests` job to appear in the CI. If your pipeline is green it's good to merge (if you wait for too long the `dd-gitlab/wait_for_tests` job will appear failing your PR but this jobs isn't required)
### If the required changes are on datadog-agent

  - Create your branch in buildimages.
  - In your [datadog-agent][agent]'s PR:
    - Edit `DATADOG_AGENT_BUILDIMAGES` [with your current pipeline_id and commit](https://github.com/DataDog/datadog-agent/blob/69b46c9b8103d12364c8eb01e23a83e4c9efcf21/.gitlab-ci.yml/#L161-L162) (`v${pipeline_id}-${commit}`).
    - Set `DATADOG_AGENT_BUILDIMAGES_SUFFIX` to `_test_only`
    - Once [datadog-agent][agent]'s PR is green, merge buildimages' PR
    - Set `DATADOG_AGENT_BUILDIMAGES` to [main's current pipeline_id and commit](https://github.com/DataDog/datadog-agent/blob/69b46c9b8103d12364c8eb01e23a83e4c9efcf21/.gitlab-ci.yml/#L161-L162) (`v${pipeline_id}-${commit}`)
    - Set `DATADOG_AGENT_BUILDIMAGES_SUFFIX` back to `""`.
    - Once [datadog-agent][agent]'s PR is green, merge.

[agent]: https://github.com/DataDog/datadog-agent
[agent-omnibus]: https://github.com/DataDog/datadog-agent/blob/master/docs/dev/agent_omnibus.md

## Upgrading Golang version

Refer to [this section](#If-you-need-multiple-test-commits-in-agent-buildimages) to test your PR.

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

You can use datadog-agent's invoke task to do so:
```sh
inv -e pipeline.update-buildimages -i <new image ID> --branch-name <your working branch> [--no-test-version]
```
`--no-test-version` will prevent the task from appending the `test_only` suffix to your image tag.

## Building on Windows
See Building on Windows [README.md](windows/README.md)
