//! commitment-reader 0.1.0 against the committed Python vectors.
//!
//! `Tests/ChangeFoundationTests/vectors.json` comes from `reference/make_vectors.py`.
//! `Tests/PracticeLedgerTests/vectors.json` comes from `reference/make_practice_vectors.py`.
//! Equality is exact. There is no f32 slack: these fields are integers and canonical IEEE bits.

use commitment_reader::{
    canonical_score_bits, kind_byte, practice_commitment, state_commitment, surface_byte, Entry,
    PracticeEvent, READER_VERSION,
};
use serde::Deserialize;
use std::path::PathBuf;

fn repo_file(relative: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../..")
        .join(relative)
}

#[test]
fn version_is_named() {
    assert_eq!(READER_VERSION, "0.1.0");
}

#[derive(Deserialize)]
struct StateVector {
    name: String,
    lineage: u64,
    generation: u64,
    entries: Vec<JsonEntry>,
    order: Vec<u64>,
    #[serde(rename = "expectedStateCommitment")]
    expected_state: String,
    #[serde(rename = "expectedRelationCommitment")]
    expected_relation: String,
}

#[derive(Deserialize)]
struct JsonEntry {
    id: u64,
    value: i64,
}

#[test]
fn state_vectors_match_python() {
    let file = repo_file("Tests/ChangeFoundationTests/vectors.json");
    let vectors: Vec<StateVector> =
        serde_json::from_reader(std::fs::File::open(&file).expect("state vectors")).unwrap();
    assert_eq!(vectors.len(), 6, "the six canonical vectors");
    for vector in vectors {
        let entries: Vec<Entry> = vector
            .entries
            .iter()
            .map(|entry| Entry { id: entry.id, value: entry.value })
            .collect();
        let (state, relation) =
            state_commitment(vector.lineage, vector.generation, &entries, &vector.order);
        assert_eq!(state, vector.expected_state, "{}", vector.name);
        assert_eq!(relation, vector.expected_relation, "{}", vector.name);
    }
}

#[derive(Deserialize)]
struct PracticeVector {
    name: String,
    lineage: u64,
    generation: u64,
    events: Vec<JsonEvent>,
    #[serde(rename = "expectedStateCommitment")]
    expected_state: String,
    #[serde(rename = "expectedRelationCommitment")]
    expected_relation: String,
}

#[derive(Deserialize)]
struct JsonEvent {
    id: String,
    #[serde(rename = "skillID")]
    skill_id: String,
    surface: String,
    kind: String,
    score: f64,
    #[serde(rename = "timestampMs")]
    timestamp_ms: i64,
    confident: Option<bool>,
}

#[test]
fn practice_vectors_match_python() {
    let file = repo_file("Tests/PracticeLedgerTests/vectors.json");
    let vectors: Vec<PracticeVector> =
        serde_json::from_reader(std::fs::File::open(&file).expect("practice vectors")).unwrap();
    assert_eq!(vectors.len(), 6);
    for vector in vectors {
        let events: Vec<_> = vector
            .events
            .iter()
            .map(|event| PracticeEvent {
                id: event.id.clone(),
                skill_id: event.skill_id.clone(),
                surface: surface_byte(&event.surface).unwrap(),
                kind: kind_byte(&event.kind).unwrap(),
                score_bits: canonical_score_bits(event.score),
                timestamp_ms: event.timestamp_ms,
                confident: match event.confident {
                    None => 0,
                    Some(false) => 1,
                    Some(true) => 2,
                },
            })
            .collect();
        let (state, relation) = practice_commitment(vector.lineage, vector.generation, &events);
        assert_eq!(state, vector.expected_state, "{}", vector.name);
        assert_eq!(relation, vector.expected_relation, "{}", vector.name);
    }
}

#[test]
fn call_boundary_matches_the_state_vector() {
    let entries = {
        let mut bytes = Vec::new();
        for (id, value) in [(1u64, 10i64), (2, 20)] {
            bytes.extend_from_slice(&id.to_be_bytes());
            bytes.extend_from_slice(&value.to_be_bytes());
        }
        bytes
    };
    let order = {
        let mut bytes = Vec::new();
        for id in [1u64, 2] {
            bytes.extend_from_slice(&id.to_be_bytes());
        }
        bytes
    };
    let mut out = [0u8; 64];
    let rc = unsafe {
        commitment_reader::cf_state_commitment_hex(
            1,
            0,
            entries.as_ptr(),
            entries.len() as u32,
            order.as_ptr(),
            order.len() as u32,
            out.as_mut_ptr(),
        )
    };
    assert_eq!(rc, 0);
    let hex = std::str::from_utf8(&out).unwrap();
    assert_eq!(hex, "d9a07b92d21590167b300c10be7410322ecb78ed1a56ee0e531803fe263ccc22");
}
