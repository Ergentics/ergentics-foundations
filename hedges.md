# Hedges

These are the boundaries the public SDK does not cross. A new type can be added inside them. A change that needs to cross one has to say so in the commit and treat it as a contract change, not as a quiet improvement.

The code on `main` is the reference for each hedge. This file does not add behavior.

## Identity is not authority

`StateID` is lineage, generation, and the canonical state commitment. Two values with the same id have the same declared snapshot. That match does not make one issuer accept the other's ticket. `Evidence` is the same kind of fact: it can be constructed by anyone, and it does not commit.

A hash is a commitment to the stated bytes. It is not a proof of collision resistance, not a signature, and not permission.

## A seal is not a commit

`OracleAdmission` can abstain or return a verified ticket. Abstaining does not call the ledger. The ticket still has to be committed. Verification does not append.

`CommittedTransition` and `PracticeCommit` describe a commit that already happened in this process. They name the predecessor id, the successor id, and the change flags. They are not retained as a log, and holding one does not authorize another commit. `commit` is that same mutation and returns only the resulting state or snapshot.

Witness agreement is a count of distinct family names and a check that a dependency id is not shared. It is not a proof that the witnesses used different mathematics. `safety_class` is not implemented here.

## A moment is not a position

`PracticeSurface.moment` means the unit score came from a stage commit. The log does not store the board, the move, or a regret in the game's units. Ur and backgammon keep their engines, their thresholds, and the `0.85` / `0.2` calibration. Those numbers are not a public contract.

`problems`, `quiz`, and `recall` remain the other surfaces. Byte 4 does not rewrite their vectors.

## The reader is not the ledger

`commitment-reader` 0.1.0 recomputes `CF-STATE-v1` and `PL-LOG-v1` and must match the Python vectors exactly. The WASM build hashes those same bytes outside the Swift process. It does not issue a capability and it does not commit. Swift still ships the ledger. The reader is not a Swift package dependency. `CommitmentProbe` can be built by the same Swift 6.4.1 compiler for `wasm32-unknown-wasip1`. That probe prints one commitment and does not call the actor. It is not a second issuer, and it does not replace the Rust reader. The probe check uses Node 26.12.0. `node:wasi` there still warns that WASI is experimental and might change at any time. That warning is not a hash and not a stable WASI contract. `demos/recital/` plays two constructions in the browser: the Rust reader, and `CommitmentGuest` from the embedded WebAssembly SDK. Both construct the synthetic-base state. The page does not copy one hex into the other, and it does not commit. The 60 MB WASI command is not that guest.

UniFFI is not the parity method. FSRS and `fsrs-rs` are not this package's memory model.

## Possession is not authentication

The holder of `ReferenceAuthority` or `PracticeLedger` can issue capabilities. That is process-local issuer access. It is not user authentication, hardware isolation, or a network authority. Capabilities are not serializable. A reconstructed ticket is not a goal of this SDK.

## Checks are not the scan

`.github/workflows/check.yml` runs the Swift package and the Rust reader. A green run is the merge check for those paths. It is not performance evidence. The benches print timings under a declared control. CI runs them for 2 iterations only to prove the binary starts. Those numbers are not a gate. A data run records one frozen local pass and does not start a roadmap phase. See `docs/benchmarks.md` and `docs/data-run.md`.

CodeQL's default setup on `main`, including the Swift slot named `/language:swift`, is GitHub's scan. It is not a file in this repository and not a gate for the package. The summary can warn that the Swift configuration is missing while Autobuild is still running. That warning is not a failed `swift test`.

## Agreement is not ordered reuse

`TargetContinuity` keeps ordered vector equality, multiset equality, and common occurrence/backing agreement as separate counts from `EV-E26-CONTINUITY`. The written statement is already in `docs/e01-e26-public-synthesis.md`. The twelve dataset rows repeat across two sweeps and three observer levels. They are per-process transition and occurrence counts. They are not independent replicates, and the three predicates are not one equality. Multiset equality and a complete common-agreement ratio do not license reuse of the ordered validation product. This type loads the retained rows. It does not replace the synthesis, rerun E26, or report a speedup.

## A candidate is not E27

`docs/e27-candidates.md` lists open questions after the closed E01–E26 series. Each one is `NOT_NOMINATED`. `E27Started` stays false. The closeout describes the evidence in hand at that time. It is not a universal rule against new evidence. A speedup trial of the unsplit loop is not the next measurement. `CleanAttribution` separates four public-reference sinks. That separation is not a decomposition of the private E26 loop and not a speedup. The list does not add a graph edge, choose the largest timer, or report a speedup.

## The index is not the store

`traceability/` loads ResearchFinding, PostHocConclusion, SDKContract, reference vector and test, and SDKRelease from the committed JSON. SQLite is the local index. It is not R2, not an ObjectID, and not a canonical CBOR profile. A primary key is not a `StateID`. Nothing in that app commits. An empty vector or test list is zero links, and zero links are not proof. `PASS_FOR_DOCUMENTED_ORIGIN_AND_COVERAGE_NOT_FULL_IMPLEMENTATION` can hold while implementation is partial. `YES_WITH_LIMITATIONS` is the stored acceptance from `sdk-release-basis.json`, not a count of contracts. Deleting rows leaves the JSON unchanged.

## What stays outside

Do not import the vendored MasteryKit kernel, AgentContractKit, UrKit, or BackgammonKit. A public type may mirror a word. It does not copy a harvest, a board, or a search.

Linux hashing stays the in-tree SHA-256 until a second cryptographic operation needs Swift Crypto. Apple builds keep calling CryptoKit. Neither choice is authority.
