#!/bin/sh
# Copyright 2026 Ergentics, LLC. SPDX-License-Identifier: Apache-2.0.
# Build the embedded Swift guest and copy it next to the page.
# Reactor mode: the browser calls exports. It does not run _start.
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
# shellcheck disable=SC1091
. "$HOME/.local/share/swiftly/env.sh"
swift build -c release \
  --swift-sdk swift-6.4.1-RELEASE_wasm-embedded \
  --product CommitmentGuest \
  --scratch-path /tmp/foundation-embedded \
  -Xswiftc -Xclang-linker \
  -Xswiftc -mexec-model=reactor
wasm=/tmp/foundation-embedded/out/Products/Release-webassembly-wasm32/CommitmentGuest.wasm
size=$(wc -c < "$wasm")
max=$((25 * 1024 * 1024))
if [ "$size" -ge "$max" ]; then
  echo "guest wasm is $size bytes, at or above 25 MiB" >&2
  exit 1
fi
cp "$wasm" "$root/demos/recital/commitment_guest.wasm"
chmod 644 "$root/demos/recital/commitment_guest.wasm"
echo "staged $root/demos/recital/commitment_guest.wasm ($size bytes)"
