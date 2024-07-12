#!/usr/bin/env python

import base64
import os
import sys

from github import Auth, GithubIntegration

if __name__ == "__main__":
    if sys.stdout.isatty():
        print(
            """Refusing to display auth token to terminal.
Please run this script within a redirection or command substitution."""
        )
        sys.exit(1)
    if "GITHUB_APP_ID" not in os.environ:
        sys.exit("Missing mandatory GITHUB_APP_ID environment variable")
    if "GITHUB_KEY_B64" not in os.environ:
        sys.exit("Missing mandatory GITHUB_KEY_B64 environment variable")
    app_id = os.environ.get("GITHUB_APP_ID")
    app_key_b64 = os.environ.get("GITHUB_KEY_B64")
    app_key = base64.b64decode(app_key_b64).decode("ascii")

    auth = Auth.AppAuth(app_id, app_key)
    integration = GithubIntegration(auth=auth)
    installations = integration.get_installations()
    if installations.totalCount == 0:
        sys.exit("Failed to list app installations")
    install_id = installations[0].id
    auth_token = integration.get_access_token(install_id)
    print(auth_token.token)
