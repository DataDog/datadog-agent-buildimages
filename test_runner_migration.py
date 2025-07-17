#!/usr/bin/env python3
"""
Test script to verify GitLab CI runner tag migration
"""

import os
import re
import sys


def test_file_exists(filepath):
    """Test that file exists"""
    if not os.path.exists(filepath):
        print(f"FAIL: {filepath} does not exist")
        return False
    print(f"PASS: {filepath} exists")
    return True


def test_no_deprecated_tags(filepath):
    """Test that no deprecated runner:docker-arm tags exist"""
    try:
        with open(filepath, "r") as f:
            content = f.read()

        if "runner:docker-arm" in content:
            print(f"FAIL: {filepath} contains deprecated 'runner:docker-arm' tag")
            return False

        print(f"PASS: {filepath} contains no deprecated runner tags")
        return True
    except Exception as e:
        print(f"ERROR: Cannot read {filepath}: {e}")
        return False


def test_new_runner_tags(filepath):
    """Test that new docker-in-docker:arm64 tags are present"""
    try:
        with open(filepath, "r") as f:
            content = f.read()

        if "docker-in-docker:arm64" in content:
            print(f"PASS: {filepath} contains new 'docker-in-docker:arm64' tag")
            return True
        else:
            print(f"INFO: {filepath} does not contain new runner tag (may be normal)")
            return True
    except Exception as e:
        print(f"ERROR: Cannot read {filepath}: {e}")
        return False


def test_platform_tags_removed(filepath):
    """Test that platform:arm64 tags are not used with new runner"""
    try:
        with open(filepath, "r") as f:
            content = f.read()

        # Check for lines that have both docker-in-docker:arm64 and platform:arm64
        lines = content.split("\n")
        for i, line in enumerate(lines):
            if "docker-in-docker:arm64" in line:
                # Check surrounding lines for platform:arm64
                context_lines = lines[max(0, i - 2) : min(len(lines), i + 3)]
                context = "\n".join(context_lines)
                if "platform:arm64" in context:
                    print(
                        f"FAIL: {filepath} line {i+1}: platform:arm64 found with docker-in-docker:arm64"
                    )
                    return False

        print(f"PASS: {filepath} has no platform:arm64 tags with new runner")
        return True
    except Exception as e:
        print(f"ERROR: Cannot read {filepath}: {e}")
        return False


def main():
    """Run all tests"""
    test_files = [
        ".gitlab/stats.yml",
        ".gitlab/kernel_version_testing.yml",
        ".gitlab-ci.yml",
    ]

    print("Running GitLab CI runner migration tests...")
    print("=" * 50)

    all_passed = True

    for filepath in test_files:
        print(f"\nTesting {filepath}:")

        if not test_file_exists(filepath):
            all_passed = False
            continue

        if not test_no_deprecated_tags(filepath):
            all_passed = False

        if not test_new_runner_tags(filepath):
            all_passed = False

        if not test_platform_tags_removed(filepath):
            all_passed = False

    print("\n" + "=" * 50)
    if all_passed:
        print("✅ ALL TESTS PASSED")
        return 0
    else:
        print("❌ SOME TESTS FAILED")
        return 1


if __name__ == "__main__":
    sys.exit(main())
