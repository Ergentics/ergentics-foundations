# Practice ledger

`PracticeLedger` is the first SDK piece taken from MasteryKit. It is an editable implementation on top of the v0.1 reference. It does not revise the E01–E26 acceptance claim, and it does not make this repository a production mastery engine.

MasteryKit's public loop submits one record at a time: event id, skill id, surface, lesson kind (`WE` / `PF` / `RP`), a unit-interval score, a timestamp, and an optional confidence flag. `TutorSession.save` then writes those fields to a JSON file. A successful encode is not admission. This module keeps that submit record and commits it through `ReferenceAuthority`.

The vendored MasteryKit kernel is not in this repository. Readiness, selection, the prerequisite graph, lessons, and the SwiftUI session stay in MasteryKit. Viewer fields on the loop schema — stem, prompt, canonical answer, authored context — are not in this record. They are display data. Putting them here would require a canonical JSON or CBOR profile, which the v0.1 scope defers.

## What a caller does

```swift
import ChangeFoundation
import PracticeLedger

let ledger = try PracticeLedger(lineage: 1)
let capability = await ledger.issueCapability()
let event = try PracticeEvent(
    id: "rect-area-2x3", skillID: "rect-area", surface: .problems,
    kind: .workedExample, score: 1, timestampMs: 1_700_000_000_000)
let ticket = try await ledger.verifyAppend(event, using: capability)
let committed = try await ledger.commit(ticket, using: capability)
```

`verifyAppend` does not append. `commit` rechecks the ticket and returns a snapshot decoded from the committed carrier. `commitRecording` performs that same mutation and also returns the predecessor `StateID`, the successor id, and the change flags. The record is not kept. `verifySamePayload` admits the current events again: generation and the state commitment advance, and the relation commitment does not. That is the reference's empty consequential change, applied to a practice log.

`PracticeRejection` is the record's own failure (empty id, score out of range, duplicate event id, corrupt carrier). `Rejection` is still the authority's failure (stale generation, replay, revoked capability, wrong issuer). A duplicate id is thrown before verify, and the snapshot is unchanged.

Possession of the actor is trusted issuer access. Two ledgers with equal evidence cannot spend each other's tickets. Evidence remains knowledge.

Bootstrap `init(lineage:generation:events:)` creates a new issuer at that snapshot. It does not restore capabilities, consumed tickets, or a disk file.

## Language lessons applied

The record is Swift, because that is the language of the reference and of MasteryKit. The other attached language repositories contributed constraints, not a second runtime.

- **Swift.** Public fields are `let`. MasteryKit's loop event uses `var`, so a caller can change a score after the value exists. Failable initializers reject a non-finite or out-of-range score before any authority call. Commitments use the explicit big-endian carrier already in `ChangeFoundation`; they do not hash a Swift value's memory layout. The actor does not keep a cached event array across an `await`, because an actor method can re-enter at that suspension and a cached array would become a second source of truth.
- **Rust.** `EventID` and `SkillID` are distinct wrappers, the same idea as `NonZero<T>` making an illegal bit pattern unrepresentable. An empty identifier cannot be constructed. A skill id cannot be passed where an event id is required. Lesson kind and surface are closed enums, not open strings.
- **CPython.** `Py_LIMITED_API` keeps a stable surface smaller than the interpreter's object layout. This module does the same with the practice record: the public values are the submit fields, and the chunked `Entry` carrier stays internal. Callers import `ChangeFoundation` only because tickets and capabilities are reference types, not because they assemble chunks. The loop schema's free JSON context value is not ported. That decoder tries a boolean before an integer, so a JSON `true` is not a number; a practice commitment should not depend on that ambiguity.
- **Ruby on Rails.** `ActiveRecord::Persistence#save` writes a row when validations pass. A row write is not the foundations commit. This ledger has no database adapter. Encoding the log does not mutate it.

## Canonical profile

`reference/make_practice_vectors.py` builds the bytes with Python `struct` and hashes them with `hashlib`. Swift tests compare those hashes through the public state commitment. The profile is:

1. ASCII `PL-LOG-v1`, a zero byte, then a big-endian unsigned event count.
2. Each event, in submission order: length-prefixed UTF-8 id, length-prefixed UTF-8 skill id, one surface byte (`problems=1`, `quiz=2`, `recall=3`, `moment=4`), one kind byte (`WE=1`, `PF=2`, `RP=3`), IEEE-754 binary64 score in big-endian bits, big-endian signed timestamp milliseconds, one confidence byte (`absent=0`, `false=1`, `true=2`). Bytes 1–3 are unchanged. Byte 4 means the score came from a stage commit. The log still does not contain the position, the move, or a regret in the game's own units.
3. UTF-8 identifiers are 1...256 bytes, contain no `U+0000`, and are not Unicode-normalized. `-0` is not a canonical score; the constructor stores it as `+0`, and the decoder rejects the negative-zero bit pattern.
4. The log is zero-padded to a multiple of 8 bytes. Chunk `i` (1-based) is a signed 64-bit entry id. Those entries are then wrapped in fixed-binary state v1. Lineage and generation are not inside `PL-LOG-v1`.

Chunk ids are positions. They are not hashes of event ids, so two ids cannot alias. Reordering events changes the relation. This adapter does not demonstrate the reference's order-only relation split; `verifySamePayload` is the empty-change case instead.

## Limits

Process-local, in-memory, synthetic. No mastery math, no next-item choice, no taxonomy, no disk, no expiry, no distributed authority. A committed score is the caller's number. This module does not check that the number is the subject's true result. Callers who want that check use [oracle admission](oracle-admission.md), which can abstain without appending. Resource bounds beyond the identifier cap are unimplemented. The v0.1 combined admission path is unchanged: `verifyAppend` checks the capability and the current base together, and a pure authority-free validation result is still deferred.
