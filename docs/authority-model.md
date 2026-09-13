# Authority model

`Evidence` contains public state and relation commitments. Anyone can construct that record. `Capability` and `VerifiedTransition` have module-private constructors and are not serializable. Serialization schemas intentionally provide no capability reconstruction path.

The actor holder is the trusted issuer. A capability binds issuer, identifier and current revocation epoch; it is reusable within that epoch. A verified transition additionally binds the capability identifier, a unique receipt identifier, the exact candidate's base lineage/generation/commitment, and the observed consequential-change flags. It grants no mutation until consumed through commit.

Commit performs checks and mutation without suspension. Revocation after verification rejects the old receipt. A new capability cannot consume an old capability's receipt. Two receipts for the same base generation cannot both commit: the second becomes stale. Reusing the exact consumed receipt reports replay. Sibling authorities with identical visible states cannot interchange receipts or capabilities.

This is a process-local software contract, not authentication or non-forgeability against a compromised runtime. There is no time expiration; revocation is epoch-based. Generation overflow is rejected and tested. The epoch-overflow guard exists but is not reached by the bounded suite. The consumed-receipt set grows without compaction; resource bounds and restart/recovery semantics are unimplemented.
