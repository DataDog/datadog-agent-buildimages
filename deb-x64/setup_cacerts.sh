#!/bin/bash

set -ex

# HACK: remove expired root certificates
# The builders have very old versions of openssl (1.0.1t in the deb_x64 builder). In these versions,
# openssl will try to use the expired cert chain first even if you trust another valid cert chain,
# so the expired cert chain needs to stop being trusted.
# See: https://www.openssl.org/blog/blog/2021/09/13/LetsEncryptRootCertExpire/
# Sep 30, 2021: DST Root CA X3 expired
rm /etc/ssl/certs/DST_Root_CA_X3.pem
