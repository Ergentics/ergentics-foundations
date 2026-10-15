#!/bin/sh
# Rebuilds the embedded Swift guest and copies it next to the recital page.
# The guest constructs the synthetic-base commitment. It does not commit.
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
. "$HOME/.local/share/swiftly/env.sh"
swift build -c release --swift-sdk swift-6.4.1-RELEASE_wasm-embedded \
  --product CommitmentGuest --scratch-path /tmp/foundation-guest \
  --package-path "$root"
src=$(find /tmp/foundation-guest -path '*/Release-webassembly-wasm32/CommitmentGuest.wasm' -print -quit)
cp "$src" "$root/demos/recital/commitment_guest.wasm"
ls -l "$root/demos/recital/commitment_guest.wasm"
