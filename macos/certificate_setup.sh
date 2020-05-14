#!/bin/bash

# Installs the signing certificates and makes sure then can be used
# in a CI environment (ie. without confirmation prompts) by code-signing apps.
# Allows creating signed builds of the Agent.

# Prerequisites:
# - A MacOS 10.13.6 (High Sierra) box
# - developer_id_installer.p12 signing cerificate available in $HOME folder
# - developer_id_application.p12 signing certificate available in $HOME folder
# - $CERTIFICATE_PWD contains the password of the .p12 files
# - $KEYCHAIN_PWD contains the login keychain password

# Unlock login keychain
security unlock-keychain -p $KEYCHAIN_PWD "login.keychain"

# Import signing certificates and allow relevant apps to use them
security import ~/developer_id_installer.p12 -P $CERTIFICATE_PWD -k "login.keychain" -T /usr/bin/productbuild
security import ~/developer_id_application.p12 -P $CERTIFICATE_PWD -k "login.keychain" -T /usr/bin/codesign

# Update key partition list
security set-key-partition-list -S apple-tool:,apple: -s -k $KEYCHAIN_PWD login.keychain

# Lock login keychain
security lock-keychain "login.keychain"
