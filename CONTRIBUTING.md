# Contributing

Ergentics Foundations is licensed under [Apache-2.0](LICENSE). Under section 5, contributions intentionally submitted for inclusion are under Apache-2.0 unless explicitly stated otherwise; an applicable separate license agreement is not superseded. Section 1 defines a Contribution and excludes material designated in writing as "Not a Contribution." Submit only material you have authority to license. Identify any third-party material and its applicable terms. No separate CLA or DCO sign-off is required for this candidate.

Proposed changes should state the semantic contract, add a small synthetic counterexample or reference vector where needed, and preserve rejection behavior. Keep correctness, authority and performance claims separate. A timing observation needs its own declared control, accounting boundary and independent review; this package's tests are not performance evidence.

Never contribute private primary evidence, model inputs, patient information, credentials, signing material, private history or internal operational records. Public claims derived from the private record must use stable evidence IDs and retain uncertainty. Historical negative results and classification boundaries must not be rewritten to improve a narrative.

Run `swift test --scratch-path ../foundation-build`. Keep generated build files and local diagnostics outside the export inventory. Preserve applicable notices and follow Apache-2.0 section 4 when redistributing modified files. License adoption is complete; approval of the final public tree and repository owner remains pending.
