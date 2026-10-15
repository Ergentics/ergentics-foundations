// Copyright 2026 Ergentics, LLC
// SPDX-License-Identifier: Apache-2.0

import ChangeFoundation

/// `PL-LOG-v1` payload, then the fixed-binary v1 state carrier.
///
/// The practice bytes are a length-delimited log. They are split into 8-byte chunks,
/// zero-padded, and stored as `Entry` values so the existing state commitment covers them.
/// Generation and lineage stay in the state wrapper, not in the log, so committing the same
/// events again is an empty consequential change: the relation commitment is stable and the
/// state commitment still advances.
///
/// Chunk ids are positions, not hashes of event ids. Hashing an id into a `UInt64` would
/// alias distinct events. Reordering practice events therefore changes the relation; this
/// adapter does not claim the order-only relation split for practice records.
enum PracticeEncoding {
    static func state(lineage: UInt64, generation: UInt64, events: [PracticeEvent]) throws -> State {
        let ids = events.map(\.id)
        guard Set(ids).count == ids.count else { throw PracticeRejection.duplicateEventID }
        let (entries, order) = chunks(logBytes(events))
        let state: State
        do {
            state = try State(lineage: lineage, generation: generation, entries: entries, order: order)
        } catch {
            throw PracticeRejection.payloadCorrupt
        }
        let decoded = try decodedEvents(in: state)
        guard decoded == events else { throw PracticeRejection.payloadCorrupt }
        return state
    }

    static func transition(from base: State, events: [PracticeEvent]) throws -> CandidateTransition {
        let proposed = try state(lineage: base.lineage, generation: base.generation, events: events)
        return CandidateTransition(
            lineage: base.lineage,
            baseGeneration: base.generation,
            baseCommitment: base.commitment,
            entries: proposed.entries,
            order: proposed.order)
    }

    static func decodedEvents(in state: State) throws -> [PracticeEvent] {
        try parse(rawBytes(from: state))
    }

    static func snapshot(from state: State) throws -> PracticeSnapshot {
        let events = try decodedEvents(in: state)
        return PracticeSnapshot(
            lineage: state.lineage,
            generation: state.generation,
            commitment: state.commitment,
            relationCommitment: state.relation.commitment,
            events: events)
    }

    private static func logBytes(_ events: [PracticeEvent]) -> [UInt8] {
        var bytes = Array("PL-LOG-v1\u{0}".utf8)
        append(UInt64(events.count), to: &bytes)
        for event in events {
            appendString(event.id.rawValue, to: &bytes)
            appendString(event.skillID.rawValue, to: &bytes)
            bytes.append(event.surface.rawValue)
            bytes.append(event.kind.rawValue)
            append(event.score.bits, to: &bytes)
            append(UInt64(bitPattern: event.timestampMs), to: &bytes)
            switch event.confident {
            case nil: bytes.append(0)
            case false?: bytes.append(1)
            case true?: bytes.append(2)
            }
        }
        return bytes
    }

    private static func chunks(_ payload: [UInt8]) -> (entries: [Entry], order: [UInt64]) {
        var raw = payload
        let remainder = raw.count % 8
        if remainder != 0 { raw.append(contentsOf: repeatElement(0, count: 8 - remainder)) }
        var entries: [Entry] = []
        var order: [UInt64] = []
        entries.reserveCapacity(raw.count / 8)
        var offset = 0
        var id: UInt64 = 1
        while offset < raw.count {
            let bits = readUInt64(raw[offset..<(offset + 8)])
            entries.append(Entry(id: id, value: Int64(bitPattern: bits)))
            order.append(id)
            id += 1
            offset += 8
        }
        return (entries, order)
    }

    private static func rawBytes(from state: State) throws -> [UInt8] {
        let byID = Dictionary(uniqueKeysWithValues: state.entries.map { ($0.id, $0.value) })
        var raw: [UInt8] = []
        raw.reserveCapacity(state.order.count * 8)
        for id in state.order {
            guard let value = byID[id] else { throw PracticeRejection.payloadCorrupt }
            append(UInt64(bitPattern: value), to: &raw)
        }
        return raw
    }

    private static func parse(_ raw: [UInt8]) throws -> [PracticeEvent] {
        var parser = Parser(raw: raw)
        let tag = Array("PL-LOG-v1\u{0}".utf8)
        let got = try parser.take(tag.count)
        guard got.elementsEqual(tag) else { throw PracticeRejection.payloadCorrupt }
        let count = readUInt64(try parser.take(8))
        let remaining = raw.count - parser.cursor
        // Every event is at least an empty-rejected string pair plus the fixed tail (37 bytes).
        guard count <= UInt64(remaining / 37) else { throw PracticeRejection.payloadCorrupt }
        var events: [PracticeEvent] = []
        events.reserveCapacity(Int(count))
        for _ in 0..<Int(count) {
            events.append(try parser.event())
        }
        let rest = raw[parser.cursor...]
        guard rest.count < 8, rest.allSatisfy({ $0 == 0 }) else { throw PracticeRejection.payloadCorrupt }
        guard Set(events.map(\.id)).count == events.count else { throw PracticeRejection.payloadCorrupt }
        return events
    }

    private static func append(_ value: UInt64, to bytes: inout [UInt8]) {
        for shift in stride(from: 56, through: 0, by: -8) {
            bytes.append(UInt8(truncatingIfNeeded: value >> UInt64(shift)))
        }
    }

    private static func appendString(_ value: String, to bytes: inout [UInt8]) {
        let utf8 = Array(value.utf8)
        append(UInt64(utf8.count), to: &bytes)
        bytes.append(contentsOf: utf8)
    }

    private static func readUInt64(_ bytes: ArraySlice<UInt8>) -> UInt64 {
        var n: UInt64 = 0
        for byte in bytes { n = (n << 8) | UInt64(byte) }
        return n
    }
}

private struct Parser {
    let raw: [UInt8]
    var cursor = 0

    mutating func take(_ count: Int) throws -> ArraySlice<UInt8> {
        guard count >= 0, cursor <= raw.count, count <= raw.count - cursor else {
            throw PracticeRejection.payloadCorrupt
        }
        let end = cursor + count
        let slice = raw[cursor..<end]
        cursor = end
        return slice
    }

    mutating func event() throws -> PracticeEvent {
        let id = try string()
        let skillID = try string()
        let surfaceByte = try take(1)
        let kindByte = try take(1)
        guard let surface = surfaceByte.first.flatMap(PracticeSurface.init(rawValue:)),
              let kind = kindByte.first.flatMap(LessonKind.init(rawValue:))
        else { throw PracticeRejection.payloadCorrupt }
        let bits = readScoreBits(try take(8))
        guard bits != 0x8000_0000_0000_0000 else { throw PracticeRejection.payloadCorrupt }
        let scoreValue = Double(bitPattern: bits)
        guard scoreValue.isFinite, (0...1).contains(scoreValue) else { throw PracticeRejection.payloadCorrupt }
        let timestamp = Int64(bitPattern: readFixed(try take(8)))
        let flag = try take(1).first
        let confident: Bool?
        switch flag {
        case 0: confident = nil
        case 1: confident = false
        case 2: confident = true
        default: throw PracticeRejection.payloadCorrupt
        }
        do {
            let event = try PracticeEvent(
                id: id, skillID: skillID, surface: surface, kind: kind,
                score: scoreValue, timestampMs: timestamp, confident: confident)
            guard event.score.bits == bits else { throw PracticeRejection.payloadCorrupt }
            return event
        } catch let rejection as PracticeRejection {
            throw rejection == .payloadCorrupt ? rejection : PracticeRejection.payloadCorrupt
        } catch {
            throw PracticeRejection.payloadCorrupt
        }
    }

    private mutating func string() throws -> String {
        let length = readFixed(try take(8))
        guard length >= 1, length <= UInt64(IdentifierRules.maxUTF8Bytes) else {
            throw PracticeRejection.payloadCorrupt
        }
        let bytes = Array(try take(Int(length)))
        guard !bytes.contains(0), let text = String(bytes: bytes, encoding: .utf8), Array(text.utf8) == bytes else {
            throw PracticeRejection.payloadCorrupt
        }
        return text
    }

    private func readFixed(_ bytes: ArraySlice<UInt8>) -> UInt64 {
        var n: UInt64 = 0
        for byte in bytes { n = (n << 8) | UInt64(byte) }
        return n
    }

    private func readScoreBits(_ bytes: ArraySlice<UInt8>) -> UInt64 {
        readFixed(bytes)
    }
}
