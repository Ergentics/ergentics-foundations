#!/usr/bin/env python3
"""Agree the E26 continuity counts in the synthesis and the dataset.

docs/e01-e26-public-synthesis.md is already the written record. Its SHA-256 is
the PostHocSynthesis digest in sdk-release-basis.json. The longitudinal dataset
retains the same adjacent-transition counts. This script reads both files and
checks that they name the same fractions. It does not rewrite either file,
rerun E26, or pool the rows into replicates.
"""

import hashlib
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SYNTHESIS = ROOT / "docs" / "e01-e26-public-synthesis.md"
DATASET = ROOT / "docs" / "longitudinal-dataset.json"
BASIS = ROOT / "sdk-release-basis.json"
EVIDENCE = "EV-E26-CONTINUITY"
LEVELS = ("aggregate", "clean", "diagnostic")


def fail(message):
    print(message, file=sys.stderr)
    sys.exit(1)


def fraction(text, label):
    match = re.search(re.escape(label) + r"\s+([0-9,]+)/([0-9,]+)", text)
    if match is None:
        fail(f"synthesis omitted {label}")
    return tuple(int(part.replace(",", "")) for part in match.groups())


def synthesis_counts(text):
    marker = "E26's target continuity is especially discriminating."
    start = text.find(marker)
    if start < 0:
        fail("synthesis has no continuity paragraph")
    end = text.find(f"[{EVIDENCE}]", start)
    if end < 0:
        fail("continuity paragraph has no evidence id")
    paragraph = text[start:end].replace("**", "")
    for sentence in (
        "per-process transition/occurrence counts, not independent statistical replicates or identical equality predicates",
        "Neither unordered agreement nor a high common-association ratio licenses reuse of the whole current ordered validation product.",
    ):
        if sentence not in paragraph:
            fail(f"synthesis omitted: {sentence}")
    if "The derived dataset simply retains their exact counts." not in text:
        fail("synthesis no longer says the dataset retains the exact counts")
    pivot = paragraph.find("changed-source counterpart")
    if pivot < 0:
        fail("synthesis omitted the changed-source counterpart")
    return {
        0: pair(paragraph[:pivot], "ordered vector equality", "multiset equality", "common occurrence/backing agreement"),
        1: pair(paragraph[pivot:], "ordered equality", "multiset equality", "agreement"),
    }


def pair(text, ordered_label, multiset_label, agreement_label):
    ordered_matched, ordered_denominator = fraction(text, ordered_label)
    multiset_matched, multiset_denominator = fraction(text, multiset_label)
    agreement_matched, agreement_denominator = fraction(text, agreement_label)
    if ordered_denominator != multiset_denominator:
        fail(f"{ordered_label} and {multiset_label} use different transition denominators")
    if ordered_denominator == agreement_denominator:
        fail(f"{agreement_label} reused the transition denominator")
    return {
        "orderedEqual": ordered_matched,
        "multisetEqual": multiset_matched,
        "transitionDenominator": ordered_denominator,
        "commonAgreement": agreement_matched,
        "commonDenominator": agreement_denominator,
    }


def main():
    synthesis_bytes = SYNTHESIS.read_bytes()
    dataset_bytes = DATASET.read_bytes()
    basis = json.loads(BASIS.read_bytes())
    claimed = basis["PostHocSynthesis"]["sha256"]
    digest = hashlib.sha256(synthesis_bytes).hexdigest()
    if digest != claimed:
        fail(f"synthesis sha256 {digest} != basis {claimed}")
    if basis["PostHocSynthesis"]["publicEvidenceId"] != "POSTHOC-E01-E26-CLOSEOUT":
        fail("basis moved the synthesis evidence id")
    if SYNTHESIS.read_bytes() != synthesis_bytes or DATASET.read_bytes() != dataset_bytes:
        fail("reader wrote a record")

    expected = synthesis_counts(synthesis_bytes.decode())
    rows = json.loads(dataset_bytes)["continuityRows"]
    if len(rows) != 12:
        fail(f"expected 12 rows, found {len(rows)}")
    seen = set()
    for row in rows:
        if row["evidenceId"] != EVIDENCE:
            fail(row["evidenceId"])
        key = (row["sweep"], row["level"], row["cell"])
        if key in seen:
            fail(f"duplicate {key}")
        seen.add(key)
        counts = expected.get(row["cell"])
        if counts is None:
            fail(f"unexpected cell {row['cell']}")
        for field, value in counts.items():
            if row[field] != value:
                fail(f"{key} {field}={row[field]} synthesis={value}")
        if row["multisetEqual"] > row["transitionDenominator"]:
            fail("multiset count uses a different transition denominator than ordered equality")
    coverage = {(sweep, level, cell) for sweep in (1, 2) for level in LEVELS for cell in (0, 1)}
    if seen != coverage:
        fail(f"coverage {seen ^ coverage}")


if __name__ == "__main__":
    main()
