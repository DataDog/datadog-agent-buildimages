# MacOS builder setup scripts

The scripts in this folder are made to create a build environment for the MacOS Agent & create unsigned or signed builds of the MacOS Agent.


## Prerequisites

- A clean MacOS 10.13.6 (High Sierra) host

**Note:** The MacOS Agent build is currently not compatible with MacOS releases 10.14.4 and higher. MacOS 10.14.4 and higher use XCode 10.2+ by default. XCode 10.2 obsoleted Swift 3 ([see XCode 10.2 changelog](https://developer.apple.com/documentation/xcode_release_notes/xcode_10_2_release_notes/swift_5_release_notes_for_xcode_10_2?preferredLanguage=occ)), which [the Agent systray app targets](https://github.com/DataDog/datadog-agent/blob/master/omnibus/config/software/datadog-agent.rb#L226).

- Varying environment variables & files present on the host (see individual files for specific requirements).

## Contents

- `builder_setup.sh`: installs all required build dependencies
- `certificate_setup.sh`: installs the developer certificates in keychain & allow automatic access to code-signing applications. Only needed if you want to sign the resulting package.
- `build_script.sh`: does the omnibus build of the Agent.
- `notarization_script.sh` notarizes an Agent build. Will only work if the package was signed.
