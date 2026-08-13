#!/usr/bin/env python3
# Adds a golang image entry to mirror.yaml and mirror.lock.yaml in DataDog/images.
# Usage: GO_VERSION=1.26.6 DIGEST=sha256:... python3 update_mirror.py

import os
import re
import sys


def main():
    version = os.environ["GO_VERSION"]
    digest = os.environ["DIGEST"]

    _update_mirror_yaml(version, digest)
    _update_mirror_lock_yaml(version, digest)

    print(f"Updated mirror.yaml and mirror.lock.yaml for golang:{version}")


def _update_mirror_yaml(version: str, digest: str) -> None:
    new_entry = (
        f'  - source: "docker.io/library/golang:{version}@{digest}"\n'
        f'    dest:\n'
        f'      repo: "library/golang"\n'
        f'      tag: "{version}"\n'
        f'    replication_target: "build"\n'
    )

    with open("mirror.yaml") as f:
        content = f.read()

    pattern = (
        r'  - source: "docker\.io/library/golang:\d+\.\d+\.\d+@sha256:[a-f0-9]+"\n'
        r'    dest:\n      repo: "library/golang"\n'
        r'      tag: "\d+\.\d+\.\d+"\n    replication_target: "build"\n'
    )
    last = None
    for m in re.finditer(pattern, content):
        last = m
    if last is None:
        sys.exit("Could not find golang block in mirror.yaml")

    content = content[: last.end()] + new_entry + content[last.end() :]
    with open("mirror.yaml", "w") as f:
        f.write(content)


def _update_mirror_lock_yaml(version: str, digest: str) -> None:
    new_entry = (
        f"    - source: docker.io/library/golang:{version}@{digest}\n"
        f"      digest: {digest}\n"
    )

    with open("mirror.lock.yaml") as f:
        content = f.read()

    pattern = (
        r"    # renovate\n"
        r"    - source: docker\.io/library/golang:alpine\n"
        r"      digest: sha256:[a-f0-9]+\n"
    )
    m = re.search(pattern, content)
    if m is None:
        sys.exit("Could not find insertion point in mirror.lock.yaml")

    content = content[: m.end()] + new_entry + content[m.end() :]
    with open("mirror.lock.yaml", "w") as f:
        f.write(content)


if __name__ == "__main__":
    main()
