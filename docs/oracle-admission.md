# Oracle admission

`OracleAdmission` is the public connection from agentcraft's verify-then-abstain rule to `PracticeLedger`. Agentcraft-app stays a proprietary subject. This module does not import it, and it does not contain its harvest records, safety classifier, scaffold library, or tiling oracles.

The connection that fits is the admission boundary. A practice score in the ledger is the caller's number. Agentcraft's rule is that a number becomes a grounded result only when independent witnesses agree, and that refusing to ground it is a normal outcome. Here, that refusal is an abstention. A seal is the value the gate mints. Neither one commits the ledger.

```swift
import ChangeFoundation
import OracleAdmission
import PracticeLedger

let ledger = try PracticeLedger(lineage: 1)
let capability = await ledger.issueCapability()
let event = try PracticeEvent(
    id: "item", skillID: "skill", surface: .problems,
    kind: .workedExample, score: 1, timestampMs: 0)
let claim = ScoreClaim(
    event: event, asserted: .derived,
    witnesses: [
        try ScoreWitness(family: "bytes", dependencies: ["left"], score: 1),
        try ScoreWitness(family: "recount", dependencies: ["right"], score: 1),
    ])
let outcome = try await OracleAdmission.verify(claim, on: ledger, using: capability)
```

`JudgeResult.seal` does not append. `AdmissionOutcome.verified` is a foundations ticket. `commit` is still a separate call. `AdmissionOutcome.abstained` does not call the ledger.

## Decision order

`reference/make_oracle_vectors.py` is the non-production path. Swift tests compare its thirteen verdicts. The order is part of the contract:

1. `minimumFamilies` below 1 is `OracleInputError.minimumFamilies`, not an abstention.
2. A claim that is not `derived`, or that has no witnesses, abstains `notDerivable`.
3. A dependency id listed by two witnesses abstains `sharedDependency`. Repeating it inside one witness does not.
4. Fewer distinct `WitnessFamily` values than `minimumFamilies` abstains `tooFewFamilies`. The default floor is 2, the public two-path rule. Passing 3 raises the floor for that call. It does not create a corpus record.
5. A witness whose canonical score bits differ from the event abstains `discordant`.
6. `falsifierSettled: false` abstains `falsifierOpen`.
7. Otherwise the gate seals. `SealedScore` has no public initializer.

An empty name, an embedded NUL, or a non-finite witness score is `OracleInputError`. Those are malformed inputs. They are not abstentions.

## What this is not

This is not agentcraft's `VerifyAbstainGate`, and it is not a COMPUTABLE harvest. The private subject still abstains on `safety_class` because two of its producers share a danger ordering. That audit is not re-implemented here. Necessity of a witness is not axiomatic independence. This gate only counts distinct family names and rejects a repeated dependency id. It does not prove the witnesses used different mathematics.

`PracticeLedger.verifyAppend` still accepts a bare `PracticeEvent`. The governed path is the function above. A caller who skips it commits a caller-supplied score, which the ledger already documents.

Two paths check this table: the Swift gate and the Python script. There is no third axiom-disjoint oracle, so this module is not offered as a harvested corpus record.
