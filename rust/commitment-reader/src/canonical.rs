//! Fixed-binary state carrier. Same bytes as `reference/make_vectors.py`.

use sha2::{Digest, Sha256};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Entry {
    pub id: u64,
    pub value: i64,
}

pub fn sha256_hex(bytes: &[u8]) -> String {
    let digest = Sha256::digest(bytes);
    const HEX: &[u8; 16] = b"0123456789abcdef";
    let mut out = String::with_capacity(64);
    for byte in digest {
        out.push(HEX[(byte >> 4) as usize] as char);
        out.push(HEX[(byte & 0xf) as usize] as char);
    }
    out
}

pub fn relation_bytes(entries: &[Entry]) -> Vec<u8> {
    let mut sorted = entries.to_vec();
    sorted.sort_by_key(|entry| entry.id);
    let mut bytes = b"CF-RELATION-v1\0".to_vec();
    bytes.extend_from_slice(&(sorted.len() as u64).to_be_bytes());
    for entry in sorted {
        bytes.extend_from_slice(&entry.id.to_be_bytes());
        bytes.extend_from_slice(&entry.value.to_be_bytes());
    }
    bytes
}

pub fn state_bytes(lineage: u64, generation: u64, entries: &[Entry], order: &[u64]) -> Vec<u8> {
    let mut bytes = b"CF-STATE-v1\0".to_vec();
    bytes.extend_from_slice(&lineage.to_be_bytes());
    bytes.extend_from_slice(&generation.to_be_bytes());
    bytes.extend(relation_bytes(entries));
    bytes.extend_from_slice(&(order.len() as u64).to_be_bytes());
    for id in order {
        bytes.extend_from_slice(&id.to_be_bytes());
    }
    bytes
}

/// Split a practice payload into 8-byte carrier entries. Ids are positions, starting at 1.
pub fn chunk_payload(payload: &[u8]) -> (Vec<Entry>, Vec<u64>) {
    let pad = (8 - (payload.len() % 8)) % 8;
    let mut raw = Vec::with_capacity(payload.len() + pad);
    raw.extend_from_slice(payload);
    raw.extend(std::iter::repeat(0).take(pad));
    let mut entries = Vec::with_capacity(raw.len() / 8);
    let mut order = Vec::with_capacity(raw.len() / 8);
    for (index, chunk) in raw.chunks_exact(8).enumerate() {
        let id = (index as u64) + 1;
        let value = i64::from_be_bytes(chunk.try_into().expect("8 bytes"));
        entries.push(Entry { id, value });
        order.push(id);
    }
    (entries, order)
}

pub fn state_commitment(lineage: u64, generation: u64, entries: &[Entry], order: &[u64]) -> (String, String) {
    let relation = sha256_hex(&relation_bytes(entries));
    let state = sha256_hex(&state_bytes(lineage, generation, entries, order));
    (state, relation)
}
