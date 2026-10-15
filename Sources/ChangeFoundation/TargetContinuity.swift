// Copyright 2026 Ergentics, LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// One predicate's matched count over its own denominator.
/// A complete count is not a license for a different predicate.
public struct PredicateCount: Equatable, Sendable {
    public let matched: UInt64
    public let denominator: UInt64

    public init(matched: UInt64, denominator: UInt64) throws {
        guard denominator > 0, matched <= denominator else { throw Rejection.invalidDomain }
        self.matched = matched
        self.denominator = denominator
    }

    public var complete: Bool { matched == denominator }
}

/// Observer label on a retained E26 continuity row.
public enum ObserverLevel: String, Equatable, Sendable, Decodable {
    case aggregate
    case clean
    case diagnostic
}

/// `cell` in `docs/longitudinal-dataset.json`.
/// The public synthesis already names cell 0 as the primary target and cell 1 as the changed-source counterpart.
public enum ContinuityCell: Int, Equatable, Sendable, Decodable {
    case primary = 0
    case changedSource = 1
}

/// One retained adjacent-transition row from EV-E26-CONTINUITY.
/// Ordered equality, multiset equality, and common occurrence/backing agreement
/// keep separate numerators. The transition denominator and the occurrence
/// denominator are not the same unit.
public struct TargetContinuity: Equatable, Sendable {
    public static let evidenceID = "EV-E26-CONTINUITY"
    /// Repeated rows are per-process counts, not independent statistical replicates.
    public static let countsAreIndependentReplicates = false
    /// The three predicates are not one equality.
    public static let predicatesAreTheSameEquality = false

    public let sweep: Int
    public let level: ObserverLevel
    public let cell: ContinuityCell
    public let ordered: PredicateCount
    public let multiset: PredicateCount
    public let commonAgreement: PredicateCount

    public init(sweep: Int, level: ObserverLevel, cell: ContinuityCell,
                ordered: PredicateCount, multiset: PredicateCount,
                commonAgreement: PredicateCount) throws {
        guard sweep == 1 || sweep == 2 else { throw Rejection.invalidDomain }
        guard ordered.denominator == multiset.denominator else { throw Rejection.invalidDomain }
        guard commonAgreement.denominator != ordered.denominator else { throw Rejection.invalidDomain }
        self.sweep = sweep
        self.level = level
        self.cell = cell
        self.ordered = ordered
        self.multiset = multiset
        self.commonAgreement = commonAgreement
    }

    /// Multiset equality is unordered agreement. It does not license reuse of the
    /// ordered validation product, including when the multiset count is complete.
    public var unorderedAgreementLicensesOrderedReuse: Bool { false }

    /// The common-association ratio does not license that reuse, including when
    /// the occurrence count is complete.
    public var commonAssociationLicensesOrderedReuse: Bool { false }
}

/// The twelve dataset rows named by the public synthesis. Loading them does not replace that document or rerun E26.
public struct E26ContinuityTable: Equatable, Sendable {
    public let rows: [TargetContinuity]

    public init(decoding data: Data) throws {
        let decoded = try JSONDecoder().decode(FileShape.self, from: data)
        let rows = try decoded.rows.map { try $0.continuity() }
        guard rows.count == 12 else { throw Rejection.invalidDomain }
        var seen = Set<String>()
        for row in rows {
            let key = "\(row.sweep)|\(row.level.rawValue)|\(row.cell.rawValue)"
            guard seen.insert(key).inserted else { throw Rejection.invalidDomain }
        }
        self.rows = rows
    }
}

private struct FileShape: Decodable {
    let rows: [Row]
    enum CodingKeys: String, CodingKey { case rows = "continuityRows" }
}

private struct Row: Decodable {
    let cell: ContinuityCell
    let commonAgreement: UInt64
    let commonDenominator: UInt64
    let evidenceId: String
    let level: ObserverLevel
    let multisetEqual: UInt64
    let orderedEqual: UInt64
    let sweep: Int
    let transitionDenominator: UInt64

    func continuity() throws -> TargetContinuity {
        guard evidenceId == TargetContinuity.evidenceID else { throw Rejection.invalidDomain }
        return try TargetContinuity(
            sweep: sweep,
            level: level,
            cell: cell,
            ordered: try PredicateCount(matched: orderedEqual, denominator: transitionDenominator),
            multiset: try PredicateCount(matched: multisetEqual, denominator: transitionDenominator),
            commonAgreement: try PredicateCount(matched: commonAgreement, denominator: commonDenominator))
    }
}
