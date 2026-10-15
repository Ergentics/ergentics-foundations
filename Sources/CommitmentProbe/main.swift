// Copyright 2026 Ergentics, LLC
// SPDX-License-Identifier: Apache-2.0

import ChangeFoundation

/// Prints one canonical commitment. This probe does not issue a capability,
/// verify a proposal, or commit. It is the compiler's WASM check, not a second issuer.
@main
struct CommitmentProbe {
    static func main() throws {
        let state = try State(
            lineage: 1, generation: 0,
            entries: [Entry(id: 1, value: 10), Entry(id: 2, value: 20)],
            order: [1, 2])
        let expected = "d9a07b92d21590167b300c10be7410322ecb78ed1a56ee0e531803fe263ccc22"
        guard state.commitment == expected else { fatalError("commitment drifted") }
        print(state.commitment)
    }
}
