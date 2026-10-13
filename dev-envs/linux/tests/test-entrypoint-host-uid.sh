#!/usr/bin/env bash
# Run the real image startup with a mounted entrypoint; no image rebuild needed.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
entrypoint=$(cd -- "$script_dir/../init" && pwd)/entrypoint.sh
image=${AGENT_DEV_TEST_IMAGE:-docker.io/datadog/agent-dev-env-linux@sha256:45d652ed3e7e5fcf71f9a432b8a73042ed7afcd4c8f8481b32c97ad502e9cb42}
work_dir=$(mktemp -d)
container=
ssh_port=${AGENT_DEV_TEST_SSH_PORT:-18190}
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
    # Ownership must match the host caller so startup does not hide write failures.
    chown "$host_uid:$host_uid" "$case_dir/repo"
    container="entrypoint-uid-$host_uid-$$"
    docker run -d --init --name "$container" -p "127.0.0.1:$ssh_port:22" \
        -e HOST_UID="$host_uid" -e HOST_GID="$host_uid" -e DD_SHELL=bash \
        --mount "type=bind,src=$entrypoint,dst=/init/entrypoint.sh,readonly" \
        --mount "type=bind,src=$script_dir/../init/startup.sh,dst=/init/startup.sh,readonly" \
        --mount "type=bind,src=$case_dir/repo,dst=/repos/entrypoint-test" \
        "$image"
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
    [[ $(docker exec "$container" id -g dd) == "$host_uid" ]]
    [[ $(docker exec "$container" id -u root) == 0 ]]
    [[ $(docker exec "$container" getent passwd dd | cut -d: -f6) == /home/dd ]]
    docker exec --user dd "$container" bash -lc \
        'set -euo pipefail; printf "written by target user\n" > /repos/entrypoint-test/result; dda --version'
    [[ $(stat -c %u "$case_dir/repo/result") == "$host_uid" ]]
    [[ $(stat -c %g "$case_dir/repo/result") == "$host_uid" ]]
    if [[ ${AGENT_DEV_TEST_SSH:-0} == 1 ]]; then
        ssh_ready=0
        for ((attempt=0; attempt<30; attempt++)); do
            if ssh -p "$ssh_port" -o ConnectTimeout=2 -o BatchMode=yes \
                -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                dd@127.0.0.1 "test \"\$(id -u)\" = $host_uid && test \"\$(id -g)\" = $host_uid && dda --version" \
                > "$case_dir/ssh.log" 2>&1; then
                ssh_ready=1
                break
            fi
            sleep 1
        done
        [[ $ssh_ready == 1 ]] || { cat "$case_dir/ssh.log"; exit 1; }
        echo "PASS host UID/GID $host_uid: SSH login"
    fi
    docker restart "$container" >/dev/null
    docker exec --user dd "$container" bash -lc \
        'set -euo pipefail; test -f /.started; test -s /repos/entrypoint-test/result; dda --version'
    docker logs "$container" > "$case_dir/startup.log" 2>&1
    docker rm -fv "$container" >/dev/null
    container=
    ssh_port=$((ssh_port + 1))
    echo "PASS host UID/GID $host_uid: startup, dd identity/home, mounted writes, DDA, restart"
done
