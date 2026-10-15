// Copyright 2026 Ergentics, LLC
// SPDX-License-Identifier: Apache-2.0

import ChangeFoundation
import XCTest

@testable import PracticeLedger

@MainActor final class PracticeLedgerTests: XCTestCase {
    private struct Fixture: Decodable {
        struct Event: Decodable {
            let id: String
            let skillID: String
            let surface: String
            let kind: String
            let score: Double
            let timestampMs: Int64
            let confident: Bool?
        }

        let name: String
        let lineage: UInt64
        let generation: UInt64
        let events: [Event]
        let expectedStateCommitment: String
        let expectedRelationCommitment: String
    }

    private func loadFixtures() throws -> [Fixture] {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "vectors", withExtension: "json"))
        return try JSONDecoder().decode([Fixture].self, from: Data(contentsOf: url))
    }

    private func practiceEvent(_ raw: Fixture.Event) throws -> PracticeEvent {
        let surface: PracticeSurface
        switch raw.surface {
        case "problems": surface = .problems
        case "quiz": surface = .quiz
        case "recall": surface = .recall
        case "moment": surface = .moment
        default:
            XCTFail("Unknown surface \(raw.surface)")
            throw PracticeRejection.payloadCorrupt
        }
        guard let kind = LessonKind(code: raw.kind) else {
            XCTFail("Unknown kind \(raw.kind)")
            throw PracticeRejection.payloadCorrupt
        }
        return try PracticeEvent(
            id: raw.id, skillID: raw.skillID, surface: surface, kind: kind,
            score: raw.score, timestampMs: raw.timestampMs, confident: raw.confident)
    }

    private func expectSync(_ expected: PracticeRejection, _ body: () throws -> Void) {
        do {
            try body()
            XCTFail("Expected \(expected)")
        } catch let actual as PracticeRejection {
            XCTAssertEqual(actual, expected)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    private func expectPractice(
        _ expected: PracticeRejection, _ body: () async throws -> Void
    ) async {
        do {
            try await body()
            XCTFail("Expected \(expected)")
        } catch let actual as PracticeRejection {
            XCTAssertEqual(actual, expected)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    private func expectAuthority(_ expected: Rejection, _ body: () async throws -> Void) async {
        do {
            try await body()
            XCTFail("Expected \(expected)")
        } catch let actual as Rejection {
            XCTAssertEqual(actual, expected)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testCanonicalVectorsMatchIndependentBytes() async throws {
        let fixtures = try loadFixtures()
        XCTAssertEqual(fixtures.count, 6)
        for fixture in fixtures {
            let events = try fixture.events.map(practiceEvent)
            let state = try PracticeEncoding.state(
                lineage: fixture.lineage, generation: fixture.generation, events: events)
            XCTAssertEqual(state.commitment, fixture.expectedStateCommitment, fixture.name)
            XCTAssertEqual(state.relation.commitment, fixture.expectedRelationCommitment, fixture.name)
            XCTAssertEqual(try PracticeEncoding.decodedEvents(in: state), events, fixture.name)
        }
        let empty0 = try XCTUnwrap(fixtures.first { $0.name == "empty-generation-0" })
        let empty1 = try XCTUnwrap(fixtures.first { $0.name == "empty-generation-1" })
        XCTAssertEqual(empty0.expectedRelationCommitment, empty1.expectedRelationCommitment)
        XCTAssertNotEqual(empty0.expectedStateCommitment, empty1.expectedStateCommitment)
    }

    func testScoreBitsRejectNonCanonicalValues() async throws {
        XCTAssertEqual(try UnitScore(1).bits, 0x3ff0_0000_0000_0000)
        XCTAssertEqual(try UnitScore(0.5).bits, 0x3fe0_0000_0000_0000)
        XCTAssertEqual(try UnitScore(0).bits, 0)
        XCTAssertEqual(try UnitScore(-0.0).bits, 0)
        XCTAssertEqual(try UnitScore(0), try UnitScore(-0.0))
        expectSync(.nonFiniteScore) { _ = try UnitScore(.nan) }
        expectSync(.nonFiniteScore) { _ = try UnitScore(.infinity) }
        expectSync(.scoreOutOfRange) { _ = try UnitScore(1.1) }
        expectSync(.scoreOutOfRange) { _ = try UnitScore(-0.1) }
        expectSync(.emptyIdentifier) { _ = try EventID("") }
        expectSync(.embeddedNul) { _ = try SkillID("a\u{0}b") }
        expectSync(.identifierTooLong) { _ = try EventID(String(repeating: "a", count: 257)) }
        _ = try EventID(String(repeating: "a", count: 256))
    }

    func testAppendCommitsDecodedEventAndMatchesVector() async throws {
        let fixtures = try loadFixtures()
        let vector = try XCTUnwrap(fixtures.first { $0.name == "one-worked-example" })
        let event = try practiceEvent(try XCTUnwrap(vector.events.first))
        let ledger = try PracticeLedger(lineage: 1)
        let capability = await ledger.issueCapability()
        let before = try await ledger.snapshot()
        XCTAssertEqual(before.generation, 0)
        XCTAssertTrue(before.events.isEmpty)

        let ticket = try await ledger.verifyAppend(event, using: capability)
        XCTAssertTrue(ticket.change.relationChanged)
        let during = try await ledger.snapshot()
        XCTAssertEqual(during, before)

        let committed = try await ledger.commit(ticket, using: capability)
        XCTAssertEqual(committed.generation, 1)
        XCTAssertEqual(committed.events, [event])
        XCTAssertEqual(committed.commitment, vector.expectedStateCommitment)
        XCTAssertEqual(committed.relationCommitment, vector.expectedRelationCommitment)
        let reread = try await ledger.snapshot()
        XCTAssertEqual(reread, committed)
    }

    func testSamePayloadAdvancesGenerationWithoutChangingRelation() async throws {
        let ledger = try PracticeLedger(lineage: 1)
        let capability = await ledger.issueCapability()
        let before = try await ledger.snapshot()
        let ticket = try await ledger.verifySamePayload(using: capability)
        XCTAssertTrue(ticket.change.isEmpty)
        let after = try await ledger.commit(ticket, using: capability)
        XCTAssertEqual(after.generation, 1)
        XCTAssertEqual(after.events, before.events)
        XCTAssertEqual(after.relationCommitment, before.relationCommitment)
        XCTAssertNotEqual(after.commitment, before.commitment)
    }

    func testSubmissionOrderIsPreservedWhenIdentifiersAreNotSorted() async throws {
        let fixtures = try loadFixtures()
        let vector = try XCTUnwrap(fixtures.first { $0.name == "two-events-submission-order" })
        let events = try vector.events.map(practiceEvent)
        let ledger = try PracticeLedger(lineage: 4)
        let capability = await ledger.issueCapability()
        var ticket = try await ledger.verifyAppend(events[0], using: capability)
        _ = try await ledger.commit(ticket, using: capability)
        ticket = try await ledger.verifyAppend(events[1], using: capability)
        let committed = try await ledger.commit(ticket, using: capability)
        XCTAssertEqual(committed.events.map(\.id.rawValue), ["b", "a"])
        XCTAssertEqual(committed.generation, 2)
        XCTAssertEqual(committed.commitment, vector.expectedStateCommitment)
    }

    func testDuplicateIdentifierDoesNotMutate() async throws {
        let ledger = try PracticeLedger(lineage: 1)
        let capability = await ledger.issueCapability()
        let event = try PracticeEvent(
            id: "rect-area-2x3", skillID: "rect-area", surface: .problems,
            kind: .workedExample, score: 1, timestampMs: 1_700_000_000_000)
        let ticket = try await ledger.verifyAppend(event, using: capability)
        let committed = try await ledger.commit(ticket, using: capability)
        await expectPractice(.duplicateEventID) {
            _ = try await ledger.verifyAppend(event, using: capability)
        }
        let afterDuplicate = try await ledger.snapshot()
        XCTAssertEqual(afterDuplicate, committed)
        let again = try PracticeEvent(
            id: "rect-area-2x4", skillID: "rect-area", surface: .problems,
            kind: .retrievalPractice, score: 0, timestampMs: 1_700_000_000_100)
        let next = try await ledger.commit(
            try await ledger.verifyAppend(again, using: capability), using: capability)
        XCTAssertEqual(next.events.map(\.id.rawValue), ["rect-area-2x3", "rect-area-2x4"])
    }

    func testStaleSiblingAndReplayLeaveTheCommittedLog() async throws {
        let ledger = try PracticeLedger(lineage: 1)
        let capability = await ledger.issueCapability()
        let first = try PracticeEvent(
            id: "one", skillID: "rect-area", surface: .problems,
            kind: .workedExample, score: 1, timestampMs: 10)
        let second = try PracticeEvent(
            id: "two", skillID: "tri-area", surface: .quiz,
            kind: .productiveFailure, score: 0.5, timestampMs: 20, confident: true)
        let older = try await ledger.verifyAppend(first, using: capability)
        let sibling = try await ledger.verifyAppend(second, using: capability)
        let committed = try await ledger.commit(older, using: capability)
        await expectAuthority(.staleGeneration) {
            _ = try await ledger.commit(sibling, using: capability)
        }
        await expectAuthority(.replay) {
            _ = try await ledger.commit(older, using: capability)
        }
        let afterRejection = try await ledger.snapshot()
        XCTAssertEqual(afterRejection, committed)
        XCTAssertEqual(committed.events, [first])
    }

    func testRevocationAndSiblingIssuerCannotCommit() async throws {
        let left = try PracticeLedger(lineage: 1)
        let right = try PracticeLedger(lineage: 1)
        let leftCapability = await left.issueCapability()
        let rightCapability = await right.issueCapability()
        let event = try PracticeEvent(
            id: "one", skillID: "rect-area", surface: .recall,
            kind: .retrievalPractice, score: 0, timestampMs: -1, confident: false)
        let ticket = try await left.verifyAppend(event, using: leftCapability)
        let leftEvidence = try await left.snapshot().evidence
        let rightEvidence = try await right.snapshot().evidence
        XCTAssertEqual(leftEvidence, rightEvidence)
        await expectAuthority(.invalidCapability) {
            _ = try await right.commit(ticket, using: rightCapability)
        }
        try await left.revokeCapabilities()
        await expectAuthority(.invalidCapability) {
            _ = try await left.commit(ticket, using: leftCapability)
        }
        let unchanged = try await left.snapshot()
        XCTAssertTrue(unchanged.events.isEmpty)
        XCTAssertEqual(unchanged.generation, 0)
    }

    func testGenerationExhaustionDoesNotWrap() async throws {
        let ledger = try PracticeLedger(lineage: 1, generation: .max)
        let capability = await ledger.issueCapability()
        await expectAuthority(.generationExhausted) {
            _ = try await ledger.verifySamePayload(using: capability)
        }
        let snap = try await ledger.snapshot()
        XCTAssertEqual(snap.generation, .max)
        XCTAssertTrue(snap.events.isEmpty)
    }

    func testCarrierGarbageIsNotAPracticeLog() async throws {
        let junk = try State(lineage: 1, generation: 0, entries: [Entry(id: 1, value: 0)], order: [1])
        expectSync(.payloadCorrupt) { _ = try PracticeEncoding.decodedEvents(in: junk) }
    }
}
