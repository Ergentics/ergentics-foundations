//! Timings for the Rust reader. Not performance evidence and not a comparison with Swift.
//!
//! The hash-only arm hashes bytes that were encoded once. The other arms encode and hash
//! a fixed-size value on every iteration. This process has no actor and no growing log.

use commitment_reader::{practice_commitment, state_commitment, Entry, PracticeEvent};
use std::env;
use std::hint::black_box;
use std::time::Instant;

fn main() {
    let iterations = iterations();
    println!("# commitment-bench");
    println!("# not-performance-evidence");
    println!("# reader={}", commitment_reader::READER_VERSION);
    println!("# rust-version={}", env!("CARGO_PKG_RUST_VERSION"));
    println!("# iterations={iterations}");
    println!("# excludes: actor, disk, oracle, growing log, Swift");

    let entries: Vec<Entry> = (1..=32)
        .map(|id| Entry { id, value: (id as i64) * 3 })
        .collect();
    let order: Vec<u64> = entries.iter().map(|entry| entry.id).collect();
    let encoded = commitment_reader::state_bytes(1, 0, &entries, &order);
    let pinned_state = "58b8db0ebace624abdd96712379cbf5dfb7ce9b9bbfc0c17d1c00482b6c73c02";
    let pinned_moment = "01921ef1f4bf0fa708d90d7d8612bc1f320c52152a0a010868026d2eccc18e32";

    let hash_started = Instant::now();
    let mut hash_sink = String::new();
    for _ in 0..iterations {
        hash_sink = commitment_reader::sha256_hex(black_box(&encoded));
    }
    require_sink("hash-precomputed-state", &hash_sink, pinned_state);
    report(
        "hash-precomputed-state",
        iterations,
        hash_started.elapsed().as_nanos(),
        "includes: SHA-256 of one already-encoded 32-entry state; excludes: canonical encoding",
        &hash_sink,
    );

    let encode_started = Instant::now();
    let mut encode_sink = String::new();
    for _ in 0..iterations {
        encode_sink = black_box(state_commitment(1, 0, &entries, &order).0);
    }
    require_sink("state-encode", &encode_sink, pinned_state);
    report(
        "state-encode",
        iterations,
        encode_started.elapsed().as_nanos(),
        "includes: CF-STATE-v1 encoding and SHA-256 of a fixed 32-entry state. Control against hash-precomputed-state",
        &encode_sink,
    );

    let event = PracticeEvent {
        id: "moment-1".to_string(),
        skill_id: "capturing".to_string(),
        surface: 4,
        kind: 3,
        score_bits: 1.0_f64.to_bits(),
        timestamp_ms: 1_700_000_000_000,
        confident: 0,
    };
    let practice_started = Instant::now();
    let mut practice_sink = String::new();
    for _ in 0..iterations {
        practice_sink = black_box(practice_commitment(1, 1, std::slice::from_ref(&event)).0);
    }
    require_sink("practice-fixed-log", &practice_sink, pinned_moment);
    report(
        "practice-fixed-log",
        iterations,
        practice_started.elapsed().as_nanos(),
        "includes: PL-LOG-v1 for one moment event, chunking, CF-STATE-v1, SHA-256. The log does not grow",
        &practice_sink,
    );
}

fn iterations() -> usize {
    let mut args = env::args().skip(1);
    while let Some(arg) = args.next() {
        if arg == "--iterations" {
            if let Some(value) = args.next().and_then(|text| text.parse().ok()) {
                if value > 0 {
                    return value;
                }
            }
        }
    }
    10_000
}

fn require_sink(name: &str, sink: &str, pinned: &str) {
    if sink != pinned {
        eprintln!("{name} sink drifted from the pinned commitment");
        std::process::exit(1);
    }
}

fn report(name: &str, iterations: usize, total_ns: u128, note: &str, sink: &str) {
    let per = total_ns / u128::try_from(iterations).unwrap_or(1);
    println!("workload={name} iterations={iterations} total_ns={total_ns} ns_per_op={per}");
    println!("note={note}");
    println!("sink={sink}");
}
