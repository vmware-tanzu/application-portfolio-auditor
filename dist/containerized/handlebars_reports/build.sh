#!/usr/bin/env bash

#### Darwin build
export SDKROOT=$(pwd)/MacOSX13.3.sdk/
export PATH=$PATH:~/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/lib/rustlib/x86_64-unknown-linux-gnu/bin/
export CARGO_TARGET_X86_64_APPLE_DARWIN_LINKER=rust-lld
cargo build --release --target x86_64-apple-darwin

#### Linux build
export CC_x86_64_unknown_linux_gnu=x86_64-linux-gnu-gcc
export CXX_x86_64_unknown_linux_gnu=x86_64-linux-gnu-g++
export AR_x86_64_unknown_linux_gnu=x86_64-linux-gnu-ar
cargo build --release --target x86_64-unknown-linux-gnu

# Copy binaries
cp target/x86_64-apple-darwin/release/handlebars_reports "${1}_darwin"
cp target/x86_64-unknown-linux-gnu/release/handlebars_reports "${1}_linux"
