# SPDX-FileCopyrightText: 2025-present Datadog, Inc. <dev@datadoghq.com>
#
# SPDX-License-Identifier: MIT
from dda.utils.fs import Path

PROJECT_ROOT = Path(__file__).parents[4]
TOOL_CONFIG_DIR = PROJECT_ROOT / "tools" / "dotslash" / "config"
