#!/usr/bin/env bash

export CC_x86_64_unknown_linux_gnu=x86_64-linux-gnu-gcc
export CXX_x86_64_unknown_linux_gnu=x86_64-linux-gnu-g++
export AR_x86_64_unknown_linux_gnu=x86_64-linux-gnu-ar

cargo build --release --quiet
cp target/x86_64-apple-darwin/release/handlebars_reports "${1}_darwin"
cp target/x86_64-unknown-linux-gnu/release/handlebars_reports "${1}_linux"
