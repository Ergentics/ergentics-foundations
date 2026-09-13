import Foundation
import CryptoKit

public enum Rejection: Error, Equatable, Sendable {
    case invalidDomain, wrongLineage, staleGeneration, wrongCommitment
    case invalidCapability, replay, generationExhausted, authorityExhausted
}

public struct Entry: Codable, Equatable, Sendable {
    public let id: UInt64
    public let value: Int64
    public init(id: UInt64, value: Int64) { self.id = id; self.value = value }
}

/// Public knowledge. Constructing a snapshot never grants commit authority.
public struct State: Equatable, Sendable {
    public let lineage: UInt64
    public let generation: UInt64
    public let entries: [Entry]
    public let order: [UInt64]

    public init(lineage: UInt64, generation: UInt64, entries: [Entry], order: [UInt64]) throws {
        let ids = Set(entries.map(\.id))
        guard ids.count == entries.count, Set(order).count == order.count,
              ids == Set(order) else { throw Rejection.invalidDomain }
        self.lineage = lineage; self.generation = generation
        self.entries = entries.sorted { $0.id < $1.id }; self.order = order
    }
    public var commitment: String { Canonical.digest(Canonical.state(self)) }
    public var relation: Relation { Relation(entries: entries) }
}

/// Order-independent ID/value relation; persistence of this value is not authority.
public struct Relation: Equatable, Sendable {
    public let entries: [Entry]
    fileprivate init(entries: [Entry]) { self.entries = entries }
    public var commitment: String { Canonical.digest(Canonical.relation(entries)) }
}

public struct CandidateTransition: Codable, Equatable, Sendable {
    public let lineage: UInt64
    public let baseGeneration: UInt64
    public let baseCommitment: String
    public let entries: [Entry]
    public let order: [UInt64]
    public init(lineage: UInt64, baseGeneration: UInt64, baseCommitment: String,
                entries: [Entry], order: [UInt64]) {
        self.lineage = lineage; self.baseGeneration = baseGeneration
        self.baseCommitment = baseCommitment; self.entries = entries; self.order = order
    }
}

public struct ConsequentialChange: Equatable, Sendable {
    public let relationChanged: Bool
    public let orderChanged: Bool
    public var isEmpty: Bool { !relationChanged && !orderChanged }
}

/// Serializable evidence is freely inspectable knowledge, never a capability.
public struct Evidence: Codable, Equatable, Sendable {
    public let stateCommitment: String
    public let relationCommitment: String
    public init(stateCommitment: String, relationCommitment: String) {
        self.stateCommitment = stateCommitment; self.relationCommitment = relationCommitment
    }
}

/// Intentionally not Codable and not publicly constructible. Process-local only.
public final class Capability: Sendable {
    fileprivate let issuer: UUID
    fileprivate let id: UUID
    fileprivate let epoch: UInt64
    fileprivate init(issuer: UUID, epoch: UInt64) {
        self.issuer = issuer; self.epoch = epoch; self.id = UUID()
    }
}

/// A verified proposal, not a commit. Its authority is rechecked on consumption.
public final class VerifiedTransition: Sendable {
    fileprivate let id = UUID()
    fileprivate let issuer: UUID
    fileprivate let capabilityID: UUID
    fileprivate let epoch: UInt64
    fileprivate let candidate: CandidateTransition
    public let change: ConsequentialChange
    fileprivate init(issuer: UUID, capability: Capability, candidate: CandidateTransition,
                     change: ConsequentialChange) {
        self.issuer = issuer; self.capabilityID = capability.id; self.epoch = capability.epoch
        self.candidate = candidate; self.change = change
    }
}

/// A bounded, single-process software reference. The holder of this actor is the
/// trusted bootstrap issuer. This is not authentication or hardware isolation.
public actor ReferenceAuthority {
    private let issuer = UUID()
    private var epoch: UInt64 = 0
    private var current: State
    private var consumed: Set<UUID> = []
    public init(initial: State) { current = initial }
    public func snapshot() -> State { current }
    public func evidence() -> Evidence {
        Evidence(stateCommitment: current.commitment, relationCommitment: current.relation.commitment)
    }
    public func issueCapability() -> Capability { Capability(issuer: issuer, epoch: epoch) }
    public func revokeCapabilities() throws {
        guard epoch < UInt64.max else { throw Rejection.authorityExhausted }
        epoch += 1
    }
    private func check(_ capability: Capability) throws {
        guard capability.issuer == issuer, capability.epoch == epoch else {
            throw Rejection.invalidCapability
        }
    }
    private func resolve(_ candidate: CandidateTransition) throws -> State {
        guard candidate.lineage == current.lineage else { throw Rejection.wrongLineage }
        guard candidate.baseGeneration == current.generation else { throw Rejection.staleGeneration }
        guard candidate.baseCommitment == current.commitment else { throw Rejection.wrongCommitment }
        guard current.generation < UInt64.max else { throw Rejection.generationExhausted }
        return try State(lineage: current.lineage, generation: current.generation + 1,
                         entries: candidate.entries, order: candidate.order)
    }
    public func verify(_ candidate: CandidateTransition, using capability: Capability) throws -> VerifiedTransition {
        try check(capability)
        let next = try resolve(candidate)
        return VerifiedTransition(issuer: issuer, capability: capability, candidate: candidate,
            change: ConsequentialChange(relationChanged: next.relation != current.relation,
                                        orderChanged: next.order != current.order))
    }
    public func commit(_ verified: VerifiedTransition, using capability: Capability) throws -> State {
        // No suspension occurs between authority/currentness checks and update.
        try check(capability)
        guard verified.issuer == issuer, verified.epoch == epoch,
              verified.capabilityID == capability.id else { throw Rejection.invalidCapability }
        guard !consumed.contains(verified.id) else { throw Rejection.replay }
        let next = try resolve(verified.candidate)
        consumed.insert(verified.id)
        current = next
        return next
    }
}

/// Canonical v1: ASCII domain tag, big-endian UInt64 fields/counts, signed values
/// encoded as UInt64 two's-complement bits. Entries sorted by ID; order preserved.
/// SHA-256 is a commitment to these bytes, not authority or collision-free proof.
private enum Canonical {
    static func append(_ value: UInt64, to bytes: inout [UInt8]) {
        for shift in stride(from: 56, through: 0, by: -8) {
            bytes.append(UInt8(truncatingIfNeeded: value >> UInt64(shift)))
        }
    }
    static func relation(_ entries: [Entry]) -> [UInt8] {
        var bytes = Array("CF-RELATION-v1\u{0}".utf8)
        append(UInt64(entries.count), to: &bytes)
        for e in entries { append(e.id, to: &bytes); append(UInt64(bitPattern: e.value), to: &bytes) }
        return bytes
    }
    static func state(_ state: State) -> [UInt8] {
        var bytes = Array("CF-STATE-v1\u{0}".utf8)
        append(state.lineage, to: &bytes); append(state.generation, to: &bytes)
        bytes += relation(state.entries)
        append(UInt64(state.order.count), to: &bytes)
        for id in state.order { append(id, to: &bytes) }
        return bytes
    }
    static func digest(_ bytes: [UInt8]) -> String {
        SHA256.hash(data: Data(bytes)).map { String(format: "%02x", $0) }.joined()
    }
}
