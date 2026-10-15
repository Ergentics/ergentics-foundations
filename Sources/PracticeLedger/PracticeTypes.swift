// Copyright 2026 Ergentics, LLC
// SPDX-License-Identifier: Apache-2.0

import ChangeFoundation

/// Failures of the practice record itself. These are not `Rejection`s:
/// a bad score is not a stale commit, and a rejected record must not be
/// reported as if the authority had admitted it.
public enum PracticeRejection: Error, Equatable, Sendable {
    /// Event and skill identifiers must be non-empty.
    case emptyIdentifier
    /// UTF-8 length is capped so a record cannot smuggle an unbounded blob into the carrier.
    case identifierTooLong
    /// A zero byte would be ambiguous inside the length-prefixed canonical string.
    case embeddedNul
    case scoreOutOfRange
    case nonFiniteScore
    case duplicateEventID
    /// The carrier bytes are not a canonical practice log. This is a structural failure, not authority.
    case payloadCorrupt
}

enum IdentifierRules {
    static let maxUTF8Bytes = 256

    static func validate(_ raw: String) throws {
        let utf8 = Array(raw.utf8)
        guard !utf8.isEmpty else { throw PracticeRejection.emptyIdentifier }
        guard utf8.count <= maxUTF8Bytes else { throw PracticeRejection.identifierTooLong }
        guard !utf8.contains(0) else { throw PracticeRejection.embeddedNul }
    }
}

/// One submitted practice item. Distinct from `SkillID` so a skill name cannot be passed where an event id is required.
public struct EventID: Hashable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) throws {
        try IdentifierRules.validate(rawValue)
        self.rawValue = rawValue
    }
}

/// A subject skill key, as MasteryKit's taxonomy uses it. This module does not interpret the key.
public struct SkillID: Hashable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) throws {
        try IdentifierRules.validate(rawValue)
        self.rawValue = rawValue
    }
}

/// The three surfaces MasteryKit's practice loop already distinguishes. An unknown surface is not a stringly-typed escape hatch.
public enum PracticeSurface: UInt8, Hashable, Sendable {
    case problems = 1
    case quiz = 2
    case recall = 3
}

/// Closed lesson kind. The wire byte is `rawValue`; `code` is the MasteryKit label (`WE` / `PF` / `RP`).
public enum LessonKind: UInt8, Hashable, Sendable {
    case workedExample = 1
    case productiveFailure = 2
    case retrievalPractice = 3

    public var code: String {
        switch self {
        case .workedExample: "WE"
        case .productiveFailure: "PF"
        case .retrievalPractice: "RP"
        }
    }

    public init?(code: String) {
        switch code {
        case "WE": self = .workedExample
        case "PF": self = .productiveFailure
        case "RP": self = .retrievalPractice
        default: return nil
        }
    }
}

/// A score in the closed unit interval. `-0` is stored as `+0` so the canonical bits have one form.
public struct UnitScore: Hashable, Sendable {
    public let value: Double

    /// IEEE-754 bits of the stored value. `-0` has already been rewritten to `+0`.
    public var canonicalBits: UInt64 { value.bitPattern }

    var bits: UInt64 { canonicalBits }

    public init(_ value: Double) throws {
        guard value.isFinite else { throw PracticeRejection.nonFiniteScore }
        guard (0...1).contains(value) else { throw PracticeRejection.scoreOutOfRange }
        self.value = value == 0 ? 0 : value
    }
}

/// The fields MasteryKit's `TutorSession.submit` consumes. Viewer copy (stem, prompt, authored context) is intentionally absent:
/// this record is the admission payload, not a display document.
public struct PracticeEvent: Hashable, Sendable {
    public let id: EventID
    public let skillID: SkillID
    public let surface: PracticeSurface
    public let kind: LessonKind
    public let score: UnitScore
    public let timestampMs: Int64
    public let confident: Bool?

    public init(
        id: String,
        skillID: String,
        surface: PracticeSurface,
        kind: LessonKind,
        score: Double,
        timestampMs: Int64,
        confident: Bool? = nil
    ) throws {
        self.id = try EventID(id)
        self.skillID = try SkillID(skillID)
        self.surface = surface
        self.kind = kind
        self.score = try UnitScore(score)
        self.timestampMs = timestampMs
        self.confident = confident
    }
}

/// A decoded carrier snapshot. `evidence` is public knowledge; it does not authorize a later commit.
public struct PracticeSnapshot: Equatable, Sendable {
    public let lineage: UInt64
    public let generation: UInt64
    public let commitment: String
    public let relationCommitment: String
    public let events: [PracticeEvent]
}

extension PracticeSnapshot {
    /// Inspectable commitments. Matching another ledger's evidence does not grant commit rights.
    public var evidence: Evidence {
        Evidence(stateCommitment: commitment, relationCommitment: relationCommitment)
    }
}
