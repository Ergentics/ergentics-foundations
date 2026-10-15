# Rust parity and WASM

The earlier note treated `swift-ffi-demo/` in the Rust repository as MasteryKit's Swift–Rust bridge. That was the wrong artifact. MasteryKit does not call UniFFI. It calls for parity with a named Rust reference, and the oracle policy names WASM as an external checker. This note replaces that reading.

Decision for this maintenance line: **`commitment-reader` 0.1.0 is that reader.** Python wrote the vectors. Rust recomputes them and must match exactly. The same crate builds to `wasm32-unknown-unknown` and hashes those bytes outside the Swift process. Swift still ships the ledger. The reader does not issue capabilities or commit.

## What MasteryKit actually checks

On `memory-layer`, not on current `main`, `Tests/MasteryKitTests/FSRSTests.swift` has a section titled parity with fsrs-rs. The expected numbers are fsrs-rs v6.6.2's own tests in `src/inference.rs` (`test_memory_state`, `test_next_interval`). That Rust code computes in `f32`. The Swift port uses `Double` and states the slack: stability within `1e-3`, difficulty within `1e-4`, and the 3.1-million-day interval within a relative `1e-5`. The shorter intervals match after rounding.

`Sources/MasteryKit/Memory/FSRS.swift` on that branch says the formulas follow published FSRS-6 and py-fsrs v6.3.2. The test file is the Rust pin. There is no WASM build, no `fsrs-rs` crate in the tree, and no UniFFI. `git log -S uniffi` on MasteryKit is empty.

The shape of the call is: name the reference version, commit the vectors it produced, and write down where the numeric types differ. The Swift tests do not link the Rust library.

## What the oracle policy adds

`agentcraft-app/docs/ORACLE-POLICY.md`, under "Improving this policy," lists external oracle languages still to record as apps are added: Python, Rust, WASM. That line is a checklist item. It is not a built pipeline. The one-sentence law above it is unchanged: at least two paths must agree, and at least one path must not be the production scorer.

WASM belongs on that list because it runs the checker somewhere other than the shipping Swift process: a browser, or a CI sandbox. It is not a way to give Swift a Rust object.

## What this repository already has

Python is the external path that the policy asks for first.

- `reference/make_vectors.py` and `reference/make_practice_vectors.py` build `CF-STATE-v1` and `PL-LOG-v1` with `struct` and hash them with `hashlib`.
- `reference/make_oracle_vectors.py` decides the thirteen admission verdicts.
- The SHA-256 answers for the empty message and for `abc` are the published digests, not a Swift-only result.

Those matches are exact. There is no `f32` slack, and there should not be. The fields are integers, length-prefixed UTF-8, and IEEE-754 bits that the encoder has already canonicalized (`-0` stored as `+0`). The oracle table uses only scores `0`, `0.5`, and `1`. Copying the FSRS tolerance here would hide a byte that had changed.

## What not to build from this

Do not vendor `fsrs-rs` into foundations. The memory model is not this package's contract, and it is not on MasteryKit `main`.

Do not add UniFFI so Swift can call a Rust encoder. That would make the production path and the "external" path the same code. The FSRS tests avoid that: they store the Rust output and recompute it in Swift.

Do not run the ledger as an issuer inside WASM. Authority, capabilities, and tickets are process-local on purpose. A WASM port of `ReferenceAuthority` would look like a second issuer.

The Swift 6.4.1 compiler can cross-compile with its WebAssembly SDK. `CommitmentProbe` prints one commitment from that module and does not call the actor. `wasm32-unknown-unknown` is not a target of this compiler; the SDK triple is `wasm32-unknown-wasip1`. See [the compiler probe](swift-wasm-probe.md).

## The reader that is now in the tree

`rust/commitment-reader` is version **0.1.0** and builds with Rust **1.99.0**, the stable release. `wasm-check.mjs` runs on Node **26.12.0**, the Current release. That script loads WebAssembly directly and does not import `node:wasi`. `Cargo.lock` pins `sha2` 0.10.8. The tests name the two vector files and require exact hex, including the signed `u64`/`i64` bounds and the UTF-8 skill id `café`. `commitment-bench` times that reader. Its numbers are not a comparison with Swift. See `docs/benchmarks.md`.

```sh
cd rust/commitment-reader
cargo test
rustup target add wasm32-unknown-unknown
cargo build --release --target wasm32-unknown-unknown
node wasm-check.mjs
```

`cargo test` checks all six state vectors and all five practice vectors. `wasm-check.mjs` loads the wasm module and checks two of those hashes: the synthetic base state, and the empty practice log at generation 0. The call packing is big-endian fields at the boundary. The bytes under the hash are still `CF-STATE-v1` and `PL-LOG-v1`.

The module exports `cf_state_commitment_hex` and `pl_state_commitment_hex`. It does not export an authority, a capability, or a commit.
