#!/usr/bin/env bash
set -euxo pipefail

mkdir /tmp/rust
cd /tmp/rust

curl -sSL -o rustup-init https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${ARCH}-unknown-linux-gnu/rustup-init
echo "${RUSTUP_SHA256}  rustup-init" | sha256sum --check
chmod +x ./rustup-init
./rustup-init -y --profile minimal --default-toolchain ${RUST_VERSION}
echo "${RUSTUP_SHA256}  /root/.cargo/bin/rustc" | sha256sum --check
rm ./rustup-init

rm -rf /tmp/rust
