// Copyright 2026 Ergentics, LLC
// SPDX-License-Identifier: Apache-2.0

import ChangeFoundation
import OracleAdmission
import PracticeLedger

/// Timings for the public Swift path. Not performance evidence and not a comparison with Rust.
@main
struct FoundationBench {
    static func main() async throws {
        let iterations = iterations(from: CommandLine.arguments)
        print("# foundation-bench")
        print("# not-performance-evidence")
        print("# iterations=\(iterations)")
        print("# commitment-is-not-memoized: reading State.commitment encodes and hashes again")
        print("# excludes: disk, network, wasm, the Rust reader")

        let entries = (1...32).map { Entry(id: UInt64($0), value: Int64($0) * 3) }
        let order = entries.map(\.id)
        let state = try State(lineage: 1, generation: 0, entries: entries, order: order)
        let pinnedState = "58b8db0ebace624abdd96712379cbf5dfb7ce9b9bbfc0c17d1c00482b6c73c02"
        if state.commitment != pinnedState {
            fatalError("state commitment drifted from the pinned 32-entry sink")
        }

        let cached = measure {
            for _ in 0..<iterations {
                _ = state.commitment
            }
        }
        report(
            "state-commitment-reread",
            iterations: iterations,
            elapsed: cached,
            note: "includes: canonical bytes and SHA-256 of one already-built 32-entry state; excludes: State.init and the actor",
            sink: state.commitment)

        var rebuilt = ""
        let rebuild = try measureThrows {
            for _ in 0..<iterations {
                let next = try State(lineage: 1, generation: 0, entries: entries, order: order)
                rebuilt = next.commitment
            }
        }
        report(
            "state-rebuild",
            iterations: iterations,
            elapsed: rebuild,
            note: "includes: domain check, sort, canonical bytes, SHA-256; excludes: the actor. Control against state-commitment-reread",
            sink: rebuilt)

        let authority = ReferenceAuthority(initial: state)
        let capability = await authority.issueCapability()
        var current = state
        var lastID = current.stateID
        let commits = try await measureAsync {
            for _ in 0..<iterations {
                let proposal = CandidateTransition(
                    lineage: current.lineage,
                    baseGeneration: current.generation,
                    baseCommitment: current.commitment,
                    entries: current.entries,
                    order: current.order)
                let ticket = try await authority.verify(proposal, using: capability)
                let recorded = try await authority.commitRecording(ticket, using: capability)
                current = recorded.committed
                lastID = recorded.successor
            }
        }
        report(
            "empty-commit-sequence",
            iterations: iterations,
            elapsed: commits,
            note: "includes: actor hop, capability recheck, generation advance, re-encode. The consumed-ticket set grows by one each iteration. Not a steady state",
            sink: "\(lastID.generation) \(lastID.commitment)")

        let ledger = try PracticeLedger(lineage: 1)
        let ledgerCapability = await ledger.issueCapability()
        var ledgerSink = ""
        let appends = try await measureAsync {
            for index in 0..<iterations {
                let event = try PracticeEvent(
                    id: "bench-\(index)",
                    skillID: "bench",
                    surface: .moment,
                    kind: .retrievalPractice,
                    score: 1,
                    timestampMs: Int64(index))
                let ticket = try await ledger.verifyAppend(event, using: ledgerCapability)
                let recorded = try await ledger.commitRecording(ticket, using: ledgerCapability)
                ledgerSink = recorded.successor.commitment
            }
        }
        report(
            "practice-growing-log",
            iterations: iterations,
            elapsed: appends,
            note: "includes: re-encoding the whole practice log on every commit, actor hop, moment surface. Average ns/op is not a per-event constant; the log length grows",
            sink: ledgerSink)

        let claim = try ScoreClaim(
            event: PracticeEvent(
                id: "bench", skillID: "bench", surface: .moment,
                kind: .retrievalPractice, score: 1, timestampMs: 0),
            asserted: .derived,
            witnesses: [
                ScoreWitness(family: "bytes", dependencies: ["left"], score: 1),
                ScoreWitness(family: "recount", dependencies: ["right"], score: 1),
            ])
        var judged = 0
        let judges = try measureThrows {
            for _ in 0..<iterations {
                if case .seal = try OracleAdmission.judge(claim) { judged += 1 }
            }
        }
        report(
            "oracle-judge",
            iterations: iterations,
            elapsed: judges,
            note: "includes: family count, shared-dependency check, score-bit compare. Excludes: the ledger and commit",
            sink: "\(judged)")
    }
}

private func iterations(from arguments: [String]) -> Int {
    guard let flag = arguments.firstIndex(of: "--iterations"),
          arguments.indices.contains(flag + 1),
          let value = Int(arguments[flag + 1]),
          value > 0
    else { return 1_000 }
    return value
}

private func report(_ name: String, iterations: Int, elapsed: Duration, note: String, sink: String) {
    let parts = elapsed.components
    let total = parts.seconds * 1_000_000_000 + parts.attoseconds / 1_000_000_000
    let per = total / Int64(iterations)
    print("workload=\(name) iterations=\(iterations) total_ns=\(total) ns_per_op=\(per)")
    print("note=\(note)")
    print("sink=\(sink)")
}

private func measure(_ body: () -> Void) -> Duration {
    let clock = ContinuousClock()
    let start = clock.now
    body()
    return start.duration(to: clock.now)
}

private func measureThrows(_ body: () throws -> Void) rethrows -> Duration {
    let clock = ContinuousClock()
    let start = clock.now
    try body()
    return start.duration(to: clock.now)
}

@MainActor
private func measureAsync(_ body: () async throws -> Void) async rethrows -> Duration {
    let clock = ContinuousClock()
    let start = clock.now
    try await body()
    return start.duration(to: clock.now)
}
