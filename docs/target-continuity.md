# E26 target continuity

`TargetContinuity` records one retained row from `docs/longitudinal-dataset.json`. The evidence id is `EV-E26-CONTINUITY`. Loading the twelve rows does not rerun E26 and does not start E27.

Each row keeps three predicates:

| Predicate | Primary target, cell 0 | Changed source, cell 1 | Denominator |
|---|---|---|---|
| Ordered vector equality | 0/63 | 0/63 | Adjacent transitions |
| Multiset equality | 63/63 | 0/63 | Adjacent transitions |
| Common occurrence/backing agreement | 65,457/65,457 | 64,323/65,457 | Occurrences |

The same counts appear in sweep 1 and sweep 2, at the aggregate, clean, and diagnostic observer levels. Those repetitions are per-process counts. They are not independent statistical replicates, and the three predicates are not one equality. The transition denominator and the occurrence denominator stay distinct.

Multiset equality is unordered agreement. A complete multiset count does not license reuse of the ordered validation product. The common-association ratio does not license that reuse either, including the primary target's complete 65,457/65,457 agreement. `unorderedAgreementLicensesOrderedReuse` and `commonAssociationLicensesOrderedReuse` stay false.

`Relation` in this package is the unique ID/value map. It is not the E26 coordinate-to-backing relation, and this type does not recompute one. No speedup is claimed.
