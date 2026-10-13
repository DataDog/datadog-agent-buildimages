#!/usr/bin/env bash
# Validate the managed transport against the published image with mounted patches.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
init_dir=$(cd -- "$script_dir/../init" && pwd)
image=${AGENT_DEV_TEST_IMAGE:-docker.io/datadog/agent-dev-env-linux@sha256:45d652ed3e7e5fcf71f9a432b8a73042ed7afcd4c8f8481b32c97ad502e9cb42}
work_dir=$(mktemp -d "${AGENT_DEV_TEST_TMPDIR:-${TMPDIR:-/tmp}}/agent-dev-test.XXXXXX")
container=
cleanup() {
    result=$?
    if [[ -n $container ]]; then
        docker logs "$container" > "$work_dir/container.log" 2>&1 || true
        docker rm -fv "$container" >/dev/null || result=1
    fi
    echo "Evidence: $work_dir"
    exit "$result"
}
trap cleanup EXIT
mkdir -p "$work_dir/trust"
# Public artifacts from OpenSSL and Bazel’s embedded JDK, with no host credentials.
docker run --rm --entrypoint bash --mount "type=bind,src=$work_dir/trust,dst=/trust" "$image" -lc '
    openssl req -x509 -newkey rsa:2048 -nodes -keyout /tmp/test.key -out /trust/sandbox-proxy-ca.crt -days 1 -subj /CN=bits-test
    cat /etc/ssl/certs/ca-certificates.crt /trust/sandbox-proxy-ca.crt > /trust/ca-certificates.crt
    USE_BAZEL_VERSION=9.3.0 bazel --batch version
    cacerts=$(find /var/cache /root/.cache /home/dd/.cache -path "*/lib/security/cacerts" -print -quit 2>/dev/null || true)
    test -n "$cacerts"
    cp "$cacerts" /trust/java-cacerts
'
for host_uid in 0 12345; do
    case_dir="$work_dir/uid-$host_uid"
    mkdir -p "$case_dir/repo"
    docker run --rm --entrypoint chown --mount "type=bind,src=$case_dir/repo,dst=/test" "$image" "$host_uid:$host_uid" /test
    container="entrypoint-exec-$host_uid-$$"
    docker run -d --init --name "$container" --entrypoint /bin/bash \
        -e HOST_UID="$host_uid" -e HOST_GID="$host_uid" -e DD_SHELL=bash \
        -e DD_DEV_ENV_TRANSPORT=exec -e DD_BITS_CODE=1 \
        --mount "type=bind,src=$init_dir/entrypoint.sh,dst=/init/entrypoint.sh,readonly" \
        --mount "type=bind,src=$init_dir/startup.sh,dst=/init/startup.sh,readonly" \
        --mount "type=bind,src=$init_dir/bits-code-trust.sh,dst=/init/bits-code-trust.sh,readonly" \
        --mount "type=bind,src=$work_dir/trust,dst=/run/codegen-trust,readonly" \
        --mount "type=bind,src=$case_dir/repo,dst=/repos/entrypoint-test" \
        "$image" -lc '. /home/dd/.profile; grep -Fxq "# preserve test config" /etc/bazel.bazelrc 2>/dev/null || echo "# preserve test config" >> /etc/bazel.bazelrc; exec /init/entrypoint.sh /bin/sleep infinity'
    ready=0
    for ((attempt=0; attempt<180; attempt++)); do
        if docker exec "$container" test -f /.started; then
            ready=1
            break
        fi
        [[ $(docker inspect --format '{{.State.Running}}' "$container") == true ]] || break
        sleep 1
    done
    [[ $ready == 1 ]] || { docker logs "$container"; exit 1; }
    [[ $(docker exec "$container" id -u dd) == "$host_uid" ]]
    [[ $(docker exec "$container" getent passwd dd | cut -d: -f6) == /home/dd ]]
    docker exec --user dd --env HOME=/home/dd "$container" bash -lc \
        'test ! -S /var/run/docker.sock; test ! -d /var/config/dd/.config/password-store; test ! -e /home/dd/.vscode-server; printf "exec write\n" > /repos/entrypoint-test/result; dda --version'
    [[ $(docker exec "$container" stat -c %u /repos/entrypoint-test/result) == "$host_uid" ]]
    docker exec --user dd --env HOME=/home/dd "$container" bash -lc '
        test "$SSL_CERT_FILE" = /run/codegen-trust/ca-certificates.crt
        test "$REQUESTS_CA_BUNDLE" = "$SSL_CERT_FILE"
        test "$CURL_CA_BUNDLE" = "$SSL_CERT_FILE"
        test "$GIT_SSL_CAINFO" = "$SSL_CERT_FILE"
        openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt /run/codegen-trust/sandbox-proxy-ca.crt
        grep -Fx "# preserve test config" /etc/bazel.bazelrc
        grep -Fx "startup --host_jvm_args=-Djavax.net.ssl.trustStore=/run/codegen-trust/java-cacerts" /etc/bazel.bazelrc
    '
    processes=$(docker exec "$container" ps -eo args)
    if grep -E '[s]shd|[r]un-services.sh|[s]can-editor-servers.sh' <<< "$processes"; then
        echo "Unexpected host integration service in exec transport" >&2
        exit 1
    fi
    docker stop "$container" >/dev/null
    docker start "$container" >/dev/null
    docker exec --user dd "$container" bash -lc 'test -f /.started; test -s /repos/entrypoint-test/result; dda --version'
    docker logs "$container" > "$case_dir/startup.log" 2>&1
    docker rm -fv "$container" >/dev/null
    container=
    echo "PASS exec UID/GID $host_uid: startup, writes, DDA, no SSH/editor/credential bootstrap, restart"
done

# Fail closed on missing, invalid, or writable trust before startup succeeds.
for failure in missing-ca-certificates.crt missing-sandbox-proxy-ca.crt missing-java-cacerts writable invalid-ca-certificates.crt invalid-sandbox-proxy-ca.crt; do
    options=readonly
    fixture="$work_dir/trust"
    if [[ $failure == missing-* || $failure == invalid-* ]]; then
        fixture="$work_dir/$failure"; mkdir -p "$fixture"; cp "$work_dir/trust/"* "$fixture/"
        if [[ $failure == missing-* ]]; then
            rm "$fixture/${failure#missing-}"
        else
            printf 'invalid certificate\n' > "$fixture/${failure#invalid-}"
        fi
    else
        options=readonly=false
    fi
    if docker run --rm --entrypoint /bin/bash \
        --mount "type=bind,src=$init_dir/bits-code-trust.sh,dst=/init/bits-code-trust.sh,readonly" \
        --mount "type=bind,src=$fixture,dst=/run/codegen-trust,$options" \
        "$image" /init/bits-code-trust.sh > "$work_dir/$failure.log" 2>&1; then
        echo "Unexpected success: $failure trust" >&2; exit 1
    fi
    grep 'Bits Code trust:' "$work_dir/$failure.log"
done
