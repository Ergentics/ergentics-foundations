# Security boundary

This is a single-process Swift semantic reference. Holding `ReferenceAuthority` is trusted bootstrap access and allows capability issuance. The module does not authenticate users or defend against code executing with access to the process, memory corruption, hostile toolchains or a compromised host. It supplies neither hardware enforcement nor a network security boundary.

Capabilities and verified transitions are opaque, non-Codable objects. Knowledge of a commitment, an evidence record or a candidate never creates these objects. Verification and commit are distinct; commit checks current issuer, revocation epoch, originating capability, receipt use, lineage, generation and commitment. A capability may authorize successive generations within its epoch; each verified transition is tied to one base generation.

Do not use this reference to protect production secrets or irreversible remote operations. No private vulnerability-reporting endpoint is configured yet. Do not post credentials or confidential reproductions in public issues; a reporting channel must be designated by the owner before production use.

The independent export review is a bounded inspection of exact files, not proof that a host, compiler, cryptographic library or dependency is uncompromised. No exhaustive supply-chain verification is claimed.
