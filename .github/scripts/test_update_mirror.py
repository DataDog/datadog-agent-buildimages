#!/usr/bin/env python3
"""
Tests for update_mirror.py

Run with: python3 -m pytest .github/scripts/test_update_mirror.py -v
"""

import os
import pytest
import tempfile
import textwrap
from pathlib import Path

import update_mirror


FAKE_DIGEST = "sha256:" + "a" * 64


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

# Fixtures use the exact indentation and format from the real files.
# mirror.yaml entries use 2-space indent; mirror.lock.yaml entries use 4-space indent.
# Digests are shortened but valid hex (regex uses [a-f0-9]+, no length requirement).

MIRROR_YAML_TEMPLATE = (
    '  - source: "docker.io/library/golang:1.25.11@sha256:a' + 'a' * 63 + '11"\n'
    '    dest:\n'
    '      repo: "library/golang"\n'
    '      tag: "1.25.11"\n'
    '    replication_target: "build"\n'
    '  - source: "docker.io/library/golang:1.25.12@sha256:a' + 'a' * 63 + '12"\n'
    '    dest:\n'
    '      repo: "library/golang"\n'
    '      tag: "1.25.12"\n'
    '    replication_target: "build"\n'
    '  - source: "docker.io/library/golang:1.26.4@sha256:a' + 'a' * 63 + '64"\n'
    '    dest:\n'
    '      repo: "library/golang"\n'
    '      tag: "1.26.4"\n'
    '    replication_target: "build"\n'
    '  - source: "docker.io/library/golang:1.26.5@sha256:a' + 'a' * 63 + '65"\n'
    '    dest:\n'
    '      repo: "library/golang"\n'
    '      tag: "1.26.5"\n'
    '    replication_target: "build"\n'
    '  - source: "docker.io/library/alpine:3.17.5@sha256:b' + 'b' * 63 + 'al"\n'
    '    dest:\n'
    '      repo: "library/alpine"\n'
    '      tag: "3.17.5"\n'
    '    replication_target: "build"\n'
)

MIRROR_LOCK_YAML_TEMPLATE = (
    '    # renovate\n'
    '    - source: docker.io/library/golang:alpine\n'
    '      digest: sha256:' + 'c' * 64 + '\n'
    '    - source: docker.io/library/golang:1.26.5@sha256:a' + 'a' * 63 + '65\n'
    '      digest: sha256:a' + 'a' * 63 + '65\n'
    '    - source: docker.io/library/golang:1.26.4@sha256:a' + 'a' * 63 + '64\n'
    '      digest: sha256:a' + 'a' * 63 + '64\n'
    '    - source: docker.io/library/golang:1.26\n'
    '      digest: sha256:d' + 'd' * 63 + '\n'
    '    - source: docker.io/library/golang:1.25.12@sha256:a' + 'a' * 63 + '12\n'
    '      digest: sha256:a' + 'a' * 63 + '12\n'
    '    - source: docker.io/library/golang:1.25.11@sha256:a' + 'a' * 63 + '11\n'
    '      digest: sha256:a' + 'a' * 63 + '11\n'
)


@pytest.fixture
def work_dir(tmp_path, monkeypatch):
    """Change to a temp dir with fresh mirror files for each test."""
    (tmp_path / "mirror.yaml").write_text(MIRROR_YAML_TEMPLATE)
    (tmp_path / "mirror.lock.yaml").write_text(MIRROR_LOCK_YAML_TEMPLATE)
    monkeypatch.chdir(tmp_path)
    return tmp_path


def run(version, digest=FAKE_DIGEST):
    os.environ["GO_VERSION"] = version
    os.environ["DIGEST"] = digest
    update_mirror.main()
    yaml = Path("mirror.yaml").read_text()
    lock = Path("mirror.lock.yaml").read_text()
    return yaml, lock


def lines_between(text, before_snippet, after_snippet):
    """Return the lines that appear between two snippets in text."""
    i = text.index(before_snippet)
    j = text.index(after_snippet, i)
    return text[i:j]


# ---------------------------------------------------------------------------
# mirror.yaml tests (ascending version order)
# ---------------------------------------------------------------------------

class TestMirrorYaml:
    def test_patch_update_inserted_after_previous_patch(self, work_dir):
        yaml, _ = run("1.26.6")
        assert 'golang:1.26.6@' in yaml
        # 1.26.6 must appear after 1.26.5 and before alpine
        between = lines_between(yaml, 'golang:1.26.5', 'library/alpine')
        assert 'golang:1.26.6' in between

    def test_new_minor_inserted_after_last_existing_version(self, work_dir):
        yaml, _ = run("1.27.0")
        assert 'golang:1.27.0@' in yaml
        between = lines_between(yaml, 'golang:1.26.5', 'library/alpine')
        assert 'golang:1.27.0' in between

    def test_backport_inserted_after_nearest_lower_version(self, work_dir):
        yaml, _ = run("1.25.13")
        assert 'golang:1.25.13@' in yaml
        # 1.25.13 must appear after 1.25.12 and before 1.26.4
        between = lines_between(yaml, 'golang:1.25.12', 'golang:1.26.4')
        assert 'golang:1.25.13' in between

    def test_version_between_two_existing_inserted_correctly(self, work_dir):
        yaml, _ = run("1.26.3")
        assert 'golang:1.26.3@' in yaml
        # Must appear after 1.25.12 and before 1.26.4
        between = lines_between(yaml, 'golang:1.25.12', 'golang:1.26.4')
        assert 'golang:1.26.3' in between

    def test_exact_format_matches_reference(self, work_dir):
        yaml, _ = run("1.26.6")
        expected = (
            f'  - source: "docker.io/library/golang:1.26.6@{FAKE_DIGEST}"\n'
            f'    dest:\n'
            f'      repo: "library/golang"\n'
            f'      tag: "1.26.6"\n'
            f'    replication_target: "build"\n'
        )
        assert expected in yaml

    def test_only_one_entry_added(self, work_dir):
        yaml, _ = run("1.26.6")
        assert yaml.count('golang:1.26.6@') == 1

    def test_existing_entries_unchanged(self, work_dir):
        yaml, _ = run("1.26.6")
        for snippet in ["1.25.11@sha256:", "1.25.12@sha256:", "1.26.4@sha256:", "1.26.5@sha256:"]:
            assert f'golang:{snippet}' in yaml

    def test_alpine_entry_unchanged(self, work_dir):
        yaml, _ = run("1.26.6")
        assert 'library/alpine:3.17.5@sha256:' in yaml


# ---------------------------------------------------------------------------
# mirror.lock.yaml tests (descending version order, newest first)
# ---------------------------------------------------------------------------

class TestMirrorLockYaml:
    def test_patch_update_inserted_before_previous_patch(self, work_dir):
        _, lock = run("1.26.6")
        assert 'golang:1.26.6@' in lock
        # 1.26.6 must appear before 1.26.5 (descending order)
        between = lines_between(lock, 'golang:alpine', 'golang:1.26.5')
        assert 'golang:1.26.6' in between

    def test_new_minor_inserted_before_existing_latest(self, work_dir):
        _, lock = run("1.27.0")
        assert 'golang:1.27.0@' in lock
        between = lines_between(lock, 'golang:alpine', 'golang:1.26.5')
        assert 'golang:1.27.0' in between

    def test_backport_inserted_before_nearest_lower_version(self, work_dir):
        _, lock = run("1.25.13")
        assert 'golang:1.25.13@' in lock
        # 1.25.13 > 1.25.12, so must appear before 1.25.12
        between = lines_between(lock, 'golang:1.26.5', 'golang:1.25.12')
        assert 'golang:1.25.13' in between

    def test_version_between_two_existing_inserted_correctly(self, work_dir):
        _, lock = run("1.26.3")
        assert 'golang:1.26.3@' in lock
        # 1.26.4 > 1.26.3 > 1.26.0 (not in fixture, so before 1.25.12)
        between = lines_between(lock, 'golang:1.26.4', 'golang:1.25.12')
        assert 'golang:1.26.3' in between

    def test_exact_format_matches_reference(self, work_dir):
        _, lock = run("1.26.6")
        expected = (
            f'    - source: docker.io/library/golang:1.26.6@{FAKE_DIGEST}\n'
            f'      digest: {FAKE_DIGEST}\n'
        )
        assert expected in lock

    def test_only_one_entry_added(self, work_dir):
        _, lock = run("1.26.6")
        assert lock.count('golang:1.26.6@') == 1

    def test_existing_entries_unchanged(self, work_dir):
        _, lock = run("1.26.6")
        for snippet in ["1.26.5@sha256:", "1.26.4@sha256:", "1.25.12@sha256:", "1.25.11@sha256:"]:
            assert f'golang:{snippet}' in lock

    def test_alpine_entry_unchanged(self, work_dir):
        _, lock = run("1.26.6")
        assert 'golang:alpine\n      digest: sha256:' in lock


# ---------------------------------------------------------------------------
# Edge case tests
# ---------------------------------------------------------------------------

class TestEdgeCases:
    def test_blank_lines_between_yaml_entries(self, work_dir):
        # Extra blank line between entries should not break insertion
        content = Path("mirror.yaml").read_text()
        content = content.replace(
            '    replication_target: "build"\n  - source: "docker.io/library/golang:1.26',
            '    replication_target: "build"\n\n  - source: "docker.io/library/golang:1.26',
        )
        Path("mirror.yaml").write_text(content)
        yaml, _ = run("1.26.6")
        assert 'golang:1.26.6@' in yaml

    def test_blank_lines_between_lock_entries(self, work_dir):
        content = Path("mirror.lock.yaml").read_text()
        content = content.replace(
            '      digest: sha256:' + 'a'*64 + '\n    - source: docker.io/library/golang:1.26.4',
            '      digest: sha256:' + 'a'*64 + '\n\n    - source: docker.io/library/golang:1.26.4',
        )
        Path("mirror.lock.yaml").write_text(content)
        _, lock = run("1.26.6")
        assert 'golang:1.26.6@' in lock

    def test_version_with_trailing_whitespace_is_stripped(self, work_dir):
        # GO_VERSION env var with trailing space should produce a clean entry
        yaml, lock = run("1.26.6 ")
        assert 'golang:1.26.6@' in yaml
        assert 'golang:1.26.6 @' not in yaml
        assert 'golang:1.26.6@' in lock
        assert 'golang:1.26.6 @' not in lock

    def test_digest_with_trailing_whitespace_is_stripped(self, work_dir):
        yaml, lock = run("1.26.6", FAKE_DIGEST + " ")
        assert FAKE_DIGEST in yaml
        assert FAKE_DIGEST + " " not in yaml
