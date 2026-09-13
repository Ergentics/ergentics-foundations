# Terminology

| Term | Meaning in this reference |
|---|---|
| Generation | Unsigned monotonic logical version within a lineage; no wraparound |
| State | Lineage, generation, unique ID/value entries and their requested order |
| Relation | Sorted ID/value entries independent of requested order |
| CandidateTransition | Proposed replacement entries/order tied to an exact current base |
| ConsequentialChange | Separate relation-change and order-change flags |
| Evidence | Serializable public commitments, without authority |
| Capability | Opaque issuer/epoch permission within the trusted process boundary |
| VerifiedTransition | Opaque candidate-specific, generation-bound admission receipt |
| Commit | Fresh admission and atomic current-state advance |
| Commitment | SHA-256 of explicit versioned canonical bytes, not permission |
| Post-hoc graph | Evidence-linked historical derivative, not primary evidence or runtime policy |

Numerical delta, dependency delta, observed delta and storage delta remain distinct research concepts. This Foundation does not implement tensor deltas or transfer logical counts into hardware claims.
