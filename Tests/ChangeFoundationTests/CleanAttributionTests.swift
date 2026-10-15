import XCTest
@testable import ChangeFoundation

@MainActor final class CleanAttributionTests: XCTestCase {
    func testPublicArmsSeparateWithoutASpeedup() async throws {
        let study = try await CleanAttribution.run()
        XCTAssertTrue(study.armsSeparate)
        XCTAssertFalse(CleanAttribution.speedupTested)
        XCTAssertFalse(CleanAttribution.e27Started)
        XCTAssertFalse(CleanAttribution.privateLoopDecomposed)
        XCTAssertFalse(study.orderedProductReused)
        XCTAssertFalse(study.construction.contains("digest="))
        XCTAssertEqual(
            study.projection,
            "bytes=827 digest=58b8db0ebace624abdd96712379cbf5dfb7ce9b9bbfc0c17d1c00482b6c73c02")
        XCTAssertEqual(
            study.equality,
            "relationEqual=true orderedEqual=false orderedProductReused=false")
        XCTAssertEqual(
            study.append,
            "generation=1 relationStable=true stateChanged=true")
        XCTAssertEqual(study.construction, study.mixedConstruction)
        XCTAssertEqual(study.projection, study.mixedProjection)
        XCTAssertEqual(study.equality, study.mixedEquality)
        XCTAssertEqual(study.append, study.mixedAppend)

        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("docs/e27-candidates.json"))
        let listed = try JSONDecoder().decode(CandidateFile.self, from: data)
        XCTAssertEqual(listed.attribution.boundary, "public-change-foundation")
        XCTAssertEqual(listed.attribution.armsSeparateOnSinks, study.armsSeparate)
        XCTAssertFalse(listed.attribution.speedupTested)
        XCTAssertFalse(listed.attribution.e26PrivateLoopDecomposed)
        XCTAssertEqual(
            listed.attribution.projectionDigest,
            "58b8db0ebace624abdd96712379cbf5dfb7ce9b9bbfc0c17d1c00482b6c73c02")
        XCTAssertEqual(listed.candidates.first { $0.id == CleanAttribution.questionID }?.status, "NOT_NOMINATED")
    }
}

private struct CandidateFile: Decodable {
    struct Attribution: Decodable {
        let boundary: String
        let armsSeparateOnSinks: Bool
        let speedupTested: Bool
        let e26PrivateLoopDecomposed: Bool
        let projectionDigest: String
    }
    struct Candidate: Decodable {
        let id: String
        let status: String
    }
    let attribution: Attribution
    let candidates: [Candidate]
}
