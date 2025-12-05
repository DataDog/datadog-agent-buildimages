#!/usr/bin/env bash
set -euxo pipefail

chmod +x ./rustup-init
./rustup-init -y --profile minimal --default-toolchain ${RUST_VERSION}
echo "${RUSTUP_SHA256}  /root/.cargo/bin/rustc" | sha256sum --check
