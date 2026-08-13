#!/usr/bin/env python3
# Adds a golang image entry to mirror.yaml and mirror.lock.yaml in DataDog/images.
# Usage: GO_VERSION=1.26.6 DIGEST=sha256:... python3 update_mirror.py

import os
import re
import sys


def main():
    version = os.environ["GO_VERSION"].strip()
    digest = os.environ["DIGEST"].strip()

    _update_mirror_yaml(version, digest)
    _update_mirror_lock_yaml(version, digest)

    print(f"Updated mirror.yaml and mirror.lock.yaml for golang:{version}")


def _parse_version(version_str: str) -> tuple:
    return tuple(int(x) for x in version_str.split("."))


def _update_mirror_yaml(version: str, digest: str) -> None:
    new_entry = (
        f'  - source: "docker.io/library/golang:{version}@{digest}"\n'
        '    dest:\n'
        '      repo: "library/golang"\n'
        f'      tag: "{version}"\n'
        '    replication_target: "build"\n'
    )

    with open("mirror.yaml") as f:
        content = f.read()

    # mirror.yaml entries are in ascending version order
    pattern = (
        r'  - source: "docker\.io/library/golang:(\d+\.\d+\.\d+)@sha256:[a-f0-9]+"\n'
        r'    dest:\n      repo: "library/golang"\n'
        r'      tag: "\d+\.\d+\.\d+"\n    replication_target: "build"\n'
    )

    matches = list(re.finditer(pattern, content))
    if not matches:
        sys.exit("Could not find any golang entries in mirror.yaml")

    new_ver = _parse_version(version)

    # Insert after the last entry with version < new_ver
    insert_after = None
    for m in matches:
        if _parse_version(m.group(1)) < new_ver:
            insert_after = m

    insert_pos = insert_after.end() if insert_after else matches[0].start()
    content = content[:insert_pos] + new_entry + content[insert_pos:]

    with open("mirror.yaml", "w") as f:
        f.write(content)


def _update_mirror_lock_yaml(version: str, digest: str) -> None:
    new_entry = (
        f"    - source: docker.io/library/golang:{version}@{digest}\n"
        f"      digest: {digest}\n"
    )

    with open("mirror.lock.yaml") as f:
        content = f.read()

    # mirror.lock.yaml entries are in descending version order (newest first)
    pattern = (
        r"    - source: docker\.io/library/golang:(\d+\.\d+\.\d+)@sha256:[a-f0-9]+\n"
        r"      digest: sha256:[a-f0-9]+\n"
    )

    matches = list(re.finditer(pattern, content))
    if not matches:
        sys.exit("Could not find any golang versioned entries in mirror.lock.yaml")

    new_ver = _parse_version(version)

    # Insert before the first entry with version < new_ver
    for m in matches:
        if _parse_version(m.group(1)) < new_ver:
            insert_pos = m.start()
            break
    else:
        # new_ver is older than all existing entries, append after the last one
        insert_pos = m.end()

    content = content[:insert_pos] + new_entry + content[insert_pos:]

    with open("mirror.lock.yaml", "w") as f:
        f.write(content)


if __name__ == "__main__":
    main()
