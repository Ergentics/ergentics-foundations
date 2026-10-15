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

/// The E26 closeout as a statement about the evidence then in hand.
public struct E27Closeout: Equatable, Sendable {
    public let classification: String
    public let speedupTested: Bool
    public let e27InThisSeries: Bool
    public let economicExhaustion: String
    public let successorProjectsBlocked: Bool
    public let evidenceScope: String
    /// False. The closeout is not a universal ban on later evidence.
    public let universalNoNewEvidence: Bool
}

/// Where a later measurement would start. A speedup trial is not that start.
public struct E27Design: Equatable, Sendable {
    public let firstQuestionIfMeasured: String
    public let openSourceSpeedupTrial: Bool
    public let publicBenchesAreE26: Bool
    public let speedupTestFirst: Bool
}

/// Questions the closed series does not nominate. `e27Started` stays false.
public struct E27CandidateList: Equatable, Sendable {
    public let closeout: E27Closeout
    public let design: E27Design
    public let seriesStatus: String
    public let nomination: String
    public let e27Started: Bool
    public let source: String
    public let candidates: [E27Candidate]
    public let excluded: [E27Exclusion]

    public init(decoding data: Data) throws {
        let decoded = try JSONDecoder().decode(FileShape.self, from: data)
        let closeout = decoded.closeout
        guard closeout.classification == "H. MEASUREMENT DECOMPOSITION INCONCLUSIVE" else {
            throw Rejection.invalidDomain
        }
        guard closeout.speedupTested == false, closeout.e27InThisSeries == false else {
            throw Rejection.invalidDomain
        }
        guard closeout.economicExhaustion == "UNKNOWN" else { throw Rejection.invalidDomain }
        guard closeout.successorProjectsBlocked == false else { throw Rejection.invalidDomain }
        guard closeout.evidenceScope == "AT_CLOSEOUT" else { throw Rejection.invalidDomain }
        guard closeout.universalNoNewEvidence == false else { throw Rejection.invalidDomain }
        let design = decoded.design
        guard design.speedupTestFirst == false, design.openSourceSpeedupTrial == false else {
            throw Rejection.invalidDomain
        }
        guard design.publicBenchesAreE26 == false else { throw Rejection.invalidDomain }
        guard design.firstQuestionIfMeasured == "CANDIDATE-CLEAN-ATTRIBUTION" else {
            throw Rejection.invalidDomain
        }
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
        guard candidates.contains(where: { $0.id == design.firstQuestionIfMeasured }) else {
            throw Rejection.invalidDomain
        }
        let excluded = try decoded.excluded.map { row -> E27Exclusion in
            guard row.status == E27Exclusion.notACandidate else { throw Rejection.invalidDomain }
            guard row.id.hasPrefix("EXCLUDED-"), !row.reason.isEmpty else { throw Rejection.invalidDomain }
            guard seen.insert(row.id).inserted else { throw Rejection.invalidDomain }
            return E27Exclusion(id: row.id, reason: row.reason, status: row.status)
        }
        self.design = E27Design(
            firstQuestionIfMeasured: design.firstQuestionIfMeasured,
            openSourceSpeedupTrial: design.openSourceSpeedupTrial,
            publicBenchesAreE26: design.publicBenchesAreE26,
            speedupTestFirst: design.speedupTestFirst)
        self.closeout = E27Closeout(
            classification: closeout.classification,
            speedupTested: closeout.speedupTested,
            e27InThisSeries: closeout.e27InThisSeries,
            economicExhaustion: closeout.economicExhaustion,
            successorProjectsBlocked: closeout.successorProjectsBlocked,
            evidenceScope: closeout.evidenceScope,
            universalNoNewEvidence: closeout.universalNoNewEvidence)
        self.seriesStatus = decoded.seriesStatus
        self.nomination = decoded.nomination
        self.e27Started = false
        self.source = decoded.source
        self.candidates = candidates
        self.excluded = excluded
    }
}

private struct FileShape: Decodable {
    let closeout: CloseoutRow
    let design: DesignRow
    let seriesStatus: String
    let nomination: String
    let e27Started: Bool
    let source: String
    let candidates: [CandidateRow]
    let excluded: [ExcludedRow]
}

private struct DesignRow: Decodable {
    let firstQuestionIfMeasured: String
    let openSourceSpeedupTrial: Bool
    let publicBenchesAreE26: Bool
    let speedupTestFirst: Bool
}

private struct CloseoutRow: Decodable {
    let classification: String
    let speedupTested: Bool
    let e27InThisSeries: Bool
    let economicExhaustion: String
    let successorProjectsBlocked: Bool
    let evidenceScope: String
    let universalNoNewEvidence: Bool
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
