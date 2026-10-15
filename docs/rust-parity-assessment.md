# Rust parity assessment

Decision for this maintenance line: **do not put the ledger or the authority behind UniFFI.** Byte parity already has a second implementation in Python. A Rust encoder of those same bytes would be a third implementation. UniFFI would make Swift call that Rust, so the Swift tests would stop being independent.

## Where the UniFFI demo actually is

There is no UniFFI crate in MasteryKit. `git log -S uniffi` on that repository, including `memory-layer`, is empty. The demo is `swift-ffi-demo/` in the Rust repository: crate `greeter`, UniFFI 0.32.2, Rust 1.91, Swift 6.2 or newer. `build.sh` compiles the crate, generates `greeter.swift`, and stages `libgreeter_rs.a`. The generated Swift is not committed.

What it crosses:

| Rust | Swift |
|---|---|
| `greet(name) -> String` | a function |
| `Stats` (`uniffi::Record`) | an equatable struct of `UInt64` and `Double` |
| `StatsError` (`uniffi::Error`) | a thrown enum |
| `Counter` (`uniffi::Object`, `Mutex<u64>`) | a class Swift holds and Rust owns |

That is a binding demo. It does not encode `CF-STATE-v1` or `PL-LOG-v1`, and it does not admit a practice event.

MasteryKit's `memory-layer` branch does have an FSRS test file. Its commit message says fsrs-rs reference vectors. The test itself says the numbers are hand-computed from the published formulas. That is formula parity inside Swift. It is not this UniFFI demo, and it is not a commitment profile.

## What parity means here

The public contracts are bytes and verdicts, not struct layout.

- `reference/make_vectors.py` and `reference/make_practice_vectors.py` build the canonical bytes with Python `struct` and hash them with `hashlib`. Swift must match.
- `reference/make_oracle_vectors.py` decides the thirteen admission verdicts. Swift must match.
- `InTreeSHA256` matches the published answers for the empty message and for `abc`, and the six original state vectors.

A Rust port has parity when it prints those same hashes and verdicts. Sharing a process with Swift is a later packaging choice.

## What UniFFI would get wrong if it were the next piece

`Stats.mean` is an `f64` computed in Rust. The practice score's identity is the canonical IEEE bits after `-0` has been rewritten to `+0`. The demo rejects NaN and does not canonicalize signed zero. Passing a `Double` through UniFFI and hashing the Swift value would be a second score profile.

`Counter` is a mutable heap object. `PracticeLedger` does not keep a cached event list across an `await`, because the authority's state is the only source of truth. A UniFFI object holding that state would be a Rust heap Swift merely references. `Capability` and `VerifiedTransition` are not serializable on purpose. An object Swift can reconstruct from the Rust side is the reconstruction path the authority model refuses.

UniFFI's own serialization is not `PL-LOG-v1`. Generating Swift from the crate would make the public types a build artifact. This repository commits the vectors and the byte recipe. The generated bindings in the demo are deliberately uncommitted.

## When a Rust crate is worth adding

Add a small Rust library that only encodes and decodes `PL-LOG-v1` and the fixed-binary state carrier, and checks the existing JSON vectors. No UniFFI, no actor, no capability. Swift remains the implementation the package ships. Rust and Python are then two non-production readers of the same bytes.

Add UniFFI only when a Swift program must call that crate and cannot do the work in Swift. Foundations can already do the work in Swift. Binding it to Rust would collapse the independent check the vectors exist to provide.
