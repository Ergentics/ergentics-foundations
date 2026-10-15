# Data run

The roadmap in `docs/roadmap.md` lists later phases and says they have not started. This note is the first scoped data run. It does not start those phases.

## Question

What does one frozen local pass of the already-specified public paths cost, when the controls in `docs/benchmarks.md` are printed with the numbers?

That is a question about the local reference runtime that already exists: `FoundationBench` and `commitment-bench`. It is not a question about E26. It does not reopen that line, and it is not E27.

## Frozen controls

- Iteration counts are arguments, not tuned after looking at the times. The recorder's default is 100. CI's bench smoke stays at 2 and is not this run.
- Each workload prints what it includes and what it excludes. Those notes are the accounting boundary. The recorder copies them. It does not rank workloads or languages.
- The Swift arms and the Rust arms are different processes. A data run does not subtract one from the other.
- The sinks must match the pinned commitments in `docs/benchmarks.md`. A drifted sink is a failed run, not a faster run.

## Toolchains for this run

| Tool | Version | Role |
|---|---|---|
| Swift | 6.4.1 | Latest 6.4 stable. Runs the package and `FoundationBench`. |
| Rust | 1.99.0 | Current stable. Runs `commitment-bench`. |
| Ruby | 4.0.7 | Latest stable. The recorder. Standard library only. |
| Rails | 8.1.4 | The section 9 index in `traceability/`. The recorder does not load it. |

## What this run does not start

Storage, Cloudflare/R2, Apple Core AI, a microkernel, and cognitive or differential execution research stay unstarted. A Rails process is not the store. An Active Record row is not authority and is not a commitment. The section 9 index is a separate app and is not this cost question. Cloud infrastructure remains execution infrastructure. A model result remains not semantic authority.

## Record

```sh
export PATH="$HOME/.local/ruby-4.0.7/bin:$PATH"
ruby reference/data_run.rb --execute --iterations 100
```

The JSON is written under `data-runs/`, which is not committed. Committing a machine's timings would turn one pass into a baseline. The file records the question, the controls, the toolchain versions, the bench text, and the phases that remain unstarted.
