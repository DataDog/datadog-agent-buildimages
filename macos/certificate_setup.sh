#!/bin/bash

# Installs the signing certificates and makes sure they can be used
# in a CI environment (ie. without confirmation prompts) by code-signing apps.
# Allows creating signed builds of the Agent.

# Prerequisites:
# - A MacOS 10.13.6 (High Sierra) box
# - developer_id_installer.p12 signing cerificate available in $HOME folder
# - developer_id_application.p12 signing certificate available in $HOME folder
# - $INSTALLER_CERTIFICATE_PWD contains the password of the developer_id_installer.p12 file
# - $APPLICATION_CERTIFICATE_PWD contains the password of the developer_id_application.p12 file
# - $KEYCHAIN_NAME contains the keychain name. Defaults to login.keychain
# - $KEYCHAIN_PWD contains the keychain password

export KEYCHAIN_NAME=${KEYCHAIN_NAME:-"login.keychain"}

# Unlock login keychain
security unlock-keychain -p "$KEYCHAIN_PWD" "$KEYCHAIN_NAME"

# Import signing certificates and allow relevant apps to use them
security import ~/developer_id_installer.p12 -P "$INSTALLER_CERTIFICATE_PWD" -k "$KEYCHAIN_NAME" -T /usr/bin/productbuild
security import ~/developer_id_application.p12 -P "$APPLICATION_CERTIFICATE_PWD" -k "$KEYCHAIN_NAME" -T /usr/bin/codesign

# Update key partition list
security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PWD" "$KEYCHAIN_NAME"

# Lock login keychain
security lock-keychain "$KEYCHAIN_NAME"
