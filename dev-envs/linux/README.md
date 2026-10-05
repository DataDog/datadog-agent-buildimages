# Agent dev env - Linux

-----

This directory contains the Linux environment used by all Agent developers and is based on the Debian build images themselves.

Consumers of this image may need to know about certain predefined paths and environment variables which are defined in the [env-vars.sh](env-vars.sh) file.


## Host UID 0

The entrypoint maps the target user to the caller's UID/GID. When `HOST_UID=0`,
it permits that user to share UID 0 with root, preserving the login name and home
that DDA expects (`dd` and `/home/dd` in the standard image). Non-root callers
retain the existing mapping and duplicate-UID checks. A root caller's development
session therefore has root privileges inside the container.

Test a modified entrypoint without rebuilding the image by mounting it read-only:

```bash
dda env dev start --type linux-container --id root-entrypoint-test --no-secrets \
  --mount "type=bind,src=$(pwd)/dev-envs/linux/init/entrypoint.sh,dst=/init/entrypoint.sh,readonly"
```

Use a new environment ID so startup runs in a fresh container. The mounted file
must be executable. For the managed sandbox, run this command where the source
file exists in that sandbox and set `DOCKER_HOST` to its managed API socket.

The real-image regression runs both UID/GID 0 and 12345, checking startup, target
identity/home, bind-mounted file ownership, DDA availability, and restart:

```bash
bash dev-envs/linux/tests/test-entrypoint-host-uid.sh
```

Run it from a Linux Docker/Podman host with permission to prepare test-directory
ownership and a working server-side init binary. `AGENT_DEV_TEST_IMAGE` can select
a different image; the default is the official image used to reproduce the bug.
Set `AGENT_DEV_TEST_SSH=1` to require SSH login for both UIDs as well. The test uses
loopback SSH ports 18190 and 18191, overridable with `AGENT_DEV_TEST_SSH_PORT`.

On 2026-10-05, the mounted entrypoint passed both UID regressions in hotdog
`vysmal-container-dev-takeover`. Literal DDA start also returned 0 and retained a
running container. DDA shell exited 255 because OpenSSH could not
`chroot("/var/empty")` (`Operation not permitted`); full SSH workflow validation
is separate from the passing entrypoint and ownership checks. The unchanged image
with UID/GID 12345 failed SSH at the same chroot operation, confirming that this
restriction also exists without the root-caller patch. No image rebuild
or publication was required for these tests.

### Managed container exec

The opt-in `DD_DEV_ENV_TRANSPORT=exec` startup mode supports DDA's container-exec
transport. Its launcher supplies native init and a foreground `sleep infinity`
command instead of SSH. UID/GID alignment, `/home/dd`, toolchains, and persisted
build directories remain available. Startup skips passwordless SSH setup,
SSH environment persistence, editor watchers, imported shell/agent histories,
and the local pass/GPG/aws-vault credential bootstrap. It adds no capabilities. Exec startup refreshes system certificate trust so
caller-mounted public CA certificates under `/usr/local/share/ca-certificates`
also work for tools that sanitize their subprocess environment. TLS verification
remains enabled. Exec mode disables container-local DDA telemetry; Bits session
telemetry is unaffected.
The mode marker selects startup behavior; it does not authorize SCM or cloud access.

Mount the patched entrypoint and startup script to test against the published
image without rebuilding:

```bash
bash dev-envs/linux/tests/test-exec-transport.sh
```

The test covers root and regular UID callers, real DDA startup, mounted file
ownership, service/credential-bootstrap absence, and stop/start persistence.
SCM operations should use the caller's broker outside this container. The DDA
exec launcher intentionally omits socket/credential forwarding and SSH ports.
