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

### Container exec and Bits Code

`DD_DEV_ENV_TRANSPORT=exec` selects container-exec startup: the launcher supplies
init and a foreground command, and startup skips SSH/password setup, SSH environment
persistence, editor watchers and imported shell histories. Default SSH startup is
unchanged. This transport selection alone does not change trust or credentials.

The separate, explicit `DD_BITS_CODE=1` hint selects Bits Code initialization. It
grants no authorization. Bits Code skips local pass/GPG/aws-vault bootstrap and
disables container-local DDA telemetry. Fully silent initialization also requires
a DDA release that skips telemetry discovery when `DD_BITS_CODE=1`; the pinned
test image carries DDA 0.39.1 and may emit a telemetry warning during disable. SCM and cloud authorization remain with
the caller's broker; no host credentials, sockets, capabilities or listeners are
added by this mode.

Before startup, the caller must mount these public files read-only under
`/run/codegen-trust`:

- `ca-certificates.crt`: PEM CA bundle for standard TLS clients.
- `sandbox-proxy-ca.crt`: PEM proxy CA installed into system trust as root.
- `java-cacerts`: Java truststore for the Bazel JVM.

Missing, empty, unreadable or writable trust files, and malformed PEM certificates,
stop startup with a clear error, including on restart. Java validates the Java
truststore format when Bazel starts. TLS verification remains enabled. The image persists
`SSL_CERT_FILE`, `REQUESTS_CA_BUNDLE`, `CURL_CA_BUNDLE` and `GIT_SSL_CAINFO` through
its normal shell configuration mechanism. It appends an idempotent Bazel startup
JVM truststore option to `/etc/bazel.bazelrc`, preserving existing system settings
and leaving repository files untouched. Launchers should also pass the standard
CA variables for direct non-shell exec commands, which do not read shell profiles.

Run `bash dev-envs/linux/tests/test-exec-transport.sh` against the published image
without rebuilding. It covers root and regular UID startup, file ownership,
system and shell trust, service/credential-bootstrap absence, restart, and
negative trust-file cases. Override `AGENT_DEV_TEST_IMAGE` when needed.

For Docker VMs, set `AGENT_DEV_TEST_TMPDIR` to a host directory shared with the VM.
