import unittest
import os
import yaml

from unittest.mock import patch

import tasks.gitlab as gitlab


class TestListBuildImages(unittest.TestCase):
    @patch.dict(
        os.environ,
        {"CI_PROJECT_DIR": "tasks/unit_tests/test_data/one_image"},
        clear=True,
    )
    def test_one_image(self):
        self.assertListEqual(gitlab.list_built_images(), ["btf_gen"])

    @patch.dict(
        os.environ,
        {"CI_PROJECT_DIR": "tasks/unit_tests/test_data/all_images"},
        clear=True,
    )
    def test_all_images(self):
        self.assertListEqual(
            gitlab.list_built_images(),
            [
                "docker_x64",
                "deb_armhf",
                "docker_arm64",
                "windows_ltsc2022_x64",
                "windows_1809_x64",
                "rpm_armhf",
                "gitlab_agent_deploy",
                "system_probe_arm64",
                "btf_gen",
                "deb_arm64",
                "linux_glibc_2_17_x64",
                "deb_x64",
                "system_probe_x64",
                "linux_glibc_2_23_arm64",
                "rpm_arm64",
                "dd_agent_testing",
                "rpm_x64",
            ],
        )

    @patch.dict(
        os.environ, {"CI_PROJECT_DIR": "tasks/unit_tests/test_data"}, clear=True
    )
    def test_no_update(self):
        self.assertListEqual(gitlab.list_built_images(), [])


class TestUpdateVariables(unittest.TestCase):
    def setUp(self):
        with open(".gitlab/trigger_template.yml") as f:
            trigger_template = yaml.safe_load(f)
            self.variables = trigger_template["trigger_datadog_agent"]["variables"]

    @patch.dict(
        os.environ,
        {"CI_PIPELINE_ID": "42", "CI_COMMIT_SHORT_SHA": "5h0rtc4t"},
        clear=True,
    )
    def test_one_update(self):
        images = ["btf_gen"]
        test = ""
        new_variables = gitlab.update_variables(self.variables, images, test)
        self.assertEqual(new_variables["RUN_KITCHEN_TESTS"], "false")
        self.assertEqual(new_variables["BUCKET_BRANCH"], "dev")
        self.assertEqual(
            sum([1 for v in new_variables.values() if v == "v42-5h0rtc4t"]), 5
        )  # 4 for former variables + 1 for btf_gen
        self.assertEqual(sum([1 for v in new_variables.values() if v == ""]), 37)
        self.assertEqual(
            sum([1 for v in new_variables.values() if v == "_test_only"]), 0
        )

    @patch.dict(
        os.environ,
        {"CI_PIPELINE_ID": "1789", "CI_COMMIT_SHORT_SHA": "fr4nc3"},
        clear=True,
    )
    def test_all_updates_with_test(self):
        images = [
            "docker_x64",
            "deb_armhf",
            "docker_arm64",
            "windows_ltsc2022_x64",
            "windows_1809_x64",
            "rpm_armhf",
            "gitlab_agent_deploy",
            "system_probe_arm64",
            "btf_gen",
            "deb_arm64",
            "linux_glibc_2_17_x64",
            "deb_x64",
            "system_probe_x64",
            "linux_glibc_2_23_arm64",
            "rpm_arm64",
            "dd_agent_testing",
            "rpm_x64",
        ]
        test = "_test_only"
        new_variables = gitlab.update_variables(self.variables, images, test)
        self.assertEqual(new_variables["RUN_KITCHEN_TESTS"], "false")
        self.assertEqual(new_variables["BUCKET_BRANCH"], "dev")
        self.assertEqual(
            sum([1 for v in new_variables.values() if v == "v1789-fr4nc3"]), 21
        )
        self.assertEqual(
            sum([1 for v in new_variables.values() if v == "_test_only"]), 21
        )
        self.assertEqual(sum([1 for v in new_variables.values() if v == ""]), 0)

    @patch.dict(
        os.environ,
        {"CI_PIPELINE_ID": "1000000", "CI_COMMIT_SHORT_SHA": "m1n10n5"},
        clear=True,
    )
    def test_updates_no_images(self):
        images = ["circleci_runner"]
        test = "_test_only"
        new_variables = gitlab.update_variables(self.variables, images, test)
        self.assertEqual(new_variables["RUN_KITCHEN_TESTS"], "false")
        self.assertEqual(new_variables["BUCKET_BRANCH"], "dev")
        self.assertEqual(
            sum([1 for v in new_variables.values() if v == "v1000000-m1n10n5"]), 4
        )  # only BUILDIMAGES
        self.assertEqual(
            sum([1 for v in new_variables.values() if v == "_test_only"]), 4
        )
        self.assertEqual(sum([1 for v in new_variables.values() if v == ""]), 34)
