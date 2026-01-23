#!/usr/bin/env bash
set -euxo pipefail

chmod +x ./rustup-init
./rustup-init -y --profile minimal --default-toolchain ${RUST_VERSION}
echo "${RUSTUP_SHA256}  /root/.cargo/bin/rustc" | sha256sum --check

/root/.cargo/bin/cargo install --git https://github.com/DataDog/rust-license-tool dd-rust-license-tool
/root/.cargo/bin/cargo install cargo-deny --locked
