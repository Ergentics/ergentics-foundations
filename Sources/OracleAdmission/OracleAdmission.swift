// Copyright 2026 Ergentics, LLC
// SPDX-License-Identifier: Apache-2.0

import ChangeFoundation
import PracticeLedger

/// How a caller classifies a practice score before any witness is consulted.
/// Only `derived` can be sealed. A prediction or a recorded note stays unsealed.
public enum ScoreClass: UInt8, Equatable, Sendable {
    case prediction = 0
    case recorded = 1
    case derived = 2
}

public enum OracleInputError: Error, Equatable, Sendable {
    case emptyName
    case nameTooLong
    case embeddedNul
    case invalidWitnessScore
    /// The family floor must be at least 1. Zero would seal an empty witness list.
    case minimumFamilies
}

public enum AbstainReason: String, Equatable, Sendable {
    /// The claim is not offered as derived, or it has no witnesses.
    case notDerivable
    /// The same dependency id appears on two witnesses.
    case sharedDependency
    /// Distinct witness families are below the requested floor.
    case tooFewFamilies
    /// A witness score is not the practice event's canonical score.
    case discordant
    /// The caller says a falsifier is still open.
    case falsifierOpen
}

/// A witness family name. Distinct from a dependency id, so one cannot be passed as the other.
public struct WitnessFamily: Hashable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) throws {
        self.rawValue = try OracleName.validate(rawValue)
    }
}

public struct DependencyID: Hashable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) throws {
        self.rawValue = try OracleName.validate(rawValue)
    }
}

public struct ScoreWitness: Hashable, Sendable {
    public let family: WitnessFamily
    public let dependencies: [DependencyID]
    public let score: UnitScore

    public init(family: String, dependencies: [String], score: Double) throws {
        self.family = try WitnessFamily(family)
        self.dependencies = try dependencies.map(DependencyID.init)
        do {
            self.score = try UnitScore(score)
        } catch {
            throw OracleInputError.invalidWitnessScore
        }
    }
}

public struct ScoreClaim: Sendable {
    public let event: PracticeEvent
    public let asserted: ScoreClass
    public let witnesses: [ScoreWitness]

    public init(event: PracticeEvent, asserted: ScoreClass, witnesses: [ScoreWitness]) {
        self.event = event
        self.asserted = asserted
        self.witnesses = witnesses
    }
}

/// Minted only by `OracleAdmission.judge`. Holding one does not commit the ledger.
public struct SealedScore: Equatable, Sendable {
    public let event: PracticeEvent
    public let familyCount: Int

    fileprivate init(event: PracticeEvent, familyCount: Int) {
        self.event = event
        self.familyCount = familyCount
    }
}

public enum JudgeResult: Equatable, Sendable {
    case seal(SealedScore)
    case abstain(AbstainReason)
}

public enum AdmissionOutcome: Sendable {
    case abstained(AbstainReason)
    /// The ledger has verified this ticket and has not committed it.
    case verified(VerifiedTransition, SealedScore)
}

enum OracleName {
    static func validate(_ raw: String) throws -> String {
        let utf8 = Array(raw.utf8)
        guard !utf8.isEmpty else { throw OracleInputError.emptyName }
        guard utf8.count <= 256 else { throw OracleInputError.nameTooLong }
        guard !utf8.contains(0) else { throw OracleInputError.embeddedNul }
        return raw
    }
}

/// Parallel public gate for a practice score. It mirrors the agentcraft rule that witnesses
/// must be independent and concordant before a result is sealed, and it does not import
/// AgentContractKit. Abstaining is a result. Sealing is not a commit.
public enum OracleAdmission {
    public static func judge(
        _ claim: ScoreClaim,
        minimumFamilies: Int = 2,
        falsifierSettled: Bool = true
    ) throws -> JudgeResult {
        guard minimumFamilies >= 1 else { throw OracleInputError.minimumFamilies }
        guard claim.asserted == .derived, !claim.witnesses.isEmpty else {
            return .abstain(.notDerivable)
        }
        if sharesDependency(claim.witnesses) {
            return .abstain(.sharedDependency)
        }
        let families = Set(claim.witnesses.map(\.family))
        guard families.count >= minimumFamilies else {
            return .abstain(.tooFewFamilies)
        }
        let expected = claim.event.score.canonicalBits
        guard claim.witnesses.allSatisfy({ $0.score.canonicalBits == expected }) else {
            return .abstain(.discordant)
        }
        guard falsifierSettled else { return .abstain(.falsifierOpen) }
        return .seal(SealedScore(event: claim.event, familyCount: families.count))
    }

    /// Judge, then verify on the ledger only when the judge seals. An abstention does not
    /// call the ledger. A returned ticket is still not a commit.
    public static func verify(
        _ claim: ScoreClaim,
        on ledger: PracticeLedger,
        using capability: Capability,
        minimumFamilies: Int = 2,
        falsifierSettled: Bool = true
    ) async throws -> AdmissionOutcome {
        switch try judge(claim, minimumFamilies: minimumFamilies, falsifierSettled: falsifierSettled) {
        case .abstain(let reason):
            return .abstained(reason)
        case .seal(let sealed):
            let ticket = try await ledger.verifyAppend(sealed.event, using: capability)
            return .verified(ticket, sealed)
        }
    }

    private static func sharesDependency(_ witnesses: [ScoreWitness]) -> Bool {
        var owners: [DependencyID: Int] = [:]
        for witness in witnesses {
            for dependency in Set(witness.dependencies) {
                let count = (owners[dependency] ?? 0) + 1
                owners[dependency] = count
                if count >= 2 { return true }
            }
        }
        return false
    }
}
