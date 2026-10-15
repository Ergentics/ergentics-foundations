// Copyright 2026 Ergentics, LLC
// SPDX-License-Identifier: Apache-2.0

import CanonicalBytes

/// Stable 64-byte slot in this module's memory. The pointer returned to the
/// page addresses this allocation, not a temporary array.
nonisolated(unsafe) private let storage: UnsafeMutablePointer<UInt8> = {
    let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
    pointer.initialize(repeating: 0, count: 64)
    return pointer
}()

/// Constructs the synthetic-base state and writes `State.commitment` into the
/// stable buffer. Lineage 1, generation 0, entries (1, 10) and (2, 20), order
/// 1 then 2. Returns 0 when 64 hex bytes were written. This guest does not
/// issue a capability, verify, or commit.
#if arch(wasm32)
@_expose(wasm, "cf_synthetic_base_hex")
@_cdecl("cf_synthetic_base_hex")
#endif
nonisolated func cfSyntheticBaseHex() -> Int32 {
    let state: State
    do {
        state = try State(
            lineage: 1, generation: 0,
            entries: [Entry(id: 1, value: 10), Entry(id: 2, value: 20)],
            order: [1, 2])
    } catch {
        return 1
    }
    let bytes = Array(state.commitment.utf8)
    guard bytes.count == 64 else { return 2 }
    for index in 0..<64 { storage[index] = bytes[index] }
    return 0
}

#if arch(wasm32)
@_expose(wasm, "cf_synthetic_base_ptr")
@_cdecl("cf_synthetic_base_ptr")
#endif
nonisolated func cfSyntheticBasePtr() -> UnsafePointer<UInt8> {
    UnsafePointer(storage)
}

#if !arch(wasm32)
@main
struct CommitmentGuestHost {
    static func main() {
        let rc = cfSyntheticBaseHex()
        guard rc == 0 else { fatalError("commitment guest failed") }
        let pointer = cfSyntheticBasePtr()
        var bytes = [UInt8](repeating: 0, count: 64)
        for index in 0..<64 { bytes[index] = pointer[index] }
        print(String(decoding: bytes, as: UTF8.self))
    }
}
#endif
