//! commitment-reader 0.1.0.
//!
//! Reads `CF-STATE-v1` and `PL-LOG-v1` and returns the same SHA-256 hex as the
//! committed Python vectors. Swift still ships the ledger. This crate does not
//! issue capabilities or commit state.
//!
//! The `cdylib` is the off-process entry (native tests and `wasm32-unknown-unknown`).
//! Callers pass big-endian fields. That packing is only the call boundary.
//! The bytes that are hashed are the canonical profile.

mod canonical;
mod practice;

pub use canonical::{
    chunk_payload, relation_bytes, sha256_hex, state_bytes, state_commitment, Entry,
};
pub use practice::{
    canonical_score_bits, kind_byte, log_bytes, practice_commitment, surface_byte, PracticeEvent,
};

pub const READER_VERSION: &str = env!("CARGO_PKG_VERSION");

/// SHA-256 hex of one state carrier.
///
/// `entries` is `entry_bytes / 16` pairs of big-endian `(u64 id, i64 value)`.
/// `order` is `order_bytes / 8` big-endian `u64` ids.
/// On success, writes 64 lowercase hex bytes to `out` and returns 0.
/// Returns 1 when a length is not a multiple of the field width.
///
/// # Safety
///
/// `entries`, `order`, and `out` must be readable or writable for the given lengths.
/// `out` must hold 64 bytes.
#[no_mangle]
pub unsafe extern "C" fn cf_state_commitment_hex(
    lineage: u64,
    generation: u64,
    entries: *const u8,
    entry_bytes: u32,
    order: *const u8,
    order_bytes: u32,
    out: *mut u8,
) -> i32 {
    if entry_bytes % 16 != 0 || order_bytes % 8 != 0 || out.is_null() {
        return 1;
    }
    if entry_bytes > 0 && entries.is_null() || order_bytes > 0 && order.is_null() {
        return 1;
    }
    let entry_slice = if entry_bytes == 0 {
        &[]
    } else {
        unsafe { std::slice::from_raw_parts(entries, entry_bytes as usize) }
    };
    let order_slice = if order_bytes == 0 {
        &[]
    } else {
        unsafe { std::slice::from_raw_parts(order, order_bytes as usize) }
    };
    let parsed = match parse_entries(entry_slice) {
        Some(entries) => entries,
        None => return 1,
    };
    let order = match parse_order(order_slice) {
        Some(order) => order,
        None => return 1,
    };
    write_hex(out, &state_commitment(lineage, generation, &parsed, &order).0);
    0
}

/// SHA-256 hex of the state carrier for a practice log.
///
/// `packed` is a big-endian event list, not the canonical log itself:
/// `u64` count, then for each event a `u64` id length, UTF-8 id, `u64` skill
/// length, UTF-8 skill, surface byte, kind byte, 8 score bits, `i64` timestamp,
/// confidence byte (`0` absent, `1` false, `2` true).
///
/// # Safety
///
/// `packed` must be readable for `packed_len` bytes and `out` writable for 64.
#[no_mangle]
pub unsafe extern "C" fn pl_state_commitment_hex(
    lineage: u64,
    generation: u64,
    packed: *const u8,
    packed_len: u32,
    out: *mut u8,
) -> i32 {
    if out.is_null() || (packed_len > 0 && packed.is_null()) {
        return 1;
    }
    let packed = if packed_len == 0 {
        &[]
    } else {
        unsafe { std::slice::from_raw_parts(packed, packed_len as usize) }
    };
    let Some(events) = parse_packed_events(packed) else {
        return 1;
    };
    write_hex(out, &practice_commitment(lineage, generation, &events).0);
    0
}

#[no_mangle]
pub extern "C" fn alloc(len: u32) -> *mut u8 {
    let mut buffer = Vec::<u8>::with_capacity(len as usize);
    unsafe { buffer.set_len(len as usize) };
    let ptr = buffer.as_mut_ptr();
    std::mem::forget(buffer);
    ptr
}

/// # Safety
///
/// `ptr` must have come from [`alloc`] with the same `len`.
#[no_mangle]
pub unsafe extern "C" fn dealloc(ptr: *mut u8, len: u32) {
    if ptr.is_null() || len == 0 {
        return;
    }
    unsafe { drop(Vec::from_raw_parts(ptr, len as usize, len as usize)) };
}

fn write_hex(out: *mut u8, hex: &str) {
    unsafe { std::ptr::copy_nonoverlapping(hex.as_ptr(), out, 64) };
}

fn parse_entries(bytes: &[u8]) -> Option<Vec<Entry>> {
    let mut entries = Vec::with_capacity(bytes.len() / 16);
    for chunk in bytes.chunks(16) {
        let id = u64::from_be_bytes(chunk[..8].try_into().ok()?);
        let value = i64::from_be_bytes(chunk[8..].try_into().ok()?);
        entries.push(Entry { id, value });
    }
    Some(entries)
}

fn parse_order(bytes: &[u8]) -> Option<Vec<u64>> {
    bytes
        .chunks(8)
        .map(|chunk| chunk.try_into().ok().map(u64::from_be_bytes))
        .collect()
}

fn parse_packed_events(bytes: &[u8]) -> Option<Vec<PracticeEvent>> {
    let mut cursor = Cursor { bytes, index: 0 };
    let count = cursor.u64()?;
    let mut events = Vec::with_capacity(count as usize);
    for _ in 0..count {
        let id = cursor.string()?;
        let skill_id = cursor.string()?;
        let surface = cursor.byte()?;
        let kind = cursor.byte()?;
        let score_bits = cursor.u64()?;
        let timestamp_ms = cursor.i64()?;
        let confident = cursor.byte()?;
        events.push(PracticeEvent {
            id,
            skill_id,
            surface,
            kind,
            score_bits,
            timestamp_ms,
            confident,
        });
    }
    if cursor.index != cursor.bytes.len() {
        return None;
    }
    Some(events)
}

struct Cursor<'a> {
    bytes: &'a [u8],
    index: usize,
}

impl Cursor<'_> {
    fn take(&mut self, len: usize) -> Option<&[u8]> {
        let end = self.index.checked_add(len)?;
        if end > self.bytes.len() {
            return None;
        }
        let slice = &self.bytes[self.index..end];
        self.index = end;
        Some(slice)
    }

    fn u64(&mut self) -> Option<u64> {
        Some(u64::from_be_bytes(self.take(8)?.try_into().ok()?))
    }

    fn i64(&mut self) -> Option<i64> {
        Some(i64::from_be_bytes(self.take(8)?.try_into().ok()?))
    }

    fn byte(&mut self) -> Option<u8> {
        Some(*self.take(1)?.first()?)
    }

    fn string(&mut self) -> Option<String> {
        let len = self.u64()?;
        let len = usize::try_from(len).ok()?;
        let bytes = self.take(len)?;
        Some(String::from_utf8(bytes.to_vec()).ok()?)
    }
}
