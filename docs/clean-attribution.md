# Clean attribution

`CANDIDATE-CLEAN-ATTRIBUTION` asks whether projection, construction, equality, and append can be named apart. `CleanAttribution.run` answers that on the public `ChangeFoundation` boundary only.

The fixture is the 32-entry state whose commitment is `58b8db0ebace624abdd96712379cbf5dfb7ce9b9bbfc0c17d1c00482b6c73c02`. Each arm has its own sink:

| Arm | What it includes | Sink |
|---|---|---|
| Construction | Domain check, sort, stored lineage, generation, entry count, and order count | No digest |
| Projection | `CF-STATE-v1` bytes of that state, then SHA-256 | 827 bytes and the pinned digest |
| Equality | Same entries in reversed order | Relation equal, ordered unequal, ordered product not reused |
| Append | One empty verify and commit | Generation 1, relation commitment stable, state commitment changed |

A second straight-line pass repeats the four operations. The arms separate when those sinks match. That match is an accounting identity. It is not a duration and not a speedup.

This run does not instrument the private E26 mixed loop, does not start E27, and does not rank the arms. The candidate stays `NOT_NOMINATED`.
