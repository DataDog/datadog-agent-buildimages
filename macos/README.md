# MacOS builder setup scripts

The scripts in this folder are made to create a build environment for the MacOS Agent & create unsigned or signed builds of the MacOS Agent.


## Prerequisites

- A clean MacOS 10.13.6 (High Sierra) host
- Varying environment variables & files present on the host (see individual files for specific requirements).

## Contents

- `builder_setup.sh`: installs all required build dependencies
- `certificate_setup.sh`: installs the developer certificates in keychain & allow automatic access to code-signing applications
- `build_script.sh`: does the omnibus build of the Agent

## Notes on notarization

To notarize a build:
- you need a host running MacOS 10.13.6 or higher (not necessarily the builder), with XCode >= 10.1 installed.
- the omnibus build must have been signed and run with the `--hardened-runtime` option (done by default by `build_script.sh` when `$SIGN == "true"`).
- `$APPLE_ACCOUNT` must contain the Apple account name for the Agent.
- `$NOTARIZATION_PWD` must contain the app-specific notarization password for the Agent.

Then follow these instructions:

1. Select XCode app to use

`sudo xcode-select -s /Applications/Xcode.app`

2. Add notarization password to keychain

`xcrun altool --store-password-in-keychain-item "AC_PASSWORD" -u "package@datadoghq.com" -p "$NOTARIZATION_PWD"`

3. Send notarization request

`xcrun altool --notarize-app --primary-bundle-id "com.datadoghq.agent.$VERSION" --username "$APPLE_ACCOUNT" --password "@keychain:AC_PASSWORD" --file <dmg file>`

This command will upload the dmg package to Apple and return a UUID identifying the notarization request (if successful).

4. Use the provided UUID to check on the notarization status

`xcrun altool --notarization-info <UUID> -u "$APPLE_ACCOUNT" -p "@keychain:AC_PASSWORD"`