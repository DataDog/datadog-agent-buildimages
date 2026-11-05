#!/bin/bash
# Install public Bits Code trust only. The mode marker grants no authorization.
set -euo pipefail
fail() { echo "Bits Code trust: $*" >&2; exit 1; }
[[ $(id -u) == 0 ]] || fail "initialization must run as root"
trust=/run/codegen-trust
for name in ca-certificates.crt sandbox-proxy-ca.crt java-cacerts; do
    file="$trust/$name"
    [[ -f "$file" && -r "$file" && -s "$file" && ! -L "$file" ]] || fail "missing or unreadable public trust file: $file"
    options=$(findmnt -n -o VFS-OPTIONS -T "$file") || fail "cannot inspect mount for $file"
    [[ ",$options," == *,ro,* ]] || fail "public trust mount must be read-only: $file"
done
openssl x509 -in "$trust/ca-certificates.crt" -noout >/dev/null || fail "invalid PEM CA bundle"
openssl crl2pkcs7 -nocrl -certfile "$trust/ca-certificates.crt" | openssl pkcs7 -print_certs -noout >/dev/null || fail "invalid PEM CA bundle"
openssl x509 -in "$trust/sandbox-proxy-ca.crt" -noout >/dev/null || fail "invalid proxy CA certificate"
# Java validates its truststore when Bazel starts; do not add a JDK to startup.
install -m 0644 "$trust/sandbox-proxy-ca.crt" /usr/local/share/ca-certificates/bits-code-proxy.crt
update-ca-certificates
# Preserve existing system Bazel configuration and make repeat starts idempotent.
line='startup --host_jvm_args=-Djavax.net.ssl.trustStore=/run/codegen-trust/java-cacerts'
touch /etc/bazel.bazelrc
grep -Fxq -- "$line" /etc/bazel.bazelrc || printf '\n%s\n' "$line" >> /etc/bazel.bazelrc
