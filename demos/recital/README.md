# Commitment recital

A short public page for one piece: the synthetic-base state commitment, then the empty practice log. `index.html` runs two constructions of that state. The Swift guest calls `State.commitment`. The Rust reader builds the same state from the call fields. The page compares the hex strings. It does not commit.

`commitment_guest.wasm` is the embedded Swift reactor, 237947 bytes. Regenerate it with `demos/recital/stage-guest.sh`. `commitment_reader.wasm` is the Rust release module. Regenerate it with `demos/recital/stage.sh`. The script runs `cargo +1.99.0 build --locked --release --target wasm32-unknown-unknown` and copies the module beside the page. Do not commit `rust/commitment-reader/target/`. The 60 MB WASI command is not a page asset.

These pages follow the recital shape: one HTML file, a control, and checks that run in the page. `hello-440.html` is the public just-intonation greeting. `index.html` plays both constructions. The private lyre composition engine is not copied here.

```sh
python3 -m http.server 8765 --directory demos/recital
```

Then open `http://127.0.0.1:8765/`. Both modules play in the browser. The compiler probe in `docs/swift-wasm-probe.md` is the separate WASI command.

The Worker in `docs/cloudflare-host.md` has a temporary `workers.dev` preview. The zone path beside `/research/propulsion.html` is not attached.

Copyright 2026 Ergentics, LLC. SPDX-License-Identifier: Apache-2.0.
