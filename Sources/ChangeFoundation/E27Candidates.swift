// Copyright 2026 Ergentics, LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// An open question after the closed E01–E26 series.
/// Loading the list does not start E27.
public struct E27Candidate: Equatable, Sendable {
    public static let notNominated = "NOT_NOMINATED"

    public let id: String
    public let question: String
    public let evidenceIds: [String]
    public let status: String

    public var startsE27: Bool { false }
}

/// Motives the E26 closeout keeps out of the candidate list.
public struct E27Exclusion: Equatable, Sendable {
    public static let notACandidate = "NOT_A_CANDIDATE"

    public let id: String
    public let reason: String
    public let status: String
}

/// Questions the closed series does not nominate. `e27Started` stays false.
public struct E27CandidateList: Equatable, Sendable {
    public let seriesStatus: String
    public let nomination: String
    public let e27Started: Bool
    public let source: String
    public let candidates: [E27Candidate]
    public let excluded: [E27Exclusion]

    public init(decoding data: Data) throws {
        let decoded = try JSONDecoder().decode(FileShape.self, from: data)
        guard decoded.seriesStatus == "CLOSED_AFTER_E26" else { throw Rejection.invalidDomain }
        guard decoded.nomination == "NONE" else { throw Rejection.invalidDomain }
        guard decoded.e27Started == false else { throw Rejection.invalidDomain }
        guard decoded.source == "docs/e01-e26-public-synthesis.md" else { throw Rejection.invalidDomain }
        guard decoded.candidates.count == 8, decoded.excluded.count == 3 else { throw Rejection.invalidDomain }
        var seen = Set<String>()
        let candidates = try decoded.candidates.map { row -> E27Candidate in
            guard row.status == E27Candidate.notNominated else { throw Rejection.invalidDomain }
            guard row.id.hasPrefix("CANDIDATE-"), !row.question.isEmpty, !row.evidenceIds.isEmpty else {
                throw Rejection.invalidDomain
            }
            guard seen.insert(row.id).inserted else { throw Rejection.invalidDomain }
            return E27Candidate(id: row.id, question: row.question, evidenceIds: row.evidenceIds, status: row.status)
        }
        let excluded = try decoded.excluded.map { row -> E27Exclusion in
            guard row.status == E27Exclusion.notACandidate else { throw Rejection.invalidDomain }
            guard row.id.hasPrefix("EXCLUDED-"), !row.reason.isEmpty else { throw Rejection.invalidDomain }
            guard seen.insert(row.id).inserted else { throw Rejection.invalidDomain }
            return E27Exclusion(id: row.id, reason: row.reason, status: row.status)
        }
        self.seriesStatus = decoded.seriesStatus
        self.nomination = decoded.nomination
        self.e27Started = false
        self.source = decoded.source
        self.candidates = candidates
        self.excluded = excluded
    }
}

private struct FileShape: Decodable {
    let seriesStatus: String
    let nomination: String
    let e27Started: Bool
    let source: String
    let candidates: [CandidateRow]
    let excluded: [ExcludedRow]
}

private struct CandidateRow: Decodable {
    let id: String
    let question: String
    let evidenceIds: [String]
    let status: String
}

private struct ExcludedRow: Decodable {
    let id: String
    let reason: String
    let status: String
}
