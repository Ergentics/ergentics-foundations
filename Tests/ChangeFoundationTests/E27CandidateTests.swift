import XCTest
@testable import ChangeFoundation

@MainActor final class E27CandidateTests: XCTestCase {
    func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    func testCandidateListDoesNotStartE27() async throws {
        let root = repoRoot()
        let listURL = root.appendingPathComponent("docs/e27-candidates.json")
        let basisURL = root.appendingPathComponent("sdk-release-basis.json")
        let noteURL = root.appendingPathComponent("docs/e27-candidates.md")
        let listBytes = try Data(contentsOf: listURL)
        let basisBytes = try Data(contentsOf: basisURL)
        let note = try XCTUnwrap(String(data: Data(contentsOf: noteURL), encoding: .utf8))
        let list = try E27CandidateList(decoding: listBytes)

        XCTAssertFalse(list.e27Started)
        XCTAssertEqual(list.nomination, "NONE")
        XCTAssertEqual(list.seriesStatus, "CLOSED_AFTER_E26")
        XCTAssertEqual(list.closeout.classification, "H. MEASUREMENT DECOMPOSITION INCONCLUSIVE")
        XCTAssertFalse(list.closeout.speedupTested)
        XCTAssertFalse(list.closeout.e27InThisSeries)
        XCTAssertEqual(list.closeout.economicExhaustion, "UNKNOWN")
        XCTAssertFalse(list.closeout.successorProjectsBlocked)
        XCTAssertEqual(list.closeout.evidenceScope, "AT_CLOSEOUT")
        XCTAssertFalse(list.closeout.universalNoNewEvidence)
        XCTAssertEqual(list.candidates.count, 8)
        XCTAssertEqual(list.excluded.count, 3)
        for candidate in list.candidates {
            XCTAssertEqual(candidate.status, E27Candidate.notNominated)
            XCTAssertFalse(candidate.startsE27)
            XCTAssertTrue(note.contains(candidate.id))
        }
        for exclusion in list.excluded {
            XCTAssertEqual(exclusion.status, E27Exclusion.notACandidate)
            XCTAssertTrue(note.contains(exclusion.id))
        }
        XCTAssertTrue(note.contains("It does not start E27"))
        XCTAssertTrue(note.contains("There is no E27 in this series."))
        XCTAssertTrue(note.contains("successor projects are not blocked."))
        XCTAssertTrue(note.contains(
            "The evidence in hand at closeout is not a universal rule that no new evidence can be gathered."))

        struct BasisFile: Decodable {
            let E27Started: Bool
            let E26Classification: String
        }
        let basis = try JSONDecoder().decode(BasisFile.self, from: basisBytes)
        XCTAssertFalse(basis.E27Started)
        XCTAssertEqual(basis.E26Classification, "H. MEASUREMENT DECOMPOSITION INCONCLUSIVE")
        XCTAssertEqual(try Data(contentsOf: listURL), listBytes)
        XCTAssertEqual(try Data(contentsOf: basisURL), basisBytes)
    }
}
