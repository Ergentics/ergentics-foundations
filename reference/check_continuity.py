#!/usr/bin/env python3
"""Read the retained E26 continuity rows and check the published counts.

The rows are per-process transition and occurrence counts. Repeating them
across two sweeps and three observer levels does not make them independent
replicates. This script does not rerun E26, pool the rows, or treat multiset
equality or common agreement as a license to reuse the ordered validation product.
"""

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
DATASET = ROOT / "docs" / "longitudinal-dataset.json"
EVIDENCE = "EV-E26-CONTINUITY"
LEVELS = ("aggregate", "clean", "diagnostic")
PRIMARY = {
    "orderedEqual": 0,
    "multisetEqual": 63,
    "transitionDenominator": 63,
    "commonAgreement": 65457,
    "commonDenominator": 65457,
}
CHANGED = {
    "orderedEqual": 0,
    "multisetEqual": 0,
    "transitionDenominator": 63,
    "commonAgreement": 64323,
    "commonDenominator": 65457,
}


def fail(message):
    print(message, file=sys.stderr)
    sys.exit(1)


def expect(row, counts):
    for key, value in counts.items():
        if row[key] != value:
            fail(f"sweep {row['sweep']} level {row['level']} cell {row['cell']} {key}={row[key]}")
    if row["transitionDenominator"] == row["commonDenominator"]:
        fail("transition and occurrence denominators must stay distinct")


def main():
    before = DATASET.read_bytes()
    document = json.loads(before)
    if DATASET.read_bytes() != before:
        fail("reader wrote the dataset")
    rows = document["continuityRows"]
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
        if row["cell"] == 0:
            expect(row, PRIMARY)
        elif row["cell"] == 1:
            expect(row, CHANGED)
        else:
            fail(f"unexpected cell {row['cell']}")
    expected = {(sweep, level, cell) for sweep in (1, 2) for level in LEVELS for cell in (0, 1)}
    if seen != expected:
        fail(f"coverage {seen ^ expected}")


if __name__ == "__main__":
    main()
