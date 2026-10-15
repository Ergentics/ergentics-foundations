#!/usr/bin/env python3
"""Check that the E27 candidate list stays unnominated.

The public synthesis remains the written closeout. This script checks that
the candidate file agrees with that closeout and with E27Started in the
release basis. It does not start an experiment.
"""

import hashlib
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SYNTHESIS = ROOT / "docs" / "e01-e26-public-synthesis.md"
BASIS = ROOT / "sdk-release-basis.json"
CANDIDATES = ROOT / "docs" / "e27-candidates.json"
NOTE = ROOT / "docs" / "e27-candidates.md"
CATALOG = ROOT / "docs" / "evidence-catalog.json"
CLOSEOUT = "The series closes after E26 because the accepted evidence no longer uniquely nominates a next intervention."


def fail(message):
    print(message, file=sys.stderr)
    sys.exit(1)


def main():
    synthesis = SYNTHESIS.read_bytes()
    basis = json.loads(BASIS.read_bytes())
    listed = json.loads(CANDIDATES.read_bytes())
    note = NOTE.read_text()
    catalog_ids = {row["id"] for row in json.loads(CATALOG.read_bytes())["evidence"]}

    digest = hashlib.sha256(synthesis).hexdigest()
    if digest != basis["PostHocSynthesis"]["sha256"]:
        fail("synthesis digest drifted from the release basis")
    if basis["E27Started"] is not False or basis["E26SpeedupTested"] is not False:
        fail("basis no longer records E26 as closed without a speedup")
    synthesis_text = synthesis.decode()
    if CLOSEOUT not in synthesis_text or "Future work is not blocked." not in synthesis_text:
        fail("synthesis closeout sentence missing")
    closeout = listed["closeout"]
    if closeout != {
        "classification": "H. MEASUREMENT DECOMPOSITION INCONCLUSIVE",
        "e27InThisSeries": False,
        "economicExhaustion": "UNKNOWN",
        "evidenceScope": "AT_CLOSEOUT",
        "speedupTested": False,
        "successorProjectsBlocked": False,
        "universalNoNewEvidence": False,
    }:
        fail("closeout record changed")
    for sentence in (
        "H. MEASUREMENT DECOMPOSITION INCONCLUSIVE; no speedup was tested.",
        "without isolating removable work or establishing reusable validation authority or net benefit.",
        "the evidence no longer uniquely nominates another intervention.",
        "There is no E27 in this series.",
        "Economic exhaustion remains UNKNOWN; successor projects are not blocked.",
        "The evidence in hand at closeout is not a universal rule that no new evidence can be gathered.",
    ):
        if sentence not in note:
            fail(f"note omitted: {sentence}")
    if listed["attribution"] != {
        "armsSeparateOnSinks": True,
        "boundary": "public-change-foundation",
        "e26PrivateLoopDecomposed": False,
        "projectionDigest": "58b8db0ebace624abdd96712379cbf5dfb7ce9b9bbfc0c17d1c00482b6c73c02",
        "speedupTested": False,
    }:
        fail("attribution record changed")
    if "The public reference has now run that attribution once." not in note:
        fail("note lost the attribution run")
    if listed["design"] != {
        "firstQuestionIfMeasured": "CANDIDATE-CLEAN-ATTRIBUTION",
        "openSourceSpeedupTrial": False,
        "publicBenchesAreE26": False,
        "speedupTestFirst": False,
    }:
        fail("design record changed")
    if "The untested speedup is not the next measurement." not in note:
        fail("note lost the yield order")
    if listed["e27Started"] is not False or listed["nomination"] != "NONE":
        fail("candidate file nominates E27")
    if listed["seriesStatus"] != "CLOSED_AFTER_E26":
        fail(listed["seriesStatus"])
    if listed["source"] != "docs/e01-e26-public-synthesis.md":
        fail("candidate file left the synthesis")

    seen = set()
    if len(listed["candidates"]) != 8 or len(listed["excluded"]) != 3:
        fail("candidate inventory changed size")
    for row in listed["candidates"]:
        if row["status"] != "NOT_NOMINATED" or not row["id"].startswith("CANDIDATE-"):
            fail(row["id"])
        if row["id"] in seen or row["id"] not in note or not row["question"]:
            fail(row["id"])
        seen.add(row["id"])
        for evidence_id in row["evidenceIds"]:
            if evidence_id not in catalog_ids:
                fail(evidence_id)
    for row in listed["excluded"]:
        if row["status"] != "NOT_A_CANDIDATE" or not row["id"].startswith("EXCLUDED-"):
            fail(row["id"])
        if row["id"] in seen or row["id"] not in note:
            fail(row["id"])
        seen.add(row["id"])
    if "It does not start E27" not in note:
        fail("note lost the unstarted statement")


if __name__ == "__main__":
    main()
