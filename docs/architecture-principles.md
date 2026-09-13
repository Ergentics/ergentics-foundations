# Architecture principles

1. Public knowledge and a proposed state transition are inspectable values. They do not confer commit authority.
2. Verification produces a private, process-local receipt. Admission is rechecked when that receipt is consumed.
3. Canonical representation supplies deterministic identity under a specified encoding. It does not establish semantic applicability or current authority.
4. Relation and order are separate. Reordering can preserve the ID/value relation while changing the state commitment.
5. An empty consequential change still advances generation when committed. Equal values do not erase history.
6. Preserve stable contracts and reference evidence, not incidental benchmark machinery.

The executable center consists of one Swift module. `State` validates a unique ID domain and a permutation of that domain; `CandidateTransition` is untrusted input; `ReferenceAuthority.verify` evaluates a proposal without committing; `commit` atomically rechecks and advances state. These new synthetic contracts illustrate post-hoc lessons. They are not a claim that the private testbed used this exact implementation.

The current authority object is an actor and uses in-memory UUID identities plus a revocation epoch. It has no persistence, message transport, remote admission or microkernel implementation. Numerical computation, storage adapters and isolation boundaries remain future design work.
