import XCTest
@testable import ChangeFoundation

@MainActor final class ContinuityTests: XCTestCase {
    func count(_ matched: UInt64, _ denominator: UInt64) throws -> PredicateCount {
        try PredicateCount(matched: matched, denominator: denominator)
    }

    func primary(sweep: Int = 1, level: ObserverLevel = .aggregate) throws -> TargetContinuity {
        try TargetContinuity(
            sweep: sweep, level: level, cell: .primary,
            ordered: count(0, 63), multiset: count(63, 63), commonAgreement: count(65457, 65457))
    }

    func changedSource(sweep: Int = 1, level: ObserverLevel = .aggregate) throws -> TargetContinuity {
        try TargetContinuity(
            sweep: sweep, level: level, cell: .changedSource,
            ordered: count(0, 63), multiset: count(0, 63), commonAgreement: count(64323, 65457))
    }

    func testCompleteUnorderedCountsDoNotLicenseOrderedReuse() async throws {
        let row = try primary()
        XCTAssertFalse(row.ordered.complete)
        XCTAssertTrue(row.multiset.complete)
        XCTAssertTrue(row.commonAgreement.complete)
        XCTAssertFalse(row.unorderedAgreementLicensesOrderedReuse)
        XCTAssertFalse(row.commonAssociationLicensesOrderedReuse)
        XCTAssertNotEqual(row.ordered.denominator, row.commonAgreement.denominator)
    }

    func testChangedSourceAgreementDoesNotLicenseOrderedReuse() async throws {
        let row = try changedSource()
        XCTAssertFalse(row.ordered.complete)
        XCTAssertFalse(row.multiset.complete)
        XCTAssertFalse(row.commonAgreement.complete)
        XCTAssertEqual(row.commonAgreement.matched, 64323)
        XCTAssertEqual(row.commonAgreement.denominator, 65457)
        XCTAssertFalse(row.unorderedAgreementLicensesOrderedReuse)
        XCTAssertFalse(row.commonAssociationLicensesOrderedReuse)
    }

    func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    func testPublicSynthesisIsAlreadyTheRecord() async throws {
        let root = repoRoot()
        let synthesisURL = root.appendingPathComponent("docs/e01-e26-public-synthesis.md")
        let basisURL = root.appendingPathComponent("sdk-release-basis.json")
        let synthesisBefore = try Data(contentsOf: synthesisURL)
        let basisBefore = try Data(contentsOf: basisURL)
        let synthesis = try XCTUnwrap(String(data: synthesisBefore, encoding: .utf8))
        XCTAssertTrue(synthesis.contains("E26's target continuity is especially discriminating."))
        XCTAssertTrue(synthesis.contains("[EV-E26-CONTINUITY]"))
        XCTAssertTrue(synthesis.contains("ordered vector equality 0/63"))
        XCTAssertTrue(synthesis.contains("multiset equality 63/63"))
        XCTAssertTrue(synthesis.contains("65,457/65,457"))
        XCTAssertTrue(synthesis.contains("ordered equality 0/63"))
        XCTAssertTrue(synthesis.contains("multiset equality 0/63"))
        XCTAssertTrue(synthesis.contains("64,323/65,457"))
        XCTAssertTrue(synthesis.contains(
            "per-process transition/occurrence counts, not independent statistical replicates or identical equality predicates"))
        XCTAssertTrue(synthesis.contains(
            "Neither unordered agreement nor a high common-association ratio licenses reuse of the whole current ordered validation product."))
        XCTAssertTrue(synthesis.contains("The derived dataset simply retains their exact counts."))

        struct BasisFile: Decodable {
            struct Synthesis: Decodable {
                let publicEvidenceId: String
                let sha256: String
            }
            let PostHocSynthesis: Synthesis
        }
        let basis = try JSONDecoder().decode(BasisFile.self, from: basisBefore)
        XCTAssertEqual(basis.PostHocSynthesis.publicEvidenceId, "POSTHOC-E01-E26-CLOSEOUT")
        XCTAssertEqual(basis.PostHocSynthesis.sha256.count, 64)
        XCTAssertEqual(try Data(contentsOf: synthesisURL), synthesisBefore)
        XCTAssertEqual(try Data(contentsOf: basisURL), basisBefore)
    }

    func testRetainedTableRepeatsTheSameCountsAtEachSweepAndLevel() async throws {
        let url = repoRoot().appendingPathComponent("docs/longitudinal-dataset.json")
        let before = try Data(contentsOf: url)
        let table = try E26ContinuityTable(decoding: before)
        XCTAssertEqual(try Data(contentsOf: url), before)
        XCTAssertEqual(table.rows.count, 12)
        XCTAssertFalse(TargetContinuity.countsAreIndependentReplicates)
        XCTAssertFalse(TargetContinuity.predicatesAreTheSameEquality)

        let levels: [ObserverLevel] = [.aggregate, .clean, .diagnostic]
        for sweep in [1, 2] {
            for level in levels {
                let rows = table.rows.filter { $0.sweep == sweep && $0.level == level }
                XCTAssertEqual(rows.count, 2)
                let primaryRow = try XCTUnwrap(rows.first { $0.cell == .primary })
                let changed = try XCTUnwrap(rows.first { $0.cell == .changedSource })
                XCTAssertEqual(primaryRow, try primary(sweep: sweep, level: level))
                XCTAssertEqual(changed, try changedSource(sweep: sweep, level: level))
                XCTAssertFalse(primaryRow.unorderedAgreementLicensesOrderedReuse)
                XCTAssertFalse(primaryRow.commonAssociationLicensesOrderedReuse)
                XCTAssertFalse(changed.unorderedAgreementLicensesOrderedReuse)
                XCTAssertFalse(changed.commonAssociationLicensesOrderedReuse)
            }
        }
    }

    func testSharedDenominatorAndOverflowAreRejected() async throws {
        let ordered = try count(0, 63)
        let multiset = try count(63, 63)
        let sameUnit = try count(63, 63)
        XCTAssertThrowsError(try TargetContinuity(
            sweep: 1, level: .clean, cell: .primary,
            ordered: ordered, multiset: multiset, commonAgreement: sameUnit)) { error in
            XCTAssertEqual(error as? Rejection, .invalidDomain)
        }
        XCTAssertThrowsError(try PredicateCount(matched: 64, denominator: 63)) { error in
            XCTAssertEqual(error as? Rejection, .invalidDomain)
        }
    }
}
