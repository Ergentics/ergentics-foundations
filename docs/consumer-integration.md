# Consumer integration with the published reference

This guide explains one bounded way to integrate `ChangeFoundation`; it does not define new SDK types or a normative application architecture. It is informed by CIT-01, classified **VALID WITH CONSUMER ADAPTER LIMITATIONS**. Meaningful adapter work was required; the study did not establish a semantic contract deficiency.

The exact SDK revision tested by CIT-01 is [`dd831fb7e4cd432c84dabc5de81ed3a391d1eac4`](https://github.com/Ergentics/ergentics-foundations/tree/dd831fb7e4cd432c84dabc5de81ed3a391d1eac4). A later documentation revision has its own file inventory; it does not change which implementation CIT-01 tested. Foundation acceptance remains **YES_WITH_LIMITATIONS**. See the [scope](../SDK-v0.1-SCOPE.md), [authority model](authority-model.md), and [reference](../reference/README.md).

**Reference boundary:** possession of `ReferenceAuthority` is trusted software issuer access. The actor is a semantic/reference mechanism, not a complete security boundary. Possession does not itself establish user authentication, process isolation, sandboxing, secure hardware authority, cryptographic identity, multi-tenant security, or production authorization infrastructure.

## Separate domain truth from admission

The following is a **conceptual integration sequence**, with actual SDK calls named explicitly:

```text
Application state / selected base snapshot
  -> Consumer proposal logic
  -> Consumer semantic validation
  -> CandidateTransition (exact payload and base binding)
  -> ReferenceAuthority.verify(candidate, using: capability)
  -> VerifiedTransition (co-admission ticket; no mutation)
  -> ReferenceAuthority.commit(ticket, using: capability)
  -> Consumer read-back, including ReferenceAuthority.snapshot()
```

Constructing a candidate earlier for inspection is also possible. What matters is that consumer validation covers exactly the source and payload eventually admitted and committed. Constructing `CandidateTransition` does not itself validate that payload or grant authority.

- Proposal != validation; validation != authority; authority != commit.
- Historical validity != current authority.
- Representation equality != semantic applicability.
- Backend/result availability != permission to commit.
- Structural persistence does not imply authority persistence.

The actual reference does **not** expose independent pure `Verify` and pure `Authorize` stages. Despite its name, `verify` combines structural/current-base checks with capability checks and returns an authority-related `VerifiedTransition`. It checks the capability's issuer and epoch, resolves lineage/generation/base commitment and the proposed state's structural domain, and binds the supplied capability ID into the ticket. `commit` checks the current capability, ticket issuer/epoch/capability-ID match, replay and current base again before mutation. No actor suspension occurs between those commit checks and mutation.

Domain validation belongs outside that reference admission path. For example, the consumer established that `3x + 2x - 4 + 7` and `5x + 3` have equal coefficients; it rejected `5x + 4`. Foundations did **not** prove the algebra. A finance consumer would validate its financial invariants, a document consumer its document semantics, and a compiler consumer its domain constraints. These are conceptual applications, not additional tested integrations.

## Responsibilities

| Responsibility | Owner and boundary |
|---|---|
| Domain semantics; business or mathematical correctness | Consumer validator. SDK structural `invalidDomain` checks do not establish application truth. |
| Application object identity and requested action/problem/session scope | Consumer; arbitrary application scope is not encoded natively by capability fields. |
| Source/payload interpretation | Consumer defines the encoding and binds the validated source/result to the exact base/payload. |
| Mapping and scope wrappers | Application integration layer maps domain objects into `State` / `CandidateTransition` and may wrap capabilities/tickets. |
| Lineage, current generation and base commitment | Foundations reference checks the candidate against its current owned state at admission and commit. |
| Capability issuer/epoch; ticket identity and applicability | Foundations reference checks issuer/epoch at admission; commit also requires the same capability ID bound into the ticket. |
| Admission and replay rejection | Foundations reference returns `VerifiedTransition` and rejects reuse of a consumed ticket, subject to preceding capability checks. |
| Commit mutation | Foundations reference mutates its owned `State`; it does not atomically update arbitrary external application storage. |
| Read-back and lifecycle adaptation | Integration layer observes the committed state and deliberately defines any mapping to application lifecycle. |
| UI, persistence and application lifecycle | Consumer. The reference does not provide these behaviors. |

## Map state and bind the validated bytes

`State` contains `lineage`, `generation`, `entries` and `order`. An `Entry` has a `UInt64` ID and an `Int64` value. `CandidateTransition` carries the base lineage/generation/commitment and proposed entries/order. A consumer must define what those fields mean for its application; neither entry IDs nor a matching digest automatically establish an application's object identity or semantic correctness.

**One bounded pattern:** CIT-01 encoded expression UTF8 bytes as positional entries/order. The adapter checked that the candidate payload matched the mathematically validated result and that the validated source was bound to the admitted base commitment. This was representation adaptation, not a new SDK encoding. Typed domain objects may need a different mapping. Do not silently validate one object and commit a separately interpreted payload.

Keep consumer errors separate from SDK errors. For example, a consumer might report `wrongMathematics`, scope or source/payload binding failures. Those are not Foundations error cases. SDK errors include `Rejection.staleGeneration`, `.invalidCapability`, `.replay`, `.wrongCommitment`, `.wrongLineage`, `.invalidDomain`, `.generationExhausted` and `.authorityExhausted`. Preserve their layer attribution; do not treat rejection as proof of non-mutation without reading back the relevant application state.

## Scope and revocation

A native `Capability` is process-local and binds issuer, identifier and revocation epoch. It does not directly encode arbitrary application object, problem, session, action or generation scope. An application-specific wrapper or domain binding **may** constrain those concepts. CIT-01's private session authority and operation-specific wrappers are one bounded pattern, not mandatory public types.

A capability may remain valid across more than one application generation unless the consumer or authority lifecycle narrows it. Current-generation applicability is checked separately through candidate/ticket/current-state semantics. Creating a fresh capability does not make an old ticket applicable, and another capability from the same current issuer cannot consume a ticket bound to a different capability ID.

`ReferenceAuthority.revokeCapabilities()` advances the issuer epoch, invalidating all capabilities from its prior epoch and preventing those tickets from committing. Revocation is **issuer-epoch-wide**, not per-capability. Consumers needing independently revocable per-object, per-action or per-session authority should account for this granularity in their integration design. That consideration is not a proven contract defect, and this guide proposes no finer-grained API. Epoch exhaustion throws `Rejection.authorityExhausted`; it is not exercised by the retained bounded test suite.

## Choose one authoritative mutation path

One bounded state transition should have one clearly identified authoritative mutation path. Avoid accidental dual authority: separately mutable consumer data plus independently mutable Foundations state, without deliberately defined synchronization semantics.

**CIT-01 pattern:** an app-owned session actor kept its private Foundations `State` as the sole mutable expression/generation store. The app read the SDK's committed result rather than updating a second independent expression store. The integration allowed one owned problem per controller and did not implement a general session-replacement lifecycle. This is an example, not a production architecture prescription.

Application/session lifetime != capability lifetime != admission-ticket lifetime. Persistence, recovery, UI updates and synchronization with other stores require separate consumer design. Actor-local atomic commit does not establish an atomic transaction across those systems or complete application concurrency safety.

## Currentness and replay: a small API example

This complete async function illustrates only the reference's currentness and replay behavior. It uses an empty-content transition: unchanged values still advance generation. A real consumer would separately validate and bind its domain result before admission.

```swift
import ChangeFoundation

func demonstrateCurrentness() async throws {
    let initial = try State(lineage: 1, generation: 0,
        entries: [Entry(id: 1, value: 10)], order: [1])
    let owner = ReferenceAuthority(initial: initial)
    let capability = await owner.issueCapability()
    let candidate = CandidateTransition(lineage: initial.lineage,
        baseGeneration: initial.generation,
        baseCommitment: initial.commitment,
        entries: initial.entries, order: initial.order)

    // Both tickets are admitted against S_n. Neither changes current state.
    let oldTicket = try await owner.verify(candidate, using: capability)
    let committedTicket = try await owner.verify(candidate, using: capability)
    let before = await owner.snapshot()
    precondition(before == initial)

    let next = try await owner.commit(committedTicket, using: capability)
    precondition(next.generation == 1) // S_n -> S_(n+1)

    do {
        _ = try await owner.commit(oldTicket, using: capability)
        preconditionFailure("Expected staleGeneration")
    } catch Rejection.staleGeneration {
        // Previously admitted != currently applicable.
    }
    let afterStale = await owner.snapshot()
    precondition(afterStale == next)

    do {
        _ = try await owner.commit(committedTicket, using: capability)
        preconditionFailure("Expected replay")
    } catch Rejection.replay {
        // A consumed ticket is not reusable authority.
    }
    let afterReplay = await owner.snapshot()
    precondition(afterReplay == next)
}
```

Here the capability remains current and no other caller intervenes. Thus the unconsumed old ticket fails with `.staleGeneration`; the already consumed ticket fails with `.replay`. If the capability were revoked first, `.invalidCapability` would precede either check. Error precedence should not be mistaken for a guarantee that every invalid ticket produces the same error under all conditions.

## Integration checklist

- **Before:** pin the exact SDK revision; identify authoritative state and its consumer semantic validator; define application identity, base/generation relationships, capability scope and mutation ownership.
- **Positive path:** propose; semantically validate; bind the exact candidate; admit; commit; read back the resulting state and expected generation change.
- **Failure paths:** exercise an invalid domain result, stale state, wrong capability/scope, revocation, replay, change after admission and supported commitment/lineage mismatches.
- **After every rejection:** explicitly check the bounded application state and unrelated state that the integration promises to preserve. Do not infer this solely from an error.
- **Lifecycle:** decide how sessions, capabilities, tickets, UI and persistence interact. Existing backend output, evidence or a valid historical representation does not grant commit permission.

Each consumer chooses its own test structure and sufficient coverage; CIT-01's counts and wrapper types are not requirements.

## Evidence and limits

The first consumer study integrated this published reference into a private algebra application for a bounded polynomial simplification transition. The positive transition `3x + 2x - 4 + 7` → `5x + 3` and required rejection paths passed; successful generation was 0 → 1. Meaningful adapter work was required around application-specific scope, representation and lifecycle. Independent verification passed. Classification: **VALID WITH CONSUMER ADAPTER LIMITATIONS**.

The study was headless, deterministic and consumer-specific: synthetic with respect to the authority implementation, real with respect to application state integration. Its domain was bounded additive linear integer expressions; it did not establish arbitrary polynomial correctness or general symbolic proof. It did not establish production readiness, complete concurrency safety, authentication, OS isolation, hardware authority, iOS/device behavior, a visual workflow, persistence or learner-scoring integration, performance benefit, or general consumer compatibility. Private source and primary reports are not included here. E01–E26 remains a separate closed research series.
