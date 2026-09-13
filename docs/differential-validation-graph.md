# Differential Validation Graph

The JSON graph is a curated **post-hoc** representation of 26 frozen experiment reports, not a new runtime trace, primary evidence, causal model or executable authority policy. It contains 88 typed nodes and 104 typed edges. Every node and edge names supporting public evidence IDs; the research owner's private evidence map binds those IDs to exact frozen-file SHA-256 values and line or JSON selectors. The public catalog discloses that primary payloads remain private.

Each experiment has a report-local classification and a focus node. E04–E26 focus nodes are connected by `FOLLOWED_BY` edges to express historical progression without asserting that costs disappeared. Additional nodes distinguish semantic state, relations, representations, construction evidence, validation results, authority, integrity, plans, publication and consequential source change. The graph intentionally omits individual private artifact IDs and most runtime objects.

## Edge semantics

| Type | Meaning |
|---|---|
| OBSERVED_AT | A bounded report supports a focus, classification or concept |
| FOLLOWED_BY | Historical focus progression; not causal elimination or timing equivalence |
| DEPENDS_ON | Stated semantic dependency within the cited contract |
| DERIVED_FROM | Current construction supplies bounded representation evidence |
| REQUIRES | A current obligation, or an explicitly unknown proposed reuse precondition |
| AUTHORIZED_BY | Private admission/current-authority boundary, not a public hash granting rights |
| INVALIDATED_BY | Tested conditional relation-eligibility invalidation by consequential source change |

Edge interpretation text is part of the assertion. For example, the validation-result/current-authority edge does not say E26 implemented a cross-generation validation cache: it marks applicability as UNKNOWN. The source-change edge is about the tested changed-source fixture, not every conceivable source edit.

## Reading the branches

The historical spine moves from discovery through execution/publication, plan and request maintenance, commitments and bootstrap, then result reuse, representation and validation. The **recurring output-integrity branch from E17 remains unresolved** beside the first-result work continued in E18–E26. No new edge nominates E27.

The series closes at E26 by explicit subsequent decision. Its classification remains H. MEASUREMENT DECOMPOSITION INCONCLUSIVE; no speedup was tested. A graph of historical bottlenecks cannot by itself identify a removable check or justify an optimization. Structural persistence, current authority and economic benefit need separate evidence.
