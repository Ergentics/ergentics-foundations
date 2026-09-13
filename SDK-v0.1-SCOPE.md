# Ergentics Foundations SDK v0.1 scope

**Foundation acceptance: YES_WITH_LIMITATIONS.** E01–E26 support a bounded set of developer-facing identity, proposal, current-admission and commit distinctions. They do not establish a production SDK, general proof engine, canonical CBOR profile, global object model, distributed authority system, or economically beneficial validation-result cache. This document extracts contracts; it authorizes no new implementation.

**Non-claim.** Foundation acceptance means there is sufficient evidence to define a bounded SDK contract surface. It does not certify production readiness, security completeness, formal correctness, distributed authority, performance benefit, or suitability for safety-critical use.

The intended repository is **ergentics-foundations**, a public research-derived, evolvable SDK/foundation. The private research explains why; the proposed contracts describe what survived and how to use the small reference safely. A future release may evolve these contracts without rewriting the evidence or meaning of an earlier release.

E01–E26 remain **CLOSED AFTER E26**, E27 is not nominated or started, and economic exhaustion is **UNKNOWN**. E26 remains **H. MEASUREMENT DECOMPOSITION INCONCLUSIVE**. No speedup was tested in E26. Its unknowns do not block successor work.

## 1. Four independently versioned layers

| Layer | Meaning | Change rule |
|---|---|---|
| Immutable research evidence | Accepted observations, failures, manifests, receipts and original experimental classifications | Preserve original identities and historical meaning; never rewrite to improve a release narrative |
| Versioned research interpretation | Post-hoc graph, persistence taxonomy, operating-region map and stated limitations | New interpretation may supersede a prior interpretation through a named version; original remains available |
| Evolvable SDK contracts | Public definitions, wire profiles, rejection rules, applicability and compatibility policy | Explicit version, contract-impact review, deprecation/migration notes and new reference cases |
| Editable implementation | Swift code, storage/backend adapters and implementation strategy | May change while preserving a release's semantics; changed semantics require versioned contract review |

Lifecycle: **frozen research checkpoint → post-hoc interpretation → SDK release N → future accepted research → contract-impact review → SDK release N+1**. Future evidence can split a type, narrow/broaden generation applicability, add evidence relationships, revise invalidation or enable a new backend. Preserve the old release and its research provenance. Such future research need not be called E27.

### 1.1. Versioning and compatibility rules

These are proposed release rules; this document does not publish a release or select its exact version.

- Additive types or fields qualify for a minor release only when existing semantics, valid encodings, identity preimages and consumer acceptance remain compatible. An added field that changes canonical identity or breaks a strict decoder is a breaking change, not automatically a compatible addition.
- Changes to generation, validation, authority or identity semantics require a major release at 1.0 or later, or an explicitly declared pre-1.0 breaking release with migration notes. A pre-1.0 breaking release advances the minor version; it must never be disguised as a patch.
- Implementation-only fixes that preserve the normative contracts and reference vectors qualify for a patch. Vector agreement alone is necessary but does not prove every behavioral contract unchanged.
- New accepted research that changes a contract's meaning requires a contract-impact review before release classification. Preserve the earlier evidence, interpretation, release and reference suite; record the new basis and migration/deprecation consequences.

## 2. Proposed contract set

The machine-readable `sdk-contract-candidates.json` is the normative scope inventory for this proposal. Every entry provides definition, research basis, invariants, generation binding, persistence, invalidation, authority implications, developer purpose, limitations, origin and actual reference coverage.

**Normative for this bounded v0.1 scope proposal:** the contract matrix's decisions/invariants, the fixed-binary profile described in `reference/README.md`, the rejection semantics explicitly specified here and in `docs/authority-model.md`, and the existing synthetic canonical vectors plus named reference-test expectations. These define the candidate's covered subset, not unimplemented production guarantees.

**Informative:** research-basis/origin explanations, the post-hoc graph, operating-region analysis, future backend/storage abstractions and proposed implementation structure. Their presence creates no runtime requirement. Historical measurements never override a contract, grant authority or certify a future implementation.

The amendment's §8 lists **16** named concepts. This review adds **ReferenceVerifier**, separately requested in §12, as the seventeenth evaluated component. DeltaBackend and ObjectStore remain separate conceptual boundaries, not hidden implemented types.

| Candidate | Decision | Actual bounded reference or gap |
|---|---|---|
| Generation | ACCEPT_WITH_LIMITATIONS | UInt64 revision fields; no dedicated type; successful empty commits advance by engineering convention |
| State | ACCEPT_WITH_LIMITATIONS | Immutable synthetic ID/value entries and separate exact order |
| StateID | ACCEPT_WITH_LIMITATIONS | Proposed lineage/generation/commitment identity; no wrapper type |
| Transition | ACCEPT_WITH_LIMITATIONS | Proposal plus committed successor; no durable transition record |
| CandidateTransition | ACCEPT | Existing public proposal fields; acceptance is a semantic contract decision, not production certification |
| ConsequentialChange | ACCEPT_WITH_LIMITATIONS | RelationChanged/orderChanged flags only; no tensor delta engine |
| Evidence | ACCEPT_WITH_LIMITATIONS | Inspectable state/relation commitments; not a general verified witness |
| Relation | ACCEPT_WITH_LIMITATIONS | Synthetic ID/value association; not the private backing-vector schema |
| Representation | INTERNAL_ONLY | Keep exact encoding explicit; do not expose E26 layouts or construction capsules as generic APIs |
| ValidationResult → **AdmissionResult** (proposed public name) | ACCEPT_WITH_LIMITATIONS | Current VerifiedTransition is a private co-admission ticket; a pure ValidationResult remains deferred |
| Capability | ACCEPT_WITH_LIMITATIONS | Process-local private issuer/epoch permission; not external authentication |
| Authority | ACCEPT_WITH_LIMITATIONS | Trusted reference actor and current head/epoch; no hardware boundary |
| Commitment | ACCEPT_WITH_LIMITATIONS | Versioned fixed-binary SHA-256 preimage; not authority or collision-free proof |
| CommitResult | ACCEPT_WITH_LIMITATIONS | State return or typed rejection; dedicated/durable result type absent |
| ObjectID | DEFER | No canonical global object profile, namespace or migration rules yet |
| EvidenceRoot | ACCEPT_WITH_LIMITATIONS | Provenance descriptor of commitment kind/algorithm; no runtime proof-tree API |
| ReferenceVerifier | ACCEPT_WITH_LIMITATIONS | Immediate-base/domain/capability checks; no recursive parent/witness proof engine |

Fourteen entries have limitations, one is accepted, one remains internal and one is deferred. These decisions evaluate contract maturity, not public API implementation count. An accepted contract without an implemented type remains a proposal; no code is added here merely to fill the matrix.

Research-derived distinctions are not equivalent to research-derived API syntax. `RESEARCH_DERIVED` identifies the supported semantic lesson; `ENGINEERING_DERIVED` labels a new representation/API convention; `COMPATIBILITY_DERIVED` labels adaptations needed to preserve semantics across language or transport boundaries. The matrix explicitly classifies fixed binary encoding as engineering, integer-preserving JSON transport as compatibility work, and the Swift adapter as a language choice. No engineering preference is presented as an experimental finding.

## 3. Semantic flow and the current deviation

The intended conceptual separation is:

**State → CandidateTransition → Verify → Authorize → Commit**

**First-class invariant: structural persistence does not imply authority persistence.**

Proposal is not validation; validation is not authority; authority is not commit. Historical validity is not current authority. Representation equality is not semantic applicability. Knowledge is not authority. A numerical backend result is neither automatically validated nor an authorized commit.

The existing synthetic reference implements a **combined admission step**: `ReferenceAuthority.verify(candidate, using: capability)` checks the capability and candidate's immediate current base, then creates a private `VerifiedTransition` ticket. It does **not** expose independent pure Verify and Authorize APIs. `commit(ticket, using: capability)` rechecks issuer, capability identity/epoch, unconsumed ticket and current base before advancing the actor's state, with no suspension between checks and mutation.

The evaluated candidate retains the historical matrix ID `SDK-ValidationResult`, while its proposed public-facing name is **AdmissionResult**. The name describes the current authority-entangled co-admission outcome. This is an engineering naming proposal; it neither renames the implemented `VerifiedTransition` nor creates a new runtime type. A pure authority-free ValidationResult or VerificationOutcome remains deferred until the Verify/Authorize split has its own reviewed contract.

This deviation is retained and explicitly documented. It preserves the conceptual distinction between proposal and commit and exercises revocation/currentness at use, but it does not prove a general split authorization architecture. A future API split would require a scope-bearing pure validation result, a separately issued admission capability/ticket, expiration/revocation policy and new contract-impact review. Do not rename the existing co-admission ticket into a supposedly authority-free result without changing its semantics transparently.

The trusted bootstrap boundary is possession of the actor: its holder can issue capabilities and revoke them. That is a small reference convention, not authentication, process isolation, cryptographic identity, a microkernel or hardware enforcement. Capability epochs are separate from state generations; a capability can remain epoch-current across state commits while each ticket remains bound to its own candidate base.

## 4. Canonical representation and identity

Retain the reviewed **fixed-binary canonical v1** as the current synthetic reference profile. It encodes ASCII domain tags, big-endian UInt64 fields/counts, signed Int64 values by two's-complement bit pattern, ID-sorted relation entries and explicit state order, then SHA-256. Six independent synthetic vectors cover the profile, including signed bounds and empty domain. Do not hash native Swift memory layouts.

**Deterministic canonical CBOR: DEFER.** It is a candidate future interoperability format, not an E01–E26 result or an implementation already validated here. Adoption would require an exact supported-type/canonicalization profile, equivalence and rejection rules, domain/version rules, independent cross-language byte vectors and migration consequences. A canonical-format change would change identity preimages unless a separately specified migration says otherwise. No CBOR library, encoder or performance experiment is introduced by this amendment.

Typed schemas are useful at the proposal/evidence transport boundary, but passing JSON shape checks alone is not semantic admission. The existing schemas require integer-preserving decoding for the full UInt64/Int64 ranges; no general JavaScript or other-language round trip has been tested. A canonical ObjectID and canonical transition ID remain future engineering work rather than aliases silently assigned to the current toy integers or random private ticket IDs.

`EvidenceRoot` must identify its commitment kind. E26's value

`34d3858e8f40e84f2effbba4852de4a0d8a4ff7bc1581280632c6cdee7d41a12`

is a **canonical inventory SHA-256 commitment, not a Merkle root**. It grants neither runtime permission nor permission to reclaim the only recoverable evidence. A future tree proof would require its own construction and verification contract. Storage location and an SQLite row/index never define semantic object identity. SQLite is only a possible future storage implementation, not a required dependency.

## 5. Reference verifier validity scope

A useful general design decomposition is:

`Validity = TypeCorrect AND ParentsValid AND TransitionAdmissible AND CommitmentValid AND WitnessValid`

The current implementation covers only a bounded specialization:

| Clause | Current evidence | Unimplemented/general scope |
|---|---|---|
| TypeCorrect | Swift types plus unique IDs and exact order-domain validation | General typed-object/wire validation and adversarial parser profile |
| ParentsValid | Immediate candidate lineage/generation/base commitment matches current head | Recursive ancestry, arbitrary parent DAG and independently verified parent history |
| TransitionAdmissible | Valid domain, current base and generation increment without overflow | General transition algebra, policy and cross-object invariants |
| CommitmentValid | Exact match to recomputed current state commitment; six canonical fixture checks | Arbitrary content-addressed object/witness graphs and CBOR identity |
| WitnessValid | Private capability/ticket binding checks in the combined admission path | General public Evidence verification, signatures, attestations and arbitrary witness proofs |

Do not claim that the generic five-clause verifier exists. The current public `Evidence` is freely constructible and contains two commitments; it is not parsed and independently verified as a general witness.

Reference failures are typed rejections for domain, lineage, generation, commitment, capability, replay and exhaustion. The existing cases exercise rejected operations and selected no-mutation checks; this is not an exhaustive fault-atomicity or memory safety proof. Commit's recheck rejects a pending sibling after another candidate advances the head. Consumed-ticket replay is process-local; there is no durable restart registry, wall-clock expiry or remote capability scheme. Authority-epoch overflow is guarded in source but was not reached in execution. No formal verification or hardware enforcement is claimed.

## 6. Synthetic reference suite and gaps

`research-to-sdk-traceability.json` maps exact method IDs to the retained **12 XCTest cases**, and exact vector IDs to the **six canonical JSON vectors**. These are already executed engineering reference checks with retained PASS evidence. This amendment did not run new tests. They are synthetic and do not disclose private primary E-series values.

The covered bounded cases include successful/empty transitions, entry/value changes, stale proposals, replay, order-only relation persistence, wrong lineage/current commitment, wrong capability, revocation between verify/commit, identical evidence under different private authorities, domain errors and generation exhaustion. The six canonical vectors are synthetic-base, synthetic-order-change, synthetic-source-change, synthetic-empty-transition, synthetic-signed-bounds and synthetic-empty-domain.

Explicit gaps:

- Wrong immediate parent is partially represented by base commitment/lineage rejection; recursive parent validation is absent.
- Sibling authority and a wrong lineage field are checked; a complete branching lineage/ancestry graph is not implemented.
- Equal inspectable evidence cannot supply another authority's rights; arbitrary witness validity is not tested.
- Revocation and invalid capability are tested; wall-clock expiration is not implemented.
- Accepted/rejected reference commits are tested; durable commit receipts, crash recovery and replay across restart are absent.
- No direct vector exists for a canonical ObjectID, generic EvidenceRoot runtime type or general persistence/decay API. These are not fabricated as covered cases.

The minimal currently supported suite is retained. Missing production/general requirements are deferred to future versioned SDK work, not blockers to preserving this scoped reference.

## 7. Backend and storage independence

**DeltaBackend — conceptual ACCEPT_WITH_LIMITATIONS.** A future execution adapter should receive an explicitly scoped computation request and return proposed output plus whatever execution metadata its contract declares. A numerical result does not decide semantic applicability or authority. A verifier/authority boundary must separately establish which output may enter a committed transition. Determinism, cancellation, evaluation/synchronization, errors, dtype/shape and effect reporting need concrete adapter contracts before implementation. ReferenceBackend, CoreAIBackend, MetalBackend and RemoteBackend are future possibilities; none is implemented by this scope.

The present reference does not execute tensors or neural models. E03 supports separation of tensor execution from semantic identities/first-party graph ownership, but it does not validate these proposed production adapters. Core AI remains future numerical/model execution, not semantic authority.

**ObjectStore — conceptual ACCEPT_WITH_LIMITATIONS.** A future store may retain/retrieve versioned object bytes and metadata under an explicit identity profile. Retrieved bytes are untrusted until required commitment/schema checks pass; storage success grants no commit permission or validity. LocalObjectStore, R2ObjectStore and S3CompatibleObjectStore are candidates only. Persistence, durability, read consistency, error behavior, size limits and archive restoration require separate design/testing. No storage implementation, credentials, R2 buckets, Workers, services or deployment is created. Cloud storage is not authority. An archive's existence or hash does not establish recoverability by itself.

## 8. Language and actual repository structure

Swift is a reasonable initial implementation language for the planned Apple-native work and the existing small reference. **Swift implementation is not the semantic definition.** Wire identity rules and synthetic vectors should remain independently expressible. Actor syntax, UUID allocation and CryptoKit are implementation choices, not requirements that every future language mimic native Swift layout.

Recommend retaining the current single Swift package/module and tests while adding these scoped documents and JSON design records. The existing `Sources/ChangeFoundation` and `Tests/ChangeFoundationTests` contain the bounded reference; its name need not be changed merely because the repository is called `ergentics-foundations`. A later reviewed package/API rename is a compatibility decision. Keep existing proposal/evidence schemas, `reference/` vector recipe, `docs/` research/architecture material, and a small `paper/` public post-hoc summary. Retain SDK-v0.1-SCOPE.md and its three linked JSON design records at repository root as the release-basis entry point; detailed research/architecture docs remain in docs/. Do not create empty ErgenticsCore/Verifier/Graph/Reference modules, examples or backend folders to imitate a speculative structure.

The proposed release-basis record is **SDK 0.1.x**, exact version not yet selected. It binds E01–E26, closed-series status, unchanged E26 classification, post-hoc/graph hashes, proposed contract-matrix hash, existing vector identity and known limitations. It is a proposal, not a published release or runtime admission receipt.

## 9. Traceability and acceptance

The traceability chain is **ResearchFinding → PostHocConclusion → SDKContract → ReferenceVector/Test → SDKRelease**. Each significant contract includes origin and evidence IDs. Missing reference coverage is explicit; no empty link means proof. Thus traceability can pass for documented origin/coverage while implementation remains partial.

Acceptance is **YES_WITH_LIMITATIONS**: mature semantic distinctions justify a scoped public foundation and editable contracts. Preserve internal representation machinery, defer canonical ObjectID/CBOR/general witness or parent proofs, and leave backend/store production work unimplemented. E26's lack of a nominated next optimization does not block these contracts or prove universal necessity/redundancy of validation.

This amendment prepares a publication-ready surface, not a public push. The fresh export must undergo its own complete review after the new documents/license are assembled. No private Git history may enter it. Apache License 2.0 has been separately approved for this public candidate, with Copyright 2026 Ergentics, LLC; the custom Ergentics License Candidate 0.1 was not adopted. This licensing update does not change the SDK contract scope or accepted research conclusions. The exact final public tree and repository owner still require human approval. No GitHub remote, public push, new research series or next major implementation is authorized here.
