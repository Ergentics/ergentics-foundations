// Copyright 2026 Ergentics, LLC
// SPDX-License-Identifier: Apache-2.0

/// One public-reference pass of construction, projection, equality, and append.
/// The sinks say whether those arms can be named apart. They are not a speedup,
/// and they do not decompose the private E26 loop.
public struct CleanAttribution: Equatable, Sendable {
    public static let questionID = "CANDIDATE-CLEAN-ATTRIBUTION"
    public static let speedupTested = false
    public static let e27Started = false
    public static let privateLoopDecomposed = false

    public let construction: String
    public let projection: String
    public let equality: String
    public let append: String
    public let mixedConstruction: String
    public let mixedProjection: String
    public let mixedEquality: String
    public let mixedAppend: String
    /// Relation equality does not license reuse of the ordered product.
    public let orderedProductReused: Bool

    public var armsSeparate: Bool {
        construction == mixedConstruction
            && projection == mixedProjection
            && equality == mixedEquality
            && append == mixedAppend
            && orderedProductReused == false
            && Self.speedupTested == false
            && Self.e27Started == false
            && Self.privateLoopDecomposed == false
    }

    public static func run() async throws -> CleanAttribution {
        let entries = (1...32).map { Entry(id: UInt64($0), value: Int64($0) * 3) }
        let order = entries.map(\.id)
        let reversed = Array(order.reversed())

        let built = try State(lineage: 1, generation: 0, entries: entries, order: order)
        let construction = constructionSink(built)
        let projected = Canonical.state(built)
        let projection = projectionSink(projected)
        let swapped = try State(lineage: 1, generation: 0, entries: entries, order: reversed)
        let equality = equalitySink(base: built, swapped: swapped)
        let append = try await appendSink(from: built)

        let mixedBuilt = try State(lineage: 1, generation: 0, entries: entries, order: order)
        let mixedConstruction = "lineage=\(mixedBuilt.lineage) generation=\(mixedBuilt.generation) entries=\(mixedBuilt.entries.count) order=\(mixedBuilt.order.count)"
        let mixedBytes = Canonical.state(mixedBuilt)
        let mixedProjection = "bytes=\(mixedBytes.count) digest=\(Canonical.digest(mixedBytes))"
        let mixedSwapped = try State(lineage: 1, generation: 0, entries: entries, order: reversed)
        let relationEqual = mixedBuilt.relation == mixedSwapped.relation
        let orderedEqual = mixedBuilt.order == mixedSwapped.order
        let mixedEquality = "relationEqual=\(relationEqual) orderedEqual=\(orderedEqual) orderedProductReused=false"
        let mixedAuthority = ReferenceAuthority(initial: mixedBuilt)
        let mixedCapability = await mixedAuthority.issueCapability()
        let mixedProposal = CandidateTransition(
            lineage: mixedBuilt.lineage, baseGeneration: mixedBuilt.generation,
            baseCommitment: mixedBuilt.commitment, entries: mixedBuilt.entries, order: mixedBuilt.order)
        let mixedTicket = try await mixedAuthority.verify(mixedProposal, using: mixedCapability)
        let mixedCommitted = try await mixedAuthority.commitRecording(mixedTicket, using: mixedCapability)
        let mixedAppend = "generation=\(mixedCommitted.successor.generation) relationStable=\(mixedCommitted.committed.relation.commitment == mixedBuilt.relation.commitment) stateChanged=\(mixedCommitted.successor.commitment != mixedBuilt.commitment)"

        return CleanAttribution(
            construction: construction,
            projection: projection,
            equality: equality,
            append: append,
            mixedConstruction: mixedConstruction,
            mixedProjection: mixedProjection,
            mixedEquality: mixedEquality,
            mixedAppend: mixedAppend,
            orderedProductReused: false)
    }
}

private func constructionSink(_ state: State) -> String {
    "lineage=\(state.lineage) generation=\(state.generation) entries=\(state.entries.count) order=\(state.order.count)"
}

private func projectionSink(_ bytes: [UInt8]) -> String {
    "bytes=\(bytes.count) digest=\(Canonical.digest(bytes))"
}

private func equalitySink(base: State, swapped: State) -> String {
    let relationEqual = base.relation == swapped.relation
    let orderedEqual = base.order == swapped.order
    return "relationEqual=\(relationEqual) orderedEqual=\(orderedEqual) orderedProductReused=false"
}

private func appendSink(from state: State) async throws -> String {
    let authority = ReferenceAuthority(initial: state)
    let capability = await authority.issueCapability()
    let proposal = CandidateTransition(
        lineage: state.lineage, baseGeneration: state.generation,
        baseCommitment: state.commitment, entries: state.entries, order: state.order)
    let ticket = try await authority.verify(proposal, using: capability)
    let committed = try await authority.commitRecording(ticket, using: capability)
    let relationStable = committed.committed.relation.commitment == state.relation.commitment
    let stateChanged = committed.successor.commitment != state.commitment
    return "generation=\(committed.successor.generation) relationStable=\(relationStable) stateChanged=\(stateChanged)"
}
