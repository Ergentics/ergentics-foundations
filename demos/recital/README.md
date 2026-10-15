# Commitment recital

A short public page for one piece: the synthetic-base state commitment, then the empty practice log. `index.html` calls `commitment-reader` 0.1.0. It does not commit.

`commitment_reader.wasm` next to the page is the release module, so this directory can be served without a rebuild. Regenerate that file with `demos/recital/stage.sh`. The script runs `cargo +1.99.0 build --locked --release --target wasm32-unknown-unknown` and copies the module beside the page. Do not commit `rust/commitment-reader/target/`.

These pages follow the recital shape: one HTML file, a control, and checks that run in the page. `hello-440.html` is the public just-intonation greeting. `index.html` plays the Rust commitment reader. The private lyre composition engine is not copied here.

```sh
python3 -m http.server 8765 --directory demos/recital
```

Then open `http://127.0.0.1:8765/`. The Rust module is the voice the browser can play. The Swift voice is the compiler probe in `docs/swift-wasm-probe.md`.

Copyright 2026 Ergentics, LLC. SPDX-License-Identifier: Apache-2.0.
