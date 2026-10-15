// Copyright 2026 Ergentics, LLC
// SPDX-License-Identifier: Apache-2.0

import ChangeFoundation

/// In-memory practice log whose commits go through `ReferenceAuthority`.
///
/// This is the MasteryKit practice record — the arguments `TutorSession.submit` keeps —
/// placed on the foundations admission path. It does not score mastery, choose the next
/// item, or store a taxonomy. Possession of the actor is trusted issuer access, the same
/// bootstrap the reference already documents. There is no disk, restart, or network.
///
/// The log is not cached across an `await`. Swift actors re-enter there, so a snapshot
/// taken before a suspension would be a stale source of truth. Current events are always
/// decoded from the authority's state.
public actor PracticeLedger {
    private let authority: ReferenceAuthority

    /// Bootstrap a new issuer at this snapshot. This does not restore capabilities or
    /// consumed tickets, and it does not prove the events were committed before.
    public init(lineage: UInt64, generation: UInt64 = 0, events: [PracticeEvent] = []) throws {
        let state = try PracticeEncoding.state(lineage: lineage, generation: generation, events: events)
        self.authority = ReferenceAuthority(initial: state)
    }

    public func issueCapability() async -> Capability {
        await authority.issueCapability()
    }

    public func revokeCapabilities() async throws {
        try await authority.revokeCapabilities()
    }

    public func snapshot() async throws -> PracticeSnapshot {
        try PracticeEncoding.snapshot(from: await authority.snapshot())
    }

    /// Admit one new event against the current log. Does not append it.
    ///
    /// - Throws: `PracticeRejection.duplicateEventID` when `event.id` is already in the log.
    ///   Authority failures (`Rejection`) are unchanged: a stale base, a revoked capability,
    ///   or a wrong issuer fails here without mutation.
    public func verifyAppend(_ event: PracticeEvent, using capability: Capability) async throws -> VerifiedTransition {
        let base = await authority.snapshot()
        let existing = try PracticeEncoding.decodedEvents(in: base)
        guard !existing.contains(where: { $0.id == event.id }) else {
            throw PracticeRejection.duplicateEventID
        }
        let candidate = try PracticeEncoding.transition(from: base, events: existing + [event])
        return try await authority.verify(candidate, using: capability)
    }

    /// Admit the current events again. A later commit advances generation and the state
    /// commitment without changing the relation commitment.
    public func verifySamePayload(using capability: Capability) async throws -> VerifiedTransition {
        let base = await authority.snapshot()
        let existing = try PracticeEncoding.decodedEvents(in: base)
        let candidate = try PracticeEncoding.transition(from: base, events: existing)
        return try await authority.verify(candidate, using: capability)
    }

    /// Recheck the ticket and, if it is current, advance the log. The returned snapshot is
    /// decoded from the committed state, not from the caller's copy of the event.
    public func commit(_ verified: VerifiedTransition, using capability: Capability) async throws -> PracticeSnapshot {
        try await commitRecording(verified, using: capability).snapshot
    }

    /// The same mutation as `commit`, plus the predecessor id and the change flags.
    /// The record is not kept on the ledger.
    public func commitRecording(
        _ verified: VerifiedTransition, using capability: Capability
    ) async throws -> PracticeCommit {
        let recorded = try await authority.commitRecording(verified, using: capability)
        let snapshot = try PracticeEncoding.snapshot(from: recorded.committed)
        return PracticeCommit(previous: recorded.previous, snapshot: snapshot, change: recorded.change)
    }
}

/// A practice commit that already happened. Holding it does not authorize another append.
public struct PracticeCommit: Equatable, Sendable {
    public let previous: StateID
    public let snapshot: PracticeSnapshot
    public let change: ConsequentialChange

    public var successor: StateID { snapshot.stateID }
}
