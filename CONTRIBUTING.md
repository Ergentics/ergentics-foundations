# Contributing

Ergentics Foundations is licensed under [Apache-2.0](LICENSE). Under section 5, contributions intentionally submitted for inclusion are under Apache-2.0 unless explicitly stated otherwise; an applicable separate license agreement is not superseded. Section 1 defines a Contribution and excludes material designated in writing as "Not a Contribution." Submit only material you have authority to license. Identify any third-party material and its applicable terms. No separate CLA or DCO sign-off is required for this candidate.

Proposed changes should state the semantic contract, add a small synthetic counterexample or reference vector where needed, and preserve rejection behavior. Keep correctness, authority and performance claims separate. A timing observation needs its own declared control, accounting boundary and independent review; this package's tests are not performance evidence.

Never contribute private primary evidence, model inputs, patient information, credentials, signing material, private history or internal operational records. Public claims derived from the private record must use stable evidence IDs and retain uncertainty. Historical negative results and classification boundaries must not be rewritten to improve a narrative.

Keep generated build files and local diagnostics outside the tree (`target/`, `.build/`, scratch paths). Preserve applicable notices and follow Apache-2.0 section 4 when redistributing modified files. License adoption is complete. The maintenance remote is `https://github.com/Ergentics/ergentics-foundations`. That remote does not by itself approve every future tree.

## Along the way

Fetch `origin/main` before the next commit. If `git log HEAD..origin/main` is not empty, merge or rebase onto `main` first.

A commit is one concern. The subject says what landed. The body says the contract consequence, including what the change does not claim: not authority, not a harvested corpus record, not a performance result. A correction of a decision rewrites the lead of that note in the same commit. New public surface stays inside [hedges.md](hedges.md). Crossing a hedge is a contract change and has to be named in the commit.

A behavior change carries an independent vector or extends one. The expected hash comes from the Python recipe or a published digest, not from rerunning the implementation under test and pasting its output. Rust and WASM readers must match those bytes exactly. Numeric slack from another project, such as an `f32` memory model, does not apply to `CF-STATE-v1` or `PL-LOG-v1`.

Do not import proprietary sibling trees. A public type may mirror a vocabulary. It does not copy a game engine, a harvest, or a vendored kernel. `commitment-reader` hashes bytes. It does not commit, and it does not become a Swift package dependency. Commit its `Cargo.lock`. Do not commit its `target/` directory.

| Change | Run before pushing |
|---|---|
| `Sources/`, `Tests/`, `Package.swift` | `swift test --scratch-path /tmp/foundation-build`. If `FoundationBench` changed, also `swift run --scratch-path /tmp/foundation-build FoundationBench --iterations 2`. If continuity counts changed, `python3 reference/check_continuity.py` |
| `rust/commitment-reader` | Rust 1.99.0. `cargo test --locked`, then the wasm32 release build, `node wasm-check.mjs`, and `cargo run --locked --release --bin commitment-bench -- --iterations 2` |
| `traceability/` | Ruby 4.0.7 and Rails 8.1.4. `cd traceability && bin/rails test` |
| Docs only | Do not describe a test run that did not happen |

The Swift job uses the `swift:6.4.1` image, the latest 6.4 stable. A data run is `ruby reference/data_run.rb` and is not the merge check. Ruby 4.0.7 records it. Rails 8.1.4 loads the traceability index under `traceability/`. That app is not the data-run recorder and not a production store. See `docs/data-run.md` and `docs/traceability-index.md`.

`.github/workflows/check.yml` runs those checks on pull requests and on pushes to `main`. GitHub Actions in this repository follow the org rule: an action must be owned by Ergentics and pinned to a full commit SHA. `actions/checkout` is not eligible, so the workflow fetches the commit with git. A green run of that workflow is the merge check for the paths it covers. It is not performance evidence and not an authority proof. CodeQL's default Swift configuration on `main` is a separate setup; a pull request that does not carry it shows a recycled warning, not a failure of this workflow.
