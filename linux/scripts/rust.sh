#!/usr/bin/env bash
set -euxo pipefail

chmod +x ./rustup-init
./rustup-init -y --profile minimal --default-toolchain ${RUST_VERSION}
echo "${RUSTUP_SHA256}  /root/.cargo/bin/rustc" | sha256sum --check

/root/.cargo/bin/cargo install --git https://github.com/DataDog/rust-license-tool dd-rust-license-tool
/root/.cargo/bin/cargo install cargo-deny --locked

# Set the default toolchain to the one we just installed
/root/.cargo/bin/rustup default ${RUST_VERSION}

# Move binaries out of Cargo's default location so that we can cleanly move them to their
# own directory and treat everything else as cached assets. This default mingling of files
# with different purposes is a known issue that the community is working to fix. See:
# https://blog.rust-lang.org/inside-rust/2025/10/01/this-development-cycle-in-cargo-1.90/#all-hands-xdg-paths
mv /root/.cargo/bin /usr/local/cargo-bin
