# Ergentics Foundations

Ergentics Foundations is a proposed public, research-derived, evolvable SDK/foundation. This unpublished v0.1 scope checkpoint includes a small Swift semantic reference for **State → CandidateTransition → Verify → Commit**, contract extraction, synthetic vectors and a public-safe post-hoc synthesis of E01–E26. It is not a production SDK or a private research archive. The selected repository name is `ergentics-foundations`.

Consequential-change research asks which consequences must be recomputed when state changes, and what exactness, applicability and authority must be established before those consequences can be used. Differential computation includes the cost of discovering changes, maintaining dependencies, storing results, validating reuse and checking output integrity.

“A Delta Processing Unit is an accelerator that computes the consequences of change” describes an execution-model research direction here. No dedicated ΔPU hardware has been established.

## What the research supports

The 26 experiments progressed from first-party optimizer/autodiff boundaries through selective execution, persistent representations, request maintenance, commitments and current validation. Selected sparse, warm and request-only regions produced differential wins against their contemporaneous FULL controls. Arithmetic reduction alone often lost once management and materialization were included. Later representation improvements frequently helped both FULL and differential paths. Source changes reversed some reuse benefits. See the [public synthesis](docs/e01-e26-public-synthesis.md) and [experiment-local dataset](docs/longitudinal-dataset.json) for comparison boundaries and negative results.

E26 is **H. MEASUREMENT DECOMPOSITION INCONCLUSIVE**; no speedup was tested. It concentrates a mixed provenance loop without isolating removable work or establishing reusable validation authority or net benefit. E01–E26 closes here because the evidence no longer uniquely nominates another intervention. There is no E27 in this series. **Economic exhaustion remains UNKNOWN; successor projects are not blocked.**

## What this code does

The reference implements immutable logical state, domain-checked proposals, deterministic canonical commitments, a distinction between order and relation, opaque process-local capabilities, generation-bound verified proposals, fresh commit admission, revocation, and stale/replay rejection. A verified proposal does not mutate state. Commit rechecks authority and currentness without an actor suspension between checks and mutation.

Twelve deterministic XCTest cases include six independently generated canonical vectors and rejection cases. This is a new synthetic semantic reference, not the private benchmark engine or a model. It performs no training, tensor execution or performance benchmark.

On macOS with Swift 6 or newer:

```sh
swift test --scratch-path ../foundation-build
```

A bounded example (inside an async Swift context):

```swift
import ChangeFoundation
let initial = try State(lineage: 1, generation: 0,
                        entries: [Entry(id: 1, value: 10)], order: [1])
let authority = ReferenceAuthority(initial: initial)
let capability = await authority.issueCapability()
let proposal = CandidateTransition(lineage: initial.lineage,
    baseGeneration: initial.generation, baseCommitment: initial.commitment,
    entries: initial.entries, order: initial.order)
let checked = try await authority.verify(proposal, using: capability)
let committed = try await authority.commit(checked, using: capability)
// committed.generation == 1; checked.change.isEmpty == true
```

This synthetic empty-content transition still advances the generation. Possession of the actor is trusted issuer access; the example provides no external authentication.

`PracticeLedger` is the first SDK piece taken from MasteryKit's practice loop. It commits the fields `TutorSession.submit` consumes — event id, skill id, surface, lesson kind, score, timestamp, optional confidence — and does not implement readiness, selection, or the vendored engine. See the [practice ledger](docs/practice-ledger.md).

```swift
import ChangeFoundation
import PracticeLedger
let ledger = try PracticeLedger(lineage: 1)
let capability = await ledger.issueCapability()
let event = try PracticeEvent(
    id: "rect-area-2x3", skillID: "rect-area", surface: .problems,
    kind: .workedExample, score: 1, timestampMs: 1_700_000_000_000)
let checked = try await ledger.verifyAppend(event, using: capability)
let committed = try await ledger.commit(checked, using: capability)
// committed.generation == 1; committed.events.count == 1
```

`verifyAppend` does not append. A duplicate event id is a `PracticeRejection`, not an authority `Rejection`. Equal evidence across two ledgers still grants no commit rights.

`OracleAdmission` is the agentcraft connection: a practice score is sealed only when distinct witness families agree and do not share a dependency. Abstaining does not touch the ledger, and a seal is not a commit. Agentcraft-app is not imported. See [oracle admission](docs/oracle-admission.md). The Linux hash choice is recorded in [the CryptoKit assessment](docs/cryptokit-assessment.md). Ur and backgammon are assessed in [game evidence](docs/game-evidence-assessment.md): the next piece is a moment surface for a board commit, not either rules engine. Rust parity and WASM are in [Rust parity](docs/rust-parity-assessment.md). `rust/commitment-reader` 0.1.0 recomputes the committed Python hashes exactly, and the same crate builds to WASM. It does not ship inside the Swift ledger and it does not commit.

No external package dependencies are fetched. The Swift standard library, Foundation and, on Apple platforms, CryptoKit are execution dependencies. The Linux Swift toolchain does not ship CryptoKit, so that build hashes with an in-tree SHA-256; the canonical vectors are the check that the digest matches. The synthetic vector generator uses Python's standard library solely as an independent byte-encoding/hash reference; it is not a runtime dependency.

For application integration, see the [consumer integration guide](docs/consumer-integration.md), informed by the bounded CIT-01 study. It separates consumer semantic validation from reference admission, scope and commit behavior.

## Limits

This is software reference behavior, not formal verification, hardware isolation, authentication, a production service or universal acceleration. The trusted holder of the authority actor can issue capabilities. Capabilities are epoch-scoped; each verified proposal is generation-bound. Commit history is in-memory only. Public evidence, hashes and equality never grant authority. UUID collision resistance and SHA-256 assumptions are not proofs. Resource limits, persistence, distributed concurrency and production hardening are unimplemented.

Primary research evidence remains privately retained and awaits verified archival; this public dataset is a derivative, not a replacement. Private paths, Git history, model data and raw payloads are excluded. Research integrity and runtime authority are separate boundaries.

Start with [architecture](docs/architecture-principles.md), [authority](docs/authority-model.md), [canonical reference](reference/README.md), and the [roadmap](docs/roadmap.md). No later roadmap phase is implemented by this release preparation.

## SDK scope and evolution

The [SDK v0.1 scope](SDK-v0.1-SCOPE.md) separates immutable evidence, versioned interpretation, evolvable contracts and editable implementation. Significant contracts trace through research findings, post-hoc conclusions and synthetic reference coverage into a proposed release basis. Future accepted research can change contracts through an impact review and a new version; it cannot rewrite the provenance of an earlier release.

The retained `ChangeFoundation` module is a tested synthetic prototype, not the final SDK module layout. `PracticeLedger` is later editable implementation on that reference; it does not revise this scope checkpoint or add a backend.

## License

Copyright 2026 Ergentics, LLC

Licensed under the **Apache License, Version 2.0**. See [LICENSE](LICENSE) for the complete terms and [licensing](docs/licensing.md) for coverage and redistribution guidance. SPDX license identifier: `Apache-2.0`.

Apache-2.0 is the approved license for this candidate's code, documentation, schemas and synthetic vectors, to the extent covered by licensable rights. The custom Ergentics License Candidate 0.1 was not adopted and remains a private historical design/review artifact. License adoption does not approve every future tree. Maintenance of this branch is on `https://github.com/Ergentics/ergentics-foundations`, and the checks that run with it are in [Contributing](CONTRIBUTING.md).
