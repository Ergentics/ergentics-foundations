# Benchmarks

These commands time the public paths. A printed `ns_per_op` is not a result that can be compared across languages, machines, or commits unless a later note declares the pair, the control, and the accounting boundary again. The test suite does not read these numbers. CI runs each bench for 2 iterations only to prove the binary starts.

## What is timed

| Workload | Process | Control |
|---|---|---|
| `state-commitment-reread` | Swift | Read `State.commitment` on one value. Commitment is not memoized, so this still encodes and hashes. |
| `state-rebuild` | Swift | Construct that state again each iteration, then hash. The difference from the reread is `State` initialization. |
| `empty-commit-sequence` | Swift | Verify and `commitRecording` of an unchanged payload, one issuer, growing consumed-ticket set. |
| `practice-growing-log` | Swift | Append one moment event per iteration. Each commit re-encodes the whole log. |
| `oracle-judge` | Swift | `OracleAdmission.judge` on one fixed claim. No ledger. |
| `hash-precomputed-state` | Rust | SHA-256 of bytes encoded once. |
| `state-encode` | Rust | Encode and hash a fixed 32-entry state. |
| `practice-fixed-log` | Rust | Encode and hash one moment event. The log does not grow, and there is no actor. |

The Rust arms are not a paired trial against the Swift arms. The Swift commit arms include the actor. The Rust arms do not.

The 32-entry state used by both programs hashes to `58b8db0ebace624abdd96712379cbf5dfb7ce9b9bbfc0c17d1c00482b6c73c02`. The Rust one-moment log hashes to the `moment-stage-commit` vector. The bench exits nonzero if those sinks move. That check is byte identity, not a time limit.

## Run

```sh
swift run --scratch-path /tmp/foundation-build FoundationBench --iterations 1000
cd rust/commitment-reader
cargo +1.99.0 run --locked --release --bin commitment-bench -- --iterations 10000
```

Rust 1.99.0 is the stable release used for this crate. The lockfile still pins `sha2` 0.10.8. The bench does not change `CF-STATE-v1` or `PL-LOG-v1`.
