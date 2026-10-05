#!/usr/bin/env bash
# Validate the managed transport against the published image with mounted patches.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
init_dir=$(cd -- "$script_dir/../init" && pwd)
image=${AGENT_DEV_TEST_IMAGE:-docker.io/datadog/agent-dev-env-linux@sha256:45d652ed3e7e5fcf71f9a432b8a73042ed7afcd4c8f8481b32c97ad502e9cb42}
work_dir=$(mktemp -d)
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
for host_uid in 0 12345; do
    case_dir="$work_dir/uid-$host_uid"
    mkdir -p "$case_dir/repo"
    chown "$host_uid:$host_uid" "$case_dir/repo"
    container="entrypoint-exec-$host_uid-$$"
    docker run -d --init --name "$container" --entrypoint /bin/bash \
        -e HOST_UID="$host_uid" -e HOST_GID="$host_uid" -e DD_SHELL=bash \
        -e DD_DEV_ENV_TRANSPORT=exec \
        --mount "type=bind,src=$init_dir/entrypoint.sh,dst=/init/entrypoint.sh,readonly" \
        --mount "type=bind,src=$init_dir/startup.sh,dst=/init/startup.sh,readonly" \
        --mount "type=bind,src=$case_dir/repo,dst=/repos/entrypoint-test" \
        "$image" -lc '. /home/dd/.profile; exec /init/entrypoint.sh /bin/sleep infinity'
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
    [[ $(stat -c %u "$case_dir/repo/result") == "$host_uid" ]]
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
