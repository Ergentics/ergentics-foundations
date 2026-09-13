import XCTest
import ChangeFoundation

@MainActor final class FoundationTests: XCTestCase {
    func initial(generation: UInt64 = 0) throws -> State {
        try State(lineage: 1, generation: generation,
                  entries: [Entry(id: 1, value: 10), Entry(id: 2, value: 20)], order: [1, 2])
    }
    func proposal(_ state: State, entries: [Entry]? = nil, order: [UInt64]? = nil) -> CandidateTransition {
        CandidateTransition(lineage: state.lineage, baseGeneration: state.generation,
                            baseCommitment: state.commitment, entries: entries ?? state.entries,
                            order: order ?? state.order)
    }
    func expect(_ error: Rejection, action: () async throws -> Void) async {
        do { try await action(); XCTFail("Expected rejection") }
        catch let actual as Rejection { XCTAssertEqual(actual, error) }
        catch { XCTFail("Unexpected error type") }
    }
    func testIndependentCanonicalVectors() throws {
        struct Vector: Decodable {
            let name: String; let lineage: UInt64; let generation: UInt64
            let entries: [Entry]; let order: [UInt64]
            let expectedStateCommitment: String; let expectedRelationCommitment: String
        }
        let url = try XCTUnwrap(Bundle.module.url(forResource: "vectors", withExtension: "json"))
        let vectors = try JSONDecoder().decode([Vector].self, from: Data(contentsOf: url))
        XCTAssertEqual(vectors.count, 6)
        for v in vectors {
            let s = try State(lineage: v.lineage, generation: v.generation, entries: v.entries, order: v.order)
            XCTAssertEqual(s.commitment, v.expectedStateCommitment, v.name)
            XCTAssertEqual(s.relation.commitment, v.expectedRelationCommitment, v.name)
        }
    }
    func testVerifyDoesNotCommitAndEmptyTransitionAdvances() async throws {
        let s = try initial(); let owner = ReferenceAuthority(initial: s)
        let cap = await owner.issueCapability(); let ticket = try await owner.verify(proposal(s), using: cap)
        XCTAssertTrue(ticket.change.isEmpty)
        let before = await owner.snapshot(); XCTAssertEqual(before, s)
        let after = try await owner.commit(ticket, using: cap)
        XCTAssertEqual(after.generation, 1); XCTAssertEqual(after.relation, s.relation)
        XCTAssertNotEqual(after.commitment, s.commitment)
    }
    func testRelationPersistsAcrossOrderChange() async throws {
        let s = try initial(); let owner = ReferenceAuthority(initial: s); let cap = await owner.issueCapability()
        let ticket = try await owner.verify(proposal(s, order: [2,1]), using: cap)
        XCTAssertFalse(ticket.change.relationChanged); XCTAssertTrue(ticket.change.orderChanged)
        let next = try await owner.commit(ticket, using: cap)
        XCTAssertEqual(next.relation.commitment, s.relation.commitment); XCTAssertNotEqual(next.order, s.order)
    }
    func testConsequentialSourceChange() async throws {
        let s = try initial(); let owner = ReferenceAuthority(initial: s); let cap = await owner.issueCapability()
        let ticket = try await owner.verify(proposal(s, entries: [Entry(id: 1,value:11),Entry(id:2,value:20)]), using: cap)
        XCTAssertTrue(ticket.change.relationChanged)
        let next = try await owner.commit(ticket, using: cap); XCTAssertNotEqual(next.relation, s.relation)
    }
    func testReplayRejected() async throws {
        let s = try initial(); let owner = ReferenceAuthority(initial: s); let cap = await owner.issueCapability()
        let ticket = try await owner.verify(proposal(s), using: cap); _ = try await owner.commit(ticket, using: cap)
        await expect(.replay) { _ = try await owner.commit(ticket, using: cap) }
    }
    func testStaleProposalAndVerifiedSiblingRecheckedAtCommit() async throws {
        let s = try initial(); let owner = ReferenceAuthority(initial: s); let cap = await owner.issueCapability()
        let a = try await owner.verify(proposal(s), using: cap)
        let b = try await owner.verify(proposal(s, order:[2,1]), using: cap)
        _ = try await owner.commit(a, using: cap)
        await expect(.staleGeneration) { _ = try await owner.verify(self.proposal(s), using: cap) }
        await expect(.staleGeneration) { _ = try await owner.commit(b, using: cap) }
    }
    func testRevocationBetweenVerifyAndCommit() async throws {
        let s = try initial(); let owner = ReferenceAuthority(initial: s); let cap = await owner.issueCapability()
        let ticket = try await owner.verify(proposal(s), using: cap); try await owner.revokeCapabilities()
        await expect(.invalidCapability) { _ = try await owner.commit(ticket, using: cap) }
        let fresh = await owner.issueCapability()
        await expect(.invalidCapability) { _ = try await owner.commit(ticket, using: fresh) }
        let unchanged = await owner.snapshot(); XCTAssertEqual(unchanged, s)
    }
    func testSiblingAuthorityCannotUseIdenticalRepresentation() async throws {
        let s = try initial(); let a = ReferenceAuthority(initial: s); let b = ReferenceAuthority(initial: s)
        let ca = await a.issueCapability(); let cb = await b.issueCapability()
        let ea = await a.evidence(); let eb = await b.evidence(); XCTAssertEqual(ea, eb)
        let ticket = try await a.verify(proposal(s), using: ca)
        await expect(.invalidCapability) { _ = try await b.commit(ticket, using: cb) }
        await expect(.invalidCapability) { _ = try await b.verify(self.proposal(s), using: ca) }
    }
    func testAnotherCurrentCapabilityCannotConsumeTicket() async throws {
        let s = try initial(); let owner = ReferenceAuthority(initial: s)
        let ca = await owner.issueCapability(); let cb = await owner.issueCapability()
        let ticket = try await owner.verify(proposal(s), using: ca)
        await expect(.invalidCapability) { _ = try await owner.commit(ticket, using: cb) }
    }
    func testWrongLineageAndCommitment() async throws {
        let s = try initial(); let owner = ReferenceAuthority(initial: s); let cap = await owner.issueCapability()
        await expect(.wrongLineage) { _ = try await owner.verify(CandidateTransition(lineage:2,baseGeneration:0,baseCommitment:s.commitment,entries:s.entries,order:s.order),using:cap) }
        await expect(.wrongCommitment) { _ = try await owner.verify(CandidateTransition(lineage:1,baseGeneration:0,baseCommitment:"synthetic-invalid",entries:s.entries,order:s.order),using:cap) }
    }
    func testInvalidDomainRejectedWithoutMutation() async throws {
        let s = try initial(); let owner = ReferenceAuthority(initial: s); let cap = await owner.issueCapability()
        for order: [UInt64] in [[1,1],[1],[1,2,3]] {
            await expect(.invalidDomain) { _ = try await owner.verify(self.proposal(s,order:order),using:cap) }
        }
        await expect(.invalidDomain) { _ = try await owner.verify(self.proposal(s,entries:[Entry(id:1,value:10),Entry(id:1,value:20)]),using:cap) }
        let unchanged = await owner.snapshot(); XCTAssertEqual(unchanged,s)
    }
    func testGenerationOverflowRejected() async throws {
        let s = try initial(generation: .max); let owner = ReferenceAuthority(initial:s); let cap = await owner.issueCapability()
        await expect(.generationExhausted) { _ = try await owner.verify(self.proposal(s),using:cap) }
    }
}
