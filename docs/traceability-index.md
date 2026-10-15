# Traceability index

`SDK-v0.1-SCOPE.md` section 9 names the chain ResearchFinding, PostHocConclusion, SDKContract, ReferenceVector or Test, then SDKRelease. `traceability/` is a Rails 8.1.4 app that loads that chain from `research-to-sdk-traceability.json`. Acceptance is copied from `foundationAcceptance` in `sdk-release-basis.json`.

The loader reads those files and inserts rows. It does not write them back. An empty `canonicalVectors` or `referenceTests` array becomes zero `trace_links`. The loader refuses a blank target. Coverage text such as `EXISTING_BOUNDED_REFERENCE` does not fill a missing vector list. `SDK-Generation` keeps its three tests and zero vectors. `SDK-ObjectID` stays `DEFER` with zero vectors and zero tests. `SDK-Representation` stays `INTERNAL_ONLY` even where vector links exist.

The indexed status is `PASS_FOR_DOCUMENTED_ORIGIN_AND_COVERAGE_NOT_FULL_IMPLEMENTATION`. That pass is not full implementation. Requirement rows whose status is `PARTIAL` stay partial, including wrong parent, sibling lineage, evidence without current authority, and invalid or revoked authority. `YES_WITH_LIMITATIONS` is the stored acceptance. Deleting contracts does not recompute it. `E27Started` is stored as false.

`recorded_publication` repeats the basis field. It is not a live check of a Git remote. License fields are not copied onto contracts. This load does not change contract scope.

SQLite primary keys and `created_at` are index metadata. They are not a StateID, not an experiment time, and not a commit. The app has no ObjectID, CBOR, witness, or parent-proof tables, and `config/database.yml` does not configure a production database. The data-run recorder does not boot this app.
