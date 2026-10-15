# Traceability index

Rails 8.1.4 on Ruby 4.0.7. SQLite holds a local index of the section 9 chain in `../research-to-sdk-traceability.json`, plus the acceptance value in `../sdk-release-basis.json`.

The chain is ResearchFinding, PostHocConclusion, SDKContract, reference vector or test, then SDKRelease. Empty vector and test lists are zero links. A missing link is not proof. The document status can pass for origin and coverage while implementation stays partial. Acceptance `YES_WITH_LIMITATIONS` is copied from the release basis. It is not inferred from the number of rows.

A row id is the SQLite key. It is not a StateID and not a commit. Deleting rows does not change the JSON. This app does not implement ObjectID, CBOR, witness or parent proofs, or a production store. The contract note is [docs/traceability-index.md](../docs/traceability-index.md).

```sh
export PATH="$HOME/.local/ruby-4.0.7/bin:$PATH"
cd traceability
bin/rails db:prepare
bin/rails db:seed
bin/rails test
```

`config/master.key` stays on the machine that generated the app. It is not part of this tree.
