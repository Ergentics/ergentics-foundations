# Synthetic reference vectors

`make_vectors.py` independently constructs canonical bytes with Python `struct` and hashes with `hashlib`. Its six generated cases are retained in `Tests/ChangeFoundationTests/vectors.json`. Swift tests use public APIs to compare all twelve expected state/relation hashes. No private record, model or identifier was copied into the cases.

Canonical relation bytes are ASCII `CF-RELATION-v1` followed by a zero byte, an unsigned 64-bit big-endian entry count, then sorted pairs of unsigned 64-bit ID and signed 64-bit value encoded as two's-complement bits. State bytes are ASCII `CF-STATE-v1` followed by a zero byte, unsigned big-endian lineage and generation, the complete relation bytes, an order count and ordered unsigned IDs. Hashes are lowercase SHA-256 hexadecimal. The byte format, not JSON serialization, defines the commitment.

The cases cover base state, order-only change, value change, an empty consequential transition, signed/unsigned bounds and an empty domain. XCTest additionally checks stale/replay rejection, revocation between verification and commit, sibling authority, two pending receipts, a different current capability, malformed domains and generation overflow.

The JSON transport represents UInt64/Int64 numbers exactly in Swift and Python. Consumers with IEEE-754-only JSON numbers must use an integer-preserving parser; rounding a value is invalid. JSON schema shape validity never grants authority or replaces runtime domain validation.

`make_practice_vectors.py` builds the separate `PL-LOG-v1` practice-log profile, chunks it into this same state carrier, and writes `Tests/PracticeLedgerTests/vectors.json`. It does not replace the six vectors above. The practice profile is specified in [the practice ledger note](../docs/practice-ledger.md).
