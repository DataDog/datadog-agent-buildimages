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

## If your changes requires a mirror PR

Current tests are running a [datadog-agent pipeline][agent] without kitchen 
tests to confirm if your newly builded images are working. If your changes requires
a mirror PR on the [datadog-agent repository][agent], you have two option :
### If you need multiple test commits in agent-buildimages
  - Add `branch: your/datadog-agent-branch` in your [.gitlab-ci.yml](https://github.com/DataDog/datadog-agent-buildimages/blob/fcc4843103d3bfdb976da845133ad3edc48754b2/.gitlab-ci.yml#L261-L263)
  - Commit and waits for the `dd-gitlab/wait_for_tests` jobs to appear in the CI, it will indicate if your tests succeeded or failed.
    Once your tests worked you can move to the next step.
  - Remove `branch: your/datadog-agent-branch` in your [.gitlab-ci.yml](https://github.com/DataDog/datadog-agent-buildimages/blob/fcc4843103d3bfdb976da845133ad3edc48754b2/.gitlab-ci.yml#L261-L263)
    - Commit and don't waits for the `dd-gitlab/wait_for_tests` job to appear in the CI. 
      If your pipeline is green it's good to merge (if you wait too long the `dd-gitlab/wait_for_tests` job will appear failling your PR but this jobs isn't required)
### Or if the required changes are on datadog-agent
  - Create your branch normally on datadog-agent-buildimages
  - On your [datadog-agent][agent] PR, edit `DATADOG_AGENT_BUILDIMAGES` with your current commit and pipelind id and the `SUFFIX` in `_test_only`
  - Make your changes until datadog-agent CI is green
  - Merge agent-buildimages PR, set `DATADOG_AGENT_BUILDIMAGES` with main commit and pipeline id and revert `SUFFIX` to `""`.
    If your pipeline is green it's good to merge

[agent]: https://github.com/DataDog/datadog-agent
[agent-omnibus]: https://github.com/DataDog/datadog-agent/blob/master/docs/dev/agent_omnibus.md

## Upgrading Golang version

Refer to [#If-your-changes-requires-a-mirror-PR](#If-your-changes-requires-a-mirror-PR) to test your PR.

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
