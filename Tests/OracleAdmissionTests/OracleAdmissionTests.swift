// Copyright 2026 Ergentics, LLC
// SPDX-License-Identifier: Apache-2.0

import PracticeLedger
import XCTest

@testable import OracleAdmission

@MainActor final class OracleAdmissionTests: XCTestCase {
    private struct Fixture: Decodable {
        struct Witness: Decodable {
            let family: String
            let dependencies: [String]
            let score: Double
        }

        let name: String
        let asserted: String
        let claimScore: Double
        let witnesses: [Witness]
        let minimumFamilies: Int
        let falsifierSettled: Bool
        let expected: String
    }

    private func load() throws -> [Fixture] {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "vectors", withExtension: "json"))
        return try JSONDecoder().decode([Fixture].self, from: Data(contentsOf: url))
    }

    private func claim(_ fixture: Fixture) throws -> ScoreClaim {
        let asserted: ScoreClass
        switch fixture.asserted {
        case "prediction": asserted = .prediction
        case "recorded": asserted = .recorded
        case "derived": asserted = .derived
        default:
            XCTFail(fixture.asserted)
            throw OracleInputError.emptyName
        }
        let event = try PracticeEvent(
            id: "item-\(fixture.name)", skillID: "skill", surface: .problems,
            kind: .workedExample, score: fixture.claimScore, timestampMs: 0)
        let witnesses = try fixture.witnesses.map {
            try ScoreWitness(family: $0.family, dependencies: $0.dependencies, score: $0.score)
        }
        return ScoreClaim(event: event, asserted: asserted, witnesses: witnesses)
    }

    func testDecisionTableMatchesPython() throws {
        let fixtures = try load()
        XCTAssertEqual(fixtures.count, 13)
        for fixture in fixtures {
            let judged = try OracleAdmission.judge(
                claim(fixture),
                minimumFamilies: fixture.minimumFamilies,
                falsifierSettled: fixture.falsifierSettled)
            switch judged {
            case .abstain(let reason):
                XCTAssertEqual(reason.rawValue, fixture.expected, fixture.name)
            case .seal(let sealed):
                XCTAssertEqual("seal", fixture.expected, fixture.name)
                XCTAssertEqual(sealed.event.score.value, fixture.claimScore, fixture.name)
                XCTAssertEqual(
                    sealed.familyCount,
                    Set(fixture.witnesses.map(\.family)).count,
                    fixture.name)
            }
        }
    }

    func testIllFormedInputDoesNotAbstain() {
        XCTAssertThrowsError(try WitnessFamily("")) { error in
            XCTAssertEqual(error as? OracleInputError, .emptyName)
        }
        XCTAssertThrowsError(try ScoreWitness(family: "a", dependencies: [], score: .nan)) { error in
            XCTAssertEqual(error as? OracleInputError, .invalidWitnessScore)
        }
        XCTAssertThrowsError(try OracleAdmission.judge(
            ScoreClaim(
                event: try PracticeEvent(
                    id: "item", skillID: "skill", surface: .quiz,
                    kind: .retrievalPractice, score: 1, timestampMs: 1),
                asserted: .derived, witnesses: []),
            minimumFamilies: 0)) { error in
            XCTAssertEqual(error as? OracleInputError, .minimumFamilies)
        }
    }

    func testAbstainDoesNotTouchTheLedger() async throws {
        let ledger = try PracticeLedger(lineage: 1)
        let capability = await ledger.issueCapability()
        let before = try await ledger.snapshot()
        let fixture = try XCTUnwrap(load().first { $0.name == "one-family" })
        let outcome = try await OracleAdmission.verify(claim(fixture), on: ledger, using: capability)
        guard case .abstained(.tooFewFamilies) = outcome else {
            XCTFail("Expected abstention")
            return
        }
        let after = try await ledger.snapshot()
        XCTAssertEqual(after, before)
    }

    func testSealVerifiesAndCommitIsSeparate() async throws {
        let ledger = try PracticeLedger(lineage: 1)
        let capability = await ledger.issueCapability()
        let fixture = try XCTUnwrap(load().first { $0.name == "two-families-seal" })
        let proposed = try claim(fixture)
        let outcome = try await OracleAdmission.verify(proposed, on: ledger, using: capability)
        guard case .verified(let ticket, let sealed) = outcome else {
            XCTFail("Expected a verified ticket")
            return
        }
        XCTAssertTrue(ticket.change.relationChanged)
        XCTAssertEqual(sealed.event, proposed.event)
        let during = try await ledger.snapshot()
        XCTAssertEqual(during.generation, 0)
        XCTAssertTrue(during.events.isEmpty)
        let committed = try await ledger.commit(ticket, using: capability)
        XCTAssertEqual(committed.generation, 1)
        XCTAssertEqual(committed.events, [sealed.event])
    }
}
