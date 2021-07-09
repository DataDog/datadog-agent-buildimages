#!/bin/bash

# FIXME: Uncomment this once the build script is fixed, and we
# check that this script doesn't accidentally exit early with set -e.

# set -e

# Requests notarization of the Agent package to Apple.

# Prerequisites:
# - you need a host running MacOS >= 10.13.6, with XCode >= 10.1 installed.
# - xpath installed and in $PATH (it should be installed by default).
# - builder_setup.sh has been run with SIGN=true.
# - the artifact is stored in $GOPATH/src/github.com/DataDog/datadog-agent/omnibus/pkg/.
# - $RELEASE_VERSION contains the version that was created. Defaults to $VERSION.
# - $APPLE_ACCOUNT contains the Apple account name for the Agent.
# - $NOTARIZATION_PWD contains the app-specific notarization password for the Agent.

# Load build setup vars
source ~/.build_setup

export RELEASE_VERSION=${RELEASE_VERSION:-$VERSION}

unset REQUEST_UUID
unset NOTARIZATION_STATUS_CODE
unset LATEST_DMG

# Find latest .dmg file in $GOPATH/src/github.com/Datadog/datadog-agent/omnibus/pkg
for file in "$GOPATH/src/github.com/Datadog/datadog-agent/omnibus/pkg"/*.dmg; do
  if [[ -z "$LATEST_DMG" || "$file" -nt "$LATEST_DMG" ]]; then LATEST_DMG="$file"; fi
done

echo "File to upload: $LATEST_DMG"

# Send package for notarization; retrieve REQUEST_UUID
echo "Sending notarization request."

# Example notarization request output:
# <?xml version="1.0" encoding="UTF-8"?>
# <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
# <plist version="1.0">
# <dict>
#         <key>notarization-upload</key>
#         <dict>
#                 <key>RequestUUID</key>
#                 <string>wwwwwwww-xxxx-yyyy-zzzz-tttttttttttt</string>
#         </dict>
#         <key>os-version</key>
#         <string>10.14.6</string>
#         <key>success-message</key>
#         <string>No errors uploading '/path/to/file'.</string>
#         <key>tool-path</key>
#         <string>/Applications/Xcode.app/Contents/SharedFrameworks/ContentDeliveryServices.framework/Versions/A/Frameworks/AppStoreService.framework</string>
#         <key>tool-version</key>
#         <string>4.00.1181</string>
# </dict>
# </plist>
for i in {1..5}; do
    NOTARIZATION_REQUEST_OUTPUT=$(xcrun altool --notarize-app --primary-bundle-id "com.datadoghq.agent.$RELEASE_VERSION" --username "$APPLE_ACCOUNT" --password "$NOTARIZATION_PWD" --file "$LATEST_DMG" --output-format xml)
    echo "$NOTARIZATION_REQUEST_OUTPUT"
    REQUEST_UUID=$(echo "$NOTARIZATION_REQUEST_OUTPUT" | xpath "/plist/dict/key[text()='notarization-upload']/following-sibling::*[1]/key[text()='RequestUUID']/following-sibling::*[1]/text()")
    if [[ -n "$REQUEST_UUID" ]]; then
        break
    fi

    sleep 5
done

if [[ -z "$REQUEST_UUID" ]]; then
    echo "Error while retrieving REQUEST_UUID."
    exit 1
fi

# Example notarization status output:
# <?xml version="1.0" encoding="UTF-8"?>
# <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
# <plist version="1.0">
# <dict>
#         <key>notarization-info</key>
#         <dict>
#                 <key>Date</key>
#                 <date>2020-08-25T17:48:58Z</date>
#                 <key>Hash</key>
#                 <string>12e79ec...</string>
#                 <key>LogFileURL</key>
#                 <string>https://osxapps-ssl.itunes.apple.com/itunes-assets/...</string>
#                 <key>RequestUUID</key>
#                 <string>wwwwwwww-xxxx-yyyy-zzzz-tttttttttttttttt</string>
#                 <key>Status</key>
#                 <string>invalid</string>
#                 <key>Status Code</key>
#                 <integer>2</integer>
#                 <key>Status Message</key>
#                 <string>Package Invalid</string>
#         </dict>
#         <key>os-version</key>
#         <string>10.14.6</string>
#         <key>success-message</key>
#         <string>No errors getting notarization info.</string>
#         <key>tool-path</key>
#         <string>/Applications/Xcode.app/Contents/SharedFrameworks/ContentDeliveryServices.framework/Versions/A/Frameworks/AppStoreService.framework</string>
#         <key>tool-version</key>
#         <string>4.00.1181</string>
# </dict>
# </plist>

echo "Waiting for notarization process to complete."
while [[ -z "$NOTARIZATION_STATUS_CODE" ]]; do
    sleep 30
    echo "Fetching notarization status"
    NOTARIZATION_STATUS_OUTPUT=$(xcrun altool --notarization-info "$REQUEST_UUID" -u "$APPLE_ACCOUNT" -p "$NOTARIZATION_PWD" --output-format xml)
    echo "$NOTARIZATION_STATUS_OUTPUT"
    NOTARIZATION_STATUS_CODE=$(echo "$NOTARIZATION_STATUS_OUTPUT" | xpath "/plist/dict/key[text()='notarization-info']/following-sibling::*[1]/key[text()='Status Code']/following-sibling::*[1]/text()")
done

# Print final status in the console
xcrun altool --notarization-info "$REQUEST_UUID" -u "$APPLE_ACCOUNT" -p "$NOTARIZATION_PWD"

if [[ "$NOTARIZATION_STATUS_CODE" -ne "0" ]]; then
    exit 1
fi
exit 0
