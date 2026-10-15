//! `PL-LOG-v1`, then the fixed-binary carrier. Same bytes as `reference/make_practice_vectors.py`.

use crate::canonical::{chunk_payload, state_commitment};

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct PracticeEvent {
    pub id: String,
    pub skill_id: String,
    pub surface: u8,
    pub kind: u8,
    pub score_bits: u64,
    pub timestamp_ms: i64,
    pub confident: u8,
}

pub fn canonical_score_bits(score: f64) -> u64 {
    let score = if score == 0.0 { 0.0 } else { score };
    score.to_bits()
}

pub fn surface_byte(name: &str) -> Option<u8> {
    match name {
        "problems" => Some(1),
        "quiz" => Some(2),
        "recall" => Some(3),
        "moment" => Some(4),
        _ => None,
    }
}

pub fn kind_byte(name: &str) -> Option<u8> {
    match name {
        "WE" => Some(1),
        "PF" => Some(2),
        "RP" => Some(3),
        _ => None,
    }
}

pub fn log_bytes(events: &[PracticeEvent]) -> Vec<u8> {
    let mut bytes = b"PL-LOG-v1\0".to_vec();
    bytes.extend_from_slice(&(events.len() as u64).to_be_bytes());
    for event in events {
        push_str(&mut bytes, &event.id);
        push_str(&mut bytes, &event.skill_id);
        bytes.push(event.surface);
        bytes.push(event.kind);
        bytes.extend_from_slice(&event.score_bits.to_be_bytes());
        bytes.extend_from_slice(&event.timestamp_ms.to_be_bytes());
        bytes.push(event.confident);
    }
    bytes
}

pub fn practice_commitment(
    lineage: u64,
    generation: u64,
    events: &[PracticeEvent],
) -> (String, String) {
    let (entries, order) = chunk_payload(&log_bytes(events));
    state_commitment(lineage, generation, &entries, &order)
}

fn push_str(bytes: &mut Vec<u8>, text: &str) {
    let raw = text.as_bytes();
    bytes.extend_from_slice(&(raw.len() as u64).to_be_bytes());
    bytes.extend_from_slice(raw);
}
