#!/bin/sh
# Copyright 2026 Ergentics, LLC. SPDX-License-Identifier: Apache-2.0.
# Build commitment-reader for wasm32 and copy the module next to the page.
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
crate="$root/rust/commitment-reader"
cargo +1.99.0 build --locked --release --manifest-path "$crate/Cargo.toml" --target wasm32-unknown-unknown
cp "$crate/target/wasm32-unknown-unknown/release/commitment_reader.wasm" "$(dirname "$0")/commitment_reader.wasm"
echo "staged $(dirname "$0")/commitment_reader.wasm"
echo "serve with: python3 -m http.server 8765 --directory $(dirname "$0")"
